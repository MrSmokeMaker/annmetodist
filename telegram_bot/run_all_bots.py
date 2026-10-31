#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Мульти-раннер Telegram-ботов платформы «Методист Pro»:
1. Основной бот экосистемы: @annmetodist_bot (8839424428:AAG2i4SC7qq6LgeQ1_mXPE4koaCGauYCJlE)
2. Отдельный AI-помощник: MetodistAI (9106775452:AAHZmVZleB2jeM78FSBRuITBeHFZRFvIPI8)
"""

import os
import sys
import time
import subprocess
import threading
from pathlib import Path

# Safe encoding on Windows console
try:
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    if hasattr(sys.stderr, 'reconfigure'):
        sys.stderr.reconfigure(encoding='utf-8', errors='replace')
except Exception:
    pass

BASE_DIR = Path(__file__).resolve().parent


def run_bot_daemon(script_name: str, bot_title: str):
    """Запуск бота с бесконечным авто-перезапуском при сетевых сбоях."""
    while True:
        print(f'[START] Запуск процесса: {bot_title} ({script_name})...')
        try:
            proc = subprocess.Popen(
                [sys.executable, '-u', str(BASE_DIR / script_name)],
                stdout=sys.stdout,
                stderr=sys.stderr,
                cwd=str(BASE_DIR)
            )
            proc.wait()
            print(f'[WARN] Процесс {bot_title} завершился (код {proc.returncode}). Перезапуск через 3 сек...')
        except Exception as e:
            print(f'[ERROR] Ошибка запуска {bot_title}: {e}. Повтор через 5 сек...')
            time.sleep(2)
        time.sleep(3)


def main():
    print('========================================================')
    print('  Запуск экосистемы Telegram-ботов «Методист Pro»')
    print('========================================================')
    print('1. Основной бот: @annmetodist_bot')
    print('2. Отдельный AI-помощник: MetodistAI (9106775452:AAHZmVZle...)')
    print('--------------------------------------------------------')

    t1 = threading.Thread(target=run_bot_daemon, args=('bot.py', 'Основной бот (@annmetodist_bot)'), daemon=True)
    t2 = threading.Thread(target=run_bot_daemon, args=('metodist_ai_bot.py', 'Отдельный AI-помощник MetodistAI'), daemon=True)

    t1.start()
    t2.start()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print('\n[INFO] Остановка всех ботов.')


if __name__ == '__main__':
    main()
