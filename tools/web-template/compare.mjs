// Prepare stock/custom browser controls with an identical PCK and fixed local gzip sizes.
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { cp, mkdir, readFile, writeFile } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { parseArgs } from 'node:util';
const usage = `usage: node tools/web-template/compare.mjs --export DIR --stock-template ZIP --output DIR [--help|-h]
Copies the export into stock/ and trimmed/ under a NEW output directory. Replaces only the
stock engine/loader/worklets from the official threadless release template. Keeps one PCK.
Writes sizes.json using actual gzip -9 -n, hashes and exported texture encodings.
Example: node tools/web-template/compare.mjs --export build/web --stock-template /path/to/web_nothreads_release.zip --output /tmp/new-comparison
`;
let options;
try {
  options = parseArgs({ options: {
    export: { type: 'string' }, 'stock-template': { type: 'string' }, output: { type: 'string' },
    help: { type: 'boolean', short: 'h' },
  } }).values;
  if (options.help) { process.stdout.write(usage); process.exit(0); }
  assert(options.export && options['stock-template'] && options.output);
} catch { process.stderr.write(usage); process.exit(2); }
const html = await readFile(join(options.export, 'index.html'), 'utf8');
const match = [...html.matchAll(/const GODOT_CONFIG = (\{[^\n]+\});/g)];
assert.equal(match.length, 1, 'One Godot shell config required');
const config = JSON.parse(match[0][1]);
assert(/^[a-zA-Z0-9._-]+\/index$/.test(config.executable), 'Expected versioned local executable');
const output = resolve(options.output);
await mkdir(output);
for (const variant of ['stock', 'trimmed']) await cp(options.export, join(output, variant), { recursive: true });
for (const extension of ['wasm', 'js', 'audio.worklet.js', 'audio.position.worklet.js']) {
  const content = execFileSync('unzip', ['-p', resolve(options['stock-template']), `godot.${extension}`], { maxBuffer: 128 * 1024 * 1024 });
  assert(content.length > 0);
  await writeFile(join(output, 'stock', `${config.executable}.${extension}`), content);
  if (extension === 'wasm') config.fileSizes[`${config.executable}.wasm`] = content.length;
}
const stockHtml = html.replace(match[0][0], `const GODOT_CONFIG = ${JSON.stringify(config)};`);
assert(stockHtml !== html, 'Stock control must have a different Wasm size');
await writeFile(join(output, 'stock', 'index.html'), stockHtml);
const hash = data => createHash('sha256').update(data).digest('hex');
const result = { compression: 'gzip -9 -n', stockTemplateSha256: hash(await readFile(options['stock-template'])), variants: {} };
for (const variant of ['stock', 'trimmed']) {
  const files = {};
  for (const extension of ['wasm', 'js', 'pck']) {
    const file = join(output, variant, `${config.executable}.${extension}`);
    const data = await readFile(file);
    const gzip = execFileSync('gzip', ['-9', '-n', '-c', file], { maxBuffer: 128 * 1024 * 1024 });
    files[extension] = { bytes: data.length, gzipBytes: gzip.length, sha256: hash(data) };
  }
  result.variants[variant] = files;
}
assert.equal(result.variants.stock.pck.sha256, result.variants.trimmed.pck.sha256);
// Godot 4 format-4 PCK and CompressedTexture2D's GST2 header in the pinned source.
const pack = await readFile(join(output, 'trimmed', `${config.executable}.pck`));
assert.equal(pack.readUInt32LE(0), 0x43504447);
assert.equal(pack.readUInt32LE(4), 4);
assert.equal(pack.readUInt32LE(20) & 1, 0, 'Unencrypted directory required');
const base = Number(pack.readBigUInt64LE(24));
const directory = Number(pack.readBigUInt64LE(32));
const encodings = {};
let cursor = directory + 4;
for (let i = 0; i < pack.readUInt32LE(directory); ++i) {
  const length = pack.readUInt32LE(cursor); cursor += 4;
  const name = pack.subarray(cursor, cursor + length).toString().replace(/\0+$/, ''); cursor += length;
  const offset = base + Number(pack.readBigUInt64LE(cursor));
  const size = Number(pack.readBigUInt64LE(cursor + 8)); cursor += 36;
  assert(offset + size <= pack.length);
  if (!name.endsWith('.ctex')) continue;
  assert.equal(pack.subarray(offset, offset + 4).toString(), 'GST2');
  const encoding = ['IMAGE', 'PNG', 'WEBP', 'BASIS_UNIVERSAL'][pack.readUInt32LE(offset + 36)];
  assert(encoding);
  encodings[encoding] = (encodings[encoding] || 0) + 1;
}
result.textureEncodings = encodings;
await writeFile(join(output, 'sizes.json'), JSON.stringify(result, null, 2) + '\n');
process.stdout.write(JSON.stringify(result, null, 2) + '\n');
