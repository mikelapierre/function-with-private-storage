@description('Name of the storage account')
param name string
@description('SKU name the storage account')
param skuName string
@description('SKU tier of the storage account')
param skuTier string
@description('VNet Id to link with the storage account')
param vnetId string
@description('Subnet Id to link with the storage account')
param subnetId string
@description('Storage endpoints to expose through private link')
param endpoints array

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: name
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    allowBlobPublicAccess: false
    networkAcls: {
      defaultAction: 'Deny'
    }
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = [for endpoint in endpoints: {
  name: 'privatelink.${endpoint}.${environment().suffixes.storage}'
  location: 'global'
}]

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for endpoint in endpoints: {
  name: 'privatelink.${endpoint}.${environment().suffixes.storage}/${uniqueString(vnetId)}'  
  location: 'global'
  dependsOn: [ 
    privateDnsZone 
  ]  
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}]

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = [for endpoint in endpoints: {
  name: '${name}-${endpoint}'
  location: resourceGroup().location
  properties: {
     privateLinkServiceConnections: [
      {
        name: '${name}-${endpoint}'
         properties: {
           privateLinkServiceId: storageAccount.id
           groupIds: [
             '${endpoint}'
           ]
         }
      }
     ]
     subnet: {
       id: subnetId
     }
  }
}]

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = [for endpoint in endpoints: {
  name: '${name}-${endpoint}/dnsZone'
  dependsOn: [ 
    privateEndpoint 
  ]
  properties: {    
    privateDnsZoneConfigs: [
      {
        name: 'dnsConfig'
        properties: {
          privateDnsZoneId: resourceId('Microsoft.Network/privateDnsZones', 'privatelink.${endpoint}.${environment().suffixes.storage}')
        }
      }
    ]
  }
}]
