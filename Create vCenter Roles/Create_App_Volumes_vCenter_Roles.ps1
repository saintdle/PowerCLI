 <#
.SYNOPSIS
    Create_App_Volumes_vCenter_Roles.ps1 - PowerShell Script to create a new vCenter Roles algined with the prereqs for App Volumes. 
.DESCRIPTION
    This script is used to create a new roles on your vCenter server for App Volumes 2.x, 3.x and 4.x
    The newly created role will be filled with the needed permissions for App Volumes
    The permissions are based on the documentation found here: https://docs.vmware.com/en/VMware-App-Volumes/4/com.vmware.appvolumes.admin.doc/GUID-505624F3-F3EB-428C-BEA0-5BD7F6095A1F.html
.OUTPUTS
    Results are printed to the console.
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

# Load the PowerCLI SnapIn and set the configuration
Add-PSSnapin VMware.VimAutomation.Core -ea "SilentlyContinue"
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

# Get the vCenter Server Name to connect to
$vCenterServer = Read-Host "Enter vCenter Server host name (DNS with FQDN or IP address)"

# Get User to connect to vCenter Server
$vCenterUser = Read-Host "Enter your user name (DOMAIN\User or user@domain.com)"

# Get Password to connect to the vCenter Server
$vCenterUserPassword = Read-Host "Enter your password (this will be converted to a secure string)" -AsSecureString:$true

# Collect username and password as credentials
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $vCenterUser,$vCenterUserPassword

# Connect to the vCenter Server with collected credentials
Connect-VIServer -Server $vCenterServer -Credential $Credentials | Out-Null
Write-Host "Connected to your vCenter server $vCenterServer" -ForegroundColor Green

$cvRole = "App Volumes Role"
$cvRoleIds = @(
    'System.Anonymous',
    'System.View',
    'System.Read',
    'Global.CancelTask',
    'Folder.Create',
    'Folder.Delete',
    'Datastore.Browse',
    'Datastore.DeleteFile',
    'Datastore.FileManagement',
    'Datastore.AllocateSpace',
    'Datastore.UpdateVirtualMachineFiles',
    'Host.Local.CreateVM',
    'Host.Local.ReconfigVM',
    'Host.Local.DeleteVM',
    'VirtualMachine.Inventory.Create',
    'VirtualMachine.Inventory.CreateFromExisting',
    'VirtualMachine.Inventory.Register',
    'VirtualMachine.Inventory.Delete',
    'VirtualMachine.Inventory.Unregister',
    'VirtualMachine.Inventory.Move',
    'VirtualMachine.Interact.PowerOn',
    'VirtualMachine.Interact.PowerOff',
    'VirtualMachine.Interact.Suspend',
    'VirtualMachine.Config.AddExistingDisk',
    'VirtualMachine.Config.AddNewDisk',
    'VirtualMachine.Config.RemoveDisk',
    'VirtualMachine.Config.AddRemoveDevice',
    'VirtualMachine.Config.Settings',
    'VirtualMachine.Config.Resource',
    'VirtualMachine.Provisioning.Customize',
    'VirtualMachine.Provisioning.Clone',
    'VirtualMachine.Provisioning.PromoteDisks',
    'VirtualMachine.Provisioning.CreateTemplateFromVM',
    'VirtualMachine.Provisioning.DeployTemplate',
    'VirtualMachine.Provisioning.CloneTemplate',
    'VirtualMachine.Provisioning.MarkAsTemplate',
    'VirtualMachine.Provisioning.MarkAsVM',
    'VirtualMachine.Provisioning.ReadCustSpecs',
    'VirtualMachine.Provisioning.ModifyCustSpecs',
    'Resource.AssignVMToPool',
    'Task.Create',
    'Sessions.TerminateSession',
)

New-VIRole -name $cvRole -Privilege (Get-VIPrivilege -Server $viserver -id $cvRoleIds) -Server $viserver | Out-Null
Write-Host "Creating vCenter role $cvRole" -ForegroundColor Green
Set-VIRole -Role $cvRole -AddPrivilege (Get-VIPrivilege -Server $viserver -id $cvRoleIds) -Server $viserver | OUt-Null
Write-Host "Setting vCenter role $cvRole" -ForegroundColor Cyan

# Disconnecting from the vCenter Server
Disconnect-VIServer -Confirm:$false
Write-Host "Disconnected from your vCenter Server $vCenterServer" -ForegroundColor Green
