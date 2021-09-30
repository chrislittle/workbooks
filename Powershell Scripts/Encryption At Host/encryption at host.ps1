# Initial Azure Encryption at Host script. Enables Encryption at Host on VM & updates the OS & Data Disks to SSE with CMK to the Disk Encryption Set

$ResourceGroupName = "newbackup"
$VMName = "sqlstandalone"
$diskEncryptionSetName = "des-sqlnodes"
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Force
$vmosdisk = $vm.StorageProfile.OsDisk
$vmdatadisks = $vm.StorageProfile.DataDisks
$diskEncryptionSet = Get-AzDiskEncryptionSet -ResourceGroupName $ResourceGroupName -Name $diskEncryptionSetName
Update-AzVM -VM $VM -ResourceGroupName $ResourceGroupName -EncryptionAtHost $true

# Update OS disk to SSE with CMK
New-AzDiskUpdateConfig -EncryptionType "EncryptionAtRestWithCustomerKey" -DiskEncryptionSetId $diskEncryptionSet.Id | Update-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $vmosdisk.name

# Update Data disks to SSE with CMK
foreach($vmdatadisk in $vmdatadisks){
New-AzDiskUpdateConfig -EncryptionType "EncryptionAtRestWithCustomerKey" -DiskEncryptionSetId $diskEncryptionSet.Id | Update-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $vmdatadisk.name}
