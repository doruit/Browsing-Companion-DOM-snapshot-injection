param location string
param staticWebAppName string

param appSettings object = {}

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

resource staticWebAppSettings 'Microsoft.Web/staticSites/config@2021-02-01' = {
  parent: staticWebApp
  name: 'appsettings'
  properties: appSettings
}

output name string = staticWebApp.name
