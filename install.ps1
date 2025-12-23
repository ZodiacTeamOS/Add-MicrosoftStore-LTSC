$u = "https://raw.githubusercontent.com/ZodiacTeamOS/Add-MicrosoftStore-LTSC/the_bun/script.ps1"
$f = "$env:TEMP\store.ps1"

irm $u -OutFile $f
powershell -ExecutionPolicy Bypass -File $f
