@description('Name of the Key Vault')
param keyVaultName string

@description('Cosmos DB connection string')
@secure()
param cosmosConnectionString string

@description('Azure OpenAI endpoint')
param openaiEndpoint string

@description('Azure OpenAI API key')
@secure()
param openaiKey string

@description('Storage connection string')
@secure()
param storageConnectionString string

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

resource openaiEndpointSecret 'Microsoft.KeyVault/vaults/secrets@2025-05-01' = {
  parent: keyVault
  name: 'openai-endpoint'
  properties: {
    value: openaiEndpoint
  }
}

resource openaiKeySecret 'Microsoft.KeyVault/vaults/secrets@2025-05-01' = {
  parent: keyVault
  name: 'openai-api-key'
  properties: {
    value: openaiKey
  }
}

resource storageSecret 'Microsoft.KeyVault/vaults/secrets@2025-05-01' = {
  parent: keyVault
  name: 'storage-connection-string'
  properties: {
    value: storageConnectionString
  }
}
