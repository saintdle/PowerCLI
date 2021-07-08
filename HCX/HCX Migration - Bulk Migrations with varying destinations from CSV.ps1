write-host(“Getting Time for Scheduling”)
$startTime = [DateTime]::Now.AddDays(12)
$endTime = [DateTime]::Now.AddDays(15)
Connect-HCXServer -Server  SOURCEHCXSERVER
write-host(“Getting Source Site”)
$HcxSrcSite = Get-HCXSite -Source “SourceSite”
write-host(“Getting Target Site”)
$HcxDstSite = Get-HCXSite -Destination “DestinationSite”
$HCXVMS = Import-CSV .\Import_VM_list.csv
ForEach ($HCXVM in $HCXVMS) {
    $DstFolder = Get-HCXContainer $HCXVM.DESTINATION_VM_FOLDER -Site $HcxDstSite
    $DstCompute = Get-HCXContainer $HCXVM.DESTINATION_CLUSTER_OR_HOST  -Site $HcxDstSite
    $DstDatastore = Get-HCXDatastore $HCXVM.DESTINATION_DATASTORE -Site $HcxDstSite
    $SrcNetwork = Get-HCXNetwork $HCXVM.SOURCE_PORTGROUP -type DistributedVirtualPortgroup -Site $HcxSrcSite
    $DstNetwork = Get-HCXNetwork $HCXVM.DESTINATION_PORTGROUP -Site $HcxDstSite
    $NetworkMapping = New-HCXNetworkMapping -SourceNetwork $SrcNetwork -DestinationNetwork $DstNetwork
    $NewMigration = New-HCXMigration -VM (Get-HCXVM $HCXVM.VM_NAME) -MigrationType Bulk -SourceSite $HcxSrcSite -DestinationSite $HcxDstSite -Folder $DstFolder -TargetComputeContainer $DstCompute -TargetDatastore $DstDatastore -NetworkMapping $NetworkMapping -DiskProvisionType Thin -UpgradeVMTools $True -RemoveISOs $True -ForcePowerOffVm $True -RetainMac $True -UpgradeHardware $True -RemoveSnapshots $True -ScheduleStartTime $startTime -ScheduleEndTime $endTime
    Start-HCXMigration -Migration $NewMigration -Confirm:$false
}
