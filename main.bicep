@description('Name prefix when using default names')
param namePrefix string = 'pssample'

// VNet parameters
@description('Name used when creating a new VNet')
param vnetName string = '${namePrefix}-vnet'
@description('Address space used when creating a new VNet')
param vnetAddressSpace string = '10.5.0.0/16'
@description('Storage subnet when creating a new VNet')
param storageSubnet string = '10.5.1.0/24'
@description('Function subnet when creating a new VNet')
param functionSubnet string = '10.5.2.0/24'
// To use an existing VNet, set the following parameter to false and set the next parameters to the proper values
@description('Switch to deploy a new VNet or use an existing one')
param deployVNet bool = true
@description('VNet Id used when using an existing VNet')
param existingVnetId string = ''
@description('Storage subnet Id used when using an existing VNet')
param existingStorageSubnetId string = ''
@description('Function subnet Id used when using an existing VNet')
param existingFunctionSubnetId string = ''

// Storage parameters
@description('SKU name used when creating a new storage account')
param storageSKUName string = 'Standard_LRS'
@description('SKU tier used when creating a new storage account')
param storageSKUTier string = 'Standard'
@description('Storage endpoints to expose through private link when creating a new storage account')
param storageEndpoints array = [ 
  'blob'
  'file'
  'queue'
  'table'
]
// To use an existing storage account, set the following parameter to false and set the next parameters to the proper values
@description('Switch to deploy a new storage account or use an existing one')
param deployStorage bool = true
@description('Name used when creating a new storage account or using an existing one')
param storageAccountName string = '${namePrefix}storage'
@description('Resource group name used when using an existing storage account')
param existingStorageAccountRG string = ''

// App Service/Function parameters
@description('Name of the App Service plan')
param appServicePlanName string = '${namePrefix}-plan'
@description('SKU of the App Service plan')
param appServicePlanSKU string = 'S1'
@description('Name of the Function')
param functionName string = '${namePrefix}-function'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = if (deployVNet) {
  name: vnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    subnets: [
      {
        name: 'storage'
        properties: {
          addressPrefix: storageSubnet
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'function'
        properties: {
          addressPrefix: functionSubnet
          delegations: [
            {
              name: 'appService'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]          
        }
      }
    ]
  }
}

module storageModule './private-storage.bicep' = if (deployStorage) {  
  name: 'private-storage'
  params: {
    name: storageAccountName
    skuName: storageSKUName
    skuTier: storageSKUTier
    vnetId: deployVNet ? virtualNetwork.id : existingVnetId
    subnetId: deployVNet ? virtualNetwork.properties.subnets[0].id : existingStorageSubnetId
    endpoints: storageEndpoints
  }
}

module functionModule './function.bicep' = {  
  name: 'function'
  dependsOn: [
    storageModule
  ]
  params: {
    storageAccountName: storageAccountName
    storageAccountResourceGroup: deployStorage ? resourceGroup().name : existingStorageAccountRG
    appServicePlanName: appServicePlanName
    appServicePlanSKU: appServicePlanSKU
    functionName: functionName
    functionSubnetId: deployVNet ? virtualNetwork.properties.subnets[1].id : existingFunctionSubnetId
  }
}
