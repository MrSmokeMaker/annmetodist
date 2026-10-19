// yandex_gpt_proxy/index.js
const https = require('https');

exports.handler = async (event, context) => {
  const YANDEX_API_KEY = process.env.YANDEX_API_KEY;
  const FOLDER_ID = process.env.YANDEX_FOLDER_ID;

  // Support both production domain and local/staging origins
  const origin = (event.headers && (event.headers.origin || event.headers.Origin)) || '*';
  const CORS_HEADERS = {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-folder-id',
  };

  // Preflight OPTIONS
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 204,
      headers: CORS_HEADERS,
      body: '',
    };
  }

  // Parse incoming body
  let rawBody = '';
  if (event.isBase64Encoded) {
    rawBody = Buffer.from(event.body || '', 'base64').toString('utf-8');
  } else if (typeof event.body === 'string') {
    rawBody = event.body;
  } else if (event.body) {
    rawBody = JSON.stringify(event.body);
  }

  let bodyObj = {};
  try {
    bodyObj = rawBody ? JSON.parse(rawBody) : {};
  } catch (err) {
    bodyObj = {};
  }

  // Ensure model parameter is valid for Yandex Foundation Models OpenAI API
  if (!bodyObj.model) {
    bodyObj.model = `gpt://${FOLDER_ID}/yandexgpt-lite`;
  } else if (!bodyObj.model.startsWith('gpt://')) {
    bodyObj.model = `gpt://${FOLDER_ID}/${bodyObj.model}`;
  }

  const payload = JSON.stringify(bodyObj);
  const payloadBuffer = Buffer.from(payload, 'utf-8');

  const requestOptions = {
    hostname: 'ai.api.cloud.yandex.net',
    path: '/v1/chat/completions',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Api-Key ${YANDEX_API_KEY}`,
      'x-folder-id': FOLDER_ID,
      'Content-Length': payloadBuffer.length,
    },
  };

  return new Promise((resolve) => {
    const req = https.request(requestOptions, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: {
            ...CORS_HEADERS,
            'Content-Type': 'application/json',
          },
          body: data,
        });
      });
    });

    req.on('error', (e) => {
      resolve({
        statusCode: 502,
        headers: {
          ...CORS_HEADERS,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ error: e.message }),
      });
    });

    req.write(payloadBuffer);
    req.end();
  });
};
