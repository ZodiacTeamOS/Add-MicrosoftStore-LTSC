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

# Required packages to download
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
    "Microsoft.WindowsStore_22409.1401.5.0_neutral_~_8wekyb3d8bbwe.Msixbundle",
    "Microsoft.StorePurchaseApp_22408.1401.0.0_neutral_~_8wekyb3d8bbwe.AppxBundle",
    "Microsoft.XboxIdentityProvider_12.115.1001.0_neutral_~_8wekyb3d8bbwe.AppxBundle"
)

# Function to download file
function Download-File {
    param(
        [string]$FileName
    )
    
    $url = "$baseUrl/$FileName"
    $destination = Join-Path $scriptPath $FileName
    
    if (Test-Path $destination) {
        Write-Host "✓ $FileName already exists" -ForegroundColor Green
        return $destination
    }
    
    try {
        Write-Host "Downloading $FileName..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing
        Write-Host "✓ Downloaded $FileName" -ForegroundColor Green
        return $destination
    }
    catch {
        Write-Host "✗ Failed to download $FileName" -ForegroundColor Red
        return $null
    }
}

# Download all packages
Write-Host "`nDownloading packages...`n" -ForegroundColor Yellow
$downloadedFiles = @()
foreach ($package in $packages) {
    $file = Download-File -FileName $package
    if ($file) {
        $downloadedFiles += $file
    }
}

# Download winget separately
Write-Host "`nDownloading latest winget (DesktopAppInstaller)..." -ForegroundColor Cyan
try {
    $wingetPath = Join-Path $scriptPath "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    Invoke-WebRequest -Uri 'https://aka.ms/getwinget' -OutFile $wingetPath -UseBasicParsing
    Write-Host "✓ Downloaded winget" -ForegroundColor Green
    $downloadedFiles += $wingetPath
}
catch {
    Write-Host "✗ Failed to download winget" -ForegroundColor Red
}

$PurchaseApp = Join-Path $scriptPath "Microsoft.StorePurchaseApp_22408.1401.0.0_neutral_~_8wekyb3d8bbwe.AppxBundle"
$XboxIdentity = Join-Path $scriptPath "Microsoft.XboxIdentityProvider_12.115.1001.0_neutral_~_8wekyb3d8bbwe.AppxBundle"
$AppInstaller = $wingetPath

# Function to install AppX packages
function Install-AppxPackages {
    param(
        [string]$Pattern,
        [string]$Name
    )
    
    Write-Host "`n$Name installing..." -ForegroundColor Cyan
    $packages = Get-ChildItem -Path $scriptPath -Filter $Pattern -ErrorAction SilentlyContinue
    
    foreach ($package in $packages) {
        try {
            Add-AppxPackage -Path $package.FullName -ErrorAction Stop
            Write-Host "✓ $Name installed: $($package.Name)" -ForegroundColor Green
        }
        catch {
            Write-Host "✗ Failed to install $($package.Name): $_" -ForegroundColor Red
        }
    }
}

Write-Host "`n=== Installing Packages ===" -ForegroundColor Yellow

# Install x64 packages if system is 64-bit
if ($arch -eq "x64") {
    Install-AppxPackages "*NET.Native.Framework*x64*" "Microsoft.NET.Native.Framework x64"
    Install-AppxPackages "*NET.Native.Runtime*x64*" "Microsoft.NET.Native.Runtime x64"
    Install-AppxPackages "*UI.Xaml*x64*" "Microsoft.UI.Xaml x64"
    Install-AppxPackages "*VCLibs*x64*" "Microsoft.VCLibs x64 and UWP x64"
}

# Install x86 packages (required for both architectures)
Install-AppxPackages "*NET.Native.Framework*x86*" "Microsoft.NET.Native.Framework x86"
Install-AppxPackages "*NET.Native.Runtime*x86*" "Microsoft.NET.Native.Runtime x86"
Install-AppxPackages "*UI.Xaml*x86*" "Microsoft.UI.Xaml x86"
Install-AppxPackages "*VCLibs*x86*" "Microsoft.VCLibs x86 and UWP x86"

# Install Windows Store
Install-AppxPackages "*WindowsStore*" "Microsoft.WindowsStore"

# Install DesktopAppInstaller (winget)
if ($AppInstaller -and (Test-Path $AppInstaller)) {
    Write-Host "`nLatest DesktopAppInstaller (winget) installing..." -ForegroundColor Cyan
    try {
        Add-AppxPackage -Path $AppInstaller -ErrorAction Stop
        Write-Host "✓ Latest DesktopAppInstaller install finished" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed to install DesktopAppInstaller: $_" -ForegroundColor Red
    }
}

# Install optional packages
if ($PurchaseApp -and (Test-Path $PurchaseApp)) {
    Write-Host "`nMicrosoft.StorePurchaseApp installing..." -ForegroundColor Cyan
    try {
        Add-AppxPackage -Path $PurchaseApp -ErrorAction Stop
        Write-Host "✓ Microsoft.StorePurchaseApp install finished" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed to install StorePurchaseApp: $_" -ForegroundColor Red
    }
}

if ($XboxIdentity -and (Test-Path $XboxIdentity)) {
    Write-Host "`nMicrosoft.XboxIdentityProvider installing..." -ForegroundColor Cyan
    try {
        Add-AppxPackage -Path $XboxIdentity -ErrorAction Stop
        Write-Host "✓ Microsoft.XboxIdentityProvider install finished" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed to install XboxIdentityProvider: $_" -ForegroundColor Red
    }
}

# Update packages using winget
Write-Host "`n=== Updating Packages via winget ===" -ForegroundColor Yellow
Start-Sleep -Seconds 3

$wingetCommand = Get-Command winget -ErrorAction SilentlyContinue
if ($wingetCommand) {
    Write-Host "winget is available, updating packages...`n" -ForegroundColor Cyan
    
    # Update all packages
    try {
        winget upgrade --all --accept-source-agreements --accept-package-agreements --silent
        Write-Host "`n✓ Packages updated successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed to update packages via winget" -ForegroundColor Red
    }
    
    # Specifically ensure Microsoft Store is updated
    Write-Host "`nEnsuring Microsoft Store is up to date..." -ForegroundColor Cyan
    try {
        winget upgrade "Microsoft Store" --accept-source-agreements --accept-package-agreements --silent
    }
    catch {
        Write-Host "Microsoft Store is already up to date or update not needed" -ForegroundColor Yellow
    }
}
else {
    Write-Host "winget not found. Please restart your terminal or computer to use winget." -ForegroundColor Yellow
}

# Cleanup temp files
Write-Host "`n=== Cleaning up temporary files ===" -ForegroundColor Yellow
try {
    Remove-Item -Path $scriptPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✓ Cleanup completed" -ForegroundColor Green
}
catch {
    Write-Host "Could not clean up temp files at: $scriptPath" -ForegroundColor Yellow
}

Write-Host "`n=== Installation Complete ===" -ForegroundColor Green
Write-Host "Microsoft Store and winget have been installed successfully!" -ForegroundColor Green
Write-Host "You may need to restart your computer for all changes to take effect.`n" -ForegroundColor Yellow
Read-Host "Press Enter to exit"
