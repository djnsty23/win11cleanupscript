# Windows 11 Daily Cleanup Script
# This script performs daily system cleanup operations silently

# Requires -RunAsAdministrator

# Load configuration
$configPath = Join-Path $PSScriptRoot "config.json"
$config = Get-Content $configPath | ConvertFrom-Json

# Function to expand environment variables in paths
function Expand-EnvPath {
    param (
        [string]$Path
    )
    [System.Environment]::ExpandEnvironmentVariables($Path)
}

# Initialize logging
$logFile = Expand-EnvPath $config.logging.path
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logFile -Value "=== Daily Cleanup Started at $date ==="

# Function to safely remove folder contents with progress
function Remove-FolderContents {
    param (
        [string]$Path,
        [string]$Description
    )
    
    $expandedPath = Expand-EnvPath $Path
    if (Test-Path $expandedPath) {
        Add-Content -Path $logFile -Value "Cleaning $Description..."
        Write-Progress -Activity "System Cleanup" -Status "Cleaning $Description" -PercentComplete 0
        
        try {
            $items = Get-ChildItem -Path $expandedPath -Force
            $total = $items.Count
            $current = 0
            
            foreach ($item in $items) {
                $current++
                $percent = ($current / $total) * 100
                Write-Progress -Activity "System Cleanup" -Status "Cleaning $Description" -PercentComplete $percent -CurrentOperation $item.Name
                
                try {
                    Remove-Item $item.FullName -Force -Recurse -ErrorAction Stop
                } catch {
                    $errMsg = $_.Exception.Message
                    Add-Content -Path $logFile -Value ("Could not remove " + $item.FullName + ": " + $errMsg)
                }
            }
            
            Write-Progress -Activity "System Cleanup" -Status "Cleaning $Description" -PercentComplete 100 -Completed
            Add-Content -Path $logFile -Value "Successfully cleaned $Description"
        } catch {
            Write-Progress -Activity "System Cleanup" -Status "Cleaning $Description" -PercentComplete 100 -Completed
            $errMsg = $_.Exception.Message
            Add-Content -Path $logFile -Value ("Error cleaning " + $Description + ": " + $errMsg)
        }
    } else {
        Add-Content -Path $logFile -Value "$Description path not found: $expandedPath"
    }
}

# Function to clean Chrome cache while preserving important data
function Remove-ChromeCache {
    param (
        [string]$CachePath,
        [string[]]$PreservePatterns
    )
    
    if (Test-Path $CachePath) {
        Add-Content -Path $logFile -Value "Cleaning Chrome Cache..."
        Write-Progress -Activity "System Cleanup" -Status "Cleaning Chrome Cache" -PercentComplete 0
        
        try {
            $items = Get-ChildItem -Path $CachePath -Force
            $total = $items.Count
            $current = 0
            
            foreach ($item in $items) {
                $current++
                $percent = ($current / $total) * 100
                Write-Progress -Activity "System Cleanup" -Status "Cleaning Chrome Cache" -PercentComplete $percent -CurrentOperation $item.Name
                
                $shouldPreserve = $false
                foreach ($pattern in $PreservePatterns) {
                    if ($item.Name -like $pattern) {
                        $shouldPreserve = $true
                        break
                    }
                }
                
                if (-not $shouldPreserve) {
                    try {
                        Remove-Item $item.FullName -Force -Recurse -ErrorAction Stop
                    } catch {
                        Add-Content -Path $logFile -Value "Could not remove Chrome cache item $($item.FullName): $($_.Exception.Message)"
                    }
                }
            }
            
            Write-Progress -Activity "System Cleanup" -Status "Cleaning Chrome Cache" -PercentComplete 100 -Completed
            Add-Content -Path $logFile -Value "Chrome Cache cleaned successfully"
        } catch {
            Write-Progress -Activity "System Cleanup" -Status "Cleaning Chrome Cache" -PercentComplete 100 -Completed
            Add-Content -Path $logFile -Value "Error cleaning Chrome Cache: $($_.Exception.Message)"
        }
    }
}

# Main cleanup operations
try {
    # Empty Recycle Bin
    Write-Progress -Activity "System Cleanup" -Status "Emptying Recycle Bin" -PercentComplete 0
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Add-Content -Path $logFile -Value "Recycle Bin emptied."
    Write-Progress -Activity "System Cleanup" -Status "Emptying Recycle Bin" -PercentComplete 100 -Completed
    
    # Clean Temp files
    foreach ($tempPath in $config.cleanup.paths.temp) {
        Remove-FolderContents -Path $tempPath -Description "Temp folder"
    }
    
    # Clean Windows Update Cache
    Write-Progress -Activity "System Cleanup" -Status "Cleaning Windows Update Cache" -PercentComplete 0
    try {
        Stop-Service -Name $config.cleanup.services.windowsUpdate -Force -ErrorAction Stop
        Remove-FolderContents -Path $config.cleanup.paths.windowsUpdate -Description "Windows Update cache"
        Start-Service -Name $config.cleanup.services.windowsUpdate
        Add-Content -Path $logFile -Value "Windows Update Cache cleared."
    } catch {
        Add-Content -Path $logFile -Value "Error managing Windows Update service: $($_.Exception.Message)"
    }
    Write-Progress -Activity "System Cleanup" -Status "Cleaning Windows Update Cache" -PercentComplete 100 -Completed
    
    # Clean Chrome Cache
    Remove-ChromeCache -CachePath $config.cleanup.paths.chromeCache -PreservePatterns $config.cleanup.preservePatterns.chrome
    
    # Clean Windows Store Cache
    Remove-FolderContents -Path $config.cleanup.paths.windowsStore -Description "Windows Store cache"
    
    # Clean Thumbnail Cache
    Write-Progress -Activity "System Cleanup" -Status "Cleaning Thumbnail Cache" -PercentComplete 0
    try {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Remove-FolderContents -Path $config.cleanup.paths.thumbnails -Description "Thumbnail cache"
        Start-Process explorer.exe
        Add-Content -Path $logFile -Value "Windows Thumbnail cache cleared."
    } catch {
        Add-Content -Path $logFile -Value "Error managing Thumbnail cache: $($_.Exception.Message)"
    }
    Write-Progress -Activity "System Cleanup" -Status "Cleaning Thumbnail Cache" -PercentComplete 100 -Completed
    
    # Clean Prefetch
    Remove-FolderContents -Path $config.cleanup.paths.prefetch -Description "Prefetch"
    
    # Clean Recent Items
    Remove-FolderContents -Path $config.cleanup.paths.recent -Description "Recent Items"
    
    # Clean Windows Error Reports
    Remove-FolderContents -Path $config.cleanup.paths.errorReports -Description "Windows Error Reports"
    
    # Run Disk Cleanup
    Write-Progress -Activity "System Cleanup" -Status "Running Disk Cleanup" -PercentComplete 0
    Add-Content -Path $logFile -Value "Running Disk Cleanup..."
    $regKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
    Get-ChildItem $regKey | ForEach-Object {
        Set-ItemProperty -Path "$regKey\$($_.PSChildName)" -Name "StateFlags0064" -Value 2 -Type DWord -ErrorAction SilentlyContinue
    }
    Start-Process cleanmgr.exe -ArgumentList "/sagerun:64" -Wait -NoNewWindow
    Add-Content -Path $logFile -Value "Disk Cleanup completed."
    Write-Progress -Activity "System Cleanup" -Status "Running Disk Cleanup" -PercentComplete 100 -Completed
    
    # Clean old logs
    $logRetentionDate = (Get-Date).AddDays(-$config.logging.retentionDays)
    Get-ChildItem -Path (Split-Path $logFile) -Filter "CleanupLog*.txt" | 
    Where-Object { $_.LastWriteTime -lt $logRetentionDate } | 
    ForEach-Object {
        Remove-Item $_.FullName -Force
        Add-Content -Path $logFile -Value "Removed old log file: $($_.Name)"
    }
    
} catch {
    Add-Content -Path $logFile -Value "Critical error during cleanup: $($_.Exception.Message)"
    Write-Progress -Activity "System Cleanup" -Status "Error" -PercentComplete 100 -Completed
    exit 1
}

$endDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logFile -Value "=== Daily Cleanup Completed at $endDate ==="
Write-Progress -Activity "System Cleanup" -Status "Complete" -PercentComplete 100 -Completed 