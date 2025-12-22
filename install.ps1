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
# Ask Reinstall
# ===============================
$reinstall = Read-Host "Reinstall Microsoft Store even if installed? (Y/N)"
$reinstall = $reinstall.Substring(0,1).ToUpper()
$force = ($reinstall -eq "Y")

try {

    # ===============================
    # Windows version check
    # ===============================
    $build = [int](Get-ComputerInfo).OsBuildNumber
    if ($build -lt 19044) { throw "Windows 10 21H2+ required" }

    # ===============================
    # Arch detect
    # ===============================
    $arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }

    # ===============================
    # Temp + Log
    # ===============================
    $temp = "$env:TEMP\msstore"
    $log  = "$temp\install.log"
    New-Item $temp -ItemType Directory -Force | Out-Null
    Start-Transcript -Path $log | Out-Null

    # ===============================
    # Helper
    # ===============================
    function Install-Appx {
        param ($Name, $Url)

        if (-not $force -and (Get-AppxPackage -Name $Name -ErrorAction SilentlyContinue)) {
            Write-Host "$Name already installed, skipping"
            return
        }

        $file = "$temp\$(Split-Path $Url -Leaf)"
        Invoke-WebRequest $Url -OutFile $file
        Add-AppxPackage -Path $file -ForceApplicationShutdown
    }

    # ===============================
    # Dependencies
    # ===============================
    Install-Appx "Microsoft.NET.Native.Framework.2.2" `
        "https://aka.ms/Microsoft.NET.Native.Framework.2.2.appx"

    Install-Appx "Microsoft.NET.Native.Runtime.2.2" `
        "https://aka.ms/Microsoft.NET.Native.Runtime.2.2.appx"

    Install-Appx "Microsoft.UI.Xaml.2.8" `
        "https://aka.ms/Microsoft.UI.Xaml.2.8.$arch.appx"

    Install-Appx "Microsoft.VCLibs.140.00.UWPDesktop" `
        "https://aka.ms/Microsoft.VCLibs.$arch.14.00.Desktop.appx"

    # ===============================
    # DesktopAppInstaller + winget
    # ===============================
    if ($force -or -not (Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue)) {
        $wingetFile = "$temp\DesktopAppInstaller.msixbundle"
        Invoke-WebRequest "https://aka.ms/getwinget" -OutFile $wingetFile
        Add-AppxPackage -Path $wingetFile -ForceApplicationShutdown
    }

    # ===============================
    # Store packages
    # ===============================
    $api = "https://store.rg-adguard.net/api/GetFiles"
    $storePackages = @(
        "Microsoft.WindowsStore",
        "Microsoft.StorePurchaseApp",
        "Microsoft.XboxIdentityProvider"
    )

    foreach ($pkg in $storePackages) {

        if (-not $force -and (Get-AppxPackage -Name $pkg -ErrorAction SilentlyContinue)) {
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

        if (-not $link) { throw "Failed to fetch $pkg" }

        $file = "$temp\$(Split-Path $link -Leaf)"
        Invoke-WebRequest $link -OutFile $file
        Add-AppxPackage -Path $file -ForceApplicationShutdown
    }

    Write-Host "Microsoft Store installation completed."

}
finally {
    Stop-Transcript | Out-Null

    # ===============================
    # Cleanup
    # ===============================
    if (Test-Path $temp) {
        Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue
    }

    # ===============================
    # Self-delete session
    # ===============================
    exit
}
