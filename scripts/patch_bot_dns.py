import os

for filename in ['telegram_bot/metodist_ai_bot.py', 'telegram_bot/bot.py']:
    if not os.path.exists(filename):
        continue
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add DNS patch if not present
    if '_patched_getaddrinfo' not in content:
        insert_marker = 'import urllib.parse\n'
        if insert_marker not in content:
            insert_marker = 'import urllib.request\n'

        dns_code = """import socket

# Safe encoding on Windows console
try:
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    if hasattr(sys.stderr, 'reconfigure'):
        sys.stderr.reconfigure(encoding='utf-8', errors='replace')
except Exception:
    pass

# Patch DNS for Telegram API to bypass ISP blocks on 149.154.166.110
_orig_getaddrinfo = socket.getaddrinfo
def _patched_getaddrinfo(host, port, *args, **kwargs):
    if host == 'api.telegram.org':
        return [(socket.AF_INET, socket.SOCK_STREAM, 6, '', ('149.154.167.220', port))]
    return _orig_getaddrinfo(host, port, *args, **kwargs)
socket.getaddrinfo = _patched_getaddrinfo
"""
        content = content.replace(insert_marker, insert_marker + dns_code)

    # Exclude AG_LS_PROXY
    content = content.replace(
        "PROXY = os.getenv('HTTPS_PROXY') or os.getenv('HTTP_PROXY') or os.getenv('AG_LS_PROXY')",
        "PROXY = os.getenv('HTTPS_PROXY') or os.getenv('HTTP_PROXY')"
    )

    with open(filename, 'w', encoding='utf-8', newline='\n') as f:
        f.write(content)
    print(f"Patched {filename} successfully")
