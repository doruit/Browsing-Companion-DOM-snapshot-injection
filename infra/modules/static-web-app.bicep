param location string
param staticWebAppName string

resource staticWebApp 'Microsoft.Web/staticSites@2021-02-01' = {
  name: staticWebAppName
  location: location
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {
    allowConfigFileUpdates: true
    stagingEnvironmentPolicy: 'Enabled'
    enterpriseGradeCdnStatus: 'Disabled'
  }
}

output name string = staticWebApp.name
