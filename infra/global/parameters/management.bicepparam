using none
extends './base.bicepparam'

param managementNetwork = {
  vnet: 'FILL_IN_MANAGEMENT_VNET_CIDR'
  jumpSubnet: 'FILL_IN_JUMP_SUBNET_CIDR'
}
param jumpVmSize = 'FILL_IN_STANDARD_VM_SIZE'
param osDiskSku = 'FILL_IN_DISK_TIER'
param sshPublicKey = 'FILL_IN_OPENSSH_PUBLIC_KEY'
param adminSourceCidrs = [ 'FILL_IN_APPROVED_PUBLIC_IP_WITH_SLASH_32' ]
