# WARNING: THIS SCRIPT IS PROVIDED WITHOUT WARRANTY AND SUPPORT. ROBUST TESTING SHOULD BE PERFORMED.

SAMPLE POWERSHELL SCRIPTS FOR MOVING MSSQL & AzureVM Workload Types to new Vaults

* Move Azure VM to new vault.ps1 - Moves (while retaining existing data) an Azure VM to a new recovery services vault. This script is not for use with workloads being protected such as MSSQL.
* Move Azure SQL Standalone VM to new Vault.ps1 - Moves (while retaining existing data) a stand alone MS SQL Azure VM to a new recovery services vault. This script is capable of migrating both Azure VM backup and MS SQL database configurations.

