targetScope = 'resourceGroup'

// ─── Parameters ───────────────────────────────────────────────────────────────

@description('Azure region for all resources')
param location string

@description('Base name prefix for resources')
param baseName string = 'aksbackend'

@description('VNet address space')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Runner subnet CIDR')
param runnerSubnetPrefix string = '10.0.250.0/24'

@description('Private endpoint subnet CIDR')
param peSubnetPrefix string = '10.0.251.0/24'

@description('Storage account name for Terraform state')
param storageAccountName string

@description('GitHub runner token (PAT)')
@secure()
param githubRunnerToken string

@description('GitHub repository in owner/repo format')
param githubRepository string

@description('VM size for the runner')
param runnerVmSize string = 'Standard_B2s'

@description('Admin password for the runner VM (auto-generated if not provided)')
@secure()
param runnerAdminPassword string = newGuid()

// ─── Variables ────────────────────────────────────────────────────────────────

var vnetName = 'vnet-${baseName}'
var natGatewayName = 'natgw-${baseName}-runner'
var natGatewayPipName = 'pip-${natGatewayName}'
var runnerVmName = 'vm-${baseName}-runner'
var runnerNicName = '${runnerVmName}-nic'
var runnerSubnetName = 'snet-runner'
var peSubnetName = 'snet-private-endpoints'
var storagePeName = 'pe-${storageAccountName}-blob'
var privateDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'
var stateContainerName = 'tfstate'

// ─── Virtual Network ──────────────────────────────────────────────────────────

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
    subnets: [
      {
        name: runnerSubnetName
        properties: {
          addressPrefix: runnerSubnetPrefix
          natGateway: {
            id: natGateway.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: peSubnetName
        properties: {
          addressPrefix: peSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// ─── NAT Gateway ──────────────────────────────────────────────────────────────

resource natGatewayPip 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: natGatewayPipName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource natGateway 'Microsoft.Network/natGateways@2024-05-01' = {
  name: natGatewayName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 10
    publicIpAddresses: [
      {
        id: natGatewayPip.id
      }
    ]
  }
}

// ─── Storage Account (Terraform State) ────────────────────────────────────────

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    allowSharedKeyAccess: false
    publicNetworkAccess: 'Enabled'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource stateContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: stateContainerName
}

// ─── Private DNS Zone (Blob) ──────────────────────────────────────────────────

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  tags: tags
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsZone
  name: '${vnetName}-link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}

// ─── Storage Private Endpoint ─────────────────────────────────────────────────

resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: storagePeName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: vnet.properties.subnets[1].id
    }
    privateLinkServiceConnections: [
      {
        name: storagePeName
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: ['blob']
        }
      }
    ]
  }
}

resource storagePeDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: storagePrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'blob'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

// ─── Runner VM ────────────────────────────────────────────────────────────────

var githubOwner = split(githubRepository, '/')[0]
var githubRepoName = split(githubRepository, '/')[1]
var runnerUser = 'githubrunner'

var cloudInitScript = '''#!/usr/bin/env bash
set -euxo pipefail

RUNNER_USER="{0}"
RUNNER_HOME="/home/{0}"
REPOSITORY="{1}"
OWNER="{2}"
REPO_NAME="{3}"
VM_NAME="{4}"
TOKEN="{5}"

if ! id "$RUNNER_USER" >/dev/null 2>&1; then
  useradd --create-home --home-dir "$RUNNER_HOME" --shell /bin/bash "$RUNNER_USER"
fi

install -d -m 0755 -o "$RUNNER_USER" -g "$RUNNER_USER" "$RUNNER_HOME/actions-runner"

# Get registration token from PAT
REGISTRATION_TOKEN="$TOKEN"
API_RESPONSE=$(curl -fsSL -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO_NAME/actions/runners/registration-token" || true)

if [ -n "$API_RESPONSE" ]; then
  API_TOKEN=$(printf '%s' "$API_RESPONSE" | jq -r '.token // empty')
  if [ -n "$API_TOKEN" ]; then
    REGISTRATION_TOKEN="$API_TOKEN"
  fi
fi

# Download latest runner
RUNNER_VERSION=$(curl -fsSL "https://api.github.com/repos/actions/runner/releases/latest" | jq -r '.tag_name | ltrimstr("v")')
RUNNER_ARCHIVE="actions-runner-linux-x64-$RUNNER_VERSION.tar.gz"
RUNNER_URL="https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/$RUNNER_ARCHIVE"
RUNNER_ARCHIVE_PATH="$RUNNER_HOME/$RUNNER_ARCHIVE"

curl -fsSL "$RUNNER_URL" -o "$RUNNER_ARCHIVE_PATH"
chown "$RUNNER_USER:$RUNNER_USER" "$RUNNER_ARCHIVE_PATH"

# Configure runner
runuser -u "$RUNNER_USER" -- bash -lc "
  set -euo pipefail
  cd '$RUNNER_HOME/actions-runner'
  if [ ! -f .runner ]; then
    tar xzf '$RUNNER_ARCHIVE_PATH'
    ./config.sh --unattended --replace --url 'https://github.com/$REPOSITORY' --token '$REGISTRATION_TOKEN' --name '$VM_NAME' --work '_work' --labels 'self-hosted,linux,azure'
  fi
"

# Install as service
cd "$RUNNER_HOME/actions-runner"
./bin/installdependencies.sh
./svc.sh install "$RUNNER_USER"
./svc.sh start

rm -f "$RUNNER_ARCHIVE_PATH"
'''

var cloudInit = format('''#cloud-config
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
  - apt-transport-https
  - gnupg
  - lsb-release
  - docker.io
write_files:
  - path: /usr/local/bin/install-github-runner.sh
    permissions: "0755"
    owner: root:root
    content: |
      {0}
runcmd:
  - [bash, /usr/local/bin/install-github-runner.sh]
  - [systemctl, enable, docker]
  - [systemctl, start, docker]
  - [usermod, -aG, docker, githubrunner]
''', replace(replace(replace(replace(replace(replace(cloudInitScript, '{0}', runnerUser), '{1}', githubRepository), '{2}', githubOwner), '{3}', githubRepoName), '{4}', runnerVmName), '{5}', githubRunnerToken))

resource runnerNic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: runnerNicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'internal'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource runnerVm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: runnerVmName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: runnerVmSize
    }
    osProfile: {
      computerName: runnerVmName
      adminUsername: runnerUser
      adminPassword: runnerAdminPassword
      customData: base64(cloudInit)
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        name: '${runnerVmName}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: runnerNic.id
        }
      ]
    }
  }
}

// ─── RBAC: Runner gets Storage Blob Data Contributor on state storage ─────────

var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource runnerStorageRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, runnerVm.id, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalId: runnerVm.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// ─── Outputs ──────────────────────────────────────────────────────────────────

output vnetName string = vnet.name
output vnetId string = vnet.id
output resourceGroupName string = resourceGroup().name
output storageAccountName string = storageAccount.name
output stateContainerName string = stateContainerName
output runnerVmName string = runnerVm.name
output runnerSubnetId string = vnet.properties.subnets[0].id
output peSubnetId string = vnet.properties.subnets[1].id
