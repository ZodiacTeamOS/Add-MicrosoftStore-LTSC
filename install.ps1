$ErrorActionPreference = "Stop"

# تأكيد تشغيل كمسؤول
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run PowerShell as Administrator"
    exit 1
}

# فولدر مؤقت
$temp = "$env:TEMP\msstore"
New-Item $temp -ItemType Directory -Force | Out-Null

Write-Host "Downloading dependencies..."

# ===== Dependencies (Microsoft official links) =====
$deps = @(
  "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx",
  "https://aka.ms/Microsoft.UI.Xaml.2.8.x64.appx",
  "https://aka.ms/Microsoft.NET.Native.Framework.2.2.appx",
  "https://aka.ms/Microsoft.NET.Native.Runtime.2.2.appx"
)

foreach ($url in $deps) {
    $out = "$temp\$(Split-Path $url -Leaf)"
    Invoke-WebRequest $url -OutFile $out
    Add-AppxPackage -Path $out
}

Write-Host "Downloading Store packages..."

# ===== Store components (Microsoft CDN via RG-Adguard) =====
$storePkgs = @(
  "Microsoft.WindowsStore",
  "Microsoft.StorePurchaseApp",
  "Microsoft.DesktopAppInstaller",
  "Microsoft.XboxIdentityProvider"
)

$api = "https://store.rg-adguard.net/api/GetFiles"

foreach ($pkg in $storePkgs) {
    $resp = Invoke-WebRequest `
        -Uri $api `
        -Method POST `
        -Body "type=PackageFamilyName&url=$pkg&ring=Retail&lang=en-US" `
        -UseBasicParsing

    $link = ($resp.Links |
        Where-Object href -Match "msixbundle|appxbundle" |
        Where-Object href -Match "x64|neutral" |
        Select-Object -First 1).href

    if (-not $link) {
        Write-Error "Failed to fetch $pkg"
        exit 1
    }

    $out = "$temp\$(Split-Path $link -Leaf)"
    Invoke-WebRequest $link -OutFile $out
    Add-AppxPackage -Path $out -ForceApplicationShutdown
}

Write-Host "Microsoft Store installed successfully."
