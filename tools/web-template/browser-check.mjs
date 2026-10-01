// Bounded CDP verification of the actual release Wasm, in a disposable Chrome profile.
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { mkdtemp, readFile, writeFile, mkdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve, join, extname, sep } from 'node:path';
import { parseArgs } from 'node:util';

const usage = `usage: node tools/web-template/browser-check.mjs --export DIR --output DIR --browser FILE [--help|-h]
Requires Node 22 and Chrome/Chromium. Exercises title/play, save/reload, later days and escape.
The output directory must not exist; logs/screenshots/results go there, never into the game.
Example: node tools/web-template/browser-check.mjs --export build/web --output /tmp/web-check --browser /usr/bin/google-chrome
`;
let options;
try {
  options = parseArgs({ options: {
    export: { type: 'string' }, output: { type: 'string' }, browser: { type: 'string' },
    help: { type: 'boolean', short: 'h' },
  } }).values;
  if (options.help) { process.stdout.write(usage); process.exit(0); }
  assert(options.export && options.output && options.browser);
} catch { process.stderr.write(usage); process.exit(2); }
assert(Number(process.versions.node.split('.')[0]) >= 22, 'Node 22 or newer required');
const root = resolve(options.export);
const output = resolve(options.output);
await mkdir(output);
const profile = await mkdtemp(join(tmpdir(), 'nappy-web-check-'));
const logs = [];
const errors = [];
const results = [];
const pause = ms => new Promise(r => setTimeout(r, ms));
const until = async (predicate, label, milliseconds = 120000) => {
  const deadline = Date.now() + milliseconds;
  while (Date.now() < deadline) {
    const result = await predicate();
    if (result) return result;
    await pause(200);
  }
  throw new Error(`Timed out: ${label}`);
};
const server = createServer(async (req, res) => {
  try {
    const path = resolve(root, '.' + new URL(req.url, 'http://localhost').pathname);
    assert(path === root || path.startsWith(root + sep));
    const file = path === root ? join(root, 'index.html') : path;
    const body = await readFile(file);
    res.setHeader('Content-Type', ({ '.html': 'text/html', '.js': 'application/javascript', '.wasm': 'application/wasm' })[extname(file)] || 'application/octet-stream');
    res.end(body);
  } catch { res.writeHead(404); res.end(); }
});
await new Promise(r => server.listen(0, '127.0.0.1', r));
const url = `http://127.0.0.1:${server.address().port}`;
const browser = spawn(options.browser, [
  '--headless=new', '--no-sandbox', '--disable-dev-shm-usage', '--enable-unsafe-swiftshader',
  '--use-angle=swiftshader', '--disable-background-timer-throttling',
  '--disable-renderer-backgrounding', '--disable-backgrounding-occluded-windows',
  '--remote-debugging-port=0', `--user-data-dir=${profile}`, '--no-first-run', 'about:blank',
], { stdio: ['ignore', 'ignore', 'pipe'] });
let browserLog = '';
browser.stderr.on('data', data => { browserLog += data; });
let socket;
let sequence = 0;
const pending = new Map();
const call = (method, params = {}) => new Promise((resolveCall, reject) => {
  const id = ++sequence;
  const timer = setTimeout(() => { pending.delete(id); reject(new Error(`CDP timeout: ${method}`)); }, 30000);
  pending.set(id, { resolveCall, reject, timer });
  socket.send(JSON.stringify({ id, method, params }));
});
const evaluate = async expression => {
  const result = await call('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
  if (result.exceptionDetails) throw new Error(JSON.stringify(result.exceptionDetails));
  return result.result.value;
};
const key = async (key, code, virtualKey) => {
  await call('Input.dispatchKeyEvent', { type: 'keyDown', key, code, windowsVirtualKeyCode: virtualKey });
  await pause(100);
  await call('Input.dispatchKeyEvent', { type: 'keyUp', key, code, windowsVirtualKeyCode: virtualKey });
};
const saved = () => evaluate(`(async () => {
  const databases = await indexedDB.databases();
  if (!databases.some(db => db.name === '/userfs')) return null;
  const db = await new Promise((resolve, reject) => { const request = indexedDB.open('/userfs'); request.onsuccess = () => resolve(request.result); request.onerror = () => reject(request.error); });
  try {
    const entries = await new Promise((resolve, reject) => { const request = db.transaction('FILE_DATA', 'readonly').objectStore('FILE_DATA').getAll(); request.onsuccess = () => resolve(request.result); request.onerror = () => reject(request.error); });
    for (const entry of entries) {
      if (!entry.contents) continue;
      try { const value = JSON.parse(new TextDecoder().decode(entry.contents)); if (value.format_version && value.state) return value; } catch {}
    }
    return null;
  } finally { db.close(); }
})()`);
const snapshot = async name => {
  const capture = await call('Page.captureScreenshot');
  await writeFile(join(output, `${name}.png`), Buffer.from(capture.data, 'base64'));
};
const load = async (name, query, expected) => {
  const start = logs.length;
  await call('Page.navigate', { url: url + '/' + query });
  await until(() => logs.slice(start).some(line => line.includes(expected)), name);
  await until(() => evaluate(`!document.getElementById('status')`), `${name} splash hidden`);
  await pause(1500);
  await snapshot(name);
  results.push({ name, expected, boot: logs.slice(start).filter(line => line.includes('[Main]')) });
};
let success = false;
try {
  const port = await until(async () => {
    try { return (await readFile(join(profile, 'DevToolsActivePort'), 'utf8')).split('\n')[0]; } catch { return false; }
  }, 'Chrome CDP port', 20000);
  const target = await (await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, { method: 'PUT' })).json();
  socket = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((r, reject) => { socket.onopen = r; socket.onerror = reject; });
  socket.onmessage = event => {
    const message = JSON.parse(event.data);
    if (message.id) {
      const waiter = pending.get(message.id);
      if (!waiter) return;
      pending.delete(message.id); clearTimeout(waiter.timer);
      if (message.error) waiter.reject(new Error(JSON.stringify(message.error)));
      else waiter.resolveCall(message.result);
    } else if (message.method === 'Runtime.consoleAPICalled') {
      const line = message.params.args.map(arg => arg.value ?? arg.description ?? '').join(' ');
      logs.push(line);
      if (/SCRIPT ERROR|Parse Error|ERROR:/.test(line)) errors.push(line);
      process.stdout.write(line + '\n');
    } else if (message.method === 'Runtime.exceptionThrown') {
      errors.push(JSON.stringify(message.params.exceptionDetails));
    }
  };
  await call('Runtime.enable'); await call('Page.enable');
  await call('Network.enable');
  // No external analytics or third-party fetch is part of the test.
  await call('Network.setBlockedURLs', { urls: ['https://gc.zgo.at/*', 'https://*.goatcounter.com/*'] });
  await call('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });
  const version = await call('Browser.getVersion');
  results.push({ browser: version.product, userAgent: version.userAgent });
  await load('title', '?debug=1', '[Main] day 1 started');
  await key(' ', 'Space', 32);
  const firstSave = await until(saved, 'persisted day save');
  assert.equal(firstSave.day_under_way, true);
  await call('Input.dispatchKeyEvent', { type: 'keyDown', key: 'ArrowDown', code: 'ArrowDown', windowsVirtualKeyCode: 40 });
  await pause(2000);
  await call('Input.dispatchKeyEvent', { type: 'keyUp', key: 'ArrowDown', code: 'ArrowDown', windowsVirtualKeyCode: 40 });
  await snapshot('walking');
  await load('resume', '?debug=1', '[Main] day 1 started');
  const resumedSave = await until(async () => { const value = await saved(); return value && !value.day_under_way ? value : null; }, 'resumed dawn persisted');
  assert.equal(typeof firstSave.state.run_seed, 'number');
  assert.equal(resumedSave.state.run_seed, firstSave.state.run_seed);
  assert.equal(resumedSave.state.nerves, firstSave.state.nerves - 1);
  results.push({ save: { first: firstSave, resumed: resumedSave } });
  for (const day of [8, 14]) await load(`day-${day}`, `?debug=1&seed=4242&day=${day}`, `[Main] day ${day} started`);
  await load('escape', '?debug=1&seed=4242&escape=1', 'atlas pages held from escape');
  assert.deepEqual(errors, [], 'Engine/browser errors');
  success = true;
} finally {
  await writeFile(join(output, 'result.json'), JSON.stringify({ success, results, errors }, null, 2) + '\n');
  await writeFile(join(output, 'console.log'), logs.join('\n'));
  await writeFile(join(output, 'browser.log'), browserLog);
  socket?.close();
  browser.kill('SIGKILL');
  for (const waiter of pending.values()) clearTimeout(waiter.timer);
  server.closeAllConnections(); server.close();
  await pause(300);
  await rm(profile, { recursive: true, force: true });
}
