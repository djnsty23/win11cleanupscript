# Windows 11 Automated Cleanup & Maintenance Solution

This solution provides automated, silent system cleanup and maintenance for Windows 11.

## Features

*   **Silent Operation**: Runs completely in the background with no popups.
*   **Daily Cleanup (9 PM)**: Performs routine cleanup tasks.
*   **Monthly Maintenance (Approx. 1st Sunday, 1 AM)**: Runs deeper system checks and optimizations.
*   **Safe Deletion**: Skips files currently in use to prevent errors.
*   **Automated Disk Cleanup**: Configures and runs Windows Disk Cleanup without user interaction.
*   **Comprehensive Cleaning**: Targets various temporary files, caches, logs, and browser data (Chrome focused).
*   **Logging**: Records actions and errors to log files in your Documents folder.

## Files Included

1.  `CleanupScript.ps1` - The PowerShell script for **daily** cleanup operations.
2.  `MonthlyMaintenance.ps1` - The PowerShell script for **monthly** maintenance tasks.
3.  `SetupScheduledTask.ps1` - Script to set up the daily and monthly scheduled tasks.
4.  `README.md` - This instruction file.

## What It Cleans/Maintains

**Daily Cleanup (`CleanupScript.ps1`):**

*   Empties the Recycle Bin
*   Removes User Temp Files (`%TEMP%`) (skips files in use)
*   Removes System Temp Files (`C:\Windows\Temp`) (skips files in use)
*   Clears Windows Update cache (skips files in use)
*   Clears Event Logs (attempts to clear all)
*   Runs automated Disk Cleanup (configured via registry)
*   Flushes DNS cache
*   Cleans Chrome cache and history (preserves cookies)
*   Clears Windows Store cache
*   Clears Windows thumbnail cache (restarts explorer.exe)
*   Clears Windows Prefetch files
*   Clears Windows Recent Items
*   Clears Windows Error Reports cache

**Monthly Maintenance (`MonthlyMaintenance.ps1`):**

*   Runs System File Checker (`sfc /scannow`)
*   Repairs Windows image (`DISM /Online /Cleanup-Image /RestoreHealth`)
*   Optimizes all fixed drives (`Optimize-Volume`)

## Setup Instructions

1.  Ensure all script files (`CleanupScript.ps1`, `MonthlyMaintenance.ps1`, `SetupScheduledTask.ps1`) are in the same folder.
2.  Right-click on `SetupScheduledTask.ps1` and select "Run with PowerShell".
3.  **Approve the Administrator elevation prompt (UAC).** This is necessary to create the scheduled tasks that run with high privileges.
4.  The script will configure and register two scheduled tasks:
    *   `Daily System Cleanup` (runs daily at 9:00 PM)
    *   `Monthly System Maintenance` (runs approx. every 4th Sunday at 1:00 AM)

## Manual Execution

While designed for automated use, you can run the scripts manually:

1.  Open PowerShell **as Administrator**.
2.  Navigate to the directory containing the scripts using the `cd` command.
3.  Run the desired script:
    *   `.\CleanupScript.ps1` for daily tasks.
    *   `.\MonthlyMaintenance.ps1` for monthly tasks.

## Logs

Log files are created in your Documents folder:

*   `CleanupLog.txt` (for daily tasks)
*   `MonthlyMaintenanceLog.txt` (for monthly tasks)

Check these logs for details on what was cleaned or if any errors occurred.

## Customization

*   **Schedule**: You can modify the schedule triggers directly in the Windows Task Scheduler.
*   **Cleanup Items**: Edit `CleanupScript.ps1` or `MonthlyMaintenance.ps1` to add/remove specific actions. Be careful when modifying system operations.
*   **Disk Cleanup Items**: The items selected for automated Disk Cleanup are set via registry keys in `CleanupScript.ps1`. Modify the `$cleanupItems` array carefully.

## Security Note

These scripts require administrator privileges to perform system maintenance and modify scheduled tasks. The scheduled tasks are configured to run as the `SYSTEM` account for silent background operation.

## Browser Cleanup

### Chrome (Enhanced)
The script includes enhanced functionality for Chrome on Windows 11:
- Cleans Chrome cache across all user profiles
- Clears browsing history while preserving cookies (to maintain OAuth authentication)
- Automatically closes Chrome if running (to ensure proper cleanup)
- Cleans additional Chrome storage areas
- Handles multiple Chrome profiles

### Other Browsers
For Edge and Firefox, the script includes placeholder functionality that will detect these browsers but not modify cookies or cache. For a complete implementation, SQLite tools would be needed.

## System Maintenance

The enhanced script includes several system maintenance tasks:
- System File Checker to repair corrupted Windows files
- DISM to repair the Windows image
- SSD optimization for systems with solid-state drives
- Clearing of various Windows caches and temporary files 

If you enjoyed the tool, feel free to share a coffee with me at https://ko-fi.com/djnsty. Thanks!
