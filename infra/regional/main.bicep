targetScope = 'subscription'

@description('Stable, globally distinctive lower-case deployment prefix.')
param namePrefix string
param location string
param managementLocation string = location
param network object
param skus object
param sshPublicKey string
param adminSourceCidrs array
param vmAdminGroupObjectIds array
param keyVaultOfficerGroupObjectIds array = []
@secure()
param mysqlAdministratorPassword string
param mysqlVersion string
param mysqlStorageGb int
param mysqlHaMode string = 'ZoneRedundant'
param mysqlPrimaryZone string = ''
param mysqlStandbyZone string = ''
param mysqlBackupRetentionDays int = 14
param mysqlGeoRedundantBackupEnabled bool = false
param mysqlDatabaseName string = 'application'
param mysqlAdministratorLogin string = 'bootstrapadmin'
param mysqlEntraReady bool = false
param mysqlEntraAdmin object = {}
param mysqlEntraOnly bool = false
param appBackendPort int = 443
param appPeerTcpPorts array = []
param healthProbePath string = '/healthz'
param availabilitySetFaultDomains int = 2
param osDiskSizeGb int?
param vmImage object = {
  publisher: 'Canonical'
  offer: 'ubuntu-24_04-lts'
  sku: 'server'
  version: 'latest'
}
param adminUsername string = 'provisionadmin'
param logRetentionDays int = 90
param tags object = {}

var regionalRgName = 'rg-${namePrefix}-regional'
var managementRgName = 'rg-${namePrefix}-management'
var sharedRgName = 'rg-${namePrefix}-shared'
var commonTags = union(tags, { managed_by: 'Bicep', deployment: namePrefix })

resource regionalRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: regionalRgName
  location: location
  tags: commonTags
}
resource managementRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: managementRgName
  location: managementLocation
  tags: commonTags
}

module regional 'modules/network.bicep' = {
  name: 'regional-platform'
  scope: regionalRg
  params: {
    namePrefix: namePrefix
    location: location
    network: network
    skus: skus
    sshPublicKey: sshPublicKey
    adminUsername: adminUsername
    vmImage: vmImage
    osDiskSizeGb: osDiskSizeGb
    availabilitySetFaultDomains: availabilitySetFaultDomains
    appBackendPort: appBackendPort
    appPeerTcpPorts: appPeerTcpPorts
    healthProbePath: healthProbePath
    jumpPrivateIp: cidrHost(network.jump_subnet, 4)
    mysqlAdministratorPassword: mysqlAdministratorPassword
    mysqlAdministratorLogin: mysqlAdministratorLogin
    mysqlVersion: mysqlVersion
    mysqlStorageGb: mysqlStorageGb
    mysqlHaMode: mysqlHaMode
    mysqlPrimaryZone: mysqlPrimaryZone
    mysqlStandbyZone: mysqlStandbyZone
    mysqlBackupRetentionDays: mysqlBackupRetentionDays
    mysqlGeoRedundantBackupEnabled: mysqlGeoRedundantBackupEnabled
    mysqlDatabaseName: mysqlDatabaseName
    mysqlEntraReady: mysqlEntraReady
    mysqlEntraAdmin: mysqlEntraAdmin
    mysqlEntraOnly: mysqlEntraOnly
    tags: commonTags
  }
}

module management 'modules/management.bicep' = {
  name: 'management-platform'
  scope: managementRg
  params: {
    namePrefix: namePrefix
    location: managementLocation
    network: network
    skus: skus
    sshPublicKey: sshPublicKey
    adminUsername: adminUsername
    vmImage: vmImage
    osDiskSizeGb: osDiskSizeGb
    adminSourceCidrs: adminSourceCidrs
    tags: commonTags
    regionalVnetId: regional.outputs.vnetId
  }
}

output resourceGroups object = { regional: regionalRg.name, management: managementRg.name }
output jump object = management.outputs.jump
output appVms array = regional.outputs.appVms
output loadBalancerPrivateIp string = regional.outputs.loadBalancerPrivateIp
output outboundPublicIp string = regional.outputs.outboundPublicIp
output mysql object = regional.outputs.mysql
output privateLinkServiceId string = regional.outputs.privateLinkServiceId
