@echo off
title Maliy App Server
echo ============================================
echo Starting Maliy App on http://localhost:8085
echo ============================================
cd /d "%~dp0flutter_application_1"
if not exist "build\web" (
    echo Building Web version... Please wait.
    call flutter build web
)
start http://localhost:8085
python -m http.server 8085 --directory "build\web"
pause
