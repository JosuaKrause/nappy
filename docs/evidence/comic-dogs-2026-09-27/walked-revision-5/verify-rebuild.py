"""Rebuild all preview outputs in isolation and reject altered/missing inputs.

Usage: uv run python verify-rebuild.py
"""
from __future__ import annotations
import hashlib
import importlib.util
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]


def sha(p:Path)->str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def snapshot(root:Path)->dict[str,str]:
    return {p.relative_to(root).as_posix():sha(p) for p in root.rglob('*') if p.is_file()}


def main()->None:
    if len(sys.argv)!=1:raise SystemExit(__doc__)
    spec=importlib.util.spec_from_file_location('assembly',HERE/'assemble.py')
    recipe=importlib.util.module_from_spec(spec);spec.loader.exec_module(recipe)
    recipe.frozen()
    saved=json.loads((HERE/'revision-manifest.json').read_text())
    with tempfile.TemporaryDirectory(prefix='dog-three-poses-') as directory:
        root=Path(directory);target=root/HERE.relative_to(ROOT);target.mkdir(parents=True)
        for name in recipe.MANIFESTS:
            for item in json.loads((HERE/name).read_text())['inputs']:
                dest=root/item['path'];dest.parent.mkdir(parents=True,exist_ok=True)
                shutil.copy2(ROOT/item['path'],dest)
            shutil.copy2(HERE/name,target/name)
        shutil.copy2(HERE/'assemble.py',target/'assemble.py')
        command=[sys.executable,str(target/'assemble.py'),'build']
        subprocess.run(command,check=True,cwd=root)
        if saved!=json.loads((target/'revision-manifest.json').read_text()):
            raise SystemExit('isolated rebuild manifest differs')
        for path,digest in saved['outputs'].items():
            if sha(target/path)!=digest:raise SystemExit('isolated derivative differs: '+path)
        print(f"Isolated rebuild reproduces {len(saved['outputs'])} derivatives byte-for-byte.")
        probes=[target/'raw'/name for name in recipe.SELECTED.values()]
        probes.append(root/'art/events/dog_c.svg')
        for path in probes:
            original=path.read_bytes()
            for mode in ('changed','missing'):
                if mode=='changed':path.write_bytes(original+b'changed-input-probe')
                else:path.unlink()
                before=snapshot(root)
                result=subprocess.run(command,capture_output=True,text=True,cwd=root)
                if result.returncode==0 or 'frozen input changed or missing:' not in result.stderr:
                    raise SystemExit(f'{mode} input not explicitly rejected: {path.name}')
                if before!=snapshot(root):raise SystemExit('preflight wrote before refusing')
                path.write_bytes(original)
                print(f'{mode} {path.name}: refused before any write.')


if __name__=='__main__':main()
