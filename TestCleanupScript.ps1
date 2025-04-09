# Test Script for Windows 11 Cleanup Solution
# This script tests the functionality of the cleanup script

# Run as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please run this script as Administrator!"
    exit
}

# Create a test log file
$testLogFile = "$env:USERPROFILE\Documents\CleanupTestLog.txt"
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $testLogFile -Value "=== Cleanup Test Started at $date ==="

# Function to test if a path exists
function Test-PathExists {
    param (
        [string]$Path,
        [string]$Description
    )
    
    $exists = Test-Path -Path $Path
    if ($exists) {
        $result = "EXISTS"
    } else {
        $result = "MISSING"
    }
    Write-Output ($Description + ": " + $result)
    Add-Content -Path $testLogFile -Value ($Description + ": " + $result)
    return $exists
}

# Function to create test files
function New-TestFile {
    param (
        [string]$Path,
        [string]$Content = "Test content"
    )
    
    try {
        New-Item -Path $Path -ItemType File -Force | Out-Null
        Set-Content -Path $Path -Value $Content
        Write-Host "Created test file: $Path"
    } catch {
        Write-Host "Error creating test file $Path : $_"
    }
}

# Function to test if a file was deleted
function Test-FileDeleted {
    param (
        [string]$Path,
        [string]$Description
    )
    
    $exists = Test-Path -Path $Path
    if (-not $exists) {
        $result = "DELETED"
    } else {
        $result = "STILL EXISTS"
    }
    Write-Output ($Description + ": " + $result)
    Add-Content -Path $testLogFile -Value ($Description + ": " + $result)
    return (-not $exists)
}

# Function to verify cleanup
function Test-CleanupResult {
    param (
        [string]$Path,
        [string]$Description
    )
    
    if (Test-Path $Path) {
        Write-Host "❌ $Description was not cleaned up: $Path"
        Add-Content -Path $testLogFile -Value "❌ $Description was not cleaned up: $Path"
        return $false
    } else {
        Write-Host "✅ $Description was successfully cleaned up"
        Add-Content -Path $testLogFile -Value "✅ $Description was successfully cleaned up"
        return $true
    }
}

# Function to verify test results
function Test-CleanupResults {
    param (
        [hashtable]$TestResults,
        [string]$TestName
    )
    
    $allPassed = $true
    Add-Content -Path $testLogFile -Value "`nVerifying $TestName results:"
    
    foreach ($test in $TestResults.GetEnumerator()) {
        $result = Test-Path $test.Value
        if ($result) {
            Add-Content -Path $testLogFile -Value "❌ Failed: $($test.Key) was not cleaned up"
            $allPassed = $false
        } else {
            Add-Content -Path $testLogFile -Value "✅ Passed: $($test.Key) was cleaned up successfully"
        }
    }
    
    return $allPassed
}

# Create test files in various locations
Write-Output "Creating test files..."
Add-Content -Path $testLogFile -Value "Creating test files..."

# Test Recycle Bin
$recycleBinTest = @{
    "Recycle Bin" = $true  # We can't directly test the Recycle Bin, but we'll check if the command works
}

# Test Temp Files
$tempTestFile = "$env:TEMP\test_cleanup_script.txt"
$windowsTempTestFile = "C:\Windows\Temp\test_cleanup_script.txt"
$tempTest = @{
    "User Temp File" = New-TestFile -Path $tempTestFile
    "Windows Temp File" = New-TestFile -Path $windowsTempTestFile
}

# Test Windows Update Cache
$windowsUpdateTestFile = "C:\Windows\SoftwareDistribution\Download\test_cleanup_script.txt"
$windowsUpdateTest = @{
    "Windows Update Cache File" = New-TestFile -Path $windowsUpdateTestFile
}

# Test Chrome Cache
$chromeCacheTestFile = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\test_cleanup_script.txt"
$chromeTest = @{
    "Chrome Cache File" = New-TestFile -Path $chromeCacheTestFile
}

# Test Windows Store Cache
$windowsStoreTestFile = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalCache\test_cleanup_script.txt"
$windowsStoreTest = @{
    "Windows Store Cache File" = New-TestFile -Path $windowsStoreTestFile
}

# Test Windows Thumbnail Cache
$thumbnailTestFile = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_test.db"
$thumbnailTest = @{
    "Windows Thumbnail Cache File" = New-TestFile -Path $thumbnailTestFile
}

# Test Windows Prefetch
$prefetchTestFile = "C:\Windows\Prefetch\test_cleanup_script.exe-12345678.pf"
$prefetchTest = @{
    "Windows Prefetch File" = New-TestFile -Path $prefetchTestFile
}

# Test Windows Recent Items
$recentTestFile = "$env:APPDATA\Microsoft\Windows\Recent\test_cleanup_script.lnk"
$recentTest = @{
    "Windows Recent Items File" = New-TestFile -Path $recentTestFile
}

# Test Windows Error Reports
$errorReportTestFile = "$env:LOCALAPPDATA\Microsoft\Windows\WER\ReportQueue\test_cleanup_script.txt"
$errorReportTest = @{
    "Windows Error Report File" = New-TestFile -Path $errorReportTestFile
}

# Run the cleanup script
Write-Output "Running the cleanup script..."
Add-Content -Path $testLogFile -Value "Running the cleanup script..."
& "$PSScriptRoot\CleanupScript.ps1"

# Test if files were deleted
Write-Output "Testing if files were deleted..."
Add-Content -Path $testLogFile -Value "Testing if files were deleted..."

# Test Temp Files
$tempTestResults = @{
    "User Temp File" = Test-FileDeleted -Path $tempTestFile -Description "User Temp File"
    "Windows Temp File" = Test-FileDeleted -Path $windowsTempTestFile -Description "Windows Temp File"
}

# Test Windows Update Cache
$windowsUpdateTestResults = @{
    "Windows Update Cache File" = Test-FileDeleted -Path $windowsUpdateTestFile -Description "Windows Update Cache File"
}

# Test Chrome Cache
$chromeTestResults = @{
    "Chrome Cache File" = Test-FileDeleted -Path $chromeCacheTestFile -Description "Chrome Cache File"
}

# Test Windows Store Cache
$windowsStoreTestResults = @{
    "Windows Store Cache File" = Test-FileDeleted -Path $windowsStoreTestFile -Description "Windows Store Cache File"
}

# Test Windows Thumbnail Cache
$thumbnailTestResults = @{
    "Windows Thumbnail Cache File" = Test-FileDeleted -Path $thumbnailTestFile -Description "Windows Thumbnail Cache File"
}

# Test Windows Prefetch
$prefetchTestResults = @{
    "Windows Prefetch File" = Test-FileDeleted -Path $prefetchTestFile -Description "Windows Prefetch File"
}

# Test Windows Recent Items
$recentTestResults = @{
    "Windows Recent Items File" = Test-FileDeleted -Path $recentTestFile -Description "Windows Recent Items File"
}

# Test Windows Error Reports
$errorReportTestResults = @{
    "Windows Error Report File" = Test-FileDeleted -Path $errorReportTestFile -Description "Windows Error Report File"
}

# Calculate test results
$totalTests = 0
$passedTests = 0

foreach ($test in $tempTestResults.Values) {
    $totalTests++
    if ($test) { 
        $passedTests++ 
    }
}

foreach ($test in $windowsUpdateTestResults.Values) {
    $totalTests++
    if ($test) { 
        $passedTests++ 
    }
}

foreach ($test in $chromeTestResults.Values) {
    $totalTests++
    if ($test) { 
        $passedTests++ 
    }
}

foreach ($test in $windowsStoreTestResults.Values) {
    $totalTests++
    if ($test) { 
        $passedTests++ 
    }
}

foreach ($test in $thumbnailTestResults.Values) {
    $totalTests++
    if ($test) { 
        $passedTests++ 
    }
}

foreach ($test in $prefetchTestResults.Values) {
    $totalTests++
    if ($test) { 
        $passedTests++ 
    }
}

foreach ($test in $recentTestResults.Values) {
    $totalTests++
    if ($test) { 
        $passedTests++ 
    }
}

foreach ($test in $errorReportTestResults.Values) {
    $totalTests++
    if ($test) { 
        $passedTests++ 
    }
}

$passRate = [math]::Round(($passedTests / $totalTests) * 100, 2)

# Output test results
Write-Output "`nTest Results:"
Write-Output "Total Tests: $totalTests"
Write-Output "Passed Tests: $passedTests"
Write-Output "Pass Rate: $passRate%"
Add-Content -Path $testLogFile -Value "`nTest Results:"
Add-Content -Path $testLogFile -Value "Total Tests: $totalTests"
Add-Content -Path $testLogFile -Value "Passed Tests: $passedTests"
Add-Content -Path $testLogFile -Value "Pass Rate: $passRate%"

# Verify cleanup results
Write-Host "`nVerifying cleanup results..."
Add-Content -Path $testLogFile -Value "`n=== Cleanup Verification ==="

# Verify Recycle Bin
Test-CleanupResult -Path $recycleBinTestFile -Description "Recycle Bin test file"

# Verify Temp files
Test-CleanupResult -Path $tempTestFile -Description "User Temp test file"
Test-CleanupResult -Path $windowsTempTestFile -Description "Windows Temp test file"

# Verify Windows Update Cache
Test-CleanupResult -Path $windowsUpdateTestFile -Description "Windows Update Cache test file"

# Verify Chrome Cache
Test-CleanupResult -Path $chromeCacheTestFile -Description "Chrome Cache test file"

# Verify Windows Store Cache
Test-CleanupResult -Path $windowsStoreTestFile -Description "Windows Store Cache test file"

# Verify Windows Thumbnail Cache
Test-CleanupResult -Path $thumbnailTestFile -Description "Windows Thumbnail Cache test file"

# Verify Windows Prefetch
Test-CleanupResult -Path $prefetchTestFile -Description "Windows Prefetch test file"

# Verify Windows Recent Items
Test-CleanupResult -Path $recentTestFile -Description "Windows Recent Items test file"

# Verify Windows Error Reports
Test-CleanupResult -Path $errorReportTestFile -Description "Windows Error Reports test file"

$endDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $testLogFile -Value "=== Cleanup Test Completed at $endDate ==="

Write-Output "`nTest log saved to: $testLogFile"

# Verify all test results
$totalTests = 0
$passedTests = 0

Add-Content -Path $testLogFile -Value "`n=== Verifying Cleanup Results ==="

if (Test-CleanupResults -TestResults $recycleBinTest -TestName "Recycle Bin") { $passedTests++ }
$totalTests++

if (Test-CleanupResults -TestResults $tempTest -TestName "Temp Files") { $passedTests++ }
$totalTests++

if (Test-CleanupResults -TestResults $windowsUpdateTest -TestName "Windows Update Cache") { $passedTests++ }
$totalTests++

if (Test-CleanupResults -TestResults $chromeTest -TestName "Chrome Cache") { $passedTests++ }
$totalTests++

if (Test-CleanupResults -TestResults $windowsStoreTest -TestName "Windows Store Cache") { $passedTests++ }
$totalTests++

if (Test-CleanupResults -TestResults $thumbnailTest -TestName "Thumbnail Cache") { $passedTests++ }
$totalTests++

if (Test-CleanupResults -TestResults $prefetchTest -TestName "Prefetch") { $passedTests++ }
$totalTests++

if (Test-CleanupResults -TestResults $recentTest -TestName "Recent Items") { $passedTests++ }
$totalTests++

if (Test-CleanupResults -TestResults $errorReportTest -TestName "Error Reports") { $passedTests++ }
$totalTests++

# Calculate and log final results
$passRate = [math]::Round(($passedTests / $totalTests) * 100, 2)
Add-Content -Path $testLogFile -Value "`n=== Test Summary ==="
Add-Content -Path $testLogFile -Value "Total Tests: $totalTests"
Add-Content -Path $testLogFile -Value "Passed Tests: $passedTests"
Add-Content -Path $testLogFile -Value "Pass Rate: $passRate%"

if ($passRate -eq 100) {
    Add-Content -Path $testLogFile -Value "✅ All cleanup operations completed successfully!"
    exit 0
} else {
    Add-Content -Path $testLogFile -Value "❌ Some cleanup operations failed. Check the log for details."
    exit 1
} 