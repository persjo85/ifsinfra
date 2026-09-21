using none
extends './management.bicepparam'

param workspaceId = 'FILL_IN_LOG_ANALYTICS_WORKSPACE_RESOURCE_ID'
param regions = [
  {
    // Copy `frontDoorOrigin` from the regional deployment output.
    regionCode: 'region1'
    regionalResourceGroupName: 'FILL_IN_REGION1_RESOURCE_GROUP'
    regionalVnetId: 'FILL_IN_REGION1_VNET_RESOURCE_ID'
    mysqlPrivateDnsZoneId: 'FILL_IN_REGION1_MYSQL_PRIVATE_DNS_ZONE_RESOURCE_ID'
    privateLinkServiceId: 'FILL_IN_REGION1_PRIVATE_LINK_SERVICE_RESOURCE_ID'
    privateLinkLocation: 'FILL_IN_SUPPORTED_PRIVATE_LINK_LOCATION'
    hostName: 'FILL_IN_REGION1_ORIGIN_TLS_HOSTNAME'
    originHostHeader: ''
    priority: 1
    weight: 1000
    enabled: true
  }
]
