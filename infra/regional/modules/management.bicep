targetScope = 'resourceGroup'
param namePrefix string
param location string
param network object
param skus object
param sshPublicKey string
param adminUsername string
param vmImage object
param osDiskSizeGb int?
param adminSourceCidrs array
param tags object
param regionalVnetId string
var jumpIp = cidrHost(network.jump_subnet, 4)
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = { name: 'vnet-${namePrefix}-mgmt', location: location, tags: tags, properties: { addressSpace: { addressPrefixes: [ network.management_vnet ] } } }
resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-${namePrefix}-jump'
  location: location
  tags: tags
  properties: { securityRules: [
    { name: 'Allow-Approved-Admin-SSH', properties: { priority: 100, direction: 'Inbound', access: 'Allow', protocol: 'Tcp', sourcePortRange: '*', destinationPortRange: '22', sourceAddressPrefixes: adminSourceCidrs, destinationAddressPrefix: '${jumpIp}/32' } }
    { name: 'Deny-All-Other-Inbound', properties: { priority: 4096, direction: 'Inbound', access: 'Deny', protocol: '*', sourcePortRange: '*', destinationPortRange: '*', sourceAddressPrefix: '*', destinationAddressPrefix: '*' } }
  ] }
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = { parent: vnet, name: 'snet-jump', properties: { addressPrefix: network.jump_subnet, defaultOutboundAccess: false, networkSecurityGroup: { id: nsg.id } } }
resource managementToRegional 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = { parent: vnet, name: 'peer-mgmt-to-app', properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: false, allowGatewayTransit: false, useRemoteGateways: false, remoteVirtualNetwork: { id: regionalVnetId } } }
resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = { name: 'pip-${namePrefix}-jump', location: location, sku: { name: 'Standard' }, tags: tags, properties: { publicIPAllocationMethod: 'Static', publicIPAddressVersion: 'IPv4' } }
resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = { name: 'nic-${namePrefix}-jump', location: location, tags: tags, properties: { ipConfigurations: [ { name: 'primary', properties: { privateIPAllocationMethod: 'Static', privateIPAddress: jumpIp, subnet: { id: subnet.id }, publicIPAddress: { id: pip.id } } } ] } }
resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: 'vm-${namePrefix}-jump'
  location: location
  tags: tags
  identity: { type: 'SystemAssigned' }
  properties: { hardwareProfile: { vmSize: skus.jump_vm }, networkProfile: { networkInterfaces: [ { id: nic.id, properties: { primary: true } } ] }, osProfile: { computerName: 'vm-${namePrefix}-jump', adminUsername: adminUsername, linuxConfiguration: { disablePasswordAuthentication: true, ssh: { publicKeys: [ { path: '/home/${adminUsername}/.ssh/authorized_keys', keyData: sshPublicKey } ] } }, patchSettings: { patchMode: 'ImageDefault', assessmentMode: 'AutomaticByPlatform' } }, storageProfile: { imageReference: vmImage, osDisk: union({ name: 'osdisk-${namePrefix}-jump', createOption: 'FromImage', caching: 'ReadWrite', managedDisk: { storageAccountType: skus.os_disk } }, osDiskSizeGb == null ? {} : { diskSizeGB: osDiskSizeGb }) }, diagnosticsProfile: { bootDiagnostics: { enabled: true } } }
}
resource entraSsh 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = { parent: vm, name: 'AADSSHLoginForLinux', location: location, properties: { publisher: 'Microsoft.Azure.ActiveDirectory', type: 'AADSSHLoginForLinux', typeHandlerVersion: '1.0', autoUpgradeMinorVersion: true } }
output vnetId string = vnet.id
output jumpVmId string = vm.id
output jump object = { name: vm.name, resourceGroupName: resourceGroup().name, publicIp: pip.properties.ipAddress, privateIp: jumpIp }
