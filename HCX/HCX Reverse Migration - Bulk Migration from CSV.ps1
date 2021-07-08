write-host(“Getting Source Site”)
 
$HcxSrcSite = Get-HCXSite -Destination -server (Legacy HCX Connector) -name  (Cloud vCenter)
 
write-host(“Getting Target Site”)
 
$HcxDstSite = Get-HCXSite -Source (Legacy vCenter)
$HCXVMS = Import-CSV -Path 'E:\PowerCLI\HCX_Reverse Migration_From_Cloud_to_Legacy_withCSV.csv'
 
ForEach ($HCXVM in $HCXVMS) {
    $DstFolder = Get-HCXContainer $HCXVM.DESTINATION_VM_FOLDER -Site $HcxDstSite
    $DstCompute = Get-HCXContainer -Type Cluster $HCXVM.DESTINATION_CLUSTER_OR_HOST  -Site $HcxDstSite
    $DstDatastore = Get-HCXDatastore $HCXVM.DESTINATION_DATASTORE -Site $HcxDstSite
    $SrcNetwork = Get-HCXNetwork $HCXVM.SOURCE_PORTGROUP -type DistributedVirtualPortgroup -Site $HcxSrcSite
    $DstNetwork = Get-HCXNetwork $HCXVM.DESTINATION_PORTGROUP -Type DistributedVirtualPortgroup -Site $HcxDstSite
    $NetworkMapping = New-HCXNetworkMapping -SourceNetwork $SrcNetwork -DestinationNetwork $DstNetwork
    $NewMigration = New-HCXMigration -VM (Get-HCXVM -name $HCXVM.VM_NAME -site $HcxSrcSite )  -MigrationType vMotion -SourceSite $HcxSrcSite -DestinationSite $HcxDstSite -Folder $DstFolder -TargetComputeContainer $DstCompute -TargetDatastore $DstDatastore -NetworkMapping $NetworkMapping -DiskProvisionType Thin -UpgradeVMTools $False -RemoveISOs $True -ForcePowerOffVm $True -RetainMac $True -UpgradeHardware $False -RemoveSnapshots $True
    Start-HCXMigration -Migration $NewMigration -Confirm:$false #-WhatIf
    }
Disconnect-HCXServer -Server (Legacy HCX Connector) -Confirm:$false
