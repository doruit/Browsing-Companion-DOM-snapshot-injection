targetScope = 'subscription'

@description('Environment name (dev, staging, prod)')
param environment string = 'dev'

@description('Azure region for all resources')
param location string = 'eastus'

@description('Base name for all resources')
param baseName string = 'browsing-companion'

@description('Your Azure AD tenant ID')
param tenantId string = subscription().tenantId

@description('Your Azure AD object ID (for Key Vault access)')
param principalId string

// Resource group
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-${baseName}-${environment}'
  location: location
  tags: {
    Environment: environment
    Project: 'BrowsingCompanion'
    ManagedBy: 'Bicep'
  }
}

// Key Vault (deploy first for secrets)
module keyVault 'modules/key-vault.bicep' = {
  scope: rg
  name: 'keyvault-deployment'
  params: {
    location: location
    keyVaultName: 'kv-${baseName}-${environment}'
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
    storageAccountName: 'st${replace(baseName, '-', '')}${environment}'
  }
}

// Cosmos DB
module cosmosDb 'modules/cosmos-db.bicep' = {
  scope: rg
  name: 'cosmosdb-deployment'
  params: {
    location: location
    accountName: 'cosmos-${baseName}-${environment}'
  }
}

// Azure OpenAI
module openai 'modules/openai.bicep' = {
  scope: rg
  name: 'openai-deployment'
  params: {
    location: location
    accountName: 'openai-${baseName}-${environment}'
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

// AI Foundry Hub and Project
module aiFoundry 'modules/ai-foundry.bicep' = {
  scope: rg
  name: 'aifoundry-deployment'
  params: {
    location: location
    hubName: 'aihub-${baseName}-${environment}'
    projectName: 'aiproject-${baseName}-${environment}'
    storageAccountId: storage.outputs.storageAccountId
    keyVaultId: keyVault.outputs.keyVaultId
    appInsightsId: appInsights.outputs.appInsightsId
    openAiId: openai.outputs.openAiId
  }
}

// Store connection strings in Key Vault
module secrets 'modules/secrets.bicep' = {
  scope: rg
  name: 'secrets-deployment'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    cosmosConnectionString: cosmosDb.outputs.connectionString
    openaiEndpoint: openai.outputs.endpoint
    openaiKey: openai.outputs.apiKey
    storageConnectionString: storage.outputs.connectionString
  }
  dependsOn: [
    keyVault
  ]
}

// Outputs
output resourceGroupName string = rg.name
output keyVaultName string = keyVault.outputs.keyVaultName
output cosmosAccountName string = cosmosDb.outputs.accountName
output cosmosEndpoint string = cosmosDb.outputs.endpoint
output openaiEndpoint string = openai.outputs.endpoint
output openaiDeploymentName string = openai.outputs.deploymentName
output storageAccountName string = storage.outputs.storageAccountName
output aiHubName string = aiFoundry.outputs.hubName
output aiProjectName string = aiFoundry.outputs.projectName
output appInsightsConnectionString string = appInsights.outputs.connectionString
