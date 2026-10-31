FROM python:3.11-slim

WORKDIR /app

# Копируем исходный код ботов
COPY . /app/telegram_bot

WORKDIR /app/telegram_bot

# Создаем папку для персистентных данных
RUN mkdir -p /app/telegram_bot/data

ENV PYTHONUNBUFFERED=1
ENV BOT_TOKEN=8839424428:AAG2i4SC7qq6LgeQ1_mXPE4koaCGauYCJlE
ENV METODIST_AI_BOT_TOKEN=9106775452:AAHZmVZleB2jeM78FSBRuITBeHFZRFvIPI8
ENV WEB_APP_URL=https://mrsmokemaker.github.io/annmetodist/
ENV YANDEX_GPT_PROXY_URL=https://functions.yandexcloud.net/d4eq8r2ueghpmbl5oj3c
ENV YANDEX_MODEL=yandexgpt

CMD ["python", "run_all_bots.py"]
