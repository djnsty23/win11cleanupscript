#Requires -RunAsAdministrator
# BackupGamingProfiles.ps1
# Script to backup MSI Afterburner and FanControl profiles

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
Add-Content -Path $logFile -Value "`n=== Gaming Profiles Backup Started at $date ==="

# Backup destination
$backupRoot = Expand-EnvPath $config.gamingProfiles.backupLocation
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$backupFolder = Join-Path $backupRoot $timestamp

# Function to backup a folder
function Backup-Folder {
    param (
        [string]$SourcePath,
        [string]$DestinationPath,
        [string]$Description
    )

    $expandedSource = Expand-EnvPath $SourcePath
    
    if (Test-Path $expandedSource) {
        Add-Content -Path $logFile -Value "Backing up $Description from $expandedSource"
        
        # Create destination folder structure
        $folderName = Split-Path -Leaf $expandedSource
        $targetPath = Join-Path $DestinationPath $folderName
        
        if (-not (Test-Path $targetPath)) {
            New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
        }
        
        # Copy files
        try {
            Copy-Item -Path "$expandedSource\*" -Destination $targetPath -Recurse -Force
            Add-Content -Path $logFile -Value "Successfully backed up $Description to $targetPath"
            return $true
        } catch {
            # Store exception message in temp variable to avoid parsing issues
            $exMessage = ($_.Exception.Message -replace ":", "-")
            Add-Content -Path $logFile -Value "Error backing up $Description: $exMessage"
            return $false
        }
    } else {
        Add-Content -Path $logFile -Value "$Description path not found: $expandedSource (skipping)"
        return $false
    }
}

# Create backup root if it doesn't exist
if (-not (Test-Path $backupRoot)) {
    New-Item -Path $backupRoot -ItemType Directory -Force | Out-Null
    Add-Content -Path $logFile -Value "Created backup folder: $backupRoot"
}

# Create timestamp folder
New-Item -Path $backupFolder -ItemType Directory -Force | Out-Null
Add-Content -Path $logFile -Value "Created timestamp folder: $backupFolder"

# Backup MSI Afterburner profiles
$msiSuccess = $false
foreach ($path in $config.gamingProfiles.backupPaths.msiAfterburner) {
    $result = Backup-Folder -SourcePath $path -DestinationPath $backupFolder -Description "MSI Afterburner profiles"
    if ($result) {
        $msiSuccess = $true
    }
}

# Backup FanControl profiles
$fanSuccess = $false
foreach ($path in $config.gamingProfiles.backupPaths.fanControl) {
    $result = Backup-Folder -SourcePath $path -DestinationPath $backupFolder -Description "FanControl profiles"
    if ($result) {
        $fanSuccess = $true
    }
}

# Cleanup old backups if needed
$maxBackups = $config.gamingProfiles.maxBackups
if ($maxBackups -gt 0) {
    $allBackups = Get-ChildItem -Path $backupRoot -Directory | Sort-Object CreationTime -Descending
    if ($allBackups.Count -gt $maxBackups) {
        $toDelete = $allBackups | Select-Object -Skip $maxBackups
        foreach ($folder in $toDelete) {
            Remove-Item -Path $folder.FullName -Recurse -Force
            Add-Content -Path $logFile -Value "Removed old backup: $($folder.FullName)"
        }
    }
}

# Summary
if ($msiSuccess -or $fanSuccess) {
    Add-Content -Path $logFile -Value "Gaming profiles backup successful"
    Write-Host "Gaming profiles backed up to: $backupFolder" -ForegroundColor Green
} else {
    Add-Content -Path $logFile -Value "No gaming profiles were found to backup"
    Write-Host "No gaming profiles were found to backup. Check if the applications are installed." -ForegroundColor Yellow
}

$endDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logFile -Value "=== Gaming Profiles Backup Completed at $endDate ===" 