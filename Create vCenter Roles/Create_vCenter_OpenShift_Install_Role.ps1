 <#
.SYNOPSIS
    Create_vCenter_OpenShift_Install_Role.ps1 - PowerShell Script to create a new vCenter Roles algined with the prereqs for the OpenShift Container Platform Install. 
.DESCRIPTION
    This script is used to create a new roles on your vCenter server.
    The newly created role will be filled with the needed permissions for installing OpenShift Container Platform using the IPI Method.
    The permissions are based on the documentation found here: https://docs.openshift.com/container-platform/4.6/installing/installing_vsphere/installing-vsphere-installer-provisioned.html#installation-vsphere-installer-infra-requirements_installing-vsphere-installer-provisioned
.OUTPUTS
    Results are printed to the console.
.NOTES
    Author        Dean Lewis, https://vEducate.co.uk, Twitter: @saintdle
    
    Change Log    V1.00, 07/11/2020 - Initial version
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

# Create OpenShift-Install role
$OpenShiftInstallPrivilege = @(
    'System.Anonymous',
    'System.View',
    'System.Read',
    'Folder.Create',
    'Folder.Delete',
    'Datastore.Browse',
    'Datastore.DeleteFile',
    'Datastore.FileManagement',
    'Datastore.AllocateSpace',
    'Network.Assign',
    'VirtualMachine.Inventory.Create',
    'VirtualMachine.Inventory.CreateFromExisting',
    'VirtualMachine.Inventory.Register',
    'VirtualMachine.Inventory.Delete',
    'VirtualMachine.Inventory.Unregister',
    'VirtualMachine.Inventory.Move',
    'VirtualMachine.Interact.PowerOn',
    'VirtualMachine.Interact.PowerOff',
    'VirtualMachine.Interact.Suspend',
    'VirtualMachine.Interact.SuspendToMemory',
    'VirtualMachine.Interact.Reset',
    'VirtualMachine.Interact.Pause',
    'VirtualMachine.Interact.AnswerQuestion',
    'VirtualMachine.Interact.ConsoleInteract',
    'VirtualMachine.Interact.DeviceConnection',
    'VirtualMachine.Interact.SetCDMedia',
    'VirtualMachine.Interact.SetFloppyMedia',
    'VirtualMachine.Interact.ToolsInstall',
    'VirtualMachine.Interact.GuestControl',
    'VirtualMachine.Interact.DefragmentAllDisks',
    'VirtualMachine.Interact.CreateSecondary',
    'VirtualMachine.Interact.TurnOffFaultTolerance',
    'VirtualMachine.Interact.MakePrimary',
    'VirtualMachine.Interact.TerminateFaultTolerantVM',
    'VirtualMachine.Interact.DisableSecondary',
    'VirtualMachine.Interact.EnableSecondary',
    'VirtualMachine.Interact.Record',
    'VirtualMachine.Interact.Replay',
    'VirtualMachine.Interact.Backup',
    'VirtualMachine.Interact.CreateScreenshot',
    'VirtualMachine.Interact.PutUsbScanCodes',
    'VirtualMachine.Interact.SESparseMaintenance',
    'VirtualMachine.Interact.DnD',
    'VirtualMachine.GuestOperations.Query',
    'VirtualMachine.GuestOperations.Modify',
    'VirtualMachine.GuestOperations.Execute',
    'VirtualMachine.GuestOperations.QueryAliases',
    'VirtualMachine.GuestOperations.ModifyAliases',
    'VirtualMachine.Config.Rename',
    'VirtualMachine.Config.Annotation',
    'VirtualMachine.Config.AddExistingDisk',
    'VirtualMachine.Config.AddNewDisk',
    'VirtualMachine.Config.RemoveDisk',
    'VirtualMachine.Config.RawDevice',
    'VirtualMachine.Config.HostUSBDevice',
    'VirtualMachine.Config.CPUCount',
    'VirtualMachine.Config.Memory',
    'VirtualMachine.Config.AddRemoveDevice',
    'VirtualMachine.Config.EditDevice',
    'VirtualMachine.Config.Settings',
    'VirtualMachine.Config.Resource',
    'VirtualMachine.Config.UpgradeVirtualHardware',
    'VirtualMachine.Config.ResetGuestInfo',
    'VirtualMachine.Config.ToggleForkParent',
    'VirtualMachine.Config.AdvancedConfig',
    'VirtualMachine.Config.DiskLease',
    'VirtualMachine.Config.SwapPlacement',
    'VirtualMachine.Config.DiskExtend',
    'VirtualMachine.Config.ChangeTracking',
    'VirtualMachine.Config.QueryUnownedFiles',
    'VirtualMachine.Config.ReloadFromPath',
    'VirtualMachine.Config.QueryFTCompatibility',
    'VirtualMachine.Config.MksControl',
    'VirtualMachine.Config.ManagedBy',
    'VirtualMachine.State.CreateSnapshot',
    'VirtualMachine.State.RevertToSnapshot',
    'VirtualMachine.State.RemoveSnapshot',
    'VirtualMachine.State.RenameSnapshot',
    'VirtualMachine.Hbr.ConfigureReplication',
    'VirtualMachine.Hbr.ReplicaManagement',
    'VirtualMachine.Hbr.MonitorReplication',
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
    'VirtualMachine.Provisioning.DiskRandomAccess',
    'VirtualMachine.Provisioning.DiskRandomRead',
    'VirtualMachine.Provisioning.FileRandomAccess',
    'VirtualMachine.Provisioning.GetVmFiles',
    'VirtualMachine.Provisioning.PutVmFiles',
    'VirtualMachine.Namespace.Management',
    'VirtualMachine.Namespace.Query',
    'VirtualMachine.Namespace.ModifyContent',
    'VirtualMachine.Namespace.ReadContent',
    'VirtualMachine.Namespace.Event',
    'VirtualMachine.Namespace.EventNotify',
    'Resource.AssignVMToPool',
    'VApp.ResourceConfig',
    'VApp.InstanceConfig',
    'VApp.ApplicationConfig',
    'VApp.ManagedByConfig',
    'VApp.Export',
    'VApp.Import',
    'VApp.PullFromUrls',
    'VApp.ExtractOvfEnvironment',
    'VApp.AssignVM',
    'VApp.AssignResourcePool',
    'VApp.AssignVApp',
    'VApp.Clone',
    'VApp.Create',
    'VApp.Delete',
    'VApp.Unregister',
    'VApp.Move',
    'VApp.PowerOn',
    'VApp.PowerOff',
    'VApp.Suspend',
    'VApp.Rename',
    'InventoryService.Tagging.AttachTag',
    'InventoryService.Tagging.ModifyUsedByForCategory',
    'InventoryService.Tagging.DeleteCategory',
    'InventoryService.Tagging.EditTag',
    'InventoryService.Tagging.ModifyUsedByForTag',
    'InventoryService.Tagging.CreateTag',
    'InventoryService.Tagging.DeleteTag',
    'InventoryService.Tagging.ObjectAttachable',
    'StorageProfile.Update',
    'StorageProfile.View',
    'InventoryService.Tagging.EditCategory',
    'InventoryService.Tagging.CreateCategory'
)
$OpenShiftInstallRole = New-VIRole -Name 'OpenShift-Install' -Privilege (Get-VIPrivilege -Id $OpenShiftInstallPrivilege) | Out-Null
Write-Host "Creating vCenter role $OpenShiftInstallRole" -ForegroundColor Green

# Disconnecting from the vCenter Server
Disconnect-VIServer -Confirm:$false
Write-Host "Disconnected from your vCenter Server $vCenterServer" -ForegroundColor Green
 
