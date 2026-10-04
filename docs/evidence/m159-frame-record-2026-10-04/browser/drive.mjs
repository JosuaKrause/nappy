// Drives the frame record's page path in headless desktop Chrome against a release Web export,
// in a fresh temporary profile on its own port, and writes what it saw into --output.
//
// The checks, in order (each one is a named entry in result.json):
//   1. ?debug=1&framerecord=1&seed=67: the page's "save frames" button shows, once, at the top
//      of the page, just right of the day's clock; the day is started and walked; a click on the
//      button downloads a JSON file that parses, whose every row's buckets add up to its frame, with the browser's user agent and
//      the page clock's step in its environment; focus goes back to the canvas and the keyboard
//      still steers (a second download's newest row has her somewhere else); the readout's
//      `slow` line is photographed beside the button.
//   2. A restart (Esc, then R: the pause screen's `_restart_run()`, the same function the held
//      restart reaches) leaves exactly one button, shown, and a click on it still downloads.
//   3. ?debug=1&seed=67 alone, and ?framerecord=1&seed=67 without ?debug=1: no button.
//   4. The record's page at a phone's size (844x390 CSS pixels, touch), photographed for the
//      button's place beside the clock, the readout and the pause button.
//   5. No save was written in the profile (every page carries a dev flag), and no engine or page
//      error was logged.
//
// It reuses the bounded-CDP and browser-scratch machinery of tools/web-template/browser-check.mjs.
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { constants } from 'node:fs';
import { access, mkdtemp, readFile, readdir, writeFile, mkdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve, join, extname, sep } from 'node:path';
import { parseArgs } from 'node:util';
import { BrowserScratch, cloneRoot } from '../../../../tools/web-template/browser-scratch.mjs';

const usage = `usage: node drive.mjs --export DIR --output DIR --browser FILE [--help|-h]
Drives the frame record's page path (M159) in headless Chrome against a release Web export.
The output directory must not exist; downloads, screenshots, the console log and result.json go
there. The browser runs in a temporary profile on its own port and is closed through CDP.
Example: node drive.mjs --export build/web --output /tmp/m159-browser \\
  --browser "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
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
const downloads = join(output, 'downloads');
await mkdir(output);
await mkdir(downloads);
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
const keyDown = (key, code, virtualKey) =>
  call('Input.dispatchKeyEvent', { type: 'keyDown', key, code, windowsVirtualKeyCode: virtualKey });
const keyUp = (key, code, virtualKey) =>
  call('Input.dispatchKeyEvent', { type: 'keyUp', key, code, windowsVirtualKeyCode: virtualKey });
const key = async (key, code, virtualKey) => {
  await keyDown(key, code, virtualKey);
  await pause(100);
  await keyUp(key, code, virtualKey);
};
const hold = async (key, code, virtualKey, milliseconds) => {
  await keyDown(key, code, virtualKey);
  await pause(milliseconds);
  await keyUp(key, code, virtualKey);
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
const button = () => evaluate(`(() => {
  const all = document.querySelectorAll('#nappy-frame-record');
  const shown = all[0];
  if (!shown) return { count: 0 };
  const rect = shown.getBoundingClientRect();
  return { count: all.length, text: shown.textContent, display: getComputedStyle(shown).display,
    x: rect.x, y: rect.y, width: rect.width, height: rect.height, viewport: innerWidth };
})()`);
const snapshot = async (name, clip) => {
  const capture = await call('Page.captureScreenshot', clip ? { clip: { ...clip, scale: 1 } } : {});
  await writeFile(join(output, `${name}.png`), Buffer.from(capture.data, 'base64'));
};
const load = async (name, query, expected) => {
  const start = logs.length;
  await call('Page.navigate', { url: url + '/' + query });
  await until(() => logs.slice(start).some(line => line.includes(expected)), name);
  await until(() => evaluate(`!document.getElementById('status')`), `${name} splash hidden`);
  await pause(1500);
  return logs.slice(start).filter(line => line.includes('[Main]'));
};
const downloaded = new Set();
// A click on the page's own button, as a pointer press and release at its centre, and the file
// the browser's download wrote for it.
const tap = async label => {
  const shown = await button();
  assert.equal(shown.count, 1, `${label}: one button`);
  const x = shown.x + shown.width / 2;
  const y = shown.y + shown.height / 2;
  await call('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
  await call('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
  await call('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
  const name = await until(async () => {
    const files = (await readdir(downloads)).filter(file => file.endsWith('.json') && !downloaded.has(file));
    return files[0];
  }, `${label}: a downloaded file`, 30000);
  downloaded.add(name);
  const text = await until(async () => {
    const body = await readFile(join(downloads, name), 'utf8');
    try { JSON.parse(body); return body; } catch { return false; }
  }, `${label}: the download finishes and parses`, 30000);
  return { name, bytes: Buffer.byteLength(text), record: JSON.parse(text) };
};
// What a record says about itself, and whether every row's buckets add up to its frame.
const audit = record => {
  const columns = record.columns;
  const frame = columns.indexOf('frame_usec');
  const slow = columns.indexOf('slow');
  // The file names its buckets in its own notes, one `<bucket>_usec` column each.
  const buckets = Object.keys(record.buckets).map(name => name + '_usec');
  const indices = buckets.map(name => columns.indexOf(name));
  assert(indices.every(index => index >= 0), 'every bucket the file names has a column');
  let mismatched = 0;
  for (const row of record.rows) {
    const sum = indices.reduce((total, index) => total + row[index], 0);
    if (sum !== row[frame]) mismatched += 1;
  }
  const last = record.rows.at(-1) || [];
  return {
    schema: record.schema, schema_version: record.schema_version,
    buckets, rows: record.rows.length, rows_whose_buckets_do_not_add_up: mismatched,
    slow_rows: record.rows.filter(row => row[slow] === 1).length,
    last_row_player: [last[columns.indexOf('player_x')], last[columns.indexOf('player_y')]],
    last_row_process_frame: last[columns.indexOf('process_frame')],
    environment: record.environment,
    summary_keys: Object.keys(record.summary || {}),
  };
};
let success = false;
let failure = null;
let observer;
let observing = null;
const waitExit = milliseconds => Promise.race([browserExit.then(() => true), pause(milliseconds).then(() => false)]);
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
  profile = await mkdtemp(join(tmpdir(), 'nappy-m159-browser-'));
  await new Promise((r, reject) => { server.once('error', reject); server.listen(0, '127.0.0.1', r); });
  url = `http://127.0.0.1:${server.address().port}`;
  await new Promise((r, reject) => {
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
  await call('Network.setBlockedURLs', { urls: ['https://gc.zgo.at/*', 'https://*.goatcounter.com/*'] });
  await call('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });
  // A headless page never has the OS focus, and the game pauses when it loses focus.
  await call('Emulation.setFocusEmulationEnabled', { enabled: true });
  await call('Browser.setDownloadBehavior', { behavior: 'allow', downloadPath: downloads });
  const version = await call('Browser.getVersion');
  results.push({ check: 'browser', product: version.product, userAgent: version.userAgent });

  // 1. The record's page.
  const boot = await load('record', '?debug=1&framerecord=1&seed=67', '[Main] day 1 started');
  const onTitle = await button();
  assert.equal(onTitle.count, 1, 'the button is on the page');
  assert.notEqual(onTitle.display, 'none', 'the button is shown');
  // The day's clock is centred at the top in a box 120 design pixels wide.
  assert(onTitle.x >= onTitle.viewport / 2 + 60 && onTitle.y <= 8,
    'the button sits at the top, right of the clock');
  results.push({ check: 'button on the record page', boot, button: onTitle });
  await key(' ', 'Space', 32);
  await pause(1500);
  await hold('ArrowUp', 'ArrowUp', 38, 6000);
  await pause(4000);
  await snapshot('button-and-readout');
  await snapshot('readout', { x: 940, y: 0, width: 340, height: 720 });
  const first = await tap('first tap');
  const afterTap = await evaluate(`document.activeElement && document.activeElement.tagName`);
  const firstAudit = audit(first.record);
  assert.equal(first.record.schema, 'nappy-frame-record');
  assert(firstAudit.rows > 0, 'the record has rows');
  assert.equal(firstAudit.rows_whose_buckets_do_not_add_up, 0, 'every row adds up to its frame');
  assert.equal(firstAudit.buckets.length, 9, 'nine buckets');
  assert(typeof first.record.environment.user_agent === 'string'
    && first.record.environment.user_agent.includes('Chrome'), 'the user agent is in the file');
  assert(first.record.environment.timer_resolution_usec > 0, 'the clock step is in the file');
  assert.equal(first.record.environment.run_seed, 67, 'the seed is in the file');
  assert.equal(afterTap, 'CANVAS', 'the tap hands focus back to the canvas');
  results.push({ check: 'first download', file: first.name, bytes: first.bytes, focus_after: afterTap, ...firstAudit });
  // The keyboard still steers after the tap: walk down off the stoop, short of the road, save
  // again, compare where she is.
  await hold('ArrowDown', 'ArrowDown', 40, 1500);
  await pause(1000);
  const second = await tap('second tap');
  const secondAudit = audit(second.record);
  assert.equal(secondAudit.rows_whose_buckets_do_not_add_up, 0, 'the second file adds up too');
  const moved = secondAudit.last_row_player[0] !== firstAudit.last_row_player[0]
    || secondAudit.last_row_player[1] !== firstAudit.last_row_player[1];
  assert(moved, 'she moved after the tap');
  assert(secondAudit.last_row_process_frame > firstAudit.last_row_process_frame, 'the record kept recording');
  results.push({ check: 'keyboard steers after the tap', file: second.name, bytes: second.bytes,
    rows: secondAudit.rows, player_before: firstAudit.last_row_player, player_after: secondAudit.last_row_player,
    rows_whose_buckets_do_not_add_up: secondAudit.rows_whose_buckets_do_not_add_up, slow_rows: secondAudit.slow_rows });
  await snapshot('button-and-readout-after');

  // 2. A restart through the pause screen, the held restart's own function.
  const restartFrom = logs.length;
  await key('Escape', 'Escape', 27);
  await pause(800);
  await key('r', 'KeyR', 82);
  await until(() => logs.slice(restartFrom).some(line => line.includes('[Main] day 1 started')), 'the restart boots a new day');
  await pause(1500);
  const restarted = await button();
  assert.equal(restarted.count, 1, 'a restart leaves exactly one button');
  assert.notEqual(restarted.display, 'none', 'and it is shown');
  const third = await tap('tap after the restart');
  const thirdAudit = audit(third.record);
  assert.equal(thirdAudit.rows_whose_buckets_do_not_add_up, 0, 'the file after the restart adds up');
  results.push({ check: 'restart', boot: logs.slice(restartFrom).filter(line => line.includes('[Main]')),
    button: restarted, file: third.name, rows: thirdAudit.rows });
  await snapshot('after-restart');

  // 3. The pages that must not show it.
  for (const [name, query] of [['debug only', '?debug=1&seed=67'], ['framerecord without debug', '?framerecord=1&seed=67']]) {
    const pageBoot = await load(name, query, '[Main] day 1 started');
    const none = await button();
    const hook = await evaluate(`typeof window.nappyFrameRecordButton`);
    assert.equal(none.count, 0, `${name}: no button`);
    assert.equal(hook, 'undefined', `${name}: the recorder never ran`);
    results.push({ check: `no button: ${name}`, query, boot: pageBoot, button: none, recorder_hook: hook });
  }
  await snapshot('debug-only-no-button');

  // 4. A phone's size.
  await call('Emulation.setDeviceMetricsOverride', { width: 844, height: 390, deviceScaleFactor: 2, mobile: true });
  await call('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 });
  const phoneBoot = await load('phone', '?debug=1&framerecord=1&seed=67', '[Main] day 1 started');
  await key(' ', 'Space', 32);
  await pause(4000);
  const phoneButton = await button();
  assert.equal(phoneButton.count, 1, 'the phone-sized page has one button');
  await snapshot('phone');
  results.push({ check: 'phone size', boot: phoneBoot, button: phoneButton });

  // 5. No save in this profile, and no error.
  const save = await saved();
  assert.equal(save, null, 'no save was written');
  results.push({ check: 'no save written', save });
  assert.deepEqual(errors, [], 'Engine/browser errors');
  success = true;
} catch (error) {
  failure = error.stack || String(error);
  process.exitCode = 1;
  process.stderr.write(failure + '\n');
} finally {
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
