import json
import os
import re
import sys
import subprocess
from datetime import datetime

MONTHS_RU = {
    1: 'января', 2: 'февраля', 3: 'марта', 4: 'апреля',
    5: 'мая', 6: 'июня', 7: 'июля', 8: 'августа',
    9: 'сентября', 10: 'октября', 11: 'ноября', 12: 'декабря'
}

def get_today_ru(dt=None):
    if dt is None:
        dt = datetime.now()
    return f"{dt.day} {MONTHS_RU[dt.month]} {dt.year}"

def get_pubspec_version(pubspec_path='pubspec.yaml'):
    with open(pubspec_path, 'r', encoding='utf-8') as f:
        content = f.read()
    m = re.search(r'^version:\s*([0-9]+)\.([0-9]+)\.([0-9]+)(?:\+([0-9]+))?', content, re.MULTILINE)
    if not m:
        raise ValueError("Could not find version in pubspec.yaml")
    major, minor, patch = int(m.group(1)), int(m.group(2)), int(m.group(3))
    build = int(m.group(4)) if m.group(4) else 1
    return major, minor, patch, build

def bump_pubspec_version(part='patch', pubspec_path='pubspec.yaml'):
    major, minor, patch, build = get_pubspec_version(pubspec_path)
    if part == 'major':
        major += 1
        minor = 0
        patch = 0
    elif part == 'minor':
        minor += 1
        patch = 0
    else: # patch
        patch += 1
    build += 1

    new_ver_clean = f"{major}.{minor}.{patch}"
    new_ver_full = f"{new_ver_clean}+{build}"

    with open(pubspec_path, 'r', encoding='utf-8') as f:
        content = f.read()

    content = re.sub(
        r'^version:\s*.*$',
        f'version: {new_ver_full}',
        content,
        flags=re.MULTILINE
    )

    with open(pubspec_path, 'w', encoding='utf-8', newline='') as f:
        f.write(content)

    return new_ver_clean, new_ver_full

def update_news_json(version, title, badge, highlights, news_path='assets/news.json', date_str=None):
    if date_str is None:
        date_str = get_today_ru()

    today_iso = datetime.now().strftime('%Y-%m-%d')
    v_tag = f"v{version.lstrip('v')}"

    with open(news_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    releases = data.get('releases', [])

    # Check if this version already exists
    existing_index = -1
    for i, r in enumerate(releases):
        if r.get('version') == v_tag:
            existing_index = i
            break

    new_entry = {
        "version": v_tag,
        "date": date_str,
        "title": title,
        "badge": badge,
        "highlights": highlights
    }

    if existing_index >= 0:
        releases[existing_index] = new_entry
    else:
        releases.insert(0, new_entry)

    data['currentVersion'] = v_tag
    data['updatedAt'] = today_iso
    data['releases'] = releases

    with open(news_path, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')

    print(f"Updated {news_path} to {v_tag} ({date_str}): {title}")
    return v_tag

def auto_from_git():
    # Check staged files
    try:
        diff_proc = subprocess.run(['git', 'diff', '--cached', '--name-only'], capture_output=True, text=True, check=True)
        staged_files = [f.strip() for f in diff_proc.stdout.splitlines() if f.strip()]
    except Exception:
        staged_files = []

    if not staged_files:
        print("No staged files found. Nothing to auto-bump.")
        return

    # If pubspec.yaml or assets/news.json are ALREADY explicitly staged, check if version changed
    with open('assets/news.json', 'r', encoding='utf-8') as f:
        news_data = json.load(f)
    major, minor, patch, build = get_pubspec_version()
    current_pub_v = f"v{major}.{minor}.{patch}"

    if news_data.get('currentVersion') != current_pub_v:
        # Update news.json to match pubspec version
        news_data['currentVersion'] = current_pub_v
        with open('assets/news.json', 'w', encoding='utf-8', newline='\n') as f:
            json.dump(news_data, f, ensure_ascii=False, indent=2)
            f.write('\n')
        subprocess.run(['git', 'add', 'assets/news.json'])
        print(f"Synced news.json version to {current_pub_v}")
        return

    # If news.json is not modified in this commit, auto-generate a patch entry
    if 'assets/news.json' not in staged_files:
        print("Auto-bumping version and appending news entry from git changes...")
        new_clean, new_full = bump_pubspec_version('patch')

        # Gather context from changed files
        highlights = []
        for file in staged_files:
            if 'pdf' in file.lower():
                highlights.append("Улучшение генератора и верстки PDF-материалов")
            elif 'screen' in file.lower() or 'widget' in file.lower():
                highlights.append(f"Обновление интерфейса: {os.path.basename(file)}")
            elif 'prompt' in file.lower() or 'ai' in file.lower() or 'gpt' in file.lower():
                highlights.append("Оптимизация педагогических промптов и алгоритмов ИИ")
            elif 'method' in file.lower() or 'topic' in file.lower():
                highlights.append("Актуализация методических данных и учебных тем")

        if not highlights:
            highlights = ["Плановое обновление стабильности и быстродействия приложения."]
        else:
            highlights = list(dict.fromkeys(highlights))[:5]

        title = f"Обновление компонентов: {', '.join([os.path.basename(f) for f in staged_files[:3]])}"
        badge = "Обновление"

        update_news_json(new_clean, title, badge, highlights)
        subprocess.run(['git', 'add', 'pubspec.yaml', 'assets/news.json'])
        print(f"Auto-bumped to {new_full} and added news entry.")

if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == '--from-git':
        auto_from_git()
    elif len(sys.argv) > 1 and sys.argv[1] == '--bump':
        part = sys.argv[2] if len(sys.argv) > 2 else 'patch'
        new_clean, new_full = bump_pubspec_version(part)
        print(f"Bumped pubspec version to {new_full}")
    elif len(sys.argv) > 1 and sys.argv[1] == '--manual':
        # Used for manual release insertion
        # argv: --manual <version> <title> <badge> <h1|h2|h3>
        ver = sys.argv[2]
        title = sys.argv[3]
        badge = sys.argv[4]
        highlights = sys.argv[5].split('|')
        update_news_json(ver, title, badge, highlights)
    else:
        print("Usage:")
        print("  python scripts/bump_version_and_news.py --from-git")
        print("  python scripts/bump_version_and_news.py --bump [patch|minor|major]")
        print("  python scripts/bump_version_and_news.py --manual <version> <title> <badge> <h1|h2|...>")
