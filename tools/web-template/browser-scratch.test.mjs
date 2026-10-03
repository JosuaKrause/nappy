// Ownership and retention of browser scratch, against fixtures only: every clone here is a
// directory under a fresh temporary root, held open by a `sleep` this test starts, so no real
// browser, profile or system directory is ever read for removal.
//
//   node --test tools/web-template/browser-scratch.test.mjs
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { mkdir, mkdtemp, realpath, rm, stat, symlink, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { after, before, test } from 'node:test';
import { BrowserScratch, cloneRoot, listClones } from './browser-scratch.mjs';

let scratchDir;
before(async () => { scratchDir = await realpath(await mkdtemp(join(tmpdir(), 'browser-scratch-test-'))); });
after(async () => { await rm(scratchDir, { recursive: true, force: true }); });

const fixture = async name => {
  const root = join(scratchDir, name, 'X');
  await mkdir(join(root, 'com.example.Fixture.code_sign_clone'), { recursive: true });
  return root;
};
const clone = async (root, name) => {
  const path = join(root, 'com.example.Fixture.code_sign_clone', name);
  await mkdir(join(path, 'Fixture.app', 'Contents'), { recursive: true });
  await writeFile(join(path, 'Fixture.app', 'Contents', 'binary'), 'fixture\n');
  return path;
};
// A stand-in browser: a shell whose child `sleep` holds the clone's file open as fd 3, so the
// evidence comes from a descendant, as a real browser's helper processes would give it.
const holder = path => {
  const child = spawn('/bin/sh', ['-c', 'exec 3<"$1"; sleep 30 & wait', 'holder', join(path, 'Fixture.app', 'Contents', 'binary')], { stdio: 'ignore' });
  return child;
};
const settleWithin = (child, milliseconds = 3000) => new Promise(r => {
  const timer = setTimeout(r, milliseconds);
  child.once('exit', () => { clearTimeout(timer); r(); });
});
const stop = async child => {
  // The shell's sleep is its child; kill the group's members one by one.
  const { execFileSync } = await import('node:child_process');
  for (const line of execFileSync('ps', ['-A', '-o', 'pid=,ppid=']).toString().split('\n')) {
    const [pid, ppid] = line.trim().split(/\s+/).map(Number);
    if (ppid === child.pid) process.kill(pid, 'SIGKILL');
  }
  child.kill('SIGKILL');
  await settleWithin(child);
};
const exists = async path => { try { await stat(path); return true; } catch { return false; } };
const pause = ms => new Promise(r => setTimeout(r, ms));

test('the clone root is the override, and none off macOS', async () => {
  assert.equal(await cloneRoot({ NAPPY_BROWSER_CLONE_DIR: '/fixture/X' }, 'darwin'), '/fixture/X');
  assert.equal(await cloneRoot({}, 'linux'), null);
});

test('an attributed clone is removed once its process is gone; others are reported or ignored', async () => {
  const root = await fixture('attributed');
  const earlier = await clone(root, 'code_sign_clone.EARLIER');
  const scratch = new BrowserScratch({ root });
  await scratch.begin();
  const owned = await clone(root, 'code_sign_clone.OWNED');
  const stranger = await clone(root, 'code_sign_clone.STRANGER');
  const browser = holder(owned);
  await pause(300);
  await scratch.observe(browser.pid);
  assert.equal(scratch.attribution, 'lsof');
  assert.deepEqual([...scratch.owned.keys()], [owned]);
  await stop(browser);
  const report = await scratch.settle({ waitMs: 0 });
  assert.deepEqual(report.removed.map(entry => entry.path), [owned]);
  assert.match(report.removed[0].evidence, /Fixture\.app\/Contents\/binary$/);
  assert.deepEqual(report.retained, []);
  assert.deepEqual(report.candidates.map(entry => entry.path), [stranger]);
  assert.match(report.candidates[0].missing, /no process of this run/);
  assert.equal(await exists(owned), false);
  assert.equal(await exists(stranger), true);
  assert.equal(await exists(earlier), true);
});

test('a clone something else still holds is kept, with the holder named', async () => {
  const root = await fixture('held');
  const scratch = new BrowserScratch({ root });
  await scratch.begin();
  const owned = await clone(root, 'code_sign_clone.HELD');
  const browser = holder(owned);
  await pause(300);
  await scratch.observe(browser.pid);
  await stop(browser);
  const other = holder(owned);
  await pause(300);
  try {
    const report = await scratch.settle({ waitMs: 0 });
    assert.deepEqual(report.removed, []);
    assert.equal(report.retained.length, 1);
    assert.match(report.retained[0].reason, /still open by process/);
    assert.equal(await exists(owned), true);
  } finally {
    await stop(other);
  }
});

test('a clone whose run process is still alive is kept', async () => {
  const root = await fixture('alive');
  const scratch = new BrowserScratch({ root });
  await scratch.begin();
  const owned = await clone(root, 'code_sign_clone.ALIVE');
  const browser = holder(owned);
  await pause(300);
  try {
    await scratch.observe(browser.pid);
    const report = await scratch.settle({ waitMs: 0 });
    assert.equal(report.retained.length, 1);
    assert.match(report.retained[0].reason, /run process still alive/);
    assert.equal(await exists(owned), true);
  } finally {
    await stop(browser);
  }
});

test('a clone the browser removed itself is neither removed nor reported', async () => {
  const root = await fixture('self-cleaned');
  const scratch = new BrowserScratch({ root });
  await scratch.begin();
  const owned = await clone(root, 'code_sign_clone.GONE');
  const browser = holder(owned);
  await pause(300);
  await scratch.observe(browser.pid);
  await stop(browser);
  await rm(owned, { recursive: true });
  const report = await scratch.settle({ waitMs: 0 });
  assert.deepEqual(report, { root, attribution: 'lsof', removed: [], retained: [], candidates: [] });
});

test('without lsof nothing is attributed, so nothing is removed and new clones are candidates', async () => {
  const root = await fixture('no-lsof');
  const scratch = new BrowserScratch({ root, lsof: join(scratchDir, 'missing-lsof') });
  await scratch.begin();
  const owned = await clone(root, 'code_sign_clone.UNPROVEN');
  const browser = holder(owned);
  await pause(300);
  await scratch.observe(browser.pid);
  await stop(browser);
  const report = await scratch.settle({ waitMs: 0 });
  assert.deepEqual(report.removed, []);
  assert.deepEqual(report.candidates.map(entry => entry.path), [owned]);
  assert.match(report.candidates[0].missing, /lsof could not run/);
  assert.equal(await exists(owned), true);
});

test('a symlinked clone entry is never listed, so never removed', async () => {
  const root = await fixture('symlink');
  const target = join(scratchDir, 'symlink-target');
  await mkdir(target);
  await symlink(target, join(root, 'com.example.Fixture.code_sign_clone', 'code_sign_clone.LINK'));
  assert.deepEqual(await listClones(root), []);
  assert.equal(await exists(target), true);
});
