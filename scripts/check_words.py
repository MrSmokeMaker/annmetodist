import re

with open('scripts/create_conspect_pdf.py', 'r', encoding='utf-8') as f:
    text = f.read()

# Extract all string literals
matches = re.findall(r'"""(.*?)"""', text, re.DOTALL) + re.findall(r'\"([^\"]*?)\"', text)
combined = ' '.join(matches)
words = re.findall(r'[а-яА-ЯёЁa-zA-Z0-9]+', combined)
print('Total words in conspect script:', len(words))
