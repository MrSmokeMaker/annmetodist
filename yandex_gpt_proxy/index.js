/**
 * Yandex Cloud Function: Прокси для Yandex Cloud AI Studio / YandexGPT API
 * Обеспечивает безопасный вызов API из браузера (CORS) без передачи API-ключа на клиент.
 * 
 * Runtime: Node.js 20
 * Точка входа: index.handler
 */

const YANDEX_API_URL = 'https://ai.api.cloud.yandex.net/v1/chat/completions';

module.exports.handler = async function (event, context) {
  const httpMethod = (event.httpMethod || event.requestContext?.http?.method || 'GET').toUpperCase();
  const origin = event.headers?.origin || event.headers?.Origin || '';

  // Разрешаем запросы с GitHub Pages и локальной разработки
  let allowOrigin = 'https://mrsmokemaker.github.io';
  if (
    origin === 'https://mrsmokemaker.github.io' ||
    origin.startsWith('http://localhost') ||
    origin.startsWith('http://127.0.0.1')
  ) {
    allowOrigin = origin;
  }

  const corsHeaders = {
    'Access-Control-Allow-Origin': allowOrigin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-folder-id',
    'Access-Control-Max-Age': '86400',
  };

  // 1. Preflight CORS OPTIONS запрос
  if (httpMethod === 'OPTIONS') {
    return {
      statusCode: 204,
      headers: corsHeaders,
      body: '',
    };
  }

  // Принимаем только POST запросы
  if (httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ error: { message: 'Метод не поддерживается. Используйте POST.', code: 405 } }),
    };
  }

  // 2. Проверка наличия API-ключа в переменных окружения
  const apiKey = process.env.YANDEX_API_KEY;
  if (!apiKey || apiKey.trim() === '') {
    return {
      statusCode: 401,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        error: {
          message: 'Неверный API-ключ или ключ не задан в переменных окружения прокси (YANDEX_API_KEY).',
          code: 401,
        },
      }),
    };
  }

  // 3. Разбор входящего тела запроса
  let bodyObj = {};
  try {
    let bodyText = event.body;
    if (event.isBase64Encoded && typeof bodyText === 'string') {
      bodyText = Buffer.from(bodyText, 'base64').toString('utf8');
    }
    if (typeof bodyText === 'string' && bodyText.trim().length > 0) {
      bodyObj = JSON.parse(bodyText);
    } else if (typeof bodyText === 'object' && bodyText !== null) {
      bodyObj = bodyText;
    }
  } catch (err) {
    return {
      statusCode: 400,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        error: {
          message: `Некорректный JSON в теле запроса: ${err.message}`,
          code: 400,
        },
      }),
    };
  }

  // 4. Подготовка заголовков и тела для Yandex Cloud AI Studio
  const folderId = process.env.YANDEX_FOLDER_ID;
  const forwardHeaders = {
    'Content-Type': 'application/json',
    'Authorization': `Api-Key ${apiKey.trim()}`,
  };

  if (folderId && folderId.trim() !== '') {
    forwardHeaders['x-folder-id'] = folderId.trim();

    // Если модель указана без префикса gpt://<folderId>/
    const model = bodyObj.model || 'yandexgpt-lite';
    if (!model.startsWith('gpt://')) {
      bodyObj.model = `gpt://${folderId.trim()}/${model}`;
    }
  } else if (!bodyObj.model) {
    bodyObj.model = 'yandexgpt-lite';
  }

  // 5. Пересылка запроса на https://ai.api.cloud.yandex.net/v1/chat/completions
  try {
    const apiResponse = await fetch(YANDEX_API_URL, {
      method: 'POST',
      headers: forwardHeaders,
      body: JSON.stringify(bodyObj),
    });

    const responseText = await apiResponse.text();

    return {
      statusCode: apiResponse.status,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
      body: responseText,
    };
  } catch (fetchErr) {
    return {
      statusCode: 502,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        error: {
          message: `Ошибка при пересылке запроса в Yandex AI Studio: ${fetchErr.message}`,
          code: 502,
        },
      }),
    };
  }
};
