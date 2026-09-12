# Review

**What waits on a human.** Everything here is built, measured by a rig, and unfelt: a person has
to play it, look at it, or decide about it. *(2026-09-11: "keep a document with items that need
human review / test runs. That way you can keep working without having to stop. And test runs
can capture multiple items at once.")* The work goes on while this list waits, and one run
answers as many of these as it passes through.

**How it is kept.** An item enters when work lands that only a person can judge, in the same PR
as the work. It names what to do, where to look, and the question a run answers — not what was
built, which is `DECISIONS.md`'s. A playtest closes the items it covered: the finding goes in
that `PLAYTEST-NN.md`, the item leaves this file in the same commit, and what the player asked
for goes to `TODO.md`. Nothing here is a task; a task is `TODO.md`'s.

## Next run, in one sitting

Each line is a thing to try or look at and the question it settles. `tools/run.sh` plays the
desktop build; `--seed <n> --day <n>` puts a run where an item says; `1` to `4` in a debug build
toggle the field, shadow, bounding-box and readout layers (`docs/TELEMETRY.md`, "The debug
view"). `--invincible` is the way to walk this whole list in one sitting: nothing ends the day,
the clock stands still and the excitement meter never rises, so one run can stand next to every
item below for as long as looking takes.

- **Cross a region door on foot, from day 7** (`--day 7`; a door is the hut-boom-hut across a
  boundary street). The boom hangs between its posts across the lanes, level with the huts; the
  inspection starts as soon as she stands against the hut; the camera eases from where it was
  drawing to the hut and back, the hut stays drawn with its guard gone, and she comes out on the
  far side and is left alone until she walks away and back. Does the hold read as one move, and
  does walking out of the door's area and back in, about a third of a second on a pavement, read
  as a fair toll or as being charged twice for hesitating? Record is `DECISIONS.md`, M100, the
  checkpoint as played.
- **Walk the approach to a door with the field layer on** (`1`). A hut's field is a 98px disc,
  grown from the invariant that a captured player is fully charged rather than from a balance
  decision. Does the approach to a wall crossing now cost more than it should? Same record.
- **Walk her into a wall, a corner and a barrier at an angle** (any day; `3` shows the bodies).
  The pram's body is an 8px circle centred on the edge of her own 14px one, so the pram's far
  half overlaps what it meets and she stands against a wall again. Does the pram still catch on
  corners, and does the far half clipping into a wall read as wrong? 8px is a guess. Record is
  `DECISIONS.md`, M100, the pram's body sits on her circumference.
- **Turn on the bounding-box layer and look at everything** (`3`). It now draws every body physics
  reads, from the collision nodes themselves: hers, the pram's, buildings, events, closure
  barriers and the map's boundary. Is there any body you can walk into that has no outline? Same
  record.
- **Click to set a heading, then press an arrow or WASD while she walks** (either control mode).
  She walks in the key's direction only, and the joystick knob reads as stopped. Does a held Shift
  survive it, and does a click afterwards aim fresh? Record is `DECISIONS.md`, M100, the keyboard
  resets the pointer's aim.
- **Find a crossing alley walled at its mouth on day 7 or later** (`--seed 2199579682 --day 7`,
  tile 95,88). The band is 64px wide, flush with the alley's paving, no longer over the roof
  edges either side. Does it still read as standing on a roof? Record is `DECISIONS.md`, M100, a
  region wall fits the alley mouth.
- **Walk north into the top of any building.** Her body goes 6px into the roof's northern edge
  before stopping. Does that read as leaning into the top of a wall, or is it too little to
  notice? Same record.
- **Run `--invincible` for a couple of minutes beside a loud event** (any day). The clock and the
  light stay where the day started and the excitement bar never rises, while the crowd, the
  events, the closures and the checkpoints all still run. Does anything still flash or darken, and
  is a held day still useful for looking at the rest of this list? Record is `DECISIONS.md`,
  M100, invincible freezes the clock and the meter.
- **Find a crossing alley walled at both mouths on day 7 or later** (`--seed 2199579682 --day 7`
  has one). No chalk mark and no robber ever stands on its paving; the mark is offered somewhere
  she can reach. Does the mark ever appear behind a band anywhere else — a closure, a soft seal?
  Record is `DECISIONS.md`, M100, a blocked-off alley has no chalk mark.
- **Stand by a sealed street and watch the crowd** (any day; seals are the bodies on the streets
  the day's route does not use). Walkers and cars turn back from a hard seal, a wall and a
  closure; a soft seal takes both pavements from walkers and leaves the road to cars; a door lets
  cars through one at a time. Does a street the crowd refuses read as *shut*, and does the crowd
  ever look stuck against it? Record is `DECISIONS.md`, M110. **And the open question is
  yours**: should a café, a construction band or a kerbed van divert the crowd the same way?
  `TODO.md`, M110.
- **Stand by a region door on a busy street and watch the walkers** (day 7 or later,
  `--invincible`). Most stop beside the hut, vanish inside for a second, come out on the far side
  and walk on; one in eight walks straight through; one in four turns off at the last junction;
  never more than three are committed to one hut. At real density a hut was occupied only now and
  then in the rig, so does the hold ever read on screen, and if a door should read as busy is the
  lever the hold length or the fractions? Does a walker turning round where it stands, when it
  meets a full door from inside the door's own street, read as wrong? Record is `DECISIONS.md`,
  M110, walkers are held at a door.
- **Find a roadblock on day 7 or later** (a 120px barrier across a road, drawn as one continuous
  barrier with end posts). Does it read as one barrier rather than blocks? At resistance progress
  3 of 4 performs, its guards leave the post and come for her on foot, standing then lunging —
  nobody has reached that state. Does a guard on foot read as *the roadblock coming for her*, and
  does the street it left read as open? Record is `DECISIONS.md`, M56, the roadblock hunts.
- **Find the burning building on day 3** (`--day 3`; it is on a pavement against a building). The
  engine arrives along the fire's street only once the fire is on screen. Does the engine read as
  *summoned by the sight*, and does a day where she never finds the fire feel different? Record
  is `DECISIONS.md`, M101.
- **Walk a precinct end to end** (a pedestrian street with bollards at each mouth). Nothing is
  built over its paving any more. Does it read as one paved place? Record is `DECISIONS.md`,
  M100, a precinct's pavement.
- **Meet the dog on day 4 or later** (`--day 4`). It is placed on the map now, never on her
  line, and it charges from off screen the moment she passes within a block of it. Does it read
  as *a dog that was somewhere* or as the lesson again? That is the open question in `TODO.md`,
  M96, whether it should wait to be routed into; a played answer decides it. Record is
  `DECISIONS.md`, M96.
- **Watch a car turn at a junction, and one turn round at a closure** (any day; a closure or a
  seal on a road sends cars back). A car now drives to the mouth of the junction, eases to a turn
  speed, follows one arc onto the centre of the lane it is joining and picks up speed again; an
  about-face is a half circle inside the junction box, or, with no junction to reach, in the
  street with its body over the kerb by a few pixels. The crowd car's picture follows the arc
  now — side, diagonal, front or back by its actual heading, standing pictures registered so the
  box and shadow (`2` and `3` in the debug view) sit on the body — so judge both: does a turn
  read as a car turning, does the pause at the mouth read as slowing rather than stalling, does
  the picture ever jump a view or float off its shadow, and does a street about-face over the
  kerb read as wrong? That last one is the open question in `TODO.md`, M111. Records are
  `DECISIONS.md`, M111 and M108, the crowd car.
- **Look at a parked delivery van and, from day 7, a police car on patrol.** The delivery van and
  the abduction van now face east when parked facing east; before, their west-authored pictures
  were drawn unmirrored, so a van sited nose-east showed its nose west. Does the parked van read
  as facing the right way along its kerb? The police car is the one event vehicle that turns
  corners, so it shows the diagonal views: do its markings and light bar hold up from every
  side, and does it sit on its shadow at the diagonal? Record is `DECISIONS.md`, M108, the event
  vehicles.
- **Look at the people and animals in events from more than one side** (any day). The dog
  walker and his dog, the pacing yeller and the chatting mother, the cat, the loose dog, the
  charging dog, the cyclist and each pigeon now face the way they actually move, through the
  same eight views the mother has; a stationary busker, poster crew, leaf blower or protest rank
  faces the way its site was placed; the waiting robber turns to face *you*; café sitters share
  their frontage's facing. Does a figure seen from behind still read as what it is, does the
  robber turning toward you read as a tell or as a glitch, and do the café sitters all facing one
  way read as a party or as a row? Record is `DECISIONS.md`, M108, the event people.
- **Watch any walker on any pavement.** They stride now, two frames alternating at the mother's
  own rate, frame a whenever one stops. Do the feet read as walking at street scale, and does a
  queue of stopped walkers read as standing? Record is `DECISIONS.md`, M108, the walkers' stride.
- **Watch a dog walker, a cyclist, a running cat and a lunging robber, then sit by a café and a
  busker** (any day; `--spawn event:dog_walker` puts one beside you). Every event person and
  animal that moves now strides too, two frames at the same rate as the mother, and the walker
  and his dog flip together; the café sitters lean every few seconds and the busker's strumming
  hand goes up and down twice a second, each on its own timer. Do the strides read at street
  scale, does the cyclist's pedal swap read as pedalling or as a twitch, and is the busker's
  tempo right? Record is `DECISIONS.md`, M108, the event strides.
- **Watch walkers round a corner or step aside for you** (any day, any busy pavement). A walker
  now picks one of eight views from the way it is actually moving, so it shows a diagonal picture
  for the few tenths of a second it is steering across its lane, and a stopped one keeps its last
  facing. Does the diagonal moment read as *turning* or as a flicker, and does a walker ever face
  the wrong way while standing? Record is `DECISIONS.md`, M108, the crowd walkers.
- **Walk through an alley in act I.** A mouse waits in some of them and darts across once she is
  within 150px, after a short telegraph. Does it read as a startle rather than a threat, and does
  the dash read as *across her path*? Record is `DECISIONS.md`, M100, the mouse in the alley.
- **Reach any ending and read the last line.** The run clock is there, to the millisecond, and
  nowhere else — not the HUD, not the pause screen, not a day summary. It counts only while a day
  is being walked: a retried day's first attempt counts, a minute on the summary does not. Does
  the number feel like the run's length, and is *hidden until an ending* still the right call?
  Record is `DECISIONS.md`, M107.
- **Walk one block of each district and look up.** Roofs carry furniture by district (vents,
  ducts and boxes on industrial, skylights on civic, water tanks elsewhere), commercial ground
  floors are storefronts with awnings, civic fronts have a portico, residential facades a fire
  escape, and pavements have trees in pits. In the rig pictures commercial and residential read
  at a glance; industrial and civic are told apart by their roofs alone, which are small at play
  scale, and the portico was out of frame. Does each district read as a place, and does the
  street-tree density read as a street or as a hedge? Record is `DECISIONS.md`, M106.
- **Find a fallen tree.** A fallen tree closure prefers a street with standing trees. Does the
  fallen tree read as one of the standing ones down? Record is `DECISIONS.md`, M106.
- **Play or jump to day 5, day 9 and day 13 and look at the ground** (`--day 9`). The city
  degrades on one curve from day 5: cracks on pavement before road, in three levels; litter on
  pavements, alleys and squares; garbage sacks in alleys first and against building fronts from
  day 7; storefronts and windows shuttered on a boarded-up block and, later, on some commercial
  ones. None of it changes what a route costs. Does the decline read as *the acts*, is day 5 the
  right first day (the range was "day 4 or 5"), and does anything read as a bug rather than as
  decay — litter under a car, a sack in the way? **One decision is yours**: a sack pile in an
  alley has no body yet; whether an alley narrowed by rubbish should cost the route is decided
  when a pile is seen in an alley she has to use. Record is `DECISIONS.md`, M105.
- **Look at a park or a forest block.** Trees keep at least a canopy's width apart now. Do the
  lots still read as *wooded*, or has the spacing made them look planted in rows? Record is
  `DECISIONS.md`, M100, the park trees.

## What is untested by a human, listed so nobody mistakes arithmetic for a verdict


- **Walk the apartment and judge the reference-based interior graphics.** `tools/run.sh --start-escape` (debug only;
  `--start-escape stairwell:left|stairwell:right|lobby|basement|floor:2|floor:1` boots into a
  part) puts her, carrying the baby, in front of her door on the third floor of a building with
  three hallways, two switchback stairwells at opposite ends, a barricaded lobby and a winding
  basement to the emergency exit — one map, the parts 64 tiles apart, every door a fade and a
  teleport. The south-edge doors are plain indents now, a brown bar across an indent being the
  whole of what says closed, and every flight's treads are vertical lines, one per step: do the
  bars read as closed doors and the lines as steps at play scale? Record is `DECISIONS.md`,
  M102, the south-edge doors are indents. Both stairwells have recorded physical walks, but the feel of
  the sideways controls and fade-and-teleport still needs a person's verdict: does a diagonal
  flight read as *descending* when a sideways press walks it, and does the fade-and-teleport
  read as a door or as a cut? Records are in `DECISIONS.md` under M112, the escape scene and
  interior graphics; what M102, the finale, still adds is in `TODO.md`.

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
- **The scheme a thumb actually drives has been walked once, and every part of it has moved since.**
  Playtest 33 is the one session on it, and it is what M85 answers — so the focal points are 120px
  out and 120px down from where that thumb met them, both circles are drawn where nothing was, a
  held finger re-aims where it did not, and the middle of the screen stops her where it used to
  steer her. **Four questions only a thumb settles.** Whether a drawn ring at `STOP_RADIUS` (48px)
  with a knob in it is read as *this is what is locked in* or as furniture. Whether a stop band
  nobody can see reads as a deliberate stop or as the game dropping an input. Whether the band and
  the two focus discs together take enough of the screen that ordinary aiming gets refused. And
  whether losing *tap her to stop* in joystick mode is felt as a loss at all, since the band is the
  same ground and the lesson no longer teaches either.
- **Nobody has chosen a mode, and the choice is now the first thing the game asks.** M88 offers
  joystick and tap on every device, so **tap on a phone and joystick on a desktop are both playable
  for the first time and neither has been played** — a thumb aiming from her own position across a
  whole phone screen is exactly the reach problem the two focal points were invented to solve, and a
  mouse driving a focal point is a hand that never had the reach problem being asked to use the
  answer to it. **The captions are the other half of it.** Two sentences on a title screen are all a
  first-time player gets to tell the modes apart, and whether *"aims from the nearer of two fixed
  points"* means anything before you have played either one is a question no rig can answer.
- **The restart path is guarded twice now and nobody has fumbled a tap at it.** A stray press after
  an ending can no longer begin a run just by landing anywhere, since only the two mode discs do
  that — but it can still land *on a disc*, so the 0.35s window (`TouchControls
  .DOUBLE_TAP_SECONDS`) that swallows a press right after a restart-triggered reload is kept rather
  than deleted along with the headline defect. **"Often" was the player's own word**, so what is left
  is a race with a much smaller target, and the window is still the thing to distrust in both
  directions: too short and an ending tap still reaches a disc, too long and a deliberate press
  feels ignored.
- **A phone held upright gets one rotation now, and nobody has held a phone since.** The three
  disagreeing rotations playtest 23 met are gone: one transform is applied to every `CanvasLayer`,
  the camera is no longer a second implementation, and the choice is re-asked every frame rather
  than on a `size_changed` that could arrive stale. The record is in `DECISIONS.md` under M60.
  **The one thing a rig cannot settle is the one that shipped three of those four symptoms** —
  `tests/test_orientation.gd` proves the input remap by construction and says outright that it
  cannot catch a sign error the transform and the drawing share. `tools/shot.sh` takes a resolution
  now, so the rotated branch can at least be photographed; it wants a person holding a phone.
- **The social card has been unfurled once, in a messaging app, and it failed.** The cause was the
  image's alpha channel — its transparent pixels carry RGB `(0, 0, 0)`, so a client that ignores
  alpha paints the card black — and the published copy is now flattened onto an opaque background,
  with its dimensions and type declared and a `twitter:image` beside the `og:` pair. **The fix has
  not itself been unfurled.** Paste the address into a chat client and see what comes back; the
  record of what was wrong and what was ruled out is in `DECISIONS.md` under M80.
- **There is no main menu.** There is a title screen — the doorstep with the traffic and the events
  running behind it — and it asks exactly one question: which of the two control schemes. Two
  circular discs with a caption each, and the hint under them reads `press a button to begin`. That
  is the whole of it: no options, no seed box, no load game. `WASD`, the arrows and `space` begin a
  run too and choose tap, and nothing on screen says so — deliberately, the same way nothing in the
  game names a key. **Nobody has met this screen on a phone**, so whether two discs and two
  sentences are enough to pick between schemes you have not played is unanswered.
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
  and `loose_dog` at 32 are meant to land as a startle without becoming a day lost to something
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
