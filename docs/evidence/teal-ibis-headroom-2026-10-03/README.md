# Peak disk allocation of worktrees, imports, Web builds and captures · 2026-10-03

**Question.** How much additional disk does each kind of batch the tools start take at its peak,
so that `tools/lib_disk_headroom.sh` can refuse a batch the volume has no room for without a
guessed threshold? And what does a browser run leave beyond its profile?

**Conclusion.** The estimates in `tools/lib_disk_headroom.sh` are the peaks below with the margin
each row states there. Only two jobs are large: a full worktree (about 1.08 GiB, against 24 MiB
sparse) and a Web-template build on a cache miss (about 2.7 GiB under `build/web-template-work/`,
removed on success). A recording grows with its length, about 9.5 MiB per recorded second of
the measured opening of day 1. Every other job measured is under 40 MiB. A headless Chrome on
macOS copies its own bundle (about 2.1 GiB allocated) at every launch unless that feature is
switched off, and removes the copy only after a graceful close.

## Method

`tools/measure-disk-peak.sh` ran each command while sampling `du -sk` of the paths the job
writes and `df -Pk` on their volume (every 0.25 to 0.5 seconds; every 5 seconds for the
template build). The figure used is the peak of the paths' summed allocation above their
baseline. `df` moved with every other process on the shared disk, including the other agents
working at the same time, so its drops are recorded but not attributed.

Environment: macOS 26.6.2 (arm64, 8 cores, 16 GiB), APFS data volume with about 70 GiB free,
Godot 4.7.2.stable.official.ed1daf0bf, Node 22.22.2, git 2.54.0, Google Chrome 154.0.8037.95.
The worktree, import, bake, debug export and capture runs used a detached worktree of
`475193055c04cb997535adab7ee4b5d0c7228c6a`; the template build and the release export ran in the
branch's own sparse worktree from `24c19b321e91e7eeaef6caf46a75522d052198ea`, before the build
script's preflight was added.

| Job | Command | Paths sampled | Peak additional | Result file |
|---|---|---|---:|---|
| Sparse worktree | `git worktree add --detach` from a sparse worktree, which inherits its exclusions | worktree, its admin directory | 24,416 KiB | `worktree-sparse.json` |
| Full worktree | `git sparse-checkout disable` on that worktree, materializing everything | the same | 1,106,556 KiB more (1,130,972 KiB in all) | `worktree-full-materialize.json` |
| Atlas bake | `tools/bake-atlases.sh` with no pages | `assets/atlases/baked`, `.godot` | 1,148 KiB | `atlas-bake.json` |
| Import | `tools/check.sh` after that bake | `.godot`, `assets/atlases/baked` | 1,004 KiB | `import.json` |
| Debug Web export | `tools/export-web.sh debug` | `build`, `.godot` | 39,624 KiB | `web-export-debug.json` |
| Release Web export | `tools/export-web.sh` on a checkout with no pages and no import | `build/web`, `.godot`, `assets/atlases/baked` | 33,076 KiB | `web-export-release.json` |
| Web-template build | `nice -n 15 tools/build-web-template.sh --jobs 3`, cache miss, 15 minutes | `build/web-template-work`, `build/web-template` | 2,832,532 KiB; 7,108 KiB retained | `web-template-build.json` |
| Ten recipes, headless | `tools/scene-recipes.sh --output DIR` | the output directory | 112 KiB | `scene-recipes-headless.json` |
| One recipe with its still | `tools/scene-recipes.sh --screenshots --recipe scene-recipes/trailer-city.json --output DIR` | the output directory | 436 KiB (still 419,463 bytes; its telemetry run 4 KiB) | `scene-capture-one.json` |
| Four-second recording | `TMPDIR=DIR tools/record.sh --out measure-4s.mp4 -- --seed 4242 --walk north --after 4` | that `TMPDIR`, `build/records` | 39,176 KiB for 242 frames and the WAV | `record-4s.json` |

A sparse worktree's tracked files were also summed from `git ls-tree -r -l` on 4 KiB blocks:
22,860 KiB sparse and 1,128,768 KiB full, matching the measured checkouts.

## Browser scratch

Four probe launches of the installed Chrome with `--headless=new`, each with its own temporary
profile, while listing the per-user `X/com.google.Chrome.code_sign_clone/` directory: one stopped
with `SIGTERM`, one closed with the debugging protocol's `Browser.close`, one closed the same way
with `--disable-features=MacAppCodeSignClone`, and one stopped with `SIGKILL`.

- Each of the three launches without the feature switch made a new `code_sign_clone.XXXXXX`
  directory; the first measured 2,198,548 KiB allocated by `du`.
- In the `Browser.close` launch, `lsof -p` on the browser listed the clone's own executable as a
  `txt` mapping 1.5 seconds after startup, the evidence `browser-scratch.mjs` attributes a clone
  by; in the `SIGKILL` launch it had not appeared yet at that moment, which is why the harness
  looks repeatedly while the browser runs.
- `Browser.close` removed the clone within a second of the browser's exit; `SIGTERM` and
  `SIGKILL` each left it in place.
- With the feature switch no clone was made.

`browser-check-release-scratch.json` is the harness's own report from a full passing run against
the release export above, with those changes: the browser closed through the protocol, no clone
was made, nothing was removed or left.

## Limits

`du` counts allocated blocks, including copy-on-write blocks shared with other files, so each
figure is an upper bound on what the job takes from the volume, not space its removal returns.
A sampling interval can miss a peak between two samples, most of all the template build's five
seconds and its link step's temporary files outside the work directory; its estimate carries the
larger margin for that. A recording's frames vary with what is on screen: the measured four
seconds were the quiet opening of day 1, about 160 KiB a frame, while a busy city still is
410 KiB, so the estimate uses 512 KiB a frame. The import is small because the game draws most
of its art at run time from baked atlas pages. These are single runs on one machine.

## Rerun

From a checkout of the revision under test, each into fresh scratch paths:

```sh
tools/measure-disk-peak.sh --output /tmp/new-run/export.json --path build --path .godot \
  -- tools/export-web.sh debug
tools/measure-disk-peak.sh --interval 5 --output /tmp/new-run/template.json \
  --path build/web-template-work --path build/web-template -- tools/build-web-template.sh
```

The other rows follow the same shape with the command and paths in the table.
