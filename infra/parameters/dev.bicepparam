using '../main.bicep'

param environment = 'dev'
param location = 'eastus'
param baseName = 'browsing-companion'
// Note: principalId must be provided at deployment time via --parameters principalId=<your-object-id>
// You can get your object ID by running: az ad signed-in-user show --query id -o tsv
