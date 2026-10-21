#!/usr/bin/env python3
"""
Скрипт для проверки работоспособности изменений перед слиянием PR.
Проверяет основные функции, добавленные в ветке feature/improve-ui-generation.
"""

import os
import sys
import re

def check_file_exists(file_path):
    """Проверяет существование файла."""
    if os.path.exists(file_path):
        print(f"✅ {file_path} - найден")
        return True
    else:
        print(f"❌ {file_path} - не найден")
        return False

def check_html_structure(file_path):
    """Проверяет базовую структуру HTML файла."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        checks = [
            ('DOCTYPE html', 'Объявление DOCTYPE'),
            ('<html', 'Тег <html>'),
            ('<head>', 'Тег <head>'),
            ('<body>', 'Тег <body>'),
            ('</html>', 'Закрывающий тег </html>'),
        ]
        
        all_good = True
        for check_str, check_name in checks:
            if check_str in content:
                print(f"  ✅ {check_name}")
            else:
                print(f"  ❌ {check_name}")
                all_good = False
        
        return all_good
    except Exception as e:
        print(f"❌ Ошибка при чтении {file_path}: {e}")
        return False

def check_css_structure(file_path):
    """Проверяет базовую структуру CSS файла."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Проверяем наличие ключевых селекторов
        selectors = [
            (r':root\s*{', 'CSS переменные (:root)'),
            (r'\.generation-type-selector', 'Селектор типа генерации'),
            (r'\.type-option', 'Опции типа генерации'),
            (r'\.action-buttons', 'Кнопки действий'),
            (r'\.btn-secondary', 'Вторичная кнопка'),
            (r'\.result-block', 'Блоки результата'),
        ]
        
        all_good = True
        for pattern, selector_name in selectors:
            if re.search(pattern, content):
                print(f"  ✅ {selector_name}")
            else:
                print(f"  ❌ {selector_name}")
                all_good = False
        
        return all_good
    except Exception as e:
        print(f"❌ Ошибка при чтении {file_path}: {e}")
        return False

def check_js_functionality(file_path):
    """Проверяет наличие ключевых JavaScript функций."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        functions = [
            ('generateMaterial', 'Функция генерации материалов'),
            ('getGeneratedContent', 'Функция получения контента'),
            ('updateGenerateButtonText', 'Обновление текста кнопки'),
            ('shareGeneratedMaterial', 'Функция поделиться'),
            ('currentGenerationType', 'Переменная типа генерации'),
        ]
        
        all_good = True
        for func_name, func_desc in functions:
            if func_name in content:
                print(f"  ✅ {func_desc}")
            else:
                print(f"  ❌ {func_desc}")
                all_good = False
        
        return all_good
    except Exception as e:
        print(f"❌ Ошибка при чтении {file_path}: {e}")
        return False

def main():
    print("🔍 Проверка изменений в ветке feature/improve-ui-generation")
    print("=" * 60)
    
    # Проверяем основные файлы
    files_to_check = [
        ('index.html', check_html_structure),
        ('web/index.html', check_html_structure),
        ('web/custom.css', check_css_structure),
    ]
    
    all_good = True
    
    for file_name, check_func in files_to_check:
        print(f"\n📄 Проверка файла: {file_name}")
        if check_file_exists(file_name):
            if not check_func(file_name):
                all_good = False
        else:
            all_good = False
    
    # Проверяем JavaScript функциональность
    print(f"\n📄 Проверка JavaScript функциональности: web/index.html")
    if check_file_exists('web/index.html'):
        if not check_js_functionality('web/index.html'):
            all_good = False
    
    # Проверяем дополнительные файлы
    print(f"\n📁 Проверка дополнительных файлов:")
    additional_files = [
        'fonts/Nunito-Regular.ttf',
        'fonts/Nunito-Bold.ttf',
        'test_generation.html',
        'test_index.html',
        'CHANGES_SUMMARY.md',
        'PR_TEMPLATE.md',
    ]
    
    for file_path in additional_files:
        if check_file_exists(file_path):
            print(f"  ✅ {file_path} - проверен")
        else:
            print(f"  ⚠️ {file_path} - отсутствует (не критично)")
    
    print("\n" + "=" * 60)
    
    if all_good:
        print("🎉 Все проверки пройдены успешно!")
        print("\n📋 Рекомендации:")
        print("1. Создать Pull Request через веб-интерфейс GitHub")
        print("2. Использовать шаблон из PR_TEMPLATE.md")
        print("3. Провести код-ревью изменений")
        print("4. Протестировать вручную через test_generation.html")
        print("5. Слить ветку после одобрения")
        return 0
    else:
        print("⚠️ Найдены проблемы! Необходимо исправить перед созданием PR.")
        return 1

if __name__ == "__main__":
    sys.exit(main())