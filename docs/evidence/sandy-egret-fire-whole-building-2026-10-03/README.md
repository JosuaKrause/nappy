# Day 3's fire along the whole building's front

**Claim.** The day-3 fire (`burning_building`) burns along the whole front of the building it
caught on, every column of the facade, rather than five flames around its site. The sidewalk in
front stays clear, and the fire engine called in on sight still parks at the kerb in front of it.
The player, sandy-egret: *"the fire should be on the whole building not only the door"*.

**Stills.**

- `day3-fire-whole-front-seed4242.png`, 3s in: the burning building is upper left. Flames stand
  along its whole front, from the corner at one crossing to the corner at the next, and smoke
  rises at intervals above them. The sidewalk in front of it is bare.
- `day3-fire-truck-parked-seed4242.png`, 14s in: the same fire with the engine parked at the kerb
  in front of it.
- `day3-fire-burst-seed4242.mp4` and its timing record `day3-fire-burst-seed4242.json`: a
  29-frame burst from second one to second four. The flames flicker out of step
  along the front, and the engine's screen-edge badge is up at the right.

**How it was taken.** Source revision `5e3eea5b` (branch `feature/building-burns`, PR #415) plus a
throwaway edit to `src/main.gd`, not committed. On day 3, right after `_resistance.start_day(...)`
in `_start_day()`, it spawned `burning_building` with `EventManager.spawn_extra()` at tile
(93, 84), a real `AT_THE_FRONT` site. It set the start position to the walkable ground nearest
192px east and 32px south of it, on the sidewalk's kerb lane. A second later it called
`EventManager._summon_the_sighted_row()`, which a planned fire calls the first time she sees it.
Then:

    tools/shot.sh fire.png 3 --seed 4242 --day 3 --invincible --no-title --zoom 0.7
    tools/shot.sh truck.png 14 --seed 4242 --day 3 --invincible --no-title --zoom 0.7 \
        --press snapshot_burst 1

The MP4 is `tools/clip.sh` run on that burst. The burst's frames themselves are not kept.

**Limits.** A rig, not a walk. The fire is spawned directly rather than sited from her walk, and
the summon is called rather than triggered by her sighting it. `--invincible` keeps the clock
still. The debug readout covers the right edge, as on every `shot.sh` still.
