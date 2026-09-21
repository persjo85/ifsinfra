targetScope = 'subscription'

@description('Resource group containing global Front Door/WAF and the shared jumpserver.')
param globalResourceGroupName string
param globalLocation string
param namePrefix string
param managementNetwork object
param jumpVmSize string
param osDiskSku string
param sshPublicKey string
param adminSourceCidrs array
param adminUsername string = 'provisionadmin'
param vmImage object = {
  publisher: 'Canonical'
  offer: 'ubuntu-24_04-lts'
  sku: 'server'
  version: 'latest'
}
@description('Regional connectivity and Front Door origins. Add one object per deployed region.')
param regions array = []
param workspaceId string
param healthProbePath string = '/healthz'
param customDomainName string = ''
param customDomainReady bool = false
param enablePublicRoute bool = false
param allowDefaultFrontdoorDomain bool = false
@allowed([ 'Prevention', 'Detection' ])
param wafMode string = 'Prevention'
param tags object = {}

var commonTags = union(tags, { managed_by: 'Bicep', deployment: namePrefix, scope: 'global' })

resource globalRg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: globalResourceGroupName
  location: globalLocation
  tags: commonTags
}

module management 'modules/management.bicep' = {
  name: 'global-management'
  scope: globalRg
  params: {
    namePrefix: namePrefix
    location: globalLocation
    managementNetwork: managementNetwork
    jumpVmSize: jumpVmSize
    osDiskSku: osDiskSku
    sshPublicKey: sshPublicKey
    adminUsername: adminUsername
    vmImage: vmImage
    adminSourceCidrs: adminSourceCidrs
    regions: regions
    tags: commonTags
  }
}

module mysqlDnsLink '../regional/modules/mysql-dns-link.bicep' = [for region in regions: {
  name: 'management-mysql-dns-${region.regionCode}'
  scope: resourceGroup(region.regionalResourceGroupName)
  params: {
    privateDnsZoneName: last(split(region.mysqlPrivateDnsZoneId, '/'))
    managementVnetId: management.outputs.managementVnetId
    linkName: 'link-global-management'
    tags: commonTags
  }
}]

module frontDoor 'modules/front-door.bicep' = {
  name: 'global-front-door'
  scope: globalRg
  params: {
    namePrefix: namePrefix
    origins: regions
    healthProbePath: healthProbePath
    customDomainName: customDomainName
    customDomainReady: customDomainReady
    enablePublicRoute: enablePublicRoute
    allowDefaultFrontdoorDomain: allowDefaultFrontdoorDomain
    wafMode: wafMode
    workspaceId: workspaceId
    tags: commonTags
  }
}

output managementVnetId string = management.outputs.managementVnetId
output jump object = management.outputs.jump
output frontDoor object = frontDoor.outputs.frontDoor
