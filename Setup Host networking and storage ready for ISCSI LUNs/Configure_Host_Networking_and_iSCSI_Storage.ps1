<#
.SYNOPSIS
    Configure_Host_Networking_and_iSCSI_Storage.ps1 - PowerShell Script configure a VMware ESXi host's networking and setup the iSCSI Software Adapter
.DESCRIPTION
    You can read more about this script the decisions made in its design here: https://veducate.co.uk/powercli-setup-host-networking-and-storage-ready-for-iscsi-luns
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

#Setup which host to target 
$VMhost = 'hostname'

#Create vSwitch2 for storage, add vmnics, add two vmkernels with Storage IPs, setup NIC teaming (based on the fact you probably have vSwitch0 for mgmt and vSwitch1 for VM traffic)

$vswitch2 = get-vmhost $VMhost | new-virtualswitch -Name vSwitch2 -Nic 'vmnic2','vmnic5' -Mtu 9000 -NumPorts 120

New-VMHostNetworkAdapter -VMhost $VMhost -virtualswitch $vswitch2 -portgroup iSCSI_ESX_01 -ip IP_ADDR -subnetmask SUBNET_MASK -Mtu 9000

New-VMHostNetworkAdapter -VMhost $VMhost -virtualswitch $vswitch2 -portgroup iSCSI_ESX_02 -ip IP_ADDR -subnetmask SUBNET_MASK -Mtu 9000

Get-VirtualPortGroup -VMhost $VMhost -virtualswitch $vswitch2 -Name iSCSI_ESX_01 | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive vmnic2 -MakeNicUnused vmnic5

Get-VirtualPortGroup -VMhost $VMhost -virtualswitch $vswitch2 -Name iSCSI_ESX_02 | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive vmnic5 -MakeNicUnused vmnic2

#Create Software iSCSI Adapter

get-vmhoststorage $vmhost | set-vmhoststorage -softwareiscsienabled $True

#Get Software iSCSI adapter HBA number and put it into an array

$HBA = Get-VMHostHba -VMHost $VMHost -Type iSCSI | %{$_.Device}

#Set your VMKernel numbers, Use ESXCLI to create the iSCSI Port binding in the iSCSI Software Adapter

$vmk1number = 'vmk1'
$vmk2number = 'vmk2'
$esxcli = Get-EsxCli -VMhost $VMhost
$Esxcli.iscsi.networkportal.add($HBA, $Null, $vmk1number)
$Esxcli.iscsi.networkportal.add($HBA, $Null, $vmk2number)

#Setup the Discovery iSCSI IP addresses on the iSCSI Software Adapter

$hbahost = get-vmhost $VMhost | get-vmhosthba -type iscsi
new-iscsihbatarget -iscsihba $hbahost -address IP_ADDR

#Rescan the HBA to discover any storage
get-vmhoststorage $VMhost -rescanallhba -rescanvmfs
