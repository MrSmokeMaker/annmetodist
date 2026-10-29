// test_headless_chrome.js
const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const PORT = 8080;
const WEB_DIR = path.join(__dirname, 'build', 'web');

const MIME_TYPES = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

// 1. Local HTTP server
const server = http.createServer((req, res) => {
  let reqPath = req.url.split('?')[0];
  if (reqPath === '/') reqPath = '/index.html';
  const filePath = path.join(WEB_DIR, reqPath);

  if (fs.existsSync(filePath) && fs.statSync(filePath).isFile()) {
    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
    res.writeHead(200, {
      'Content-Type': contentType,
      'Access-Control-Allow-Origin': '*',
    });
    fs.createReadStream(filePath).pipe(res);
  } else {
    // SPA fallback
    const indexPath = path.join(WEB_DIR, 'index.html');
    res.writeHead(200, { 'Content-Type': 'text/html' });
    fs.createReadStream(indexPath).pipe(res);
  }
});

server.listen(PORT, async () => {
  console.log(`[Local Server] Serving ${WEB_DIR} on http://localhost:${PORT}`);

  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const debugPort = 9222;

  console.log('[Headless Chrome] Launching Chrome...');
  const chromeProcess = spawn(chromePath, [
    '--headless=new',
    `--remote-debugging-port=${debugPort}`,
    '--disable-gpu',
    '--no-sandbox',
    '--disable-dev-shm-usage',
    `http://localhost:${PORT}`,
  ]);

  chromeProcess.stderr.on('data', (d) => {
    // console.log('[Chrome err]', d.toString());
  });

  // Wait 2 seconds for Chrome to start CDP
  await new Promise((r) => setTimeout(r, 2000));

  try {
    // Query CDP version
    const targetsRes = await fetch(`http://127.0.0.1:${debugPort}/json`);
    const targets = await targetsRes.json();
    console.log('[CDP] Available targets count:', targets.length);

    const pageTarget = targets.find((t) => t.type === 'page') || targets[0];
    if (!pageTarget || !pageTarget.webSocketDebuggerUrl) {
      throw new Error('No page target with WebSocket debugger URL found');
    }

    console.log('[CDP] Connecting to target:', pageTarget.title, pageTarget.webSocketDebuggerUrl);
    const ws = new WebSocket(pageTarget.webSocketDebuggerUrl);

    let msgId = 1;
    const callbacks = new Map();

    ws.onmessage = (event) => {
      const msg = JSON.parse(event.data);
      if (msg.id && callbacks.has(msg.id)) {
        callbacks.get(msg.id)(msg);
        callbacks.delete(msg.id);
      }

      if (msg.method === 'Network.responseReceived') {
        const url = msg.params.response.url;
        const status = msg.params.response.status;
        console.log(`[Network Response] ${status} ${url}`);
        if (url.includes('functions.yandexcloud.net')) {
          console.log(`>>> VERIFIED PROXY RESPONSE: Status ${status} from ${url} <<<`);
        }
      }
    };

    function sendCommand(method, params = {}) {
      return new Promise((resolve) => {
        const id = msgId++;
        callbacks.set(id, resolve);
        ws.send(JSON.stringify({ id, method, params }));
      });
    }

    await new Promise((r) => (ws.onopen = r));
    console.log('[CDP] WebSocket connected. Enabling Network & Page domains...');
    await sendCommand('Network.enable');
    await sendCommand('Page.enable');
    await sendCommand('Runtime.enable');

    // Wait 5 seconds for Flutter web app to initialize
    console.log('[Headless Chrome] Waiting for Flutter Web app to load...');
    await new Promise((r) => setTimeout(r, 5000));

    // Test proxy call directly from within the browser window context!
    console.log('[Headless Chrome] Triggering proxy request from browser context...');
    const evalResult = await sendCommand('Runtime.evaluate', {
      expression: `
        (async () => {
          const res = await window.fetch('https://functions.yandexcloud.net/d4eq8r2ueghpmbl5oj3c', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              messages: [
                { role: 'user', content: 'Привет из Headless Chrome! Составь конспект занятия по математике на 30 слов.' }
              ]
            })
          });
          const json = await res.json();
          return { status: res.status, json: json };
        })()
      `,
      awaitPromise: true,
      returnByValue: true,
    });

    const evalVal = evalResult.result?.result?.value || evalResult.result?.value;
    console.log('[Headless Chrome] Evaluation result:', JSON.stringify(evalVal, null, 2));

    const status = evalVal?.status;
    const model = evalVal?.json?.model;
    const content = evalVal?.json?.choices?.[0]?.message?.content;

    console.log('\n========================================');
    console.log(`HEADLESS CHROME TEST SUMMARY:`);
    console.log(`HTTP Status: ${status}`);
    console.log(`Model: ${model}`);
    console.log(`Content: ${content}`);
    console.log('========================================\n');

    if (status === 200) {
      console.log('SUCCESS: Headless Chrome received 200 OK from the deployed Yandex Cloud Function proxy!');
    } else {
      console.error('FAILURE: Unexpected status', status);
      process.exitCode = 1;
    }

    ws.close();
  } catch (err) {
    console.error('Headless Chrome Test Error:', err);
    process.exitCode = 1;
  } finally {
    chromeProcess.kill();
    server.close();
  }
});
