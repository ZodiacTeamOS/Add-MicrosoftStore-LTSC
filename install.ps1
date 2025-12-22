$ErrorActionPreference = "Stop"

# ===============================
# Auto Elevate
# ===============================
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Start-Process powershell `
        -Verb RunAs `
        -ArgumentList "irm https://raw.githubusercontent.com/ZodiacTeamOS/Add-MicrosoftStore-LTSC/main/install.ps1 | iex"
    exit
}

# ===============================
# Windows version check (21H2+)
# ===============================
$build = [int](Get-ComputerInfo).OsBuildNumber
if ($build -lt 19044) {
    Write-Error "This pack is for Windows 10 21H2 (19044) and later"
    exit 1
}

# ===============================
# Arch detect
# ===============================
$arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }

# ===============================
# Temp directory
# ===============================
$temp = "$env:TEMP\msstore"
New-Item $temp -ItemType Directory -Force | Out-Null

# ===============================
# Helper: Install package if not installed
# ===============================
function Install-AppxIfMissing {
    param (
        [string]$Name,
        [string]$Url
    )

    if (Get-AppxPackage -Name $Name -ErrorAction SilentlyContinue) {
        Write-Host "$Name already installed, skipping"
        return
    }

    $file = "$temp\$(Split-Path $Url -Leaf)"
    Invoke-WebRequest $Url -OutFile $file
    Add-AppxPackage -Path $file
}

# ===============================
# Dependencies
# ===============================
Write-Host "Installing dependencies..."

Install-AppxIfMissing `
    "Microsoft.NET.Native.Framework.2.2" `
    "https://aka.ms/Microsoft.NET.Native.Framework.2.2.appx"

Install-AppxIfMissing `
    "Microsoft.NET.Native.Runtime.2.2" `
    "https://aka.ms/Microsoft.NET.Native.Runtime.2.2.appx"

Install-AppxIfMissing `
    "Microsoft.UI.Xaml.2.8" `
    "https://aka.ms/Microsoft.UI.Xaml.2.8.$arch.appx"

Install-AppxIfMissing `
    "Microsoft.VCLibs.140.00.UWPDesktop" `
    "https://aka.ms/Microsoft.VCLibs.$arch.14.00.Desktop.appx"

# ===============================
# Ask for DesktopAppInstaller + winget
# ===============================
$installWinget = Read-Host "Install latest DesktopAppInstaller with winget? (Y/N)"
$installWinget = $installWinget.Substring(0,1).ToUpper()

if ($installWinget -eq "Y") {
    $wingetUrl = "https://aka.ms/getwinget"
    $wingetFile = "$temp\Microsoft.DesktopAppInstaller.msixbundle"
    Invoke-WebRequest $wingetUrl -OutFile $wingetFile
    Add-AppxPackage -Path $wingetFile -ForceApplicationShutdown
}

# ===============================
# Microsoft Store packages
# ===============================
Write-Host "Installing Microsoft Store components..."

$storePackages = @(
    "Microsoft.WindowsStore",
    "Microsoft.StorePurchaseApp",
    "Microsoft.XboxIdentityProvider"
)

$api = "https://store.rg-adguard.net/api/GetFiles"

foreach ($pkg in $storePackages) {

    if (Get-AppxPackage -Name $pkg -ErrorAction SilentlyContinue) {
        Write-Host "$pkg already installed, skipping"
        continue
    }

    $resp = Invoke-WebRequest `
        -Uri $api `
        -Method POST `
        -Body "type=PackageFamilyName&url=$pkg&ring=Retail&lang=en-US" `
        -UseBasicParsing

    $link = ($resp.Links |
        Where-Object href -Match "appxbundle|msixbundle" |
        Where-Object href -Match $arch |
        Select-Object -First 1).href

    if (-not $link) {
        Write-Error "Failed to fetch $pkg"
        exit 1
    }

    $file = "$temp\$(Split-Path $link -Leaf)"
    Invoke-WebRequest $link -OutFile $file
    Add-AppxPackage -Path $file -ForceApplicationShutdown
}

Write-Host ""
Write-Host "========================================"
Write-Host " Microsoft Store installation completed "
Write-Host "========================================"
Write-Host ""
Read-Host "Press Enter to exit"
