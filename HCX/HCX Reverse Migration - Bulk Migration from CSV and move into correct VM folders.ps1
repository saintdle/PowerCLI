write-host(“Getting Time for Scheduling”)
$startTime = [DateTime]::Now.AddDays(12)
$endTime = [DateTime]::Now.AddDays(15)
Connect-HCXServer -Server  (Legacy HCX Connector) # Connect to HCX Connector at Legacy 
Connect-VIServer -Server w(LegacyVC) # Connect to Legacy vCenter
write-host(“Getting Source Site”)
 
$HcxSrcSite = Get-HCXSite -Destination -server (HCX Connctor) -name  (Cloud VC) # Source site is the cloud
 
write-host(“Getting Target Site”)
 
$HcxDstSite = Get-HCXSite -Source (LegacyVC) # Destination is Legacy vCenter
 
$HCXVMS = Import-CSV -Path 'E:\PowerCLI\Bulk\FromCloudtoLegacy\HCX_Reverse_BULK_Migration_From_Cloud_to_Legacy_withCSV.csv'
 
ForEach ($HCXVM in $HCXVMS) {
    $folderfull = get-folder $HCXVM.DESTINATION_VM_FOLDER | where {$_.Parent -Match $HCXVM.DESTINATION_VM_ParentFOLDER} | select Id 
    $foldershort = $folderfull.Id.Replace("Folder-group-","*")
    $ContainerUid = Get-HCXContainer | where {$_.Id -Like $foldershort} | Select Uid
    $DstFolder = Get-hcxcontainer -Uid $ContainerUid.Uid
    $DstCompute = Get-HCXContainer -Type Cluster $HCXVM.DESTINATION_CLUSTER_OR_HOST  -Site $HcxDstSite
    $DstDatastore = Get-HCXDatastore $HCXVM.DESTINATION_DATASTORE -Site $HcxDstSite
    $SrcNetwork = Get-HCXNetwork $HCXVM.SOURCE_PORTGROUP -type DistributedVirtualPortgroup -Site $HcxSrcSite
    $DstNetwork = Get-HCXNetwork $HCXVM.DESTINATION_PORTGROUP -Type DistributedVirtualPortgroup -Site $HcxDstSite
    $NetworkMapping = New-HCXNetworkMapping -SourceNetwork $SrcNetwork -DestinationNetwork $DstNetwork
    $NewMigration = New-HCXMigration -VM (Get-HCXVM -name $HCXVM.VM_NAME -site $HcxSrcSite )  -MigrationType Bulk -SourceSite $HcxSrcSite -DestinationSite $HcxDstSite -Folder $DstFolder  -TargetComputeContainer $DstCompute -TargetDatastore $DstDatastore -NetworkMapping $NetworkMapping -DiskProvisionType Thin -UpgradeVMTools $False -RemoveISOs $True -ForcePowerOffVm $True -RetainMac $True -UpgradeHardware $False -RemoveSnapshots $True -ScheduleStartTime $startTime -ScheduleEndTime $endTime
    Start-HCXMigration -Migration $NewMigration -Confirm:$false -WhatIf
     
    }
Disconnect-HCXServer -Server (HCX Connector at Legacy) -Confirm:$false
Disconnect-VIServer -Server (Legacy VC) -Confirm:$False
 
# This script is used for bulk migrations, you can populate the csv with VMs to migrate from Cloud to the Legacy VC/clusters
# The -WhatIf is used for testing, once you have populated the csv uncomment the -WhatIf and run it, if it runs without errors you can comment it out again and run the command for it to configure actual migrations 
# Bulk Syncs will start but the cut over is scheduled for 12 days in advance, this allows you to configure the syncs to start in advance of the migration event, and during the event you can cut over VMs by brinng the date forward to what suits you (in the web interface)
# Since the legacy side has multiple sub folders with the same name in vCenter, this script needs to connect to vcenter and pull the IDs for the correct folder based on its uid and then pass that back to hcx, since hcx does not support this directly,
# which is what the script is doing with #folderfull #foldershot #containeruid
