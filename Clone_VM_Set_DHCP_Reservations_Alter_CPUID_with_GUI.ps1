<#
.SYNOPSIS
    Clone_VM_Set_DHCP_Reservations_Alter_CPUID_with_GUI.ps1 - PowerShell Script to clone a virtual machine, create a DHCP reservation for this new VM, 
    and alter the CPUID to mask the CPU attributes to the guest OS. 
.DESCRIPTION
    This script loads a GUI that is used to clone and existing virtual machine, set a DHCP reservation based on the new VM's MAC Address, and finally configure the new
    VM's CPUID to mask the CPU that is known to the guest OS. 
    You can read more about this script the decisions made in its design here: https://veducate.co.uk/powercli-gui-clone-machine-dhcp-cpuid/
.OUTPUTS
    You are provided a GUI interface for interactions.
.NOTES
    Author        Dean Lewis, https://vEducate.co.uk, Twitter: @saintdle
    
    Change Log    V1.00, 30/06/2020 - Initial version
.LICENSE
    MIT License
    Copyright (c) 2020 Dean Lewis
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
#>

function PickVcenter()
{
#Text label for vCenter selection
$dropDownLabel = New-Object System.Windows.Forms.Label
$dropDownLabel.Location = New-Object System.Drawing.Size(10,12)
$dropDownLabel.Size = New-Object System.Drawing.Size(120, 20)
$dropDownLabel.Text = "Select vCenter Server"
$form.Controls.Add($dropDownLabel)
 
#Dropdown list for vCenter names
$dropDownList = New-Object System.Windows.Forms.ComboBox
$dropDownList.Location = New-Object System.Drawing.Size(150,10)
$dropDownList.Size = New-Object System.Drawing.Size(150,30)
$dropDownList.Items.Add("vCenter01.vEducate.co.uk")
$dropDownList.Items.Add("vCenter02.vEducate.co.uk")
$form.Controls.Add($dropDownList)
 
#Button to click off connect to selected vCenter
$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Size(310, 10)
$button.Size = New-Object System.Drawing.Size(60, 20)
$button.Text = "Connect"
$button.Add_Click({ConnectVIServer})
$form.Controls.Add($button)
 
#Dialog title name of GUI Form, and size of form
$form.Text = "Clone Me Baby!"
$form.Size = New-Object System.Drawing.Size(1000,500)
$form.StartPosition = "CenterScreen"
 
$form.ShowDialog()
 
}
 
function ConnectVIServer() {
#takes the selection in the previous function to a string, to be used as a variable
$choice = $dropDownList.SelectedItem.ToString()
try {
$viServer = Connect-VIServer $choice
if ($viServer -eq $null) { return }
#Loads the ShowVMs function should a connection be made
ShowVMs
}
catch { Write-Host -ForegroundColor Red "Exception: $_" }
}
 
function ShowVMs() {
 
#Text Label for listbox of VMs returned
$listBoxVMsLabel = New-Object System.Windows.Forms.Label
$listBoxVMsLabel.Location = New-Object System.Drawing.Size(10,60)
$listBoxVMsLabel.Text = "Select VM"
$form.Controls.Add($listBoxVMsLabel)
#Listbox populated with VMs
$listBoxVMs.Location = New-Object System.Drawing.Size(10,85)
$listBoxVMs.Size = New-Object System.Drawing.Size(200,20)
$listBoxVMs.Height = 200
#Command used to pull VMs from vCenter filtered on vCenter tag, this can be any mixture of the Get-VM command
 
Get-VM -Tag "Clone-VM" | % {
$listBoxVMs.Items.Add($_.Name)
}
$form.Controls.Add($listBoxVMs)
 
#Datastore list box label
$listBoxDSLabel = New-Object System.Windows.Forms.Label
$listBoxDSLabel.Location = New-Object System.Drawing.Size(250,60)
$listBoxDSLabel.Text = "Select Datastore"
$form.Controls.Add($listBoxDSLabel)
#Datastore list box
$listBoxDS.Location = New-Object System.Drawing.Size(250,85)
$listBoxDS.Size = New-Object System.Drawing.Size(200,20)
$listBoxDS.Height = 200
#Powershell command used to retrieve the datastore details
Get-DataStore | % {
 
$freeGB = [string]::Format("{0:#,##0}", $_.FreeSpaceGB)
$listBoxDS.Items.Add("$($_.Name) | $freeGB GB Free")
}
$form.Controls.Add($listBoxDS)
 
#Host list box label
$listBoxHostLabel = New-Object System.Windows.Forms.Label
$listBoxHostLabel.Location = New-Object System.Drawing.Size(475,60)
$listBoxHostLabel.Text = "Select Target Host"
$form.Controls.Add($listBoxHostLabel)
#Host list box
$listBoxHost.Location = New-Object System.Drawing.Size(475,85)
$listBoxHost.Size = New-Object System.Drawing.Size(200,20)
$listBoxHost.Height = 200
#Powershell command to find hosts, and also parse the information so we can display the free memory on the host
Get-VMHost | % {
 
$memoryTotalMB = $_.MemoryTotalMB
$memoryUsageMB = $_.MemoryUsageMB
$memoryFreeMB = $_.MemoryTotalMB - $_.MemoryUsageMB
$memoryFreePerc = 0.0
try { $memoryFreePerc = $memoryFreeMB / $memoryTotalMB}
catch { }
$freeMB = [string]::Format("{0:#,##0.0%}", $memoryFreePerc)
$listBoxHost.Items.Add("$($_.Name) | $freeMB Free")
 
}
$form.Controls.Add($listBoxHost)
 
#New Virtual Machine name label
$newNameLabel = New-Object System.Windows.Forms.Label
$newNameLabel.Location = New-Object System.Drawing.Size(700, 60)
$newNameLabel.Text = "New VM Name"
$form.Controls.Add($newNameLabel)
#New virtual machine name text box
$newNameTextBox.Location = New-Object System.Drawing.Size(700, 85)
$newNameTextBox.Size = New-Object System.Drawing.Size(200, 20)
$form.Controls.Add($newNameTextBox)
 
#Clone button on the GUI form
$cloneButton = New-Object System.Windows.Forms.Button
$cloneButton.Location = New-Object System.Drawing.Size(700, 120)
$cloneButton.Size = New-Object System.Drawing.Size(60, 20)
$cloneButton.Text = "Clone"
#Confirming actions to be taken when button is clicked
$cloneButton.Add_Click({CloneVM $listBoxVMs $listBoxDS $listBoxHost $newNameTextBox $VMIPAddrTextBox $DHCPScopeBox})
$form.Controls.Add($cloneButton)
 
#Virtual Machine IP address on Production
$VMIPaddr = New-Object system.windows.Forms.Label
$VMIPaddr.Text = "Production IP address"
$VMIPaddr.AutoSize = $true
$VMIPaddr.Width = 25
$VMIPaddr.Height = 10
$VMIPaddr.location = new-object system.drawing.point(700,170)
$Form.controls.Add($VMIPaddr)
#Virtual Machine IP address text box
$VMIPAddrTextBox.Width = 110
$VMIPAddrTextBox.Height = 20
$VMIPAddrTextBox.location = new-object system.drawing.point(700,190)
$Form.controls.Add($VMIPAddrTextBox)
 
#Production DHCP Server label
$DHCPscopes = New-Object system.windows.Forms.Label
$DHCPscopes.Text = "Production DHCP Scopes"
$DHCPscopes.AutoSize = $true
$DHCPscopes.Width = 25
$DHCPscopes.Height = 10
$DHCPscopes.location = new-object system.drawing.point(700,215)
$Form.controls.Add($DHCPscopes)
 
#DHCP list box for production
$DHCPScopeBox.Text = "listBox"
$DHCPScopeBox.Width = 115
$DHCPScopeBox.Height = 75
$DHCPScopeBox.location = new-object system.drawing.point(700,240)
#Specifying a varible where the credentials to be used are stored securely
$MyCredentials=IMPORT-CLIXML C:\Scripts\SecureCredentials.xml
#Powershell command to remotely connect to a server in the DMZ
Invoke-command -computername 10.10.1.1 -Scriptblock {get-dhcpserverv4scope } -credential $MyCredentials | % {
$DHCPScopeBox.Items.Add("$($_.ScopeId)")}
$Form.controls.Add($DHCPScopeBox)
 
#Label for text box, for IP address to be removed from the DHCP scope
$DBVMIPaddr = New-Object system.windows.Forms.Label
$DBVMIPaddr.Text = "Prod DB IP address"
$DBVMIPaddr.AutoSize = $true
$DBVMIPaddr.Width = 25
$DBVMIPaddr.Height = 10
$DBVMIPaddr.location = new-object system.drawing.point(700,330)
$Form.controls.Add($DBVMIPaddr)
 
#Text box, for IP address that is to be removed from DHCP scope
$DBVMIPAddrTextBox.Width = 110
$DBVMIPAddrTextBox.Height = 20
$DBVMIPAddrTextBox.location = new-object system.drawing.point(700,350)
$Form.controls.Add($DBVMIPAddrTextBox)
 
#Label for text box, virtual Machine IP address on DR environment
$DRVMIPaddr = New-Object system.windows.Forms.Label
$DRVMIPaddr.Text = "DR IP address"
$DRVMIPaddr.AutoSize = $true
$DRVMIPaddr.Width = 25
$DRVMIPaddr.Height = 10
$DRVMIPaddr.location = new-object system.drawing.point(820,170)
$Form.controls.Add($DRVMIPaddr)
 
#Text box, for IP address that is to be reserved in DHCP
$DRVMIPAddrTextBox.Width = 110
$DRVMIPAddrTextBox.Height = 20
$DRVMIPAddrTextBox.location = new-object system.drawing.point(820,190)
$Form.controls.Add($DRVMIPAddrTextBox)
 
#DR DHCP Server label
$DRDHCPscopes = New-Object system.windows.Forms.Label
$DRDHCPscopes.Text = "DR DHCP Scopes"
$DRDHCPscopes.AutoSize = $true
$DRDHCPscopes.Width = 25
$DRDHCPscopes.Height = 10
$DRDHCPscopes.location = new-object system.drawing.point(820,215)
$Form.controls.Add($DRDHCPscopes)
 
#DR DHCP server scopes
$DRDHCPScopeBox.Text = "listBox"
$DRDHCPScopeBox.Width = 115
$DRDHCPScopeBox.Height = 75
$DRDHCPScopeBox.location = new-object system.drawing.point(820,240)
#Secure creds location to be used as variable for connection to server
$DRMyCredentials=IMPORT-CLIXML C:\Scripts\DRSecureCredentials.xml
#Command used to connect to DR DHCP server
Invoke-command -computername 10.50.1.1 -Scriptblock {get-dhcpserverv4scope } -credential $DRMyCredentials | % {
$DRDHCPScopeBox.Items.Add("$($_.ScopeId)")}
$Form.controls.Add($DRDHCPScopeBox)
 
#Label for text box, for IP address to be removed from the DR DHCP scope
$DRDBVMIPaddr = New-Object system.windows.Forms.Label
$DRDBVMIPaddr.Text = "DR DB IP address"
$DRDBVMIPaddr.AutoSize = $true
$DRDBVMIPaddr.Width = 25
$DRDBVMIPaddr.Height = 10
$DRDBVMIPaddr.location = new-object system.drawing.point(820,330)
$Form.controls.Add($DBVMIPaddr)
 
#Text box, for IP address that is to be removed from DR DHCP scope
$DRDBVMIPAddrTextBox.Width = 110
$DRDBVMIPAddrTextBox.Height = 20
$DRDBVMIPAddrTextBox.location = new-object system.drawing.point(820,350)
$Form.controls.Add($DRDBVMIPAddrTextBox)
 
}
 
 
function CloneVM()
{  
$vmName = $listBoxVMs.Items[$listBoxVMs.SelectedIndex].ToString()   
$dsName = $listBoxDS.Items[$listBoxDS.SelectedIndex].ToString().Split("|")[0].ToString().Trim()
$hostName = $listBoxHost.Items[$listBoxHost.SelectedIndex].ToString().Split("|")[0].ToString().Trim()
$DHCPscope = $DHCPScopeBox.Items[$DHCPScopeBox.SelectedIndex].ToString()
$IPaddvm = $VMIPAddrTextBox.Text
$DRIPaddvm = $DRVMIPAddrTextBox.Text
$DBIPaddvm = $DBVMIPAddrTextBox.Text
DRDHCPscope = $DRDHCPScopeBox.Items[$DRDHCPScopeBox.SelectedIndex].ToString()
    $DRDBIPaddvm = $DRDBVMIPAddrTextBox.Text
$newName = $newNameTextBox.Text
 
#Basic error checking, unable to continue if the below items are empty
if ($vmName.Length -eq 0) { return }
if ($dsName.Length -eq 0) { return }
if ($hostName.Length -eq 0) { return }
if ($newName.Length -eq 0) { return }
if ($DHCPScope.Length -eq 0) { return }
if ($IPaddvm.Length -eq 0) { return }
if ($DRIPaddvm.Length -eq 0) {return}
 
#Capture current date for logging purposes
$Date = get-date
 
#Output message which reads back the selected variables and confirms the action taken upon hitting the "clone" button
$message = [string]::Format("Cloning {0} on DS {1}, host {2}, named {3}", $vmName, $dsName, $hostName, $newName)
$OutputTextBox = New-Object System.Windows.Forms.TextBox
$OutputTextBox.Location = New-Object System.Drawing.Size(10, 300)
$OutputTextBox.Size = New-Object System.Drawing.Size(600, 200)
$OutputTextBox.Text = $message
$form.Controls.Add($OutputTextBox)
 
### Code to clone VM from selected objects ###
$VM = New-VM -VM $vmName -Name $newName -VMHost $hostName -DiskStorageFormat Thick -Datastore $dsName -Notes "Clone created $(whoami) $Date"
 
### Configure CPUID in VMX File ###
#Setup a connection to the datastore where the VM is located
New-PSDrive -Location $ds -Name DS -PSProvider VimDatastore -Root "\"
#copies VMX file from vmware datastore location to temporary location on c: drive
copy-datastoreitem -item "DS:$vmname\$vmname.vmx" -destination "c:\scripts\$vmname.vmx" -Force
#Regex to place CPUID settings into vmx file, thank you Ian Morris for the continued assistance with this!
get-childitem "c:\scripts\$vmname.vmx" | % {
$content = get-content $_
[System.Text.StringBuilder] $newContent = New-Object -TypeName "System.Text.StringBuilder"
[int] $i = 0
$stream = [System.IO.StreamWriter] $_.FullName
foreach ($s in $content)
{
if ([Regex]::IsMatch($s, "cpuid\.") -eq $false)
{
$stream.WriteLine($s)
[void]$newContent.Append($s)
}
}
#These are the CPUID lines mask the VM into thinking it has a Intel Xeon 2.7 GHz chip from around 2007
$stream.WriteLine("cpuid.2.eax=`"00000101101100001011000100000001`"")
$stream.WriteLine("cpuid.2.ebx=`"00000000010101100101011111110000`"")
$stream.WriteLine("cpuid.2.ecx=`"00000000000000000000000000000000`"")
$stream.WriteLine("cpuid.2.edx=`"00101100101101000011000001001000`"")
$stream.Close()
} 
#Copy the modified VMX back to the datastore, by default any duplicate named will will be replaced
copy-datastoreitem -item "c:\scripts\$vmname.vmx" -destination "DS:$vmname\$vmname.vmx"
#close the PS Drive connection to the datastore
Remove-PSDrive -Name DS
#Delete the modified VMX file from the windows machine running the script
Remove-item "c:\scripts\$vmname.vmx"
 
### Setup DHCP Scopes ###
#Need to recall the secure stored credentials to connect to the DHCP Servers
$MyCredentials=IMPORT-CLIXML C:\Scripts\SecureCredentials.xml
$DRMyCredentials=IMPORT-CLIXML C:\Scripts\DRSecureCredentials.xml
#Grab the new VMs MAC address and convert the string to a format usable with the DHCP Powershell Module
$vmmac = get-vm $vmName | get-networkadapter
$vmmacalt = $vmmac.MacAddress -replace ":"
 
#Using invoke-command to connect to DHCP servers and setup the DHCP scope reservations and remove the IP address from the available range as a precaution
Invoke-command -computername 10.10.1.1 -Scriptblock {Add-DhcpServerv4Reservation -ScopeId $Using:DHCPScope -IPAddress $Using:IPAddvm -Name $Using:vmName -ClientId $Using:vmmacalt} -credential $MyCredentials
Invoke-command -computername 10.50.1.1 -Scriptblock {Add-DhcpServerv4Reservation -ScopeId $Using:DRDHCPScope -IPAddress $Using:DRIPAddvm -Name $Using:vmName -ClientId $Using:vmmacalt} -credential $DRMyCredentials
Invoke-command -computername 10.10.1.1 -Scriptblock {Add-DhcpServerv4ExclusionRange -ScopeID $Using:DHCPScope -StartRange $Using:DBIPAddvm -EndRange $Using:DBIPAddvm } -credential $MyCredentials
Invoke-command -computername 10.50.1.1 -Scriptblock {Add-DhcpServerv4ExclusionRange -ScopeID $Using:DRDHCPScope -StartRange $Using:DRDBIPAddvm -EndRange $Using:DRDBIPAddvm } -credential $DRMyCredentials
}
 
### Start form
#Add necessary modules and .Net to build GUI form
Import-Module VMware.PowerCLI
Add-Type -AssemblyName System.Windows.Forms
 
#Hide PowerShell Console > code snippet from http://blog.dbsnet.fr/hide-powershell-console-from-a-gui
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0)
 
#Build form based on earlier configuration
 
PickVcenter
