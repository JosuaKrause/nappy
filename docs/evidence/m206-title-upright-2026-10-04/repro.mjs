// M206 reproduction: the released (or a locally served) web build in headless Chrome with a phone
// emulated (412x915 CSS px portrait, touch on). --scenario restart loses day 1 at once (?meters=
// with the excitement meter nearly full, then walks south) and holds the summary's restart disc
// with a touch; --scenario gameover lets every try of day 1 time out (?daylength=4) until the run
// is over and continues past the GAME OVER screen; --scenario boot records a first page load.
// Every frame Chrome produces from the action on is kept with its timestamp (Page.startScreencast),
// so how long a wrong-way-up screen lasts is measured, not guessed. Node 22, no dependencies; the
// browser runs in a disposable profile with MacAppCodeSignClone off, as tools/web-template/browser-check.mjs does.
//
//   node repro.mjs --url https://nappy.josuakrause.com/ --scenario restart --output DIR \
//       [--browser "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"]
//   node repro.mjs --export build/web --scenario gameover --output DIR
import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { mkdtemp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { extname, join, resolve, sep } from 'node:path';
import { parseArgs } from 'node:util';

const { values: o } = parseArgs({ options: {
  url: { type: 'string' }, export: { type: 'string' }, output: { type: 'string' },
  scenario: { type: 'string', default: 'restart' }, query: { type: 'string' },
  browser: { type: 'string', default: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' },
  width: { type: 'string', default: '412' }, height: { type: 'string', default: '915' },
  tail: { type: 'string', default: '6000' },
} });
if (!o.output || (!o.url && !o.export) || !['restart', 'gameover', 'boot'].includes(o.scenario)) {
  console.error('usage: node repro.mjs (--url URL | --export DIR) --output DIR [--scenario restart|gameover|boot]');
  process.exit(2);
}
const output = resolve(o.output);
await mkdir(join(output, 'frames'), { recursive: true });
const pause = ms => new Promise(r => setTimeout(r, ms));
const logs = [];
const t0 = Date.now();
const note = line => { const s = `${((Date.now() - t0) / 1000).toFixed(2)}s ${line}`; logs.push(s); console.log(s); };

let server; let base = o.url;
if (o.export) {
  const root = resolve(o.export);
  server = createServer(async (req, res) => {
    try {
      const path = resolve(root, '.' + new URL(req.url, 'http://localhost').pathname);
      if (!(path === root || path.startsWith(root + sep))) throw new Error();
      const file = path === root || path.endsWith(sep) ? join(path, 'index.html') : path;
      res.setHeader('Content-Type', ({ '.html': 'text/html', '.js': 'application/javascript', '.wasm': 'application/wasm' })[extname(file)] || 'application/octet-stream');
      res.end(await readFile(file));
    } catch { res.writeHead(404); res.end(); }
  });
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  base = `http://127.0.0.1:${server.address().port}/`;
}
const profile = await mkdtemp(join(tmpdir(), 'm206-'));
const browser = spawn(o.browser, ['--headless=new', '--no-sandbox', '--enable-unsafe-swiftshader',
  '--use-angle=swiftshader', '--disable-background-timer-throttling', '--disable-renderer-backgrounding',
  '--disable-backgrounding-occluded-windows', '--disable-features=MacAppCodeSignClone',
  '--remote-debugging-port=0', `--user-data-dir=${profile}`, '--no-first-run', 'about:blank'],
  { stdio: ['ignore', 'ignore', 'ignore'] });
let socket; let seq = 0; const pending = new Map();
const call = (method, params = {}) => new Promise((ok, no) => {
  const id = ++seq; pending.set(id, { ok, no }); socket.send(JSON.stringify({ id, method, params }));
});
const evaluate = async e => (await call('Runtime.evaluate', { expression: e, returnByValue: true, awaitPromise: true })).result.value;
const frames = []; let recording = false;
const consoleLines = [];
const seen = (text, from = 0) => consoleLines.slice(from).some(l => l.includes(text));
const until = async (pred, label, ms = 120000) => {
  const end = Date.now() + ms;
  while (Date.now() < end) { if (await pred()) return; await pause(100); }
  throw new Error('timed out: ' + label);
};
try {
  let port;
  await until(async () => { try { port = (await readFile(join(profile, 'DevToolsActivePort'), 'utf8')).split('\n')[0]; return true; } catch { return false; } }, 'cdp', 20000);
  const target = await (await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, { method: 'PUT' })).json();
  socket = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise(r => { socket.onopen = r; });
  socket.onmessage = ev => {
    const m = JSON.parse(ev.data);
    if (m.id) { const w = pending.get(m.id); pending.delete(m.id); if (w) m.error ? w.no(new Error(JSON.stringify(m.error))) : w.ok(m.result); return; }
    if (m.method === 'Runtime.consoleAPICalled') {
      const line = m.params.args.map(a => a.value ?? a.description ?? '').join(' ');
      consoleLines.push(line); note('console: ' + line);
    } else if (m.method === 'Page.screencastFrame') {
      call('Page.screencastFrameAck', { sessionId: m.params.sessionId });
      if (recording) frames.push({ t: m.params.metadata.timestamp, data: m.params.data });
    }
  };
  await call('Runtime.enable'); await call('Page.enable');
  await call('Network.enable');
  await call('Network.setBlockedURLs', { urls: ['https://gc.zgo.at/*', 'https://*.goatcounter.com/*'] });
  const W = Number(o.width), H = Number(o.height);
  await call('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: true,
    screenOrientation: { type: 'portraitPrimary', angle: 0 } });
  await call('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 });
  if (o.scenario === 'boot') { recording = true; await call('Page.startScreencast', { format: 'jpeg', quality: 70 }); }
  // A held restart needs a day lost fast (the meter nearly full); a game over needs every try of
  // the day to time out.
  o.query ??= { restart: '?debug=1&meters=0,99.9', gameover: '?debug=1&daylength=4', boot: '?debug=1' }[o.scenario];
  await call('Page.navigate', { url: base + o.query });
  await until(() => seen('[Main] day 1 started'), 'first boot');
  note('touch: ' + await evaluate(`'ontouchstart' in window`) + ', canvas ' + await evaluate(`(()=>{const c=document.querySelector('canvas');return c.width+'x'+c.height})()`));
  await pause(2500);
  const shot = async name => { const c = await call('Page.captureScreenshot'); await writeFile(join(output, name + '.png'), Buffer.from(c.data, 'base64')); note('still ' + name); };
  await shot('01-title');
  const key = async (key, code, vk, hold = 100) => {
    await call('Input.dispatchKeyEvent', { type: 'keyDown', key, code, windowsVirtualKeyCode: vk });
    await pause(hold);
    await call('Input.dispatchKeyEvent', { type: 'keyUp', key, code, windowsVirtualKeyCode: vk });
  };
  // A presented design-space point (1280x720, the box every screen is authored in) to the CSS
  // pixel it lands on in a portrait page, rotated and fitted the way ScreenOrientation does.
  const scale = Math.min(W / 720, H / 1280);
  const toPage = (x, y) => ({ x: (W - 720 * scale) / 2 + (720 - y) * scale, y: (H - 1280 * scale) / 2 + x * scale });
  const touch = async (type, p) => call('Input.dispatchTouchEvent', { type, touchPoints: type === 'touchEnd' ? [] : [{ x: p.x, y: p.y, id: 1 }] });
  if (o.scenario !== 'boot') {
    await key(' ', 'Space', 32);
    note('start pressed');
    await pause(1500);
    await shot('02-day');
    // Into the road south of the doorstep: the day ends on the hard fail or the meter.
    const loseOne = async n => {
      const from = consoleLines.length;
      await call('Input.dispatchKeyEvent', { type: 'keyDown', key: 'ArrowDown', code: 'ArrowDown', windowsVirtualKeyCode: 40 });
      await pause(Number(process.env.WALK_MS || 6000));
      await call('Input.dispatchKeyEvent', { type: 'keyUp', key: 'ArrowDown', code: 'ArrowDown', windowsVirtualKeyCode: 40 });
      await pause(1500);
      await shot(`03-summary-${n}`);
      return from;
    };
    if (o.scenario === 'restart') {
      await loseOne(1);
      recording = true; await call('Page.startScreencast', { format: 'jpeg', quality: 70 });
      const at = toPage(720, 544); // the summary's restart disc, in the 1280x720 design box
      note(`holding restart at page ${at.x.toFixed(0)},${at.y.toFixed(0)}`);
      await touch('touchStart', at);
      await pause(1800);
      await touch('touchEnd', at);
      note('released');
    } else {
      // Every try of the day times out (?daylength=), so each costs a nerve the way a lost day
      // does, until the last one ends the run and its continue shows the ending.
      const losses = Number(process.env.LOSSES || 5);
      for (let n = 1; n <= losses; n++) {
        await pause(Number(process.env.TRY_MS || 8000));
        await shot(`03-summary-${n}`);
        if (n === losses) { recording = true; await call('Page.startScreencast', { format: 'jpeg', quality: 70 }); }
        await key(' ', 'Space', 32); note('continue pressed');
      }
      const from = consoleLines.length;
      await pause(4000);
      if (!seen('run started', from)) { await key(' ', 'Space', 32); note('continue on the ending pressed'); }
    }
  }
  await pause(Number(o.tail));
  recording = false;
  await call('Page.stopScreencast');
  await shot('99-after');
} catch (e) { note('FAILED ' + (e.stack || e)); process.exitCode = 1; }
finally {
  const start = frames.length ? frames[0].t : 0;
  const index = [];
  for (const [i, f] of frames.entries()) {
    const name = `frame-${String(i).padStart(3, '0')}-${((f.t - start) * 1000).toFixed(0)}ms.jpg`;
    await writeFile(join(output, 'frames', name), Buffer.from(f.data, 'base64'));
    index.push({ name, ms: Math.round((f.t - start) * 1000) });
  }
  await writeFile(join(output, 'frames.json'), JSON.stringify(index, null, 1));
  await writeFile(join(output, 'run.log'), logs.join('\n') + '\n');
  try { await call('Browser.close'); } catch {}
  await pause(1000); browser.kill();
  server?.close();
  await rm(profile, { recursive: true, force: true });
  process.exit();
}
