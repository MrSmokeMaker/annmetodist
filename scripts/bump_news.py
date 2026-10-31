import json

def bump():
    with open('assets/news.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    data['currentVersion'] = 'v0.5.6'
    data['updatedAt'] = '2026-10-31'

    new_release = {
        'version': 'v0.5.6',
        'date': '31 октября 2026',
        'title': 'Вылезающее меню выбора Telegram-ботов, дизайнерские маскоты и адаптивный доступ',
        'badge': 'Telegram',
        'highlights': [
            'Интерактивная кнопка «Telegram боты (2)» с выпадающим меню подробного сравнения и быстрого перехода к любому из ботов платформы.',
            'Два новых дизайнерских PNG-маскота 512x512: Mini App самолёт-конструктор (@annmetodist_bot) и кристаллический нейро-мозг с золотой короной Директора (@MetodistAIpro_bot).',
            'Полная кроссплатформенная интеграция: кнопка встроена на десктопе (в шапку и боковую панель) и на мобильных устройствах (в верхнюю панель и главный дашборд Bento Hero).',
            'Интерактивный раздел «Команды и фичи ⚡»: шпаргалка популярных дидактических команд (/addaction, /actions, /pdf) с моментальным копированием в буфер в 1 клик.',
            'Прямой запуск Mini App и чатов Telegram с поддержкой как нативного Telegram WebApp API, так и стандартных браузеров.'
        ]
    }

    # Only insert if not already present
    if not any(r['version'] == 'v0.5.6' for r in data['releases']):
        data['releases'].insert(0, new_release)

    with open('assets/news.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print("Bumped news.json to v0.5.6")

if __name__ == '__main__':
    bump()
