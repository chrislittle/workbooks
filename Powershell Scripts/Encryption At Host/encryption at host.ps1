# Initial Azure Encryption at Host script. Enables Encryption at Host on VM & updates the OS & Data Disks to SSE with CMK to the Disk Encryption Set

# Set proper subscription context
set-azcontext -Subscription SubscriptionID

# Set variables
$ResourceGroupName = "Resource Group Name"
$VMName = "Azure VM Name"
$diskEncryptionSetName = "Disk Encryption Set Name"
$diskEncryptionSet = Get-AzDiskEncryptionSet -ResourceGroupName $ResourceGroupName -Name $diskEncryptionSetName

# Get VM Data
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName

# Deallocate Virtual Machine
Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force

# Set Disk Variables
$vmosdisk = $vm.StorageProfile.OsDisk
$vmdatadisks = $vm.StorageProfile.DataDisks

# Enable Encryption at Host
Update-AzVM -VM $VM -ResourceGroupName $ResourceGroupName -EncryptionAtHost $true

# Update OS disk to SSE with CMK
New-AzDiskUpdateConfig -EncryptionType "EncryptionAtRestWithCustomerKey" -DiskEncryptionSetId $diskEncryptionSet.Id | Update-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $vmosdisk.name

# Update Data disks to SSE with CMK
foreach($vmdatadisk in $vmdatadisks){
New-AzDiskUpdateConfig -EncryptionType "EncryptionAtRestWithCustomerKey" -DiskEncryptionSetId $diskEncryptionSet.Id | Update-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $vmdatadisk.name}
