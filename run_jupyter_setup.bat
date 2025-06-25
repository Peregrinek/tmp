@echo off
set "ps1script=%~dp0setup_jupyter_server_win.ps1"

powershell -NoProfile -ExecutionPolicy Bypass -File "%ps1script%"
pause
