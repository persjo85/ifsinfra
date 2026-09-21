targetScope = 'resourceGroup'

param namePrefix string
param location string
param network object
param skus object
param sshPublicKey string
param adminUsername string
param vmImage object
param osDiskSizeGb int?
param availabilitySetFaultDomains int
param appBackendPort int
param appPeerTcpPorts array
param healthProbePath string
param jumpPrivateIp string
param globalManagementVnetId string
@secure()
param mysqlAdministratorPassword string
param mysqlAdministratorLogin string
param mysqlVersion string
param mysqlStorageGb int
param mysqlHaMode string
param mysqlPrimaryZone string
param mysqlStandbyZone string
param mysqlBackupRetentionDays int
param mysqlGeoRedundantBackupEnabled bool
param mysqlDatabaseName string
param mysqlEntraReady bool
param mysqlEntraAdmin object
param mysqlEntraOnly bool
param tags object

var appIp01 = cidrHost(network.app_subnet, 9)
var appIp02 = cidrHost(network.app_subnet, 10)
var lbIp = cidrHost(network.app_subnet, 4)
var plsNatIp = cidrHost(network.pls_subnet, 4)
var vmNames = [ 'vm-${namePrefix}-app-01', 'vm-${namePrefix}-app-02' ]
var loadBalancerName = 'ilb-${namePrefix}-app'
// Azure's Bicep type model does not permit a computed port-list inside an NSG
// rule object. Keep the default deny posture; add named peer rules deliberately
// after deciding which application ports are required.
var appPeerRules = []

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-${namePrefix}-app'
  location: location
  tags: tags
  properties: {
    addressSpace: { addressPrefixes: [ network.regional_vnet ] }
  }
}
resource regionalToManagement 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: vnet
  name: 'peer-app-to-global-management'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: false, allowGatewayTransit: false, useRemoteGateways: false, remoteVirtualNetwork: { id: globalManagementVnetId } }
}
resource appNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-${namePrefix}-app'
  location: location
  tags: tags
  properties: {
    securityRules: concat([
      { name: 'Allow-PLS-to-App', properties: { priority: 100, direction: 'Inbound', access: 'Allow', protocol: 'Tcp', sourcePortRange: '*', destinationPortRange: string(appBackendPort), sourceAddressPrefix: '${plsNatIp}/32', destinationAddressPrefix: network.app_subnet } }
      { name: 'Allow-LoadBalancer-Probe', properties: { priority: 110, direction: 'Inbound', access: 'Allow', protocol: 'Tcp', sourcePortRange: '*', destinationPortRange: string(appBackendPort), sourceAddressPrefix: 'AzureLoadBalancer', destinationAddressPrefix: network.app_subnet } }
      { name: 'Allow-Jump-SSH-and-HealthTest', properties: { priority: 120, direction: 'Inbound', access: 'Allow', protocol: 'Tcp', sourcePortRange: '*', destinationPortRanges: [ '22', string(appBackendPort) ], sourceAddressPrefix: '${jumpPrivateIp}/32', destinationAddressPrefix: network.app_subnet } }
    ], appPeerRules, [
      { name: 'Deny-All-Other-Inbound', properties: { priority: 4096, direction: 'Inbound', access: 'Deny', protocol: '*', sourcePortRange: '*', destinationPortRange: '*', sourceAddressPrefix: '*', destinationAddressPrefix: '*' } }
    ])
  }
}
resource peNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-${namePrefix}-pe'
  location: location
  tags: tags
  properties: { securityRules: [
    { name: 'Allow-App-and-Jump-HTTPS', properties: { priority: 100, direction: 'Inbound', access: 'Allow', protocol: 'Tcp', sourcePortRange: '*', destinationPortRange: '443', sourceAddressPrefixes: [ network.app_subnet, '${jumpPrivateIp}/32' ], destinationAddressPrefix: network.private_endpoints_subnet } }
    { name: 'Deny-All-Other-Inbound', properties: { priority: 4096, direction: 'Inbound', access: 'Deny', protocol: '*', sourcePortRange: '*', destinationPortRange: '*', sourceAddressPrefix: '*', destinationAddressPrefix: '*' } }
  ] }
}
resource appSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet
  name: 'snet-app'
  properties: { addressPrefix: network.app_subnet, defaultOutboundAccess: false, networkSecurityGroup: { id: appNsg.id }, natGateway: { id: natGateway.id } }
}
resource mysqlSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet
  name: 'snet-mysql'
  properties: { addressPrefix: network.mysql_subnet, serviceEndpoints: [ { service: 'Microsoft.Storage' } ], delegations: [ { name: 'mysql-flexible-server', properties: { serviceName: 'Microsoft.DBforMySQL/flexibleServers' } } ] }
}
resource plsSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet
  name: 'snet-pls'
  properties: { addressPrefix: network.pls_subnet, privateLinkServiceNetworkPolicies: 'Disabled', defaultOutboundAccess: false }
}
resource peSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet
  name: 'snet-private-endpoints'
  properties: { addressPrefix: network.private_endpoints_subnet, privateEndpointNetworkPolicies: 'NetworkSecurityGroupEnabled', defaultOutboundAccess: false, networkSecurityGroup: { id: peNsg.id } }
}
resource egressPip 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: 'pip-${namePrefix}-egress'
  location: location
  sku: { name: 'Standard' }
  tags: tags
  properties: { publicIPAllocationMethod: 'Static', publicIPAddressVersion: 'IPv4' }
}
resource natGateway 'Microsoft.Network/natGateways@2024-05-01' = {
  name: 'nat-${namePrefix}-app'
  location: location
  sku: { name: 'Standard' }
  tags: tags
  properties: { publicIpAddresses: [ { id: egressPip.id } ] }
}
resource availabilitySet 'Microsoft.Compute/availabilitySets@2024-03-01' = {
  name: 'avset-${namePrefix}-app'
  location: location
  tags: tags
  sku: { name: 'Aligned' }
  properties: { platformFaultDomainCount: availabilitySetFaultDomains, platformUpdateDomainCount: 5 }
}
resource appNics 'Microsoft.Network/networkInterfaces@2024-05-01' = [for (suffix, index) in [ '01', '02' ]: {
  name: 'nic-${namePrefix}-app-${suffix}'
  location: location
  tags: tags
  properties: { ipConfigurations: [ { name: 'primary', properties: { privateIPAllocationMethod: 'Static', privateIPAddress: index == 0 ? appIp01 : appIp02, subnet: { id: appSubnet.id } } } ] }
}]
resource appVms 'Microsoft.Compute/virtualMachines@2024-03-01' = [for (suffix, index) in [ '01', '02' ]: {
  name: vmNames[index]
  location: location
  tags: tags
  identity: { type: 'SystemAssigned' }
  properties: {
    hardwareProfile: { vmSize: skus.app_vm }
    availabilitySet: { id: availabilitySet.id }
    networkProfile: { networkInterfaces: [ { id: appNics[index].id, properties: { primary: true } } ] }
    osProfile: { computerName: vmNames[index], adminUsername: adminUsername, linuxConfiguration: { disablePasswordAuthentication: true, ssh: { publicKeys: [ { path: '/home/${adminUsername}/.ssh/authorized_keys', keyData: sshPublicKey } ] } }, patchSettings: { patchMode: 'ImageDefault', assessmentMode: 'AutomaticByPlatform' } }
    storageProfile: { imageReference: vmImage, osDisk: union({ name: 'osdisk-${namePrefix}-app-${suffix}', createOption: 'FromImage', caching: 'ReadWrite', managedDisk: { storageAccountType: skus.os_disk } }, osDiskSizeGb == null ? {} : { diskSizeGB: osDiskSizeGb }) }
    diagnosticsProfile: { bootDiagnostics: { enabled: true } }
  }
}]
resource entraSsh 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = [for (suffix, index) in [ '01', '02' ]: {
  parent: appVms[index]
  name: 'AADSSHLoginForLinux'
  location: location
  properties: { publisher: 'Microsoft.Azure.ActiveDirectory', type: 'AADSSHLoginForLinux', typeHandlerVersion: '1.0', autoUpgradeMinorVersion: true }
}]
resource loadBalancer 'Microsoft.Network/loadBalancers@2024-05-01' = {
  name: loadBalancerName
  location: location
  sku: { name: 'Standard' }
  tags: tags
  properties: {
    frontendIPConfigurations: [ { name: 'private-https', properties: { privateIPAddress: lbIp, privateIPAllocationMethod: 'Static', subnet: { id: appSubnet.id } } } ]
    backendAddressPools: [ { name: 'app-nics', properties: {} } ]
    probes: [ { name: 'https-health', properties: { protocol: 'Https', port: appBackendPort, requestPath: healthProbePath, intervalInSeconds: 15, numberOfProbes: 2 } } ]
    loadBalancingRules: [ { name: 'https', properties: { protocol: 'Tcp', frontendPort: 443, backendPort: appBackendPort, frontendIPConfiguration: { id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, 'private-https') }, backendAddressPool: { id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, 'app-nics') }, probe: { id: resourceId('Microsoft.Network/loadBalancers/probes', loadBalancerName, 'https-health') }, enableTcpReset: true, disableOutboundSnat: true } } ]
  }
}
resource pls 'Microsoft.Network/privateLinkServices@2024-05-01' = {
  name: 'pls-${namePrefix}-app'
  location: location
  tags: tags
  properties: { loadBalancerFrontendIpConfigurations: [ { id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, 'private-https') } ], visibility: { subscriptions: [ subscription().subscriptionId ] }, enableProxyProtocol: false, ipConfigurations: [ { name: 'primary', properties: { privateIPAllocationMethod: 'Static', privateIPAddress: plsNatIp, subnet: { id: plsSubnet.id }, primary: true } } ] }
}
resource mysqlIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = { name: 'id-${namePrefix}-mysql', location: location, tags: tags }
resource mysqlDns 'Microsoft.Network/privateDnsZones@2024-06-01' = { name: '${namePrefix}.mysql.database.azure.com', location: 'global', tags: tags }
resource mysqlRegionalDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = { parent: mysqlDns, name: 'link-regional', location: 'global', tags: tags, properties: { virtualNetwork: { id: vnet.id }, registrationEnabled: false } }
resource mysqlServer 'Microsoft.DBforMySQL/flexibleServers@2023-12-30' = {
  name: 'mysql-${namePrefix}'
  location: location
  sku: { name: skus.mysql, tier: startsWith(skus.mysql, 'MO_') ? 'MemoryOptimized' : 'GeneralPurpose' }
  tags: tags
  identity: { type: 'UserAssigned', userAssignedIdentities: { '${mysqlIdentity.id}': {} } }
  properties: {
    version: mysqlVersion
    administratorLogin: mysqlAdministratorLogin
    administratorLoginPassword: mysqlAdministratorPassword
    network: { delegatedSubnetResourceId: mysqlSubnet.id, privateDnsZoneResourceId: mysqlDns.id }
    backup: { backupRetentionDays: mysqlBackupRetentionDays, geoRedundantBackup: mysqlGeoRedundantBackupEnabled ? 'Enabled' : 'Disabled' }
    highAvailability: { mode: mysqlHaMode, standbyAvailabilityZone: mysqlStandbyZone }
    storage: { storageSizeGB: mysqlStorageGb, autoGrow: 'Enabled' }
    availabilityZone: mysqlPrimaryZone
  }
  dependsOn: [ mysqlRegionalDnsLink ]
}
resource mysqlDatabase 'Microsoft.DBforMySQL/flexibleServers/databases@2023-12-30' = { parent: mysqlServer, name: mysqlDatabaseName, properties: { charset: 'utf8mb4', collation: 'utf8mb4_unicode_ci' } }
resource mysqlTls 'Microsoft.DBforMySQL/flexibleServers/configurations@2023-12-30' = { parent: mysqlServer, name: 'require_secure_transport', properties: { value: 'ON', source: 'user-override' } }
resource mysqlSlowLog 'Microsoft.DBforMySQL/flexibleServers/configurations@2023-12-30' = { parent: mysqlServer, name: 'slow_query_log', properties: { value: 'ON', source: 'user-override' } }
resource mysqlAuditLog 'Microsoft.DBforMySQL/flexibleServers/configurations@2023-12-30' = { parent: mysqlServer, name: 'audit_log_enabled', properties: { value: 'ON', source: 'user-override' } }
resource mysqlAuditEvents 'Microsoft.DBforMySQL/flexibleServers/configurations@2023-12-30' = { parent: mysqlServer, name: 'audit_log_events', properties: { value: 'CONNECTION', source: 'user-override' } }

output vnetId string = vnet.id
output privateEndpointSubnetId string = peSubnet.id
output appVmIds array = [for i in range(0, 2): appVms[i].id]
output appVmPrincipalIds array = [for i in range(0, 2): appVms[i].identity.principalId]
output appVms array = [for i in range(0, 2): { name: appVms[i].name, resourceGroupName: resourceGroup().name, privateIp: i == 0 ? appIp01 : appIp02, principalId: appVms[i].identity.principalId }]
output loadBalancerId string = loadBalancer.id
output loadBalancerPrivateIp string = lbIp
output outboundPublicIp string = egressPip.properties.ipAddress
output privateLinkServiceId string = pls.id
output mysqlServerId string = mysqlServer.id
output mysqlPrivateDnsZoneId string = mysqlDns.id
output mysql object = { name: mysqlServer.name, fqdn: mysqlServer.properties.fullyQualifiedDomainName, database: mysqlDatabase.name, resourceGroupName: resourceGroup().name, identityName: mysqlIdentity.name, identityPrincipalId: mysqlIdentity.properties.principalId, identityClientId: mysqlIdentity.properties.clientId, entraAuthenticationReady: mysqlEntraReady }
