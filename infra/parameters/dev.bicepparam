using '../main.bicep'

param environment = 'dev'
param location = 'westus'  // West US has better AI Foundry support
param baseName = 'browsercompdom'  // Short name for storage account compatibility
param modelDeploymentName = 'gpt-4o-mini'
param principalId = '1d18bbec-ccea-4818-8f94-1e2f80306df1'
param resourceGroupName = 'rg-browser-companion-DOM-method'
