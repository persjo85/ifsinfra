using '../main.bicep'

// Deploy this first with regions = [] to create the one shared management VNet
// and jumpserver. Copy its outputs into each regional parameter file.
param globalResourceGroupName = 'FILL_IN_GLOBAL_RESOURCE_GROUP'
param globalLocation = 'swedencentral'
param namePrefix = 'FILL_IN_GLOBAL_PREFIX'
param managementNetwork = {
  vnet: 'FILL_IN_MANAGEMENT_VNET_CIDR'
  jumpSubnet: 'FILL_IN_JUMP_SUBNET_CIDR'
}
param jumpVmSize = 'FILL_IN_STANDARD_VM_SIZE'
param osDiskSku = 'FILL_IN_DISK_TIER'
param sshPublicKey = 'FILL_IN_OPENSSH_PUBLIC_KEY'
param adminSourceCidrs = [ 'FILL_IN_APPROVED_PUBLIC_IP_WITH_SLASH_32' ]
param workspaceId = 'FILL_IN_LOG_ANALYTICS_WORKSPACE_RESOURCE_ID'

// After regional deployment, copy its `frontDoorOrigin` output here.
param regions = [
  {
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
