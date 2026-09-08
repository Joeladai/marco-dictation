@echo off
title Marco Dictation - Uninstaller
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0engine\uninstall.ps1"
