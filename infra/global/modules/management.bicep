targetScope = 'resourceGroup'

param namePrefix string
param location string
param managementNetwork object
param jumpVmSize string
param osDiskSku string
param sshPublicKey string
param adminUsername string
param vmImage object
param adminSourceCidrs array
param regions array
param tags object

var jumpIp = cidrHost(managementNetwork.jumpSubnet, 4)

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-${namePrefix}-mgmt'
  location: location
  tags: tags
  properties: { addressSpace: { addressPrefixes: [ managementNetwork.vnet ] } }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-${namePrefix}-jump'
  location: location
  tags: tags
  properties: { securityRules: [
    { name: 'Allow-Approved-Admin-SSH', properties: { priority: 100, direction: 'Inbound', access: 'Allow', protocol: 'Tcp', sourcePortRange: '*', destinationPortRange: '22', sourceAddressPrefixes: adminSourceCidrs, destinationAddressPrefix: '${jumpIp}/32' } }
    { name: 'Deny-All-Other-Inbound', properties: { priority: 4096, direction: 'Inbound', access: 'Deny', protocol: '*', sourcePortRange: '*', destinationPortRange: '*', sourceAddressPrefix: '*', destinationAddressPrefix: '*' } }
  ] }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet
  name: 'snet-jump'
  properties: { addressPrefix: managementNetwork.jumpSubnet, defaultOutboundAccess: false, networkSecurityGroup: { id: nsg.id } }
}

resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-${namePrefix}-jump'
  location: location
  sku: { name: 'Standard' }
  tags: tags
  properties: { publicIPAllocationMethod: 'Static', publicIPAddressVersion: 'IPv4' }
}

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: 'nic-${namePrefix}-jump'
  location: location
  tags: tags
  properties: { ipConfigurations: [ { name: 'primary', properties: { privateIPAllocationMethod: 'Static', privateIPAddress: jumpIp, subnet: { id: subnet.id }, publicIPAddress: { id: pip.id } } } ] }
}

resource jumpVm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: 'vm-${namePrefix}-jump'
  location: location
  tags: tags
  identity: { type: 'SystemAssigned' }
  properties: {
    hardwareProfile: { vmSize: jumpVmSize }
    networkProfile: { networkInterfaces: [ { id: nic.id, properties: { primary: true } } ] }
    osProfile: { computerName: 'vm-${namePrefix}-jump', adminUsername: adminUsername, linuxConfiguration: { disablePasswordAuthentication: true, ssh: { publicKeys: [ { path: '/home/${adminUsername}/.ssh/authorized_keys', keyData: sshPublicKey } ] } } }
    storageProfile: { imageReference: vmImage, osDisk: { name: 'osdisk-${namePrefix}-jump', createOption: 'FromImage', caching: 'ReadWrite', managedDisk: { storageAccountType: osDiskSku } } }
    diagnosticsProfile: { bootDiagnostics: { enabled: true } }
  }
}

resource entraSsh 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  parent: jumpVm
  name: 'AADSSHLoginForLinux'
  location: location
  properties: { publisher: 'Microsoft.Azure.ActiveDirectory', type: 'AADSSHLoginForLinux', typeHandlerVersion: '1.0', autoUpgradeMinorVersion: true }
}

resource managementToRegional 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = [for region in regions: {
  parent: vnet
  name: 'peer-mgmt-to-${region.regionCode}'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: false, allowGatewayTransit: false, useRemoteGateways: false, remoteVirtualNetwork: { id: region.regionalVnetId } }
}]

output managementVnetId string = vnet.id
output jump object = { name: jumpVm.name, resourceGroupName: resourceGroup().name, publicIp: pip.properties.ipAddress, privateIp: jumpIp }
