using '../../main.bicep'
extends './monitoring.bicepparam'

param mysqlAdministratorPassword = readEnvironmentVariable('MYSQL_ADMINISTRATOR_PASSWORD')
