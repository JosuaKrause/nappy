// M205 browser driver: headless Chrome over CDP against a served Web export (or a remote URL),
// optional GODOT_CONFIG args injection, a timed key script, periodic screenshots, console capture.
// Modelled on tools/web-template/browser-check.mjs (same launch flags, same scratch settling).
import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { mkdtemp, readFile, writeFile, mkdir, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve, join, extname, sep } from 'node:path';
import { parseArgs } from 'node:util';
// The repository root, three levels up from this file (docs/evidence/<this folder>/).
const repo = resolve(new URL('../../..', import.meta.url).pathname);
const { BrowserScratch, cloneRoot } = await import(join(repo, 'tools/web-template/browser-scratch.mjs'));

const o = parseArgs({ options: {
  dir: { type: 'string' }, url: { type: 'string' }, query: { type: 'string', default: '' },
  args: { type: 'string', default: '' }, seconds: { type: 'string', default: '40' },
  keys: { type: 'string', default: '' }, shots: { type: 'string', default: '0' },
  output: { type: 'string' }, browser: { type: 'string', default: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' },
  width: { type: 'string', default: '1280' }, height: { type: 'string', default: '720' },
} }).values;
const output = resolve(o.output);
await mkdir(output, { recursive: true });
const pause = ms => new Promise(r => setTimeout(r, ms));
const logs = [];
let server; let base;
if (o.dir) {
  const root = resolve(o.dir);
  server = createServer(async (req, res) => {
    try {
      const path = resolve(root, '.' + new URL(req.url, 'http://localhost').pathname);
      if (!(path === root || path.startsWith(root + sep))) throw new Error('outside');
      const file = path === root ? join(root, 'index.html') : path;
      let body = await readFile(file);
      if (file.endsWith('index.html') && o.args) {
        const injected = JSON.stringify(['--', ...o.args.split(' ')]);
        const text = body.toString();
        const anchor = '"args":[]';
        if (text.split(anchor).length !== 2) throw new Error('args anchor not found exactly once');
        body = Buffer.from(text.replace(anchor, '"args":' + injected));
      }
      res.setHeader('Content-Type', ({ '.html': 'text/html', '.js': 'application/javascript', '.wasm': 'application/wasm' })[extname(file)] || 'application/octet-stream');
      res.end(body);
    } catch (e) { res.writeHead(404); res.end(String(e)); }
  });
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  base = `http://127.0.0.1:${server.address().port}/index.html`;
} else base = o.url;

const scratch = new BrowserScratch({ root: await cloneRoot() });
await scratch.begin();
const profile = await mkdtemp(join(tmpdir(), 'nappy-m205-'));
let exited = false;
const browser = spawn(o.browser, [
  '--headless=new', '--no-sandbox', '--disable-dev-shm-usage', '--enable-unsafe-swiftshader',
  '--use-angle=swiftshader', '--disable-background-timer-throttling',
  '--disable-renderer-backgrounding', '--disable-backgrounding-occluded-windows',
  '--disable-features=MacAppCodeSignClone',
  '--remote-debugging-port=0', `--user-data-dir=${profile}`, '--no-first-run', 'about:blank',
], { stdio: ['ignore', 'ignore', 'pipe'] });
const browserExit = new Promise(r => browser.once('exit', () => { exited = true; r(); }));
const observer = setInterval(() => { if (!exited) scratch.observe(browser.pid).catch(() => {}); }, 2000);
let socket; let seq = 0; const pending = new Map();
const call = (method, params = {}) => new Promise((ok, bad) => {
  const id = ++seq; pending.set(id, { ok, bad }); socket.send(JSON.stringify({ id, method, params }));
});
try {
  let port;
  for (let i = 0; i < 100 && !port; i++) {
    try { port = (await readFile(join(profile, 'DevToolsActivePort'), 'utf8')).split('\n')[0]; } catch { await pause(200); }
  }
  const target = await (await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, { method: 'PUT' })).json();
  socket = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise(r => { socket.onopen = r; });
  const t0 = Date.now();
  socket.onmessage = ev => {
    const m = JSON.parse(ev.data);
    if (m.id) { const w = pending.get(m.id); pending.delete(m.id); if (m.error) w.bad(new Error(JSON.stringify(m.error))); else w.ok(m.result); }
    else if (m.method === 'Runtime.consoleAPICalled') {
      const line = m.params.args.map(a => a.value ?? a.description ?? '').join(' ');
      logs.push(`${((Date.now() - t0) / 1000).toFixed(1)} ${line}`);
      if (!line.startsWith('[M205]')) process.stdout.write(line + '\n');
    }
  };
  await call('Runtime.enable'); await call('Page.enable'); await call('Network.enable');
  await call('Network.setBlockedURLs', { urls: ['https://gc.zgo.at/*', 'https://*.goatcounter.com/*'] });
  await call('Emulation.setDeviceMetricsOverride', { width: Number(o.width), height: Number(o.height), deviceScaleFactor: 1, mobile: false });
  await call('Page.navigate', { url: base + o.query });
  // wait for the day to start
  for (let i = 0; i < 600 && !logs.some(l => l.includes('day ') && l.includes('started')); i++) await pause(200);
  await pause(1500);
  const codes = { up: ['ArrowUp', 38], down: ['ArrowDown', 40], left: ['ArrowLeft', 37], right: ['ArrowRight', 39], space: [' ', 32], k4: ['4', 52] };
  const keyEvent = async (type, name) => {
    const [key, vk] = codes[name];
    await call('Input.dispatchKeyEvent', { type, key, code: name === 'space' ? 'Space' : name === 'k4' ? 'Digit4' : key, windowsVirtualKeyCode: vk });
  };
  const shotEvery = Number(o.shots) * 1000;
  let nextShot = shotEvery ? Date.now() : Infinity; let shotN = 0;
  const shoot = async () => {
    const cap = await call('Page.captureScreenshot');
    await writeFile(join(output, `shot-${String(shotN++).padStart(3, '0')}.png`), Buffer.from(cap.data, 'base64'));
  };
  // keys: "space@0 down@1:3 right@4:2" -> press name at t seconds for d seconds (tap if no d)
  const script = o.keys ? o.keys.split(' ').map(s => { const [n, rest] = s.split('@'); const [t, d] = rest.split(':'); return { n, t: Number(t), d: d ? Number(d) : 0.1, down: false, up: false }; }) : [];
  const start = Date.now(); const end = start + Number(o.seconds) * 1000;
  while (Date.now() < end) {
    const now = (Date.now() - start) / 1000;
    for (const s of script) {
      if (!s.down && now >= s.t) { s.down = true; await keyEvent('keyDown', s.n); }
      if (s.down && !s.up && now >= s.t + s.d) { s.up = true; await keyEvent('keyUp', s.n); }
    }
    if (Date.now() >= nextShot) { await shoot(); nextShot += shotEvery; }
    await pause(50);
  }
  await shoot();
} finally {
  clearInterval(observer);
  try { await Promise.race([call('Browser.close').catch(() => {}), pause(3000)]); } catch {}
  await Promise.race([browserExit, pause(10000)]);
  if (!exited) { browser.kill('SIGTERM'); await Promise.race([browserExit, pause(5000)]); }
  if (server) { server.closeAllConnections(); server.close(); }
  await pause(300);
  await rm(profile, { recursive: true, force: true, maxRetries: 3, retryDelay: 200 });
  const report = exited ? await scratch.settle() : { settled: 'browser still running' };
  await writeFile(join(output, 'console.log'), logs.join('\n') + '\n');
  await writeFile(join(output, 'scratch.json'), JSON.stringify(report, null, 2) + '\n');
  process.exit(0);
}
