#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Отдельный AI-бот помощник экосистемы «Методист Pro» — MetodistAI Bot.
Токен: 9106775452:AAHZmVZleB2jeM78FSBRuITBeHFZRFvIPI8

Включает полный комплекс педагогических функций:
- Интерактивный диалог с Совёнком-Методистом AI
- /parents — Генератор постов для родительских чатов WhatsApp / Telegram
- /hw — Дифференцированное домашнее задание на 3 уровня (ФГОС, практика, ТРИЗ)
- /game — Сюжетные квесты и дидактические игры по 5 мирам
- /test — Экспресс-тесты среза знаний с критериями и эталоном ответов
- /worksheet — Быстрый текстовый рабочий лист для урока
- /modes — Переключение 5 педагогических ролей Совёнка
- /break — Тематические физкультминутки по нормам СанПиН
- /trap — Задания «Ловушка Незнайки»
- /intro — Вдохновляющее вводное слово учителя на первые 2 минуты
- /remind — Утренний дайджест и напоминания расписания уроков
- /worlds — 5 тематических миров с арт-шапками YandexART
- /director — Возможности тарифа «Директор»
- /pdf — Отправка образцов рабочих листов PDF
- /app — Запуск веб-платформы Mini App
- Инлайн-режим в любых чатах
"""

import os
import sys
import json
import time
import urllib.request
import urllib.parse
from pathlib import Path

# Токен отдельного бота помощника MetodistAI
METODIST_AI_TOKEN = os.getenv('METODIST_AI_BOT_TOKEN', os.getenv('BOT_TOKEN', '9106775452:AAHZmVZleB2jeM78FSBRuITBeHFZRFvIPI8'))
WEB_APP_URL = os.getenv('WEB_APP_URL', 'https://mrsmokemaker.github.io/annmetodist/')
API_BASE = f'https://api.telegram.org/bot{METODIST_AI_TOKEN}'

# Поддержка локального прокси при необходимости
PROXY = os.getenv('HTTPS_PROXY') or os.getenv('HTTP_PROXY') or os.getenv('AG_LS_PROXY')


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
                    'text': '🦉 Диалог с Совёнком AI',
                    'web_app': {'url': f'{WEB_APP_URL}?startapp=assistant'}
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
                    'text': '🎨 5 Игровых миров',
                    'callback_data': 'show_worlds_info'
                },
                {
                    'text': '👑 Тариф Директор',
                    'callback_data': 'show_director_info'
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
        f'Я — <b>MetodistAI</b>, ваш персональный интеллектуальный AI-помощник учителя '
        f'начальных классов, завуча и воспитателя.\n\n'
        f'🦉 <b>Все педагогические функции активны:</b>\n'
        f'• 💬 <code>/parents &lt;тема&gt;</code> — Пост для родительского чата в 1 клик\n'
        f'• 📚 <code>/hw &lt;тема&gt;</code> — 3 уровня домашнего задания (ФГОС, практика, ТРИЗ)\n'
        f'• 🎮 <code>/game &lt;тема&gt;</code> — Сюжетная игра / квест по теме\n'
        f'• 📝 <code>/test &lt;тема&gt;</code> — Экспресс-срез знаний с ключами проверки\n'
        f'• 📄 <code>/worksheet &lt;тема&gt;</code> — Экспресс-лист заданий прямо в чате\n'
        f'• 🎭 <code>/modes</code> — 5 педагогических ролей Совёнка\n'
        f'• 🤸 <code>/break</code> — Физкультминутка по СанПиН\n'
        f'• 🪤 <code>/trap</code> — Задание «Ловушка Незнайки»\n'
        f'• 🎙️ <code>/intro</code> — Вводные 2 минуты урока учителя\n'
        f'• ⏰ <code>/remind</code> — Расписание и утренний дайджест\n\n'
        f'💬 <i>Вы можете просто написать мне любой методический вопрос или тему урока!</i>'
    )
    send_message(chat_id, text, reply_markup=get_start_keyboard())


def handle_help(chat_id: int):
    text = (
        '📖 <b>Полный справочник команд MetodistAI Bot:</b>\n\n'
        '• <code>/start</code> — Главное интерактивное меню\n'
        '• <code>/app</code> — Запуск приложения «Методист Pro» внутри Telegram\n'
        '• <code>/parents &lt;тема&gt;</code> — Сообщение для родительского чата\n'
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
        '• <code>/director</code> — Возможности тарифа «Директор» (1 199 ₽ / 1 499 ₽)\n'
        '• <code>/pdf</code> — Скачать образцы рабочих листов YandexART\n'
        '• <code>/owl &lt;вопрос&gt;</code> — Свободная консультация по методике'
    )
    send_message(chat_id, text, reply_markup=get_start_keyboard())


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
                    'text': '💬 Отправить пост родителям',
                    'callback_data': f'gen_parents:{t}'
                },
                {
                    'text': '📚 Задать ДЗ по теме',
                    'callback_data': f'gen_hw:{t}'
                }
            ],
            [
                {
                    'text': '🚀 Открыть конструктор в Mini App',
                    'web_app': {'url': WEB_APP_URL}
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
                    'text': '💬 Пост родителям',
                    'callback_data': 'gen_parents:Математика и письмо'
                },
                {
                    'text': '📚 3 уровня ДЗ',
                    'callback_data': 'gen_hw:Таблица умножения'
                }
            ],
            [
                {
                    'text': '🎮 Сюжетная игра',
                    'callback_data': 'gen_game:Правописание безударных'
                },
                {
                    'text': '📝 Экспресс-тест',
                    'callback_data': 'gen_test:Состав числа 10'
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
            'id': 'iq_triz_task',
            'title': '🧩 ТРИЗ-задача Незнайки',
            'description': 'Проблемный вопрос на смекалку для 1-2 классов',
            'input_message_content': {
                'message_text': (
                    '🧩 <b>ТРИЗ-задача по теме «' + (query if query else 'Смекалка') + '»:</b>\n\n'
                    'Как сделать предмет одновременно лёгким и сверхпрочным?\n'
                    'Дети предлагают идеи и защищают гипотезы!\n\n'
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
        elif text.startswith('/parents'):
            topic = text.replace('/parents', '').strip()
            handle_parents_chat(chat_id, topic)
        elif text.startswith('/hw'):
            topic = text.replace('/hw', '').strip()
            handle_homework_generation(chat_id, topic)
        elif text.startswith('/game'):
            topic = text.replace('/game', '').strip()
            handle_game_generation(chat_id, topic)
        elif text.startswith('/test'):
            topic = text.replace('/test', '').strip()
            handle_test_generation(chat_id, topic)
        elif text.startswith('/worksheet'):
            topic = text.replace('/worksheet', '').strip()
            handle_worksheet_generation(chat_id, topic)
        elif text.startswith('/modes'):
            handle_modes(chat_id)
        elif text.startswith('/break') or text.startswith('/pause'):
            handle_break(chat_id)
        elif text.startswith('/trap'):
            topic = text.replace('/trap', '').strip()
            handle_trap(chat_id, topic)
        elif text.startswith('/intro'):
            topic = text.replace('/intro', '').strip()
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
            q = text.replace('/owl', '').strip()
            handle_owl_assistant(chat_id, user, q if q else 'Как провести урок интересно?')
        elif text.startswith('/app'):
            send_message(chat_id, '🚀 Нажмите кнопку ниже для запуска:', reply_markup=get_start_keyboard())
        elif text:
            handle_owl_assistant(chat_id, user, text)

    elif 'callback_query' in update:
        cq = update['callback_query']
        cq_id = cq['id']
        chat_id = cq['message']['chat']['id']
        data = cq.get('data', '')

        answer_callback_query(cq_id)

        if data.startswith('gen_parents:'):
            topic = data.replace('gen_parents:', '')
            handle_parents_chat(chat_id, topic)
        elif data.startswith('gen_hw:'):
            topic = data.replace('gen_hw:', '')
            handle_homework_generation(chat_id, topic)
        elif data.startswith('gen_game:'):
            topic = data.replace('gen_game:', '')
            handle_game_generation(chat_id, topic)
        elif data.startswith('gen_test:'):
            topic = data.replace('gen_test:', '')
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
    print(f'[INFO] Запуск отдельного бота-помощника MetodistAI...')
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
