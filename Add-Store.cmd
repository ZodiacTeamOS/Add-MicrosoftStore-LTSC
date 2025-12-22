@echo off
for %%f in (packages\*.appx packages\*.appxbundle packages\*.msixbundle) do (
  powershell -command "Add-AppxPackage -Path '%%f' -ForceApplicationShutdown"
)
pause
