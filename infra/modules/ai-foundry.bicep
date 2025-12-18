@description('Azure region for AI Foundry resources')
param location string

@description('Name of the AI Foundry account')
param foundryName string

@description('Name of the AI Foundry project')
param projectName string

@description('Model deployment name')
param modelDeploymentName string = 'gpt-4o-mini'

@description('Model version')
param modelVersion string = '2024-07-18'

@description('Model capacity (tokens per minute in thousands)')
param modelCapacity int = 30

@description('Embedding model deployment name')
param embeddingDeploymentName string = 'text-embedding-3-small'

@description('Embedding model version')
param embeddingModelVersion string = '1'

@description('Embedding model capacity (tokens per minute in thousands)')
param embeddingCapacity int = 30

// AI Foundry Account (new pattern using CognitiveServices/accounts with allowProjectManagement)
resource aiFoundry 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: foundryName
  location: location
  tags: {
    displayName: 'Browsing Companion AI Foundry'
    description: 'Microsoft Foundry resource for Browsing Companion application'
  }
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    apiProperties: {}
    customSubDomainName: foundryName
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    allowProjectManagement: true
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    restore: true
  }
}

// AI Foundry Project (child resource of the account)
resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  parent: aiFoundry
  name: projectName
  location: location
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: 'Browsing Companion AI Project'
    displayName: projectName
  }
}

// Model Deployment (GPT-4o-mini at Foundry level)
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: aiFoundry
  name: modelDeploymentName
  sku: {
    name: 'GlobalStandard'
    capacity: modelCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o-mini'
      version: modelVersion
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    currentCapacity: modelCapacity
    // Use default RAI policy (automatically applied, no need to specify)
  }
}

// Model Deployment (Text Embedding 3 Small)
resource embeddingDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: aiFoundry
  name: embeddingDeploymentName
  sku: {
    name: 'Standard' 
    capacity: embeddingCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'text-embedding-3-small'
      version: embeddingModelVersion
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    currentCapacity: embeddingCapacity
  }
}

// Note: Microsoft.DefaultV2 is a system-managed RAI policy that is automatically applied.
// We don't need to create or specify it - it's the default content safety policy.

// Outputs
output foundryId string = aiFoundry.id
output foundryName string = aiFoundry.name
output projectId string = aiProject.id
output projectName string = aiProject.name
output foundryPrincipalId string = aiFoundry.identity.principalId
output projectPrincipalId string = aiProject.identity.principalId
output endpoint string = aiFoundry.properties.endpoint
output projectEndpoint string = 'https://${foundryName}.cognitiveservices.azure.com/agents/v1.0/projects/${projectName}'
output modelDeploymentName string = modelDeployment.name
output embeddingDeploymentName string = embeddingDeployment.name
