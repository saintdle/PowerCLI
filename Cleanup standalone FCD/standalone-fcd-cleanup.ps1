<# 
.SYNOPSIS
    Enterprise-grade cleanup tool for standalone First Class Disks (FCDs) not managed by CNS in vSphere.

.DESCRIPTION
    - Identifies and optionally deletes orphaned FCDs (FCDs not managed by CNS).
    - Handles multiple or existing vCenter sessions.
    - Logs all actions and creates CSV report.
    - Runs in single session for stability (no parallelism).
    - Dry-run enabled by default for safety.

.VERSION
    5.0 - Production safe version with serial deletion, session-safe, fully annotated.

.AUTHOR
    Dean Lewis (@saintdle) | https://bsky.app/profile/saintdle.bsky.social

.SOURCE
    https://github.com/saintdle/PowerCLI

.LICENSE
    MIT License
#>

param (
    [switch]$AutoDelete,            
    [switch]$DryRun = $true         
)

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

function Select-vCenterSession {
    if ($null -ne $global:defaultviserver -and $global:defaultviserver.IsConnected) {
        Write-Host "`nExisting vCenter session found: $($global:defaultviserver.Name)" -ForegroundColor Cyan
        $useDefault = Read-Host "Use this session? Type YES to proceed, NO to select or connect"
        if ($useDefault -eq "YES") {
            return $global:defaultviserver
        }
    }

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

function Connect-NewvCenter {
    $vCenter = Read-Host -Prompt "Enter vCenter FQDN/IP"
    Connect-VIServer -Server $vCenter -ErrorAction Stop
}

function Cleanup-StandaloneFCDs {
    $scriptStart = Get-Date

    try {
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host "   vSphere Standalone FCD Cleanup Tool v5" -ForegroundColor Cyan
        Write-Host "==========================================" -ForegroundColor Cyan

        $session = Select-vCenterSession
        if (-not $session) {
            $session = Connect-NewvCenter
        }

        Import-Module VMware.VimAutomation.Storage -ErrorAction Stop

        $vCenterName = $session.Name
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $global:LogFile = ".\\FCD-Cleanup-$($vCenterName)-$timestamp.log"
        $reportFile = ".\\StandaloneFCDs-$($vCenterName)-$timestamp.csv"

        Write-Log "=========================================="
        Write-Log " Connected to: $vCenterName"
        Write-Log " DryRun: $DryRun"
        Write-Log " AutoDelete: $AutoDelete"
        Write-Log "=========================================="

        Write-Log "Retrieving all FCDs..."
        $allFCDs = Get-VDisk

        Write-Log "Retrieving all CNS volumes..."
        $cnsVolumes = Get-CnsVolume
        $cnsBackingIds = $cnsVolumes | ForEach-Object { $_.BackingObjectId }

        $orphanedFCDs = $allFCDs | Where-Object { $cnsBackingIds -notcontains $_.Id }

        if ($orphanedFCDs.Count -eq 0) {
            Write-Log "No standalone FCDs found." "SUCCESS"
        } else {
            Write-Log "Found $($orphanedFCDs.Count) orphaned FCD(s)." "WARNING"
            $orphanedFCDs | Select-Object Name, Id, CapacityGB, Datastore, CreatedTime |
                Export-Csv -Path $reportFile -NoTypeInformation
            Write-Log "Exported report: $reportFile"

            if ($DryRun) {
                Write-Log "Dry run mode ON. No deletions will occur." "INFO"
            } elseif (-not $AutoDelete) {
                $confirm = Read-Host "Delete these orphaned FCDs? Type YES to proceed"
                if ($confirm -ne "YES") {
                    Write-Log "User cancelled deletion step." "INFO"
                    return
                }
            }

            if (-not $DryRun) {
                Write-Log "Starting serial deletion..." "INFO"
                $count = 0
                foreach ($fcd in $orphanedFCDs) {
                    $count++
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

        $duration = (Get-Date) - $scriptStart
        Write-Log "=========================================="
        Write-Log " Completed in $($duration.TotalMinutes.ToString("0.00")) minutes."
        Write-Log "=========================================="
    } catch {
        Write-Log "Fatal error: $_" "ERROR"
    } finally {
        if (Get-VIServer) {
            Disconnect-VIServer -Server * -Confirm:$false
            Write-Log "Disconnected from vCenter." "INFO"
        }
    }
}

Cleanup-StandaloneFCDs
