param location string
param appName string
param serverFarmId string
param linuxFxVersion string
param appCommandLine string = ''
param appSettings array = []

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: appName
  location: location
  properties: {
    serverFarmId: serverFarmId
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      appCommandLine: appCommandLine
      appSettings: appSettings
      alwaysOn: false // Free/Basic tier might not support AlwaysOn or we want to save cost. Set to true if B1+.
    }
    httpsOnly: true
  }
}

output name string = webApp.name
output defaultHostName string = webApp.properties.defaultHostName
