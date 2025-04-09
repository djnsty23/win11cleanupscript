#Requires -RunAsAdministrator

# Load configuration
$configPath = Join-Path $PSScriptRoot "config.json"
$config = Get-Content $configPath | ConvertFrom-Json

# Initialize logging
$logFile = $config.logging.path
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logFile -Value "=== Task Setup Started at $date ==="

# Function to create or update a scheduled task
function Set-ScheduledTask {
    param (
        [string]$TaskName,
        [string]$ScriptPath,
        [string]$Description,
        [string]$TriggerTime,
        [string]$DayOfWeek = $null,
        [int]$WeekInterval = 1
    )
    
    Write-Progress -Activity "Task Setup" -Status "Configuring $TaskName" -PercentComplete 0
    
    try {
        # Check if task exists
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        
        if ($existingTask) {
            Add-Content -Path $logFile -Value "Updating existing task: $TaskName"
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        } else {
            Add-Content -Path $logFile -Value "Creating new task: $TaskName"
        }
        
        # Create the action
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""
        
        # Create the trigger
        if ($DayOfWeek) {
            $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DayOfWeek -WeeksInterval $WeekInterval -At $TriggerTime
        } else {
            $trigger = New-ScheduledTaskTrigger -Daily -At $TriggerTime
        }
        
        # Create the settings
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        # Create the principal (run with highest privileges)
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        # Register the task
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description $Description -Force
        
        Write-Progress -Activity "Task Setup" -Status "Configuring $TaskName" -PercentComplete 100 -Completed
        Add-Content -Path $logFile -Value "Successfully configured task: $TaskName"
        return $true
    } catch {
        Write-Progress -Activity "Task Setup" -Status "Configuring $TaskName" -PercentComplete 100 -Completed
        Add-Content -Path $logFile -Value "Error configuring task $TaskName : $($_.Exception.Message)"
        return $false
    }
}

# Function to remove a scheduled task
function Remove-ScheduledTask {
    param (
        [string]$TaskName
    )
    
    Write-Progress -Activity "Task Setup" -Status "Removing $TaskName" -PercentComplete 0
    
    try {
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Add-Content -Path $logFile -Value "Successfully removed task: $TaskName"
            Write-Progress -Activity "Task Setup" -Status "Removing $TaskName" -PercentComplete 100 -Completed
            return $true
        } else {
            Add-Content -Path $logFile -Value "Task not found: $TaskName"
            Write-Progress -Activity "Task Setup" -Status "Removing $TaskName" -PercentComplete 100 -Completed
            return $false
        }
    } catch {
        Add-Content -Path $logFile -Value "Error removing task $TaskName : $($_.Exception.Message)"
        Write-Progress -Activity "Task Setup" -Status "Removing $TaskName" -PercentComplete 100 -Completed
        return $false
    }
}

# Main task setup
try {
    # Get script paths
    $cleanupScriptPath = Join-Path $PSScriptRoot "CleanupScript.ps1"
    $maintenanceScriptPath = Join-Path $PSScriptRoot "MonthlyMaintenance.ps1"
    
    # Verify scripts exist
    if (-not (Test-Path $cleanupScriptPath)) {
        throw "CleanupScript.ps1 not found at: $cleanupScriptPath"
    }
    if (-not (Test-Path $maintenanceScriptPath)) {
        throw "MonthlyMaintenance.ps1 not found at: $maintenanceScriptPath"
    }
    
    # Setup daily cleanup task
    $dailyResult = Set-ScheduledTask -TaskName $config.scheduling.dailyCleanup.description `
                                   -ScriptPath $cleanupScriptPath `
                                   -Description "Daily system cleanup task" `
                                   -TriggerTime $config.scheduling.dailyCleanup.time
    
    # Setup monthly maintenance task
    $monthlyResult = Set-ScheduledTask -TaskName $config.scheduling.monthlyMaintenance.description `
                                     -ScriptPath $maintenanceScriptPath `
                                     -Description "Monthly system maintenance task" `
                                     -TriggerTime $config.scheduling.monthlyMaintenance.time `
                                     -DayOfWeek $config.scheduling.monthlyMaintenance.dayOfWeek `
                                     -WeekInterval $config.scheduling.monthlyMaintenance.weekInterval
    
    if ($dailyResult -and $monthlyResult) {
        Add-Content -Path $logFile -Value "All tasks configured successfully"
    } else {
        throw "One or more tasks failed to configure"
    }
    
} catch {
    Add-Content -Path $logFile -Value "Critical error during task setup: $($_.Exception.Message)"
    Write-Progress -Activity "Task Setup" -Status "Error" -PercentComplete 100 -Completed
    exit 1
}

$endDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $logFile -Value "=== Task Setup Completed at $endDate ==="
Write-Progress -Activity "Task Setup" -Status "Complete" -PercentComplete 100 -Completed 