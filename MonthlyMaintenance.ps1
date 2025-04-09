# Windows 11 Monthly Maintenance Script
# This script performs less frequent system maintenance tasks
# Requires -RunAsAdministrator

# Load configuration
$configPath = Join-Path $PSScriptRoot "config.json"
$config = Get-Content $configPath | ConvertFrom-Json

# Initialize logging
$logFile = $config.logging.path
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logFile -Value "`n=== Monthly Maintenance Started at $date ==="

try {
    # Run DISM RestoreHealth
    Write-Progress -Activity "Monthly Maintenance" -Status "Running DISM RestoreHealth" -PercentComplete 0
    Add-Content -Path $logFile -Value "Starting DISM RestoreHealth..."
    
    $dismOutput = Start-Process -FilePath "DISM.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$env:TEMP\dism_output.txt"
    
    if ($dismOutput.ExitCode -eq 0) {
        Add-Content -Path $logFile -Value "DISM RestoreHealth completed successfully."
    } else {
        Add-Content -Path $logFile -Value "DISM RestoreHealth encountered issues. Exit code: $($dismOutput.ExitCode)"
        Add-Content -Path $logFile -Value (Get-Content "$env:TEMP\dism_output.txt")
    }
    
    Remove-Item "$env:TEMP\dism_output.txt" -ErrorAction SilentlyContinue
    Write-Progress -Activity "Monthly Maintenance" -Status "DISM RestoreHealth Complete" -PercentComplete 100
    
    # Optimize-Volume (Defrag for HDDs, TRIM for SSDs)
    Write-Progress -Activity "Monthly Maintenance" -Status "Optimizing Volumes" -PercentComplete 0
    Add-Content -Path $logFile -Value "Starting volume optimization..."
    
    Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' } | ForEach-Object {
        Add-Content -Path $logFile -Value "Optimizing volume $($_.DriveLetter)..."
        Optimize-Volume -DriveLetter $_.DriveLetter -Verbose
    }
    
    Write-Progress -Activity "Monthly Maintenance" -Status "Volume Optimization Complete" -PercentComplete 100
    Add-Content -Path $logFile -Value "Volume optimization completed."
    
} catch {
    Add-Content -Path $logFile -Value "Error during monthly maintenance: $($_.Exception.Message)"
    Write-Progress -Activity "Monthly Maintenance" -Status "Error" -PercentComplete 100
    exit 1
}

$endDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logFile -Value "=== Monthly Maintenance Completed at $endDate ==="
Write-Progress -Activity "Monthly Maintenance" -Status "Complete" -PercentComplete 100 