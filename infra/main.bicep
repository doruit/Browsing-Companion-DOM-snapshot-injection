targetScope = 'subscription'

@description('Environment name (dev, staging, prod)')
param environment string = 'dev'

@description('Azure region for all resources')
param location string = 'eastus2'

@description('Base name for all resources')
param baseName string = 'brow-comp'

@description('Your Azure AD tenant ID')
param tenantId string = subscription().tenantId

@description('Your Azure AD object ID (for Key Vault access)')
param principalId string

@description('Model deployment name')
param modelDeploymentName string = 'gpt-4o-mini'

@description('Resource group name (optional, auto-generated if not provided)')
param resourceGroupName string = 'rg-${baseName}-${environment}'

// Resource group
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: {
    Environment: environment
    Project: 'BrowsingCompanion'
    ManagedBy: 'Bicep'
  }
}

// Generate a unique suffix based on subscription ID, environment, and baseName
var uniqueSuffix = substring(uniqueString(subscription().id, environment, baseName), 0, 4)

// Key Vault (deploy first for secrets)
module keyVault 'modules/key-vault.bicep' = {
  scope: rg
  name: 'keyvault-deployment'
  params: {
    location: location
    keyVaultName: 'kv-${baseName}-${environment}-${uniqueSuffix}'
    tenantId: tenantId
    principalId: principalId
  }
}

// Storage Account
module storage 'modules/storage.bicep' = {
  scope: rg
  name: 'storage-deployment'
  params: {
    location: location
    storageAccountName: 'st${replace(baseName, '-', '')}${environment}${uniqueSuffix}'
  }
}

// Cosmos DB
module cosmosDb 'modules/cosmos-db.bicep' = {
  scope: rg
  name: 'cosmosdb-deployment'
  params: {
    location: location
    accountName: 'cosmos-${baseName}-${environment}-${uniqueSuffix}'
  }
}

// Application Insights
module appInsights 'modules/app-insights.bicep' = {
  scope: rg
  name: 'appinsights-deployment'
  params: {
    location: location
    appInsightsName: 'ai-${baseName}-${environment}'
  }
}

// AI Foundry (Microsoft Foundry - includes model deployments)
module aiFoundry 'modules/ai-foundry.bicep' = {
  scope: rg
  name: 'aifoundry-deployment'
  params: {
    location: location
    foundryName: 'aif-${baseName}-${environment}-${uniqueSuffix}'
    projectName: 'prj-${baseName}-${environment}'
    modelDeploymentName: modelDeploymentName
  }
}

// Store connection strings in Key Vault
module secrets 'modules/secrets.bicep' = {
  scope: rg
  name: 'secrets-deployment'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    cosmosConnectionString: cosmosDb.outputs.connectionString
    storageConnectionString: storage.outputs.connectionString
    aiFoundryEndpoint: aiFoundry.outputs.endpoint
    aiFoundryProjectEndpoint: aiFoundry.outputs.projectEndpoint
  }
}

// Static Web App
module staticWebApp 'modules/static-web-app.bicep' = {
  scope: rg
  name: 'static-web-app-deployment'
  params: {
    location: location
    staticWebAppName: 'swa-${baseName}-${environment}-${uniqueSuffix}'
  }
}

// Outputs
output resourceGroupName string = rg.name
output keyVaultName string = keyVault.outputs.keyVaultName
output cosmosAccountName string = cosmosDb.outputs.accountName
output cosmosEndpoint string = cosmosDb.outputs.endpoint
output storageAccountName string = storage.outputs.storageAccountName
output aiFoundryName string = aiFoundry.outputs.foundryName
output aiFoundryEndpoint string = aiFoundry.outputs.endpoint
output aiProjectName string = aiFoundry.outputs.projectName
output aiProjectEndpoint string = aiFoundry.outputs.projectEndpoint
output modelDeploymentName string = aiFoundry.outputs.modelDeploymentName
output appInsightsConnectionString string = appInsights.outputs.connectionString
output staticWebAppName string = staticWebApp.outputs.name
