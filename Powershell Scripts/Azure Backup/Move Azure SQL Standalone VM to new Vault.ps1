#
# WARNING: THIS SCRIPT IS PROVIDED WITHOUT WARRANTY AND SUPPORT. ROBUST TESTING SHOULD BE PERFORMED.
#
# This script moves an Azure Virtual Machine & MS SQL workload to a new recovery services vault. This script is built to support a standalone MS SQL server with both AzureVM & MSSQL backups configured.
#
# General Notes
# - Move-AzResource events on a resource group are blocking, new resource deployments will fail validation until move is complete
# - This script assumes the new Recovery Services Vault & Policy is created ahead of time
# - There is a hidden resource group that stores restorePointCollections (snapshots) that must be found & input into this script. Its not dynamic to find these automatically.


# Set proper subscription context
set-azcontext -Subscription SubscriptionID

# Set general variables
$currentrg = "CURRENT RESOURCE GROUP"
$newrg = "NEW RESOURCE GROUP"
$currentvault = Get-AzRecoveryServicesVault -ResourceGroupName $currentrg -Name "CURRENT VAULT NAME"
$newvault = Get-AzRecoveryServicesVault -ResourceGroupName $newrg -Name "NEW VAULT NAME"
$vmname = "VM NAME"
# HIDDEN_RESOURCE_GROUP_FOR_RESTORE_POINT_COLLECTIONS
$restorePointCollectionrg = "restorePointCollection rg name"

# set the recovery context to the existing vault
Set-AzRecoveryServicesVaultContext -Vault $currentvault

# Get the container & backup items details and disable protection for Azure VM Type
$container = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM -FriendlyName $vmname
$currentitems = Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType AzureVM
foreach($currentitem in $currentitems){
Disable-AzRecoveryServicesBackupProtection -Item $currentitem -Force}

# Get the container & backup items details and disable protection for MSSQL Type
$sqlcontainer = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVMAppContainer -FriendlyName $vmname
$currentsqlitems = Get-AzRecoveryServicesBackupItem -Container $sqlcontainer -WorkloadType MSSQL
foreach($currentsqlitem in $currentsqlitems){
Disable-AzRecoveryServicesBackupProtection -Item $currentsqlitem -Force}

# remove restore point collections (snapshots)
$restorePointCollection = Get-AzResource -ResourceGroupName $restorePointCollectionrg -name *MANUALLY TYPE IN VM NAME KEEP STARS* -ResourceType Microsoft.Compute/restorePointCollections
$restorePointCollection | FT
Read-Host -Prompt "Confirm the restorePointCollection list matches your intent, Press enter key to continue"
Remove-AzResource -ResourceId $restorePointCollection.ResourceId -Force

# Move resources associated with VM (NIC, NSG, DISK)
$resources = Get-AzResource -ResourceGroupName $currentrg -name *MANUALLY TYPE IN VM NAME KEEP STARS*
$resources | FT
Read-Host -Prompt "Confirm the list of resources to move match your intent, Press enter key to continue"
Move-AzResource -DestinationResourceGroupName $newrg -ResourceId $Resources.ResourceId -Force

# set the recovery context to the new vault
Set-AzRecoveryServicesVaultContext -Vault $newvault

# set variable for the policy to be applied (must exist prior to execution)
$vmpolicy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "POLICY NAME IN NEW VAULT"
$sqlpolicy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "POLICY NAME IN NEW VAULT"

# enable protection of the newly moved VM & SQL databases to the policy defined. 
Enable-AzRecoveryServicesBackupProtection -Policy $vmpolicy -Name $vmname -ResourceGroupName $newrg -VaultId $newvault.ID
$vmdetails = Get-AzResource -Name $vmname -ResourceType Microsoft.Compute/virtualMachines
Register-AzRecoveryServicesBackupContainer -ResourceId $vmdetails.resourceid -BackupManagementType AzureWorkload -WorkloadType MSSQL -VaultId $newvault.ID -Force
Get-AzRecoveryServicesBackupProtectableItem -workloadType MSSQL -ItemType SQLDataBase -VaultId $newvault.ID -ServerName $vmname
Read-Host -Prompt "confirm the item you wish to protect is present, Press enter key to continue"
$sqldatabaseitems = Get-AzRecoveryServicesBackupProtectableItem -workloadType MSSQL -ItemType SQLDataBase -VaultId $newvault.ID -ServerName $vmname
foreach($sqldatabaseitem in $sqldatabaseitems){
Enable-AzRecoveryServicesBackupProtection -ProtectableItem $sqldatabaseitem -Policy $sqlpolicy}