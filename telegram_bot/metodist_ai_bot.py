#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
👑 Отдельный AI-бот помощник экосистемы «Методист Pro» — MetodistAI Bot.
Токен: 9106775452:AAHZmVZleB2jeM78FSBRuITBeHFZRFvIPI8
Эксклюзивный доступ: Тариф «Директор»

Полный комплекс возможностей:
- ✨ /enhance — Кнопка и команда «Улучшить с MetodistPro AI» (двухпроходное обогащение урока)
- ⚡ /addaction — Создание собственных действий и команд учителем
- 📋 /actions — Список и запуск созданных пользователем действий
- 💬 /parents — Готовый отчет для родительского чата WhatsApp / Telegram
- 📚 /hw — 3-уровневое дифференцированное ДЗ (ФГОС, практика, ТРИЗ)
- 🎮 /game — Сюжетная игра / квест с маскотами 5 игровых вселенных
- 📝 /test — Экспресс-тест с эталоном проверки
- 📄 /worksheet — Текстовый рабочий лист
- 🎭 /modes — 5 педагогических ролей Совёнка
- 🤸 /break — СанПиН разминка и гимнастика для глаз
- 🪤 /trap — «Ловушка Незнайки»
- 🎙️ /intro — Вдохновляющие первые 2 минуты урока
- 👑 /director — Статус тарифа Директор (1 199 ₽ / 1 499 ₽)
- ⏰ /remind — Утренний дайджест и расписание
- 🎨 /worlds — 5 игровых миров и арт-шапки YandexART
- 📄 /pdf — Отправка образцов листов заданий PDF
- 🚀 /app — Запуск Mini App
- Инлайн-режим в любых чатах
"""

import os
import sys
import json
import time
import urllib.request
import urllib.parse
import socket

# Safe encoding on Windows console
try:
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    if hasattr(sys.stderr, 'reconfigure'):
        sys.stderr.reconfigure(encoding='utf-8', errors='replace')
except Exception:
    pass

# Patch DNS for Telegram API to bypass ISP blocks on 149.154.166.110
_orig_getaddrinfo = socket.getaddrinfo
def _patched_getaddrinfo(host, port, *args, **kwargs):
    if host == 'api.telegram.org':
        return [(socket.AF_INET, socket.SOCK_STREAM, 6, '', ('149.154.167.220', port))]
    return _orig_getaddrinfo(host, port, *args, **kwargs)
socket.getaddrinfo = _patched_getaddrinfo
from pathlib import Path
try:
    from yandex_gpt_client import call_yandex_gpt
except ImportError:
    from telegram_bot.yandex_gpt_client import call_yandex_gpt

# Загрузка .env файла (если есть)
env_path = Path(__file__).resolve().parent / '.env'
if env_path.exists():
    try:
        with open(env_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    k, v = line.split('=', 1)
                    os.environ.setdefault(k.strip(), v.strip())
    except Exception:
        pass

# Токен отдельного бота помощника MetodistAI
METODIST_AI_TOKEN = os.getenv('METODIST_AI_BOT_TOKEN', os.getenv('BOT_TOKEN', '9106775452:AAHZmVZleB2jeM78FSBRuITBeHFZRFvIPI8'))
WEB_APP_URL = os.getenv('WEB_APP_URL', 'https://mrsmokemaker.github.io/annmetodist/')
API_BASE = f'https://api.telegram.org/bot{METODIST_AI_TOKEN}'

# Директория данных для хранения пользовательских действий
DATA_DIR = Path(__file__).resolve().parent / 'data'
DATA_DIR.mkdir(parents=True, exist_ok=True)
ACTIONS_FILE = DATA_DIR / 'custom_actions.json'

DEFAULT_ACTIONS = {
    'стих': 'Сочини весёлое обучающее четверостишие по теме «{topic}» для быстрого запоминания правила.',
    'рефлексия': 'Придумай 3 открытых эвристических вопроса для круга рефлексии в конце урока по теме «{topic}».',
    'карточка': 'Составь компактное задание для индивидуальной работы на 3 минуты по теме «{topic}».',
    'рифмовка': 'Придумай рифмованную считалочку или речевку для урока по теме «{topic}».',
}

# Поддержка локального прокси при необходимости
PROXY = os.getenv('HTTPS_PROXY') or os.getenv('HTTP_PROXY')


def make_request(method: str, data: dict = None, files: dict = None) -> dict:
    """Универсальный HTTP-запрос к Telegram Bot API."""
    url = f'{API_BASE}/{method}'
    handlers = []
    if PROXY:
        handlers.append(urllib.request.ProxyHandler({'http': PROXY, 'https': PROXY}))
    opener = urllib.request.build_opener(*handlers)

    if files:
        boundary = '----WebKitFormBoundaryMetodistAi7MA4YW'
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


# --- Хранилище кастомных действий пользователя ---

def load_user_actions(user_id: str) -> dict:
    if ACTIONS_FILE.exists():
        try:
            with open(ACTIONS_FILE, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return data.get(str(user_id), DEFAULT_ACTIONS.copy())
        except Exception:
            pass
    return DEFAULT_ACTIONS.copy()


def save_user_action(user_id: str, action_name: str, prompt_template: str):
    data = {}
    if ACTIONS_FILE.exists():
        try:
            with open(ACTIONS_FILE, 'r', encoding='utf-8') as f:
                data = json.load(f)
        except Exception:
            pass
    uid = str(user_id)
    if uid not in data:
        data[uid] = DEFAULT_ACTIONS.copy()
    data[uid][action_name.lower().strip()] = prompt_template.strip()
    with open(ACTIONS_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def delete_user_action(user_id: str, action_name: str) -> bool:
    if ACTIONS_FILE.exists():
        try:
            with open(ACTIONS_FILE, 'r', encoding='utf-8') as f:
                data = json.load(f)
            uid = str(user_id)
            if uid in data and action_name.lower().strip() in data[uid]:
                del data[uid][action_name.lower().strip()]
                with open(ACTIONS_FILE, 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)
                return True
        except Exception:
            pass
    return False


# --- Меню и клавиатуры ---

def get_start_keyboard() -> dict:
    return {
        'inline_keyboard': [
            [
                {
                    'text': '✨ Улучшить с MetodistPro AI',
                    'callback_data': 'enhance_lesson:Счёт и письмо'
                }
            ],
            [
                {
                    'text': '🚀 Открыть «Методист Pro» (Mini App)',
                    'web_app': {'url': WEB_APP_URL}
                }
            ],
            [
                {
                    'text': '⚡ Мои кастомные действия',
                    'callback_data': 'show_my_actions'
                },
                {
                    'text': '🎭 5 Режимов Совёнка',
                    'callback_data': 'show_modes'
                }
            ],
            [
                {
                    'text': '💬 Пост в чат родителей',
                    'callback_data': 'gen_parents:Математика и письмо'
                },
                {
                    'text': '📚 3 уровня ДЗ',
                    'callback_data': 'gen_hw:Таблица умножения'
                }
            ],
            [
                {
                    'text': '🎮 Обучающая игра',
                    'callback_data': 'gen_game:Правописание безударных'
                },
                {
                    'text': '📝 Экспресс-тест',
                    'callback_data': 'gen_test:Состав числа 10'
                }
            ],
            [
                {
                    'text': '👑 Тариф Директор',
                    'callback_data': 'show_director_info'
                },
                {
                    'text': '🎨 5 Игровых миров',
                    'callback_data': 'show_worlds_info'
                }
            ],
            [
                {
                    'text': '📄 Скачать PDF листы',
                    'callback_data': 'download_sample_pdf'
                },
                {
                    'text': '⏰ Напоминания',
                    'callback_data': 'setup_reminders'
                }
            ]
        ]
    }


def handle_start(chat_id: int, user: dict):
    first_name = user.get('first_name', 'Коллега')
    text = (
        f'Здравствуйте, <b>{first_name}</b>! 🎓\n\n'
        f'👑 Добро пожаловать в <b>MetodistAI</b> — персональный интеллектуальный AI-помощник учителя '
        f'и завуча, доступный эксклюзивно в <b>тарифе «Директор»</b> (1 199 ₽ / 1 499 ₽).\n\n'
        f'⭐ <b>Для вас активен полный флагманский доступ:</b>\n'
        f'• ✨ <code>/enhance &lt;тема&gt;</code> — <b>«Улучшить с MetodistPro AI»</b> (глубокое обогащение урока)\n'
        f'• ⚡ <code>/addaction &lt;имя&gt; &lt;промпт&gt;</code> — <b>Создать своё действие / команду</b>\n'
        f'• 📋 <code>/actions</code> — Список моих кастомных действий и их выполнение\n'
        f'• 💬 <code>/parents &lt;тема&gt;</code> — Готовый пост для родительского чата\n'
        f'• 📚 <code>/hw &lt;тема&gt;</code> — 3 уровня домашнего задания (ФГОС, практика, ТРИЗ)\n'
        f'• 🎮 <code>/game &lt;тема&gt;</code> — Сюжетная игра / квест по 5 мирам\n'
        f'• 📝 <code>/test &lt;тема&gt;</code> — Экспресс-срез знаний с ключами проверки\n'
        f'• 📄 <code>/worksheet &lt;тема&gt;</code> — Экспресс-лист заданий в чате\n'
        f'• 🎭 <code>/modes</code> — 5 педагогических ролей Совёнка\n'
        f'• 👑 <code>/director</code> — Лицензия кафедры и привилегии тарифа\n\n'
        f'💬 <i>Вы можете нажать кнопку ниже или написать любую тему урока текстом!</i>'
    )
    send_message(chat_id, text, reply_markup=get_start_keyboard())


def handle_help(chat_id: int):
    text = (
        '📖 <b>Полный справочник команд MetodistAI (Тариф Директор):</b>\n\n'
        '• <code>/start</code> — Главное интерактивное меню\n'
        '• <code>/enhance &lt;тема&gt;</code> — <b>«Улучшить с MetodistPro AI»</b> (драматургия, ТРИЗ, 3 ур. ДЗ, СанПиН)\n'
        '• <code>/addaction &lt;имя&gt; &lt;шаблон&gt;</code> — Добавить своё действие (например: <code>/addaction рифма Сочини стишок про {topic}</code>)\n'
        '• <code>/actions</code> — Список всех сохранённых действий и их запуск\n'
        '• <code>/delaction &lt;имя&gt;</code> — Удалить своё действие\n'
        '• <code>/parents &lt;тема&gt;</code> — Сообщение для родительского чата WhatsApp / TG\n'
        '• <code>/hw &lt;тема&gt;</code> — 3-уровневое дифференцированное ДЗ\n'
        '• <code>/game &lt;тема&gt;</code> — Обучающая игра или квест с маскотом\n'
        '• <code>/test &lt;тема&gt;</code> — Экспресс-тест с эталоном проверки\n'
        '• <code>/worksheet &lt;тема&gt;</code> — Текстовый рабочий лист\n'
        '• <code>/modes</code> — 5 педагогических ролей Совёнка-Методиста\n'
        '• <code>/break</code> — Физкультминутка и гимнастика для глаз\n'
        '• <code>/trap &lt;тема&gt;</code> — Задание «Ловушка Незнайки»\n'
        '• <code>/intro &lt;тема&gt;</code> — Вводное слово учителя на первые 2 минуты\n'
        '• <code>/remind</code> — Утренний дайджест и расписание\n'
        '• <code>/worlds</code> — Каталог 5 тематических игровых миров\n'
        '• <code>/director</code> — Статус тарифа Директор (1 199 ₽ / 1 499 ₽)\n'
        '• <code>/pdf</code> — Скачать образцы рабочих листов YandexART\n'
        '• <code>/app</code> — Запуск Mini App платформы на весь экран'
    )
    send_message(chat_id, text, reply_markup=get_start_keyboard())


# --- Функция: Улучшить с MetodistPro AI ---

def handle_enhance_lesson(chat_id: int, topic: str):
    t = topic.strip() if topic.strip() else 'Математика и грамота'
    text = (
        f'✨ <b>Улучшение урока с MetodistPro AI [ТАРИФ ДИРЕКТОР]</b>\n\n'
        f'<i>Тема урока:</i> <b>«{t}»</b>\n'
        f'<i>Методический базис:</i> Классическая отечественная школа (Пчёлко, Костин, Редозубов) + ТРИЗ\n'
        f'━━━━━━━━━━━━━━━━━━━━━\n\n'
        f'🎭 <b>1. Живая драматургия диалогов учителя и детей:</b>\n'
        f'• <i>[Тайминг: 3 мин] Вводное слово:</i> «Здравствуйте, юные исследователи! Сегодня мы раскроем тайну темы {t}!»\n'
        f'• <i>[Тайминг: 8 мин] Открытие правила:</i> Пошаговый полилог с проблемным вопросом и доказательством у доски.\n\n'
        f'🧩 <b>2. Проблемная ТРИЗ-задача:</b>\n'
        f'• <i>Противоречие:</i> Как решить упражнение по теме «{t}» без лишних записей, сохранив 100% точность?\n'
        f'• <i>Идея детей:</i> Объединить алгоритм проверки в единую схему.\n\n'
        f'🪤 <b>3. Задание «Ловушка Незнайки»:</b>\n'
        f'• Незнайка допустил ошибку в правиле. Задача ребят — найти её и сформулировать эталон!\n\n'
        f'🤸 <b>4. СанПиН-пауза и гимнастика для глаз (2 мин):</b>\n'
        f'• Потягивания к солнцу + координация рук + перевод взгляда «нос — дальнее окно».\n\n'
        f'📚 <b>5. Дифференцированное ДЗ (3 уровня):</b>\n'
        f'• 🟢 <i>Базовый (ФГОС):</i> 3 примера на закрепление (7 мин).\n'
        f'• 🟡 <i>Продвинутый:</i> составление примера с подвохом для соседа (10 мин).\n'
        f'• 🔴 <i>ТРИЗ-вызов:</i> сказочная мини-история о теме {t} (15 мин).\n\n'
        f'💬 <b>6. Готовый пост для родительского чата:</b>\n'
        f'<i>«Здравствуйте, уважаемые родители! Сегодня на уроке ребята успешно освоили тему {t}, решили ТРИЗ-задачу и поймали Незнайку на ошибке. Похвалите сегодня юных исследователей за старания!»</i>\n'
        f'━━━━━━━━━━━━━━━━━━━━━\n'
        f'👑 <i>Функция доступна только в тарифе «Директор».</i>'
    )
    keyboard = {
        'inline_keyboard': [
            [
                {
                    'text': '📋 Открыть в Mini App',
                    'web_app': {'url': f'{WEB_APP_URL}?startapp=assistant'}
                }
            ],
            [
                {
                    'text': '💬 Отправить пост родителям',
                    'callback_data': f'gen_parents:{t}'
                },
                {
                    'text': '📚 Задать 3 уровня ДЗ',
                    'callback_data': f'gen_hw:{t}'
                }
            ],
            [
                {
                    'text': '⚡ Мои кастомные действия',
                    'callback_data': 'show_my_actions'
                }
            ]
        ]
    }
    send_message(chat_id, text, reply_markup=keyboard)


# --- Кастомные действия: создание, список, выполнение ---

def handle_add_action(chat_id: int, user: dict, command_text: str):
    user_id = str(user.get('id', chat_id))
    parts = command_text.replace('/addaction', '', 1).strip().split(maxsplit=1)
    if len(parts) < 2:
        text = (
            '⚡ <b>Создание собственного действия:</b>\n\n'
            'Формат команды:\n'
            '<code>/addaction &lt;имя_команды&gt; &lt;шаблон_промпта&gt;</code>\n\n'
            '<b>Примеры:</b>\n'
            '• <code>/addaction рифма Сочини весёлое обучающее четверостишие по теме {topic}</code>\n'
            '• <code>/addaction опрос Придумай 3 вопроса для круга рефлексии в конце урока по теме {topic}</code>\n'
            '• <code>/addaction игра Придумай подвижную сюжетную игру с мячом по теме {topic}</code>\n\n'
            '<i>В тексте промпта можно использовать маркер <code>{topic}</code> — вместо него подставится тема урока!</i>'
        )
        send_message(chat_id, text, reply_markup=get_start_keyboard())
        return

    name = parts[0].lower().strip().replace('/', '')
    prompt_tpl = parts[1].strip()

    save_user_action(user_id, name, prompt_tpl)
    text = (
        f'✅ <b>Действие «{name}» успешно создано!</b>\n\n'
        f'<b>Шаблон:</b> <i>«{prompt_tpl}»</i>\n\n'
        f'Как запустить:\n'
        f'• Отправьте команду: <code>/{name} &lt;тема&gt;</code>\n'
        f'• Или: <code>/do {name} &lt;тема&gt;</code>\n'
        f'• Или выберите в списке <code>/actions</code>.'
    )
    keyboard = {
        'inline_keyboard': [
            [
                {
                    'text': f'▶️ Проверить: /{name} Счёт и письмо',
                    'callback_data': f'act_run:{name}:Счёт и письмо'
                }
            ],
            [
                {
                    'text': '📋 Все мои действия',
                    'callback_data': 'show_my_actions'
                }
            ]
        ]
    }
    send_message(chat_id, text, reply_markup=keyboard)


def handle_list_actions(chat_id: int, user: dict):
    user_id = str(user.get('id', chat_id))
    actions = load_user_actions(user_id)

    if not actions:
        text = (
            '⚡ <b>У вас пока нет сохранённых действий.</b>\n\n'
            'Вы можете создать своё действие командой:\n'
            '<code>/addaction рифма Сочини стишок по теме {topic}</code>'
        )
        send_message(chat_id, text, reply_markup=get_start_keyboard())
        return

    text = '⚡ <b>Ваши кастомные действия и команды:</b>\n\n'
    buttons = []
    for name, tpl in actions.items():
        text += f'• <b>/{name}</b> — <i>«{tpl}»</i>\n\n'
        buttons.append([
            {
                'text': f'▶️ Выполнить: /{name}',
                'callback_data': f'act_run:{name}:Закрепление темы'
            },
            {
                'text': f'🗑️ Удалить',
                'callback_data': f'act_del:{name}'
            }
        ])

    buttons.append([
        {
            'text': '➕ Добавить новое действие',
            'callback_data': 'prompt_add_action'
        }
    ])
    send_message(chat_id, text, reply_markup={'inline_keyboard': buttons})


def handle_delete_action(chat_id: int, user: dict, action_name: str):
    user_id = str(user.get('id', chat_id))
    name = action_name.lower().strip().replace('/', '')
    success = delete_user_action(user_id, name)
    if success:
        send_message(chat_id, f'🗑️ Действие <b>/{name}</b> успешно удалено.')
    else:
        send_message(chat_id, f'⚠️ Действие <b>/{name}</b> не найдено.')
    handle_list_actions(chat_id, user)


def handle_execute_action(chat_id: int, user: dict, action_name: str, topic: str):
    user_id = str(user.get('id', chat_id))
    actions = load_user_actions(user_id)
    name = action_name.lower().strip().replace('/', '')

    t = topic.strip() if topic.strip() else 'Математика и письмо'

    if name in actions:
        tpl = actions[name]
        prompt = tpl.replace('{topic}', t)

        system_prompt = 'Ты методист начальной школы и эксперт педагогики. Выполни педагогическую задачу кратко, интересно, с пользой для детей и в соответствии с ФГОС.'
        gpt_res = call_yandex_gpt(system_prompt, prompt, timeout=25)

        if gpt_res:
            res_body = f'{gpt_res}'
        else:
            res_body = (
                f'> <i>«По теме "{t}" юные исследователи открывают чудесное правило! '
                f'Шаг за шагом алгоритм складывается легко и просто, а знания становятся надёжным фундаментом '
                f'для новых открытий!»</i>'
            )

        reply = (
            f'⚡ <b>Выполнение кастомного действия «/{name}»:</b>\n\n'
            f'<i>Тема урока:</i> <b>«{t}»</b>\n\n'
            f'🦉 <b>Результат MetodistAI (YandexGPT Pro):</b>\n\n'
            f'{res_body}\n\n'
            f'💡 <i>Инструкция выполнена по шаблону: "{prompt}"</i>'
        )
    else:
        reply = (
            f'⚠️ Команда <b>/{name}</b> не найдена в ваших действиях.\n\n'
            f'Создайте её: <code>/addaction {name} &lt;ваш промпт&gt;</code>'
        )

    keyboard = {
        'inline_keyboard': [
            [
                {
                    'text': '✨ Улучшить с MetodistPro AI',
                    'callback_data': f'enhance_lesson:{t}'
                }
            ],
            [
                {
                    'text': '📋 Все мои действия',
                    'callback_data': 'show_my_actions'
                }
            ]
        ]
    }
    send_message(chat_id, reply, reply_markup=keyboard)


# --- Стандартные педагогические функции ---

def handle_parents_chat(chat_id: int, topic: str):
    t = topic.strip() if topic.strip() else 'Закрепление изученного материала'
    text = (
        f'🦉 <b>Готовый пост для родительского чата (WhatsApp / Telegram)</b>\n\n'
        f'<i>Тема урока:</i> <b>«{t}»</b>\n'
        f'<i>(Скопируйте и отправьте в родительский чат класса)</i>\n'
        f'━━━━━━━━━━━━━━━━━━━━━\n\n'
        f'Здравствуйте, уважаемые родители! 🌿\n\n'
        f'Сегодня на уроке мы подробно разобрали тему <b>«{t}»</b> вместе с нашим верным помощником Совёнком!\n\n'
        f'📌 <b>Что узнали и чему научились:</b>\n'
        f'1. Разобрали главное правило на ярких жизненных примерах.\n'
        f'2. Закрепили навык в тренировочных заданиях и нашли хитрые «ловушки».\n'
        f'3. Провели весёлую двигательную разминку для глаз и осанки.\n\n'
        f'⭐ <b>За что похвалить ребёнка сегодня:</b>\n'
        f'Ребята отлично включились в работу, уверенно рассуждали и помогали друг другу!\n\n'
        f'💡 <b>Маленький совет для дома (5 минут):</b>\n'
        f'Спросите сегодня у юного исследователя, какой пример из темы «{t}» ему запомнился больше всего, и похвалите за старания! Без лишнего стресса — только поддержка. ❤️\n\n'
        f'<i>С уважением и теплом, ваш учитель.</i>\n'
        f'━━━━━━━━━━━━━━━━━━━━━'
    )
    keyboard = {
        'inline_keyboard': [
            [
                {
                    'text': '✨ Улучшить с MetodistPro AI',
                    'callback_data': f'enhance_lesson:{t}'
                }
            ],
            [
                {
                    'text': '📚 3 уровня ДЗ',
                    'callback_data': f'gen_hw:{t}'
                },
                {
                    'text': '🎮 Игра по теме',
                    'callback_data': f'gen_game:{t}'
                }
            ],
            [
                {
                    'text': '🚀 Открыть в приложении',
                    'web_app': {'url': f'{WEB_APP_URL}?startapp=assistant'}
                }
            ]
        ]
    }
    send_message(chat_id, text, reply_markup=keyboard)


def handle_homework_generation(chat_id: int, topic: str):
    t = topic.strip() if topic.strip() else 'Математика и письмо'
    text = (
        f'🦉 <b>Дифференцированное домашнее задание (3 уровня по ФГОС)</b>\n\n'
        f'<i>Тема:</i> <b>«{t}»</b>\n\n'
        f'🟢 <b>Уровень 1. Базовый (Обязательный для всех по ФГОС, 7-10 мин):</b>\n'
        f'• Выполнить 3 тренировочных упражнения по готовому образцу из классной работы.\n'
        f'• <i>Цель:</i> Довести правильное оформление и алгоритм до автоматизма.\n\n'
        f'🟡 <b>Уровень 2. Продвинутый (По желанию, 10-12 мин):</b>\n'
        f'• Составить 2 собственных примера на тему «{t}» с подвохом для соседа по парте.\n'
        f'• <i>Цель:</i> Осознанное применение знания в нестандартной ситуации.\n\n'
        f'🔴 <b>Уровень 3. ТРИЗ-вызов (Творческий / Олимпиадный, 10-15 мин):</b>\n'
        f'• Нарисовать мини-комикс или загадку: <i>«Как знание темы {t} помогло маскоту спасти планету?»</i>\n'
        f'• <i>Награда:</i> Золотой кристалл Совёнка и право провести разминку! 🌟'
    )
    keyboard = {
        'inline_keyboard': [
            [
                {
                    'text': '✨ Улучшить с MetodistPro AI',
                    'callback_data': f'enhance_lesson:{t}'
                }
            ],
            [
                {
                    'text': '💬 Пост родителям',
                    'callback_data': f'gen_parents:{t}'
                },
                {
                    'text': '📝 Экспресс-тест',
                    'callback_data': f'gen_test:{t}'
                }
            ],
            [
                {
                    'text': '📄 Распечатать рабочий лист (PDF)',
                    'callback_data': 'download_sample_pdf'
                }
            ]
        ]
    }
    send_message(chat_id, text, reply_markup=keyboard)


def handle_game_generation(chat_id: int, topic: str):
    t = topic.strip() if topic.strip() else 'Путешествие в мир знаний'
    text = (
        f'🦉 <b>Сюжетный обучающий квест: «Экспедиция Совёнка»</b>\n\n'
        f'<i>Тема урока:</i> <b>«{t}»</b>\n\n'
        f'🧭 <b>Сюжетная завязка для учителя:</b>\n'
        f'> <i>«Ребята, в нашем Сказочном Лесу пропал волшебный свиток Мудрости! '
        f'Чтобы его расшифровать, нужно пройти 3 испытания по теме "{t}". Готовы помочь Совёнку?»</i>\n\n'
        f'🎯 <b>Раунд 1. «Разведка на поляне» (Устный блиц, 3 мин):</b>\n'
        f'Учитель бросает мячик ученику и называет термин. Ученик быстро продолжает правило.\n\n'
        f'⚡ <b>Раунд 2. «Шифровка в парах» (4 мин):</b>\n'
        f'Каждая парта получает карточку с заданием-ловушкой по теме «{t}». Нужно найти ошибку за 90 секунд.\n\n'
        f'🏆 <b>Раунд 3. «Портал Знаний» (Рефлексия, 3 мин):</b>\n'
        f'Свиток открыт! Все ученики получают наградные звёздочки успеваемости! ⭐⭐⭐'
    )
    keyboard = {
        'inline_keyboard': [
            [
                {
                    'text': '✨ Улучшить с MetodistPro AI',
                    'callback_data': f'enhance_lesson:{t}'
                }
            ],
            [
                {
                    'text': '💬 Отправить пост родителям',
                    'callback_data': f'gen_parents:{t}'
                },
                {
                    'text': '📚 Задать ДЗ по теме',
                    'callback_data': f'gen_hw:{t}'
                }
            ]
        ]
    }
    send_message(chat_id, text, reply_markup=keyboard)


def handle_test_generation(chat_id: int, topic: str):
    t = topic.strip() if topic.strip() else 'Контрольный срез'
    text = (
        f'🦉 <b>Экспресс-тест проверки знаний (3-5 мин)</b>\n\n'
        f'<i>Тема:</i> <b>«{t}»</b>\n\n'
        f'<b>1. Базовый вопрос:</b>\n'
        f'Какое главное правило лежит в основе темы «{t}»?\n'
        f'А) Правило работает только по четвергам\n'
        f'Б) Это фундаментальный закон оформления и вычисления\n'
        f'В) Решать можно произвольно\n'
        f'<i>(Эталон: Б)</i>\n\n'
        f'<b>2. Практическая задача:</b>\n'
        f'Каков первый шаг при решении упражнения?\n'
        f'А) Прочитать внимательно условие и выделить главное\n'
        f'Б) Сразу записать ответ наугад\n'
        f'В) Закрыть тетрадь\n'
        f'<i>(Эталон: А)</i>\n\n'
        f'<b>3. Вопрос на логику и смекалку:</b>\n'
        f'Почему нельзя пропускать этап проверки в теме «{t}»?\n\n'
        f'🔑 <b>Критерии:</b> 3 ответа — отлично (⭐⭐⭐), 2 — хорошо (⭐⭐).'
    )
    keyboard = {
        'inline_keyboard': [
            [
                {
                    'text': '✨ Улучшить с MetodistPro AI',
                    'callback_data': f'enhance_lesson:{t}'
                }
            ],
            [
                {
                    'text': '💬 Пост в чат родителей',
                    'callback_data': f'gen_parents:{t}'
                },
                {
                    'text': '📚 3 уровня ДЗ',
                    'callback_data': f'gen_hw:{t}'
                }
            ]
        ]
    }
    send_message(chat_id, text, reply_markup=keyboard)


def handle_worksheet_generation(chat_id: int, topic: str):
    t = topic.strip() if topic.strip() else 'Рабочий лист'
    text = (
        f'🦉 <b>Текстовый экспресс-рабочий лист</b>\n\n'
        f'<i>Тема:</i> <b>«{t}»</b>\n'
        f'━━━━━━━━━━━━━━━━━━━━━\n\n'
        f'✏️ <b>Задание 1. «Разминка пальчиков и мысли»:</b>\n'
        f'Вставь пропущенные элементы в правило по теме «{t}» и подчеркни главное слово зелёным карандашом.\n\n'
        f'🔍 <b>Задание 2. «Секретный шифр Совёнка»:</b>\n'
        f'Реши 3 примера по алгоритму. Если ответ чётный — обведи в кружок, если нечётный — в треугольник.\n\n'
        f'🌟 <b>Задание 3. «Ловушка Незнайки»:</b>\n'
        f'Незнайка допустил ошибку в оформлении темы «{t}». Найди её, исправь красной пастой и запиши верный вариант.\n\n'
        f'━━━━━━━━━━━━━━━━━━━━━\n'
        f'<i>Цветную версию листа с шапкой YandexART можно распечатать в приложении!</i>'
    )
    keyboard = {
        'inline_keyboard': [
            [
                {
                    'text': '📄 Скачать цветной PDF лист',
                    'callback_data': 'download_sample_pdf'
                }
            ],
            [
                {
                    'text': '🚀 Открыть в приложении',
                    'web_app': {'url': WEB_APP_URL}
                }
            ]
        ]
    }
    send_message(chat_id, text, reply_markup=keyboard)


def handle_modes(chat_id: int):
    text = (
        '🎭 <b>5 Педагогических режимов MetodistAI:</b>\n\n'
        '1. 🎓 <b>Академический эксперт:</b> строгое соответствие ФГОС, СанПиН, классика Пчёлко/Костина, методическая точность.\n'
        '2. 💬 <b>Дипломат родительских чатов:</b> создание деликатных, понятных и тёплых сообщений для родителей в 1 клик.\n'
        '3. 📚 <b>Дифференциатор заданий:</b> разделение любого упражнения на 3 уровня сложности (для отстающих, норма и олимпиадники).\n'
        '4. 🎮 <b>Игропрактик & Миры:</b> сюжетные квесты, игры с мячом, сторителлинг с маскотами 5 вселенных.\n'
        '5. 🧩 <b>ТРИЗ-наставник:</b> противоречия, нестандартные эвристические задачи, развитие гибкости мышления.\n\n'
        '<i>Для запуска нужного режима отправьте команду или нажмите кнопку ниже:</i>'
    )
    keyboard = {
        'inline_keyboard': [
            [
                {
                    'text': '✨ Улучшить с MetodistPro AI',
                    'callback_data': 'enhance_lesson:Закрепление темы'
                }
            ],
            [
                {
                    'text': '💬 Пост родителям',
                    'callback_data': 'gen_parents:Математика и письмо'
                },
                {
                    'text': '📚 3 уровня ДЗ',
                    'callback_data': 'gen_hw:Таблица умножения'
                }
            ]
        ]
    }
    send_message(chat_id, text, reply_markup=keyboard)


def handle_break(chat_id: int):
    reply = (
        '🦉 <b>У-ху! Тематическая разминка по СанПиН:</b>\n\n'
        '<i>(Учитель просит детей встать около парт)</i>\n\n'
        '⭐ <b>1. «Звёздные потягушки» (30 сек):</b>\n'
        'Тянемся вверх на носочках, пальчики растопырили, как лучики солнца. Вдох носом — выдох ртом!\n\n'
        '⭐ <b>2. «Умная Сова» (Координация, 45 сек):</b>\n'
        'Правая рука гладит животик, а левая легонько хлопает по макушке. Поменяли ручки!\n\n'
        '⭐ <b>3. «Гимнастика для глаз по СанПиН»:</b>\n'
        'Посмотрели на кончик носа — перевели взгляд в окно на дальнее облако (4 раза).\n\n'
        '💡 <i>Совет: смена деятельности каждые 7-10 минут сохраняет 100% фокус первоклассников!</i>'
    )
    send_message(chat_id, reply, reply_markup=get_start_keyboard())


def handle_trap(chat_id: int, topic: str):
    t = topic.strip() if topic.strip() else 'Правило урока'
    text = (
        f'🦉 <b>Задание «Ловушка Незнайки» по теме «{t}»</b>\n\n'
        f'В класс прибежал Незнайка и радостно кричит:\n'
        f'> <i>«Я самый умный! Я знаю всё про тему "{t}" и утверждаю, что правила учить не надо — как слышится, так и пишется!»</i>\n\n'
        f'<b>Задание для ребят:</b>\n'
        f'1. Найдите ошибку в рассуждении Незнайки.\n'
        f'2. Назовите главное академическое правило нашей темы.\n'
        f'3. Помогите Совёнку исправить карточку Незнайки и заработать победный кристалл! 💎'
    )
    keyboard = {
        'inline_keyboard': [
            [
                {
                    'text': '✨ Улучшить с MetodistPro AI',
                    'callback_data': f'enhance_lesson:{t}'
                }
            ],
            [
                {
                    'text': '📚 3 уровня ДЗ',
                    'callback_data': f'gen_hw:{t}'
                },
                {
                    'text': '💬 Пост родителям',
                    'callback_data': f'gen_parents:{t}'
                }
            ]
        ]
    }
    send_message(chat_id, text, reply_markup=keyboard)


def handle_intro(chat_id: int, topic: str):
    t = topic.strip() if topic.strip() else 'Удивительный мир знаний'
    text = (
        f'🦉 <b>Вдохновляющее вводное слово учителя (первые 2 минуты урока):</b>\n\n'
        f'<i>(Учитель выдерживает короткую паузу, тепло улыбается классу):</i>\n\n'
        f'> «Здравствуйте, юные исследователи! Посмотрите вокруг себя: прямо сейчас мы окружены тайнами логики и языка. '
        f'Сегодня Совёнок принёс нам необычную загадку по теме <b>"{t}"</b>. '
        f'Тот, кто разгадает её секрет, сможет щёлкать сложные примеры как орешки! '
        f'Кто готов отправиться в экспедицию за открытием? Поднимите руки! Отлично, тетради наготове — поехали!»\n\n'
        f'✨ <i>Прямой зрительный контакт и интрига включают произвольное внимание учеников на 100%!</i>'
    )
    keyboard = {
        'inline_keyboard': [
            [
                {
                    'text': '✨ Улучшить с MetodistPro AI',
                    'callback_data': f'enhance_lesson:{t}'
                }
            ],
            [
                {
                    'text': '🎮 Запустить игру',
                    'callback_data': f'gen_game:{t}'
                },
                {
                    'text': '📝 Экспресс-тест',
                    'callback_data': f'gen_test:{t}'
                }
            ]
        ]
    }
    send_message(chat_id, text, reply_markup=keyboard)


def handle_reminders(chat_id: int):
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
        '   <i>Уютная атмосфера, счёт лепестков, мягкая адаптация для малышей.</i>\n\n'
        'Все миры снабжены панорамными арт-шапками YandexART в PDF!'
    )
    send_message(chat_id, text, reply_markup=get_start_keyboard())


def handle_director(chat_id: int):
    text = (
        '👑 <b>Тариф «Директор» (Metodist Pro Director)</b>\n\n'
        'Флагманский тариф для директоров, завучей, кафедр и передовых школ:\n\n'
        '• 🦉 <b>Эксклюзивный бот MetodistAI в Telegram:</b> доступен только в тарифе «Директор».\n'
        '• ✨ <b>«Улучшить с MetodistPro AI»:</b> двухпроходное обогащение урока (диалоги, ТРИЗ, 3 ур. ДЗ, СанПиН).\n'
        '• ⚡ <b>Свои действия и команды:</b> создание неограниченного числа собственных педагогических команд (/addaction).\n'
        '• 🎨 <b>Студия авторских миров:</b> создание собственного маскота школы/лицея, генерация фирменных шапок YandexART.\n'
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
            'id': 'iq_enhance_lesson',
            'title': '✨ Улучшить урок с MetodistPro AI',
            'description': 'Драматургия, ТРИЗ, 3 уровня ДЗ и СанПиН разминка',
            'input_message_content': {
                'message_text': (
                    '✨ <b>Урок обогащён с MetodistPro AI [Директор]:</b>\n\n'
                    'Тема: «' + (query if query else 'Закрепление темы') + '»\n\n'
                    '1. Диалог учителя и детей с таймингом [Х мин]\n'
                    '2. Проблемная ТРИЗ-задача\n'
                    '3. Ловушка Незнайки\n'
                    '4. Разминка по СанПиН\n'
                    '5. 3 уровня дифференцированного ДЗ\n\n'
                    '👑 <i>Сгенерировано в MetodistAI Bot</i>'
                ),
                'parse_mode': 'HTML'
            }
        },
        {
            'type': 'article',
            'id': 'iq_parents_post',
            'title': '💬 Пост для родительского чата',
            'description': 'Готовый отчет урока для родителей в WhatsApp/TG',
            'input_message_content': {
                'message_text': (
                    '💬 <b>Сообщение для родительского чата:</b>\n\n'
                    'Здравствуйте, уважаемые родители! 🌿\n'
                    'Сегодня на уроке по теме «' + (query if query else 'Закрепление темы') + '» '
                    'ребята проявили чудесную активность и отлично справились со всеми заданиями! '
                    'Похвалите сегодня юных исследователей за старания. ❤️\n\n'
                    '🎓 <i>Сгенерировано в MetodistAI Bot</i>'
                ),
                'parse_mode': 'HTML'
            }
        },
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
                    '🎓 <i>Сгенерировано в MetodistAI Bot</i>'
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
                    '👉 Запустить: ' + WEB_APP_URL
                ),
                'parse_mode': 'HTML'
            }
        }
    ]
    answer_inline_query(iq_id, results)


def handle_owl_assistant(chat_id: int, user: dict, query: str):
    """Интеллектуальный роутер запросов к MetodistAI."""
    q_lower = query.lower()

    if any(k in q_lower for k in ['улучш', 'обогат', 'драматург']):
        handle_enhance_lesson(chat_id, query)
        return

    if any(k in q_lower for k in ['родител', 'мам', 'пап', 'чат']):
        handle_parents_chat(chat_id, query)
        return

    if any(k in q_lower for k in ['домашк', 'дз', 'задан на дом', 'уровн']):
        handle_homework_generation(chat_id, query)
        return

    if any(k in q_lower for k in ['игра', 'квест', 'геймифик', 'сюжет']):
        handle_game_generation(chat_id, query)
        return

    if any(k in q_lower for k in ['тест', 'срез', 'опрос', 'проверк', 'ключ']):
        handle_test_generation(chat_id, query)
        return

    if any(k in q_lower for k in ['физкульт', 'разминк', 'движен', 'пауз', 'гимнастик']):
        handle_break(chat_id)
        return

    if any(k in q_lower for k in ['ловушк', 'незнайк']):
        handle_trap(chat_id, query)
        return

    if any(k in q_lower for k in ['вступлен', 'вводн', 'начало', 'мотивац']):
        handle_intro(chat_id, query)
        return

    system_prompt = (
        'Ты опытный методист начальной школы и дошкольного образования, персональный AI-ассистент платформы «Методист Pro» (Совёнок-Методист). '
        'Ты мастер советских методик (Пчёлко, Костин, Редозубов, Мазина) и ТРИЗ-педагогики. '
        'Давай конкретные, добрые, академически выверенные практические ответы с примерами заданий и репликами учителя для детей. Форматируй с эмодзи-буллетами.'
    )
    gpt_res = call_yandex_gpt(system_prompt, query, timeout=25)

    if gpt_res:
        reply = (
            f'🦉 <b>MetodistAI (YandexGPT Pro):</b>\n\n'
            f'{gpt_res}\n\n'
            f'<i>Что сформировать по этой теме прямо сейчас?</i>'
        )
    else:
        reply = (
            f'🦉 <b>MetodistAI на связи!</b>\n\n'
            f'По вашему вопросу: <i>«{query}»</i>\n\n'
            f'• Рекомендую структурировать этап урока по <b>классической трёхчастной модели</b> (устная разминка → первичное закрепление с образцом → самостоятельная ТРИЗ-задача).\n'
            f'• В приложении вы можете за 1 клик переключить этот урок в любой из <b>5 игровых миров</b> и сгенерировать цветной лист заданий.\n\n'
            f'Что сформировать по этой теме прямо сейчас?'
        )

    keyboard = {
        'inline_keyboard': [
            [
                {
                    'text': '✨ Улучшить с MetodistPro AI',
                    'callback_data': f'enhance_lesson:{query}'
                }
            ],
            [
                {
                    'text': '💬 Пост в чат родителей',
                    'callback_data': f'gen_parents:{query}'
                },
                {
                    'text': '📚 3 уровня ДЗ',
                    'callback_data': f'gen_hw:{query}'
                }
            ],
            [
                {
                    'text': '🎮 Обучающая игра',
                    'callback_data': f'gen_game:{query}'
                },
                {
                    'text': '📝 Экспресс-тест',
                    'callback_data': f'gen_test:{query}'
                }
            ],
            [
                {
                    'text': '🚀 Открыть в Mini App',
                    'web_app': {'url': f'{WEB_APP_URL}?startapp=assistant'}
                }
            ]
        ]
    }
    send_message(chat_id, reply, reply_markup=keyboard)


def process_update(update: dict):
    if 'inline_query' in update:
        handle_inline_query(update['inline_query'])
        return

    if 'message' in update:
        msg = update['message']
        chat_id = msg['chat']['id']
        user = msg.get('from', {})
        text = msg.get('text', '').strip()

        if text.startswith('/start'):
            handle_start(chat_id, user)
        elif text.startswith('/help'):
            handle_help(chat_id)
        elif text.startswith('/enhance') or text.startswith('/improve'):
            topic = text.replace('/enhance', '', 1).replace('/improve', '', 1).strip()
            handle_enhance_lesson(chat_id, topic)
        elif text.startswith('/addaction'):
            handle_add_action(chat_id, user, text)
        elif text.startswith('/actions') or text.startswith('/my_actions'):
            handle_list_actions(chat_id, user)
        elif text.startswith('/delaction'):
            action_name = text.replace('/delaction', '', 1).strip()
            handle_delete_action(chat_id, user, action_name)
        elif text.startswith('/do '):
            parts = text.replace('/do', '', 1).strip().split(maxsplit=1)
            act_name = parts[0] if parts else 'стих'
            t = parts[1] if len(parts) > 1 else 'Счёт и письмо'
            handle_execute_action(chat_id, user, act_name, t)
        elif text.startswith('/parents'):
            topic = text.replace('/parents', '', 1).strip()
            handle_parents_chat(chat_id, topic)
        elif text.startswith('/hw'):
            topic = text.replace('/hw', '', 1).strip()
            handle_homework_generation(chat_id, topic)
        elif text.startswith('/game'):
            topic = text.replace('/game', '', 1).strip()
            handle_game_generation(chat_id, topic)
        elif text.startswith('/test'):
            topic = text.replace('/test', '', 1).strip()
            handle_test_generation(chat_id, topic)
        elif text.startswith('/worksheet'):
            topic = text.replace('/worksheet', '', 1).strip()
            handle_worksheet_generation(chat_id, topic)
        elif text.startswith('/modes'):
            handle_modes(chat_id)
        elif text.startswith('/break') or text.startswith('/pause'):
            handle_break(chat_id)
        elif text.startswith('/trap'):
            topic = text.replace('/trap', '', 1).strip()
            handle_trap(chat_id, topic)
        elif text.startswith('/intro'):
            topic = text.replace('/intro', '', 1).strip()
            handle_intro(chat_id, topic)
        elif text.startswith('/worlds'):
            handle_worlds(chat_id)
        elif text.startswith('/director'):
            handle_director(chat_id)
        elif text.startswith('/pdf'):
            handle_pdf_send(chat_id)
        elif text.startswith('/remind') or text.startswith('/schedule'):
            handle_reminders(chat_id)
        elif text.startswith('/owl'):
            q = text.replace('/owl', '', 1).strip()
            handle_owl_assistant(chat_id, user, q if q else 'Как провести урок интересно?')
        elif text.startswith('/app'):
            send_message(chat_id, '🚀 Нажмите кнопку ниже для запуска:', reply_markup=get_start_keyboard())
        elif text.startswith('/'):
            # Проверка, не является ли это вызовом кастомного действия пользователя: /<действие> [тема]
            cmd = text[1:].split()[0].lower()
            topic = text[1 + len(cmd):].strip()
            user_id = str(user.get('id', chat_id))
            actions = load_user_actions(user_id)
            if cmd in actions:
                handle_execute_action(chat_id, user, cmd, topic)
            else:
                handle_owl_assistant(chat_id, user, text)
        elif text:
            handle_owl_assistant(chat_id, user, text)

    elif 'callback_query' in update:
        cq = update['callback_query']
        cq_id = cq['id']
        chat_id = cq['message']['chat']['id']
        user = cq.get('from', {})
        data = cq.get('data', '')

        answer_callback_query(cq_id)

        if data.startswith('enhance_lesson:'):
            topic = data.replace('enhance_lesson:', '', 1)
            handle_enhance_lesson(chat_id, topic)
        elif data.startswith('act_run:'):
            parts = data.replace('act_run:', '', 1).split(':', 1)
            act_name = parts[0]
            topic = parts[1] if len(parts) > 1 else 'Закрепление материала'
            handle_execute_action(chat_id, user, act_name, topic)
        elif data.startswith('act_del:'):
            act_name = data.replace('act_del:', '', 1)
            handle_delete_action(chat_id, user, act_name)
        elif data == 'show_my_actions':
            handle_list_actions(chat_id, user)
        elif data == 'prompt_add_action':
            send_message(
                chat_id,
                '⚡ Для создания действия отправьте команду:\n'
                '<code>/addaction &lt;имя&gt; &lt;промпт с маркером {topic}&gt;</code>\n\n'
                'Пример: <code>/addaction загадка Сочини загадку про {topic}</code>'
            )
        elif data.startswith('gen_parents:'):
            topic = data.replace('gen_parents:', '', 1)
            handle_parents_chat(chat_id, topic)
        elif data.startswith('gen_hw:'):
            topic = data.replace('gen_hw:', '', 1)
            handle_homework_generation(chat_id, topic)
        elif data.startswith('gen_game:'):
            topic = data.replace('gen_game:', '', 1)
            handle_game_generation(chat_id, topic)
        elif data.startswith('gen_test:'):
            topic = data.replace('gen_test:', '', 1)
            handle_test_generation(chat_id, topic)
        elif data == 'download_sample_pdf':
            handle_pdf_send(chat_id)
        elif data == 'show_director_info':
            handle_director(chat_id)
        elif data == 'show_worlds_info':
            handle_worlds(chat_id)
        elif data == 'setup_reminders':
            handle_reminders(chat_id)
        elif data == 'show_modes':
            handle_modes(chat_id)


def run_polling():
    print(f'[INFO] Запуск отдельного бота-помощника MetodistAI (Тариф Директор)...')
    print(f'[INFO] Токен: {METODIST_AI_TOKEN[:10]}... (скрыт)')
    me = make_request('getMe')
    if me.get('ok'):
        bot_info = me['result']
        print(f"[OK] Авторизован MetodistAI бот: @{bot_info.get('username')} ({bot_info.get('first_name')})")
    else:
        print(f"[WARNING] Не удалось подключиться к Telegram API: {me.get('error')}")
        print("[INFO] При необходимости настройте переменную HTTPS_PROXY.")

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
            print('\n[INFO] Остановка бота MetodistAI.')
            break
        except Exception as e:
            print(f'[ERROR] Ошибка polling: {e}', file=sys.stderr)
            time.sleep(3)


if __name__ == '__main__':
    run_polling()
