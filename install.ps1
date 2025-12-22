$ErrorActionPreference = "Stop"


# ===============================
# Check Administrator
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
# Temp directory
# ===============================
$temp = "$env:TEMP\msstore"
New-Item $temp -ItemType Directory -Force | Out-Null

# ===============================
# Dependencies (Microsoft official links)
# ===============================
$dependencies = @(
    "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx",
    "https://aka.ms/Microsoft.UI.Xaml.2.8.x64.appx",
    "https://aka.ms/Microsoft.NET.Native.Framework.2.2.appx",
    "https://aka.ms/Microsoft.NET.Native.Runtime.2.2.appx"
)

Write-Host "Installing dependencies..."

foreach ($url in $dependencies) {
    $file = "$temp\$(Split-Path $url -Leaf)"
    Invoke-WebRequest $url -OutFile $file
    Add-AppxPackage -Path $file
}

# ===============================
# Microsoft Store packages
# ===============================
$storePackages = @(
    "Microsoft.XboxIdentityProvider",
    "Microsoft.StorePurchaseApp",
    "Microsoft.DesktopAppInstaller",
    "Microsoft.WindowsStore"
)

$api = "https://store.rg-adguard.net/api/GetFiles"

Write-Host "Installing Microsoft Store components..."

foreach ($pkg in $storePackages) {

    $response = Invoke-WebRequest `
        -Uri $api `
        -Method POST `
        -Body "type=PackageFamilyName&url=$pkg&ring=Retail&lang=en-US" `
        -UseBasicParsing

    $link = ($response.Links |
        Where-Object href -Match "msixbundle|appxbundle" |
        Where-Object href -Match "x64|neutral" |
        Select-Object -First 1).href

    if (-not $link) {
        Write-Error "Failed to download $pkg"
        exit 1
    }

    $file = "$temp\$(Split-Path $link -Leaf)"
    Invoke-WebRequest $link -OutFile $file
    Add-AppxPackage -Path $file -ForceApplicationShutdown
}

Write-Host "Microsoft Store installed successfully."
