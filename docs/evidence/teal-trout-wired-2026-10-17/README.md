# teal-trout — the chargers' stages, wired (2026-10-17)

**The claim.** In the game, three chargers each show three pictures for their three stages, and
the two that warn standing still do not move while they warn: the charging dog sits while it
waits, stands in its alert for its notice and gallops when it charges; the hunting roadblock's
guard stands at his post, then raises his hand there for his notice, then lunges; the alley robber
waits hood up, takes his alert (hands out of his coat) as he walks at her, then lunges. It is the
evidence for teal-trout, *every charger is neutral, then warns, then charges*, with the player's
answers on inbox #748 ("robber can walk towards her but guards should lift their hand in
warning"; "nobody walks -- only the robber").

**Not shown.** The door guard: nothing can time her walk under a boom while a car holds it up, as
the [audit](../teal-trout-2026-10-11/README.md) found; his stages are pinned by
`tests/test_event_views.gd` instead. The robber's second walk frame, which is drawn on PR #750 and
not wired here. Any crowd or other event: each recipe installs the one charger on a calm street.

## The strips

Each strip is cut from a frame-locked recording of its recipe at the labelled time into the clip.

- [strip-dog.png](strip-dog.png), from [recipes/dog.json](recipes/dog.json), day 5. Sitting until
  she walks inside its 130px trigger at about 2s; its alert, still and in the same place, until its
  4.5s notice runs out with her standing about 110px away, outside its 104px stand-off; the gallop
  from about 6.6s.
- [strip-roadblock.png](strip-roadblock.png), from [recipes/roadblock.json](recipes/roadblock.json),
  day 7, heat 4. Posted until she is inside 180px of the band's centre at about 2.3s; his hand
  raised at his post, in the same place at 2.6s and 3.5s, through his 1.8s notice; lunging once it
  runs out.
- [strip-robber.png](strip-robber.png), from [recipes/robber.json](recipes/robber.json), day 8.
  Waiting; his alert from about 1.23s; lunging from about 1.38s. His alert lasts that short a time
  because he walks at her and lunges the moment the gap is down to his 116px stand-off: she walks
  in at 92px/s while he comes at 130px/s, so 24px of trigger beyond his stand-off is gone in about
  a tenth of a second.

## How they were made

**Source.** Recorded at commit `cd48e60ff62c968f56c8038c1a806acf572105b9` (this branch's wiring
commit), with no tracked file changed, Godot 4.7.2, 1280x720, 60 frames a second, frame-locked by
the movie writer, so a time in a strip is game time.

**Recipes.** `robber.json` is the audit's recipe unchanged. `dog.json` and `roadblock.json` are the
audit's with only `name`, `playback.walk` and `playback.duration` changed, so she stops inside the
trigger and stays there for the whole notice instead of walking on into the stand-off, which in the
audit's staging cut the warning short: `1p1.25w6p` for 8 seconds, and `1p1.3s4p` for 7 seconds.
Sites, seeds and camera are the audit's.

**Command**, for each recipe, from the repository root:

```sh
tools/record.sh --out teal-wired2-<name>.mp4 -- \
    --recipe "$PWD/docs/evidence/teal-trout-wired-2026-10-17/recipes/<name>.json" \
    --invincible --after <the recipe's playback.duration plus 1.5>
```

then each strip frame with `ffmpeg -ss <time> -i <clip> -frames:v 1 -vf crop=...`, scaled 2x with
nearest-neighbour for the dog and the robber, and stacked.

**Retained**: the three strips, the three recipes, and each recording's own `settings.json` and
`manifest.json` under `provenance/<name>/`. The clips and the movie writer's frames stay in
scratch: the strips carry the stages, and the dog's and the guard's standing still is the same
place in two frames a second or more apart.

**Limits.** One staging per charger. Under `--invincible`, after a catch she is no longer drawn
(seen in the audit too; not investigated). The dog's rest and alert are the SVG pictures beside the
gallop's comic transfer, a change of style the player is judging in the game.
