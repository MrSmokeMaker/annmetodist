import sys
import zlib
import re

sys.stdout.reconfigure(encoding='utf-8')

with open('docs/russian_worksheet_premium.pdf', 'rb') as f:
    data = f.read()

def parse_cmap(obj_num):
    obj_pattern = rb'\b' + str(obj_num).encode() + rb'\s+0\s+obj[\s\S]*?stream\r?\n([\s\S]*?)\r?\nendstream'
    m = re.search(obj_pattern, data)
    if not m: return {}
    txt = zlib.decompress(m.group(1)).decode('latin1')
    mapping = {}
    for line in txt.splitlines():
        bf = re.match(r'<([0-9A-Fa-f]{4})>\s*<([0-9A-Fa-f]{4})>', line.strip())
        if bf:
            src = int(bf.group(1), 16)
            dst = chr(int(bf.group(2), 16))
            mapping[src] = dst
        bfr = re.match(r'<([0-9A-Fa-f]{4})>\s*<([0-9A-Fa-f]{4})>\s*<([0-9A-Fa-f]{4})>', line.strip())
        if bfr:
            start = int(bfr.group(1), 16)
            end = int(bfr.group(2), 16)
            dst_start = int(bfr.group(3), 16)
            for c in range(start, end + 1):
                mapping[c] = chr(dst_start + (c - start))
    return mapping

cmap_f5 = parse_cmap(7)
cmap_f10 = parse_cmap(12)
font_cmaps = {'F5': cmap_f5, 'F10': cmap_f10}

for m in re.finditer(rb'stream\r?\n([\s\S]*?)\r?\nendstream', data):
    raw = m.group(1)
    try:
        dec = zlib.decompress(raw)
        if b'BT' in dec:
            current_font = 'F5'
            tokens = []
            for t in re.finditer(rb'(/(F\d+)\s+[\d\.]+\s+Tf)|(\[<([0-9A-Fa-f]+)>\]TJ)|(ET)', dec):
                if t.group(2):
                    current_font = t.group(2).decode()
                elif t.group(4):
                    hex_str = t.group(4).decode()
                    cmap = font_cmaps.get(current_font, {})
                    w = []
                    for i in range(0, len(hex_str), 4):
                        code = int(hex_str[i:i+4], 16)
                        w.append(cmap.get(code, f'[?{code:04x}]'))
                    tokens.append(''.join(w))
                elif t.group(0) == b'ET':
                    tokens.append('\n')
            print(''.join(tokens))
    except Exception:
        pass
