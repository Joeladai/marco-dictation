@echo off
title Marco Dictation - Installer
mode con: cols=100 lines=34
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0engine\install.ps1"
