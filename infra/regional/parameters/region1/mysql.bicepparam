using none
extends './compute.bicepparam'

param mysqlVersion = '8.0.21'
param mysqlStorageGb = 0
param mysqlHaMode = 'ZoneRedundant'
param mysqlBackupRetentionDays = 14
param mysqlGeoRedundantBackupEnabled = false
param mysqlDatabaseName = 'application'
param mysqlAdministratorLogin = 'bootstrapadmin'
// Configure mysqlAdministratorPassword through an approved secret mechanism.
