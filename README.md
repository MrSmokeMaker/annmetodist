# Metodist Flutter App

Это приложение на Flutter генерирует конспекты с помощью YandexGPT (OpenAI‑совместимый эндпоинт). 

## Основные возможности
- Управление состоянием через **Provider**.
- Локальное хранение данных с помощью **Hive**.
- Хранение секретов (API‑ключ, folder_id) в **flutter_secure_storage**.
- Запросы к API реализованы в `YandexGptService` с поддержкой как OpenAI‑совместимого, так и нативного эндпоинтов.
- Защита от вызовов `dart:io` на веб‑платформе через проверку `kIsWeb`.

## Структура проекта
```
lib/
  ├─ providers/        # Provider‑ы
  ├─ services/         # Сервис YandexGPT и StorageService
  ├─ ui/               # UI‑страницы (Home, Settings и т.д.)
pubspec.yaml           # Зависимости
README.md              # Этот файл
```

## Сборка и запуск
```bash
# Установить зависимости
flutter pub get

# Запустить на Windows (пример)
flutter run -d windows
```

## Настройка GitHub Pages
Для размещения документации можно использовать ветку `gh-pages`. После пуша ветки в репозиторий включите GitHub Pages в настройках репозитория, выбрав источник `gh-pages`.

---
*Проект создан и настроен автоматически с учётом рекомендаций по работе с `Platform` и `dart:io`.*
