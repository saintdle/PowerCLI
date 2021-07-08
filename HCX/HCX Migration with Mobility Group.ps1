write-host(“Getting Time for Scheduling”)
$startTime = [DateTime]::Now.AddDays(12)
$endTime = [DateTime]::Now.AddDays(15)
 
Connect-HCXServer -Server  "HCX CONNECTOR"
 
write-host(“Getting Source Site”)
$HcxSrcSite = Get-HCXSite -Source
 
write-host(“Getting Target Site”)
$HcxDstSite = Get-HCXSite -Destination “DEST SITE” -ErrorAction SilentlyContinue
 
write-host(“Define Mobility Group Source and Destination Sites”)
$NewMGC = New-HCXMobilityGroupConfiguration -SourceSite $HcxSrcSite -DestinationSite $HcxDstSite
 
write-host(“Define Mobility Group Name”)
$MobilityGroupName = "Batman"
 
write-host(“Import csv details for the VMs to be migrated”)
$HCXVMS = Import-CSV .\Import_VM_list_mobility.csv
 
ForEach ($HCXVM in $HCXVMS) {
 
    $DstFolder = Get-HCXContainer $HCXVM.DESTINATION_VM_FOLDER -Site $HcxDstSite
    $DstCompute = Get-HCXContainer $HCXVM.DESTINATION_CLUSTER_OR_HOST  -Site $HcxDstSite
    $DstDatastore = Get-HCXDatastore $HCXVM.DESTINATION_DATASTORE -Site $HcxDstSite
    $SrcNetwork = Get-HCXNetwork $HCXVM.SOURCE_PORTGROUP -type DistributedVirtualPortgroup -Site $HcxSrcSite
    $DstNetwork = Get-HCXNetwork $HCXVM.DESTINATION_PORTGROUP -type NsxtSegment -Site $HcxDstSite
    $NetworkMapping = New-HCXNetworkMapping -SourceNetwork $SrcNetwork -DestinationNetwork $DstNetwork
    $NewMigration = New-HCXMigration -VM (Get-HCXVM $HCXVM.VM_NAME) -MigrationType Bulk -SourceSite $HcxSrcSite -DestinationSite $HcxDstSite -Folder $DstFolder -TargetComputeContainer $DstCompute -TargetDatastore $DstDatastore -NetworkMapping $NetworkMapping -DiskProvisionType Thin -UpgradeVMTools $False -RemoveISOs $True -ForcePowerOffVm $True -RetainMac $True -UpgradeHardware $False -RemoveSnapshots $True -ScheduleStartTime $startTime -ScheduleEndTime $endTime -MobilityGroupMigration
    
    #This is used the first time to create the mobility group with the required configuration, after the first go it will error saying its already created which is expected
    $mobilityGroup1 = New-HCXMobilityGroup -Name $MobilityGroupName -Migration $NewMigration -GroupConfiguration $NewMGC -ErrorAction SilentlyContinue
 
    #Even though this command will error with "Value cannot be null", it still works and adds each vm to the created mobility group
    Set-HCXMobilityGroup -MobilityGroup (get-hcxmobilitygroup -name $MobilityGroupName) -Migration $NewMigration -addMigration -ErrorAction SilentlyContinue
         
}
 
#This will error with "Value cannot be null" but it will start the migrations of the VMs in the mobility group
Start-HCXMobilityGroupMigration -MobilityGroup (get-hcxmobilitygroup -name $MobilityGroupName) -ErrorAction SilentlyContinue
