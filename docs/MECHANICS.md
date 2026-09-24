# Nappy — Mechanics & Tuning

All constants live in `src/autoload/tuning.gd` (autoload name `Tuning`) so they can be
balanced in one place. Values below are the design intent; the script is the source of truth.

## The two meters

### Sleepiness (0 → 100)

The win meter. Fills only under the right conditions.

| Condition | Rate (per second) |
| --- | --- |
| Walking, excitement below calm threshold | `+0.42` |
| Walking, in a **four-block calm zone** | `+0.42 × 21` = `+8.8` |
| Walking, in a **two-block** calm area | `+0.42 × 29.7` = `+12.5` |
| Walking, in a **single-block** calm area | `+0.42 × 42` = `+17.6` |
| Running | `0` (never fills while running) |
| Idle / near-idle | `-1.0` (drains) |
| Excitement at or above `CALM_THRESHOLD` | `0` (frozen, never drains) |

**Key rule:** while `excitement >= CALM_THRESHOLD` (default `35`), sleepiness does not rise
at all. It does not drain either — the baby is just too interested in the world.

At `sleepiness = 100` the baby falls asleep and the day enters its **return phase**.

**In acts III and IV, the return leg owes its own pressure.** `EventDirector.owe_the_return()`
fires the moment `EventBus.return_phase_started` does, adding `Tuning.RETURN_PATROLS_PER_ACT`
(`[0, 0, 2, 3]`) extra `police_patrol` rows to the owed queue and switching its pacing to
`Tuning.RETURN_PATROL_INTERVAL` (9–16s, tighter than the ordinary 11–26s) for the rest of the day
— see `docs/EVENTS.md`, "The return owes her patrols", for the siting and the fairness. Acts I
and II are untouched, so the days she is taught the mechanic on stay exactly as they were.

**Where a day is won.** These three numbers are pitched against the *day*, not against each
other, and they are what makes the walk the game:

- A whole day of undisturbed street walking reaches about **76** of 100. The street is real
  progress and can never be enough, so circling the starting block cannot win a day.
- A calm stretch clears the meter in **11.3s** in a four-block zone and **5.7s** in a single
  block, and the walk out has already contributed. A second in a park is worth twenty-one on the
  pavement, because the park has to be *obviously* the answer. **The reward moves whenever the walk
  to it gets harder**: everything between the doorstep and the park — a solid catalogue, a crowd
  that bites, a pacing man, a robber — is spent on the way there, which is where the day is meant
  to be lost, and a reward left the same length while the journey grows turns the park into a wait.
- Standing still drains faster than walking fills, so waiting is never a strategy — but it
  drains *slower* than a calm zone fills, so stopping to let something pass stays a move
  worth making.

**And the calm has to be big enough to walk in.** The three rates above are jointly sufficient for
a *lap*: progress requires motion, so a calm area smaller than a stretch of walking is somewhere you
circle rather than somewhere you go. A four-block calm zone is 704px square — 10.8s corner to corner
against the 11.3s a full meter takes — so the calm is a route. A **2×1** zone is the same claim on
one axis: 704px long, 7.7s end to end against the 8.0s two blocks fill in. Both margins are narrow
and it is the relationship rather than either number that has to survive: **a calm area must be more
than one lap wide.** See `docs/CITY.md`, "Calm zones".

**The rate is a curve over the lot's size, and it exists to pay for that lap rather than to be
generous.** It goes as `1 / sqrt(blocks)`, normalised so a 2x2 zone is the base — **21x for four
blocks, 29.7x for two, 42x for one.**

**It divides by the side rather than by the block count**, and that is the trap in it: a 1x1
against a 2x2 is a factor of two in width and *four* in area, so dividing by blocks makes a single
block four times a zone where twice is what the design wants. It is also what the design says in
words — *a lap is a length, not an area.* Paying inversely to width pays every size about the same
for one traverse of itself — **1.4 traverses for a single block against 1.05 for a zone**, against
2.75x apart at a flat rate — so a small calm area is not the weaker destination for a reason that
has nothing to do with what it is, and *which* calm area to head for stays a real question.
`tests/test_generator.gd` holds that ratio rather than either number.

**A day is aimed at a minute of play, with a grace of three.** Dusk at 180s is the outer bound, not
the target: a day walked well is over in about a minute, and the rest of the clock is there for a
day that goes wrong. It also means the day is not lost to the *meter* — once calm ground is reached
the meter is a formality — so **the difficulty has to live in the walk**, which is what every
obstacle between the doorstep and the park is for.

The first two are asserted in terms of `day_length()` rather than as numbers
(`tests/test_meters.gd`), so lengthening the day cannot quietly make the street sufficient
again. `tests/test_balance.gd` then checks the same claim against a real city with that
day's crowd and events standing in it.

### Excitement (0 → 100)

The lose meter. Anything interesting in the world pushes it up.

Sources:

| Source | Contribution |
| --- | --- |
| Proximity to an active event | `intensity × falloff(distance)` per second |
| Proximity to a passer-by | `4.2 × falloff(distance)`, inner `22`, outer `30` |
| Proximity to a passing car | `5.4 × falloff(distance)`, inner `38`, outer `104` |
| Running | `+ (speed − walk_speed) / (run_speed − walk_speed) × 14.0` per second |
| Standing in an alley | `+3.0` per second (slow, constant dread) |
| Sudden events (cat dash) | one-shot impulse on trigger |

The crowd is the same kind of quantity as an event and is summed the same way, which is
what makes the **noise floor emergent**. There is no city-wide "background noise" number
anywhere; a street is loud in proportion to how busy it is, and a park is quiet because
nobody is in it. Both facts are visible on screen, which a constant never could be.

Excitement moves at the **net** rate, `incoming − decay`, and the decay is two things multiplied:
what she is doing, times what she is standing on.

| Player state | Decay per second |
| --- | --- |
| Walking | `6.0` |
| Running | `0.5` |
| Idle | `0.0` |

| Ground | × | Walking decay |
| --- | ---: | ---: |
| Calm zone | `2.0` | `12.0/s` |
| Precinct | `1.5` | `9.0/s` |
| Ordinary street | `1.0` | `6.0/s` |
| Alley | `0.58` | `3.5/s` |
| Main road | `0.02` | `0.12/s` |

**The decay is what the bar shows.** A player watching the meter on a street with nothing on it is
watching this number and nothing else, so it is set from a *net* measurement rather than from
taste: the quietest ordinary pavement, with the day's own crowd on it and nothing authored in
range, loads about 1.3/s, which leaves 4.7/s downward and a full meter in about twenty-one seconds
of walking. Quiet ground has to read as recovery while she is on it, not merely come out negative
on paper.

**The multipliers are ratios; the rates on the right are the design.** Each ground is somewhere
she is meant to be able to recover at a particular speed, so a change to the walking rate re-derives
all five rather than leaving them alone. The park's own floor is that it stays a place rather than
a switch: at `12.0/s` a full meter takes eight and a third seconds to clear, which is long enough
to be somewhere she walks to and stays in.

**The ordering is motion-shaped, and that is the model.** The pram is a rocking chair with wheels
on: what settles a baby is being pushed. Walking settles her most, running is still motion and
settles a little, and standing still settles nothing at all.

**An idle decay faster than walking is the trap here**, and it is the ordering a physical reading
of "resting calms her" produces: it makes standing still the strongest move in the game — a full
meter cleared in under twenty seconds for a handful of points of sleepiness, anywhere, including
the middle of a street she has no business being on. A trace of that reads as a minute or more with
no entry in it at all.

Netting rather than "decay only when nothing is happening" is what makes the decay column
matter. Two consequences fall out of it, and both are wanted:

- **Standing still freezes the meter** rather than clearing it: the day stops moving in both
  directions at once. Waiting is not a plan, and the counterplay it replaces was always the better
  one — walk somewhere quiet, which is what the calm-zone multiplier is for and what the whole
  route is about.
- **Sprinting past an event is far worse than walking past it** — running contributes
  excitement *and* drops decay to almost nothing, so the same event hits roughly three
  times as hard. Panic is punished twice, everywhere except against the one thing that
  chases (see "Running that matters" below).

It also sets a floor on what counts as a source: anything weaker than the decay on the ground she
is on cannot move the meter on a walking player at all. That floor is a different number per
ground, which is the point — an empty alley's `+3.0/s` of constant *pressure* sits just under the
`3.5/s` an alley gives back, so it can never be a threat on its own and is never quite recovery
either, while the same trickle on a park would be nothing at all.

**The crowd is pitched so that a contact and a busy pavement cost, and a lone passer-by does not.**
One person at arm's length is `4.2`, under the walking decay, so somebody going past at the
pavement's width is nearly nobody and an empty street reads as recovery — which is the whole
sentence the decay was raised for. What costs is walking **into** them, `18/s` of jolt for a second
and a bit, and that is a thing she did rather than a thing that happened; and what costs more is
several of them, because the load is a sum and a crowded pavement never stops emitting. One car is
`5.4`, and no single car is dangerous either. The danger is that on a main road there is always
another one, and the ground itself gives back next to nothing to offset it — the arterial's mean
load runs many times what its own ground recovers, where an ordinary street's load stays under
what it recovers. Above about half the meter to cross it, it is a street nobody can use rather than
a route decision; `tests/test_crowd.gd` holds both ends of that.

**Every one of those comparisons is against the decay on the ground it is measured on**, not
against the walking rate on its own. The spine gives back `0.12/s` and a back street `6.0/s`, so
pricing a crowd load against the unmultiplied number flatters one street and libels the other — and
standing still settles nothing at all, so the only question a street has to answer is what it costs
to walk down, which is what a route is made of.

**The bar may reach and sit at `excitement = 100` without ending the day.** The day ends crying
only once a further mass of excitement has arrived while she is already sitting at the cap —
`Tuning.EXCITEMENT_OVERFLOW_TO_CRY` (9.5) points inside `Tuning.EXCITEMENT_OVERFLOW_WINDOW` (3s) —
so a single contact that only just reaches 100 leaves almost nothing behind it and does not end
the day, and a source that keeps her at the cap does. See "Baby state machine", "A push at the
cap", for exactly what counts as that mass and what happens to it once she gets away from the
source.

**The entity halo reads this same subtraction, per source.** `ExcitementHalo` traces every live
source's own gross points landed over the last `ExcitementHalo.WINDOW` (five seconds, the same
figure `Baby.decay_in_window()` sums the decay above over) and subtracts that source's own share of
the decay taken in the same window — shared between every source in proportion to what each landed,
never below zero (`ExcitementHalo.net_landed()`). So the rims live at once sum to exactly what this
section's net rate bought the bar over the window, and a source reads red only while the bar is
actually climbing because of it — not merely because it is loud. See `docs/EVENTS.md`, "The visual
vocabulary," for the whole cue and its colour and transparency curves.

## A conversation

`chatting_mother` is the one row in the catalogue that takes the player's own controls away rather
than costing a meter: coming within `EventDef.detain_distance()` of an instance that has not yet
chatted locks her movement input for `detain_seconds` (5s) — the run key does nothing, and she
keeps no speed of her own: velocity runs out through
the ordinary friction rather than stopping her dead, the same as letting go of every key would.

**No new meter rule prices the stop**, because the idle rules above already do: sleepiness drains
at `SLEEPINESS_DRAIN_IDLE` and excitement decay freezes at `EXCITEMENT_DECAY_IDLE` (zero) for as
long as she is held still, exactly as they would for a player who stopped on her own. What the
conversation adds on top is the meter's own content while it runs — `Tuning.CHAT_EXCITEMENT` (25)
added flat over the capture while the baby is **awake**, and nothing at all while she is **asleep**,
read off the baby's state rather than scaled through `SLEEPING_SENSITIVITY`: a *pure* time loss
means the contribution is exactly zero, not merely smaller. Five seconds is a quarter of the lose
meter outbound and only the clock on the way home, which is why the same body reads as a different
obstacle in each half of a day. See docs/EVENTS.md for the row itself.

## A checkpoint

`checkpoint_hut` and `checkpoint_post` — the huts and the alley guard a region wall's own door
stands, see docs/DECISIONS.md, "M62 — Checkpoints that divide the map" — reuse the conversation
mechanism above at a shorter hold, `Tuning.CHECKPOINT_DETAIN_SECONDS` (2s): a toll paid at every
crossing of the wall has to stay cheap to repeat, where a conversation is spent once.

**The boom between a street door's huts, `checkpoint_gate`, is not an inspection.** *(2026-09-24,
the player: "Boom shouldn't inspect her. It should block her.")* Lowered it is a wall across the
carriageway; raised for a car it is ground she may walk under, at the price of that car, and it does
not come down while any of her rig is beneath it. A hut does not take her in from the carriageway
the boom spans, so the inspection is where the guards are: at the huts, on the sidewalks. Walking
under it is unlawful: a guard steps out of the nearer hut after her — running outpaces him, walking
does not — and a catch ends the day. See docs/EVENTS.md, "Checkpoints".

**The inspection starts as she walks up, measured from the door body's own wall** —
`Tuning.CHECKPOINT_DETAIN_REACH` (48px) past its solid edge, rather than a radius from its middle.
A door body is something she cannot walk through, so a trigger stated from the middle has to be
wider than her own body *and* than whatever she is pushing in front of it; stated from the wall,
one number covers both, and the hold cannot be switched off by a change to the pram. Only the
nearest of a door's bodies ever captures her, so one approach is one inspection.

**She comes out just clear of the door, standing inside its own trigger, and what stops it taking
her again is a latch rather than distance.** `ReleaseLatch` (`src/world/release_latch.gd`) is armed
on the way out with the trigger's own circle and holds until she is measured outside it: standing
where she was let out is free for as long as she likes, and leaving is what re-arms the toll. Every
door body whose reach she lands in gets one — two doors can meet at a corner — so a crossing costs
one hold. The escape scene's own doors reuse the same class.

**She and the guard are both gone for the hold's duration**, reading as *inside* rather than as
frozen in the street — `Stroller.hide_for_inspection()` and `EventInstance.is_its_guard_inside()`
stop drawing the two of them the moment the hold starts, and both are back the moment it ends, her
on the far side of the door so being let out reads as being let through
(`EventManager._release_finished_door_detentions()`).

**Going in and coming out are owned by different halves, and that asymmetry is the whole of why
she reappears where she is let out.** Hiding her happens on the frame `start_chat()` fires, which
is a physics frame, so no drawn frame can catch her between the two. Showing her again has to
happen on the frame she is *moved*, and the move is the release — also a physics frame — while the
hold's own seconds run down in `EventInstance._process()`, a drawn one. So the release does both,
in order: teleport, then show, then hand the camera back. Ending the hold by un-hiding her where
its clock ran out drew her standing at the place she went in for every frame until the next physics
tick. The pram's cue and the alert mark hidden
along with her are the same drawing call that draws her, so nothing about them needs its own
switch. The meters keep running throughout — sleepiness still drains at the idle rate, because the
baby is still there whether or not the player can see her.

**The hold charges its toll and nothing else.** While she is inside a door — inside the trigger of
a `redetains` instance whose hold is running — the only thing the meter sums is that hold's own
flat `Tuning.CHAT_EXCITEMENT` (25) over `Tuning.CHECKPOINT_DETAIN_SECONDS`. Every other event field
and the whole crowd are off: `EventManager.door_holding_her_at()` is the one question both halves
of `City.excitement_sources_at()` ask. She is in the hut for those two seconds, not on the
pavement, so what happens to stand beside that particular door is not part of what the crossing
costs — *"it works in both directions with the same cost each time"*. Nothing gives back either,
since `EXCITEMENT_DECAY_IDLE` is zero for a player held still, so the hold is exactly the toll.
`chatting_mother` is deliberately not in this: her conversation happens on the pavement with both
of them still drawn, so a lorry reversing beside them is part of what it costs.

**The hut, the boom and the shadow under them stay exactly where they are.** The guard is what goes
inside, not the building he works in: a checkpoint that blinks out for two seconds reads as the
door having been removed rather than as her having gone through it. The one row where the whole
picture goes is `checkpoint_post`, an alley guard standing alone, since he *is* all of it —
`EventInstance.is_suppressed_by_its_own_hold()` is that narrower question and the halo gates on it
too.

**The crowd is held at the same huts, and none of it is her machinery.** *(Playtest 58: "walkers
walk through checkpoints..."; asked which rule they get, "Held at the hut like her"; then "a small
fraction can do that"; "others can turn back"; "don't want a queue that is long".)* A walker draws
its answer once, when it is placed: one in eight walks through, one in four turns back at the last
junction the way it does at a wall, and the rest are held. A held walker walks up to the hut on its
own sidewalk, waits stopped beside it in its last facing behind whoever is already in the line,
goes **inside** for `Tuning.WALKER_DOOR_HOLD_SECONDS` (1s, shorter than her own two, because a
walker is not the one being looked for) and is not drawn, and comes out on the far side of the door
on the same lane with a cooldown that keeps that hut from taking it again until it has left the
hut's area — so the crowd's own steering turning it round just past a door cannot put it through a
second inspection. One inside at a time, and **the line is short by construction**: a door holds
one walker inside and `Tuning.WALKER_DOOR_QUEUE_MAX` (2) behind it, and the next walker to see it
turns back at the last junction instead of joining. The decision is taken where the lookahead first
sees the door — the same seven tiles the crowd sees a wall from — rather than at the hut, because a
walker has no about-face to make once it is standing in a queue.

It is the crowd's own state throughout — `Crowd._hold_walkers_at_doors()`, `WalkerDoorHold` and
`CrowdAgent`'s four `DoorState`s, keyed on the hut body's ground point from the region plan. It
reads no catalogue row: not `detain_radius`, which is the reach *she* is caught at, and none of the
detention above, which teleports her, hides her, moves the camera and charges her meter.

**The camera eases onto the door instead of following her**, and back again once she is released —
`Stroller.focus_camera_on()`/`release_camera_focus()`, a smooth-stepped ease over `Tuning.
CAMERA_EASE_SECONDS` rather than a cut or the ordinary per-frame walking follow. This is the one
camera move in the game that is not her walking; any later one that is not either reuses the same
two calls rather than a second camera.

**An ease starts from where the camera was drawing, which is not where the camera is.** Three
things sit between `Camera2D.global_position` and the point on screen — `position_smoothing_enabled`
still catching up, the walking look-ahead in `offset`, and the city limits — so
`Stroller.camera_screen_center()` is what the ease reads. Two more belong to the switch itself:
taking the camera off her transform (`top_level`) leaves its *local* position, the world origin, as
its new global one, so it is put back on the drawn point in the same call; and its own smoothing is
switched off for the duration, because the ease is the smoothing and two of them in series make a
half-second move read as a cut.

## Baby state machine

**A push at the cap.** The bar may reach and sit at `Tuning.METER_MAX` without ending the day —
`_update_excitement()` still nets `incoming − decay` every frame the way it always has, and the
day only ends once `Tuning.EXCITEMENT_OVERFLOW_TO_CRY` (9.5) points of that net have arrived
**while she is already sitting at the cap**, summed over the last `Tuning.EXCITEMENT_OVERFLOW_WINDOW`
(3s). That sum is the bar's own would-be overflow — the part of a positive net rate the clamp would
otherwise have piled on top of 100 — not the raw incoming: a single contact from just under the cap
spends nearly all of itself getting *to* 100 and leaves almost nothing over, so it no longer ends
the day on its own, while a source that keeps emitting once she is there keeps feeding the sum. The
moment incoming drops under decay, the bar falls back from 100 at its ordinary ground-and-motion
rate exactly as it always has, and the sum itself never resets — it simply drains as its own
entries age out of the three-second window, the same way the decay side of the meter already ages
out of `ExcitementHalo.WINDOW`. Two constants, both in `src/autoload/tuning.gd`, tightened once
from the player's own starting point of 10 over 3s to 9.5 over 3s (`docs/DECISIONS.md`, M96 and
M100).

```
        ┌────────────────────────────────────────────┐
        │                                            │
   ┌────▼────┐  sleepiness = 100   ┌────────┐        │
   │  AWAKE  ├────────────────────▶│ ASLEEP │        │
   └────┬────┘                     └───┬────┘        │
        │                              │              │
        │ excitement = 100             │ excitement ≥ │
        │ and a push at the cap        │ WAKE_THRESH  │
        │ (above)                      │              │
        ▼                              └──────────────┘
   ┌─────────┐                     (sleepiness drops to 50,
   │ CRYING  │  day lost            back to AWAKE)
   └─────────┘
```

The same edge — excitement at 100 and a push at the cap, described above — reaches `CRYING` from
`ASLEEP` as well, checked before the wake transition below: a push while asleep ends the day
directly rather than waking her first.

While `ASLEEP`:

- Sleepiness is pinned at 100.
- Excitement still accumulates, but from a *lower* baseline — a sleeping baby is harder to
  disturb. Incoming excitement is multiplied by `SLEEPING_SENSITIVITY` (default `0.55`).
- If excitement crosses `WAKE_THRESHOLD` (default `60`) without the push below having reached the
  day-ending mass yet, the baby wakes: sleepiness resets to `WAKE_SLEEPINESS_PENALTY` (default
  `50`) and the day continues.
- If excitement reaches 100 and a push at the cap reaches `EXCITEMENT_OVERFLOW_TO_CRY` while
  asleep, the baby cries → day lost — "A push at the cap" above is what a push is and how it
  drains.

This makes the walk home a real second act rather than a victory lap.

## Movement

| Property | Value |
| --- | --- |
| Walk speed | `92 px/s` |
| Run speed | `168 px/s` |
| Acceleration | `700 px/s²` |
| Friction (deceleration) | `900 px/s²` |
| Idle threshold | speed `< 12 px/s` counts as idle |

Controls: arrow keys or WASD to walk, hold **Shift** to run, **Esc** to pause. There is no
interact key — touching a resistance chalk mark or a task's own contact is what completes it. The
keyboard is a device rather than a scheme and works this way regardless of what a pointer does. A
press on the arrows or WASD resets whatever heading a click, tap or drag last locked in, so the
keys steer alone from that frame; a later click sets a fresh heading as it does today.

The title screen offers a choice of two pointer schemes, picked by pressing one of its two buttons
— a direction key or `space` begins a run in the **tap** scheme instead. Both share the same shape:
a press sets a direction that is locked in and walked with nothing held down until the next press
changes it; a double press sets the direction and holds **run** until the next press changes or
releases it, the same deliberate act **Shift** is rather than a gradient a thumb could cross by
accident. Held down and moved, the pointer keeps re-aiming continuously until it lifts. There is no
partial-strength walk on any input path: every press or motion event presses a full-speed unit
vector, so the only two speeds in the game are the walk and the run.

The two schemes differ only in where that press is measured from. **Tap** aims from wherever she is
standing, the way a mouse always has, and a press within a generous radius of her stops her.
**Joystick** aims from whichever of two fixed points on the screen is nearer the press — both drawn
as a ring — and is stopped by a press on either point or in a band down the screen's own middle
instead. Neither scheme is tied to a touchscreen or a mouse: either can be picked on either device.

Where a heading is measured from, and what stops her, are the one place a mouse and a real finger
disagree. A mouse aims from her own world position, and a click within a generous radius of that
position stops her. A real touch instead aims from whichever of two fixed points on the screen is
nearer the press — drawn as a ring with a knob at the currently-held direction, so what is locked in
can be read off the glass without watching her — and is stopped by a press on either point or by one
in a band down the screen's own middle, never by a press near her own position: the camera keeps her
at the middle of the screen, so that ground is the band's own.

The pause button, top right, is shown on every device once a day — or a section of the escape, the
run's own ending — is actually running: a real `InputEventAction` for `pause` through
`Input.parse_input_event()` rather than held state, since `main` reads the pause off the propagated
event and would hear nothing from `Input.action_press()` alone. It fires on release rather than on
press, and only when the release is still over the button, so a thumb that lands wrong can slide off
without stopping the day. **Esc** pauses too, on every device, silently. Losing the window's focus
opens the same screen, unless `--no-focus-pause` says otherwise. Neither ever opens over a section's
brief or the epilogue, the escape's own two screens between one section and the next — the same
reason Esc opens over an ordinary day's own end-of-day message and focus loss does not: a section's
brief stands between her and a clock that has not started yet, not between her and a day already
decided.

The stroller faces the movement direction and lags slightly behind the mother, so the
player can read direction at a glance.

## The street has physics

**A crowd that is a field with a picture attached is not a street.** If you can walk through a
person, through a car, through a queue at a bus stop, and the only thing that happens is that a
number moves, then the route is never a decision: every pavement is identical, none of them can
hurt you, and a day can cross the whole city without meeting anything.

Four mechanisms, all of them in `src/crowd/crowd.gd`, all of them about the *player* — which
is why they live there rather than in `CrowdAgent`, which has no business knowing she exists.

### A body is solid

| | |
| --- | --- |
| Contact radius | `14 px`, centre to centre, released past `19 px` |
| Separation | positional, `70%` to them and `30%` to her |
| Deflection | `55 px/s`, decayed by `FRICTION` |
| Cost | one jolt: `18/s` fading over `1.2 s`, so **~10.8 points** |

The jolt is pitched against what the *authored* content costs: the crowd is most of what a street
costs and must not be all of it.

**The radius is set by the lane spacing, not by a body's width.** Pedestrian lanes are one tile
apart, so the only line with no contact on it is the midline between two of them. Too wide a radius
closes that line everywhere on a two-tile pavement, so every walk collects a bump every few seconds
however carefully it is done — a toll, not a decision. At the contact radius above, a lane centre
still costs bumps for the length of the walk and the midline costs none, which is what makes staying
on it a real decision.

Three things about it that only show up by walking a rig down a real pavement and reading the
meter, none of which a data-level test can see:

- **Somebody bumped along their own line of travel steps aside**, rather than being pushed
  further along it. She walks at 92 and they walk at 60, so pushing them straight ahead
  separates nobody: it ploughs a wedge of pedestrians down the pavement in front of her, all of
  them permanently in contact and permanently loud.
- **A contact startles once, not once per frame.** `CrowdAgent.touching` is the hysteresis.
- **The separation is positional and the deflection is not.** Resolving position means two
  bodies can never end up inside each other however fast she is going; the velocity kick on
  top is what makes a crowd somewhere you get pushed around. It is applied with
  `move_and_collide` rather than folded into `velocity`, because `velocity` is what
  `is_idle()` and `run_excess_ratio()` answer from and those two questions are about the
  *player*, not about the crowd.

### The bump is a source, not a write

**Excitement stays a pure query.** A contact does not touch `Baby.excitement`; it *startles
the person she walked into*, and `Crowd` sums that agent like it sums every other one. So
contacts still compose by plain addition, there is still no ordering to get wrong, and
`City.total_excitement_at` still adds exactly two things. See the **events** skill.

### A car is lethal

Stepping into the carriageway in front of a moving car ends the day (`hard_fail`
`car_strike`). The strike volume is a **box** — 26px along the car, 14px across — because a
car is two tiles long and one wide, and a radius that covered its length would kill people
standing beside it. It only counts while she is standing on a road tile, and a car below
`20 px/s` cannot run anybody over, so a car halted at a zebra is scenery.

### The traffic fairness contract

A car is not an event: it has no telegraph, it is not in the catalogue, and
`validate_event()` never sees it. Two things stand in for the telegraph, and
`Tuning.validate_traffic()` checks the second on boot.

1. **The road itself.** The carriageway is painted, permanent and learnable, and the kerb is
   an edge she chooses to step over. Same shape of contract as `alley_robbery`, where the
   alley is the warning.
2. **The horn.** A car sounds it `1.6 s` out at anybody standing in its lane, which must
   exceed the time to walk the whole width of the carriageway with the doubled margin every
   hard fail is owed: `64px × 2 / 92 = 1.39 s`. The horn is itself a jolt (~8 points), so a
   near miss costs something even when it stays a near miss. The crowd watches for it from
   `CAR_HORN_SIGHT` (296px) out — wider than the 200px the strike and the give-way scan use,
   since a fast car needs more than 200px of travel to sound the whole `1.6 s` — and
   `Tuning.validate_traffic()` checks that reach against the fastest car on boot.

The horn also raises the **exclamation mark over the player**, the load-bearing cue of the visual
vocabulary. See docs/EVENTS.md.

**On the main road the light is the contract, and with the power out the horn is.** The spine's
traffic does not give way at a zebra, so what stands between her and a hard fail there is the length
of the side street's green (`Tuning.validate_signals()`). On the last night, after the blackout, the
lights are dead: a spine junction is negotiated the way a side street's is, and crossing the spine
is kept by the same two things every other street's carriageway is — the paint and the horn. The
spine's carriageway is the same 64px as every street's and the horn is stated in seconds of the
car's own travel, so the check above is the dark spine's check too. That night's roads are harder
on purpose; see docs/CITY.md, "Traffic signals".

Belt and braces: a car in its lane has a strike box geometrically incapable of reaching over the
kerb. A car sits half a tile off the middle of the carriageway, so its far edge is `16 + 14 = 30 px`
out and the kerb is at `32`. `tests/test_crowd.gd` asserts it, because a box that reached the
pavement would kill people who never stepped off it and would look exactly like a fair death.

**The one manoeuvre that puts a car's body over a kerb is an about-face in a street**, and it cannot
kill anybody standing there: a strike only counts while she is on a road tile, which is the same
kerb read from her side. See "How a car turns".

### The zebra is a negotiation

Traffic **gives way** at a crossing somebody is waiting at: a car looks `CAR_ZEBRA_SIGHT`
(200 px) ahead, which is nearly four times the 53 px it needs to stop from top speed. The
margin is the point — the slowing has to be *visible from the kerb*, because a player deciding
whether to step off needs to see the car slowing rather than discover afterwards that it would
have.

So the crossing is the safe way over and jaywalking is the fast way over, which is the choice the
zebra exists to offer.

**A car gives way *at a place*.** Braking toward **zero speed** from wherever it noticed leaves a
car stopped wherever the curve ran out — with four times the room it needs, most of a block short —
and says nothing about not stopping on the paint. Both halves of that are the same missing thing:
somewhere to stop.

Three rules, and they are separable:

- **The target is the stop line**, `CAR_STOP_LINE_SETBACK` before the near edge of the zebra.
  Measured to the car's centre, so its nose ends up a few pixels clear of the paint.
- **The approach is shaped by `CAR_ZEBRA_APPROACH_BRAKE`, not by `CAR_BRAKE`.** The gentle rate
  is what makes the easing begin as the crossing comes into sight; `CAR_BRAKE` stays in reserve
  for the emergency. Shaping it with the hard brake makes the onset of braking and the commit
  point the same instant, and then no car ever stops at all.
- **A car too close to stop commits and clears the crossing.** Measured against the *paint*
  rather than the line: overrunning into the setback is a car stopped a little close, and
  overrunning onto the zebra is the thing being prevented. Since sight is four times the
  braking distance, this only ever fires for somebody who stepped up after the car had
  committed, never for a player already waiting — and there the horn is the contract rather
  than the brake.

Why it matters more than tidiness: the painted carriageway is one of the two things standing in
for a telegraph in the traffic fairness contract. A car halted on the zebra cannot hurt anybody
— it is under `CAR_STRIKE_MIN_SPEED` — but it is *unreadable* scenery parked on the one place
the game has told the player is the safe way across.

### How a car turns

**A turn is a path a car follows, not a swap of its axis and its lane.** It plans one arc before it
starts, drives its own lane up to where the arc begins, and then follows the curve frame by frame —
so its position and its heading are continuous the whole way round, and it lands on the centre line
of the lane it was turning into rather than steering across to it afterwards.

**The radius is the city's geometry rather than a dial.** An arc tangent to both lanes has one free
parameter, and fixing it by where the arc *starts* is what makes a turn sit inside the junction it
is taken at: a lane centre is 16px from its own kerb and the two lanes of a carriageway are 32px
apart, so the near-side arm is a 16px radius, the far-side arm 48px, and an about-face 16px with no
choice in it at all. `Tuning.CAR_TURN_SPEED` (60px/s) is the speed the arc is taken at — 0.42s in
the tightest quarter turn, where the 130px/s cruise would be through it in 0.19s — and the approach
eases toward it from the moment the car knows it is turning.

**A car's back swings to the outside of its turn**, which is why the two arms start in different
places. Turning toward its own kerb, the tail swings into the far lane, which is road; turning away
from it, the tail swings over the pavement of the street it is still leaving, so that arm does not
begin until the tail is past the kerb — a body's half length into the junction.

**Nothing is committed to before it has been checked.** The strike box swept along the curve is the
footprint, and it is validated against the pavement, closures, seals, walls, precinct paving and the
edge of the map; the lane the car lands in must have a car's length free, and that place is *held*
for every frame of the manoeuvre so nothing else turns or recycles into it; and there must be road
past the end of the arc for the car to leave by. A turn that fails any of those is not taken, and
the separation pass is never asked to repair one — `Crowd.space_out_the_traffic()` refuses to slide
a car that is on an arc.

**A lane makes room for a car that is coming.** The room above is a fact about the frame the turn
was committed in, and the car is not standing there until a run-up and a whole arc later; the
traffic in that lane keeps driving in the meantime. So the booked landing is given to the lane as a
**stopped leader**: the nearest car behind it keeps a headway to the spot exactly as it would to any
car in front of it, and the gap is open by the time the turn arrives. Nobody ahead of the landing is
told anything, since they are driving away from it and a leader behind a car is how a queue
deadlocks.

**And the arrival is never moved off the end of its own arc.** A brake aims at a point and arrives
late, so the follower that was holding back can settle a little inside the minimum gap rather than
outside it — and a body too close *behind* an arrival is what the front-to-back resolve is for: it
moves the car behind, by the overlap. The alternative, sending the arrival to the back of the lane
the way a recycled car merges, is the one thing a turn may not rest on: off screen at the entry band
"further back" is more off-screen road, and at a junction it is most of a street, so a car drives a
visible arc and then disappears backwards past every other car in it. **The room a turn needs is
checked before the arc starts or the turn is not taken**, and the landing frame decides nothing.

**What a car does when nothing fits is brake.** It aims to stop a half turn's worth of road short of
whatever is in the way, plus the slack a 28px body has in a 32px lane, which is what leaves it
somewhere it can still turn round with a little to spare. **A manoeuvre that fits exactly does not
fit**: a brake arrives a frame late and a swept body is sampled rather than solved, so a car that
stops with precisely the arc's own length in front of it finds its own turn refused.

Three places a turn can happen, in order of preference: the arm the car picked, the other arm, an
about-face in the middle of the junction box, and — only when a barrier leaves it no junction to
reach — an about-face in the street. **That last one is the one manoeuvre whose swept body crosses a
kerb**, by 8px, and it is a fact about the city rather than a concession: a half turn between two
lanes 32px apart is a 16px arc, and a car's corners then reach 40px from the centre of it. The
alternative manoeuvre is a three-point turn, and the traffic has no reverse gear. Every hard blocker
is still refused, so a car turning round in a dead end never touches what it stopped for.

**And a car that finds no arc this frame waits, because most of the reasons an arc is refused go
away on their own.** The lane a half turn lands in is the other side of the car's own carriageway
and the traffic on it is driving somewhere, so a landing that is taken now is free a moment later;
the ground the body sweeps, the geometry of the arc and the shape of the map are not going anywhere.
A car refused for the first reason stands at the point it braked to and asks again, with its
followers queueing behind it exactly as they queue behind any stopped car, and takes the arc as soon
as the lane clears. **The wait is bounded** — long enough for a car to clear its own minimum gap at
the speed a turn is taken at — because waiting on a car that is itself stopped is a deadlock, and a
car that never moves again takes its whole street with it.

**The last resort is a heading reversed where the car stands**, with no path in it at all, and it is
reached only from a state that waiting cannot mend: the ground the arc would sweep is a wall, a
closure, a seal or a precinct's paving. It costs a stride before the car may reverse again. **A
reversal that lands in the same state is not an escape** — it swaps the lane the car belongs to
without moving it, and the ordinary steering then slides the body over to the other lane's centre at
three pixels a frame, which is a car shaking its head rather than turning round. So a car with less
than a half turn's road at *both* ends of the piece of carriageway it is on does not reverse. It
stands where it is and leaves the way any body with nowhere to go leaves — recycled at the first
frame the camera is not on it, the same rule a body caught in a pocket already follows.

### Which side of the road

**The city drives on the right**, and that is a rule about the side of the road relative to
*travel*, so it flips with the axis. **Stating it over the lane offset is the trap**: "offset 3
runs the positive way along the axis" is eastbound in the southern lane on an east-west street,
which is right-hand traffic, and southbound in the eastern lane on a north-south street, which is
left-hand traffic. `road_direction()` and `road_lane()` are a pair that both take the axis, and
`tests/test_crowd.gd` asserts it for both axes and both directions: the lane a car is in is the one
on its own right.

**Nothing in a suite or a screenshot can see that going wrong.** Separation, headway, capacity and
noise are all true whichever side anybody drives on, and a stopped frame does not say which way a
car is pointing. It shows up the moment a human watches a junction.

**Walkers have no side convention**, and that is deliberate. They are not mirrored — they are
unordered, which is a different thing. Giving them one is a design change with a measured cost
attached: the contact numbers the pavement is balanced on — a lane centre costs bumps, the midline
costs none — assume somebody may be coming the other way in any lane.

### Traffic queues

A car keeps `CAR_HEADWAY_TIME` seconds of clear road in front of it and never closes to less
than `CAR_GAP_MIN`, which is a car's own length plus a nose. The two wants compose by taking
the lower, so a queue at a zebra is the front car stopping and everybody behind it honouring
the headway rather than a special case for queues.

The **separation is positional**, not a brake, and that is the load-bearing part. A brake keeps
a gap that already exists and cannot open one that does not: two cars inside each other both
choose zero and stay there forever, and recycling puts a car into a lane at a point it cannot
see. `Crowd.space_out_the_traffic()` resolves each lane from the front backwards, so a whole
chain comes apart in one pass. It is the same shape as the player's bump, for the same reason —
see the **events** skill.

The relationship, rather than the numbers: **the headway has to outlast the time it takes to
brake from cruise**, or a car cannot physically honour the gap it is keeping and the queue
resolves by interpenetration again however good the controller is.

**The spacing correction never places a car on ground it could not have driven onto itself.**
`CrowdAgent.nudge_back()` and `_join_the_back_of_the_queue()` are pure arithmetic with no notion
of the map underneath them, so both ask the same `_cannot_go_on` the forward-looking lookahead
already trusts about blocked ground — a hard seal, a region wall or a dead end's own built-over
footprint — rather than parking a car inside it. A recycle's merge is refused whole, since the spot
it rolled is still somewhere to stand. **A nudge goes as far back as the ground allows and stops a
pixel short of the first blocked tile**, walking the tiles between rather than probing only where it
would end, because a refused nudge is a deferred one: the pair stays inside each other, and the
overlap is paid in one jump on whichever later frame the leader has pulled far enough ahead for the
whole slide to be legal — a frame nobody chooses, so possibly one she is watching.

**A hard seal, a region wall, and the closed streets a car cannot see through, all read the same
way to the traffic.** `CrowdAgent._cannot_go_on` treats a tile on a held segment (a hard seal's own
ground, or a region wall's) exactly like a closed one: a car turns off at the last junction rather
than driving into a barrier it has no physics against. A soft seal takes only the pavements, so a
car still crosses it — the street reads quiet on foot and ordinary on the road.

**The same street is not shut to a walker, and the asymmetry is the manoeuvre rather than a
policy.** *(2026-09-19: "pedestrians should only avoid the area if they cannot reach it physically.
right now they give up if there is an event at all when they should only give up if they touch an
impassable wall".)* A car has to decide while the last junction is still in front of it: a turn is
an arc that needs a junction box to fit, it has no reverse gear, and one stopped nose to a wall
holds the street behind it. A walker turns round in a stride wherever it happens to be standing, so
deciding early buys it nothing and costs the city a great deal — a street given up from a junction
away is a street with nobody on it for the whole of its length, which is how sealed blocks and side
streets came to stand empty. So a walker walks a held street up to the seal's own bodies, which are
recorded tile by tile like every other solid body, and turns where it meets them. A car is turned
by the hold; a walker is turned by the thing.

**And a walker picking an arm at a junction weights a sealed street like an open one.** *(2026-09-19:
"they should still go into the section until they cannot continue. this should also happen from
inside the path since right now we have offshoots that are clear because nobody attempts to go
in".)* The only thing a walker refuses to turn into is ground nothing travels — a T-junction on the
edge of a calm zone has one arm that is park, and a walker that turns into it is standing on grass
before anything notices. A street with a barrier somewhere along it is a street to walk into as far
as the barrier, from either end, so a side street off the day's route fills as far as its seal and
the people who reach the seal turn round and walk back out. A car still asks the whole question at
an arm, because an arm it cannot get out of is a car parked there for the rest of the day.

A region door is carved out for whoever it means to let through: a car brakes and queues for the
gate the way it already does at a red light or a zebra, and so does a walker — unless the answer it
drew when it was placed is to turn back, which one in four do, and the door then reads to that
walker exactly like the wall either side of it. That is the one barrier a walker still gives a
street up for from a junction away, because turning back at a door is a decision about the door
rather than about the ground. A walker that crosses is held at the hut on its own sidewalk, one at
a time; see "A checkpoint" above.

**And every other solid body diverts the crowd too, as far as avoiding it.** *(2026-09-12: "yes
every solid body should do that -- not necessarily force a turn around but at least avoid the
solid".)* A café's tables, a construction band, a kerbed van, a stall, a skip, a burnt-out car:
`CityMap.obstructed_tiles` records the tiles each stationary solid body stands on — every piece of
it, for the one row that is several (`docs/EVENTS.md`, "A row may be solid in parts") — filled from
the day's whole plan rather than from the events near the player, because the crowd is steered
across the whole map while an event only exists within reach of her. Mobile rows are exempt, the way the
catalogue's own solidity rule exempts them; so is a body on a segment that is held anyway, and so
is a door, because a hard seal and a hut each already have an answer.

**A body stands on the tiles whose middle it covers, and that is what keeps a row on the pavement
out of the road.** Every lane in the city is travelled down its own centre line — a car sits on its
lane centre, which is a tile centre, and a walker eight pixels either side of one — so a tile whose
centre a body leaves clear still has a line down it to walk or drive. A delivery van pinned to the
kerb is a 22px body around a lane centre 16px from the kerb: it overhangs the carriageway by six
pixels, and counting every tile it touches handed the crowd a whole 32px lane of road as taken,
which turned every car on that street for something parked on the pavement.

**A walker steps round it and a car turns at the junction, and the difference is that a walker has
another lane.** A footway is two lanes wide, so a walker whose own lane is taken steers into the
other one `Tuning.WALKER_BODY_SIDESTEP_TILES` (4 tiles, 128px) before it gets there and steers back
once it is past — the same sidestep a bump gives it, aimed at a lane rather than away from a person.
Only a body that takes **every** lane of one footway at the same point along the street shuts that
footway, and then the walker walks up to it and about-faces in front of it — with the other footway
and the carriageway still open, which is the whole difference between a body and a seal. A car has
one lane per direction and the oncoming one is not an option, so a body on its own lane tile shuts
that direction to it and it turns at the last junction; a car already past the last junction stops
behind the body the way it stops behind a queue, and the oncoming lane keeps flowing.

**An about-face costs a stride before the next one may be taken, and that is what keeps a barrier
from collecting a crowd that shakes its head at it.** A walker that turns is committed to its new
heading for the time one stride takes, so nothing reverses on consecutive frames however it is
boxed in; and because it turns round rather than stopping, it walks back out the way it came
instead of standing at the barrier — two walkers meeting one wall leave in opposite lanes of the
same footway and the ordinary separation keeps them off each other.

**Neither the brake nor the sidestep is what makes this true, and that is worth knowing.** Both are
*approaches* — they aim at a point and arrive late by whatever the last frame's speed bought — so
the guarantee is positional instead: an agent's step is held inside the tile it started the frame
on whenever it would have carried its centre into a body, the sideways half given up before the
forward half so a walker crossing a pavement beside a stall keeps walking along it rather than
wedging against it.

## The world near you

Nothing is loaded upfront: the crowd and the events exist in the few blocks around the player and
nowhere else.

**The city is 160×160 tiles and the visible world is 640×360 px — about 20×11 tiles, well under one
percent of it — the same on every screen.** The window letterboxes to that aspect rather than
showing more city on a wider monitor, so a measurement stated in world px means the same thing for
every player. A city-wide population is divided by that before any of it reaches the player,
which is how a hundred cars read as a street you can ignore. The licence for spending the budget
locally is that continuity of a car you cannot see is unobservable, so it is free to give away, and
density where somebody is looking is not.

**The crowd is a field.** `CrowdField` is a `CROWD_FIELD_RADIUS` box centred on the player.
Agents that pass the edge they are heading for — or fall further behind the edge they came in
at than the entry band is deep, or end up on a street the box no longer reaches — are recycled
into a band outside the edge they will re-enter through. `Tuning.CROWD_PEDESTRIANS_PER_ACT` and
`CROWD_CARS_PER_ACT` are populations *of the field*. **That band never crosses the map's own true
edge**: a walker or a car on an ordinary street re-enters from inside the map, out of sight, and
only a car on the spine re-enters through the tunnel or off the bridge — see docs/CITY.md, "Life
on the streets".

The radius has one floor and it is the screen: half the viewport diagonal is the furthest
anything visible can be from the camera, so an agent recycled outside that is always off-camera
when it appears, whichever way she is facing.

**And a recycle never lands a car somewhere with no way out.** A junction with every arm shut is a
*pocket* — carriageway with no street out of it — and both the morning's placement and every
recycle refuse a car a spot inside one, because a car cannot turn round against a barrier and one
stopped nose-on holds the queue behind it. A car a seal goes up around while it is already standing
there stands exactly where it caught it — no step, no steering, no turn — until it is recycled out,
at the first frame it is further from the camera than `OUT_OF_SIGHT`: the field's own edge is off
camera by hundreds of pixels, and this is the one recycle that has to check. **A car can be caught
one scale below a pocket** — on a stub of carriageway too short to turn round in, between a
precinct's paving and a van parked on its lane, which is not a junction and so is invisible to the
pocket record. It does the same thing for the same reason: it stands, and it goes when nobody is
looking.

**Sealed-off ground has walkers in it, and they keep walking.** *(2026-09-19: "they should be able
to spawn inside a closed off section but shouldn't stand in one place but instead walk until they
are forced to turn around (by the environment)".)* There is no walker pocket: a person turns round
in a stride, so a crossing sealed on all four sides is ground to walk the whole of — down each stub
to the barrier on the end of it, about-face, and back out into the next one. The morning places
walkers there like any street and a recycle lands them there like any street. What used to make
that ground look like a trap was walkers giving a street up from a junction away and pacing the
one junction they had left, which is fixed where it was caused — see "The crowd goes round a seal"
above — rather than by emptying the ground of people.

**The morning's own placement is unpacked before the first frame is drawn.** Every car is placed
without consulting the ones already placed, so some of them start inside each other, and the
front-to-back resolve is what pulls them apart. A day starts from an idle frame — the engine draws
what was placed and only then reaches the physics tick that would correct it — so a correction left
to the first frame is a car jumping most of its own length on the street she is standing in, on the
first thing she sees. `Crowd.start_day()` therefore runs that resolve itself, once, before returning.
**It is the overlap resolve and nothing else**: no car is given a position, and a car that was not
inside another one does not move at all. Spacing the morning out to a minimum headway would be a
different thing and is not done — it would turn a random morning into platoons and make every street
read as busier than the day asked for. **And the index a car looks at is filled from that resolve
before `start_day()` returns**, since the first frame's turns and recycles ask it whether the road
is free before any frame has rebuilt it. An empty one tells each of them yes: a turn books a landing
a queued car is standing on, and the queue's resolve shunts that car a car's length backwards
whenever the turn arrives — seconds later, and possibly in front of her.

**Events stream.** `EventScheduler` still plans the whole day across the whole city — every
guarantee the game makes is a property of the *plan*, so nothing about one usable park, two
routes to two calm areas, one-shots firing once, or determinism from a seed is touched. What
changed is when a plan becomes a node: `EventManager.stream_around()` puts a planned event in
the world when the player comes within `EVENT_STREAM_RADIUS` and takes it away again when she
leaves, with `EVENT_STREAM_HYSTERESIS` so pacing on the boundary does not rebuild it every
other frame. An event that has finished is **spent**: streaming may take an event away and give
it back while it is running, and may never rewind one that is over.

`EVENT_STREAM_RADIUS` has a second floor on top of the screen one, and it is what makes
streaming an event legal rather than a way of dropping things on people: it is wider than the
widest field in the catalogue, so an event is outside its own outer radius at the moment it
becomes visible.

The gameplay consequence is larger than the frames. Without streaming a day can pass with **zero**
events ever coming within reach: a twenty-second event planted across the city at dawn is over
before the player could have reached it. An event that waits for her is an event she meets.

**And some events have no place at all.** `EventDef.SpawnMode.AHEAD_OF_PLAYER` events are
budgeted by the day and sited by `EventDirector`, which puts them across her line
`AHEAD_LEAD_DISTANCE` in front of her while she is walking. See docs/EVENTS.md, "Where an event
happens", for which events earn that and what the contract on them is.

## One event per block

**The density target is one event per block**, and streaming is what makes it computable: the
stream radius is a knowable fraction of the map, so what she is standing in is a knowable fraction
of what the day planned. `EventScheduler.budget_for()` is stated per block for the same reason, and
the caps have to move before the budget — see docs/EVENTS.md, "The density, and why it is caps
before budget".

What the density does to the game is a change of kind, not of degree. A street with one event every
four blocks is a street with an event *on* it — you see it, you route around it, and the rest of the
walk is empty. A street with one event per block has no empty stretch to route into, so the question
stops being *"can I avoid this"* and becomes **"which of these is cheapest to walk through"**. That
is the route decision the whole game is about, and a sparse city cannot ask it.

## Excitement falloff

Each active event has an `intensity`, an `inner_radius` and an `outer_radius`.

```
contribution(d) = intensity                              , d <= inner_radius
                = intensity × (1 − t^power)               , inner < d < outer
                = 0                                      , d >= outer_radius
   where t = (d − inner_radius) / (outer_radius − inner_radius)
```

`power` is `EventDef.falloff_power` and **every row in the catalogue is at its 2.0 default**, which
is the curve the rest of this section is about. It exists so that a row needing a shape its two
radii cannot give — a fast drop with a long tail, or a plateau with a cliff at the end of it — is a
decision that row takes rather than a change to the one function thirty other rows share.

**The shape has a shoulder on it, and that is a design decision rather than an implementation
detail.** The meter has to go substantially up from some way off rather than waiting for contact.

**One row has a second, louder part close in.** `EventDef.core_intensity` and `core_radius` put the
same curve over a shorter band and the row emits the larger of the two at every distance, so the
leaf blower is a wall inside the pavement it stands on and a busker beyond it. Both numbers are
zero everywhere else. It is one field rather than two: the same
`EventDef.emission_at_distance()` answers the meter, the cost table and the placement rules, and an
instance's telegraph and pulse damp the core by the fraction they damp the field by.

**`d` is a distance to a field, not always to a point.** The field is the Minkowski sum of the
object's own `GroundShape` and a kernel — a disc while it stands still, an ellipse while it
moves — so `inner_radius`/`outer_radius` mean distance *from that shape*, not from a fixed centre.
A point body's field is exactly the circle above; a segment's (a café frontage, a barricade) is a
capsule about its own spine, `GroundShape.distance_to_spine()`. A moving emitter is a point either
way — nobody builds the general capsule-and-ellipse sum, because every emitting segment row is
stationary — and its field is `GroundShape.eccentric_distance()`: a conic with the emitter at one
focus rather than at the centre, eccentricity from speed (`Tuning.field_eccentricity()`). **The
resting disc's own width is what the ellipse keeps**: it holds exactly `outer_radius` abeam of a
moving thing whatever its speed, reaches `outer_radius · Tuning.field_scale(e)` ahead of it — more
than a disc's `outer_radius`, since motion only ever adds reach — and less far, `outer_radius /
(1+e)`, behind. See docs/EVENTS.md, "The emission model", for the full derivation and the debug
view (`DebugLayers`, layer `1`) for where the boundary is checked by eye.

**`(1 − t)²` is the shape that looks equally reasonable and inverts the game.** It puts a
**quarter** of the intensity at the midpoint of the falloff band and six percent three quarters of
the way out, so a café at 12/s sits under the 6.0/s walking decay across the whole outer 70% of its
own field — and a run log written at an event's own outer radius reads `events 0.0`. An event you
are not charged for until you touch it is not something to route around, it is something to bump
into.

`1 − t²` holds **three quarters** of the intensity at the midpoint and reaches zero only at the
outer edge. Two consequences worth knowing before touching it again:

- **The telegraph contract is unaffected.** It is stated over *distance* — how far she has to walk
  to be outside the radius — and no radius moved.
- **It applies to the crowd too, and the crowd compensates in radius.** A field that bites from a
  distance is right for an authored event and wrong for one of a couple of hundred bodies, so the
  pedestrian and car outer radii are tight (30 and 104) — a close pass costs what it should and the
  summed street floor lands where the balance wants it.

## Running that matters

Running is deliberately the wrong move against every event you route **around**. The numbers above
are why: `EXCITEMENT_FROM_RUNNING` (14/s) plus the collapsed decay outweighs the shorter exposure
for every row in the catalogue, and `tests/test_events.gd` asserts it row by row. That is not an
accident to be tuned away — an event that merely emits is a *place*, and the answer to a place is
a route.

The exception is the one kind of thing a route cannot answer: something that **follows**.
`EventDef.pursues` marks it, and three properties make walking and running give *opposite
outcomes* rather than the same outcome at two prices:

| | |
| --- | --- |
| Speed | strictly between `WALK_SPEED` and `RUN_SPEED`, by `PURSUIT_MIN_MARGIN` either side |
| Lethal | `hard_fail`, so the alternative to running is losing the day rather than paying points |
| Bounded | gives up after `PURSUIT_TIME`, **or** after `Tuning.PURSUIT_SHAKEN_OFF` seconds of the gap opening, because a run is priced per second and an unbounded chase is a loss however well it is played |

Its telegraph is the **approach**, the way a fire engine's is. A pursuer that stands still while it
telegraphs hands her more ground in two seconds than the entire chase can take back; what she is
owed is `PURSUIT_MIN_NOTICE` seconds of visibly being closed on. `Tuning.validate_pursuit()` is the
whole contract and it runs on load.

**And it stops at walls.** A chase is a straight line at whatever is chasing her, and nothing about
that line asks the city anything — so `EventInstance._walkable_step()` clamps every step of it to
ground `CityMap.is_walkable()` agrees with, sliding along whichever single axis is still open when
the direct line is not, rather than cutting the corner of a building the way an unclamped chase
would. It is not a body — a pursuer stays exempt from `obstructs_radius` for the same reason
`dog_walker` is, a moving wall on a two-tile pavement pins her against a building — it is only ever
a question about the one tile the next step would land on.

### The stand-off, and what a contract in seconds cannot say

**A contract stated entirely in speeds and durations can pass every line of itself while the dog is
killing people, because a pursuit is played out in distances.** A pursuer sited across her line a
couple of hundred pixels ahead — *where she was already walking* — closes that gap in under a second
and then stands **inside its own lethal radius** for the rest of a telegraph that is not yet allowed
to kill her. The instant it is, it does, from a standing start, with nothing she could have done
after the first second.

Two rules answer it, and they are the same rule twice: the contract restated as geometry.

- **`Tuning.pursuit_standoff()`.** The telegraph is spent closing to `inner_radius + speed ×
  PURSUIT_REACTION` and *holding* it, backing off if she walks in, because she will: it is sited in
  front of her and forward is where she was going. Clamping the approach at zero instead leaves the
  contract true of the dog and false of the encounter — it stands politely still while she closes
  the gap herself.
- **`Tuning.PURSUIT_SHAKEN_OFF`.** It gives up once the gap has been **opening** for that long.
  Without a break-off at all, the price of the *right* answer is set by the clock rather than by the
  escape — the same forty points whether she reacted on the first frame or the last, which is a
  player doing exactly what the HUD asked and losing the day to the meter with the dog well behind
  her.

`charging_dog` is 130px/s and intensity 12 for two reasons worth keeping. 130 is *symmetric*:
walking loses 38px a second and running gains 38, which is the version of "opposite outcomes" a
player can feel. And it is lethal — it does not also need to be the loudest thing in act I.

### Why the break-off is a rate and not a distance

A break-off stated as a distance needs two inequalities to be safe — walking must not reach it
inside the chase, running must — and they pull against each other in the same three numbers. That is
how a stand-off widened to buy reaction time eats the escape from the other end, and how a robber's
trigger, which has to fit *between* the two, ends up with an eleven-pixel window to live in.

Stated as a rate, both facts come free from the speed clauses that were already there. A pursuer is
faster than a walk and slower than a run, so the gap can only open while she is running and must
close while she walks:

- **Walking away can never end a chase.** Not "loses if the arithmetic works out" — it cannot happen
  at any distance, for any row, at any radius.
- **Running away always ends one**, in `PURSUIT_SHAKEN_OFF` seconds plus the about-turn, and no
  slower for a large pursuer than for a small one.

The measured encounter, on a rig that **accelerates** (`tests/test_events.gd`, `_answer_rig`) — a
constant-speed rig cannot see any of this, because nobody can turn round in nought seconds:

| she | outcome | cost |
| --- | --- | ---: |
| turns and runs at the lunge | it gives up 1.1s later, 68px at the closest | 0.86s of running, **12 points** |
| dithers 0.1s, then runs | it gives up, 45px at the closest | 0.86s, 12 points |
| dithers 0.2s or more | caught | the day |
| walks away | caught | the day |
| stands still | caught | the day |

**The price of the answer is flat, and that is the design**: running from a thing that follows costs
about a tenth of the meter, and hesitating costs the day. What reacting sooner buys is margin — 68px
against 45 — rather than a discount.

**The open question is the window at the lunge**, which the table puts between 0.1s and 0.2s. She is
walking *into* the thing at that instant, so the gap closes at `pursue_speed + WALK_SPEED` and the
stand-off is worth about a third of the `PURSUIT_REACTION` it was bought with; reversing a walk into
a run costs another 0.37s on top. A player answers during the **telegraph**, where the dog is
visible and closing for two and a half seconds, so the lunge is the worst case rather than the
expected one — but the worst case is what a contract is for. Widening it means widening the
stand-off, and a stand-off much past 180px is a dog that visibly reverses away from her through its
own telegraph, which a player has watched and called nonsense. See `docs/playtests/PLAYTEST-10.md`, section C.

### A pursuer can be a place before it is a moment

`charging_dog` is a **moment**: the director sites it in front of her and the chase is the whole of
it. `EventDef.pursues_within` is the other shape — a thing that is **somewhere**, that you can see
and price and route around, and that becomes a chase if you do not. Three states rather than two:

| | it emits | it can kill | it moves |
| --- | --- | --- | --- |
| **waiting** | at full strength | no | no |
| **noticing** (`telegraph_time`) | at full strength | no | closes to the stand-off |
| **chasing** (`duration`) | at full strength | yes | holds, then comes |

Two things are deliberately not the same as an ordinary telegraph. The **clock starts when it
notices**, not when the day put it there — a robbery whose telegraph ran at dawn four streets away
would arrive with no notice in it at all. And its notice does **not** damp what it is emitting:
`TELEGRAPH_INTENSITY_FRACTION` means *this has not started yet*, and a man who has been standing in
that alley since she came round the corner has started. What has not started is the lunge.

**The second of those flips for a row whose waiting state is the harmless one**, and
`EventDef.quiet_until_noticed` is where a row says so. `pigeon_flock` waits the same way without
being a pursuer at all — birds pecking on a pavement, priced and walked around from down the
street — and there the damping is telling the truth: what is standing there is nearly nothing and
the event is the flock going up. With the flag, the top two rows of the table above read *at
`TELEGRAPH_INTENSITY_FRACTION`* instead of *at full strength*.

**And what ends a telegraph is her, wherever a clock cannot know when the thing started.** A
pursuer's lunge fires when she reaches its stand-off rather than when its clock runs out, and a
flock's flush fires when she reaches the birds — `flock_spread` plus her own body — for the same
reason: the birds are on the ground for the whole telegraph, so its length is the wait between her
walking into them and them reacting, and a fixed wait puts them up behind whoever walked in.
`telegraph_time` is then the backstop for a flock she came near and never reached, and the
geometry `Tuning.validate_event()` checks is untouched either way.

`validate_pursuit()` gained two clauses for the trigger and a third that was found by measuring
rather than by thinking. It has to notice her from **outside its own stand-off**, or the notice is
spent standing still; from **inside its own field**, or it decides about her before she could have
felt it; and from **inside its break-off** — which is the one that bit. At a trigger of 170 against
a break-off of 170 the rig strolled away from the robber every time, because she was already
standing at the distance that means it has lost her.

**All three clauses are stated over derived quantities**, which is what lets the robber's trigger
and field move — as the stand-off changes, the trigger has to stay outside it and the field outside
the trigger, so *on sight* keeps coming before *he has seen you* — without any clause being
rewritten.

| she | outcome | cost |
| --- | --- | ---: |
| walks up and stops | caught | the day |
| walks up and past | caught | the day |
| walks away at a walk | caught | the day |
| runs when he stands up | shakes him off in 1.5s | 21 points |
| dithers a second, then runs | shakes him off in 1.6s | 22 points |

### A beat rather than a journey

`EventDef.paces` walks a route and turns round at the ends, for ever. It is the difference between
a `dog_walker`, which is *going somewhere* and is gone at the end of thirty tiles, and a man
shouting, who is **at** a place. Without it the only way to say the second thing is to make him
stationary, and a stationary source on a fixed patch is a line you draw once rather than something
to time.

A paced event never reaches the end of its path, so it never departs and never expires: it is a
fixture that moves. The price is its body — anything mobile is exempt from "solid things are solid",
because a moving wall on a two-tile pavement pins her against a building. What stops you walking
through a man shouting is the meter: intensity 14 over 210px.

**Nothing pursues before `RUN_TAUGHT_DAY` (day 3).** Day 1 says *Tap to walk, double tap to run* and
nothing more; day 3 is when something comes after the pram, and the HUD says *Double tap to run* —
naming no key on any device, since the keyboard's own **Shift** works silently like every other key
this game never puts on screen — on the frame the **first** pursuit of that day telegraphs, rather
than at dawn — a line of text at dawn is a control list, and the same line over a dog at the pram is
an instruction.
`EventDirector` moves that first pursuit to the head of its queue, so the lesson is not left to a
weight of 1.4. The hint says nothing again for the rest of the run: it is the lesson, not a running
commentary on the mechanic, so every later pursuit — a second dog the same day, `alley_robbery`
from day 8 — telegraphs in silence.

## Tearing a poster down

**She tears a poster down by pushing against its wall**, and there is no button for it. Her
heading has to point into the postered wall — at least thirty degrees off its line
(`PosterWalls.PRESS_INTO`), so a diagonal counts — while her feet are at its face
(`PosterWalls.PRESS_REACH`, a few pixels past where the pram stops her), for 0.4 seconds
(`PosterWalls.PRESS_TO_TEAR`). Walking past, even drifting into the wall, tears nothing; a push can
still happen by accident, which is how it is found. What is read is her steering rather than her
velocity, since the wall stops the one and not the other. A diagonal slides her along the wall, so
a push held along a papered wall tears a sheet every 0.4 seconds while she is in front of an
intact one.

The sheet shows one of the three tears and stays torn until a crew, or a dawn, pastes that wall
again. **A tear costs nothing on the meter and counts for nothing**: it is a gimmick, judged by
feel.

**What it can do is bring a patrol, and whether it does is drawn from a marble bag** rather than
rolled (`MarbleBag`, PLAYTEST-125): each tear draws one marble at random and removes it, and an
empty bag is filled again with the same set, so over every bag the share is exact where a roll at
the same odds runs streaks. The run's first bag is a pre-bag of one "no pursuit" marble, so the
first tear is always safe; every bag after it holds one "pursuit" and nine "no pursuit"
(`PosterWalls.TEAR_PRE_BAG`, `TEAR_BAG`). The bag draws from a stream of its own off the run's
seed, and its whole state is how many tears the run has made (`PosterState.tears`), so a save, a
lost day and a retry all draw the same marbles. A pursuit marble sends a `police_patrol` toward
her from off screen, down the carriageway lane driving toward her, under the lead the row already
owes (`EventDirector.send_a_patrol()`) — sited once she walks on along the street, since a heading
into a wall gives a car no street to come down. Only poster tears use a marble bag.

## Telegraphing

Every event has a `telegraph_time` (default `2.5 s`, longer for big events) during which:

- The event is **visible** (sprite, audio cue).
- It emits at most `TELEGRAPH_INTENSITY_FRACTION` (default `0.15`) of its full intensity.

A telegraph the player cannot perceive is not a telegraph. **Every cue must be legible with
the sound off** — audio reinforces the warning, it never carries it (see docs/EVENTS.md,
"Audio is never the only channel"). `Tuning.validate_event()` checks the geometry and cannot
tell whether the player was actually warned, so that part is on the author.

The design contract: *from the moment an event becomes visible, the player must have enough
time to walk out of its outer radius at normal walking speed.* Event authoring must satisfy

```
telegraph_time × walk_speed >= escape_distance × margin
```

where `margin` is 2 for `hard_fail` events, and

```
escape_distance = outer_radius − inner_radius     for anything at or below walking pace
                = outer_radius                    for anything FASTER than walking
```

The split matters. A stationary event, or one slower than the player (a dog walker at
32 px/s), only has to be walked away from, so clearing the falloff band is enough. Something
faster than the player — a fire engine at 190 px/s — cannot be outwalked at all; it sweeps
its entire outer radius along the street, and the only escape is getting off its line. So
it must give enough warning to clear the *full* radius. That is why the fire engine's
telegraph is 4 seconds and not the 2.9 the band rule would have allowed.

`Tuning.validate_event()` asserts this on load, and `tests/test_events.gd` checks it over
the whole catalogue, so an unfair event fails loudly rather than quietly ruining a run.

## Calm zones, and what every other ground does

Parks, quiet squares, forests and courtyards are `CALM` tiles. Inside them:

- Sleepiness gain ×`21` in a four-block zone, more in a smaller one — a second in a park is worth
  twenty-one on the street. Only calm ground fills the sleepiness bar at all, which is why that half
  stays a threshold rather than a rate.
- Excitement decay ×`2.0`, so the park reads on **both** bars — a full meter clears in eight and a
  third seconds of walking under the trees, which is fast enough to be worth the walk and slow
  enough that a park is a place rather than a switch.

**And the excitement half is a rate everywhere**, not calm-or-not:
`WorldContext.decay_multiplier()` answers with what this ground does, and the order is

    calm 2.0  >  precinct 1.5  >  ordinary street 1.0  >  alley 0.58  >  main road 0.02

so a route is a **recovery rate** and not only a set of things to walk past. Three consequences
worth holding on to. A precinct is worth walking to although it is loud — a retail street is busy,
and it is still the best ground outside a park to bring a meter down on. An alley is the shortcut
that is not recovery, which is what keeps the fast route a real choice rather than a free one. And
the main road is the calm zone's sentence inverted: it is the one ground in the city that is
actively bad at letting her recover, which is what *"a main road is crossed, not walked"* means
arithmetically. Walking its length loses a day in about seventeen seconds at act I density; that is
the intent, measured over three seeds with `tests/probes/m117_decay.gd`.

But calm zones are contested — see `docs/CITY.md` (spoiling) and `docs/EVENTS.md`. The spoiling
remembers a whole **act** rather than a night, and the city has one calm area per day of the longest
act plus one in reserve (`Tuning.calm_areas_needed()`), so finding a new one is the work of an act
and the parks go quiet again when it turns.

## Alleys

Alley tiles apply a constant `+3.0/s` excitement trickle. They are shortcuts, and they are
where the resistance meets. Both facts are the point: the fastest route and the story route
are the ones that cost you the baby's calm.

A resistance pickup's chalk mark follows her rather than sitting still: it counts as noticed
only once she has been within `ResistanceDirector.SEEN_DISTANCE` (150px, kept under the
visible world's own 180px vertical half-extent so the point is on screen on every bearing
rather than only a favourable one — never right at the screen's own edge) of it, on screen,
continuously, for `ResistanceDirector.SEEN_DWELL_SECONDS` (1.0s) — near enough, for long
enough, that walking past it rather than to it is a choice, not the instant its tile merely
swept across the camera on the way to somewhere else. Until then, walking more than
`ResistanceDirector.NOTICE_RADIUS` (400px) away from it moves it to the nearest reachable
alley tile within that radius of her instead — the alley's own mouth, on the path rather
than off it — skipping an alley a completed step's mark already stood at as long as some
other one is still in reach. Its guard moves with it, at the same 66–176px band from
wherever it lands.

Neither the mark nor its guard is ever offered ground she cannot reach that day: a held
segment, a sealed alley, or the ground behind a region wall's band — including a crossing
alley the wall seals at both mouths, which is unreachable in its own right even though it is
never on the closed-street list and never on a `StreetNetwork` segment.

## Day timer

Each day runs for `DAY_LENGTH_SECONDS` (default `180 s`, 3 minutes) of in-game dusk, and is
aimed at being won in about a third of that.
Running out is a day loss. The timer is shown as a light-level shift rather than a number,
with an explicit clock in the HUD corner, `m:ss` through `GameState.format_clock_seconds()`.

The summary between days (`DaySummary.show_day()`) names the same clock at the instant the day
ended, one line under its title: a won day reads *"She fell asleep after 1:24."*, a lost day
reads its own reason with the clock worked into it — *"She started crying after 1:24. There is
no settling her now."* for a crying loss, the reason then the clock as its own sentence for a
hard fail — and a day lost to running out of daylight shows only its reason, since dusk already
is the whole day and printing the day's own length back would only repeat it.
`GameState.format_clock_seconds()` is the shared `m:ss` formatter the HUD clock and this line
both read through, so the two can never disagree; the ending screen's *"Time played"* line stays
on `GameState.format_clock()`'s millisecond form, over the whole run rather than one day — see
"The run clock" below.

## The run clock

`GameState.play_seconds` is a second clock, over the whole run rather than one day: the sum of
every second a day spent `WALKING` or `RETURNING` with the tree unpaused. Not wall time, and not
the day timer above, which resets every day — a retried day's first attempt counts toward it, and
neither the pause screen, the day summary nor the title screen do.

It is hidden throughout play — no HUD, no pause screen, no day summary — and the ending screen is
the only place it is shown, once, on every ending alike: bad, neutral and good all carry a line
under their own body text reading the run's length as `%d:%02d.%03d`, to the millisecond.
`GameState.format_clock()` is the one place that format is written, so a second clock reading to
the millisecond calls it rather than carrying a second copy of the string.

## The escape, which is the run's ending

The walk out of the building and out of the city is the fifteenth and sixteenth walks of a run:
no route to a calm area and home, but one way out, played in two sections — the building and the
city — that are **each a day of their own**, with a day's brief, a day's clock and a checkpoint at
the brief.

**It is where a won run ends.** A day 14 that is won with every task complete — `GameState
.earned_good_ending()`, `Tuning.RESISTANCE_GOAL` errands run *and* the last night's sabotage
performed, the same pair that has always decided the good ending — goes on from its own summary to
the building instead of to the ending screen. A won day 14 without them keeps the neutral ending it
has. Nothing about the run is recorded as finished on the way in: `GameState.finish_day()` is not
called until she is out of the city, so the run has no `ending` and its save stays on disk for the
whole escape, which is what the checkpoints come back to. `--start-escape` reaches the same
sequence directly, with a fresh run behind it, so it can be walked without playing fourteen days
first.

**Nothing about the last night is the easy half.** *([PLAYTEST-121](playtests/PLAYTEST-121.md):
"the escape shouldn't be easy!")* The sabotage is a hand-over at the power station's door and
changes nothing there; once she is `Tuning.BLACKOUT_DISTANCE` from the station the city's power
goes (docs/CITY.md, "The power station"). Every mast stops with it, so the rest of the walk home
has no loudspeaker anywhere — but it is walked under dead traffic lights, across a spine that no
longer stops for anybody, with everything else the last day carries still out. The escape after it
is in the dark as well.

**A full clock per section, `Tuning.FINALE_LENGTH_SECONDS`, which is a day's own length.** Each
brief starts one, so the time spent walking down three floors is not time the city has lost: at the
service door the building's clock stops and the city's brief starts its own.
`FinaleController` owns a `DayController` rather than being a second one: the countdown, the three
losing paths, the `EventBus.day_time_changed` the HUD draws from, and `--invincible` standing the
clock still are all a day's already and none of them change. What the escape does differently is
only what happens at the end of one.

**The clock reads to the millisecond** — `%d:%02d.%03d` through `GameState.format_clock()`, in
place of a day's `%d:%02d` — and nothing else about it changes. Milliseconds ticking make the same
countdown read as faster, which is the whole of the reason.

**A lost section starts again where it began, and costs no Nerve.** Being taken, the meter reaching
100 and the clock running out are the same three losses a day has, and every one of them puts her
back at the start of the section she was in — the hallway outside her own door, or the service exit
— with a fresh clock, the baby asleep with sleepiness full again, and `GameState` untouched. A
fourteen-day run is never thrown by one wrong turn in the last minutes; at zero the way out is
gone, and what she does about it is walk it again.

**Every section opens on its brief**, a first walk through it and a retry alike — the same screen
between days that a resumed run opens on (`DaySummary.show_finale_brief()`), titled *"Escape the
building"* or *"Escape the city"* where a day's number stands, and carrying the Nerve count
unchanged, because nothing here spends one. Continuing from it is the moment the section actually
begins: the clock starts there and nowhere else, and the section's one hint line is said by the
HUD as she starts walking. A retry is not told that line a second time, the way day 1 teaches
tapping and then never again.

**And the brief is the checkpoint a closed game comes back to.** A save is written as each brief
comes up, carrying which section it is (`GameState.escape_section`, written beside the day-under-
way flag rather than inside the run snapshot, so a save from before the escape existed still
loads), and opening the game again puts that section's brief back up with a whole clock behind it
— the same way closing a game mid-day comes back to that day's brief. Nothing about the escape is
ever a day under way, so no nerve is charged for leaving one.

**Everything around a day exists around a section too, built the same way.** `Esc`, the pause
button and losing the window's focus open the same pause screen a day opens, with the same continue,
the same held restart and the same quit; the held restart ends the escape in a fresh run,
`GameState.escape_section` cleared, the same way it ends any other run. The touch controls, the
orientation handling, the developer readout and the debug-mode note are all the one instance each
boot already builds before it knows which of the two it is.

**The building shows what the city shows.** *(PLAYTEST-115: "The escape shouldn't behave any
different than the rest of the game.")* The screen-edge badge, the excitement halo and the debug
view's layers are built with whichever world a boot builds first and pointed at the next one when
she walks out of the service door. What they read is an **event source** — anything answering
`instances()`, which `InteriorEvents` does under the same name `EventManager` does — and a crowd
only where there is one, so indoors the masked man coming up a stairwell raises the same badge a
fire engine coming down a street does, and the fire she is standing beside wears the same rim a
dog on a sidewalk does. The debug view's fields, shadows and bounding boxes (`1`–`3`) trace the
building's events, walls and her; the readout (`4`) names the section and its clock where a day
names its phase; and the frame graph (`6`) is fed the same way. The route lines (`5`) have nothing
to draw in either section, since neither has a day's route tree. **The run log watches a section as
it watches a day** — see `docs/TELEMETRY.md`, "The escape's log".

What a day has that a section does not is the home-guidance arrow, since escaping owes no return
leg to point one at. The save indicator is built only for a run's own escape, never the flag's,
since a dev-flagged boot writes nothing a symbol could ever announce.

**Section one is a route with the first turn already taken.** A fallen ceiling fills the top
floor's hallway between her own door and the right stair door, both rows of it
(`InteriorMap.TOP_FLOOR_RUBBLE`), so the right stairwell cannot be entered on that floor at all and
the only flight down is the left one — which is the shaft the fire is in
(`InteriorEvents._BURNING_SIDE`, fixed rather than rolled, since a fire on the shut side would
leave her nothing). Getting past the fire means stepping through the nearest corridor door and
walking to the other end of that hallway, which is why the two stair doors are at opposite ends;
the right shaft it leads to is where the masked man is.

**And he keeps coming.** A masked man runs the right shaft foot to top; once he is out of the top
of it, another comes up from the foot `Tuning.FINALE_PURSUER_RESPAWN_SECONDS` later, for as long
as she is in the building. The answer is the one the row is built around — step through the
nearest corridor door and let him pass — and it stays available because from every cell of his
line a door is well under the three and a half seconds he spends standing still before he moves.
So the side she switched to is not a side she can settle on, which is the whole point of him: the
way down is a sequence of crossings rather than one.

**The building is dark, because it is the night of the blackout.** *(The player, 2026-09-20: "it
can be gloomy in the hallways and basement and maybe emergency (red?) lighting in the stairs".)*
Nothing in it has power: the wall lamps and the chandeliers are drawn unlit, and the part she is in
is multiplied by one light, her included (`InteriorScene.lighting_at()`) — a cold gloom in the
hallways and the lobby, darker in the windowless basement, and the red of the emergency lighting in
the two stairwells. The light changes only when she changes part, which is under a door's fade to
black. The city she walks out into is the same night, with every window and traffic light dark
from its first frame (docs/CITY.md, "The power station").

**The night outside is light and noise, and they are separate things.** Every
`Tuning.FINALE_EXPLOSION_INTERVAL` a bomb goes off close enough to shake the building: every
hallway window in it goes white for `Tuning.FINALE_WINDOW_FLASH_SECONDS` and the hallway she is in
is lit with it, and the meter takes the hit, wherever she is standing. Between those, far more often, a distant flash lights the same
windows the same way and does nothing else at all — no event, no field, nothing on the meter. A
shelled city is what she can see out of the window; what she is charged for is only what is close
enough to hear.

**Every window flashes together, always** — near bang or far flash, one call and no way to light a
subset, because a window lighting while the one beside it stays dark reads as a broken sprite
rather than as a city under fire. The waits between distant flashes are a short-biased smooth
draw on `[Tuning.FINALE_DISTANT_FLASH_MIN_SECONDS, _MAX_SECONDS]` (0.1s to 5s) with its mean at
`_MEAN_SECONDS` (1.3s), taken from the section's own seeded stream so a seed replays the same
night: mostly quick double-taps, with the occasional long dark gap. Two flashes close enough to
overlap run together as one longer one rather than blinking.

**And the basement is three gates on three clocks.** The corridor jogs between three brick-walled
bands and is one tile wide at three places on the way to the service exit
(`InteriorMap.BASEMENT_NARROWS`), each of them a cell the walk cannot go round. A steam vent
stands on each, in the same place every attempt, blowing on its own period out of
`Tuning.FINALE_STEAM_PERIODS` — 4, 4.5 and 5.5 seconds, pairwise coprime in half-seconds, so the
three of them never fall into a rhythm. A blow shuts its cell outright for
`Tuning.FINALE_STEAM_BLOWS_FOR` after a notice, and the shortest period still leaves twice as long
open as walking through the vent's reach costs. Waiting is the answer; there is no line past one.

**Two hint lines, said once each** as she starts walking a section she has not walked before:
*"Escape the building"* and *"Escape the city"* — the same words that head each section's brief,
so the line on the screen and the line in the HUD are one instruction rather than two.

**Section two is the city she knows with the men in it.** Army trucks, unmarked vans and
roadblocks at full resistance progress stand on every street either chain walks. A roadblock is a
barrier with a guard standing at it from the moment it is placed; when he notices her **he** comes
for her, on foot, and the barrier he leaves stays drawn and stays shut across the road behind him.
What takes the baby is his own reach (`EventCatalogue.MASKED_MAN_REACH`, 28px, the same as the man
on the stairs) — nothing about the barricade catches her. See `docs/EVENTS.md`, "The heat".

**It ends on the tunnel or the bridge**, within `Tuning.FINALE_EXIT_REACH` of the exit `CityEdge`
draws, on a summary screen with the way out behind her and nothing triumphant on it — and the clock
she took, to the millisecond, which is the only number that screen carries.

## Nerves

The run-level health bar. Starts at 5. Every lost day costs one. At 0 the run ends with the
bad ending. Nerves never regenerate — this is what makes an early bad day matter.

**Five is a number to be measured, not derived**, and nobody has played a run against it: the run
log's `nerve` entries are what say where they went. What makes it hard to reason about from first
principles is that a nerve is worth more now that it buys only a retry — three attempts were set
when a lost day *also* advanced the calendar, so a nerve cost a day of the fourteen as well as a
life. A run that ends on day 3 ends before the game has shown what it is.

**A nerve buys a retry of the same day.** The calendar moves only when a day is **won**, so the
nerves are failed attempts spread wherever they are needed and the fourteen days are fourteen days
the player actually plays. A lost day costing a nerve *and* a day punishes twice for one mistake and
hides act I from the player who needs act I most.

Three consequences, all of them chosen:

- **A retry is the same day.** The city, the closures and the whole event plan are deterministic
  from the seed and the day number, which is what makes a retry worth having in a game about
  learning a route.
- **What a lost attempt spent is given back.** *"a retry always rolls new -- nothing that happened
  on the day that got retried can influence the next repeat -- that has been a long standing
  rule"*, and *"it is the same day exactly how the player encountered it the first time this run.
  exact same state at the beginning of the day. nothing else"*. A retried day is the state the run
  was in that morning: where she settled, everything the resistance did, and everything the attempt
  did to the city — the one-shots it consumed, the scars it left and the block arcs it advanced.
  Only a day she **wins** keeps any of it. See `GameState.finish_day()`.

**A lost day gives the resistance back.** *"a task is only complete if it is done on the day that
won"*: a mark touched, the task it unlocked, a contact lost to its deadline, a package picked up
and the day-14 sabotage are all undone when the day is lost — a task is one day, so both halves of
it are the same attempt's to lose. `GameState.begin_day()` photographs the five fields that say
what the resistance has done — the completed steps, the failed ones, the progress count, the
package and the sabotage — and the loss restores them before the retry, so the retry starts at the
same mark again, in the same place, from the same seed. A won day commits the photograph.

**And gives the day's fire back with it.** Three more fields are photographed beside those five and
restored the same way: `consumed_one_shots`, `scars` and the whole of `CityState`. So a day 3 lost
after the fire burned owes a fire again — sited from whatever walk the retry takes, which is why a
player who lost walking east and retries walking west meets it on another street — and leaves no
shell standing in the meantime. The city photograph is taken **before** the dawn arc roll, since
`GameState.begin_day()` runs ahead of `CityState.begin_day()`, so the retry's own dawn makes that
roll again from the same seed and the same day rather than inheriting it. **The once-only
happenings of days 10 to 13 come back the same way**, since each is kept in one of those fields: the
block day 11 boarded up and the park day 12 took are arc steps in `CityState`, the barricade day
13's column left is a scar, and whether day 10's neighbor was taken is read off the completed steps
(`GameState.neighbor_was_taken()`). A retry of any of those days meets its happening again.
- **The run cannot end by running out of days while nerves remain.** The bad ending is the only
  way to lose, and the run length becomes a promise rather than a budget.

## Saving and resuming

The run is saved implicitly — there is no save button, no slot and no menu — at exactly two
moments, each saying which one it is. `GameSave` is the one place every read and write of it
happens, gated behind `GameSave.uses_save()` so a dev flag, a headless run, the test runner and
`tools/check.sh`'s own boot never touch it: every checkout and worktree of this repository shares
one `user://`, and none of those runs may land in or overwrite what may be the player's own day 9.
A run carrying any dev flag already falls outside the gate by being one; `--no-save` is what a
flagless `tools/run.sh` session asks for the same thing with.

**Written `day_under_way: false` the instant a resumed run's own retry exists but has not yet been
handed to the player** — `main._write_dawn_for_a_resumed_run()`, called right after
`main._start_day()` builds it, before the title, or the title and then the day brief, is ever
shown — **and written `day_under_way: true` the instant she actually starts playing a day**:
continuing from the title on a fresh run, from the day brief a resumed one opens on, or from the
previous day's own end-of-day message straight into the next day, which has no gate at all between
the two. Because the `false` write above always lands before the day brief a resumed run shows
itself, whatever the load just charged is already on disk by the time she is looking at that
screen — so a kill at any instant finds exactly what is on screen, never a free retry of a day
that was started and never a second charge for one abandoned day. **A fresh run writes nothing at
boot at all** — merely opening the game to look at the title is not playing it, and there is no
earlier charge on disk to protect — so the first write a fresh run or a held restart's next run
ever makes is the `true` one, the instant its own title is actually dismissed; a save never
appears just from looking at the title screen. The end-of-day message writes the same `false`
that a resumed run's boot does, at the moment it comes up rather than at a dawn nothing stands
behind. Nothing else writes: losing focus, a phone sending the game to the background, closing the
window and quitting all still do what they always have — the game still pauses on focus loss
(M161), the run log still closes — but none of them changes what a save holds, since a save is the
run and the day, never the moment inside one (PLAYTEST-82).

**A save holds the run, never the moment inside a day.** `GameState.save_snapshot()` — the seed,
the day, nerves, resistance progress, scars, consumed one-shot events, the block arcs the run's own
history has moved, where she settled each day and the run's clock — plus three facts the run does
not know about itself: whether a day was under way when the file was written, which section of the
escape it is in, if any (see "The escape, which is the run's ending"), and which alley tiles the
resistance has already used for a completed mark, so a mark on a later day does not reuse one it
does not have to. Her position and heading,
the meter and the sleepiness, the day's own clock, every event instance and the crowd are not
saved; the city and each day's plan need none of this either, since both are functions of the seed
and the day. Recording the moment itself would have to carry the crowd, every event instance and
the random state, with every later change to any of them owing the save format its compatibility —
the largest option, for a requirement (quitting is never an escape) a lost-day penalty already
satisfies at dawn instead.

**Opening a game whose save says a day was under way loses that day**, through the same code path
an ordinary lost day takes: one nerve, the resistance given back, the same day again, the last
nerve ending the run exactly as it does there. **The title comes up on every boot of a day that has
a save to come back to**, with the street outside her own front door running behind it exactly as
it does for a fresh run. Pressing start with a save on disk brings up the day brief instead of
starting the day outright — the screen `DaySummary` draws between days, carrying the day, the
nerves and the morning's own line for the calendar day, plus the line that a day was lost to
leaving it when the load itself charged the nerve above. Continuing from the day brief is the
moment the day actually starts, and the moment the first of the two writes above says so. If the
load spends the run's last nerve, the day brief never shows at all — the ending does, the same
screen and the same continue any other run-ending reaches. A save written once a day has already
ended at its own summary, or at a day brief before it is ever continued past, costs nothing:
opening it again finds the same nerve count and shows the same screen, and pressing on from there
is what actually spends anything.

**A save written inside the escape comes up the same way.** The escape's own boot always knows
which section a save named — `GameState.escape_section`, restored before the section is built, is
what decides whether the building or the city is built at all, not only where she stands inside
it — and a save closed mid-city-section reopens in the city rather than being rebuilt underneath
her from the hallway. What is asked first is whether this boot is **reading that section off a
file** rather than carrying it forward from a won day 14 handed over earlier in the same process:
the two reach the same boot with the same non-empty `escape_section`, and the only thing that
tells them apart is whether the value was already on the autoload before the save was read or
only arrived from the file — see `main._escape_resumed_from_disk`. A genuine resume answers the
title first, the same screen a resumed day answers first — paused rather than run behind, since
the section it stands in front of has no city day's worth of scenery to keep moving for its own
sake — and pressing start raises that section's own brief over the world already built behind it
rather than reloading anything; the handover reload from a won day 14 answers `false` and opens
straight on the brief, since nothing about walking into the escape she just earned should feel
like reopening a save.

**A save a newer build cannot read is dropped for a fresh title screen, never half-loaded.**
`GameSave.FORMAT_VERSION` is what a build compares — an ordinary release never bumps it, so a
newer build still finds an older one's save, and only a change to the shape a save carries drops
one. The build that wrote a save is recorded alongside it for a person to read, never compared
against; releasing a newer build must not by itself throw an old save away.

**The held restart clears the save.** Both the pause screen and the day summary offer it, and
starting over is what it has always meant — nothing new is drawn for clearing it.

A small symbol appears in a corner for a few seconds after each write and fades out, on whatever
screen is up — twice in an ordinary day: once when it starts, once when the day brief or the
end-of-day message comes up for the next one. It names no key and is not a danger cue; it is the
only thing that ever tells the player a write happened at all, since saving itself is otherwise
silent.
