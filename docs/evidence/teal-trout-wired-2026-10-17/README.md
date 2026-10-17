# teal-trout — the chargers' stages, wired (2026-10-17)

**The claim.** In the game, three chargers each show three pictures for their three stages, and
the two that warn standing still do not move while they warn: the charging dog sits while it
waits, stands in its alert for its notice and gallops when it charges; the hunting roadblock's
guard stands at his post, then raises his hand there for his notice, then lunges; the alley robber
waits hood up, walks at her slowly in his two-frame alert (hands out of his coat) through his
notice, then lunges. It is the
evidence for teal-trout, *every charger is neutral, then warns, then charges*, with the player's
answers on inbox #748 ("robber can walk towards her but guards should lift their hand in
warning"; "nobody walks -- only the robber") and inbox #761 ("we can increase the noticing if the
robber starts walking slowly").

**Not shown.** The door guard: nothing can time her walk under a boom while a car holds it up, as
the [audit](../teal-trout-2026-10-11/README.md) found; his stages are pinned by
`tests/test_event_views.gd` instead. Any crowd or other event: each recipe installs the one charger on a calm street.

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
- [strip-robber-v2.png](strip-robber-v2.png), from [recipes/robber-v2.json](recipes/robber-v2.json),
  day 8, recorded at commit `ac5a834f2fddb885390602c0673baa0c3b34b372`: the robber as built, noticing
  her at 180px and walking at her at 40px/s through his notice in two alternating alert frames.
  Waiting at 1.05s; she steps inside his trigger and stops, and his alert walk runs from about 1.15s
  to about 2.55s, about 1.4s, the panels at 1.40s and 1.70s showing his two frames; lunging from
  about 2.55s. Walking in rather than stopping, his walk lasts about half a second
  (`tests/test_events_pursuit.gd` prints 0.48s).
- [strip-robber.png](strip-robber.png), from [recipes/robber.json](recipes/robber.json), day 8: the
  wiring commit's robber, before the slow walk and the second frame, kept as the measure of what
  they changed. Waiting; his alert from about 1.23s; lunging from about 1.38s, so his alert lasts about 0.15s.
  It is that short because he walks at her at 130px/s and lunges the moment the gap is down to his
  116px stand-off, and the recipe stops her just inside his 140px trigger: about 19px for him to
  close alone. Standing at the very edge of the trigger it would be about 0.18s (24px at 130px/s);
  walking in at 92px/s, about a tenth of a second (24px at 130 + 92px/s).

## How they were made

**Source.** Recorded at commit `cd48e60ff62c968f56c8038c1a806acf572105b9` (this branch's wiring
commit; `strip-robber-v2.png` at the commit named beside it), with no tracked file changed, Godot 4.7.2, 1280x720, 60 frames a second, frame-locked by
the movie writer, so a time in a strip is game time.

**Recipes.** `robber.json` is the audit's recipe unchanged. `robber-v2.json` is it with only
`name`, her start (430 rather than 400, so she starts outside his 180px trigger),
`playback.walk` (`1p0.2n4p`, a step inside it and a stop) and `playback.duration` (5.2) changed. `dog.json` and `roadblock.json` are the
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
nearest-neighbour for the dog and the robber, and stacked; for `strip-robber-v2.png`, the frames
at 1.05, 1.40, 1.70, 2.20, 2.45 and 2.70s cropped to 200x480 at (540, 20), scaled 2x
nearest-neighbour and labelled with Pillow.

**Retained**: the four strips, the four recipes, and each recording's own `settings.json` and
`manifest.json` under `provenance/<name>/`. The clips and the movie writer's frames stay in
scratch: the strips carry the stages, and the dog's and the guard's standing still is the same
place in two frames a second or more apart.

**Limits.** One staging per charger. Under `--invincible`, after a catch she is no longer drawn
(seen in the audit too; not investigated). The dog's rest and alert are the SVG pictures beside the
gallop's comic transfer, a change of style the player is judging in the game.
