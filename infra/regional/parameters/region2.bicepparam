using '../main.bicep'

// Copy region1.bicepparam and use a non-overlapping address plan for region 2.
param namePrefix = 'FILL_IN_REGION2_PREFIX'
param location = 'FILL_IN_AZURE_REGION'
param frontDoorPrivateLinkLocation = 'FILL_IN_SUPPORTED_PRIVATE_LINK_LOCATION'
param originHostName = 'FILL_IN_REGION2_ORIGIN_TLS_HOSTNAME'
