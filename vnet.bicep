@description('Name of the VNet')
param name string
@description('Address space of the VNet')
param addressSpace string
@description('Subnets for the VNet')
param subnets array

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: name
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    subnets: subnets
  }
}

output vnetId string = virtualNetwork.id
output subnets array = virtualNetwork.properties.subnets
