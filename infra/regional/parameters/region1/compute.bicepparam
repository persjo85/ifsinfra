using none
extends './network.bicepparam'

param skus = {
  app_vm: 'FILL_IN_STANDARD_VM_SIZE'
  os_disk: 'FILL_IN_DISK_TIER'
  mysql: 'FILL_IN_GP_OR_MO_MYSQL_SKU'
}
param sshPublicKey = 'FILL_IN_OPENSSH_PUBLIC_KEY'
param adminUsername = 'provisionadmin'
param availabilitySetFaultDomains = 2
