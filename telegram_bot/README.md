# 🤖 Экосистема «Методист Pro» в Telegram

Официальный Telegram-бот и Telegram Mini App (TMA) для учителей начальных классов и администрации школ.

* **Username бота:** [@annmetodist_bot](https://t.me/annmetodist_bot)
* **Telegram Mini App URL:** `https://mrsmokemaker.github.io/annmetodist/`
* **Токен бота:** `8839424428:AAG2i4SC7qq6LgeQ1_mXPE4koaCGauYCJlE`

---

## 🌟 Возможности гибридной экосистемы

1. **Telegram Mini App (TMA)**:
   * Запуск прямо внутри Telegram по кнопке «Открыть Методист» в нижнем углу меню или через команду `/start`.
   * Адаптивный интерфейс: динамическая поддержка светлой и тёмной темы Telegram (`themeParams`).
   * Виброотклик (**Haptic Feedback**) при нажатии кнопок, переключении вкладок и завершении генерации.
   * Персонализированный статус: распознавание Telegram-аккаунта (`first_name`, `@username`, ID).

2. **Чат-бот (@annmetodist_bot)**:
   * `/start` — интерактивное приветствие с кнопками быстрого запуска Mini App.
   * `/app` — запуск приложения на весь экран.
   * `/worlds` — обзор 5 игровых миров и маскотов YandexART.
   * `/director` — привилегии и оформление тарифа «Директор» (1 199 ₽/мес).
   * `/pdf` — прямая отправка образцов готовых PDF-листов заданий в чат.
   * `/quick <тема>` — экспресс-структура урока по методике Пчёлко прямо в переписке.
   * `/help` — справочник для педагога.

---

## ⚙️ Настройка в @BotFather

Если требуется настроить или изменить кнопку меню вручную через **@BotFather**:

1. Откройте диалог с [@BotFather](https://t.me/BotFather) и введите команду:
   ```text
   /setmenubutton
   ```
2. Выберите бота: `@annmetodist_bot`
3. Отправьте URL приложения:
   ```text
   https://mrsmokemaker.github.io/annmetodist/
   ```
4. Введите название кнопки:
   ```text
   Открыть Методист
   ```

### Создание прямой ссылки на Mini App (`/newapp`):
1. Введите в @BotFather: `/newapp`
2. Выберите бота: `@annmetodist_bot`
3. Название: `Методист Pro`
4. Описание: `Умный ассистент учителя начальных классов на базе YandexGPT и YandexART`
5. Загрузите иконку 640x360 px (или фото логотипа).
6. URL Web App:
   ```text
   https://mrsmokemaker.github.io/annmetodist/
   ```
7. Short name: `app` (получится прямая ссылка: `t.me/annmetodist_bot/app`).

---

## 🚀 Запуск бота локально или на сервере

```bash
cd telegram_bot

# При необходимости настройте прокси (для серверов в РФ):
# export HTTPS_PROXY=http://user:pass@proxy:port

python bot.py
```
