// Bounded CDP verification of the actual release Wasm, in a disposable Chrome profile.
// The browser is closed through CDP and waited for, so it removes its own scratch; what it still
// leaves is settled by browser-scratch.mjs and reported in scratch.json beside the results.
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { constants } from 'node:fs';
import { access, mkdtemp, readFile, writeFile, mkdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve, join, extname, sep } from 'node:path';
import { parseArgs } from 'node:util';
import { BrowserScratch, cloneRoot } from './browser-scratch.mjs';

const usage = `usage: node tools/web-template/browser-check.mjs --export DIR --output DIR --browser FILE [--help|-h]
Requires Node 22 and Chrome/Chromium. Exercises title/play, save/reload, later days and escape.
The output directory must not exist; logs/screenshots/results go there, never into the game.
The browser runs in a temporary profile that is removed afterwards; it is closed through CDP
and waited for, and scratch.json reports any browser scratch it removed, kept or could not attribute.
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
let profile;
let browser;
let browserExit;
let exited = false;
const scratch = new BrowserScratch({ root: await cloneRoot() });
await scratch.begin();
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
let url;
let browserLog = '';
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
let failure = null;
let observer;
let observing = null;
const waitExit = milliseconds => Promise.race([browserExit.then(() => true), pause(milliseconds).then(() => false)]);
// Closing through CDP lets the browser remove its own scratch; a signal is the fallback.
const stopBrowser = async () => {
  if (!browser?.pid || exited) return browser ? 'exited' : 'not started';
  await observing;
  await scratch.observe(browser.pid);
  if (socket?.readyState === WebSocket.OPEN) {
    await Promise.race([call('Browser.close').catch(() => {}), pause(3000)]);
    if (await waitExit(10000)) return 'closed';
  }
  browser.kill('SIGTERM');
  if (await waitExit(5000)) return 'terminated';
  browser.kill('SIGKILL');
  await waitExit(5000);
  return exited ? 'killed' : 'still running after SIGKILL';
};
try {
  await access(options.browser, constants.X_OK);
  profile = await mkdtemp(join(tmpdir(), 'nappy-web-check-'));
  await new Promise((r, reject) => { server.once('error', reject); server.listen(0, '127.0.0.1', r); });
  url = `http://127.0.0.1:${server.address().port}`;
  await new Promise((r, reject) => {
    // MacAppCodeSignClone is macOS Chrome's copy of its own bundle, about 2 GiB allocated per
    // launch; disabled, none is made. Other platforms ignore the unknown feature name.
    browser = spawn(options.browser, [
      '--headless=new', '--no-sandbox', '--disable-dev-shm-usage', '--enable-unsafe-swiftshader',
      '--use-angle=swiftshader', '--disable-background-timer-throttling',
      '--disable-renderer-backgrounding', '--disable-backgrounding-occluded-windows',
      '--disable-features=MacAppCodeSignClone',
      '--remote-debugging-port=0', `--user-data-dir=${profile}`, '--no-first-run', 'about:blank',
    ], { stdio: ['ignore', 'ignore', 'pipe'] });
    browserExit = new Promise(r => {
      browser.once('exit', () => { exited = true; r(); });
      browser.once('error', () => { if (!browser.pid) { exited = true; r(); } });
    });
    browser.once('error', reject);
    browser.once('spawn', r);
    browser.stderr.on('data', data => { browserLog += data; });
  });
  observer = setInterval(() => {
    if (observing || exited) return;
    observing = scratch.observe(browser.pid).finally(() => { observing = null; });
  }, 2000);
  const port = await until(async () => {
    assert(browser.exitCode === null && browser.signalCode === null, 'Chrome exited before CDP startup');
    try { return (await readFile(join(profile, 'DevToolsActivePort'), 'utf8')).split('\n')[0]; } catch { return false; }
  }, 'Chrome CDP port', 20000);
  const response = await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, { method: 'PUT', signal: AbortSignal.timeout(10000) });
  assert(response.ok, 'Chrome CDP target request failed');
  const target = await response.json();
  socket = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((r, reject) => {
    const timer = setTimeout(() => reject(new Error('Chrome CDP socket startup timed out')), 10000);
    socket.onopen = () => { clearTimeout(timer); r(); };
    socket.onerror = () => { clearTimeout(timer); reject(new Error('Chrome CDP socket startup failed')); };
  });
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
  await load('transition-setup', '?debug=1&seed=4242&meters=99.9,0', '[Main] day 1 started');
  const transitionStart = logs.length;
  // A nearly settled baby makes the real walk home and summary bounded. The game still
  // handles movement, sleep, the win and next-day construction through ordinary input.
  await call('Input.dispatchKeyEvent', { type: 'keyDown', key: 'ArrowDown', code: 'ArrowDown', windowsVirtualKeyCode: 40 });
  await pause(1500);
  await call('Input.dispatchKeyEvent', { type: 'keyUp', key: 'ArrowDown', code: 'ArrowDown', windowsVirtualKeyCode: 40 });
  await call('Input.dispatchKeyEvent', { type: 'keyDown', key: 'ArrowUp', code: 'ArrowUp', windowsVirtualKeyCode: 38 });
  await pause(2000);
  await call('Input.dispatchKeyEvent', { type: 'keyUp', key: 'ArrowUp', code: 'ArrowUp', windowsVirtualKeyCode: 38 });
  await snapshot('day-summary');
  await key(' ', 'Space', 32);
  await until(() => logs.slice(transitionStart).some(line => line.includes('[Main] day 2 started')), 'summary to day 2');
  await snapshot('day-2');
  results.push({ name: 'summary-to-day-2', boot: logs.slice(transitionStart).filter(line => line.includes('[Main]')) });
  for (const day of [8, 14]) await load(`day-${day}`, `?debug=1&seed=4242&day=${day}`, `[Main] day ${day} started`);
  await load('escape', '?debug=1&seed=4242&escape=1', 'atlas pages held from escape');
  assert.deepEqual(errors, [], 'Engine/browser errors');
  success = true;
} catch (error) {
  failure = error.stack || String(error);
  throw error;
} finally {
  // Stop processes even if the output filesystem refuses an artifact write.
  clearInterval(observer);
  let shutdown;
  try { shutdown = await stopBrowser(); } catch (error) { shutdown = `failed: ${error.message}`; }
  try { socket?.close(); } catch {}
  for (const waiter of pending.values()) clearTimeout(waiter.timer);
  server.closeAllConnections(); server.close();
  let scratchReport = { shutdown, settled: 'browser never started' };
  try {
    if (profile) {
      await pause(300);
      await rm(profile, { recursive: true, force: true, maxRetries: 3, retryDelay: 200 });
    }
  } finally {
    if (browser?.pid && exited) scratchReport = { shutdown, ...await scratch.settle() };
    else if (browser?.pid) scratchReport = { shutdown, settled: 'browser still running; nothing touched' };
    for (const { path, reason } of scratchReport.retained || []) process.stderr.write(`Browser scratch kept: ${path} (${reason})\n`);
    for (const { path, missing } of scratchReport.candidates || []) process.stderr.write(`Browser scratch not attributed: ${path} (${missing})\n`);
    for (const { path } of scratchReport.removed || []) process.stderr.write(`Browser scratch removed: ${path}\n`);
    const writes = await Promise.allSettled([
      writeFile(join(output, 'result.json'), JSON.stringify({ success, results, errors, failure }, null, 2) + '\n'),
      writeFile(join(output, 'console.log'), logs.join('\n')),
      writeFile(join(output, 'browser.log'), browserLog),
      writeFile(join(output, 'scratch.json'), JSON.stringify(scratchReport, null, 2) + '\n'),
    ]);
    for (const result of writes) if (result.status === 'rejected') {
      process.stderr.write(`Cannot write browser evidence: ${result.reason}\n`);
      process.exitCode = 1;
    }
  }
}
