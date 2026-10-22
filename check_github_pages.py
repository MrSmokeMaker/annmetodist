#!/usr/bin/env python3
"""
Проверка доступности ресурсов на GitHub Pages после обновления путей.
"""

import requests
import time

BASE_URL = "https://mrsmokemaker.github.io/annmetodist/"
RESOURCES = [
    "index.html",
    "manifest.json",
    "flutter_bootstrap.js",
    "Nunito-Regular.ttf",
    "Nunito-Bold.ttf",
    "favicon.png",
    "icons/Icon-192.png",
]

def check_resource(resource):
    url = BASE_URL + resource
    try:
        response = requests.head(url, timeout=10)
        if response.status_code == 200:
            return f"✅ {url} - доступен ({response.status_code})"
        else:
            return f"❌ {url} - ошибка ({response.status_code})"
    except requests.exceptions.RequestException as e:
        return f"❌ {url} - ошибка сети: {e}"

def main():
    print("Проверка доступности ресурсов на GitHub Pages...")
    print(f"Базовая ссылка: {BASE_URL}")
    print("-" * 80)
    
    for resource in RESOURCES:
        result = check_resource(resource)
        print(result)
        time.sleep(0.5)  # Небольшая пауза между запросами
    
    print("-" * 80)
    print("Проверка завершена.")
    
    # Дополнительная проверка HTML
    try:
        html_response = requests.get(BASE_URL + "index.html", timeout=10)
        if html_response.status_code == 200:
            html_content = html_response.text
            if '<base href="/annmetodist/">' in html_content:
                print("✅ Тег <base href=\"/annmetodist/\"> найден в index.html")
            else:
                print("⚠️  Тег <base href=\"/annmetodist/\"> НЕ найден в index.html")
                
            if 'flutter_bootstrap.js' in html_content:
                print("✅ Ссылка на flutter_bootstrap.js найдена")
            else:
                print("⚠️  Ссылка на flutter_bootstrap.js НЕ найдена")
    except Exception as e:
        print(f"❌ Ошибка при проверке HTML: {e}")

if __name__ == "__main__":
    main()