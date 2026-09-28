"""Rebuild in an isolated temporary tree and exercise preflight's refusal before writes.

Usage: uv run python verify-rebuild.py
"""
from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    if len(sys.argv) != 1:
        raise SystemExit(__doc__)
    saved = json.loads((HERE / 'revision-manifest.json').read_text())
    with tempfile.TemporaryDirectory(prefix='dog-fixed-joints-') as temporary:
        copy_root = Path(temporary)
        target = copy_root / HERE.relative_to(ROOT)
        target.mkdir(parents=True)
        # Copy only immutable dependencies and the saved build recipe: no derivatives.
        for manifest_name in ('input-manifest.json', 'refinement-input-manifest.json'):
            manifest = json.loads((HERE / manifest_name).read_text())
            for item in manifest['inputs']:
                source = ROOT / item['path']
                destination = copy_root / item['path']
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, destination)
            shutil.copy2(HERE / manifest_name, target / manifest_name)
        shutil.copy2(HERE / 'assemble.py', target / 'assemble.py')
        command = [sys.executable, str(target / 'assemble.py'), 'build']
        subprocess.run(command, check=True, cwd=copy_root)
        rebuilt = json.loads((target / 'revision-manifest.json').read_text())
        if saved != rebuilt:
            raise SystemExit('isolated rebuild differs from the saved output manifest')
        for relative, expected in saved['outputs'].items():
            if digest(target / relative) != expected:
                raise SystemExit(f'isolated derivative differs: {relative}')
        print(f"isolated rebuild reproduced {len(saved['outputs'])} derivatives byte-for-byte")
        selected = target / 'raw/dog_front_diagonal_b-from-a.png'
        selected.write_bytes(selected.read_bytes() + b'changed-input-guard-probe')
        before = {p.relative_to(target): digest(p) for p in target.rglob('*') if p.is_file()}
        result = subprocess.run(command, capture_output=True, text=True, cwd=copy_root)
        after = {p.relative_to(target): digest(p) for p in target.rglob('*') if p.is_file()}
        if result.returncode == 0 or 'frozen input changed or missing:' not in result.stderr:
            raise SystemExit('changed selected raw was not explicitly rejected')
        if before != after:
            raise SystemExit('changed-input preflight wrote a file before refusing')
        print('altered selected raw rejected before any file write')


if __name__ == '__main__':
    main()
