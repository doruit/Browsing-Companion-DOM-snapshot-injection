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

// Deploy GPT-4o-mini model
resource gpt4oMiniDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: openAiAccount
  name: 'gpt-4o-mini'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o-mini'
      version: '2024-07-18'
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
  }
}

output openAiId string = openAiAccount.id
output openAiName string = openAiAccount.name
output endpoint string = openAiAccount.properties.endpoint
output apiKey string = openAiAccount.listKeys().key1
output deploymentName string = gpt4oMiniDeployment.name
