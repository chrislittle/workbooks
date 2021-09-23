# WARNING: THIS SCRIPT IS PROVIDED WITHOUT WARRANTY AND SUPPORT. ROBUST TESTING SHOULD BE PERFORMED.

SAMPLE POWERSHELL SCRIPT FOR MOVING MSSQL & AzureVM Workload Types to new Vaults

### BUG: Resource Mover code fails out when moving as the VM & SQL VM resource must be moved together. Investigating how to group that in a single move request via powershell. workaround is to move the 2 resources manually & then continue with the script