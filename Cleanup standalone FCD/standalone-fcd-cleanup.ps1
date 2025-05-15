<# 
.SYNOPSIS
    Enterprise-grade cleanup tool for standalone First Class Disks (FCDs) not managed by CNS in vSphere.

.DESCRIPTION
    - Safely identifies and optionally deletes orphaned FCDs.
    - Handles multiple vCenter sessions and connections.
    - Full logging and reporting.
    - Supports parallel deletion (PowerShell 7+).
    - Dry-run enabled by default.

.VERSION
    2.0 - Final version with parallel deletion, logging, vCenter session handling, duration tracking.

.AUTHOR
    Dean Lewis (@saintdle) | https://bsky.app/profile/saintdle.bsky.social

.SOURCE
    https://github.com/saintdle/PowerCLI

.LICENSE
    MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
    documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
    the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
    and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions 
    of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
    TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
    OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
    DEALINGS IN THE SOFTWARE.

.NOTES
    This script requires:
    - VMware PowerCLI module
    - PowerShell 7+ for parallel deletion (Linux pwsh or Windows PS7 Core)
#>

param (
    [switch]$AutoDelete,                  # Optional: Automatically delete without confirmation
    [switch]$DryRun = $true               # Optional: Dry run mode ON by default for safety
)

# ---------------------
# Helper function to write to log file and console
# ---------------------
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

# ---------------------
# Select existing vCenter session or prompt for new
# ---------------------
function Select-vCenterSession {
    $sessions = Get-VIServer
    if ($sessions.Count -eq 0) {
        Write-Host "No active vCenter connections found." -ForegroundColor Yellow
        return $null
    }

    Write-Host "`nActive vCenter connections:" -ForegroundColor Cyan
    $sessions | ForEach-Object -Begin { $i = 1 } -Process {
        Write-Host "$i) $($_.Name) [$($_.User)]"
        $i++
    }

    if ($sessions.Count -eq 1) {
        $useExisting = Read-Host "Use connected vCenter $($sessions[0].Name)? Type YES to use, or NO to connect to another"
        if ($useExisting -eq "YES") { return $sessions[0] }
    } else {
        $choice = Read-Host "Enter the number of the vCenter to use, or 0 to connect to another"
        if ($choice -ne "0") {
            return $sessions[$choice - 1]
        }
    }
    return $null
}

# ---------------------
# Prompt user to connect to a new vCenter
# ---------------------
function Connect-NewvCenter {
    $vCenter = Read-Host -Prompt "Enter vCenter Server FQDN/IP"
    Connect-VIServer -Server $vCenter -ErrorAction Stop
}

# ---------------------
# Main function to clean up orphaned FCDs
# ---------------------
function Cleanup-StandaloneFCDs {
    $scriptStart = Get-Date   # Start timer for duration reporting

    try {
        # -------------------------
        # Script header
        # -------------------------
        Write-Host "==============================" -ForegroundColor Cyan
        Write-Host "   vSphere Standalone FCD Cleanup Tool (Enterprise Edition)" -ForegroundColor Cyan
        Write-Host "==============================" -ForegroundColor Cyan

        # -------------------------
        # Connect to vCenter
        # -------------------------
        $session = Select-vCenterSession
        if (-not $session) {
            $session = Connect-NewvCenter
        }

        $vCenterName = $session.Name
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $global:LogFile = ".\FCD-Cleanup-$($vCenterName)-$timestamp.log"
        $reportFile = ".\StandaloneFCDs-$($vCenterName)-$timestamp.csv"

        # -------------------------
        # Initial log section
        # -------------------------
        Write-Log "=============================="
        Write-Log " Starting vSphere Standalone FCD Cleanup"
        Write-Log " Connected to vCenter: $vCenterName"
        Write-Log " DryRun: $DryRun"
        Write-Log " AutoDelete: $AutoDelete"
        Write-Log " LogFile: $global:LogFile"
        Write-Log "=============================="

        # -------------------------
        # Identify standalone FCDs
        # -------------------------
        Write-Log "Retrieving all FCDs..."
        $allFCDs = Get-VDisk

        Write-Log "Retrieving all CNS volumes..."
        $cnsVolumes = Get-CnsVolume
        $cnsBackingIds = $cnsVolumes | ForEach-Object { $_.BackingObjectId }

        $orphanedFCDs = $allFCDs | Where-Object { $cnsBackingIds -notcontains $_.Id }

        # -------------------------
        # Results
        # -------------------------
        if ($orphanedFCDs.Count -eq 0) {
            Write-Log "No standalone FCDs found." "SUCCESS"
        } else {
            Write-Log "Found $($orphanedFCDs.Count) standalone FCD(s)." "WARNING"
            $orphanedFCDs | Select-Object Name, Id, CapacityGB, Datastore, CreatedTime |
                Export-Csv -Path $reportFile -NoTypeInformation
            Write-Log "Standalone FCD report exported: $reportFile"

            # -------------------------
            # Confirm before deletion (unless AutoDelete)
            # -------------------------
            if ($DryRun) {
                Write-Log "Dry run mode enabled. Skipping deletion." "INFO"
            } elseif (-not $AutoDelete) {
                $confirm = Read-Host "Do you want to delete these FCDs? Type YES to proceed"
                if ($confirm -ne "YES") {
                    Write-Log "User declined deletion. Exiting." "INFO"
                    return
                }
            }

            # -------------------------
            # Parallel deletion (only if DryRun is off)
            # -------------------------
            if (-not $DryRun) {
                Write-Log "Starting parallel deletion of FCDs..." "INFO"
                $orphanedFCDs | ForEach-Object -Parallel {
                    param($fcd)
                    try {
                        Remove-VDisk -Id $fcd.Id -Confirm:$false -ErrorAction Stop
                        "$($fcd.Name) [$($fcd.Id)] successfully deleted." 
                    } catch {
                        "Failed to delete $($fcd.Name) [$($fcd.Id)] - $_"
                    }
                } -ThrottleLimit 5 -ArgumentList ($_)
                Write-Log "All deletions attempted." "SUCCESS"
            }
        }

        # -------------------------
        # Report duration
        # -------------------------
        $duration = (Get-Date) - $scriptStart
        Write-Log "=============================="
        Write-Log " Script completed in $($duration.TotalMinutes.ToString("0.00")) minutes."
        Write-Log "=============================="
    } catch {
        Write-Log "Fatal error occurred: $_" "ERROR"
    } finally {
        # -------------------------
        # Disconnect vCenter sessions
        # -------------------------
        if (Get-VIServer) {
            Disconnect-VIServer -Server * -Confirm:$false
            Write-Log "Disconnected from vCenter(s)." "INFO"
        }
    }
}

# ---------------------
# Execute script
# ---------------------
Cleanup-StandaloneFCDs
