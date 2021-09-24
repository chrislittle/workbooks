# WARNING: THIS SCRIPT IS PROVIDED WITHOUT WARRANTY AND SUPPORT. ROBUST TESTING SHOULD BE PERFORMED.

SAMPLE POWERSHELL SCRIPTS FOR MOVING MSSQL & AzureVM Workload Types to new Vaults

* Move Azure VM to new vault.ps1 - Moves (while retaining existing data) an Azure VM to a new recovery services vault. This script is not for use with workloads being protected such as MSSQL. **(QA PERFORMED)**
* Move Azure SQL Standalone VM to new Vault.ps1 - Moves (while retaining existing data) a stand alone MS SQL Azure VM to a new recovery services vault. This script is capable of moving both Azure VM backup and MS SQL database configurations. **(QA PERFORMED)**
* Move Azure SQL AOAG VM to new Vault.ps1 - Moves (while retaining existing data) MS SQL Always On Availability Group databases & Azure VM to a new recovery services vault. This script is capable of moving both Azure VM backup and MS SQL Cluster (AOAG) database configurations. Each node in the cluster needs the script run but please note there are some components of the secondary nodes that can be ommitted from the script. **(QA PENDING)**
