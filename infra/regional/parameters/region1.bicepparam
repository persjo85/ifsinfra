using '../main.bicep'

// Copy this file to main.parameters.bicepparam. Values below are deliberately invalid placeholders.
param namePrefix = 'fill-in-prefix'
param location = 'swedencentral'
param frontDoorPrivateLinkLocation = 'FILL_IN_SUPPORTED_PRIVATE_LINK_LOCATION'
param originHostName = 'FILL_IN_REGION1_ORIGIN_TLS_HOSTNAME'
param network = {
  regional_vnet: 'FILL_IN_CIDR'
  app_subnet: 'FILL_IN_CIDR'
  mysql_subnet: 'FILL_IN_CIDR'
  pls_subnet: 'FILL_IN_CIDR'
  private_endpoints_subnet: 'FILL_IN_CIDR'
  management_vnet: 'FILL_IN_CIDR'
  jump_subnet: 'FILL_IN_CIDR'
}
param skus = {
  app_vm: 'FILL_IN_STANDARD_VM_SIZE'
  jump_vm: 'FILL_IN_STANDARD_VM_SIZE'
  os_disk: 'FILL_IN_DISK_TIER'
  mysql: 'FILL_IN_GP_OR_MO_MYSQL_SKU'
  key_vault: 'standard'
}
param sshPublicKey = 'FILL_IN_OPENSSH_PUBLIC_KEY'
param adminSourceCidrs = [ 'FILL_IN_APPROVED_PUBLIC_IP_WITH_SLASH_32' ]
param vmAdminGroupObjectIds = [ 'FILL_IN_EXISTING_ENTRA_GROUP_OBJECT_GUID' ]
param mysqlVersion = '8.0.21'
param mysqlStorageGb = 0
// Pass mysqlAdministratorPassword securely with az deployment, not in this file.
