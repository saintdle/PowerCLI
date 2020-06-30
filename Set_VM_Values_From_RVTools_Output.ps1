$Server = Read-Host -Prompt 'Input your server name'
$Restore = "_RestoreFriday"
$ServerRestore = $Server + $Restore$old_vm = get-vm -name $server
$new_vm = get-vm -name $ServerRestore
set-vm -vm $new_vm  -NumCpu $old_vm.NumCpu -MemoryMB $old_vm.MemoryMB -confirm:$false
$newnics = Get-NetworkAdapter -vm $new_vm
if ($newnics.count -eq 0) {
	$nics = Get-NetworkAdapter -vm $orig_vm
	$nics | %{
		$nic = $_
		New-Networkadapter -vm $new_vm -NetworkName $nic.networkname -Type $nic.type -startconnected:$true -confirm:$false
	} 
} else { Write-Host "`nINFO:   " $(get-date -format "yyyyMMdd-HHmmss") "Restored VM already contain NICs please check manually" }
