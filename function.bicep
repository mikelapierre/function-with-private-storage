@description('Name of the storage account')
param storageAccountName string
@description('Resource group name of the storage account')
param storageAccountResourceGroup string
@description('Name of the App Service plan')
param appServicePlanName string
@description('SKU of the App Service plan')
param appServicePlanSKU string
@description('Name of the Function')
param functionName string
@description('Subnet Id to link with the Function')
param functionSubnetId string

resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: appServicePlanName
  location: resourceGroup().location
  sku: {
    name: appServicePlanSKU
    capacity: 1
  }
}

resource azureFunction 'Microsoft.Web/sites@2020-12-01' = {
  name: functionName
  location: resourceGroup().location
  kind: 'functionapp'
  properties: {
    serverFarmId: resourceId('Microsoft.Web/serverfarms', appServicePlan.name)
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(resourceId(storageAccountResourceGroup, 'Microsoft.Storage/storageAccounts', storageAccountName), '2019-06-01').keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
      ]
    }    
    virtualNetworkSubnetId: functionSubnetId
  }
}
