@echo off
title Echoes of the Ossuary
cd /d "%~dp0"
echo ========================================================
echo  Launching Echoes of the Ossuary in Godot 4.x...
echo ========================================================
"C:\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe"
if %errorlevel% neq 0 (
    echo.
    echo Godot closed with code %errorlevel%.
    pause
)
