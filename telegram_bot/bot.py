#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Официальный Telegram-бот экосистемы «Методист Pro»
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

# Optional Proxy support (e.g. 'http://proxy.example.com:8080' or via HTTPS_PROXY env)
PROXY = os.getenv('HTTPS_PROXY') or os.getenv('HTTP_PROXY')


def make_request(method: str, data: dict = None, files: dict = None) -> dict:
    """Выполняет вызов к Telegram Bot API."""
    url = f'{API_BASE}/{method}'
    handlers = []
    if PROXY:
        handlers.append(urllib.request.ProxyHandler({'http': PROXY, 'https': PROXY}))
    opener = urllib.request.build_opener(*handlers)

    if files:
        # Multipart form data for sending documents
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
        with opener.open(req, timeout=30) as resp:
            return json.loads(resp.read().decode('utf-8'))
    except Exception as e:
        print(f'[ERROR] API {method} failed: {e}', file=sys.stderr)
        return {'ok': False, 'error': str(e)}


def send_message(chat_id: int, text: str, reply_markup: dict = None, parse_mode: str = 'HTML'):
    payload = {
        'chat_id': chat_id,
        'text': text,
        'parse_mode': parse_mode,
    }
    if reply_markup:
        payload['reply_markup'] = reply_markup
    return make_request('sendMessage', payload)


def send_document(chat_id: int, file_path: str, caption: str = ''):
    path = Path(file_path)
    if not path.exists():
        return send_message(chat_id, f'⚠️ Файл не найден: {file_path}')

    with open(path, 'rb') as f:
        file_bytes = f.read()

    files = {'document': (path.name, file_bytes)}
    data = {'chat_id': str(chat_id), 'caption': caption, 'parse_mode': 'HTML'}
    return make_request('sendDocument', data=data, files=files)


def answer_callback_query(callback_query_id: str, text: str = None, show_alert: bool = False):
    payload = {'callback_query_id': callback_query_id}
    if text:
        payload['text'] = text
        payload['show_alert'] = show_alert
    return make_request('answerCallbackQuery', payload)


def get_start_keyboard():
    return {
        'inline_keyboard': [
            [
                {
                    'text': '🚀 Открыть Методист Mini App',
                    'web_app': {'url': WEB_APP_URL}
                }
            ],
            [
                {
                    'text': '🎨 Студия авторских миров',
                    'web_app': {'url': f'{WEB_APP_URL}?startapp=studio'}
                },
                {
                    'text': '🧩 Конструктор методик',
                    'web_app': {'url': f'{WEB_APP_URL}?startapp=architect'}
                }
            ],
            [
                {
                    'text': '📄 Скачать премиум PDF листа',
                    'callback_data': 'download_sample_pdf'
                },
                {
                    'text': '👑 Тариф «Директор» (1 199 ₽)',
                    'callback_data': 'show_director_info'
                }
            ],
            [
                {
                    'text': '🌌 5 Игровых миров YandexART',
                    'callback_data': 'show_worlds_info'
                },
                {
                    'text': '📚 Каталог 173 тем',
                    'callback_data': 'show_topics_info'
                }
            ]
        ]
    }


def handle_start(chat_id: int, user: dict):
    first_name = user.get('first_name', 'Учитель')
    text = (
        f'👋 <b>Здравствуйте, {first_name}!</b>\n\n'
        f'Добро пожаловать в официальную экосистему <b>«Методист Pro»</b> — умный ассистент учителя '
        f'и завуча на базе нейросетей YandexGPT 5 Pro и YandexART.\n\n'
        f'✨ <b>Что доступно прямо в Telegram:</b>\n'
        f'• 🚀 <b>Telegram Mini App</b> — бесшовное интерактивное приложение в 1 клик\n'
        f'• 🎨 <b>Студия авторских миров</b> — эмблемы школ, кастомные маскоты и палитры\n'
        f'• 🧩 <b>Конструктор авторских методик</b> (Пчёлко, Костин, ТРИЗ, сказкотерапия)\n'
        f'• 📄 <b>Готовые листы заданий</b> в PDF с цветными шапками и критериями\n'
        f'• 📦 <b>Генератор четверти</b> (до 30 уроков в ZIP-архиве)\n\n'
        f'Нажмите кнопку ниже, чтобы запустить <b>Методист Mini App</b>:'
    )
    send_message(chat_id, text, reply_markup=get_start_keyboard())


def handle_help(chat_id: int):
    text = (
        f'📖 <b>Справочник команд экосистемы «Методист»:</b>\n\n'
        f'/start — Главное меню и запуск Telegram Mini App\n'
        f'/app — Открыть приложение на полный экран\n'
        f'/worlds — 5 тематических миров (Космос, Лес, Детектив, Мастерская, Тайга)\n'
        f'/director — Преимущества тарифа «Директор» (1 199 ₽/мес)\n'
        f'/pdf — Скачать образцы готовых рабочих листов\n'
        f'/quick &lt;тема&gt; — Быстрый набросок урока в чате\n\n'
        f'💡 <i>Совет: Для комфортной работы используйте кнопку «Открыть Методист» '
        f'в левом нижнем углу меню Telegram!</i>'
    )
    send_message(chat_id, text, reply_markup=get_start_keyboard())


def handle_worlds(chat_id: int):
    text = (
        f'🌌 <b>5 Тематических игровых миров листа заданий:</b>\n\n'
        f'1. 🚀 <b>Космическая одиссея</b> — Маскот: Кот-космонавт Юра. Шапка YandexART со звёздной туманностью.\n'
        f'2. 🌲 <b>Сказочный лес</b> — Маскот: Мудрая сова Афина. Тёплые лесные тона и ягодная палитра.\n'
        f'3. 🔍 <b>Детективное агентство</b> — Маскот: Пёс-детектив Холмс. Дедуктивные шифровки и улики.\n'
        f'4. ⚙️ <b>Инженерная мастерская</b> — Маскот: Енот-изобретатель Винтик. Чертёжная графика и шестерёнки.\n'
        f'5. 🏔️ <b>Тайга первооткрывателей</b> — Маскот: Медвежонок-географ Умка. Хвойные мотивы и компас.\n\n'
        f'👑 В тарифе <b>«Директор»</b> доступно создание маскота своей школы и генерация авторских шапок через YandexART!'
    )
    send_message(chat_id, text, reply_markup=get_start_keyboard())


def handle_director(chat_id: int):
    text = (
        f'👑 <b>Тариф «Директор» — Флагман образовательной платформы:</b>\n\n'
        f'💰 <b>Цена:</b> 1 199 ₽ / месяц (при оплате за год — 14 388 ₽) или 1 499 ₽/мес.\n\n'
        f'🌟 <b>Эксклюзивные возможности:</b>\n'
        f'1. 🎨 <b>Студия авторских миров</b> — загрузка герба школы, генерация маскота в YandexART.\n'
        f'2. 🧩 <b>Конструктор авторских методик</b> — настройка тона (ТРИЗ, сократический диалог, сказки), стоп-слова.\n'
        f'3. ⚡ <b>REST API и Webhooks</b> — подключение школьного Telegram-бота, МЭШ, ЭЖД, Сферум, Moodle.\n'
        f'4. 📦 <b>Пакетный генератор четверти</b> — 15–30 уроков в 1 клик с единым ZIP-архивом (PDF + DOCX).\n'
        f'5. 🔬 <b>Лаборатория отладки</b> — лог двухпроходного цензора (Методист + Цензор), строгий аудит Пчёлко.\n'
        f'6. 👥 <b>Лицензия кафедры</b> — до 5 рабочих мест учителей с общим банком конспектов.\n'
        f'7. ⭐ Все функции Metodist Pro (безлимит, ОВЗ, Word, презентации).'
    )
    send_message(chat_id, text, reply_markup=get_start_keyboard())


def handle_pdf_send(chat_id: int):
    send_message(chat_id, '⏳ <i>Отправляю премиум-образцы листов заданий...</i>')
    
    # Try finding generated PDFs in docs/
    base_dir = Path(__file__).resolve().parent.parent
    math_pdf = base_dir / 'docs' / 'math_worksheet_premium.pdf'
    russian_pdf = base_dir / 'docs' / 'russian_worksheet_premium.pdf'
    space_pdf = base_dir / 'docs' / 'thematic_worlds_pdf' / 'world_space.pdf'

    sent = False
    if math_pdf.exists():
        send_document(
            chat_id,
            str(math_pdf),
            '📐 <b>Математика 2 класс</b> (Методика Пчёлко, мир «Космос», арт-шапка YandexART)'
        )
        sent = True

    if russian_pdf.exists():
        send_document(
            chat_id,
            str(russian_pdf),
            '📖 <b>Русский язык 1 класс</b> (Методика Костина, звёздный рейтинг, ключи)'
        )
        sent = True

    if not sent and space_pdf.exists():
        send_document(chat_id, str(space_pdf), '🚀 <b>Мир Космоса</b> (Лист заданий)')
        sent = True

    if not sent:
        send_message(chat_id, 'ℹ️ Образцы PDF доступны для скачивания в Mini App по кнопке ниже:')


def handle_quick_lesson(chat_id: int, topic: str):
    if not topic.strip():
        send_message(chat_id, 'ℹ️ Укажите тему после команды, например: <code>/quick Сложение двузначных чисел</code>')
        return

    text = (
        f'📝 <b>Экспресс-план занятия:</b>\n'
        f'📌 <b>Тема:</b> {topic.strip()}\n'
        f'🎯 <b>Цель:</b> Формирование понятийной базы через предметное действие по методике Пчёлко.\n\n'
        f'<b>Этапы урока:</b>\n'
        f'1. <b>Организационный момент</b>: ТРИЗ-загадка по сюжету мира.\n'
        f'2. <b>Актуализация знаний</b>: устный счёт на 3 минуты.\n'
        f'3. <b>Открытие нового знания</b>: наглядный вывод правила (цена × количество).\n'
        f'4. <b>Практикум</b>: 6 дифференцированных заданий на листе.\n'
        f'5. <b>Рефлексия и критериальная оценка</b>: звёзды успешности ⭐⭐⭐.\n\n'
        f'<i>Полный конспект и печатный PDF лист доступны в Mini App:</i>'
    )
    send_message(chat_id, text, reply_markup=get_start_keyboard())


def process_update(update: dict):
    # Message update
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
        elif text.startswith('/app'):
            send_message(chat_id, '🚀 Нажмите кнопку ниже для запуска:', reply_markup=get_start_keyboard())
        elif text.startswith('/quick'):
            topic = text.replace('/quick', '').strip()
            handle_quick_lesson(chat_id, topic)
        else:
            # Default response
            send_message(
                chat_id,
                f'Здравствуйте, {user.get("first_name", "Педагог")}! Выберите раздел или откройте Mini App:',
                reply_markup=get_start_keyboard()
            )

    # Callback Query update
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
        elif data == 'show_topics_info':
            send_message(
                chat_id,
                '📚 <b>Каталог 173 тем</b> охватывает 1–4 классы и дошкольную подготовку по 7 методикам '
                '(Пчёлко, Костин, Редозубов, Мазина, Чаплыгин, Боголюбов, Косинова). Все темы проверены с YandexGPT и YandexART.',
                reply_markup=get_start_keyboard()
            )


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
