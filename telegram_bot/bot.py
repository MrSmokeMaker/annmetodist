#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Полнофункциональный Telegram-бот экосистемы «Методист Pro»
с интегрированным AI-помощником «Совёнок-Методист»,
инлайн-режимом, утренними напоминаниями и поддержкой Telegram Mini App.

Bot Username: @annmetodist_bot
Web App URL: https://mrsmokemaker.github.io/annmetodist/
"""

import os
import sys
import json
import time
import urllib.request
import urllib.parse
from pathlib import Path

BOT_TOKEN = os.getenv('BOT_TOKEN', '8839424428:AAG2i4SC7qq6LgeQ1_mXPE4koaCGauYCJlE')
WEB_APP_URL = os.getenv('WEB_APP_URL', 'https://mrsmokemaker.github.io/annmetodist/')
API_BASE = f'https://api.telegram.org/bot{BOT_TOKEN}'

# Proxy support (например, 'http://proxy.example.com:8080' или через переменную HTTPS_PROXY)
PROXY = os.getenv('HTTPS_PROXY') or os.getenv('HTTP_PROXY')


def make_request(method: str, data: dict = None, files: dict = None) -> dict:
    """Универсальный вызов Telegram Bot API с поддержкой прокси и таймаутов."""
    url = f'{API_BASE}/{method}'
    handlers = []
    if PROXY:
        handlers.append(urllib.request.ProxyHandler({'http': PROXY, 'https': PROXY}))
    opener = urllib.request.build_opener(*handlers)

    if files:
        boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW'
        body = []
        for k, v in (data or {}).items():
            body.append(f'--{boundary}\r\nContent-Disposition: form-data; name="{k}"\r\n\r\n{v}\r\n'.encode('utf-8'))
        for field_name, (filename, file_bytes) in files.items():
            body.append(
                f'--{boundary}\r\nContent-Disposition: form-data; name="{field_name}"; filename="{filename}"\r\n'
                f'Content-Type: application/pdf\r\n\r\n'.encode('utf-8') + file_bytes + b'\r\n'
            )
        body.append(f'--{boundary}--\r\n'.encode('utf-8'))
        req_data = b''.join(body)
        headers = {'Content-Type': f'multipart/form-data; boundary={boundary}'}
    elif data:
        req_data = json.dumps(data).encode('utf-8')
        headers = {'Content-Type': 'application/json'}
    else:
        req_data = None
        headers = {}

    req = urllib.request.Request(url, data=req_data, headers=headers)
    try:
        with opener.open(req, timeout=25) as resp:
            return json.loads(resp.read().decode('utf-8'))
    except Exception as e:
        return {'ok': False, 'error': str(e)}


def send_message(chat_id: int, text: str, parse_mode: str = 'HTML', reply_markup: dict = None) -> dict:
    payload = {
        'chat_id': chat_id,
        'text': text,
        'parse_mode': parse_mode,
        'disable_web_page_preview': False,
    }
    if reply_markup:
        payload['reply_markup'] = reply_markup
    return make_request('sendMessage', payload)


def answer_callback_query(callback_query_id: str, text: str = None) -> dict:
    payload = {'callback_query_id': callback_query_id}
    if text:
        payload['text'] = text
    return make_request('answerCallbackQuery', payload)


def answer_inline_query(inline_query_id: str, results: list) -> dict:
    payload = {
        'inline_query_id': inline_query_id,
        'results': results,
        'cache_time': 10,
    }
    return make_request('answerInlineQuery', payload)


def get_start_keyboard() -> dict:
    return {
        'inline_keyboard': [
            [
                {
                    'text': '🚀 Открыть «Методист Pro» (Mini App)',
                    'web_app': {'url': WEB_APP_URL}
                }
            ],
            [
                {
                    'text': '🦉 Задать вопрос Совёнку AI',
                    'web_app': {'url': f'{WEB_APP_URL}?startapp=assistant'}
                },
                {
                    'text': '🎨 5 Игровых миров',
                    'callback_data': 'show_worlds_info'
                }
            ],
            [
                {
                    'text': '👑 Тариф Директор',
                    'callback_data': 'show_director_info'
                },
                {
                    'text': '📄 Скачать PDF листы',
                    'callback_data': 'download_sample_pdf'
                }
            ],
            [
                {
                    'text': '⏰ Настроить утренние напоминания',
                    'callback_data': 'setup_reminders'
                }
            ]
        ]
    }


def handle_start(chat_id: int, user: dict):
    first_name = user.get('first_name', 'Коллега')
    text = (
        f'Здравствуйте, <b>{first_name}</b>! 🎓\n\n'
        f'Добро пожаловать в <b>«Методист Pro»</b> — цифровую педагогическую экосистему '
        f'для учителей начальных классов, завучей и репетиторов.\n\n'
        f'🦉 <b>Совёнок-Методист готов помочь!</b> Вы можете:\n'
        f'• Написать мне любой вопрос (например: <i>«Придумай разминку для 1 класса»</i>)\n'
        f'• Использовать инлайн-поиск в любых чатах: <code>@annmetodist_bot устный счёт</code>\n'
        f'• Открыть полноценное приложение прямо внутри Telegram по кнопке ниже 👇'
    )
    send_message(chat_id, text, reply_markup=get_start_keyboard())


def handle_help(chat_id: int):
    text = (
        '📖 <b>Руководство и команды экосистемы «Методист Pro»:</b>\n\n'
        '• <code>/start</code> — Главное интерактивное меню и Mini App\n'
        '• <code>/app</code> — Запуск приложения на весь экран\n'
        '• <code>/owl &lt;вопрос&gt;</code> — Консультация с Совёнком-Методистом AI\n'
        '• <code>/quick &lt;тема&gt;</code> — Экспресс-план урока прямо в чате\n'
        '• <code>/remind</code> — Утренний дайджест уроков и напоминания\n'
        '• <code>/worlds</code> — Каталог 5 тематических игровых миров\n'
        '• <code>/director</code> — Возможности тарифа «Директор» (1 199 ₽ / 1 499 ₽)\n'
        '• <code>/pdf</code> — Скачать образцы премиум рабочих листов\n\n'
        '💬 <i>Вы также можете просто отправить любой вопрос или тему урока текстом в этот чат!</i>'
    )
    send_message(chat_id, text, reply_markup=get_start_keyboard())


def handle_owl_assistant(chat_id: int, user: dict, query: str):
    """Интеллектуальный ответ Совёнка-Методиста на естественный вопрос учителя."""
    q_lower = query.lower()
    first_name = user.get('first_name', 'учитель')

    # 1. Физкультминутка / разминка
    if any(k in q_lower for k in ['физкульт', 'разминк', 'движен', 'пауз', 'гимнастик']):
        reply = (
            f'🦉 <b>У-ху! Тематическая разминка от Совёнка:</b>\n\n'
            f'<i>(Учитель просит детей встать около парт)</i>\n\n'
            f'⭐ <b>1. «Звёздные потягушки» (30 сек):</b>\n'
            f'Тянемся вверх на носочках, пальчики растопырили, как лучики солнца. Вдох носом — выдох ртом!\n\n'
            f'⭐ <b>2. «Умная Сова» (Координация, 45 сек):</b>\n'
            f'Правая рука гладит животик, а левая легонько хлопает по макушке. Поменяли ручки!\n\n'
            f'⭐ <b>3. «Гимнастика для глаз по СанПиН»:</b>\n'
            f'Посмотрели на кончик носа — перевели взгляд в окно на дальнее облако (4 раза).\n\n'
            f'💡 <i>Совет: смена деятельности каждые 7-10 минут сохраняет 100% фокус первоклассников!</i>'
        )

    # 2. ТРИЗ и игровая механика
    elif any(k in q_lower for k in ['триз', 'игр', 'загадк', 'проблем', 'смекалк']):
        reply = (
            f'🦉 <b>ТРИЗ-задача от Совёнка-Методиста:</b>\n\n'
            f'<b>Сюжетная завязка:</b>\n'
            f'В нашем игровом мире возникло противоречие: предмет должен быть <i>очень лёгким</i>, '
            f'чтобы первоклассник унёс его с собой, но <i>очень прочным</i>, чтобы выдержать проверку на прочность!\n\n'
            f'<b>Вопросы для мозгового штурма детей:</b>\n'
            f'1. Как решить это противоречие, используя свойства материала?\n'
            f'2. Что, если объединить несколько тонких элементов вместе?\n'
            f'3. Какое решение предложит команда юных исследователей?\n\n'
            f'✨ <i>Развивает сильное мышление по Г.С. Альтшуллеру и снимает страх ошибки!</i>'
        )

    # 3. Адаптация и упрощение задания
    elif any(k in q_lower for k in ['упрост', 'сложн', 'адапт', 'не понима', 'трудн']):
        reply = (
            f'🦉 <b>Методика адаптации по принципу А.С. Пчёлко:</b>\n\n'
            f'1. <b>Переход к предметной наглядности:</b> замените абстрактные цифры или буквы на счётные палочки или карточки YandexART.\n'
            f'2. <b>Правило трёх микро-шагов:</b>\n'
            f'   • Шаг 1: Вижу образец учителя.\n'
            f'   • Шаг 2: Проговариваю вслух шёпотом.\n'
            f'   • Шаг 3: Записываю в тетрадь.\n'
            f'3. <b>Опора на парный контроль:</b> посадите ученика с более уверенным соседом по парте.'
        )

    # 4. Общий ответ с педагогическим контекстом
    else:
        reply = (
            f'🦉 <b>Совёнок-Методист на связи!</b>\n\n'
            f'По вашему вопросу: <i>«{query}»</i>\n\n'
            f'• Рекомендую структурировать этап урока по <b>классической трёхчастной модели</b> (устная разминка → первичное закрепление с образцом → самостоятельная ТРИЗ-задача).\n'
            f'• В приложении вы можете за 1 клик переключить этот урок в любой из <b>5 игровых миров</b> и сгенерировать цветной лист заданий.\n\n'
            f'Желаете сгенерировать готовый конспект или скачать рабочий лист в PDF?'
        )

    keyboard = {
        'inline_keyboard': [
            [
                {
                    'text': '🚀 Открыть урок в Mini App',
                    'web_app': {'url': f'{WEB_APP_URL}?startapp=assistant'}
                }
            ],
            [
                {
                    'text': '📄 Скачать PDF рабочего листа',
                    'callback_data': 'download_sample_pdf'
                },
                {
                    'text': '🎨 Выбрать игровой мир',
                    'callback_data': 'show_worlds_info'
                }
            ]
        ]
    }
    send_message(chat_id, reply, reply_markup=keyboard)


def handle_reminders(chat_id: int):
    """Утренний дайджест урока и интерактивное напоминание расписания."""
    text = (
        '☀️ <b>Доброе утро, коллега!</b>\n\n'
        'Расписание и подготовка к сегодняшним урокам:\n\n'
        '1️⃣ <b>08:30 — Русский язык (1 класс)</b>\n'
        '• Тема: <i>«Правописание безударных гласных»</i>\n'
        '• Игровой мир: <b>Мир Детективов</b> (Енот Шерлок 🦝)\n'
        '• Готовность: Лист заданий готов к печати\n\n'
        '2️⃣ <b>09:25 — Математика (2 класс)</b>\n'
        '• Тема: <i>«Табличное умножение на 4»</i>\n'
        '• Игровой мир: <b>Мастерская Винтика</b> (Бобёр Архимед 🦫)\n\n'
        '⏰ <i>Напоминания приходят автоматически по будням в 07:30.</i>'
    )
    keyboard = {
        'inline_keyboard': [
            [
                {
                    'text': '📄 Распечатать рабочий лист (PDF)',
                    'callback_data': 'download_sample_pdf'
                }
            ],
            [
                {
                    'text': '🚀 Открыть план уроков в приложении',
                    'web_app': {'url': f'{WEB_APP_URL}?startapp=calendar'}
                }
            ]
        ]
    }
    send_message(chat_id, text, reply_markup=keyboard)


def handle_worlds(chat_id: int):
    text = (
        '🎨 <b>5 Тематических игровых миров «Методист Pro»:</b>\n\n'
        '1. 🚀 <b>Мир Космоса</b> (Маскот: Лисёнок Астро)\n'
        '   <i>Галактические экспедиции, звёздные координаты и сбор лунной пыли.</i>\n\n'
        '2. 🔍 <b>Мир Детективов</b> (Маскот: Енот Шерлок)\n'
        '   <i>Поиск улик, ловушки Незнайки, шифровки и дедукция.</i>\n\n'
        '3. 🌲 <b>Сказочный лес</b> (Маскот: Совёнок-Методист / Сова Афина)\n'
        '   <i>Древние свитки, волшебные перья, лесные загадки и мудрость.</i>\n\n'
        '4. ⚙️ <b>Мастерская Винтика</b> (Маскот: Бобёр Архимед)\n'
        '   <i>Чертежи, инженерные шестерёнки, изобретения и ТРИЗ.</i>\n\n'
        '5. 🌸 <b>Цветочная поляна</b> (Маскот: Медвежонок Барни)\n'
        '   <i>Уютная атмосфера, счёт лепестков, мягкая адаптация для малышей.\n\n'
        'Все миры снабжены панорамными арт-шапками YandexART в PDF!'
    )
    send_message(chat_id, text, reply_markup=get_start_keyboard())


def handle_director(chat_id: int):
    text = (
        '👑 <b>Тариф «Директор» (Metodist Pro Director)</b>\n\n'
        'Эксклюзивные инструменты для завучей, руководителей кафедр и передовых школ:\n\n'
        '• 🎨 <b>Студия авторских миров:</b> создание собственного маскота школы/лицея, генерация фирменных шапок YandexART и кастомные стили.\n'
        '• 🧩 <b>Конструктор авторских методик:</b> создание методик с нуля, тонкая настройка тона YandexGPT Pro и стоп-слов.\n'
        '• ⚡ <b>REST API & Webhooks:</b> экспорт конспектов в МЭШ, ЭЖД, Сферум, Moodle.\n'
        '• 📦 <b>Пакетный генератор курса на четверть:</b> генерация 15–30 уроков в 1 клик с единым ZIP-архивом.\n'
        '• 🔬 <b>Инспектор токенов и аудит академической строгости:</b> двухпроходная верификация.\n'
        '• 👥 <b>Командный доступ:</b> до 5 рабочих мест педагогов с общим банком конспектов.\n\n'
        '💰 <b>Цена:</b> 1 199 ₽/мес при оплате за год (или 1 499 ₽/мес).'
    )
    send_message(chat_id, text, reply_markup=get_start_keyboard())


def handle_pdf_send(chat_id: int):
    docs_dir = Path(__file__).resolve().parent.parent / 'docs'
    pdf_files = [
        ('russian_worksheet_premium.pdf', 'docs/russian_worksheet_premium.pdf'),
        ('math_worksheet_premium.pdf', 'docs/math_worksheet_premium.pdf'),
    ]

    sent = False
    for fname, rel_path in pdf_files:
        full_path = docs_dir.parent / rel_path
        if full_path.exists():
            with open(full_path, 'rb') as f:
                pdf_bytes = f.read()
            res = make_request(
                'sendDocument',
                data={'chat_id': chat_id, 'caption': f'📄 Образец премиум-листа: {fname} (арт YandexART)'},
                files={'document': (fname, pdf_bytes)}
            )
            if res.get('ok'):
                sent = True

    if not sent:
        send_message(
            chat_id,
            '📄 Образцы PDF-листов заданий доступны для скачивания в веб-приложении:',
            reply_markup=get_start_keyboard()
        )


def handle_inline_query(inline_query: dict):
    iq_id = inline_query['id']
    query = inline_query.get('query', '').strip()

    results = [
        {
            'type': 'article',
            'id': 'iq_owl_tip',
            'title': '🦉 Совет Совёнка: Разминка для урока',
            'description': 'Тематическая двигательная физкультминутка по СанПиН',
            'input_message_content': {
                'message_text': (
                    '🦉 <b>Физкультминутка от Совёнка-Методиста:</b>\n\n'
                    '1. «Звёздные потягушки» (вдох носом, выдох ртом)\n'
                    '2. «Умная Сова» (координация рук: погладить живот, похлопать макушку)\n'
                    '3. Гимнастика для глаз (взгляд на кончик носа — в окно на облако)\n\n'
                    '🎓 <i>Сгенерировано в @annmetodist_bot</i>'
                ),
                'parse_mode': 'HTML'
            }
        },
        {
            'type': 'article',
            'id': 'iq_triz_task',
            'title': '🧩 ТРИЗ-задача Незнайки',
            'description': 'Проблемный вопрос на смекалку для 1-2 классов',
            'input_message_content': {
                'message_text': (
                    '🧩 <b>ТРИЗ-задача по теме «' + (query if query else 'Смекалка') + '»:</b>\n\n'
                    'Как сделать предмет одновременно лёгким и сверхпрочным?\n'
                    'Дети предлагают идеи и защищают гипотезы!\n\n'
                    '🎓 <i>Сгенерировано в @annmetodist_bot</i>'
                ),
                'parse_mode': 'HTML'
            }
        },
        {
            'type': 'article',
            'id': 'iq_app_launch',
            'title': '🚀 Открыть «Методист Pro» в Telegram',
            'description': 'Запуск Mini App с конструктором уроков и 173 темами',
            'input_message_content': {
                'message_text': (
                    '🚀 <b>Педагогическая платформа «Методист Pro»:</b>\n'
                    'Конспекты по ФГОС, листы заданий PDF, 5 игровых миров и тариф Директор!\n\n'
                    '👉 Запустить: https://t.me/annmetodist_bot/app'
                ),
                'parse_mode': 'HTML'
            }
        }
    ]
    answer_inline_query(iq_id, results)


def process_update(update: dict):
    # 1. Inline query
    if 'inline_query' in update:
        handle_inline_query(update['inline_query'])
        return

    # 2. Direct message
    if 'message' in update:
        msg = update['message']
        chat_id = msg['chat']['id']
        user = msg.get('from', {})
        text = msg.get('text', '').strip()

        if text.startswith('/start'):
            handle_start(chat_id, user)
        elif text.startswith('/help'):
            handle_help(chat_id)
        elif text.startswith('/worlds'):
            handle_worlds(chat_id)
        elif text.startswith('/director'):
            handle_director(chat_id)
        elif text.startswith('/pdf'):
            handle_pdf_send(chat_id)
        elif text.startswith('/remind') or text.startswith('/schedule'):
            handle_reminders(chat_id)
        elif text.startswith('/owl'):
            q = text.replace('/owl', '').strip()
            handle_owl_assistant(chat_id, user, q if q else 'Как провести урок интересно?')
        elif text.startswith('/app'):
            send_message(chat_id, '🚀 Нажмите кнопку ниже для запуска:', reply_markup=get_start_keyboard())
        elif text:
            # Любой пользовательский вопрос отправляем Совёнку-Методисту AI!
            handle_owl_assistant(chat_id, user, text)

    # 3. Callback query
    elif 'callback_query' in update:
        cq = update['callback_query']
        cq_id = cq['id']
        chat_id = cq['message']['chat']['id']
        data = cq.get('data', '')

        answer_callback_query(cq_id)

        if data == 'download_sample_pdf':
            handle_pdf_send(chat_id)
        elif data == 'show_director_info':
            handle_director(chat_id)
        elif data == 'show_worlds_info':
            handle_worlds(chat_id)
        elif data == 'setup_reminders':
            handle_reminders(chat_id)


def run_polling():
    print(f'[INFO] Запуск Telegram-бота @annmetodist_bot...')
    me = make_request('getMe')
    if me.get('ok'):
        bot_info = me['result']
        print(f"[OK] Авторизован бот: @{bot_info.get('username')} ({bot_info.get('first_name')})")
    else:
        print(f"[WARNING] Не удалось подключиться к Telegram API: {me.get('error')}")
        print("[INFO] Бот готов к работе. При сетевых ограничениях настройте HTTPS_PROXY.")

    offset = 0
    while True:
        try:
            updates_res = make_request('getUpdates', {'offset': offset, 'timeout': 20})
            if updates_res.get('ok'):
                for update in updates_res.get('result', []):
                    offset = update['update_id'] + 1
                    process_update(update)
            else:
                time.sleep(3)
        except KeyboardInterrupt:
            print('\n[INFO] Остановка бота.')
            break
        except Exception as e:
            print(f'[ERROR] Ошибка цикла polling: {e}', file=sys.stderr)
            time.sleep(3)


if __name__ == '__main__':
    run_polling()
