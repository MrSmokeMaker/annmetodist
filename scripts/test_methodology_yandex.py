import sys
import os
import urllib.request
import json

sys.stdout.reconfigure(encoding='utf-8')

def test():
    proxy_url = 'https://functions.yandexcloud.net/d4eq8r2ueghpmbl5oj3c'
    
    print("=== ТЕСТ ДВУХЭТАПНОГО ПОДХОДА YANDEXGPT PRO ===")
    print("Этап 1: Извлечение всех тем курса без искусственных лимитов...")
    
    stage1_payload = {
        'model': 'yandexgpt',
        'messages': [
            {
                'role': 'system',
                'content': 'Ты ведущий методист-дидакт РФ. Твоя задача — извлечь полный календарно-тематический план всех тем курса без искусственного ограничения 10-20. Выведи строго валидный JSON-массив.'
            },
            {
                'role': 'user',
                'content': 'Составь полный поурочный список тем для курса «Математика и логика: путешествие в мир геометрических фигур и дробей» для 2 класса. Укажи не менее 12-15 тем с номерами, названиями, разделами и связью с предыдущей темой.'
            }
        ]
    }

    req1 = urllib.request.Request(
        proxy_url,
        data=json.dumps(stage1_payload).encode('utf-8'),
        headers={'Content-Type': 'application/json'}
    )
    res1 = urllib.request.urlopen(req1, timeout=60)
    data1 = json.loads(res1.read().decode('utf-8'))
    stage1_answer = data1['choices'][0]['message']['content']
    print(f"[OK] Этап 1 завершён. Длина ответа: {len(stage1_answer)} симв.")

    print("Этап 2: Педагогическое микро-обогащение тем (ФГОС, Наглядность, Ловушка Незнайки, ТРИЗ, 3 уровня заданий)...")
    stage2_payload = {
        'model': 'yandexgpt',
        'messages': [
            {
                'role': 'system',
                'content': 'Ты ведущий методист-дидакт. Сформируй детальный педагогический паспорт для предложенных тем урока: цели ФГОС, предметная модель, типичная детская ошибка («Ловушка Незнайки»), 3 уровня заданий (Старт, Практик, ТРИЗ/Детектив) и критерии проверки. Выведи в Markdown.'
            },
            {
                'role': 'user',
                'content': 'Разработай педагогический паспорт для темы: «Деление прямоугольника на равные доли. Понятие половины, трети и четверти (2 класс)». Включи конкретные дидактические механики без подсказок в заданиях ученика.'
            }
        ]
    }

    req2 = urllib.request.Request(
        proxy_url,
        data=json.dumps(stage2_payload).encode('utf-8'),
        headers={'Content-Type': 'application/json'}
    )
    res2 = urllib.request.urlopen(req2, timeout=60)
    data2 = json.loads(res2.read().decode('utf-8'))
    stage2_answer = data2['choices'][0]['message']['content']
    print(f"[OK] Этап 2 завершён. Длина ответа: {len(stage2_answer)} симв.")

    os.makedirs('docs', exist_ok=True)
    with open('docs/test_yandex_methodology_output.md', 'w', encoding='utf-8') as f:
        f.write("# Результаты теста двухэтапного конвейера YandexGPT Pro\n\n")
        f.write("## Этап 1: Макро-структура КТП (Все темы курса)\n\n")
        f.write(stage1_answer + "\n\n")
        f.write("---\n\n")
        f.write("## Этап 2: Педагогический паспорт и микро-обогащение\n\n")
        f.write(stage2_answer + "\n")

    print("[SUCCESS] Двухэтапный тест завершён успешно! Отчёт сохранён в docs/test_yandex_methodology_output.md")

if __name__ == '__main__':
    test()
