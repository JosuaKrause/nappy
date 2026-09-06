---
name: python-tooling
description: Run or add repository Python tooling with uv and the project-local virtual environment.
---

# Python tooling

Use `uv` and the repository's `pyproject.toml` for Python tooling dependencies. The lockfile is
the reproducible record; do not add a second dependency list such as `requirements.txt` unless a
consumer specifically requires that format.

## Run a script

Run repository Python scripts through the locked environment:

```sh
uv run python tools/<script>.py
```

`uv run` creates or updates `.venv` from `pyproject.toml` and `uv.lock` as needed. Do not activate
the environment manually or install packages with bare `pip`.

## Add a tooling dependency

Add development-only tooling with `uv add --group dev <package>`, then commit both
`pyproject.toml` and `uv.lock`. Keep the runtime dependency list empty unless the game itself begins
to import Python at runtime.

If an external tool needs a requirements-format export, generate it from the lockfile for that
consumer instead of making it the hand-maintained source of truth.
