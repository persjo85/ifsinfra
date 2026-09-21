using '../../main.bicep'
extends './private-link.bicepparam'

// Reserved for regional monitoring settings as monitoring.bicep is completed.
// Export MYSQL_ADMINISTRATOR_PASSWORD in the deployment environment first.
param mysqlAdministratorPassword = readEnvironmentVariable('MYSQL_ADMINISTRATOR_PASSWORD')
