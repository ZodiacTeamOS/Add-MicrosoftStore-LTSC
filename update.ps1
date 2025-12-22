$targets = @(
  "Microsoft.WindowsStore",
  "Microsoft.StorePurchaseApp",
  "Microsoft.DesktopAppInstaller",
  "Microsoft.XboxIdentityProvider"
)

$api = "https://store.rg-adguard.net/api/GetFiles"

foreach ($pkg in $targets) {
  Invoke-WebRequest `
    -Uri $api `
    -Method POST `
    -Body "type=PackageFamilyName&url=$pkg&ring=Retail&lang=en-US" `
    -UseBasicParsing |
    Select-String -Pattern "https://.*\.(appx|appxbundle|msixbundle)" |
    ForEach-Object {
      $link = $_.Matches[0].Value
      $name = Split-Path $link -Leaf
      Invoke-WebRequest $link -OutFile "packages\$name"
    }
}

