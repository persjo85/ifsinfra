using none
extends './mysql.bicepparam'

param appBackendPort = 443
param healthProbePath = '/healthz'
param frontDoorPrivateLinkLocation = 'FILL_IN_SUPPORTED_PRIVATE_LINK_LOCATION'
param originHostName = 'FILL_IN_REGION1_ORIGIN_TLS_HOSTNAME'
