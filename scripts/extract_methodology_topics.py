#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
extract_methodology_topics.py
-----------------------------
Двухэтапный скрипт извлечения и обогащения ВСЕХ тем методики (книги) через YandexGPT Pro.
Количество тем НЕ ограничено 10-20 — извлекаются ВСЕ темы учебника/курса!

Этап 1: Макро-структура КТП (Macro Curriculum Mapping)
- Анализ книги / оглавления / программы.
- Извлечение полного перечня тем по четвертям и модулям без искусственных лимитов.

Этап 2: Микро-структурирование и педагогическое обогащение (Micro-Enrichment)
- Для каждой темы формируется глубокий методический паспорт:
  1) Предметные и метапредметные результаты по ФГОС;
  2) Наглядная предметная модель автора;
  3) Ловушка Незнайки (типичная ошибка детей);
  4) Трёхуровневые задания (Старт с образцом, Практик, ТРИЗ/Детектив Pro);
  5) Дидактическая игра или кинезиологическая пауза;
  6) Критерии экспресс-оценки.
"""

import sys
import os
import json
import urllib.request
import argparse
from typing import List, Dict, Any

# Ensure UTF-8 output on Windows
sys.stdout.reconfigure(encoding='utf-8')

PROXY_URL = os.environ.get('YANDEX_GPT_PROXY_URL', 'https://functions.yandexcloud.net/d4eq8r2ueghpmbl5oj3c')


def call_yandex_gpt(system_prompt: str, user_prompt: str, timeout: int = 60) -> str:
    """Вызов YandexGPT Pro через облачный прокси."""
    payload = {
        'model': 'yandexgpt',
        'messages': [
            {'role': 'system', 'content': system_prompt},
            {'role': 'user', 'content': user_prompt}
        ]
    }

    req = urllib.request.Request(
        PROXY_URL,
        data=json.dumps(payload).encode('utf-8'),
        headers={'Content-Type': 'application/json'}
    )

    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            data = json.loads(response.read().decode('utf-8'))
            return data['choices'][0]['message']['content']
    except Exception as e:
        print(f"[YANDEX-GPT ERROR]: {e}")
        raise


def stage_1_extract_all_topics(
    book_title: str,
    author: str,
    subject: str,
    grade: str,
    toc_text: str = ""
) -> List[Dict[str, Any]]:
    """
    ЭТАП 1: Извлечение ВСЕХ тем книги без ограничений (10, 20, 30, 40+ тем).
    """
    print(f"\n=======================================================")
    print(f"  ЭТАП 1: МАКРО-КАРТИРОВАНИЕ ВСЕХ ТЕМ МЕТОДИКИ (КНИГИ)")
    print(f"=======================================================")
    print(f"Книга: {book_title}")
    print(f"Автор: {author}")
    print(f"Предмет: {subject} | Класс/Возраст: {grade}")

    system_prompt = (
        "Ты — ведущий академический методист начального и общего образования высшей категории. "
        "Твоя задача — проанализировать методику (книгу, учебник, пособие) и составить ПОЛНЫЙ, "
        "исчерпывающий поурочный календарно-тематический план ВСЕХ тем данного курса без пропусков "
        "и без искусственных ограничений количества тем. "
        "Выводи результат СТРОГО в формате валидного JSON-массива объектов, без markdown-кавычек и пояснений вокруг."
    )

    user_prompt = f"""
Проанализируй методику/книгу:
• Название: «{book_title}»
• Автор: {author}
• Предмет: {subject}
• Целевой класс / возрастная группа: {grade}
{f'• Фрагмент оглавления / текст программы:' if toc_text else ''}
{toc_text if toc_text else 'Составь полный системный курс по каноническому содержанию классического труда автора.'}

ТРЕБОВАНИЯ К ЭТАПУ 1:
1. НЕ ОГРАНИЧИВАЙСЯ 10-20 ТЕМАМИ! Извлеки ВСЕ дидактические темы курса (от 20 до 50+ тем в зависимости от охвата года/четверти).
2. Соблюдай строгую дидактическую спираль: от базовых наглядных понятий к алгоритмам, затем к сложным комплексным задачам и контролю.
3. Разбей темы по учебным четвертям (четверть 1, четверть 2, четверть 3, четверть 4) или тематическим разделам/модулям.
4. Для КАЖДОЙ темы укажи:
   - "number": сквозной порядковый номер (1, 2, 3...)
   - "title": точное академическое название темы урока
   - "section": название раздела/четверти
   - "lesson_type": тип урока (открытие_нового / отработка_навыка / практикум / контроль / олимпиада_ТРИЗ)
   - "focus_skill": главное предметное действие ученика
   - "bridge_concept": связь с предыдущей темой (мостик преемственности)

Формат ответа: строго чистый JSON-массив:
[
  {{
    "number": 1,
    "title": "...",
    "section": "...",
    "lesson_type": "...",
    "focus_skill": "...",
    "bridge_concept": "..."
  }}
]
"""

    print("Отправка запроса Этапа 1 в YandexGPT Pro...")
    raw_answer = call_yandex_gpt(system_prompt, user_prompt, timeout=90)

    # Clean JSON
    cleaned = raw_answer.strip()
    if cleaned.startswith('```json'):
        cleaned = cleaned[7:]
    if cleaned.startswith('```'):
        cleaned = cleaned[3:]
    if cleaned.endswith('```'):
        cleaned = cleaned[:-3]
    cleaned = cleaned.strip()

    try:
        topics = json.loads(cleaned)
        print(f"[OK] Этап 1 завершён успешно: извлечено ВСЕГО тем: {len(topics)}")
        return topics
    except json.JSONDecodeError as e:
        print(f"[WARN] Прямой JSON-парсинг не удался ({e}). Выполняю интеллектуальное извлечение JSON...")
        start_idx = cleaned.find('[')
        end_idx = cleaned.rfind(']')
        if start_idx != -1 and end_idx != -1:
            topics = json.loads(cleaned[start_idx:end_idx + 1])
            print(f"[OK] Этап 1 извлёк ВСЕГО тем: {len(topics)}")
            return topics
        else:
            raise ValueError(f"Не удалось распознать JSON в ответе:\n{raw_answer[:400]}...")


def stage_2_enrich_topics(
    book_title: str,
    author: str,
    subject: str,
    grade: str,
    topics: List[Dict[str, Any]],
    batch_size: int = 5
) -> List[Dict[str, Any]]:
    """
    ЭТАП 2: Микро-структурирование и педагогическое обогащение каждой темы.
    """
    print(f"\n=======================================================")
    print(f"  ЭТАП 2: ПЕДАГОГИЧЕСКОЕ МИКРО-ОБОГАЩЕНИЕ ВСЕХ ТЕМ")
    print(f"=======================================================")
    print(f"Всего тем для обогащения: {len(topics)}. Пакетная обработка...")

    enriched_topics = []

    system_prompt = (
        "Ты — ведущий эксперт-дидакт и разработчик учебных комплексов начального и общего образования высшей квалификации. "
        "Твоя задача — разработать глубокий педагогический паспорт для каждой предложенной темы по конкретной авторской методике. "
        "Строго соблюдай требования ФГОС, защиту от списывания (без подсказок в раздатке) и методические маркеры автора. "
        "Выводи результат СТРОГО в формате валидного JSON-массива объектов."
    )

    # Process in chunks to ensure maximum quality and avoid token cutoff
    for i in range(0, len(topics), batch_size):
        chunk = topics[i:i + batch_size]
        chunk_numbers = [t['number'] for t in chunk]
        print(f"-> Обогащение тем {chunk_numbers[0]}–{chunk_numbers[-1]} из {len(topics)}...")

        user_prompt = f"""
Методика/Книга: «{book_title}», автор: {author}. Предмет: {subject}, Класс: {grade}.

Обогати следующим темам педагогический паспорт строго в духе авторской методики:
{json.dumps(chunk, ensure_ascii=False, indent=2)}

ДЛЯ КАЖДОЙ ТЕМЫ СФОРМИРУЙ ОБЪЕКТ:
- "number": номер урока
- "title": название темы
- "section": раздел
- "fgos_objectives": {{
    "subject": "конкретное предметное действие",
    "meta_subject": "познавательные УУД, логика и самоконтроль",
    "personal": "мотивация к познанию"
  }},
- "author_visual_model": "осязаемая наглядная предметная модель/метафора в стиле автора",
- "neznayka_trap": "типичная детская ошибка/заблуждение («Ловушка Незнайки») и вопрос для опровержения",
- "three_tier_tasks": {{
    "tier_1_start": "задание базового уровня с разобранным образцом решения (скаффолдинг)",
    "tier_2_practitioner": "задание повышенной сложности (сортировочная таблица с банком слов или исправление ошибки)",
    "tier_3_detective_pro": "ТРИЗ-задача или олимпиадная шифровка открытого типа"
  }},
- "dynamic_pause": "тематическая кинезиологическая или физкульт-разминка со словами речёвки",
- "assessment_criteria": "критерии экспресс-оценивания для учителя и ключи к заданиям"

Выведи валидный JSON-массив для данного пакета тем.
"""

        try:
            raw_answer = call_yandex_gpt(system_prompt, user_prompt, timeout=90)
            cleaned = raw_answer.strip()
            if cleaned.startswith('```json'):
                cleaned = cleaned[7:]
            if cleaned.startswith('```'):
                cleaned = cleaned[3:]
            if cleaned.endswith('```'):
                cleaned = cleaned[:-3]
            cleaned = cleaned.strip()

            start_idx = cleaned.find('[')
            end_idx = cleaned.rfind(']')
            if start_idx != -1 and end_idx != -1:
                batch_enriched = json.loads(cleaned[start_idx:end_idx + 1])
                enriched_topics.extend(batch_enriched)
            else:
                batch_enriched = json.loads(cleaned)
                enriched_topics.extend(batch_enriched)
        except Exception as e:
            print(f"[WARN] Ошибка обогащения пакета {chunk_numbers}: {e}. Используем базовые данные с расширением...")
            for t in chunk:
                enriched_topics.append({
                    "number": t.get("number"),
                    "title": t.get("title"),
                    "section": t.get("section", "Основной курс"),
                    "fgos_objectives": {
                        "subject": f"Овладеть ключевым алгоритмом темы {t.get('title')}",
                        "meta_subject": "Развивать алгоритмическое мышление и самоконтроль",
                        "personal": f"Формировать познавательный интерес по методике {author}"
                    },
                    "author_visual_model": f"Предметная наглядность и схемы по методике {author}",
                    "neznayka_trap": f"Незнайка путает порядок действий по теме «{t.get('title')}». Докажи ошибку!",
                    "three_tier_tasks": {
                        "tier_1_start": f"Уровень 1 • Старт: Базовое применение правила {t.get('title')} по образцу",
                        "tier_2_practitioner": f"Уровень 2 • Практик: Сортировочная таблица и поиск закономерностей",
                        "tier_3_detective_pro": f"Уровень 3 • Детектив Pro: ТРИЗ-парадокс и логическая шифровка"
                    },
                    "dynamic_pause": f"Тематическая разминка исследователей {author}",
                    "assessment_criteria": "4-ступенчатая шкала ФГОС: 7-8 б. (5), 5-6 б. (4), 3-4 б. (3)"
                })

    print(f"[OK] Этап 2 завершён: успешно обогащено тем: {len(enriched_topics)}")
    return enriched_topics


def save_reports(
    book_title: str,
    author: str,
    subject: str,
    grade: str,
    enriched_topics: List[Dict[str, Any]]
):
    """Сохранение результатов в JSON и Markdown."""
    os.makedirs('docs', exist_ok=True)

    json_path = 'docs/methodology_extracted_all_topics.json'
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump({
            "book_title": book_title,
            "author": author,
            "subject": subject,
            "grade": grade,
            "total_topics_count": len(enriched_topics),
            "topics": enriched_topics
        }, f, ensure_ascii=False, indent=2)

    md_path = 'docs/methodology_enriched_report.md'
    with open(md_path, 'w', encoding='utf-8') as f:
        f.write(f"# Полный учебно-методический комплекс тем курса\n\n")
        f.write(f"**Методика / Книга:** «{book_title}»  \n")
        f.write(f"**Автор:** {author}  \n")
        f.write(f"**Предмет:** {subject} | **Класс:** {grade}  \n")
        f.write(f"**Всего извлечено и обогащено тем:** {len(enriched_topics)}  \n\n")
        f.write(f"---\n\n")

        current_sec = ""
        for t in enriched_topics:
            sec = t.get('section', 'Основной раздел')
            if sec != current_sec:
                current_sec = sec
                f.write(f"\n## 📂 Раздел: {current_sec}\n\n")

            f.write(f"### Урок {t.get('number')}. {t.get('title')}\n")
            objs = t.get('fgos_objectives', {})
            f.write(f"- **🎯 Предметная цель ФГОС:** {objs.get('subject', '-')}\n")
            f.write(f"- **🧠 Метапредметные УУД:** {objs.get('meta_subject', '-')}\n")
            f.write(f"- **💡 Наглядная модель автора:** {t.get('author_visual_model', '-')}\n")
            f.write(f"- **⚠️ Ловушка Незнайки:** {t.get('neznayka_trap', '-')}\n")

            tasks = t.get('three_tier_tasks', {})
            f.write(f"- **📋 Трёхуровневый комплекс заданий:**\n")
            f.write(f"  - *Старт (образец):* {tasks.get('tier_1_start', '-')}\n")
            f.write(f"  - *Практик (таблица):* {tasks.get('tier_2_practitioner', '-')}\n")
            f.write(f"  - *Детектив Pro (ТРИЗ):* {tasks.get('tier_3_detective_pro', '-')}\n")
            f.write(f"- **🤸 Динамическая пауза:** {t.get('dynamic_pause', '-')}\n")
            f.write(f"- **🔑 Критерии проверки:** {t.get('assessment_criteria', '-')}\n\n")

    print(f"\n[OK] Результаты сохранены:")
    print(f"  • JSON: {json_path}")
    print(f"  • Markdown: {md_path}")


def main():
    parser = argparse.ArgumentParser(description="Двухэтапный скрипт извлечения ВСЕХ тем методики (книги)")
    parser.add_argument('--book', default='Методика преподавания арифметики в начальной школе', help='Название книги')
    parser.add_argument('--author', default='А. С. Пчёлко, Г. Б. Поляк', help='Автор')
    parser.add_argument('--subject', default='Математика и арифметика', help='Предмет')
    parser.add_argument('--grade', default='1-2 класс', help='Класс/возраст')
    parser.add_argument('--toc-file', default=None, help='Файл с оглавлением книги')
    parser.add_argument('--stage1-only', action='store_true', help='Выполнить только Этап 1')

    args = parser.parse_args()

    toc_text = ""
    if args.toc_file and os.path.exists(args.toc_file):
        with open(args.toc_file, 'r', encoding='utf-8') as f:
            toc_text = f.read()

    # ЭТАП 1
    topics = stage_1_extract_all_topics(
        book_title=args.book,
        author=args.author,
        subject=args.subject,
        grade=args.grade,
        toc_text=toc_text
    )

    if args.stage1_only:
        print(f"Этап 1 завершён. Сохраняю промежуточный список ({len(topics)} тем)...")
        with open('docs/methodology_stage1_topics.json', 'w', encoding='utf-8') as f:
            json.dump(topics, f, ensure_ascii=False, indent=2)
        return

    # ЭТАП 2
    enriched = stage_2_enrich_topics(
        book_title=args.book,
        author=args.author,
        subject=args.subject,
        grade=args.grade,
        topics=topics,
        batch_size=5
    )

    # Сохранение отчетов
    save_reports(args.book, args.author, args.subject, args.grade, enriched)
    print("\n[SUCCESS] Двухэтапный конвейер успешно выполнен для ВСЕХ тем методики!")


if __name__ == '__main__':
    main()
