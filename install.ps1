$u = "https://raw.githubusercontent.com/ZodiacTeamOS/Add-MicrosoftStore-LTSC/main/script.ps1"
$f = "$env:TEMP\store.ps1"

irm $u -OutFile $f
powershell -ExecutionPolicy Bypass -File $f
