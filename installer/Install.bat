@echo off
rem CS.Coder - Unit Styler: installs the package in every Delphi (11, 12, 13) found.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0StylerSetup.ps1" -Action install
echo.
pause
