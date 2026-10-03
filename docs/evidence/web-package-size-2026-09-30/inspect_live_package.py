"""Read a downloaded Godot 4 package's directory without running its contents."""
import collections
import argparse
import hashlib
import json
import pathlib
import struct

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('pack', type=pathlib.Path, help='Downloaded format-4 .pck to inspect')
parser.add_argument('output', type=pathlib.Path, help='New JSON report; existing files are refused')
args = parser.parse_args()
if args.output.exists():
    parser.error('output already exists; choose a new path')
path = args.pack
blob = path.read_bytes()
magic, version, major, minor, patch, flags, base, directory = struct.unpack_from('<6I2Q', blob)
assert magic == 0x43504447 and version == 4, (hex(magic), version, flags)
assert not (flags & 1), 'Encrypted directory unsupported'
count, = struct.unpack_from('<I', blob, directory)
at = directory + 4
entries = []
for _ in range(count):
    length, = struct.unpack_from('<I', blob, at)
    at += 4
    name = blob[at:at + length].rstrip(b'\0').decode()
    at += length
    offset, size = struct.unpack_from('<QQ', blob, at)
    digest = blob[at + 16:at + 32]
    at += 32
    fileflags, = struct.unpack_from('<I', blob, at)
    at += 4
    assert base + offset + size <= len(blob), name
    data = blob[base + offset:base + offset + size]
    assert hashlib.md5(data).digest() == digest, name
    entries.append({'path': name, 'bytes': size, 'flags': fileflags})
groups = collections.Counter()
for entry in entries:
    name = entry['path']
    category = ('textures' if name.endswith('.ctex') else
                'scripts' if name.endswith(('.gdc', '.gd')) else
                'fonts' if name.endswith(('.ttf', '.otf', '.fontdata')) else 'other')
    groups[category] += entry['bytes']
report = {
    'sha256': hashlib.sha256(blob).hexdigest(),
    'bytes': len(blob), 'engine': [major, minor, patch], 'format': version,
    'flags': flags, 'files': count, 'payload_bytes': sum(e['bytes'] for e in entries),
    'categories': dict(groups),
    'largest': sorted(entries, key=lambda e: e['bytes'], reverse=True)[:25],
    'entries': entries,
}
args.output.write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({k: v for k, v in report.items() if k != 'entries'}, indent=2))
