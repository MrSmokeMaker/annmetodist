FROM python:3.11-slim

WORKDIR /app

# Копируем исходный код бота
COPY . /app/telegram_bot

WORKDIR /app/telegram_bot

# Создаем папку для персистентных данных
RUN mkdir -p /app/telegram_bot/data

ENV PYTHONUNBUFFERED=1
ENV METODIST_AI_BOT_TOKEN=9106775452:AAHZmVZleB2jeM78FSBRuITBeHFZRFvIPI8
ENV WEB_APP_URL=https://mrsmokemaker.github.io/annmetodist/

CMD ["python", "metodist_ai_bot.py"]
