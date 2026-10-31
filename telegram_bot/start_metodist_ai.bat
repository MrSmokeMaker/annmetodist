@echo off
chcp 65001 > nul
title MetodistAI Bot Daemon (Pro & Director)
echo [MetodistAI] Запуск персонального AI-ассистента...
cd /d "%~dp0"
python -u metodist_ai_bot.py
pause
