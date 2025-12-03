@description('Name of the Key Vault')
param keyVaultName string

@description('Cosmos DB connection string')
@secure()
param cosmosConnectionString string

@description('Storage connection string')
@secure()
param storageConnectionString string

@description('AI Foundry endpoint')
param aiFoundryEndpoint string

@description('AI Foundry project endpoint for Agent Service')
param aiFoundryProjectEndpoint string

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: keyVaultName
}

resource cosmosSecret 'Microsoft.KeyVault/vaults/secrets@2025-05-01' = {
  parent: keyVault
  name: 'cosmos-connection-string'
  properties: {
    value: cosmosConnectionString
  }
}

resource storageSecret 'Microsoft.KeyVault/vaults/secrets@2025-05-01' = {
  parent: keyVault
  name: 'storage-connection-string'
  properties: {
    value: storageConnectionString
  }
}

resource aiFoundryEndpointSecret 'Microsoft.KeyVault/vaults/secrets@2025-05-01' = {
  parent: keyVault
  name: 'ai-foundry-endpoint'
  properties: {
    value: aiFoundryEndpoint
  }
}

resource aiFoundryProjectEndpointSecret 'Microsoft.KeyVault/vaults/secrets@2025-05-01' = {
  parent: keyVault
  name: 'ai-foundry-project-endpoint'
  properties: {
    value: aiFoundryProjectEndpoint
  }
}
