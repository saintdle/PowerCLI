 <#
.SYNOPSIS
    Create-CNS-Roles.ps1 - PowerShell Script to create a new vCenter Roles algined with the prereqs for the Kubernetes vSphere CSI Driver. 
.DESCRIPTION
    This script is used to create a new roles on your vCenter server.
    The newly created role will be filled with the needed permissions for using it with Kubernetes vSphere CSI Driver.
    The permissions are based on the documentation found here: https://vsphere-csi-driver.sigs.k8s.io/driver-deployment/prerequisites.html
.OUTPUTS
    Results are printed to the console.
.NOTES
    Author        Dean Lewis, https://vEducate.co.uk, Twitter: @saintdle
    
    Change Log    V1.00, 28/05/2020 - Initial version
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

# Create CNS-DATASTORE role
$CNSDatastorePrivilege = @(
    'Cns.Searchable',
    'Datastore.FileManagement',
    'System.Anonymous',
    'System.Read',
    'System.View'
)
$CNSDatastoreRole = New-VIRole -Name 'CNS-DATASTORE' -Privilege (Get-VIPrivilege -Id $CNSDatastorePrivilege) | Out-Null
Write-Host "Creating vCenter role $CNSDatastoreRolee" -ForegroundColor Green

# Create CNS-HOST-CONFIG-STORAGE role
$CNSHostConfigStoragePrivilege = @(
    'Host.Config.Storage',
    'System.Anonymous',
    'System.Read',
    'System.View'
)
$CNSHostConfigStorage = New-VIRole -Name 'CNS-HOST-CONFIG-STORAGE' -Privilege (Get-VIPrivilege -Id $CNSHostConfigStoragePrivilege) | Out-Null
Write-Host "Creating vCenter role $CNSHostConfigStorage" -ForegroundColor Green

# Create CNS-VM role
$CNSVMPrivilege = @(
    'VirtualMachine.Config.AddExistingDisk',
    'VirtualMachine.Config.AddRemoveDevice'
    'System.Anonymous',
    'System.Read',
    'System.View'
)
$CNSVM = New-VIRole -Name 'CNS-VM' -Privilege (Get-VIPrivilege -Id $CNSVMPrivilege) | Out-Null
Write-Host "Creating vCenter role $CNSVM" -ForegroundColor Green

# Create CNS-SEARCH-AND-SPBM role
$CNSSearchAndSPBMPrivilege = @(
    'VirtualMachine.Config.AddExistingDisk',
    'VirtualMachine.Config.AddRemoveDevice'
    'System.Anonymous',
    'System.Read',
    'System.View'
)
$CNSSearchAndSPBM = New-VIRole -Name 'CNS-SEARCH-AND-SPBM' -Privilege (Get-VIPrivilege -Id $CNSSearchAndSPBMPrivilege) | Out-Null
Write-Host "Creating vCenter role $CNSSearchAndSPBM" -ForegroundColor Green


# Disconnecting from the vCenter Server
Disconnect-VIServer -Confirm:$false
Write-Host "Disconnected from your vCenter Server $vCenterServer" -ForegroundColor Green
 
