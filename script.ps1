$ErrorActionPreference = "Stop"

net session >$null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Run PowerShell as Administrator"
    exit 1
}
# ===== Admin check (iex-safe) =====
$ErrorActionPreference = "Stop"

net session >$null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Run PowerShell as Administrator"
    exit 1
}

# ===== Repo config =====
$Repo = "ZodiacTeamOS/Add-MicrosoftStore-LTSC"
$Tag  = "the_bun"
$Base = "https://github.com/$Repo/releases/download/$Tag"

$Temp = "$env:TEMP\MSStoreLTSC"
New-Item -ItemType Directory -Force -Path $Temp | Out-Null
Set-Location $Temp

# ===== Download helper =====
function Get-File {
    param($Name)
    if (!(Test-Path $Name)) {
        Write-Host "Downloading $Name"
        Invoke-RestMethod "$Base/$Name" -OutFile $Name
    }
}

# ===== Install helper =====
function Install {
    param($Path)
    Write-Host "Installing $Path"
    Add-AppxPackage -Path $Path -DisableDevelopmentMode -ForceApplicationShutdown
}

# ================= VC++ =================
Get-File "Microsoft.VCLibs.140.00.UWPDesktop_14.0.33728.0_x64__8wekyb3d8bbwe.Appx"
Install  "Microsoft.VCLibs.140.00.UWPDesktop_14.0.33728.0_x64__8wekyb3d8bbwe.Appx"

# ================= .NET Native =================
Get-File "Microsoft.NET.Native.Framework.2.2_2.2.29512.0_x64__8wekyb3d8bbwe.Appx"
Get-File "Microsoft.NET.Native.Runtime.2.2_2.2.28604.0_x64__8wekyb3d8bbwe.Appx"
Install "Microsoft.NET.Native.Framework.2.2_2.2.29512.0_x64__8wekyb3d8bbwe.Appx"
Install "Microsoft.NET.Native.Runtime.2.2_2.2.28604.0_x64__8wekyb3d8bbwe.Appx"

# ================= UI.Xaml =================
Get-File "Microsoft.UI.Xaml.2.7_7.2409.9001.0_x64__8wekyb3d8bbwe.Appx"
Get-File "Microsoft.UI.Xaml.2.8_8.2310.30001.0_x64__8wekyb3d8bbwe.Appx"
Install "Microsoft.UI.Xaml.2.7_7.2409.9001.0_x64__8wekyb3d8bbwe.Appx"
Install "Microsoft.UI.Xaml.2.8_8.2310.30001.0_x64__8wekyb3d8bbwe.Appx"

# ================= StorePurchaseApp =================
Get-File "Microsoft.StorePurchaseApp_22408.1401.0.0_neutral__8wekyb3d8bbwe.AppxBundle"
Get-File "Microsoft.StorePurchaseApp_8wekyb3d8bbwe.xml"

Add-AppxPackage `
 -Path "Microsoft.StorePurchaseApp_22408.1401.0.0_neutral__8wekyb3d8bbwe.AppxBundle" `
 -Register "Microsoft.StorePurchaseApp_8wekyb3d8bbwe.xml" `
 -DisableDevelopmentMode `
 -ForceApplicationShutdown

# ================= Xbox Identity =================
Get-File "Microsoft.XboxIdentityProvider_12.115.1001.0_neutral__8wekyb3d8bbwe.AppxBundle"
Get-File "Microsoft.XboxIdentityProvider_8wekyb3d8bbwe.xml"

Add-AppxPackage `
 -Path "Microsoft.XboxIdentityProvider_12.115.1001.0_neutral__8wekyb3d8bbwe.AppxBundle" `
 -Register "Microsoft.XboxIdentityProvider_8wekyb3d8bbwe.xml" `
 -DisableDevelopmentMode `
 -ForceApplicationShutdown

# ================= Windows Store =================
Get-File "Microsoft.WindowsStore_22409.1401.5.0_neutral__8wekyb3d8bbwe.Msixbundle"
Get-File "Microsoft.WindowsStore_8wekyb3d8bbwe.xml"

Add-AppxPackage `
 -Path "Microsoft.WindowsStore_22409.1401.5.0_neutral__8wekyb3d8bbwe.Msixbundle" `
 -Register "Microsoft.WindowsStore_8wekyb3d8bbwe.xml" `
 -DisableDevelopmentMode `
 -ForceApplicationShutdown

Write-Host "✔ Microsoft Store Installed Successfully"
