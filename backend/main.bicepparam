using 'main.bicep'

param location = 'westeurope'
param baseName = 'aksbackend'
param vnetAddressPrefix = '10.0.0.0/16'
param runnerSubnetPrefix = '10.0.250.0/24'
param peSubnetPrefix = '10.0.251.0/24'
param storageAccountName = 'staksdemostate2026'
param githubRepository = 'marnheus/aks-test'
param runnerVmSize = 'Standard_B2s'
param tags = {
  project: 'aks-demo'
  environment: 'shared'
  managedBy: 'bicep'
}

// githubRunnerToken is passed via --parameters at deployment time from GitHub secret
