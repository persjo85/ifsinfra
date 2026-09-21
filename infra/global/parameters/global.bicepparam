using './main.bicep'

// Deploy once. Copy to a local parameter file and replace every FILL_IN value.
param namePrefix = 'FILL_IN_GLOBAL_PREFIX'
param workspaceId = 'FILL_IN_LOG_ANALYTICS_WORKSPACE_RESOURCE_ID'
param origins = [
  {
    // Copy `frontDoorOrigin` from the regional deployment output.
    regionCode: 'region1'
    privateLinkServiceId: 'FILL_IN_REGION1_PRIVATE_LINK_SERVICE_RESOURCE_ID'
    privateLinkLocation: 'FILL_IN_SUPPORTED_PRIVATE_LINK_LOCATION'
    hostName: 'FILL_IN_REGION1_ORIGIN_TLS_HOSTNAME'
    originHostHeader: ''
    priority: 1
    weight: 1000
    enabled: true
  }
]
