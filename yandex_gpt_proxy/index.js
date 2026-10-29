// yandex_gpt_proxy/index.js
const https = require('https');

function httpsRequest(options, postData) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => resolve({ statusCode: res.statusCode, headers: res.headers, data }));
    });
    req.on('error', (err) => reject(err));
    if (postData) req.write(postData);
    req.end();
  });
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

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

  // ==========================================
  // ACTION: YandexART Image Generation
  // ==========================================
  if (bodyObj.action === 'generate_image') {
    try {
      const prompt = bodyObj.prompt || 'Детская развивающая иллюстрация';
      const aspectRatio = bodyObj.aspectRatio || { widthRatio: 1, heightRatio: 1 };
      const seed = bodyObj.seed || Math.floor(Math.random() * 1000000);

      const artPayload = JSON.stringify({
        modelUri: `art://${FOLDER_ID}/yandex-art/latest`,
        generationOptions: {
          seed: seed,
          aspectRatio: aspectRatio,
        },
        messages: [
          {
            weight: 1,
            text: prompt,
          },
        ],
      });

      const startRes = await httpsRequest(
        {
          hostname: 'llm.api.cloud.yandex.net',
          path: '/foundationModels/v1/imageGenerationAsync',
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Api-Key ${YANDEX_API_KEY}`,
            'x-folder-id': FOLDER_ID,
            'Content-Length': Buffer.byteLength(artPayload),
          },
        },
        artPayload
      );

      const startData = JSON.parse(startRes.data || '{}');
      const operationId = startData.id;

      if (!operationId) {
        return {
          statusCode: startRes.statusCode || 500,
          headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
          body: JSON.stringify({ error: startData.message || 'Failed to start image generation' }),
        };
      }

      // If client asked not to wait or timeout is low, return operationId immediately
      if (bodyObj.async === true) {
        return {
          statusCode: 200,
          headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
          body: JSON.stringify({ done: false, operationId }),
        };
      }

      // Poll operation for up to ~12 seconds (6 iterations x 2000ms)
      for (let i = 0; i < 6; i++) {
        await sleep(2000);
        const pollRes = await httpsRequest({
          hostname: 'llm.api.cloud.yandex.net',
          path: `/operations/${operationId}`,
          method: 'GET',
          headers: {
            'Authorization': `Api-Key ${YANDEX_API_KEY}`,
          },
        });

        const opData = JSON.parse(pollRes.data || '{}');
        if (opData.done) {
          const imageBase64 = opData.response && opData.response.image;
          return {
            statusCode: 200,
            headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
            body: JSON.stringify({ done: true, image: imageBase64, operationId }),
          };
        }
      }

      // If not finished in 12s, return operationId so client can poll
      return {
        statusCode: 200,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
        body: JSON.stringify({ done: false, operationId }),
      };
    } catch (err) {
      return {
        statusCode: 500,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
        body: JSON.stringify({ error: err.message }),
      };
    }
  }

  // ==========================================
  // ACTION: Poll YandexART Operation Status
  // ==========================================
  if (bodyObj.action === 'get_operation' && bodyObj.operationId) {
    try {
      const pollRes = await httpsRequest({
        hostname: 'llm.api.cloud.yandex.net',
        path: `/operations/${bodyObj.operationId}`,
        method: 'GET',
        headers: {
          'Authorization': `Api-Key ${YANDEX_API_KEY}`,
        },
      });

      const opData = JSON.parse(pollRes.data || '{}');
      if (opData.done) {
        const imageBase64 = opData.response && opData.response.image;
        return {
          statusCode: 200,
          headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
          body: JSON.stringify({ done: true, image: imageBase64, operationId: bodyObj.operationId }),
        };
      }

      return {
        statusCode: 200,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
        body: JSON.stringify({ done: false, operationId: bodyObj.operationId }),
      };
    } catch (err) {
      return {
        statusCode: 500,
        headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
        body: JSON.stringify({ error: err.message }),
      };
    }
  }

  // ==========================================
  // DEFAULT: Yandex Foundation Models OpenAI chat/completions
  // ==========================================
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
