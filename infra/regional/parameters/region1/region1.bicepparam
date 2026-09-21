using '../../main.bicep'
extends './monitoring.bicepparam'

// This is the only regional parameter file passed to Azure CLI.
// Export MYSQL_ADMINISTRATOR_PASSWORD in the deployment environment first.
param mysqlAdministratorPassword = readEnvironmentVariable('MYSQL_ADMINISTRATOR_PASSWORD')
