<# 
.SYNOPSIS
    Safest enterprise cleanup tool for standalone FCDs not managed by CNS and not attached to any VM.

.DESCRIPTION
    - Detects orphaned FCDs: not in CNS + not attached to any VM
    - Logs all actions, prevents deletion of any attached FCD
    - Safe serial deletion (no parallelism)
    - Dry-run enabled by default for safety
    - Highly annotated for maintainability and learning

.VERSION
    5.1 - Safe orphan detection version with attached disk pre-check and full inline documentation

.AUTHOR
    Dean Lewis (@saintdle) | https://bsky.app/profile/saintdle.bsky.social

.SOURCE
    https://github.com/saintdle/PowerCLI

.LICENSE
    MIT License
#>

# -----------------------
# Script parameters
# -----------------------
param (
    [switch]$AutoDelete,            # Optional: Skip prompt and auto-delete
    [switch]$DryRun = $true         # Optional: Dry run ON by default for safety
)

# -----------------------
# Function: Write-Log
# Purpose: Output message to console and append to log file
# -----------------------
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] $Message"
    Add-Content -Path $global:LogFile -Value $logEntry
    Write-Host $logEntry
}

# -----------------------
# Function: Select-vCenterSession
# Purpose: Check for existing connection or prompt to connect
# -----------------------
function Select-vCenterSession {
    # If PowerCLI already has a default connection, offer to reuse it
    if ($null -ne $global:defaultviserver -and $global:defaultviserver.IsConnected) {
        Write-Host "`nExisting vCenter session found: $($global:defaultviserver.Name)" -ForegroundColor Cyan
        $useDefault = Read-Host "Use this session? Type YES to proceed, NO to select or connect"
        if ($useDefault -eq "YES") {
            return $global:defaultviserver
        }
    }

    # List all connected sessions (if any)
    $sessions = Get-VIServer
    if ($sessions.Count -eq 0) {
        Write-Host "No active vCenter connections found." -ForegroundColor Yellow
        return $null
    }

    Write-Host "`nActive sessions:" -ForegroundColor Cyan
    $i = 1
    foreach ($session in $sessions) {
        Write-Host "$i) $($session.Name) [$($session.User)]"
        $i++
    }

    # Allow user to select session or connect manually
    if ($sessions.Count -eq 1) {
        $useExisting = Read-Host "Use $($sessions[0].Name)? Type YES to proceed"
        if ($useExisting -eq "YES") { return $sessions[0] }
    } else {
        $choice = Read-Host "Enter session number, or 0 to connect manually"
        if ($choice -ne "0" -and $choice -match '^\d+$') {
            return $sessions[$choice - 1]
        }
    }
    return $null
}

# -----------------------
# Function: Connect-NewvCenter
# Purpose: Connect to a new vCenter server
# -----------------------
function Connect-NewvCenter {
    $vCenter = Read-Host -Prompt "Enter vCenter FQDN/IP"
    Connect-VIServer -Server $vCenter -ErrorAction Stop
}

# -----------------------
# Function: Test-FCDAttachedToVM
# Purpose: Checks if an FCD is currently mounted to any VM
# -----------------------
function Test-FCDAttachedToVM {
    param ($FCDId)
    $attached = $false
    $attachedVM = $null

    # Loop through all VMs and check hard disks for filename containing FCD ID
    Get-VM | ForEach-Object {
        $vm = $_
        $vm | Get-HardDisk | Where-Object { $_.Filename -like "*$FCDId*.vmdk" } | ForEach-Object {
            $attached = $true
            $attachedVM = $vm.Name
        }
    }

    return @($attached, $attachedVM)
}

# -----------------------
# Function: Cleanup-StandaloneFCDs
# Purpose: Main logic for identifying and deleting orphaned FCDs
# -----------------------
function Cleanup-StandaloneFCDs {
    $scriptStart = Get-Date

    try {
        # Welcome message
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host "   vSphere Standalone FCD Cleanup Tool v5.1 SAFE" -ForegroundColor Cyan
        Write-Host "==================================================" -ForegroundColor Cyan

        # Check or connect to vCenter
        $session = Select-vCenterSession
        if (-not $session) {
            $session = Connect-NewvCenter
        }

        # Load Storage module required for Remove-VDisk
        Import-Module VMware.VimAutomation.Storage -ErrorAction Stop

        # Setup logging
        $vCenterName = $session.Name
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $global:LogFile = ".\\FCD-Cleanup-$($vCenterName)-$timestamp.log"
        $reportFile = ".\\StandaloneFCDs-$($vCenterName)-$timestamp.csv"

        Write-Log "=================================================="
        Write-Log " Connected to: $vCenterName"
        Write-Log " DryRun: $DryRun"
        Write-Log " AutoDelete: $AutoDelete"
        Write-Log "=================================================="

        # Retrieve all FCDs and CNS volumes
        Write-Log "Retrieving all FCDs..."
        $allFCDs = Get-VDisk

        Write-Log "Retrieving all CNS volumes..."
        $cnsVolumes = Get-CnsVolume
        $cnsBackingIds = $cnsVolumes | ForEach-Object { $_.BackingObjectId }

        # Initial filter: exclude CNS backed disks
        $potentialOrphans = $allFCDs | Where-Object { $cnsBackingIds -notcontains $_.Id }

        if ($potentialOrphans.Count -eq 0) {
            Write-Log "No standalone FCDs found (after CNS filter)." "SUCCESS"
            return
        }

        Write-Log "Found $($potentialOrphans.Count) FCD(s) not part of CNS. Checking for VM attachments..." "WARNING"

        # Secondary filter: exclude any disk attached to a VM
        $finalOrphans = @()
        foreach ($fcd in $potentialOrphans) {
            $result = Test-FCDAttachedToVM -FCDId $fcd.Id
            if ($result[0]) {
                Write-Log "FCD $($fcd.Id) is attached to VM '$($result[1])'. Skipping deletion." "WARNING"
            } else {
                $finalOrphans += $fcd
            }
        }

        if ($finalOrphans.Count -eq 0) {
            Write-Log "No true orphaned FCDs found (not in CNS + not attached)." "SUCCESS"
        } else {
            Write-Log "Found $($finalOrphans.Count) true orphaned FCD(s)." "WARNING"

            # Export report
            $finalOrphans | Select-Object Name, Id, CapacityGB, Datastore, CreatedTime |
                Export-Csv -Path $reportFile -NoTypeInformation
            Write-Log "Exported report: $reportFile"

            # Ask for confirmation if DryRun is OFF
            if ($DryRun) {
                Write-Log "Dry run mode ON. No deletions will occur." "INFO"
            } elseif (-not $AutoDelete) {
                $confirm = Read-Host "Delete these orphaned FCDs? Type YES to proceed"
                if ($confirm -ne "YES") {
                    Write-Log "User cancelled deletion step." "INFO"
                    return
                }
            }

            # Delete FCDs (serial for safety)
            if (-not $DryRun) {
                Write-Log "Starting serial deletion..." "INFO"
                foreach ($fcd in $finalOrphans) {
                    try {
                        $fcd | Remove-VDisk -Confirm:$false -ErrorAction Stop
                        Write-Log "Deleted: $($fcd.Name) [$($fcd.Id)]" "SUCCESS"
                    } catch {
                        Write-Log "Failed to delete $($fcd.Name) [$($fcd.Id)] - $_" "ERROR"
                    }
                }
                Write-Log "All deletions attempted." "SUCCESS"
            }
        }

        # Script finished: report execution time
        $duration = (Get-Date) - $scriptStart
        Write-Log "=================================================="
        Write-Log " Completed in $($duration.TotalMinutes.ToString("0.00")) minutes."
        Write-Log "=================================================="
    } catch {
        Write-Log "Fatal error: $_" "ERROR"
    } finally {
        # Clean up session
        if (Get-VIServer) {
            Disconnect-VIServer -Server * -Confirm:$false
            Write-Log "Disconnected from vCenter." "INFO"
        }
    }
}

# -----------------------
# MAIN: Run the cleanup function
# -----------------------
Cleanup-StandaloneFCDs
