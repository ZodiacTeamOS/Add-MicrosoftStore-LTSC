$ErrorActionPreference = "Stop"
$global:Fail = $false

# ========== Admin ==========
if (-not ([Security.Principal.WindowsPrincipal]
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Start-Process powershell -Verb RunAs `
      -ArgumentList "irm https://raw.githubusercontent.com/USER/REPO/main/install.ps1 | iex"
    exit
}

$base = "https://raw.githubusercontent.com/USER/REPO/main/packages"
$temp = "$env:TEMP\msstore"
New-Item $temp -ItemType Directory -Force | Out-Null

function Install {
    param($url)

    $name = Split-Path $url -Leaf
    $out  = "$temp\$name"

    try {
        Invoke-WebRequest $url -OutFile $out -UseBasicParsing
        Add-AppxPackage -Path $out -ForceApplicationShutdown
    } catch {
        $global:Fail = $true
    }
}

# ========== 1. .NET Native ==========
Install "$base/netnative/x86/Microsoft.NET.Native.Framework.2.2_2.2.29512.0_x86__8wekyb3d8bbwe.Appx"
Install "$base/netnative/x64/Microsoft.NET.Native.Framework.2.2_2.2.29512.0_x64__8wekyb3d8bbwe.Appx"
Install "$base/netnative/x86/Microsoft.NET.Native.Runtime.2.2_2.2.28604.0_x86__8wekyb3d8bbwe.Appx"
Install "$base/netnative/x64/Microsoft.NET.Native.Runtime.2.2_2.2.28604.0_x64__8wekyb3d8bbwe.Appx"

# ========== 2. UI.Xaml ==========
Install "$base/uixaml/x86/Microsoft.UI.Xaml.2.7_7.2409.9001.0_x86__8wekyb3d8bbwe.Appx"
Install "$base/uixaml/x64/Microsoft.UI.Xaml.2.7_7.2409.9001.0_x64__8wekyb3d8bbwe.Appx"
Install "$base/uixaml/x86/Microsoft.UI.Xaml.2.8_8.2310.30001.0_x86__8wekyb3d8bbwe.Appx"
Install "$base/uixaml/x64/Microsoft.UI.Xaml.2.8_8.2310.30001.0_x64__8wekyb3d8bbwe.Appx"

# ========== 3. VCLibs ==========
Install "$base/vclibs/x86/Microsoft.VCLibs.140.00_14.0.33519.0_x86__8wekyb3d8bbwe.Appx"
Install "$base/vclibs/x64/Microsoft.VCLibs.140.00_14.0.33519.0_x64__8wekyb3d8bbwe.Appx"
Install "$base/vclibs/x86/Microsoft.VCLibs.140.00.UWPDesktop_14.0.33728.0_x86__8wekyb3d8bbwe.Appx"
Install "$base/vclibs/x64/Microsoft.VCLibs.140.00.UWPDesktop_14.0.33728.0_x64__8wekyb3d8bbwe.Appx"

# ========== 4. Bundles ==========
Install "$base/bundles/Microsoft.XboxIdentityProvider_12.115.1001.0_neutral___8wekyb3d8bbwe.AppxBundle"
Install "$base/bundles/Microsoft.Xbox.TCUI_1.24.10001.0_neutral_~_8wekyb3d8bbwe.AppxBundle"
Install "$base/bundles/Microsoft.GamingServices_33.108.12001.0_neutral_~_8wekyb3d8bbwe.AppxBundle"
Install "$base/bundles/Microsoft.StorePurchaseApp_22408.1401.0.0_neutral___8wekyb3d8bbwe.AppxBundle"
Install "$base/bundles/Microsoft.DesktopAppInstaller_2023.808.2243.0_neutral___8wekyb3d8bbwe.Msixbundle"
Install "$base/bundles/Microsoft.WindowsStore_22409.1401.5.0_neutral___8wekyb3d8bbwe.Msixbundle"

# ========== Auto Update ==========
try {
    winget upgrade --all --silent --accept-source-agreements --accept-package-agreements
} catch {}

Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue

# ========== Result ==========
if ($Fail) {
    Write-Host "❌ Installation finished with errors" -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ Microsoft Store installed and updated successfully" -ForegroundColor Green
    exit 0
}
