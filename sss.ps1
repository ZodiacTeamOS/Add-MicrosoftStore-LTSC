#Requires -RunAsAdministrator

# Check Windows version
$version = [System.Environment]::OSVersion.Version
if ($version.Build -lt 19044) {
    Write-Host "`nError: This script is for Windows 10 version 21H2 and later`n" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# Detect architecture
$arch = if ([System.Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
$scriptPath = Join-Path $env:TEMP "MicrosoftStore"

# Create temp directory
if (-not (Test-Path $scriptPath)) {
    New-Item -ItemType Directory -Path $scriptPath -Force | Out-Null
}

Write-Host "`n=== Microsoft Store Installer for Windows LTSC ===`n" -ForegroundColor Cyan

# GitHub Release URL
$githubRepo = "ZodiacTeamOS/Add-MicrosoftStore-LTSC"
$releaseTag = "the_bun"
$baseUrl = "https://github.com/$githubRepo/releases/download/$releaseTag"

# All packages to download
$allPackages = @(
    "Microsoft.NET.Native.Framework.2.2_2.2.29512.0_x64__8wekyb3d8bbwe.Appx",
    "Microsoft.NET.Native.Framework.2.2_2.2.29512.0_x86__8wekyb3d8bbwe.Appx",
    "Microsoft.NET.Native.Runtime.2.2_2.2.28604.0_x64__8wekyb3d8bbwe.Appx",
    "Microsoft.NET.Native.Runtime.2.2_2.2.28604.0_x86__8wekyb3d8bbwe.Appx",
    "Microsoft.UI.Xaml.2.7_7.2409.9001.0_x64__8wekyb3d8bbwe.Appx",
    "Microsoft.UI.Xaml.2.7_7.2409.9001.0_x86__8wekyb3d8bbwe.Appx",
    "Microsoft.UI.Xaml.2.8_8.2310.30001.0_x64__8wekyb3d8bbwe.Appx",
    "Microsoft.UI.Xaml.2.8_8.2310.30001.0_x86__8wekyb3d8bbwe.Appx",
    "Microsoft.VCLibs.140.00.UWPDesktop_14.0.33728.0_x64__8wekyb3d8bbwe.Appx",
    "Microsoft.VCLibs.140.00.UWPDesktop_14.0.33728.0_x86__8wekyb3d8bbwe.Appx",
    "Microsoft.VCLibs.140.00_14.0.33519.0_x64__8wekyb3d8bbwe.Appx",
    "Microsoft.VCLibs.140.00_14.0.33519.0_x86__8wekyb3d8bbwe.Appx",
    "Microsoft.WindowsStore_22409.1401.5.0_neutral___8wekyb3d8bbwe.Msixbundle",
    "Microsoft.DesktopAppInstaller_2023.808.2243.0_neutral___8wekyb3d8bbwe.Msixbundle",
    "Microsoft.StorePurchaseApp_22408.1401.0.0_neutral___8wekyb3d8bbwe.AppxBundle",
    "Microsoft.XboxIdentityProvider_12.115.1001.0_neutral___8wekyb3d8bbwe.AppxBundle",
    "Microsoft.GamingServices_33.108.12001.0_neutral_~_8wekyb3d8bbwe.AppxBundle",
    "Microsoft.Xbox.TCUI_1.24.10001.0_neutral_~_8wekyb3d8bbwe.AppxBundle"
)

# Function to show progress bar
function Show-Progress {
    param(
        [int]$Current,
        [int]$Total,
        [string]$Activity
    )
    
    $percent = [math]::Round(($Current / $Total) * 100)
    $barLength = 50
    $completed = [math]::Floor(($percent / 100) * $barLength)
    $remaining = $barLength - $completed
    
    # Use simple characters for better compatibility
    $bar = "[" + ("#" * $completed) + ("-" * $remaining) + "]"
    
    Write-Host "`r$Activity $bar $percent%" -NoNewline -ForegroundColor Cyan
}

# Function to download file silently
function Download-File {
    param([string]$FileName)
    
    $url = "$baseUrl/$FileName"
    $destination = Join-Path $scriptPath $FileName
    
    if (Test-Path $destination) {
        return $destination
    }
    
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing -ErrorAction Stop
        $ProgressPreference = 'Continue'
        return $destination
    }
    catch {
        $ProgressPreference = 'Continue'
        return $null
    }
}

# Function to install package silently
function Install-AppxSilent {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        return $false
    }
    
    try {
        # Suppress all output including deployment progress
        Add-AppxPackage -Path $Path -ErrorAction Stop *>&1 | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Phase 1: Download
Write-Host "Downloading packages..." -ForegroundColor Yellow
$totalPackages = $allPackages.Count
$currentPackage = 0

foreach ($pkg in $allPackages) {
    $currentPackage++
    Show-Progress -Current $currentPackage -Total $totalPackages -Activity "Download"
    Download-File -FileName $pkg | Out-Null
}

Write-Host "`n" # New line after progress bar

# Phase 2: Install
Write-Host "Installing packages..." -ForegroundColor Yellow
$installOrder = @()

# Build install order based on architecture
if ($arch -eq "x64") {
    $installOrder += Get-ChildItem -Path $scriptPath -Filter "*NET.Native.Framework*x64*"
    $installOrder += Get-ChildItem -Path $scriptPath -Filter "*NET.Native.Runtime*x64*"
    $installOrder += Get-ChildItem -Path $scriptPath -Filter "*UI.Xaml*x64*"
    $installOrder += Get-ChildItem -Path $scriptPath -Filter "*VCLibs*x64*"
}

$installOrder += Get-ChildItem -Path $scriptPath -Filter "*NET.Native.Framework*x86*"
$installOrder += Get-ChildItem -Path $scriptPath -Filter "*NET.Native.Runtime*x86*"
$installOrder += Get-ChildItem -Path $scriptPath -Filter "*UI.Xaml*x86*"
$installOrder += Get-ChildItem -Path $scriptPath -Filter "*VCLibs*x86*"
$installOrder += Get-ChildItem -Path $scriptPath -Filter "*WindowsStore*"
$installOrder += Get-ChildItem -Path $scriptPath -Filter "*DesktopAppInstaller*"
$installOrder += Get-ChildItem -Path $scriptPath -Filter "*StorePurchaseApp*" -ErrorAction SilentlyContinue
$installOrder += Get-ChildItem -Path $scriptPath -Filter "*XboxIdentityProvider*" -ErrorAction SilentlyContinue
$installOrder += Get-ChildItem -Path $scriptPath -Filter "*GamingServices*" -ErrorAction SilentlyContinue
$installOrder += Get-ChildItem -Path $scriptPath -Filter "*Xbox.TCUI*" -ErrorAction SilentlyContinue

$totalInstalls = $installOrder.Count
$currentInstall = 0

foreach ($package in $installOrder) {
    if ($package) {
        $currentInstall++
        Show-Progress -Current $currentInstall -Total $totalInstalls -Activity "Install "
        Install-AppxSilent -Path $package.FullName | Out-Null
    }
}

Write-Host "`n" # New line after progress bar

# Cleanup
Remove-Item -Path $scriptPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "✓ Installation completed!`n" -ForegroundColor Green

# Phase 3: Update
Write-Host "`nDo you want to update the installed packages? (Y/N): " -NoNewline -ForegroundColor Cyan
$choice = $null
while ($null -eq $choice -or ($choice -ne "Y" -and $choice -ne "N")) {
    if ($Host.UI.RawUI.KeyAvailable) {
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        $choice = $key.Character.ToString().ToUpper()
        if ($choice -eq "Y" -or $choice -eq "N") {
            Write-Host $choice
            break
        }
    }
    Start-Sleep -Milliseconds 100
}

if ($choice -eq "Y") {
    Write-Host "Preparing to update packages...`n" -ForegroundColor Yellow
    Write-Host "Note: This requires opening a new PowerShell window to refresh winget." -ForegroundColor Yellow
    Write-Host "The new window will handle updates and close automatically.`n" -ForegroundColor Yellow
    
    Start-Sleep -Seconds 2
    
    # Create a temporary script for updates
    $updateScript = @"
# Update Script
`$Host.UI.RawUI.WindowTitle = "Microsoft Store - Updating Packages"
Write-Host "=== Updating Packages ===" -ForegroundColor Cyan
Write-Host ""

# Refresh PATH
`$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Wait for winget to be available
`$retries = 0
while (`$retries -lt 10) {
    `$wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if (`$wingetCmd) {
        break
    }
    Start-Sleep -Seconds 2
    `$retries++
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "✗ winget not found. Please restart your computer and run:" -ForegroundColor Red
    Write-Host "  winget upgrade --all" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    `$null = [Console]::ReadKey(`$true)
    exit
}

Write-Host "Updating packages..." -ForegroundColor Yellow

# Function to show progress bar
function Show-Progress {
    param(
        [int]`$Current,
        [int]`$Total,
        [string]`$Activity
    )
    
    `$percent = [math]::Round((`$Current / `$Total) * 100)
    `$barLength = 50
    `$completed = [math]::Floor((`$percent / 100) * `$barLength)
    `$remaining = `$barLength - `$completed
    
    `$bar = "[" + ("█" * `$completed) + ("░" * `$remaining) + "]"
    
    Write-Host "`r`$Activity `$bar `$percent%" -NoNewline -ForegroundColor Cyan
}

# Update packages silently
`$packagesToUpdate = @(
    "Microsoft.DesktopAppInstaller",
    "Microsoft.WindowsStore",
    "Microsoft.StorePurchaseApp",
    "Microsoft.XboxIdentityProvider"
)

`$totalUpdates = `$packagesToUpdate.Count
`$currentUpdate = 0

foreach (`$pkg in `$packagesToUpdate) {
    `$currentUpdate++
    Show-Progress -Current `$currentUpdate -Total `$totalUpdates -Activity "Update  "
    winget upgrade --id `$pkg --exact --accept-source-agreements --accept-package-agreements --silent 2>&1 | Out-Null
}

Write-Host "`n"
Write-Host "✓ Updates completed!`n" -ForegroundColor Green

# Ask about Feedback Hub
Write-Host "`nDo you want to install Feedback Hub from Microsoft Store? (Y/N): " -NoNewline -ForegroundColor Cyan
`$feedbackChoice = `$null
while (`$null -eq `$feedbackChoice -or (`$feedbackChoice -ne "Y" -and `$feedbackChoice -ne "N")) {
    if (`$Host.UI.RawUI.KeyAvailable) {
        `$key = `$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        `$feedbackChoice = `$key.Character.ToString().ToUpper()
        if (`$feedbackChoice -eq "Y" -or `$feedbackChoice -eq "N") {
            Write-Host `$feedbackChoice
            break
        }
    }
    Start-Sleep -Milliseconds 100
}

if (`$feedbackChoice -eq "Y") {
    Write-Host "Installing Feedback Hub..." -ForegroundColor Yellow
    `$feedbackOutput = winget install "Feedback Hub" --source msstore --accept-source-agreements --accept-package-agreements --silent 2>&1 | Out-Null
    
    if (`$LASTEXITCODE -eq 0) {
        Write-Host "✓ Feedback Hub installed successfully!`n" -ForegroundColor Green
    } else {
        Write-Host "✗ Could not install Feedback Hub.`n" -ForegroundColor Red
    }
} else {
    Write-Host "Skipping Feedback Hub installation.`n" -ForegroundColor Yellow
}

Write-Host "============================================" -ForegroundColor Gray
Write-Host "All done!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Gray
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
`$null = [Console]::ReadKey(`$true)
"@
    
    $updateScriptPath = Join-Path $env:TEMP "MicrosoftStore_Update.ps1"
    $updateScript | Out-File -FilePath $updateScriptPath -Encoding UTF8 -Force
    
    # Launch new PowerShell window with the update script
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$updateScriptPath`"" -Wait
    
    # Cleanup
    Remove-Item -Path $updateScriptPath -Force -ErrorAction SilentlyContinue
}
else {
    Write-Host "Skipping updates.`n" -ForegroundColor Yellow
    
    # Ask about Feedback Hub
    Write-Host "Do you want to install Feedback Hub from Microsoft Store? (Y/N): " -NoNewline -ForegroundColor Cyan
    $feedbackChoice = $null
    while ($null -eq $feedbackChoice -or ($feedbackChoice -ne "Y" -and $feedbackChoice -ne "N")) {
        if ($Host.UI.RawUI.KeyAvailable) {
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            $feedbackChoice = $key.Character.ToString().ToUpper()
            if ($feedbackChoice -eq "Y" -or $feedbackChoice -eq "N") {
                Write-Host $feedbackChoice
                break
            }
        }
        Start-Sleep -Milliseconds 100
    }
    
    if ($feedbackChoice -eq "Y") {
        Write-Host "`nInstalling Feedback Hub..." -ForegroundColor Yellow
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        Start-Sleep -Seconds 2
        
        $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetCmd) {
            try {
                winget install "Feedback Hub" --source msstore --accept-source-agreements --accept-package-agreements --silent 2>&1 | Out-Null
                Write-Host "✓ Feedback Hub installed successfully!`n" -ForegroundColor Green
            }
            catch {
                Write-Host "✗ Could not install Feedback Hub.`n" -ForegroundColor Red
            }
        }
        else {
            Write-Host "✗ winget not available yet." -ForegroundColor Red
            Write-Host "Please restart your terminal and run:" -ForegroundColor Yellow
            Write-Host "  winget install `"Feedback Hub`" --source msstore`n" -ForegroundColor Cyan
        }
    }
    else {
        Write-Host "`nSkipping Feedback Hub installation.`n" -ForegroundColor Yellow
    }
}

Write-Host "`n============================================" -ForegroundColor Gray
Write-Host "All done! You may need to restart your PC." -ForegroundColor Green
Write-Host "============================================`n" -ForegroundColor Gray
Write-Host "Press any key to exit..." -ForegroundColor Gray
while (-not $Host.UI.RawUI.KeyAvailable) {
    Start-Sleep -Milliseconds 100
}
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
