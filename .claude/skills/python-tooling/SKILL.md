---
name: python-tooling
description: Run, check or add repository Python tooling with uv and the project-local virtual environment — Python 3.14, ruff, mypy, and the one gate that runs them. Load this BEFORE touching tools/*.py, pyproject.toml or uv.lock.
---

# Python tooling

Use `uv` and the repository's `pyproject.toml` for Python tooling dependencies. The lockfile is
the reproducible record; do not add a second dependency list such as `requirements.txt` unless a
consumer specifically requires that format.

**The interpreter is Python 3.14**, pinned by `.python-version` and `requires-python`. `uv` downloads
it on first use, so nothing about the host's own Python matters to the tooling.

## Run a script

Run repository Python scripts through the locked environment:

```sh
uv run python tools/<script>.py
```

`uv run` creates or updates `.venv` from `pyproject.toml` and `uv.lock` as needed. Do not activate
the environment manually or install packages with bare `pip`.

## Check it

`tools/pycheck.sh` is the gate for everything under `tools/*.py`, and CI runs it on every push and
pull request. In order: `ruff check`, `ruff format --check`, `mypy` (strict), then every
`tools/test_*.py` `unittest` file. `tools/pycheck.sh --fix` lets ruff rewrite imports and formatting first.

**Run it before committing anything that touches `tools/*.py`, `pyproject.toml` or `uv.lock`.** A
hit is a stop, the same as `lint.sh`'s.

The configuration lives in `pyproject.toml` under `[tool.ruff]` and `[tool.mypy]`. `mypy` is strict
on purpose: a typed `tools/` is the only place in this repository where a wrong type is caught
before it runs, since GDScript's checks are the engine's and shell has none. Where a library's own
typing is the problem, say so beside the override rather than loosening the whole check.

## The hook adapter is the one exception

`tools/codex-hooks.py` is checked like everything else, but Codex runs it with the host's own
`python3` from `.codex/hooks.json`, not through `uv`. So it stays **3.9-compatible** —
`typing.Optional` rather than `X | None`, nothing newer than what `CLAUDE.md`'s "Python 3.9+" line
promises — and `pyproject.toml` pins ruff's per-file target for it so `UP` rules do not modernise it
past that. Nothing in the gate proves the compatibility; run the hook once under an older
interpreter when you change it:

```sh
echo '{"hook_event_name":"SessionStart","session_id":"x","cwd":"'"$PWD"'"}' | /usr/bin/python3 tools/codex-hooks.py
```

## Add a tooling dependency

Add development-only tooling with `uv add --group dev <package>`, then commit both
`pyproject.toml` and `uv.lock`. Keep the runtime dependency list empty unless the game itself begins
to import Python at runtime. **A dependency nothing imports is removed**, since the lockfile is the
list a fresh checkout installs and every unused package there is a download nobody asked for.

If an external tool needs a requirements-format export, generate it from the lockfile for that
consumer instead of making it the hand-maintained source of truth.
