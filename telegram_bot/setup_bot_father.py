#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Скрипт автоматической настройки меню и команд бота @annmetodist_bot через Telegram Bot API
"""

import os
import sys
import json
import urllib.request

BOT_TOKEN = os.getenv('BOT_TOKEN', '8839424428:AAG2i4SC7qq6LgeQ1_mXPE4koaCGauYCJlE')
WEB_APP_URL = os.getenv('WEB_APP_URL', 'https://mrsmokemaker.github.io/annmetodist/')
API_BASE = f'https://api.telegram.org/bot{BOT_TOKEN}'

PROXY = os.getenv('HTTPS_PROXY') or os.getenv('HTTP_PROXY')


def call_api(method: str, data: dict):
    url = f'{API_BASE}/{method}'
    handlers = []
    if PROXY:
        handlers.append(urllib.request.ProxyHandler({'http': PROXY, 'https': PROXY}))
    opener = urllib.request.build_opener(*handlers)

    req_data = json.dumps(data).encode('utf-8')
    req = urllib.request.Request(url, data=req_data, headers={'Content-Type': 'application/json'})
    try:
        with opener.open(req, timeout=15) as resp:
            res = json.loads(resp.read().decode('utf-8'))
            print(f'[{method}] Результат: {res}')
            return res
    except Exception as e:
        print(f'[{method}] Ошибка: {e}')
        return {'ok': False, 'error': str(e)}


def configure_bot():
    print(f'Настройка бота @annmetodist_bot...')

    # 1. Menu Button (Кнопка в левом нижнем углу чата)
    print('\n1. Установка кнопки меню (Telegram Mini App)...')
    call_api('setChatMenuButton', {
        'menu_button': {
            'type': 'web_app',
            'text': 'Открыть Методист',
            'web_app': {'url': WEB_APP_URL}
        }
    })

    # 2. Commands Menu
    print('\n2. Регистрация команд бота...')
    commands = [
        {'command': 'start', 'description': 'Главное меню и запуск Mini App'},
        {'command': 'app', 'description': 'Открыть Методист на полный экран'},
        {'command': 'worlds', 'description': '5 тематических миров и маскоты'},
        {'command': 'director', 'description': 'Тариф Директор и авторская студия'},
        {'command': 'pdf', 'description': 'Скачать образцы листов заданий PDF'},
        {'command': 'help', 'description': 'Справка и руководство учителя'},
    ]
    call_api('setMyCommands', {'commands': commands})

    # 3. Description
    print('\n3. Описание бота...')
    call_api('setMyDescription', {
        'description': (
            'Экосистема «Методист Pro» для учителей начальных классов, завучей и репетиторов.\n\n'
            '🚀 Генерация конспектов уроков по ФГОС на базе YandexGPT 5 Pro\n'
            '🎨 5 тематических игровых миров и арт-шапки YandexART\n'
            '🧩 Конструктор авторских методик (Пчёлко, Костин, Редозубов, ТРИЗ)\n'
            '📦 Пакетный генератор курса на четверть (15–30 уроков) в ZIP\n'
            '👑 Тариф «Директор» для кафедр и школ'
        )
    })

    # 4. Short description
    print('\n4. Краткое описание...')
    call_api('setMyShortDescription', {
        'short_description': 'Умный ассистент учителя: конспекты по ФГОС, листы заданий, 5 миров и тариф Директор.'
    })

    print('\n✨ Настройка завершена!')


if __name__ == '__main__':
    configure_bot()
