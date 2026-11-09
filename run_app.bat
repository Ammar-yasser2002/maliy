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

echo Starting server...
start "" /b python -m http.server 8085 --directory "build\web"
timeout /t 2 /nobreak >nul
start "" "http://localhost:8085"
echo.
echo Server is running on: http://localhost:8085
echo Keep this window open while using the app.
echo.
pause
