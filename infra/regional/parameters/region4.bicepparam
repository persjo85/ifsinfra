using '../main.bicep'

// Copy region1.bicepparam and use a non-overlapping address plan for region 4.
param namePrefix = 'FILL_IN_REGION4_PREFIX'
param location = 'FILL_IN_AZURE_REGION'
param globalManagementVnetId = 'FILL_IN_GLOBAL_MANAGEMENT_VNET_RESOURCE_ID'
param globalJumpPrivateIp = 'FILL_IN_GLOBAL_JUMPSERVER_PRIVATE_IP'
param frontDoorPrivateLinkLocation = 'FILL_IN_SUPPORTED_PRIVATE_LINK_LOCATION'
param originHostName = 'FILL_IN_REGION4_ORIGIN_TLS_HOSTNAME'
