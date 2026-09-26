## M193 — The live page's ?debug=1 reaches the debug flags · built 2026-09-25

*([PLAYTEST-130](../playtests/PLAYTEST-130.md): "on the published site behind debug=1 we'd want some
of the debug flags (like day, invincible, etc.) so debugging the live build is easier".)* **Asked
for no modifiers on a release (2026-09-06: "for release there should be no modifiers") ·
overturned on 2026-09-25 to the sentence above**, for the bundle below and nothing else.

**What is built.** `DevFlags.live_debug_requested()` in `src/dev/dev_flags.gd` holds on a debug
build or on a release page carrying `?debug=1`, and it gates the page's query string for a
debugging bundle: `?day=N`, `?invincible=1`, `?layers=`, `?controls=`, `?escape=1`,
`?meters=S,E`, `?daylength=N`, `?ending=bad|neutral|good` and `?blackout=1`. A debug web build
answers the same words without `?debug=1`. The command line keeps its own `enabled()` gate and
takes precedence. `main.gd` builds the debug layers and the route lines under `_debug or
_readout_requested`, so `?layers=` on a release page has something to draw; the `1`–`5` keys that
toggle a layer by hand stay debug-build only.

**A run that uses any word of the bundle never reads or writes the save** — the entry's own test,
"a visitor who tries `?day=12` does not lose their own day 3". `GameSave.uses_save()` asks
`DevFlags.web_debug_flag_used()`, which answers whether the page named one of those words, on a
release page behind `?debug=1` and on a debug web build alike, since a web page has no command line
for `active_args()` to see. `?debug=1` alone opens the bundle without using it, so it keeps the
save. The debug web build's half was added at review: the agent's first version checked only the
release page, and `?day=9` on a debug web build wrote the save.

**Left closed, open to overturn:** `--spawn`, `--follow`, `--route` and `--force`, which name a
position or an event off the live city; `--overview` and `--zoom`, a rig's camera; everything that
drives input, takes a picture or writes a file (`--screenshot`, `--after`, `--walk`, `--flee`,
`--press`, `--tap`, `--quit-when-still`, `--frame-trace`, `--spikes`); the capture and window
flags (`--touch`, `--web`, `--title`, `--no-title`, `--no-focus-pause`, `--no-save`); and
`--start-escape`'s interior-part word, so `?escape=1` always starts at the escape's first part.
The query words (`daylength` rather than `day-length`) were chosen to match `seed`, `skip` and
`debug`.

**Verified** with `./tools/check.sh`, `./tools/lint.sh`, every suite that reads `DevFlags`,
`GameSave` or `main.gd`, and the full suite on the branch. A release export (`tools/export-web.sh`)
driven in Chrome: `?debug=1&day=9` started day 9 with the readout; `?day=9` alone gave the ordinary
title screen; `?debug=1&day=9&invincible=1&layers=3` drew the bodies layer and held the clock.
