using './main.bicep'

// Deploy once. Copy to a local parameter file and replace every FILL_IN value.
param namePrefix = 'FILL_IN_GLOBAL_PREFIX'
param privateLinkServiceId = 'FILL_IN_REGIONAL_PRIVATE_LINK_SERVICE_RESOURCE_ID'
param workspaceId = 'FILL_IN_LOG_ANALYTICS_WORKSPACE_RESOURCE_ID'
param privateLinkLocation = 'FILL_IN_SUPPORTED_PRIVATE_LINK_LOCATION'
param originHostName = 'FILL_IN_ORIGIN_TLS_HOSTNAME'
