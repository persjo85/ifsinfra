targetScope = 'resourceGroup'

@description('Deploy this file once for shared/global services, never once per region.')
param namePrefix string
@description('The approved Private Link Service resource ID from a regional deployment.')
param privateLinkServiceId string
@description('The Log Analytics workspace resource ID used by Front Door diagnostics.')
param workspaceId string
param healthProbePath string = '/healthz'
param privateLinkLocation string
param originHostName string
param originHostHeader string = ''
param customDomainName string = ''
param customDomainReady bool = false
param enablePublicRoute bool = false
param allowDefaultFrontdoorDomain bool = false
@allowed([ 'Prevention', 'Detection' ])
param wafMode string = 'Prevention'
param tags object = {}

module frontDoor 'modules/front-door.bicep' = {
  name: 'global-front-door'
  params: {
    namePrefix: namePrefix
    privateLinkServiceId: privateLinkServiceId
    healthProbePath: healthProbePath
    privateLinkLocation: privateLinkLocation
    originHostName: originHostName
    originHostHeader: originHostHeader
    customDomainName: customDomainName
    customDomainReady: customDomainReady
    enablePublicRoute: enablePublicRoute
    allowDefaultFrontdoorDomain: allowDefaultFrontdoorDomain
    wafMode: wafMode
    workspaceId: workspaceId
    tags: union(tags, { managed_by: 'Bicep', deployment: namePrefix, scope: 'global' })
  }
}

output frontDoor object = frontDoor.outputs.frontDoor
