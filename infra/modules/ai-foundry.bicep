@description('Azure region for AI Foundry resources')
param location string

@description('Name of the AI Foundry workspace')
param foundryName string

@description('Name of the AI Foundry project')
param projectName string

@description('Resource ID of the Storage Account')
param storageAccountId string

@description('Resource ID of the Key Vault')
param keyVaultId string

@description('Resource ID of the Application Insights')
param appInsightsId string

@description('Resource ID of the Azure OpenAI account')
param openAiId string

// AI Foundry Workspace (formerly Hub)
resource aiFoundry 'Microsoft.MachineLearningServices/workspaces@2025-09-01' = {
  name: foundryName
  location: location
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: foundryName
    description: 'AI Foundry Workspace for Browsing Companion'
    storageAccount: storageAccountId
    keyVault: keyVaultId
    applicationInsights: appInsightsId
    publicNetworkAccess: 'Enabled'
  }
}

// AI Foundry Project
resource aiProject 'Microsoft.MachineLearningServices/workspaces@2025-09-01' = {
  name: projectName
  location: location
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: projectName
    description: 'AI Foundry Project for Browsing Companion'
    hubResourceId: aiFoundry.id
  }
}

// Connection to Azure OpenAI
resource openAiConnection 'Microsoft.MachineLearningServices/workspaces/connections@2025-09-01' = {
  parent: aiFoundry
  name: 'aoai-connection'
  properties: {
    category: 'AzureOpenAI'
    target: reference(openAiId, '2025-09-01').properties.endpoint
    authType: 'AAD'
  }
}

output foundryId string = aiFoundry.id
output foundryName string = aiFoundry.name
output projectId string = aiProject.id
output projectName string = aiProject.name
output foundryPrincipalId string = aiFoundry.identity.principalId
output projectPrincipalId string = aiProject.identity.principalId
