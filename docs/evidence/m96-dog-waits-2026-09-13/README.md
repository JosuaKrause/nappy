# M96, the teaching day and the dog after it — the day-4 dog is a map placement, met by walking into it

One `tools/shot.sh` burst on `feature/m96-dog-waits`, seed 4242, day 4, at commit `8ae74e62`
(`origin/main`'s tip at capture time):

```
tools/shot.sh out.png 8 --seed 4242 --day 4 --invincible --spawn event:charging_dog --walk east \
    --press snapshot_burst 3
```

Kept whole at `rig-162308-seed4242-v0.10.0-4-g8ae74e62-dirty/` — `run.log`, `maps/day04-attempt1.png`
(the day's own route map), `auto/001-attempt1-chase-charging_dog.png` (the game's own automatic
capture on the `chase` telemetry line), and `asked/burst-5902022-001/` with its 36 numbered frames,
`burst.json` and the `tools/clip.sh`-made `burst-5902022-001.mp4` beside it. `--invincible` is
right here: the subject is the trigger, not the cost — nothing in this capture is about whether
contact ends the day.

## What the run actually did

`run.log`: day 4, act 2, `charging_dog x3` in the day's plan (three map placements, not a director
siting), she starts at `(63,19)` — `--spawn event:charging_dog` puts her `first_event_position()`'s
own offset from the nearest one — and within the same instant:

```
   0.0  near     charging_dog (telegraph) at (65,18), 65px, ...
   0.0  chase    charging_dog came for her at (65,18) | ...
   0.0  near     charging_dog at (64,18), 29px, ...
   0.0  near     charging_dog at (64,19), 15px, ...
```

`ahead owed` reads `32` in every debug-overlay frame throughout the capture, before, during and
after the encounter, and never drops — the number the director's own `AHEAD_OF_PLAYER`/
`TOWARD_PLAYER` queue would shrink by if this dog had been handed out of it. It is not: this
`charging_dog` is one of the day's three tile placements, exactly as `alley_robbery` would be,
and the encounter starts the moment she is within its own field rather than because the director
sited it in front of her.

## The frames

- **`auto/001-attempt1-chase-charging_dog.png`**, `age=0.0/4` in the debug readout — the game's
  own automatic capture at the instant the `chase` line above was written. She is still at her
  spawn tile `(63,19)`; the dog is drawn a couple of tiles off, already in its running pose,
  closing the gap rather than standing beside her. This is the earliest visual moment the capture
  has of the encounter — the frame right after it decided to come, not before.
- **`asked/burst-5902022-001/frame-0001.png`**, 9.7ms into the 3-second burst — she has covered
  the ground to `(65,19)`, immediately beside the dog, with the doubled red caret already up over
  her head. The burst starts already inside the encounter rather than catching its opening.
- **`frame-0020.png`** (mid-burst) and **`frame-0036.png`** (the last frame, 2.93s in) — the two
  of them held at the same tile for the whole burst: `run.log`'s last line reads `charging_dog
  stopped chasing after 0.0s — closest 0px`, so the dog reached her almost immediately and the
  rest of the capture is the held contact, with `cafe_tables` next door (logged at `(66,19)`, 63px
  away) blocking any further ground east. `--invincible` is why the day continues through it.

## What this does and does not show

**It shows the row is a real map placement, met by walking rather than sited ahead of her** — the
static `ahead owed 32`, the plan line naming three `charging_dog` placements, and the encounter
starting from proximity rather than from the director's queue. That is the half of the milestone a
screenshot can speak to.

**It does not show the silent, unnoticed "waiting" half**, and the reason is arithmetic rather
than a defect: `DevRig.first_event_position()`'s `--spawn event:<id>` offset is
`0.6 × outer_radius` — 90px for this row's 150px field — and `pursues_within_after_first_day` (the
new trigger this milestone adds) has to sit above `Tuning.pursuit_standoff(130.0, 26.0)` (104px) or
`Tuning.validate_pursuit` refuses it outright: a trigger inside the stand-off is a trigger that
notices her before it has finished closing. 104 is already past the tool's own 90px offset, so
**no legal value of the trigger leaves room for this dev flag to land her outside it** — the offset
and the fairness floor are on the wrong sides of each other by construction, for this row's own
geometry, not because of the number chosen here. `tests/test_tutorial_dog.gd`'s
`_test_day_4_dog_waits_until_she_is_in_its_field` is the actual proof of the wait, at the instance
level, for exactly the reason a capture cannot reach it here: it can put her at any distance,
including the 20px band between the trigger and the field's own edge that `--spawn event:<id>`
never can.

**Unwalked, and worth a look if a future capture wants the silent half**: a wider approach —
`--spawn` at a plain tile type well clear of the placement, then a long `--walk` timed to cross
into the 130–150px band from outside — or a dev flag that takes a stand-off distance rather than a
fixed fraction of the field. Neither is this task's to build (`src/dev/dev_flags.gd` and
`src/dev/dev_rig.gd` are outside its fence).
