@description('Azure region for Azure OpenAI')
param location string

@description('Name of the Azure OpenAI account')
param accountName string

resource openAiAccount 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: accountName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: accountName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Deploy GPT-5 model
resource gpt5Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: openAiAccount
  name: 'gpt-5'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-5-mini'
      version: '2025-08-07'
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
  }
}

output openAiId string = openAiAccount.id
output openAiName string = openAiAccount.name
output endpoint string = openAiAccount.properties.endpoint
output apiKey string = openAiAccount.listKeys().key1
output deploymentName string = gpt5Deployment.name
