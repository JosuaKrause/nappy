## Tooling audit: Python 3.14, ruff, mypy, and links that outlive a branch — 2026-09-09

Three things asked for in one turn: *"take a note that using branch names in pr descriptions will
lead to stale links (eg for images etc). need to do something else. beyond that do a full audit of
the codebase. also update python to 3.14 and set up ruff and mypy"*.

**The note became a rule in the committing skill.** Every merged PR up to this point embedded its
before-and-after screenshots by branch URL — `blob/feature/<thing>/…?raw=true` or the
`raw.githubusercontent.com/…/feature/<thing>/…` form — and the workflow deletes every branch on
merge, so all of those images are already 404s. The rule is to link by full commit hash, which
survives because `main` merges `--no-ff` and every branch commit stays reachable from the merge
commit. Uploading as a GitHub attachment was considered and kept as the by-hand fallback only: `gh`
cannot do it.

**Python.** `requires-python` and `.python-version` are 3.14; `uv` downloads the interpreter. `ruff`
and `mypy --strict` are dev dependencies, configured in `pyproject.toml`, and `tools/pycheck.sh`
runs them with the two `unittest` files; CI runs that script through `astral-sh/setup-uv` instead
of calling `tools/test_codex_hooks.py` with the runner's own `python3`. `tools/test_clip.py` had
never run in CI before this. PyYAML was a declared dev dependency nothing imported, and was dropped.
The strict pass found two real things and a library gap: `remove-checkerboard.py` read pixels
through `Image.load()`, whose result is typed as possibly `None` and whose element type is a union,
and now walks the raw byte plane; `reference.py` used `Image.LANCZOS`, which Pillow's stubs no
longer declare, and now names `Image.Resampling.LANCZOS`; and `pillow_heif` re-exports its public
API without an `__all__`, which is a one-module `implicit_reexport` override with the reason beside
it. `tools/codex-hooks.py` is the one script that does not run under `uv` — Codex invokes it with
the host's `python3` — so it stays 3.9-compatible and ruff's `per-file-target-version` pins it
there; it was run under the system 3.9 and 3.11 to confirm. Pillow moved from the `<12` pin to
`>=12.3`, because the repository carried ten open Dependabot alerts against the locked 11.3, every
one fixed in 12.3.0; the bump cost two more typing fixes in the same two scripts.

**The audit.** The full suite, the boot check, the doc lint and `shellcheck` on every shell script
were the baseline, all green; `shellcheck` found one unguarded `cd` in `release.sh` and one
malformed directive in `test.sh` whose trailing prose stopped the directive parsing. What the
sweep found and fixed on the branch: `AGENTS.md` had been consolidated into `CLAUDE.md` on 2026-09-06
and `README.md` and `HANDOFF.md` still named it as Codex's entry point; `docs/ARCHITECTURE.md`'s
directory tree omitted sixteen scripts under `src/` (among them `main.gd`, `seal_planner.gd`, the
traffic signals, the whole of `src/visuals/`), three scenes, three asset folders and most of
`tools/`, and filed `game_enums.gd` under `assets/`; the reference-photos skill cited an evidence
screenshot that does not exist; and `test.sh`'s shard cost table was refreshed from the run. What
it found and left for a decision: the halo's five-second landed history in `CrowdAgent` and
`EventInstance` is keyed on `Time.get_ticks_msec()`, so a pause longer than five seconds empties
every halo and a rig is measured on wall clock rather than simulated time; a local branch
(`feature/normal-density-on-the-path`) whose probe commits were re-landed by another PR and that
`git branch -d` refuses; a stray `refs/remotes/shared-main` with no remote behind it; a stash from
a long-merged branch; an orphaned agent checkout under `.claude/worktrees/` pointing at a `.git`
in a different clone; and four assets nothing references (`icon_stroller.svg`,
`icon_stroller_640.png`, `logo.svg`, `illustrated/modular/mother-pram-contact-v2.png`). No global
RNG call, no missing preload path, no duplicate `class_name` and no stray `print` outside the
bracketed boot diagnostics were found.

**What the player decided on the leftovers, the same day.** *("let's use simulation time not wall
time. remove the stale branch since its functionality has been merged. remove shared-main not sure
what that is for. fix the orphaned folders. the unreferenced assets are used for social media
headers etc. and as reference of a previous version (v2).")* The stale branch went with
`git branch -D`, the stray ref with `git update-ref -d`, and the orphaned checkout was deleted and
`git worktree prune` run; the stash was left. The four assets are kept and now say what they are
for: `ARCHITECTURE.md`'s tree names the logo, icon and social-card files as the README header,
the published social card and the store and social-media headers, loaded by nothing in the game;
`assets/illustrated/modular/README.md` names `mother-pram-contact-v2.png` as the previous version's
contact sheet kept as reference. The halo's history moved to simulation time; the record is the
entry above this one.
