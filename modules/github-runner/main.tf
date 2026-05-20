terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

locals {
  github_repository_parts = split("/", var.github_repository)
  github_owner            = local.github_repository_parts[0]
  github_repo_name        = local.github_repository_parts[1]
  runner_user             = "githubrunner"
  runner_home             = "/home/${local.runner_user}"

  cloud_init = <<-CLOUDINIT
    #cloud-config
    package_update: true
    package_upgrade: false
    packages:
      - curl
      - jq
      - tar
      - gzip
      - ca-certificates
      - git
      - unzip
      - build-essential
    write_files:
      - path: /usr/local/bin/install-github-runner.sh
        permissions: "0755"
        owner: root:root
        content: |
          #!/usr/bin/env bash
          set -euxo pipefail

          RUNNER_USER="${local.runner_user}"
          RUNNER_HOME="${local.runner_home}"
          REPOSITORY="${var.github_repository}"
          OWNER="${local.github_owner}"
          REPO_NAME="${local.github_repo_name}"
          VM_NAME="${var.vm_name}"
          TOKEN=$(printf '%s' '${base64encode(var.github_runner_token)}' | base64 -d)

          if ! id "$${RUNNER_USER}" >/dev/null 2>&1; then
            useradd --create-home --home-dir "$${RUNNER_HOME}" --shell /bin/bash "$${RUNNER_USER}"
          fi

          install -d -m 0755 -o "$${RUNNER_USER}" -g "$${RUNNER_USER}" "$${RUNNER_HOME}/actions-runner"

          REGISTRATION_TOKEN="$${TOKEN}"
          API_RESPONSE=$(curl -fsSL -X POST \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer $${TOKEN}" \
            "https://api.github.com/repos/$${OWNER}/$${REPO_NAME}/actions/runners/registration-token" || true)

          if [ -n "$${API_RESPONSE}" ]; then
            API_TOKEN=$(printf '%s' "$${API_RESPONSE}" | jq -r '.token // empty')
            if [ -n "$${API_TOKEN}" ]; then
              REGISTRATION_TOKEN="$${API_TOKEN}"
            fi
          fi

          RUNNER_VERSION=$(curl -fsSL "https://api.github.com/repos/actions/runner/releases/latest" | jq -r '.tag_name | ltrimstr("v")')
          RUNNER_ARCHIVE="actions-runner-linux-x64-$${RUNNER_VERSION}.tar.gz"
          RUNNER_URL="https://github.com/actions/runner/releases/download/v$${RUNNER_VERSION}/$${RUNNER_ARCHIVE}"
          RUNNER_ARCHIVE_PATH="$${RUNNER_HOME}/$${RUNNER_ARCHIVE}"

          curl -fsSL "$${RUNNER_URL}" -o "$${RUNNER_ARCHIVE_PATH}"
          chown "$${RUNNER_USER}:$${RUNNER_USER}" "$${RUNNER_ARCHIVE_PATH}"

          runuser -u "$${RUNNER_USER}" -- bash -lc "
            set -euo pipefail
            cd '$${RUNNER_HOME}/actions-runner'
            if [ ! -f .runner ]; then
              tar xzf '$${RUNNER_ARCHIVE_PATH}'
              ./config.sh --unattended --replace --url 'https://github.com/$${REPOSITORY}' --token '$${REGISTRATION_TOKEN}' --name '$${VM_NAME}' --work '_work' --labels 'self-hosted,linux,azure'
            fi
          "

          cd "$${RUNNER_HOME}/actions-runner"
          ./bin/installdependencies.sh
          ./svc.sh install "$${RUNNER_USER}"
          ./svc.sh start

          rm -f "$${RUNNER_ARCHIVE_PATH}"
    runcmd:
      - [bash, /usr/local/bin/install-github-runner.sh]
  CLOUDINIT
}

resource "tls_private_key" "runner_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_network_interface" "runner" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "runner" {
  name                            = var.vm_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.runner.id]
  custom_data                     = base64encode(local.cloud_init)

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.runner_ssh.public_key_openssh
  }

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "${var.vm_name}-osdisk"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = var.tags
}
