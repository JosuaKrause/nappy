## M71 — A push is a check, a tag is a release · built 2026-09-03

*(2026-09-03: "let's not deploy on every push. push is for ci checks only. tag push triggers a
deploy… that way we don't have to reason about what the next version is", and "we start with the
current origin/main as v0.0.0", and "your choice whether semantic or not. if semantic major is
reserved for game breaking/fundamental changes".)*

`deploy.yml` fires on `v*` tags instead of pushes to `main`; `ci.yml` keeps no branch or tag filter,
so a push is a check. **The deploy keeps re-running the whole gate itself** rather than trusting CI,
for the reason its own comment already gave — both workflows fire on the same push and neither waits
for the other — plus a new one: a tag can point at any commit.

`tools/release.sh <major|minor|patch>` reads the latest version tag, bumps it and pushes the next.
**Read loosely, write strictly:** a bare `v123` is understood as `v123.0.0` and what it writes is
always `vMAJOR.MINOR.PATCH`, so the shape converges after one release; with no tag at all it starts
at `v0.0.0`. Semver, with **major reserved for a change that breaks or fundamentally alters the
game**.

**Confirmation is a second literal `push` argument rather than an interactive prompt**, matching
`telemetry.sh -p`, because a script that blocks on a TTY cannot be driven from a rig or proven from a
transcript. Every refusal — dirty tree, any branch but `main`, a `main` not level with `origin/main`
— fires in the dry run too, so the dry run tells the truth about whether the real thing would work.

**A correction to the brief, worth keeping because it is the kind of thing that reads as equivalent
and is not:** `git describe --dirty` cannot replace the existing `git status --porcelain` check.
`--dirty` inspects tracked files only, via `git diff-index`, so a tree with untracked files present
still describes as clean. The porcelain check stays, preserving the documented guarantee that
untracked files count as dirty.

`git describe --tags --always` replaces the bare hash in both places that write one —
`Telemetry.source_version()` and `tools/telemetry.sh`'s `HEAD_COMMIT` — and they had to move together
or `-p` would call every run stale. Run folder names get longer, which is the cost of a name that
says which release a run belongs to.

**The version artifact is Godot's own mechanism** rather than a file shipped beside `index.html`:
`application/config/version` in `project.godot`, overwritten by CI from the tag name before the
export runs and baked into the build. The title screen prefers git where git answers and falls back
to the setting where it does not, so a developer sees `v0.0.0-53-g9077bc9-dirty` and a player sees
the release.
