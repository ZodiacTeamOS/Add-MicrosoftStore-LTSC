$ErrorActionPreference = "Stop"

$repo = "https://raw.githubusercontent.com/USERNAME/REPO/main"

$files = @(
  "packages/Microsoft.VCLibs.140.00.UWPDesktop.appx",
  "packages/Microsoft.UI.Xaml.2.8.appx",
  "packages/Microsoft.NET.Native.Framework.2.2.appx",
  "packages/Microsoft.NET.Native.Runtime.2.2.appx",
  "packages/Microsoft.WindowsStore.msixbundle",
  "packages/Microsoft.StorePurchaseApp.appxbundle",
  "packages/Microsoft.DesktopAppInstaller.msixbundle",
  "packages/Microsoft.XboxIdentityProvider.appxbundle"
)

$temp = "$env:TEMP\store"
New-Item $temp -ItemType Directory -Force | Out-Null

foreach ($f in $files) {
  $url = "$repo/$f"
  $out = "$temp\$(Split-Path $f -Leaf)"
  Invoke-WebRequest $url -OutFile $out
  Add-AppxPackage -Path $out -ForceApplicationShutdown
}
