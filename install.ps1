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

try {

    # ===============================
    # Temp directory
    # ===============================
    $temp = "$env:TEMP\msstore"
    New-Item $temp -ItemType Directory -Force | Out-Null

    # ===============================
    # Helper (safe install)
    # ===============================
    function Install-Appx {
        param ($Name, $Url)

        if (Get-AppxPackage -Name $Name -ErrorAction SilentlyContinue) {
            Write-Host "$Name already installed, skipping"
            return
        }

        $file = "$temp\$(Split-Path $Url -Leaf)"

        try {
            Invoke-WebRequest $Url -OutFile $file -UseBasicParsing
        } catch {
            Write-Warning "Failed to download $Name"
            return
        }

        # تأكيد إن الملف Appx فعلي
        if (-not (Test-Path $file) -or (Get-Item $file).Length -lt 1MB) {
            Write-Warning "$Name download invalid, skipping"
            Remove-Item $file -Force -ErrorAction SilentlyContinue
            return
        }

        try {
            Add-AppxPackage -Path $file -ForceApplicationShutdown
            Write-Host "$Name installed successfully"
        } catch {
            Write-Warning "$Name install failed, skipping"
        }
    }

    # ===============================
    # Dependencies (FIXED LINKS)
    # ===============================
    Write-Host "Installing dependencies..."

    Install-Appx "Microsoft.VCLibs.140.00.UWPDesktop" `
        "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"

    Install-Appx "Microsoft.UI.Xaml.2.8" `
        "https://aka.ms/Microsoft.UI.Xaml.2.8.x64.appx"

    Install-Appx "Microsoft.NET.Native.Framework.2.2" `
        "https://download.microsoft.com/download/9/3/4/934A6E42-7A5A-4CEB-AE0B-13E6C4B1AFAE/Microsoft.NET.Native.Framework.2.2.appx"

    Install-Appx "Microsoft.NET.Native.Runtime.2.2" `
        "https://download.microsoft.com/download/9/3/4/934A6E42-7A5A-4CEB-AE0B-13E6C4B1AFAE/Microsoft.NET.Native.Runtime.2.2.appx"

    # ===============================
    # Microsoft Store components
    # ===============================
    Write-Host "Installing Microsoft Store components..."

    $storePackages = @(
        "Microsoft.XboxIdentityProvider",
        "Microsoft.StorePurchaseApp",
        "Microsoft.DesktopAppInstaller",
        "Microsoft.WindowsStore"
    )

    $api = "https://store.rg-adguard.net/api/GetFiles"

    foreach ($pkg in $storePackages) {

        if (Get-AppxPackage -Name $pkg -ErrorAction SilentlyContinue) {
            Write-Host "$pkg already installed, skipping"
            continue
        }

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
            Write-Warning "Failed to fetch $pkg"
            continue
        }

        $file = "$temp\$(Split-Path $link -Leaf)"

        Invoke-WebRequest $link -OutFile $file -UseBasicParsing
        Add-AppxPackage -Path $file -ForceApplicationShutdown
    }

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Microsoft Store installed successfully "
    Write-Host "========================================"

}
finally {
    # ===============================
    # Cleanup
    # ===============================
    if (Test-Path $temp) {
        Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue
    }
}
