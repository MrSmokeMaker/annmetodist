import urllib.request
import json

def test():
    proxy_url = 'https://functions.yandexcloud.net/d4eq8r2ueghpmbl5oj3c'
    payload = {
        'model': 'yandexgpt',
        'messages': [
            {
                'role': 'system',
                'content': 'Ты ведущий методист-дидакт РФ. Твоя задача — разработать концепцию новой педагогической методики и список из 5 тем уроков.'
            },
            {
                'role': 'user',
                'content': 'Придумай авторскую методику «Нейро-детектив» для изучения биологии в 6 классе (дидактические принципы, 4 этапа урока) и предложи сетку из 5 последовательных тем уроков с логической прогрессией.'
            }
        ]
    }

    req = urllib.request.Request(
        proxy_url,
        data=json.dumps(payload).encode('utf-8'),
        headers={'Content-Type': 'application/json'}
    )
    res = urllib.request.urlopen(req, timeout=30)
    data = json.loads(res.read().decode('utf-8'))
    answer = data['choices'][0]['message']['content']
    
    with open('docs/test_yandex_methodology_output.md', 'w', encoding='utf-8') as f:
        f.write(answer)
    print("SUCCESS: Length of generated methodology:", len(answer))

if __name__ == '__main__':
    test()
