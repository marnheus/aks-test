<#
.SYNOPSIS
    Creates an Azure Bastion tunnel to a jumpbox VM.

.DESCRIPTION
    Opens an SSH (Linux) or RDP (Windows) tunnel through Azure Bastion
    to the appropriate jumpbox VM in the AKS demo resource group.

.PARAMETER Os
    Target OS: 'linux' (default) or 'win'.

.PARAMETER ResourceGroup
    Resource group containing the VMs and Bastion. Defaults to 'rg-aks-demo-westeurope'.

.PARAMETER LocalPort
    Local port to bind. Defaults to 2222 for Linux (SSH) or 3390 for Windows (RDP).

.EXAMPLE
    .\bastion-tunnel.ps1
    # Opens SSH tunnel on localhost:2222

.EXAMPLE
    .\bastion-tunnel.ps1 -Os win
    # Opens RDP tunnel on localhost:3390

.EXAMPLE
    .\bastion-tunnel.ps1 -Os linux -LocalPort 2200
    # Opens SSH tunnel on localhost:2200
#>

[CmdletBinding()]
param(
    [ValidateSet('linux', 'win')]
    [string]$Os = 'linux',

    [string]$ResourceGroup = 'rg-aks-demo-westeurope',

    [int]$LocalPort = 0
)

$ErrorActionPreference = 'Stop'

# Resolve VM name and port based on OS
switch ($Os) {
    'linux' {
        $vmFilter = 'linux-jumpbox'
        $resourcePort = 22
        if ($LocalPort -eq 0) { $LocalPort = 2222 }
    }
    'win' {
        $vmFilter = 'windows-jumpbox'
        $resourcePort = 3389
        if ($LocalPort -eq 0) { $LocalPort = 3390 }
    }
}

Write-Host "Looking up resources in '$ResourceGroup'..." -ForegroundColor Cyan

# Find the Bastion host
$bastion = az network bastion list --resource-group $ResourceGroup --query "[0].name" -o tsv
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($bastion)) {
    Write-Error "No Bastion host found in resource group '$ResourceGroup'."
    exit 1
}

# Find the target VM
$vmId = az vm list --resource-group $ResourceGroup `
    --query "[?contains(name, '$vmFilter')].id | [0]" -o tsv
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($vmId)) {
    Write-Error "No $Os jumpbox VM found in resource group '$ResourceGroup'."
    exit 1
}

$vmName = ($vmId -split '/')[-1]

Write-Host ""
Write-Host "Bastion:    $bastion" -ForegroundColor Green
Write-Host "Target VM:  $vmName" -ForegroundColor Green
Write-Host "Local port: $LocalPort -> $resourcePort" -ForegroundColor Green
Write-Host ""

if ($Os -eq 'linux') {
    Write-Host "Connect with: ssh -p $LocalPort <username>@localhost" -ForegroundColor Yellow
} else {
    Write-Host "Connect with: mstsc /v:localhost:$LocalPort" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Starting tunnel (Ctrl+C to stop)..." -ForegroundColor Cyan

az network bastion tunnel `
    --name $bastion `
    --resource-group $ResourceGroup `
    --target-resource-id $vmId `
    --resource-port $resourcePort `
    --port $LocalPort
