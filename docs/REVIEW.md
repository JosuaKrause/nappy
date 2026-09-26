# Review

**What waits on a human.** Everything here is built, measured by a rig, and unfelt: a person has
to play it, look at it, or decide about it. *(2026-09-11: "keep a document with items that need
human review / test runs. That way you can keep working without having to stop. And test runs
can capture multiple items at once.")* The work goes on while this list waits, and one run
answers as many of these as it passes through.

**How it is kept.** Each item is a file under [review/](review/), named after the queue entry
whose work it asks about (`<entry name>.md`, and `<entry name>-2.md` for a second item from the
same entry). It enters when work lands that only a person can judge, in the same PR as the work,
and names what to do, where to look, and the question a run answers — not what was built, which
is the record's under [decisions/](decisions/). A playtest closes the items it covered: the
finding goes in the playtest's file, the item's file is deleted in the same commit, and what the
player asked for goes to the queue. Nothing here is a task; a task is an item under
[todo/](todo/). What no person has tested yet, the list at the end of this file, stays a list
here.

## Next run, in one sitting

Each file under [review/](review/) is a thing to try or look at and the question it settles.
`tools/run.sh` plays the desktop build; `--seed <n> --day <n>` puts a run where an item says; `1`
to `5` in a debug build toggle the field, shadow, bounding-box, readout and route-line layers
(`docs/TELEMETRY.md`, "The debug view"). `--invincible` is the way to walk the whole list in one
sitting: nothing ends the day, the clock stands still and the excitement meter never rises, so one
run can stand next to every item for as long as looking takes.

## What is untested by a human, listed so nobody mistakes arithmetic for a verdict


- **Walk the apartment and judge the remaining reference-based interior graphics.**
  `tools/run.sh --start-escape` (debug only; `--start-escape stairwell:left|stairwell:right|lobby|basement|floor:2|floor:1`
  boots into a part) puts her, carrying the baby, in front of her door on the third floor of a
  building with three hallways, two switchback stairwells at opposite ends, a barricaded lobby and
  a winding basement to the emergency exit — one map, the parts 64 tiles apart, every door a fade
  and a teleport. The south-edge doors are plain indents, with a brown bar across an indent being
  the whole of what says closed: do the bars read as closed doors at play scale, and does the
  fade-and-teleport read as a door or as a cut?
  Records for the remaining interior are in `DECISIONS.md` under M112, the escape scene and
  interior graphics; what the finale lays on top of the building — its events, and the way out
  through the service door — is the escape walk in the list above.

- **Every field has a shape now, and nobody has felt one.** A stationary body's field is a capsule
  about its own spine rather than a disc about its centre, and a moving thing's is an ellipse with
  the emitter at the rear focus: it reaches exactly as far ahead as its catalogued outer radius
  always did and less far behind and beside — a car at cruising speed (`e` 0.5) reaches a third of
  that behind it and half of it abeam. The café and the market stall bill from the tables to the
  middle of the carriageway (`inner_radius` 38, `outer_radius` 64, both measured from the spine) and
  no further; the roadblock, the protest, the burnt shell and the firefight lost their segment's
  half-length from both radii. The two eccentricity constants (`Tuning.FIELD_ECCENTRICITY_MAX` 0.7,
  `FIELD_ECCENTRICITY_SPEED` 260px/s) were set by design and checked against one rig picture,
  `docs/evidence/m61-field-after.png`. Whether a car going *past* still costs enough to notice,
  and whether a café at 64px still forces the crossing it was built to force, are played questions;
  `tests/test_balance.gd`'s relationships hold and the per-street probes moved within noise, but
  *is the day still losable on the meter* is asked by a rig only. The record is in `DECISIONS.md`
  under M61, the field.
- **Every shadow is drawn from a shape and every spread stands on a capsule, and nobody has looked
  at one in play.** A band-shaped shadow under a roadblock, a car's shadow along its own length, a
  swing frame's along its width; and a barricade, a roadblock or a construction band is solid as a
  48px-thick capsule rather than the disc it used to be, so she can stand closer to it along the
  street than before. The sealing and pavement guarantees are asserted over the capsule in
  `tests/test_shapes.gd`; whether a thinner body reads as *right* or as *a wall she can lean
  through* is a played question, and the debug view's bounding-box layer (`3` in a debug build)
  is the instrument to answer it with.
- **The city is walled off the path and nobody has walked it.** About 369 seal bodies a day stand on
  the 187 streets the day's tree does not use, and a day now plans four to five hundred events where
  it used to plan a hundred and thirty. Everything about it is measured and none of it is felt.
  **The specific worry, from a rig:** walking blindly away from the route on seed 2102613802, day 6
  meets a wall at the second street, cannot move for thirteen seconds, and loses the day at 17.6s
  with excitement at 100 — and the log says `crowd 28.0/s, events 0.0/s`, so it is the crowd shoving
  a stopped player, not the seals. A player who routes would not stand there. It is still the first
  time the wrong direction loses a day inside twenty seconds with nothing telegraphing it.
- **A wall with a gap in it is an invitation, and nobody has taken one.** A fraction of the day's
  soft seals lose one of their two bodies, so the street still looks obstructed and is walkable down
  the far side. The whole point is that a wrong turn stays open long enough to be taken and returned
  from — *"guide the player without having the player know they are being guided"* — and whether a
  half-open pair reads as an opening or as a barrier somebody forgot to finish is exactly the
  question the arithmetic cannot answer. The fraction is one constant and it is meant to move against
  a played day.
- **No day plans a route along the main road any more, and nobody has walked the city that makes.**
  Crossing the spine is untouched and free; running along it is refused when the tree is grown. The
  measured consequence is elsewhere and it is worth watching: the covering sets a one-shot is offered
  got **17 points narrower** — 45.7% of runs offered a single site before, 63% after — so an authored
  set piece is more often placed in one spot rather than on every route she might take. That is a
  fairness contract getting thinner, and it is a number rather than a complaint so far.
- **Every route the game plans is now grown on cells, and nobody has walked one.** The day's corridor
  is a chain of two-tile cells rather than a list of whole streets, so it can cut a corner through a
  park or take an alley — which is the point, and which also means the shape of a day's route is not
  the shape any played run has ever had. It is verified by the test rigs and by one dusk map read off
  a screenshot. **Whether a corridor that cuts through a park still reads as a route** is the
  question, and it is a played one.
- **No barrier is placed beside a calm area any more, and that is a third of the lattice.**
  `ClosurePlanner` refuses every access street of every calm area outright — a measured mean of 33.4
  of 264 streets a day. The intent is that a closure stops reading as broken; the risk nobody has
  looked at is the opposite one, that closures now cluster away from the places she actually walks and
  stop being met at all. The same trap the region doors carry, in a new place: *a nudge that
  removes the decision is worse than a closure that does nothing.*
- **The whole of the heat is unfelt.** Every number in it was set by design and checked by a rig:
  nobody has walked a city at full resistance progress, and the item that would tell you whether it
  is fair — measuring it against the five nerves — is the one still queued. It makes the back half
  harder *precisely for the player doing well at the optional path*, and **nobody has ever reached
  act III**. The night raid is the newest rung of it: on day 10 it hunts, and is lethal, only for
  a player holding every perform so far, and no run has reached day 10 with any.
- **A roadblock's guards have never been seen leaving their post, and the barrier has never been
  seen in play.** The hunting copy draws the standing then the lunging guard the frame it stops
  waiting, and the band is one continuous barrier with end posts rather than a row of blocks; both
  were checked by rendering the textures headless, since two rig attempts to frame a forced
  roadblock failed, so no capture exists in `docs/evidence/`. Whether a guard on foot reads as
  *the roadblock coming for her* rather than a checkpoint's guard out of place is a played
  question, and so is whether a street its guards have left reads as open.
- **An investigating patrol has never been seen.** The claim is that a police car breaking off its
  route to follow her reads as *being noticed*. That is a screenshot question and no screenshot has
  been taken.
- **The van's victim reads as a man standing next to a van.** A screenshot of the scene is in
  `docs/evidence/` and it is the weaker of the two taken: the figure is upright and unheld, so the
  whole of *being taken* is carried by it walking in and disappearing over 2.5 seconds, which a
  still cannot show and nobody has watched. The hunting half came out better — end-on, closing,
  and not comic.
- **Everything that comes at her now starts off screen, and nobody has watched one arrive.** A
  pursuer and a `TOWARD_PLAYER` row are sited past the edge of the view along the heading she is
  actually walking, plus 200ms of closing speed — 51px past the boundary for `cyclist` (165px/s,
  closing at 257 against her 92), 44px for `charging_dog` (130px/s, closing at 222) — and a
  `hard_fail` row goes further still so its telegraph ends before it arrives, which for the
  cyclist's 3.3s telegraph is 900px. **Two things a rig cannot answer.** Whether the screen-edge
  badge actually reads as *something is coming* for the whole of a longer approach, rather than as a
  mark that sits there — and **whether the day-3 dog still teaches running**, since it was
  deliberately sited too close to walk around and now is not. *"Unavoidability, if it is still
  wanted, has to come from somewhere other than siting it too close to see coming"* is written down
  and not built.
- **A biker can now end the day, and no biker has hit anybody.** The row declared `hard_fail` all
  along and could never fire it: `EventInstance.is_lethal_at()` refuses while the event
  `is_telegraphing()`, and the old siting delivered it in 0.78s against a 3.3s telegraph. It is real
  now, and *lethal on contact with a 33px band* has never been felt at the speed a bike travels.
- **A hunting van drives along the footway.** A pursuer steers straight at her over any walkable
  tile, which every pursuer in this game already does; this is the first time the thing doing it is
  a van. Whether that reads as menace or as a bug is a question for somebody watching it.
- **The difficulty has been felt by a human once**, and that was a verdict on one density pass and
  one act I. The sleepiness numbers, the nerve economy, and whether the arterial is crossable are
  all still arithmetic checked by `tests/test_balance.gd` and unfelt. **Nobody has ever got past day
  4**, so the whole of acts II–IV is seen by nobody.
- **Five nerves is a number nobody has played against.** It was raised from three after a run ended
  on day 3 — but two of those nerves went on a **defect**, so the number was raised against a
  difficulty that no longer exists.
- **A spoiled park is nine things and nobody has stood in one.** The coverage is measured — 91% of a
  courtyard, 99% of a four-block zone — and what is not measured is whether it reads as *the park is
  busy today* or as somebody having tipped an event budget into a field. It is also the one place
  where `EVENT_SPACING_SAME` does not apply.
- **The robber and the pacing man have never been met by a person.** The robber is the most
  mechanically complicated row in the catalogue — a field, a trigger, a notice, a stand-off and a
  break-off — and every number on him is a rig's. The pacing man is a man with no body on a 64px
  footway, avoided by the meter alone.
- **Every pavement obstacle moved this session and nobody has walked past one.** A stationary,
  unpinned body is now centred on the two-lane pavement band rather than standing at its lane's
  centre, and a spread on a north–south street is now laid along that street instead of across it. So
  `construction` genuinely blocks a 64px pavement — she needs 46px of clearance and the band gives 32
  — where before it left a free lane. That is the intent and it is also the first time an act I
  obstacle has been physically impassable in play. **Whether it reads as *cross the street* or as a
  wall dropped on the pavement is a played question**, and it is the one the sealing places about a
  hundred and fifty of a day, in eight kinds that nobody has walked past either.
- **A street that is solid has been walked by a rig and by nobody.** About two thirds of the
  catalogue has a body. The open question is not density but whether being stopped reads as *cross
  the street* or as an obstacle course. The gap between a kerbed van and the frontage is smaller
  than the pram, which is intended and is also the exact shape of *"no line to walk"*.
- **Most of the silhouettes have never been seen in play.** Only five are reachable before day 4.
  The two to distrust are the ones that are more than a picture: the **robber's two postures**,
  where the whole claim is that *waiting* and *coming* are told apart at an alley's length, and the
  **protest**, a 110px wall of bodies on a crossing.
- **A flock has been walked through by a rig and by nobody.** The gradient is measured — +35 through
  the middle, +8 eighty pixels off it, nothing at the rim — and it is the only row where the cost
  table and the thing the player meets are computed differently.
- **Calm ground is more than twice as fast as anybody has played it.**
  `SLEEPINESS_CALM_ZONE_MULTIPLIER` is 21 and a four-block zone fills the meter in **11.3s from
  empty**, against a 10.8s lap of one. That margin is what decides whether a day is winnable once
  the park is reached, and the last human verdict on the difficulty was given when the same
  constant was 12.
- **There is no audio at all.** Less urgent than it sounds: audio is redundancy, so the game must
  already be fully playable without it.
- **Nobody has measured the web build, only confirmed it runs.** It boots and plays at the live
  address; what has not been checked is frame rate at the game's scale on a machine that is not the
  one it was built on, and whether a stranger arriving at the page understands what it is.
- **A release build carries no modifiers, and nothing has confirmed that on a real release build.**
  `?telemetry=1` answers only when `OS.is_debug_build()` is true. The truth table is asserted in the
  suites, so the *predicate* is proven; the build type itself has no seam to fake and is therefore
  untested. **The deployed page is the first real check**, and what to watch is that it still starts
  and still logs nothing.
- **The city just got much cheaper to walk through and nobody has walked it.** Five barrier rows
  emit nothing at all now and the two that kept a field had their reach roughly halved, against a
  day that plans several hundred of exactly those bodies. **Whether the day is still losable on the
  meter** is asked by `tests/test_balance.gd` and answered by nobody. The opposite risk is the one
  to watch for: the complaint was that a quiet pavement never gave the meter back, and the failure
  this creates is a city that no longer costs anything to cross.
- **Four rows changed what they do to a player and all four were set by a rig.** `cat_dash` at 17
  and `loose_dog` at 39 are meant to land as a startle without becoming a day lost to something
  behind her; `chatting_mother` at a 48px `detain_radius` (with her 56px inner radius widened to
  hold it) and `cyclist` at a 33px lethal band are both meant to stop being walkable-past. The
  chatting mother's is the one to distrust: her capture reaches three quarters of the pavement
  band, **so no lane of her own pavement avoids her**, asked for twice by the player — at 26 and
  again at 33 — and felt at 48 by nobody yet.
- **The bollards are a placeholder drawing, and the border now refuses the crowd.** Five posts seen
  from above close each precinct mouth's carriageway, and the player has seen them and the
  T-junctions on a played branch. What nobody has watched is the crowd at the border since it
  became a wall: a walker or a car that reaches the boundary pavement turns or is clamped onto the
  map's last row, and the one body allowed out is a car on the spine by the tunnel or the bridge.
  Whether that reads as a city edge or as bodies bunching against glass is a played question.
