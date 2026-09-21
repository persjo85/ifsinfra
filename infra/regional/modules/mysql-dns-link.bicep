targetScope = 'resourceGroup'

param privateDnsZoneName string
param managementVnetId string
param linkName string
param tags object

resource zone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: privateDnsZoneName
}

resource managementLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: zone
  name: linkName
  location: 'global'
  tags: tags
  properties: { virtualNetwork: { id: managementVnetId }, registrationEnabled: false }
}
