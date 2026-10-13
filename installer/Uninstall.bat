@echo off
rem CS.Coder - Unit Styler: removes the package from every Delphi.
rem Uninstall.bat          keeps your settings
rem Uninstall.bat /data    deletes the settings too
if /i "%~1"=="/data" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0StylerSetup.ps1" -Action uninstall -RemoveData
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0StylerSetup.ps1" -Action uninstall
)
echo.
pause
