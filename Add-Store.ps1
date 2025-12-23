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

Write-Host "=== Microsoft Store Installer ===" -ForegroundColor Cyan
Write-Host "Downloading required packages from GitHub...`n" -ForegroundColor Yellow

# GitHub Release URL
$githubRepo = "ZodiacTeamOS/Add-MicrosoftStore-LTSC"
$releaseTag = "the_bun"
$baseUrl = "https://github.com/$githubRepo/releases/download/$releaseTag"

# Required packages from list.txt (exact names with 3 underscores)
$packages = @(
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
    "Microsoft.StorePurchaseApp_22408.1401.0.0_neutral___8wekyb3d8bbwe.AppxBundle",
    "Microsoft.XboxIdentityProvider_12.115.1001.0_neutral___8wekyb3d8bbwe.AppxBundle"
)

# DesktopAppInstaller package (separate)
$desktopAppInstaller = "Microsoft.DesktopAppInstaller_2023.808.2243.0_neutral___8wekyb3d8bbwe.Msixbundle"

# Function to download file with progress
function Download-File {
    param(
        [string]$FileName
    )
    
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
        Write-Host "✗ Failed to download: $FileName" -ForegroundColor Red
        return $null
    }
}

# Function to install AppX package silently
function Install-Package {
    param(
        [string]$PackagePath,
        [string]$PackageName
    )
    
    if (-not (Test-Path $PackagePath)) {
        return $false
    }
    
    try {
        Add-AppxPackage -Path $PackagePath -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        Write-Host "✗ Failed to install: $PackageName" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor DarkRed
        return $false
    }
}

# Download and install packages from list
Write-Host "Step 1/3: Downloading and installing core packages..." -ForegroundColor Cyan
$successCount = 0
$totalCount = $packages.Count

foreach ($package in $packages) {
    Write-Host "  Processing: $package" -ForegroundColor Gray
    
    $filePath = Download-File -FileName $package
    if ($filePath) {
        if (Install-Package -PackagePath $filePath -PackageName $package) {
            $successCount++
            Write-Host "  ✓ Installed successfully" -ForegroundColor Green
        }
    }
}

Write-Host "`n$successCount/$totalCount packages installed successfully`n" -ForegroundColor Yellow

# Download and install DesktopAppInstaller
Write-Host "Step 2/3: Installing DesktopAppInstaller (winget)..." -ForegroundColor Cyan
$desktopAppPath = Download-File -FileName $desktopAppInstaller

if ($desktopAppPath) {
    Write-Host "  Installing DesktopAppInstaller..." -ForegroundColor Gray
    if (Install-Package -PackagePath $desktopAppPath -PackageName $desktopAppInstaller) {
        Write-Host "  ✓ DesktopAppInstaller installed successfully" -ForegroundColor Green
    }
} else {
    Write-Host "  Trying to download latest winget from Microsoft..." -ForegroundColor Yellow
    try {
        $wingetPath = Join-Path $scriptPath "Microsoft.DesktopAppInstaller_Latest.msixbundle"
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri 'https://aka.ms/getwinget' -OutFile $wingetPath -UseBasicParsing
        $ProgressPreference = 'Continue'
        
        if (Install-Package -PackagePath $wingetPath -PackageName "DesktopAppInstaller (Latest)") {
            Write-Host "  ✓ Latest DesktopAppInstaller installed successfully" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  ✗ Failed to download/install DesktopAppInstaller" -ForegroundColor Red
    }
}

# Cleanup temp files
Write-Host "`nCleaning up temporary files..." -ForegroundColor Gray
try {
    Remove-Item -Path $scriptPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✓ Cleanup completed`n" -ForegroundColor Green
}
catch {
    Write-Host "Could not clean up temp files`n" -ForegroundColor Yellow
}

# Ask about updating packages
Write-Host "Step 3/3: Package Updates" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Gray

do {
    $choice = Read-Host "`nDo you want to update all packages using winget? (Y/N)"
    $choice = $choice.Trim().Substring(0, 1).ToUpper()
    
    if ($choice -eq "Y") {
        Write-Host "`nChecking for winget..." -ForegroundColor Cyan
        Start-Sleep -Seconds 2
        
        # Refresh environment to detect winget
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        $wingetCommand = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetCommand) {
            Write-Host "✓ winget found, updating packages...`n" -ForegroundColor Green
            
            try {
                Write-Host "Updating all packages (this may take a while)..." -ForegroundColor Yellow
                winget upgrade --all --accept-source-agreements --accept-package-agreements --silent
                
                Write-Host "`n✓ Packages updated successfully" -ForegroundColor Green
            }
            catch {
                Write-Host "✗ Failed to update packages" -ForegroundColor Red
            }
        }
        else {
            Write-Host "✗ winget not found. Please restart your terminal or computer." -ForegroundColor Red
            Write-Host "  Then run: winget upgrade --all" -ForegroundColor Yellow
        }
        break
    }
    elseif ($choice -eq "N") {
        Write-Host "`nSkipping updates. You can update manually later using:" -ForegroundColor Yellow
        Write-Host "  winget upgrade --all" -ForegroundColor Cyan
        break
    }
    else {
        Write-Host "Invalid choice. Please enter Y or N." -ForegroundColor Red
    }
} while ($true)

Write-Host "`n============================================" -ForegroundColor Gray
Write-Host "=== Installation Complete ===" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Gray
Write-Host "`nMicrosoft Store and winget have been installed!" -ForegroundColor Green
Write-Host "You may need to restart your computer for all changes to take effect." -ForegroundColor Yellow
Write-Host "`nPress Enter to exit..." -ForegroundColor Gray
Read-Host
