targetScope = 'resourceGroup'
param vmIds array
param dataCollectionRuleId string
param workspaceId string
param mysqlServerId string
param loadBalancerId string
resource ama 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = [for vmId in vmIds: { name: '${last(split(vmId, '/'))}/AzureMonitorLinuxAgent', location: resourceGroup().location, properties: { publisher: 'Microsoft.Azure.Monitor', type: 'AzureMonitorLinuxAgent', typeHandlerVersion: '1.0', autoUpgradeMinorVersion: true, enableAutomaticUpgrade: true } }]
resource mysql 'Microsoft.DBforMySQL/flexibleServers@2023-12-30' existing = if (!empty(mysqlServerId)) { name: last(split(mysqlServerId, '/')) }
resource mysqlDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(mysqlServerId)) { scope: mysql, name: 'central-logs', properties: { workspaceId: workspaceId, logs: [ { category: 'MySqlAuditLogs', enabled: true }, { category: 'MySqlSlowLogs', enabled: true } ], metrics: [ { category: 'AllMetrics', enabled: true } ] } }
resource lb 'Microsoft.Network/loadBalancers@2024-05-01' existing = if (!empty(loadBalancerId)) { name: last(split(loadBalancerId, '/')) }
resource lbDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(loadBalancerId)) { scope: lb, name: 'central-metrics', properties: { workspaceId: workspaceId, metrics: [ { category: 'AllMetrics', enabled: true } ] } }
