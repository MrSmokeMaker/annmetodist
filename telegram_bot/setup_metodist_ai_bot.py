#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Скрипт автоматической настройки меню, описания и команд для отдельного бота-помощника MetodistAI
Токен: 9106775452:AAHZmVZleB2jeM78FSBRuITBeHFZRFvIPI8
"""

import os
import sys
import json
import urllib.request

METODIST_AI_TOKEN = os.getenv('METODIST_AI_BOT_TOKEN', os.getenv('BOT_TOKEN', '9106775452:AAHZmVZleB2jeM78FSBRuITBeHFZRFvIPI8'))
WEB_APP_URL = os.getenv('WEB_APP_URL', 'https://mrsmokemaker.github.io/annmetodist/')
API_BASE = f'https://api.telegram.org/bot{METODIST_AI_TOKEN}'

PROXY = os.getenv('HTTPS_PROXY') or os.getenv('HTTP_PROXY') or os.getenv('AG_LS_PROXY')


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


def configure_metodist_ai_bot():
    print(f'Настройка бота MetodistAI...')

    # 1. Menu Button (Кнопка меню с запуском Mini App)
    print('\n1. Установка кнопки меню (Telegram Mini App)...')
    call_api('setChatMenuButton', {
        'menu_button': {
            'type': 'web_app',
            'text': '🚀 Открыть Методист',
            'web_app': {'url': WEB_APP_URL}
        }
    })

    # 2. Commands Menu
    print('\n2. Регистрация команд бота...')
    commands = [
        {'command': 'start', 'description': 'Главное интерактивное меню и запуск'},
        {'command': 'owl', 'description': 'Спросить Совёнка-Методиста AI'},
        {'command': 'parents', 'description': 'Пост в чат родителей (WhatsApp/TG)'},
        {'command': 'hw', 'description': '3 уровня дифференцированного ДЗ'},
        {'command': 'game', 'description': 'Сюжетная игра / квест по уроку'},
        {'command': 'test', 'description': 'Экспресс-тест с ключами проверки'},
        {'command': 'worksheet', 'description': 'Мини-рабочий лист в чате'},
        {'command': 'modes', 'description': '5 педагогических ролей Совёнка'},
        {'command': 'break', 'description': 'Физкультминутка по СанПиН'},
        {'command': 'trap', 'description': 'Задание «Ловушка Незнайки»'},
        {'command': 'intro', 'description': 'Вводное слово учителя (2 мин)'},
        {'command': 'remind', 'description': 'Утренний дайджест и расписание'},
        {'command': 'app', 'description': 'Открыть приложение на весь экран'},
        {'command': 'worlds', 'description': '5 игровых миров и арт-шапки'},
        {'command': 'director', 'description': 'Тариф Директор и авторская студия'},
        {'command': 'pdf', 'description': 'Скачать образцы листов заданий PDF'},
        {'command': 'help', 'description': 'Справка и руководство учителя'},
    ]
    call_api('setMyCommands', {'commands': commands})

    # 3. Description
    print('\n3. Описание бота...')
    call_api('setMyDescription', {
        'description': (
            '🦉 MetodistAI — ваш персональный AI-помощник учителя начальных классов и завуча.\n\n'
            '✨ Ключевые возможности:\n'
            '• 💬 Посты для родительских чатов WhatsApp/Telegram в 1 клик\n'
            '• 📚 Дифференцированное ДЗ на 3 уровня (ФГОС, практика, ТРИЗ)\n'
            '• 🎮 Сюжетные квесты и обучающие игры с маскотами 5 миров\n'
            '• 📝 Экспресс-тесты с ключами проверки и критериями\n'
            '• 🤸 Разминки и физкультминутки по нормам СанПиН\n'
            '• 🪤 Задания-ловушки Незнайки для развития критического мышления\n'
            '• 🚀 Telegram Mini App с конструктором PDF листов и 173 готовыми темами уроков\n'
            '• 👑 Премиум тариф «Директор» для кафедр и школ'
        )
    })

    # 4. Short description
    print('\n4. Краткое описание...')
    call_api('setMyShortDescription', {
        'short_description': '🦉 MetodistAI: посты в чат родителей, 3 уровня ДЗ, квесты по 5 мирам, тесты и конспекты по ФГОС.'
    })

    print('\n✨ Настройка MetodistAI бота завершена!')


if __name__ == '__main__':
    configure_metodist_ai_bot()
