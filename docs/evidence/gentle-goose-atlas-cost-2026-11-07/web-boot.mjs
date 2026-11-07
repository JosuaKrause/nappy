// Boots an exported web build in Chrome COUNT times, each in a fresh temporary profile, and keeps
// per boot the console's `[Main] ... atlas pages held` line and, for a debug build opened with
// ?telemetry=1, the run log's `atlas page` lines read out of the page's IndexedDB (/userfs).
//
//   node web-boot.mjs --export DIR --browser FILE --query '?telemetry=1&seed=1&nosave=1' \
//        --count N --output NEWDIR [--software]
//
// --software adds Chrome's SwiftShader flags; without it Chrome picks its own GL backend. The
// output directory must not exist. Node 22 or newer. Nothing leaves the machine: GoatCounter is
// blocked, the profile is temporary and removed afterwards.
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { mkdtemp, readFile, writeFile, mkdir, rm } from 'node:fs/promises';
import { tmpdir, loadavg } from 'node:os';
import { resolve, join, extname, sep } from 'node:path';
import { parseArgs } from 'node:util';

const usage = 'usage: node web-boot.mjs --export DIR --browser FILE --query QS --count N --output NEWDIR [--software]\n';
let o;
try {
  o = parseArgs({ options: { export: { type: 'string' }, browser: { type: 'string' }, query: { type: 'string' },
    count: { type: 'string' }, output: { type: 'string' }, software: { type: 'boolean' },
    help: { type: 'boolean', short: 'h' } } }).values;
  if (o.help) { process.stdout.write(usage); process.exit(0); }
  assert(o.export && o.browser && o.query !== undefined && o.count && o.output);
} catch { process.stderr.write(usage); process.exit(2); }
const root = resolve(o.export), out = resolve(o.output);
await mkdir(out);
const pause = ms => new Promise(r => setTimeout(r, ms));
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
const url = `http://127.0.0.1:${server.address().port}/${o.query}`;

async function one(n) {
  const load = loadavg().map(x => x.toFixed(1)).join(' ');
  const profile = await mkdtemp(join(tmpdir(), 'nappy-web-boot-'));
  const flags = ['--headless=new', '--no-sandbox', '--disable-features=MacAppCodeSignClone',
    '--disable-background-timer-throttling', '--disable-renderer-backgrounding',
    '--remote-debugging-port=0', `--user-data-dir=${profile}`, '--no-first-run', 'about:blank'];
  if (o.software) flags.splice(2, 0, '--enable-unsafe-swiftshader', '--use-angle=swiftshader');
  const browser = spawn(o.browser, flags, { stdio: ['ignore', 'ignore', 'ignore'] });
  const exited = new Promise(r => browser.once('exit', r));
  const lines = [];
  try {
    let port;
    for (let i = 0; i < 300 && !port; i++) {
      try { port = (await readFile(join(profile, 'DevToolsActivePort'), 'utf8')).split('\n')[0]; } catch { await pause(200); }
    }
    const target = await (await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, { method: 'PUT' })).json();
    const socket = new WebSocket(target.webSocketDebuggerUrl);
    await new Promise(r => { socket.onopen = r; });
    let seq = 0; const pending = new Map();
    const call = (method, params = {}) => new Promise(r => { const id = ++seq; pending.set(id, r); socket.send(JSON.stringify({ id, method, params })); });
    socket.onmessage = e => {
      const m = JSON.parse(e.data);
      if (m.id) { pending.get(m.id)?.(m.result); return; }
      if (m.method === 'Runtime.consoleAPICalled') lines.push(m.params.args.map(a => a.value ?? a.description ?? '').join(' '));
    };
    await call('Runtime.enable'); await call('Page.enable'); await call('Network.enable');
    await call('Network.setBlockedURLs', { urls: ['https://gc.zgo.at/*', 'https://*.goatcounter.com/*'] });
    await call('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });
    await call('Page.navigate', { url });
    for (let i = 0; i < 600 && !lines.some(l => l.includes('atlas pages held')); i++) await pause(200);
    await pause(3000);
    const ev = async expression => (await call('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true })).result?.value;
    const gl = await ev(`(() => { const c = document.createElement('canvas').getContext('webgl2'); const x = c && c.getExtension('WEBGL_debug_renderer_info'); return x ? c.getParameter(x.UNMASKED_RENDERER_WEBGL) : 'unknown'; })()`);
    let log = '';
    for (let i = 0; i < 25 && !log.includes('atlas page'); i++) {
      log = await ev(`(async () => {
        const dbs = await indexedDB.databases(); if (!dbs.some(d => d.name === '/userfs')) return '';
        const db = await new Promise((res, rej) => { const q = indexedDB.open('/userfs'); q.onsuccess = () => res(q.result); q.onerror = () => rej(q.error); });
        try {
          const keys = await new Promise(res => { const q = db.transaction('FILE_DATA', 'readonly').objectStore('FILE_DATA').getAllKeys(); q.onsuccess = () => res(q.result); });
          const key = keys.filter(k => String(k).endsWith('run.log')).sort().pop(); if (!key) return '';
          const v = await new Promise(res => { const q = db.transaction('FILE_DATA', 'readonly').objectStore('FILE_DATA').get(key); q.onsuccess = () => res(q.result); });
          return new TextDecoder().decode(v.contents);
        } finally { db.close(); } })()`) || '';
      if (!log.includes('atlas page')) await pause(1000);
    }
    const text = [`# web boot ${n}, host load average before launch: ${load}, WebGL renderer: ${gl}`,
      ...lines.filter(l => l.includes('[Main]')),
      ...log.split('\n').filter(l => l.includes("atlas page '"))].join('\n') + '\n';
    await writeFile(join(out, `boot-${n}.txt`), text);
  } finally {
    browser.kill('SIGTERM');
    await Promise.race([exited, pause(10000)]);
    if (browser.exitCode === null) { browser.kill('SIGKILL'); await Promise.race([exited, pause(5000)]); }
    await rm(profile, { recursive: true, force: true });
  }
}
try { for (let n = 1; n <= Number(o.count); n++) await one(n); } finally { server.close(); }
process.exit(0);
