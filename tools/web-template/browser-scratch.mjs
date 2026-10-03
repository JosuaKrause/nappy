// Attribute and settle a browser run's scratch beyond its disposable profile: the code-sign
// clones macOS Chrome-family browsers make of their own application bundle.
//
// A Chrome launched on macOS copies its bundle into
// `<per-user X dir>/<bundle id>.code_sign_clone/code_sign_clone.XXXXXX/` and runs from that copy,
// so an update installed underneath it cannot break the running browser's signature. Chrome
// removes the copy itself after a graceful exit (`Browser.close`); a browser stopped with a signal
// leaves it behind, about 2 GiB allocated each. Launching with
// `--disable-features=MacAppCodeSignClone` makes no copy at all, which is the first defence; this
// module is the second, for a browser that makes one anyway.
//
// Nothing here guesses an owner from a name or a date. A clone is this run's only when `lsof`
// showed a process of this run's browser holding a file inside it while it ran; such a clone is
// removed only after every recorded process has exited and `lsof` finds no process at all still
// holding anything inside it. A clone that appeared during the run without that evidence is
// reported as a candidate with the missing evidence named, and left where it is. A clone that
// existed before the run is never examined further.
import { execFile } from 'node:child_process';
import { lstat, readdir, realpath, rm } from 'node:fs/promises';
import { basename, dirname, join, relative, sep } from 'node:path';

// A command's output, with a time limit: a system-wide `lsof` can block on a stale mount, and this
// runs inside browser-check.mjs's own cleanup, which must end.
const run = (command, args, timeout = 60000) => new Promise(resolveRun => {
  execFile(command, args, { maxBuffer: 64 * 1024 * 1024, timeout, killSignal: 'SIGKILL' }, (error, stdout) => {
    resolveRun({ error, stdout: stdout || '' });
  });
});

// The path as the kernel names it (macOS's /var is /private/var, and lsof reports the latter),
// whether or not it exists yet: the nearest existing ancestor resolved, the rest joined on.
export const canonical = async path => {
  let existing = path;
  while (true) {
    try { return join(await realpath(existing), relative(existing, path)); } catch {
      const parent = dirname(existing);
      if (parent === existing) return path;
      existing = parent;
    }
  }
};

// The per-user directory the clones live under on macOS: the sibling `X` of the Darwin user temp
// dir, which is where Chrome puts them. Elsewhere there is none. `temp` is given only by the test.
export const cloneRoot = async ({ platform = process.platform, temp } = {}) => {
  if (platform !== 'darwin') return null;
  if (temp === undefined) {
    const { error, stdout } = await run('getconf', ['DARWIN_USER_TEMP_DIR']);
    if (error) return null;
    temp = stdout;
  }
  temp = temp.trim().replace(/\/+$/, '');
  if (basename(temp) !== 'T') return null;
  return canonical(join(dirname(temp), 'X'));
};

// Every clone directory present now: `<root>/<anything>.code_sign_clone/<entry>`, real paths.
export const listClones = async root => {
  const clones = [];
  if (!root) return clones;
  let real;
  try { real = await realpath(root); } catch { return clones; }
  let parents;
  try { parents = await readdir(real, { withFileTypes: true }); } catch { return clones; }
  for (const parent of parents) {
    if (!parent.isDirectory() || !parent.name.endsWith('.code_sign_clone')) continue;
    let entries;
    try { entries = await readdir(join(real, parent.name), { withFileTypes: true }); } catch { continue; }
    for (const entry of entries) {
      if (entry.isDirectory()) clones.push(join(real, parent.name, entry.name));
    }
  }
  return clones.sort();
};

// The process and every descendant of it, from one `ps` listing.
export const processTree = async pid => {
  const { error, stdout } = await run('ps', ['-A', '-o', 'pid=,ppid=']);
  if (error) return [pid];
  const children = new Map();
  for (const line of stdout.split('\n')) {
    const [child, parent] = line.trim().split(/\s+/).map(Number);
    if (!child) continue;
    if (!children.has(parent)) children.set(parent, []);
    children.get(parent).push(child);
  }
  const tree = [];
  const queue = [pid];
  while (queue.length) {
    const next = queue.shift();
    if (tree.includes(next)) continue;
    tree.push(next);
    queue.push(...(children.get(next) || []));
  }
  return tree;
};

// `lsof -F pn` output as [pid, path] pairs; null when its answer is not known to be complete.
const openFiles = async (lsof, args) => {
  const { error, stdout } = await run(lsof, ['-n', '-P', '-w', '-F', 'pn', ...args]);
  // Exit 1 is lsof's ordinary "something asked for had nothing open". Anything else -- a missing
  // command, a timeout or another signal (code null), an overlong listing, another exit status --
  // leaves the answer unknown, and unknown keeps the clone.
  if (error && error.code !== 1) return null;
  const pairs = [];
  let pid = 0;
  for (const line of stdout.split('\n')) {
    if (line.startsWith('p')) pid = Number(line.slice(1));
    else if (line.startsWith('n') && line.length > 1) pairs.push([pid, line.slice(1)]);
  }
  return pairs;
};

const cloneOf = (path, root) => {
  if (!root || !path.startsWith(root + sep)) return null;
  const parts = path.slice(root.length + 1).split(sep);
  if (parts.length < 2 || !parts[0].endsWith('.code_sign_clone') || !parts[1]) return null;
  return join(root, parts[0], parts[1]);
};

const alive = pid => {
  try { process.kill(pid, 0); return true; } catch (error) { return error.code === 'EPERM'; }
};

// One run's ledger. `begin` before the browser starts, `observe` while it runs (as often as
// convenient), `settle` once it has exited.
export class BrowserScratch {
  constructor({ root, lsof = 'lsof' } = {}) {
    this.root = root;
    this.lsof = lsof;
    this.before = new Set();
    this.owned = new Map();
    this.pids = new Set();
    this.attribution = 'not attempted';
  }

  async begin() {
    if (this.root) this.root = await canonical(this.root);
    this.before = new Set(await listClones(this.root));
  }

  // Records every clone a process of the browser's tree holds a file in, with that evidence.
  async observe(browserPid) {
    if (!this.root || !browserPid) return;
    const tree = (await processTree(browserPid)).filter(alive);
    if (!tree.length) return;
    for (const pid of tree) this.pids.add(pid);
    const pairs = await openFiles(this.lsof, ['-p', tree.join(',')]);
    if (pairs === null) { this.attribution = 'unavailable: lsof gave no complete answer'; return; }
    this.attribution = 'lsof';
    for (const [pid, path] of pairs) {
      const clone = cloneOf(path, this.root);
      if (clone && !this.before.has(clone) && !this.owned.has(clone)) {
        this.owned.set(clone, { pid, evidence: path });
      }
    }
  }

  // After the browser has exited: waits up to `waitMs` for the browser's own removal, removes
  // what is provably this run's and released, and reports everything else. Never throws.
  async settle({ waitMs = 5000 } = {}) {
    const report = { root: this.root, attribution: this.attribution, removed: [], retained: [], candidates: [] };
    if (!this.root) return report;
    const deadline = Date.now() + waitMs;
    let present = await listClones(this.root);
    while (Date.now() < deadline && [...this.owned.keys()].some(clone => present.includes(clone))) {
      await new Promise(r => setTimeout(r, 200));
      present = await listClones(this.root);
    }
    for (const [clone, { pid, evidence }] of this.owned) {
      if (!present.includes(clone)) continue;
      const entry = { path: clone, pid, evidence };
      const live = [...this.pids].filter(alive);
      if (live.length) { report.retained.push({ ...entry, reason: `run process still alive: ${live.join(', ')}` }); continue; }
      const holders = await openFiles(this.lsof, []);
      if (holders === null) { report.retained.push({ ...entry, reason: 'lsof gave no complete answer, so it may still be held' }); continue; }
      const holding = [...new Set(holders.filter(([, path]) => path.startsWith(clone + sep) || path === clone).map(([holder]) => holder))];
      if (holding.length) { report.retained.push({ ...entry, reason: `still open by process ${holding.join(', ')}` }); continue; }
      try {
        const info = await lstat(clone);
        if (!info.isDirectory() || info.isSymbolicLink()) throw new Error('no longer a plain directory');
        await rm(clone, { recursive: true });
        report.removed.push(entry);
      } catch (error) {
        report.retained.push({ ...entry, reason: `removal failed: ${error.message}` });
      }
    }
    for (const clone of present) {
      if (this.before.has(clone) || this.owned.has(clone)) continue;
      report.candidates.push({
        path: clone,
        missing: this.attribution === 'lsof'
          ? 'no process of this run was seen holding a file inside it'
          : `attribution ${this.attribution}`,
      });
    }
    return report;
  }
}
