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

`tools/pycheck.sh` is the gate for everything under `tools/*.py`, and CI runs it on pushes to
`main` and on pull requests. In order: `ruff check`, `ruff format --check`, `mypy` (strict), then
the `unittest` files listed in `pycheck.sh`; a new one is added there. `tools/pycheck.sh --fix`
lets ruff rewrite imports and formatting first.

**Run it before committing anything that touches `tools/*.py`, `pyproject.toml` or `uv.lock`.** A
hit is a stop, the same as `lint.sh`'s.

The configuration lives in `pyproject.toml` under `[tool.ruff]` and `[tool.mypy]`. `mypy` is strict
on purpose: a typed `tools/` is the only place in this repository where a wrong type is caught
before it runs, since GDScript's checks are the engine's and shell has none. Where a library's own
typing is the problem, say so beside the override rather than loosening the whole check.

## Two scripts run on the host's own Python

`tools/codex-hooks.py` and `tools/check_citations.py` are checked like everything else, but neither
runs through `uv`: Codex runs the hook adapter with the host's own `python3` from
`.codex/hooks.json`, and `tools/lint.sh` runs the citation check with it, since CI lints before it
installs uv. So both stay **3.9-compatible**, nothing newer than what `CLAUDE.md`'s "Python 3.9+"
line promises. `X | None` is 3.10's, so it is `typing.Optional` instead, everywhere in a file
without `from __future__ import annotations` (`tools/codex-hooks.py`); only a file with that import
(`tools/check_citations.py`) may write `X | None` in an annotation, which the import leaves
unevaluated, and never outside one. Builtin generics such as `dict[str, Any]` are 3.9's and fine
anywhere. And `pyproject.toml` pins ruff's per-file target for each so `UP` rules do not modernise
them past that. Nothing in the gate proves the compatibility; run each once under an older
interpreter when you change it (`/usr/bin/python3 tools/test_check_citations.py` for the citation
check):

```sh
echo '{"hook_event_name":"SessionStart","session_id":"x","cwd":"'"$PWD"'"}' | /usr/bin/python3 tools/codex-hooks.py
```

**A change to a hook does not update the Codex adapter while Codex support is frozen** (inbox #901 in freckled-moose).
The rule that a hook change checks `tools/codex-hooks.py`, `.codex/hooks.json` and
`tools/test_codex_hooks.py` and updates them in the same PR (brisk-heron 6) is lifted until Codex
works here again, so the adapter may lag; the pull request that brings Codex back brings them up to
date (`CLAUDE.md`, "Codex integration is frozen").

## Add a tooling dependency

Add development-only tooling with `uv add --group dev <package>`, then commit both
`pyproject.toml` and `uv.lock`. Keep the runtime dependency list empty unless the game itself begins
to import Python at runtime. **A dependency nothing imports is removed**, since the lockfile is the
list a fresh checkout installs and every unused package there is a download nobody asked for.

**PyYAML is the deliberate exception.** Nothing in the repository imports it; Codex's external
`skill-creator/scripts/quick_validate.py` imports it when validating `.claude/skills/`. Keep it in
the development group so that validator runs through the locked Python 3.14 environment rather
than depending on whichever packages the host Python happens to have.

If an external tool needs a requirements-format export, generate it from the lockfile for that
consumer instead of making it the hand-maintained source of truth.
