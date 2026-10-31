@echo off
chcp 65001 > nul
title Metodist Pro Bots Ecosystem (Core & AI Assistant)
echo [Metodist Pro] Запуск обоих ботов экосистемы...
cd /d "%~dp0"
python -u run_all_bots.py
pause
