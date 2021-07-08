write-host("Getting Time for Scheduling")
$startTime = [DateTime]::Now.AddDays(12)
$endTime = [DateTime]::Now.AddDays(15)
  
#Connect-HCXServer -Server  HCXSOURCESERVER
write-host("Getting Source Site")
$HcxSrcSite = get-hcxsite -source -server HCXSOURCESERVER
write-host("Getting Target Site")
$HcxDstSite = get-hcxsite -destination -server HCXSOURCESERVER -name "Destination VC"
write-host("Getting VM (This may take a while)")
$HcxVMS = Get-HCXVM -Name (Get-Content "location of textfile") -server HCXSOURCESERVER -site $HcxSrcSite
write-host("Getting Folder")
$DstFolder = Get-HCXContainer -Name "Dest VC Folder" -Site $HcxDstSite
write-host("Getting Container")
$DstCompute = Get-HCXContainer -Name "ESXIHOSTNAME or Dest Cluster"  -Site $HcxDstSite
write-host("Getting Datastore")
$DstDatastore = Get-HCXDatastore -Name "Dest Datastore" -Site $HcxDstSite
write-host("Getting Source Network")
$SrcNetwork = Get-HCXNetwork -Name "Source PortGroup" -type DistributedVirtualPortgroup -Site $HcxSrcSite
write-host("Getting Target Network")
$DstNetwork = Get-HCXNetwork -Name "Destination Network" -type DistributedVirtualPortgroup -Site $HcxDstSite
write-host("Creating Network Mapping")
$NetworkMapping = New-HCXNetworkMapping -SourceNetwork $SrcNetwork -DestinationNetwork $DstNetwork
  
write-host("Creating Migration Command")
  
ForEach ($HCXVM in $HCXVMS) {
  
$NewMigration = New-HCXMigration -VM $HcxVM -MigrationType Bulk -SourceSite $HcxSrcSite -DestinationSite $HcxDstSite -Folder $DstFolder `
-TargetComputeContainer $DstCompute -TargetDatastore $DstDatastore -NetworkMapping $NetworkMapping -DiskProvisionType Thin `
-UpgradeVMTools $True -RemoveISOs $True -ForcePowerOffVm $True -RetainMac $True -UpgradeHardware $True `
-RemoveSnapshots $True -ScheduleStartTime $startTime -ScheduleEndTime $endTime
Start-HCXMigration -Migration $NewMigration -Confirm:$false
