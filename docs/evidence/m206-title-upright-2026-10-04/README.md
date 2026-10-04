# M206, the screen after a game over or a held restart on a portrait phone, 2026-10-04

**Question.** After a lost run's GAME OVER and its continue, and after a held restart from a day
summary, is the next screen drawn the wrong way up on a portrait phone, for how long, and why?
*(PLAYTEST-140, statement 5: "when you lose with game over the title screen is sideways";
PLAYTEST-144, statement 26, the player's still captioned "This is the screen when resetting".)*

**Answer.** Yes, both, and by one cause. Both paths end in `main._restart_run()`, which reloads the
scene. The root window survives `reload_current_scene()`, and so does the `content_scale_size` the
previous boot left: the rotated 720x1280 box. The new boot's first frames are the two
`_warm_the_canvas_shaders()` awaits, drawn through the boot camera before she exists, and the
boot camera was never turned: the city at the doorstep is drawn upright, filling the portrait
screen. That frame then stays on screen while the rest of `_ready()` runs (`_start_day()` alone is
1.6-2.5 s in these runs) until the title is drawn the right way up. On the released page that was
1.8 s after a held restart and 2.0 s after GAME OVER in desktop Chrome; a phone is slower. The
frames match the player's still: the home's front, upright, no title.

A first page load is not affected in practice: the page's own splash covers the canvas until the
boot has finished (`released-v0.23.0-first-boot.jpg`, the first frame past the splash is the
turned title).

**The fix** (`src/main.gd`): `_apply_orientation()` turns the window's box, the boot camera and
every layer already built before anything else exists, and `_new_boot_camera()` calls it before
the camera enters the tree. After it, the same frames show the city turned the same way as the
title they precede (`after-*.jpg`).

## Pictures

Each strip is four consecutive screencast frames around the reload, with their times from the
start of the recording: the screen the restart came from, the two warm-up frames, and the title.

- `released-v0.23.0-held-restart.jpg`, `released-v0.23.0-game-over.jpg`: the released page.
- `before-held-restart.jpg`, `before-game-over.jpg`: a local release export of the code before the
  fix. Same result as the released page.
- `after-held-restart.jpg`, `after-game-over.jpg`: a local release export with the fix.
- `released-v0.23.0-first-boot.jpg`: a fresh page load.

The `DEBUG MODE ON` line in the top-left corner is drawn unturned in every frame, before and after
the fix; it exists only under `?debug=1` and is outside this change.

## Results

Times are from the screencast's own frame timestamps (`runs/*/frames.json`). "Wrong way up" is
from the first warm-up frame to the first title frame; Chrome sends no frame while the page draws
nothing new, so the last warm-up frame is what is on screen for that whole interval.

| run | build | first warm-up frame | title | wrong way up |
|---|---|---|---|---|
| released held restart | v0.23.0 (released page) | 1640 ms | 3450 ms | 1.81 s |
| released game over | v0.23.0 (released page) | 6637 ms | 8606 ms | 1.97 s |
| before held restart | local release export, before | 1684 ms | 3480 ms | 1.80 s |
| before game over | local release export, before | 4851 ms | 6730 ms | 1.88 s |
| after held restart | local release export, after | 1891 ms | 4074 ms | none (turned) |
| after game over | local release export, after | 4956 ms | 6999 ms | none (turned) |

Frame indices in the strips (`strip.py`'s arguments): released held restart 19-22, released game
over 56-59, before held restart 26-29, after held restart 22-25, before game over 83-86, after
game over 76-79, first boot 1-2.

## How it was run

`repro.mjs` drives headless Chrome through CDP with a phone emulated: 412x915 CSS px, portrait,
`mobile`, touch emulation on (`'ontouchstart' in window` is true, which is what the game's touch
check reads). A held restart: `?debug=1&meters=0,99.9` (the excitement meter starts nearly full),
start, walk south until the day is lost, then a touch held for 1.8 s on the summary's restart disc.
A game over: `?debug=1&daylength=4`, start, and five tries of day 1 each timing out, one nerve
each, then continue to GAME OVER and past it. The local runs of the held restart carry
`&seed=4242422869`, because a random seed's day did not always end within the walk.

- Chrome 154.0.8037.95 (`--headless=new`, SwiftShader WebGL), macOS 26.6.2, Node 22.22.2.
- Released page: https://nappy.josuakrause.com/, v0.23.0 (`338eae50`).
- Local exports: `tools/export-web.sh` (release, the pinned custom template built by
  `tools/build-web-template.sh`). "Before" is `src/` and `tests/` checked out from `e904eb17`
  on top of the fix commit `c7dca923`, so its stamp reads `v0.23.0-3-gc7dca923-dirty`; "after"
  is `c7dca923`.

Rerun, from a checkout of the commit to test, into fresh scratch folders:

```sh
tools/build-web-template.sh && tools/export-web.sh && cp -R build/web /tmp/web-under-test
E=docs/evidence/m206-title-upright-2026-10-04
node $E/repro.mjs --export /tmp/web-under-test --scenario restart \
    --query '?debug=1&meters=0,99.9&seed=4242422869' --output /tmp/m206-restart
node $E/repro.mjs --export /tmp/web-under-test --scenario gameover --output /tmp/m206-gameover
node $E/repro.mjs --url https://nappy.josuakrause.com/ --scenario restart --output /tmp/m206-released
python3 $E/strip.py out.jpg /tmp/m206-restart <i>:caption ...   # Pillow
```

`--browser` names another Chrome executable. The run's frames are written under `frames/` of the
output folder, with `frames.json` (each frame's time) and `run.log` (the console and every step).

## Limits

Desktop Chrome emulating a phone, not a phone. The phone's own timing is longer, not different in
kind: the frames are held for as long as `_ready()` runs after the warm-up, and that is slower on a
phone. The player's own report of how long it lasted is not on record. One run of each scenario
per build; the cause is deterministic (every reload in a portrait touch window), and every run of
the six showed it or its absence as expected. Attempts that never reached the reload are harness
failures, not results, and are not kept: a random seed's day that was not lost within the walk
(why the local held restarts fix the seed; the released run is unseeded and may need a second
try), five page reloads during a day that did not spend the nerves they were meant to, and a first
game-over script whose presses fell out of step with the screens.

While building the game-over run, the GAME OVER screen restarted the run on its own each of the
two times a `Page.captureScreenshot` was taken while it was showing; `repro.mjs` no longer takes
one there. Not investigated: it may be the headless capture's own focus or input side effects.
