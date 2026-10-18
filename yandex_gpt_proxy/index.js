// yandex_gpt_proxy/index.js
// Yandex Cloud Function (Node.js) acting as a secure proxy for Yandex GPT API
// It receives POST requests from the frontend, injects the Api‑Key from an env var,
// forwards the request to https://ai.api.cloud.yandex.net/v1/chat/completions
// and returns the response with the necessary CORS headers.

const https = require('https');

/**
 * Helper to make an HTTPS request and return a Promise with {statusCode, headers, body}.
 */
function httpsRequest(options, requestBody) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        resolve({statusCode: res.statusCode, headers: res.headers, body: data});
      });
    });
    req.on('error', reject);
    if (requestBody) req.write(requestBody);
    req.end();
  });
}

exports.handler = async (event, context) => {
  const allowedOrigin = 'https://mrsmokemaker.github.io';
  const corsHeaders = {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };

  // Handle pre‑flight OPTIONS request
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 204,
      headers: corsHeaders,
      body: '',
    };
  }

  // Only accept POST
  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers: {...corsHeaders, 'Allow': 'POST, OPTIONS'},
      body: JSON.stringify({message: 'Method Not Allowed'}),
    };
  }

  // Parse incoming JSON body
  let incomingBody;
  try {
    incomingBody = JSON.parse(event.body || '{}');
  } catch (e) {
    return {
      statusCode: 400,
      headers: corsHeaders,
      body: JSON.stringify({message: 'Invalid JSON'}),
    };
  }

  const apiKey = process.env.YANDEX_API_KEY;
  if (!apiKey) {
    return {
      statusCode: 401,
      headers: corsHeaders,
      body: JSON.stringify({message: 'API key not configured on server'}),
    };
  }

  const requestOptions = {
    hostname: 'ai.api.cloud.yandex.net',
    path: '/v1/chat/completions',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Api-Key ${apiKey}`,
    },
    timeout: 30000, // 30 seconds
  };

  try {
    const {statusCode, headers, body} = await httpsRequest(requestOptions, JSON.stringify(incomingBody));
    const responseHeaders = {...corsHeaders, 'Content-Type': headers['content-type'] || 'application/json'};
    return {
      statusCode: statusCode,
      headers: responseHeaders,
      body: body,
    };
  } catch (err) {
    return {
      statusCode: 502,
      headers: corsHeaders,
      body: JSON.stringify({message: 'Proxy error', error: err.message}),
    };
  }
};
