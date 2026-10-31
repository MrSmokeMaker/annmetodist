#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Клиент для работы с нейросетью YandexGPT Pro через облачный прокси / прямое API
"""

import os
import json
import urllib.request
from pathlib import Path
from typing import Optional

# Загрузка .env если существует
env_file = Path(__file__).resolve().parent / '.env'
if env_file.exists():
    try:
        with open(env_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    k, v = line.split('=', 1)
                    os.environ.setdefault(k.strip(), v.strip())
    except Exception:
        pass

YANDEX_PROXY_URL = os.getenv('YANDEX_GPT_PROXY_URL', 'https://functions.yandexcloud.net/d4eq8r2ueghpmbl5oj3c')
YANDEX_MODEL = os.getenv('YANDEX_MODEL', 'yandexgpt')
YANDEX_FOLDER_ID = os.getenv('YANDEX_FOLDER_ID', 'b1g7jhk5r5127iikhilu')


def call_yandex_gpt(system_prompt: str, user_prompt: str, timeout: int = 25) -> Optional[str]:
    """
    Вызов нейросети YandexGPT Pro.
    Возвращает сгенерированный текст или None в случае ошибки/таймаута.
    """
    payload = {
        'model': YANDEX_MODEL,
        'messages': [
            {'role': 'system', 'content': system_prompt},
            {'role': 'user', 'content': user_prompt}
        ]
    }
    
    req_data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(
        YANDEX_PROXY_URL,
        data=req_data,
        headers={'Content-Type': 'application/json'}
    )
    
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            if resp.status == 200:
                body = json.loads(resp.read().decode('utf-8'))
                choices = body.get('choices', [])
                if choices and 'message' in choices[0]:
                    content = choices[0]['message'].get('content', '')
                    if content and content.strip():
                        return content.strip()
    except Exception as e:
        print(f"[YandexGPT Client Warning] Ошибка вызова YandexGPT ({e}), используем fallback")
    
    return None
