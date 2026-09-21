using '../../main.bicep'
extends './private-link.bicepparam'

param mysqlAdministratorPassword = readEnvironmentVariable('MYSQL_ADMINISTRATOR_PASSWORD')
