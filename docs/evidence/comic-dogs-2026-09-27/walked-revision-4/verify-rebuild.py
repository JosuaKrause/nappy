"""Rebuild in isolation; reject each missing/changed selected raw before writes.

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


def snapshot(root: Path) -> dict[str, str]:
    return {p.relative_to(root).as_posix():digest(p) for p in root.rglob('*') if p.is_file()}


def main() -> None:
    if len(sys.argv) != 1:
        raise SystemExit(__doc__)
    saved = json.loads((HERE/'revision-manifest.json').read_text())
    with tempfile.TemporaryDirectory(prefix='dog-leg-geometry-') as temporary:
        copy_root = Path(temporary)
        target = copy_root/HERE.relative_to(ROOT)
        target.mkdir(parents=True)
        for manifest_name in ('input-manifest.json','diagonal-input-manifest.json'):
            for item in json.loads((HERE/manifest_name).read_text())['inputs']:
                source = ROOT/item['path']
                dest = copy_root/item['path']
                dest.parent.mkdir(parents=True,exist_ok=True)
                shutil.copy2(source,dest)
            shutil.copy2(HERE/manifest_name,target/manifest_name)
        shutil.copy2(HERE/'assemble.py',target/'assemble.py')
        command = [sys.executable,str(target/'assemble.py'),'build']
        subprocess.run(command,check=True,cwd=copy_root)
        if saved != json.loads((target/'revision-manifest.json').read_text()):
            raise SystemExit('isolated rebuild manifest differs')
        for relative,expected in saved['outputs'].items():
            if digest(target/relative) != expected:
                raise SystemExit(f'isolated rebuild differs: {relative}')
        print(f"Isolated rebuild reproduced {len(saved['outputs'])} derivatives byte-for-byte.")
        for name in ('dog_b','dog_front_diagonal_b','dog_back_diagonal_b'):
            path = target/'raw'/f'{name}.png'
            original = path.read_bytes()
            for mode in ('changed','missing'):
                if mode == 'changed':
                    path.write_bytes(original+b'altered-selected-raw-probe')
                else:
                    path.unlink()
                before = snapshot(copy_root)
                result = subprocess.run(command,capture_output=True,text=True,cwd=copy_root)
                if result.returncode == 0 or 'frozen input changed or missing:' not in result.stderr:
                    raise SystemExit(f'{mode} selected raw was not explicitly rejected: {name}')
                if before != snapshot(copy_root):
                    raise SystemExit(f'{mode} selected raw caused writes before refusal: {name}')
                path.write_bytes(original)
                print(f'{mode} {name} refused before any output write.')


if __name__ == '__main__':
    main()
