    # Get VM details from HCX in a variable that needs to be migrated
    $vmmig = Get-HCXVM -Name $HCXVM.VM_NAME -Site $HcxSrcSite
    # Get VM details from vCenter for the VMs network adapter
    $networkAdapterList = Get-VM -Name $HCXVM.VM_NAME -Server $sourceVIServer | get-networkadapter
    # For Each Loop
    # $j = 0 - sets an variable to 0
    # $j -le $networkAdapterList.count - checks if the variable is less than the count of the network adapter list
    # ($networkAdapterList.Count -1) - Gets the count of the number of objects in the variable, minus 1
    # $j++ - increments the variable by 1
    for($j = 0; $j -le ($networkAdapterList.Count -1); $j++)
{         
    # Sets variable of the network adapter to the current network adapter in the list using the $j variable as the index number of the list
    $sourceNetwork = $vmmig.Network[$j]         
    
    # Sets variable of the HCX network Extention appliance - where it's linked to the Network from the Migration varibles set before the loop. Selects the first returned object.
    $networkExtension = Get-HCXNetworkExtension | where -Property Network -like $vmmig.Network[$j].DisplayName | Select -First 1 

    # If Statetment
    # If the network extension variable is not null, then it will run the following code
     if(($null -ne $networkExtension))
    
     # Set variable to get Destination network from HCX by looking for the destination network object within the network extension - selects first object
        {$destinationNetwork = Get-HCXNetwork -Name $networkExtension.DestinationNetwork -Site $HcxDstSite  | Select -First 1}
    else
    # If the network extension variable is null, then it will run the following code
    # Set variable to get Destination network from HCX - get HCX network from available networks (not HCX network extension based) - selects first object 
        {$destinationNetwork = Get-HCXNetwork -Name $networkAdapterList[$j].NetworkName -type DistributedVirtualPortgroup -Site $HcxDstSite  | Select -First 1}
    # End of If Statement
    
    # Set variable for Target Network Mapping > += adds/appends the network to the list of network mappings
    $targetNetworkMapping += New-HCXNetworkMapping -SourceNetwork $sourceNetwork -DestinationNetwork $destinationNetwork

    # Write out the current network mapping to the host display
    Write-Host "Network Mapping -> $targetNetworkMapping"
    }
