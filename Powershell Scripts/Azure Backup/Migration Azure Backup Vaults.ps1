#
# WARNING: THIS SCRIPT IS PROVIDED WITHOUT WARRANTY AND SUPPORT. ROBUST TESTING SHOULD BE PERFORMED.
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

# set the recovery context to the existing vault
Set-AzRecoveryServicesVaultContext -Vault $currentvault

# Get the container & backup items details and disable protection for Azure VM Type
$container = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM -FriendlyName $vmname
$currentitems = Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType AzureVM
foreach($currentitem in $currentitems){
Disable-AzRecoveryServicesBackupProtection -Item $currentitem -Force}

# disable protection for MSSQL Type (cluster AG name required for clusters
# NOTE: AFTER MOVING PRIMARY CLUSTER NODE ADDITIONAL SECONDARY NODES DO NOT NEED TO RUN THE MS SQL DISABLE PROTECTION AS THIS WAS ALREADY DONE VIA PRIMARY NODE ON THE CLUSTER AG
$currentsqlitems = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureWorkload -WorkloadType MSSQL -Name "availability group name or sql standalone vm name "
foreach($currentsqlitem in $currentsqlitems){
Disable-AzRecoveryServicesBackupProtection -Item $currentsqlitem -Force}

# remove restore point collections (snapshots)
$restorePointCollection = Get-AzResource -ResourceGroupName HIDDEN_RESOURCE_GROUP_FOR_RESTORE_POINT_COLLECTIONS -name *MANUALLY TYPE IN VM NAME KEEP STARS* -ResourceType Microsoft.Compute/restorePointCollections
$restorePointCollection | FT
Read-Host -Prompt "Confirm the restorePointCollection list matches your intent, Press any key to continue"
Remove-AzResource -ResourceId $restorePointCollection.ResourceId -Force

# Move resources associated with VM (NIC, NSG, DISK)
$resources = Get-AzResource -ResourceGroupName $currentrg -name *MANUALLY TYPE IN VM NAME KEEP STARS*
$resources | FT
Read-Host -Prompt "Confirm the list of resources to move match your intent, Press any key to continue"
Move-AzResource -DestinationResourceGroupName $newrg -ResourceId $Resources.ResourceId -Force

# set the recovery context to the new vault
Set-AzRecoveryServicesVaultContext -Vault $newvault

# set variable for the policy to be applied (must exist prior to execution)
$vmpolicy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "POLICY NAME IN NEW VAULT"
$sqlpolicy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "POLICY NAME IN NEW VAULT"

# enable protection of the newly moved VM & SQL databases to the policy defined. OS Disks only for SQL on IaaS VMs, remove -ExcludeAllDataDisks if required
Enable-AzRecoveryServicesBackupProtection -Policy $vmpolicy -ExcludeAllDataDisks -Name $vmname -ResourceGroupName $newrg -VaultId $newvault.ID
$vmdetails = Get-AzResource -Name $vmname -ResourceType Microsoft.Compute/virtualMachines
Register-AzRecoveryServicesBackupContainer -ResourceId $vmdetails.resourceid -BackupManagementType AzureWorkload -WorkloadType MSSQL -VaultId $newvault.ID -Force

# NOTE: AFTER MOVING PRIMARY CLUSTER NODE ADDITIONAL SECONDARY NODES DO NOT NEED TO ENABLE CLUSTER DB PROTECTION AS THIS WAS ALREADY DONE VIA PRIMARY NODE ON THE CLUSTER AG
Get-AzRecoveryServicesBackupProtectableItem -WorkloadType MSSQL -VaultId $newvault.ID
Read-Host -Prompt "confirm the item you wish to protect is present, Press any key to continue"
$sqldatabase = Get-AzRecoveryServicesBackupProtectableItem -workloadType MSSQL -ItemType SQLDataBase -VaultId $newvault.ID -ServerName FQDN of Cluster AG or VM Name
Enable-AzRecoveryServicesBackupProtection -ProtectableItem $sqldatabase -Policy $sqlpolicy
