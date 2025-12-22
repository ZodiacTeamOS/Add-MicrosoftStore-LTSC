$ErrorActionPreference = "Stop"

# ===============================
# Auto Elevate
# ===============================
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Start-Process powershell `
        -Verb RunAs `
        -ArgumentList "irm https://raw.githubusercontent.com/USER/REPO/main/lang.ps1 | iex"
    exit
}

try {

    Write-Host "=== Checking Language & Input Configuration ===" -ForegroundColor Cyan

    $Current = Get-WinUserLanguageList
    $NeedFix = $false

    # ===============================
    # Checks
    # ===============================
    if ($Current.Count -ne 2) {
        Write-Host "[-] More or less than 2 languages detected" -ForegroundColor Yellow
        $NeedFix = $true
    }

    if ($Current[0].LanguageTag -ne "en-US") {
        Write-Host "[-] English is not primary language" -ForegroundColor Yellow
        $NeedFix = $true
    }

    foreach ($lang in $Current) {
        if ($lang.InputMethodTips.Count -gt 0) {
            Write-Host "[-] Extra Input Methods detected for $($lang.LanguageTag)" -ForegroundColor Yellow
            $NeedFix = $true
        }
    }

    if (-not $NeedFix) {
        Write-Host "[OK] System already in Golden Configuration. No action needed." -ForegroundColor Green
        return
    }

    # ===============================
    # Ask Apply
    # ===============================
    $apply = Read-Host "Apply Golden Language Configuration? (Y/N)"
    if ($apply.Substring(0,1).ToUpper() -ne "Y") {
        Write-Host "Cancelled by user."
        return
    }

    Write-Host "[*] Applying Golden Configuration..." -ForegroundColor Cyan

    # ===============================
    # APPLY FIX
    # ===============================
    $LangList = New-WinUserLanguageList en-US
    $LangList.Add("ar-EG")

    $LangList[0].InputMethodTips.Clear()
    $LangList[1].InputMethodTips.Clear()

    Set-WinUserLanguageList $LangList -Force

    # Clean CTF
    Remove-Item "HKCU:\Software\Microsoft\CTF" -Recurse -Force -ErrorAction SilentlyContinue

    # Keyboard toggle (Alt+Shift)
    New-Item -Path "HKCU:\Keyboard Layout" -Name Toggle -Force | Out-Null
    Set-ItemProperty "HKCU:\Keyboard Layout\Toggle" -Name Hotkey -Value "1"
    Set-ItemProperty "HKCU:\Keyboard Layout\Toggle" -Name LanguageHotkey -Value "1"
    Set-ItemProperty "HKCU:\Keyboard Layout\Toggle" -Name LayoutHotkey -Value "1"

    # Restart Text Services
    Stop-Process -Name ctfmon -Force -ErrorAction SilentlyContinue
    Start-Process ctfmon.exe

    Write-Host "[DONE] Golden Configuration applied successfully." -ForegroundColor Green

}
finally {
    exit
}
