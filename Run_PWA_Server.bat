@echo off
title Echoes of the Ossuary - Local PWA Web Server
echo ============================================================================
echo   ECHOES OF THE OSSUARY - PROGRESSIVE WEB APP (PWA) LOCAL SERVER
echo   Created by daryl.created@gmail.com
echo ============================================================================
echo.
echo Starting local HTTP server for build/web on http://localhost:8080 ...
echo Opening browser automatically...
start "" "http://localhost:8080/index.html"
python -m http.server 8080 --directory "%~dp0build\web"
pause
