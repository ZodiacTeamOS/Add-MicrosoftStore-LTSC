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

Write-Host "=== Microsoft Store Installer for Windows LTSC ===" -ForegroundColor Cyan
Write-Host "Downloading packages from GitHub...`n" -ForegroundColor Yellow

# GitHub Release URL
$githubRepo = "ZodiacTeamOS/Add-MicrosoftStore-LTSC"
$releaseTag = "the_bun"
$baseUrl = "https://github.com/$githubRepo/releases/download/$releaseTag"

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
        Write-Host "  ✓ $FileName" -ForegroundColor Green
        return $destination
    }
    catch {
        $ProgressPreference = 'Continue'
        Write-Host "  ✗ Failed: $FileName" -ForegroundColor Red
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
        Add-AppxPackage -Path $Path -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Download all required packages
Write-Host "Downloading all packages..." -ForegroundColor Cyan

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
    "Microsoft.XboxIdentityProvider_12.115.1001.0_neutral___8wekyb3d8bbwe.AppxBundle"
)

foreach ($pkg in $allPackages) {
    Download-File -FileName $pkg | Out-Null
}

Write-Host "`nAll packages downloaded!`n" -ForegroundColor Green

# Install packages in correct order (following the original .cmd logic)
Write-Host "Installing packages in correct order...`n" -ForegroundColor Cyan

# Step 1: Install x64 dependencies (if 64-bit system)
if ($arch -eq "x64") {
    Write-Host "Installing x64 dependencies..." -ForegroundColor Yellow
    
    Get-ChildItem -Path $scriptPath -Filter "*NET.Native.Framework*x64*" | ForEach-Object {
        if (Install-AppxSilent -Path $_.FullName) {
            Write-Host "  ✓ $($_.Name)" -ForegroundColor Green
        }
    }
    
    Get-ChildItem -Path $scriptPath -Filter "*NET.Native.Runtime*x64*" | ForEach-Object {
        if (Install-AppxSilent -Path $_.FullName) {
            Write-Host "  ✓ $($_.Name)" -ForegroundColor Green
        }
    }
    
    Get-ChildItem -Path $scriptPath -Filter "*UI.Xaml*x64*" | ForEach-Object {
        if (Install-AppxSilent -Path $_.FullName) {
            Write-Host "  ✓ $($_.Name)" -ForegroundColor Green
        }
    }
    
    Get-ChildItem -Path $scriptPath -Filter "*VCLibs*x64*" | ForEach-Object {
        if (Install-AppxSilent -Path $_.FullName) {
            Write-Host "  ✓ $($_.Name)" -ForegroundColor Green
        }
    }
}

# Step 2: Install x86 dependencies (required for all systems)
Write-Host "`nInstalling x86 dependencies..." -ForegroundColor Yellow

Get-ChildItem -Path $scriptPath -Filter "*NET.Native.Framework*x86*" | ForEach-Object {
    if (Install-AppxSilent -Path $_.FullName) {
        Write-Host "  ✓ $($_.Name)" -ForegroundColor Green
    }
}

Get-ChildItem -Path $scriptPath -Filter "*NET.Native.Runtime*x86*" | ForEach-Object {
    if (Install-AppxSilent -Path $_.FullName) {
        Write-Host "  ✓ $($_.Name)" -ForegroundColor Green
    }
}

Get-ChildItem -Path $scriptPath -Filter "*UI.Xaml*x86*" | ForEach-Object {
    if (Install-AppxSilent -Path $_.FullName) {
        Write-Host "  ✓ $($_.Name)" -ForegroundColor Green
    }
}

Get-ChildItem -Path $scriptPath -Filter "*VCLibs*x86*" | ForEach-Object {
    if (Install-AppxSilent -Path $_.FullName) {
        Write-Host "  ✓ $($_.Name)" -ForegroundColor Green
    }
}

# Step 3: Install Microsoft Store
Write-Host "`nInstalling Microsoft Store..." -ForegroundColor Yellow

Get-ChildItem -Path $scriptPath -Filter "*WindowsStore*" | ForEach-Object {
    if (Install-AppxSilent -Path $_.FullName) {
        Write-Host "  ✓ $($_.Name)" -ForegroundColor Green
    }
}

# Step 4: Install DesktopAppInstaller (winget)
Write-Host "`nInstalling DesktopAppInstaller (winget)..." -ForegroundColor Yellow

Get-ChildItem -Path $scriptPath -Filter "*DesktopAppInstaller*" | ForEach-Object {
    if (Install-AppxSilent -Path $_.FullName) {
        Write-Host "  ✓ $($_.Name)" -ForegroundColor Green
    }
}

# Step 5: Install optional packages
$purchaseAppPath = Get-ChildItem -Path $scriptPath -Filter "*StorePurchaseApp*" -ErrorAction SilentlyContinue
if ($purchaseAppPath) {
    Write-Host "`nInstalling StorePurchaseApp..." -ForegroundColor Yellow
    if (Install-AppxSilent -Path $purchaseAppPath.FullName) {
        Write-Host "  ✓ $($purchaseAppPath.Name)" -ForegroundColor Green
    }
}

$xboxIdentityPath = Get-ChildItem -Path $scriptPath -Filter "*XboxIdentityProvider*" -ErrorAction SilentlyContinue
if ($xboxIdentityPath) {
    Write-Host "`nInstalling XboxIdentityProvider..." -ForegroundColor Yellow
    if (Install-AppxSilent -Path $xboxIdentityPath.FullName) {
        Write-Host "  ✓ $($xboxIdentityPath.Name)" -ForegroundColor Green
    }
}

# Cleanup
Write-Host "`nCleaning up..." -ForegroundColor Gray
Remove-Item -Path $scriptPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n✓ Installation completed successfully!`n" -ForegroundColor Green

# Ask about updates
Write-Host "============================================" -ForegroundColor Gray
do {
    $choice = Read-Host "Do you want to update the installed packages using winget? (Y/N)"
    if ($choice) {
        $choice = $choice.Trim().Substring(0, 1).ToUpper()
    }
    
    if ($choice -eq "Y") {
        Write-Host "`nChecking for updates..." -ForegroundColor Cyan
        Start-Sleep -Seconds 2
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetCmd) {
            Write-Host "Updating installed packages...`n" -ForegroundColor Yellow
            
            # List of packages to update (only what we installed)
            $packagesToUpdate = @(
                "Microsoft.DesktopAppInstaller",
                "Microsoft.WindowsStore",
                "Microsoft.StorePurchaseApp",
                "Microsoft.XboxIdentityProvider",
                "Microsoft.NET.Native.Framework.2.2",
                "Microsoft.NET.Native.Runtime.2.2",
                "Microsoft.UI.Xaml.2.7",
                "Microsoft.UI.Xaml.2.8",
                "Microsoft.VCLibs.140.00"
            )
            
            $updatedCount = 0
            $skippedCount = 0
            
            foreach ($package in $packagesToUpdate) {
                Write-Host "Checking: $package..." -ForegroundColor Gray
                
                # Try to upgrade the package
                $result = winget upgrade --id $package --exact --accept-source-agreements --accept-package-agreements --silent 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  ✓ Updated: $package" -ForegroundColor Green
                    $updatedCount++
                }
                else {
                    Write-Host "  ○ No update available or already latest: $package" -ForegroundColor DarkGray
                    $skippedCount++
                }
            }
            
            Write-Host "`n============================================" -ForegroundColor Gray
            Write-Host "Update Summary:" -ForegroundColor Cyan
            Write-Host "  Updated: $updatedCount package(s)" -ForegroundColor Green
            Write-Host "  Skipped: $skippedCount package(s)" -ForegroundColor Gray
            Write-Host "============================================" -ForegroundColor Gray
        }
        else {
            Write-Host "✗ winget not found. Please restart your terminal." -ForegroundColor Red
            Write-Host "Then manually update with: winget upgrade <package-name>" -ForegroundColor Yellow
        }
        break
    }
    elseif ($choice -eq "N") {
        Write-Host "`nSkipping updates." -ForegroundColor Yellow
        break
    }
    else {
        Write-Host "Invalid input. Please enter Y or N." -ForegroundColor Red
    }
} while ($true)

Write-Host "`n============================================" -ForegroundColor Gray
Write-Host "All done! You may need to restart your PC." -ForegroundColor Green
Write-Host "============================================`n" -ForegroundColor Gray
Read-Host "Press Enter to exit"
