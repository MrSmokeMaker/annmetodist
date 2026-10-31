#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Мульти-раннер Telegram-ботов платформы «Методист Pro»:
1. Основной бот экосистемы: @annmetodist_bot (8839424428:AAG2i4SC7qq6LgeQ1_mXPE4koaCGauYCJlE)
2. Отдельный бот-помощник: MetodistAI (9106775452:AAHZmVZleB2jeM78FSBRuITBeHFZRFvIPI8)
"""

import sys
import subprocess
import threading
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent


def run_script(script_name: str, bot_title: str):
    print(f'[START] Запуск процесса: {bot_title} ({script_name})...')
    try:
        proc = subprocess.Popen(
            [sys.executable, str(BASE_DIR / script_name)],
            stdout=sys.stdout,
            stderr=sys.stderr
        )
        proc.wait()
    except Exception as e:
        print(f'[ERROR] Ошибка запуска {bot_title}: {e}')


def main():
    print('========================================================')
    print('  Запуск экосистемы Telegram-ботов «Методист Pro»')
    print('========================================================')
    print('1. Основной бот: @annmetodist_bot')
    print('2. Отдельный AI-помощник: MetodistAI (9106775452:AAHZmVZle...)')
    print('--------------------------------------------------------')

    t1 = threading.Thread(target=run_script, args=('bot.py', 'Основной бот (@annmetodist_bot)'), daemon=True)
    t2 = threading.Thread(target=run_script, args=('metodist_ai_bot.py', 'Отдельный AI-помощник MetodistAI'), daemon=True)

    t1.start()
    t2.start()

    try:
        t1.join()
        t2.join()
    except KeyboardInterrupt:
        print('\n[INFO] Остановка всех ботов.')


if __name__ == '__main__':
    main()
