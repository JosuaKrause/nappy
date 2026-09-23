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
desktop build; `--seed <n> --day <n>` puts a run where an item says; `1` to `5` in a debug build
toggle the field, shadow, bounding-box, readout and route-line layers (`docs/TELEMETRY.md`, "The
debug view"). `--invincible` is the way to walk this whole list in one sitting: nothing ends the day,
the clock stands still and the excitement meter never rises, so one run can stand next to every
item below for as long as looking takes.

- **Find the power station** (`--spawn power_station` stands her at its door; `--zoom 0.35`
  shows the whole of it; `--day 14` is the day the route reaches it). **From the street, does it
  read as a power station and its door as the way in?** **On day 14, is the walk to it through a
  region door a reasonable part of the day, and is it far enough from home?** Record is
  `DECISIONS.md`, M183, slice one, the power station.
- **Play days 6 to 9 and 12 to 13 as a run would** (`--day 6` and on; a task is announced at
  its mark and done that day, a one-place task has a red arrow, and the day brief carries a line
  about the day instead of the task). **Does the mark's announcement read as an instruction you
  can act on today, and does the red arrow read as the task's and not home's?** **Do the day
  brief lines read as the city changing, and which would you rewrite?** They are the draft as it
  stood. Record is `DECISIONS.md`, M181, the resistance has a reason, and a task is one day,
  slice one.
- **Walk day 3 along a real route, twice, in different directions** (`--day 3`; the fire is
  sited on the branch of the day's routes she is walking, off screen ahead, once she has walked
  for a while and is away from the doorstep; the engine comes when she first sees it and parks
  across from it for the rest of the day). **Does she meet it, and how long into the day?** The
  walk from its siting to first sight is long, since a route winds where a straight line does
  not: **is the beat too late?** The fire and the parked engine are meant to close the street
  and send her another way: **is that the reaction, is the other way there, and is the detour a
  fair price?** The fire can come into view with the outer edge of its field already on her,
  where the telegraph's own time is what she has to walk out in: **is that fair when it
  happens?** The parked engine has a field and no body: **does it want one?** Then turn for home
  without having met it: **is it ahead of her again?** And on the second walk, in another
  direction: **does a fire that is always in front of her still read as an accident?** Win a
  day 3 without going far from home, and look for the shell on day 4: it is lit at the end of
  such a day, away from where she finished. Record is `DECISIONS.md`, M179, the fire is on her
  way.

- **Go through a region door, both ways, on day 7 or later** (`--day 7`; the doors are the huts
  and gates in the region walls). The hold costs 25 points and nothing else lands while she is
  inside; nothing is placed within 176px of a door, and the hut, the post, the gate and the
  roadblocks beside them charge as one source, the strongest of them. **Is a crossing still a
  price worth thinking about, or is it cheap now?** At a corner where two doors meet, **is it one
  toll?** One red rim shows on the barrier that is charging her rather than one on each: **does
  that read?** And when she comes out, **is she ever drawn, even for a moment, at the place she
  went in?** Record is `DECISIONS.md`, M178, a gate lets her out alive.

- **Let a loose dog run past her, walk into a flock of pigeons, and stand beside a protest**
  (`--force loose_dog 3` puts a dog in front of her every few seconds; pigeons are in act I's
  squares; the protest is day 12 onward). The dog is sited 739px ahead so its warning is over
  before its field reaches her, and a pass nets about 24 points awake, above a dog walker's 16:
  **is it loud enough now, and is it too much?** The pigeons go up the moment she is among the
  birds, and walking dead through them nets about 45, where stopping short until they have
  flown, or skirting them, costs nothing: **do they go up when she touches them, never before
  and never after, and does waiting them out work as the procedure?** The protest nets about 6 a second beside it and 23 to reach its middle from its
  edge, and sits 1.6 points under the line that would make it a wall. A roadblock emits 9 a
  second and a hut or a post 4: **is a door with its usual company a price rather than a
  loss?** Every figure is a line of `docs/COSTS.md`. Record is `DECISIONS.md`, M176, the loose
  dog is loud while it passes.

- **Hand the note to a man shouting** (the day after the first chalk mark is touched; any of
  them). He goes quiet at once and walks away from her at 60px a second, in a straight line,
  until he is off screen; the others carry on. His picture has no quiet pose, so the whole cue
  is the shouting stopping and him leaving. **Does it read as "he took it", with nothing
  written anywhere?** He walks straight, so watch whether he goes through a building or across
  a road in a way that looks wrong. Record is `DECISIONS.md`, M182, the man shouting walks off.

- **Find a chalk mark on a day that has one, and touch it** (day 4 onward; the mark is in an
  alley near wherever she walks). It stays
  put once she has been within 150px of it, on screen, for a second, and until then it moves
  to the alley she comes across: **does it ever vanish from a place she had noticed it, or
  sit at the screen's edge and never come nearer?** The first mark's note
  is one sentence. Record is `DECISIONS.md`, M177, the second
  mark is any alley she comes across.

- **Walk past the man shouting, a dog walker and a loose dog, going the other way, then walk
  beside each** (without `--invincible`, which holds the meter still; `--spawn
  event:homeless_yeller` puts one in front of her). A pass nets about 11 points for the man
  shouting, 16 for the dog walker and 15 for the loose dog with the baby awake, each a little
  over what it cost under the 3.5 a second walking decay the rows were first tuned against
  (`docs/COSTS.md` has every row). **Is a pass a price
  worth a detour and not a wall?** With the baby asleep the man shouting's pass still nets nothing,
  as it did before the decay moved: **should a sleeping baby make him free?** Watch the halo while it happens: it is red only while the
  bar climbs because of that source, and the halos add up to the bar's own rise. Watch the
  caret before it happens: it is what she nets over the next five seconds if she and the source
  both carry on. **Did the bar do what the caret said?** Against the man shouting it may not,
  since his pulse turns over inside the caret's horizon (open in `TODO.md`, M174). And on day
  1, **are there still enough things on her route to choose between**: friction placed on the
  corridor measures about a tenth lower on day 1 and a twentieth lower over five days than
  it did with these rows cheaper: `Tuning.WALL_WORTH_OF_COST` is 48 points, which keeps the dog
  walker and the man shouting on her route and `leaf_blower` off it. The dials are the three rows' `intensity`,
  `leaf_blower`'s `core_intensity` and that line, all open to overturn and meant to be tuned
  by feel. Record is `DECISIONS.md`, M174, the rows are corrected for the decay.

- **Play three days in a row on the released page and on the desktop build, and look at the
  ground each morning.** Every picture now comes off a baked page and the ground is composed
  from layers at each day's repaint, from a recipe held since startup. Is any tile a flat SVG
  drawing rather than the illustrated one — a cracked road, sidewalk or alley tile most of
  all — and does any day's ground differ in kind from the first day's? Is there a hitch when
  a day begins or when the first event of a family appears? Let something lethal come at her
  from off screen: does the screen-edge badge show the same picture as the thing itself? No
  capture has caught a badge since the events moved. Record is `DECISIONS.md`, the sections
  starting "M171,"; [PLAYTEST-110](playtests/PLAYTEST-110.md) and
  [PLAYTEST-111](playtests/PLAYTEST-111.md) are what was found on the way.

- **In a run that selects the father, watch pushing and carrying through several facings and
  the A/C/B/C walk cycle, including southeast and southwest.** Do the approved legs read as a
  continuous stride at gameplay size, with stable upper body, baby, ground contact and stroller
  placement? The complete PNG/GIF family is accepted in [PLAYTEST-104](playtests/PLAYTEST-104.md).
  The retained pushing burst shows the father; the attempted carrying burst shows the mother
  and cannot answer father-carrying appearance. Record is `DECISIONS.md`, M167, resumed delivery
  and main integration.

- **Close the game in the middle of a day and open it again**, on the desktop build, and on
  the released page in a laptop browser (refresh, close the tab). The phone is answered:
  reloading there brings up the proper day brief ([PLAYTEST-94](playtests/PLAYTEST-94.md)). Does the title come up, and does pressing start bring up the day brief — the
  day, the nerves, the resistance's own pending brief — one nerve down, with the line *"Left
  before the day ended. That cost a nerve — it starts over from dawn."* — and is that wording
  right, and does the screen read clearly as a brief rather than as an ending on its own? Does
  continuing from the day brief start the day, and does closing again before continuing past it
  come back to the same brief at no further cost? Does closing at an end-of-day message come
  back to the day brief at no cost, and does a new release still find the save of the one
  before? No rig can look at any of this, since a dev-flagged run never reads or writes the
  save (`DECISIONS.md`, M162).
- **Does a nerve lost to an accidental close or a browser crash read as fair?** It is the price
  of quitting never being an escape ([PLAYTEST-82](playtests/PLAYTEST-82.md)); the exact
  snapshot is what was given up for it.
- **Is the save symbol a floppy disk, and is it noticed without distracting?** Bottom right, a
  second and a half held and the same fading, twice in an ordinary day. It is a blue disk with a
  silver shutter and a paper label, drawn in its own colors and only faded; look at it on the
  phone, over a daylight street and over dusk. The drawing is accepted on a render
  ([PLAYTEST-95](playtests/PLAYTEST-95.md)); what is unseen is the symbol in play. Record is `DECISIONS.md`, M169.
- **Click away from the game in the middle of a day**, on the desktop build, in the browser
  (another tab, another window) and on the phone (the home button). Does the pause screen come
  up every time, and never on the title, a day summary or an ending? The desktop case rests on
  the engine's documentation rather than a captured run, since no rig's window ever holds
  focus (`DECISIONS.md`, M161). And does staying paused after coming back read right, or
  should returning resume the day?
- **Stand at a sealed street and watch one car meet the barrier**, on seed 3126506586 day 1, which
  is where the player photographed a car twitching between the two sides of the road
  (`--seed 3126506586 --day 1 --spawn closure:0 --invincible`, and `--press snapshot_burst 3` if it
  wants recording). The car now brakes a half turn short of the barrier, waits there while the
  oncoming lane is busy, and drives the arc round when it clears; where the arc's own ground is
  blocked it still reverses on the spot, and where there is no road either way it stands still until
  the camera leaves it. **Does the wait read as a driver hesitating rather than as a parked car, is
  the sideways twitching gone, and does the half turn itself read as a manoeuvre?** Record is
  `DECISIONS.md`, M152, the about-face is planned.
- **Start a day and look at the first thing drawn**, on any seed, from the doorstep and again from a
  summary screen's continue button on day 2. The morning's traffic is pulled apart before the frame
  is drawn rather than on the frame after it. **Does any car on her own street move before she
  does?** Same record.
- **Watch a car finish a turn into a street that already has traffic in it** (any day with a
  closure; `--spawn closure:0` stands the camera at the junction outside the barrier, and
  `evidence/m152-car-teleport-2026-09-15/` carries the before-and-after bursts). The arrival
  stands where its arc ended and the car behind it eases off; nothing is flung to the back of
  the lane. **Do the cars turn without a jump in the final stretch and at seals, does a car
  arriving into a queue read as traffic making room, and does an about-face at a seal still
  read as a car flipping on the spot?** Record is `DECISIONS.md`, M152.
- **Walk a minute of day 1 on the laptop with `--debug --spikes`, on this build, and read the
  run log back** (`tools/telemetry.sh`). Every picture is warm and every group is packed; the
  log carries a `texture` line per picture loaded and per atlas made ready or released, with
  milliseconds on each, so a spike that coincided with a pack says so on its own line. **Is the
  once-a-second 24 ms frame still there, do the spike lines still name a cause, and is the
  graph under the readout legible while walking?** The graph is its own layer now, `6`, on
  from boot under `--spikes` and blank again after `6` twice (`DECISIONS.md`, M153).
  *(2026-09-15: "and we can do another warm test run".)* Record is `DECISIONS.md`, M149,
  atlases by group.
- **Open the web build on the phone and walk a day.** Every atlas is under a 2048 px side and
  every region is clipped, and the desktop shows no difference. **Does anything draw
  differently — a neighbour's pixel bleeding into a sprite's edge, a ground tile on the wrong
  cell, a mark over her head in the wrong place?** Same record.
- **Start a run from the title, on the desktop and on the phone.** A camera stands on the
  doorstep before the picture warm-up awaits during boot, so the first frames draw what the
  title screen shows rather than the map's top-left corner or black. **Is the corner gone,
  with no blank frame in its place, and does the title screen still show what it showed?**
  Record is `DECISIONS.md`, M151, the first frame draws the doorstep.
- **Walk a minute of day 1 on the laptop with `--debug --frame-trace`, without screenshots or
  invincibility, then quit normally to export the trace.** Does walking feel smoother, and do
  intermittent stalls remain? The raw post-draw intervals name their callback-time counters;
  unchanged counters do not rule out other script or rendering work. The crowd contribution
  sweep is cheaper, while this trace and the player's perception still answer different
  questions. Record is `DECISIONS.md`, M159, cheaper crowd contribution sweeps.
- **Walk a minute of day 1 on the laptop with `--debug` and watch the graph under the
  readout, then the same on the phone with `?debug=1`.** Each bar is one frame's length, newest
  at the right, 240 frames wide; the lines are 60 and 30 fps and the window's mean; amber is a
  frame past 16.7 ms and red one past 33 ms. **Is the 24 ms frame there as an amber bar
  most seconds on the laptop, and on the phone does the graph fit under the block and read at
  all?** Record is `DECISIONS.md`, M148, a rolling graph of frame times.
- **Walk a minute of day 1 on the laptop with `--debug --spikes` and read the `spike` lines
  out of the run log** (`tools/telemetry.sh`, or the run folder printed at boot). Each names
  the one frame in its second that ran past twice the mean, and what changed since the frame
  before it — her tile, the live event count, or nothing. **Is the 24 ms frame there in most
  seconds, and does its line say "nothing else changed"?** A headless rig already wrote 29
  and 57 ms spikes with nothing changed, so the cadence and whether anything in the game lines
  up with it is what this run settles. Record is `DECISIONS.md`, M144, the 24 ms frame, found.
- **Walk day 1 on the laptop without the debug layers and look at the curbstones along the
  streets the routes take, then turn on `5` to see where the routes are.** The route's own
  curbstones — the stone strip along the pavement's edge, not the paving beside it — carry a
  faint yellow cast blended in at 0.45, a trial of whether a hint on the ground can stay below
  being noticed as one. Three readings, and the number is one constant
  (`Tuning.ROUTE_KERB_TINT_ALPHA`): **is it invisible, too obvious and on the nose, or somewhere
  between that guides without being read as a hint?** And where a costly thing stands on the
  route with its amber caret up, does the yellow curbstone read as part of the warning? Record
  is `DECISIONS.md`, M145, the route's curbs. The tint marks the whole street, both curb
  lines from intersection to intersection: **is any street tinted on one side only or for part of
  its length, and does a street the route merely crosses stay plain?** The purple route line (`5`)
  still runs along the one sidewalk the route walks. Record is `DECISIONS.md`, M170.
- **Turn on `5` on seed 2128084176, day 1, and follow every purple line with your eyes.** The
  tree grows on a graph with no carriageway cell but the junctions' and none of the main
  road's, and the doorstep connector is drawn along the street now rather than as a straight
  hop. **Does any route line still cross a carriageway anywhere but at a crossing, or run on
  the main road?** And walking one route end to end: is there a line through it that never
  costs, and where it breaks, what stands in the way — the probe says a leaf blower most often.
  Record is `DECISIONS.md`, M129, the four rules.
- **Find a leaf blower on a pavement on day 1** (`--spawn event:leaf_blower` puts one in front
  of her; `1` shows the field). Walk past it on its own pavement, then along the far pavement,
  then through a junction a street away from it. Its field has two parts: a wall out to a
  pavement's width, and the busker's hum beyond. **Does walking past read as a wall, does the
  far pavement read as a hum that keeps the baby awake and nothing more, and does a junction
  inside its outer field feel free to cross?** Record is `DECISIONS.md`, M129, the leaf blower
  is a wall to walk past and a busker to stay near.
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
- **Stand by a single sealed street and watch the crowd turn back** (any day; seals are the
  bodies on the streets the day's route does not use). Cars turn back at the last junction before
  a hard seal, a wall and a closure; walkers walk the street up to the bodies and turn there; a
  soft seal takes both pavements from walkers and leaves the road to cars; a door lets cars through
  one at a time. Does a street the crowd refuses read as *shut* when it has people walking half of
  it? The other half of this, whether the crowd looks stuck, was answered by
  [PLAYTEST-66](playtests/PLAYTEST-66.md) for a junction sealed on every side and built as
  `DECISIONS.md`, M119; this asks about one seal on an open street. Record is `DECISIONS.md`, M110.
- **Stand at a junction sealed on every side, then walk the open streets around it.** No car is
  placed inside such a pocket, and a car a seal goes up around leaves once it is off screen, so the
  sealed crossing carries no traffic — but it does carry people, who walk each stub to the barrier
  on the end of it and back. Two questions. Does a crossing with no cars and walking people read as
  *shut*, or as a hole in the city? And whoever a seal goes up around now stands where it caught
  them until the view moves off, which is cars only: does a stopped car in a sealed crossing read
  as stuck traffic or as a frozen body? And a walker or car that turns back from a single seal on
  open ground keeps its new heading for one stride before it may turn again — does that turn-back
  read as a decision rather than a twitch? Records are `DECISIONS.md`, M119, M146 and M156; the
  bursts are `evidence/m119-crowd-pockets-2026-09-13/`.
- **Walk the map's east and west edges facing outward, then stand at a plain edge and watch the
  traffic arrive.** The camera now stops short by the length of its glance, so no black column
  should show at any corner whichever way she faces. Two questions. Is the border whole in every
  corner, walking as well as standing? And beside an edge, do cars ever appear bunched — several
  recycles can land within a car's length of each other there and are pulled apart by the
  following rule, which a rig measured and nobody has seen. Whether anybody still enters across
  a plain edge was answered by [PLAYTEST-69](playtests/PLAYTEST-69.md) — they do — and is a
  defect under M100 in `TODO.md`. Record is `DECISIONS.md`, M120; the stills and the burst are
  `evidence/m120-map-edge-2026-09-13/`.
- **Walk past a café, a stall or a kerbed van on a day with several** (a precinct's pavements are
  the busiest early in a day). A walker steps into the other lane of its own footway to get past
  one and steps back after; a car in the body's own lane turns at the last junction while the
  oncoming lane keeps flowing past it. Do both reads happen visibly rather than the walker or the
  car simply not being there next time you look, does any street end up parked rather than turned,
  and does diverting at every body — the recommendation the player overturned on 2026-09-12 —
  blunt the tell a closure's own turn-away relies on? Record is `DECISIONS.md`, M110, every solid
  body; the tunables are `Tuning.WALKER_BODY_SIDESTEP_TILES` (4 tiles) and
  `CrowdAgent.BODY_TURN_CLEARANCE_TILES` (3 tiles), both open to overturn.
- **Stand by a region door on a busy street and watch the walkers** (day 7 or later,
  `--invincible`). Most stop beside the hut, vanish inside for a second, come out on the far side
  and walk on; one in eight walks straight through; one in four turns off at the last junction;
  never more than three are committed to one hut. At real density a hut was occupied only now and
  then in the rig, so does the hold ever read on screen, and if a door should read as busy is the
  lever the hold length or the fractions? Does a walker turning round where it stands, when it
  meets a full door from inside the door's own street, read as wrong? Record is `DECISIONS.md`,
  M110, walkers are held at a door.
- **Find a roadblock on day 7 or later** (a 120px barrier across a road, drawn as one continuous
  barrier with end posts). Does it read as one barrier rather than blocks? A guard stands at the
  middle of every one from the start, and at a roadblock that does not hunt he is a drawing only:
  **does he read as a manned checkpoint, or as a threat she should be routing around?** Record is
  `DECISIONS.md`, M168, the roadblock's guard, and M56, the roadblock hunts.
- **Find the burning building on day 3** (`--day 3`; it is on a pavement against a building). The
  engine arrives along the fire's street only once the fire is on screen. Does the engine read as
  *summoned by the sight*, and does a day where she never finds the fire feel different? Record
  is `DECISIONS.md`, M101.
- **Walk a precinct end to end** (a pedestrian street with bollards at each mouth). Nothing is
  built over its paving any more. Does it read as one paved place? Record is `DECISIONS.md`,
  M100, a precinct's pavement.
- **Watch a car pause at a junction mouth** (any day). A car drives to the mouth of the
  junction, eases to a turn speed, follows one arc onto the centre of the lane it is joining and
  picks up speed again. Does the pause at the mouth read as slowing rather than stalling? Whether
  the picture jumps a view or floats off its shadow on the arc was answered by
  [PLAYTEST-66](playtests/PLAYTEST-66.md) and built as `DECISIONS.md`, M121; the street
  about-face over the kerb is decided as built (`DECISIONS.md`, M111, the kerb overhang stays).
  Records are `DECISIONS.md`, M111 and M108, the crowd car.
- **Stand close to a car as it turns, and under a flock, and watch the rim.** The halo now
  re-traces its owner's body every frame it is drawn, so a turning car's rim should sweep through
  the diagonal with the picture and a flock's rim should fly with the birds. And every car and
  walker heading west now has a rim at all: the three mirrored views drew none before, which is a
  defect that stood since the halo landed. Three questions. Do rim and picture read as one body
  through a turn? Does a west-facing body's rim read the same as an east-facing one's? And, on the
  phone where it was seen, does an east- or west-bound car that has come round a turn now sit on
  its halo and its shadow for the rest of the street, rather than a few pixels south of them? The
  car's picture is redrawn whenever its heading moves now, not only when its view changes. Records
  are `DECISIONS.md`, M121 and M130; the bursts are `evidence/m121-halo-follows-owner-2026-09-13/`
  and `evidence/m130-car-halo-anchor-2026-09-13/`.
- **Touch the day-4 chalk mark, then lose the day on purpose, then win it** (`--day 4`). The
  lost day's summary says nothing about the mark, since the touch is given back with the loss;
  the retry offers the same mark in the same place; the won summary carries its words on their
  own larger line in the touched mark's green, above the ordinary lines. Then lose day 5: its
  summary repeats *the one who won't stop shouting* rather than anything new. Does the brief
  read as *the thing this screen is telling you*, does the retry finding the same mark read as
  a second chance rather than a repeat, and does the lost day 5 reminder read as help? On day 5
  the header reads *somewhere out there: the one who won't stop shouting* rather than the
  step's name — does that read as an instruction? Records are `DECISIONS.md`, M132 and M134.
- **Turn on the route lines and walk a route** (`5` in a debug build, or `--layers 5`). Each of
  the day's planned routes is a purple line from the doorstep to a calm area through the centres
  of the two-tile cells it runs on, and the first segment hops from the door to wherever the
  route joins the home street. Do the lines read as the routes you would take, and does the hop
  from the door read as wrong enough to draw from the join instead? Record is `DECISIONS.md`,
  M135; the still is `evidence/m135-route-lines-2026-09-13/`.
- **Find a flock of pigeons on the ground** (any day; `--spawn event:pigeon_flock` puts a rig
  in one). The birds peck on the pavement from two screens away and go up as she comes within
  150px, then are gone. Do they read as a place she can plan around rather than a thing that
  happens to her, and does a flock going up in the pram's face still read as loud? Whether a
  flock belongs on a route was answered by [PLAYTEST-71](playtests/PLAYTEST-71.md) — it is
  scenery, and M129 in `TODO.md` puts it back on them — so this asks only about the encounter.
  Record is `DECISIONS.md`, M131; the burst is `evidence/m131-flock-on-the-ground-2026-09-13/`.
- **Watch a car about-face into a street with a queue in it.** The lane holds a gap for the
  car that is coming and the arrival stands where its arc ended while the car
  behind it eases off (M152), so nobody already in the
  lane should jump. Does the merge read as traffic making room, or as the turning car waiting for
  nothing? Same record.
- **Look at a parked delivery van and, from day 7, a police car on patrol.** The delivery van and
  the abduction van now face east when parked facing east; before, their west-authored pictures
  were drawn unmirrored, so a van sited nose-east showed its nose west. Does the parked van read
  as facing the right way along its kerb? The police car is the one event vehicle that turns
  corners, so it shows the diagonal views: do its markings and light bar hold up from every
  side, and does it sit on its shadow at the diagonal? Record is `DECISIONS.md`, M108, the event
  vehicles.
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
  escape. In the rig pictures commercial and residential read at a glance; industrial and civic
  are told apart by their roofs alone, which are small at play scale, and the portico was out of
  frame. Does each district read as a place? Record is `DECISIONS.md`, M106.
- **Find a tree-lined street and walk it end to end** (`--overview` shows where the few are;
  seed 4229 has six). Trees stand only on a handful of straight runs of three to five blocks, a
  pit about every two lot-lengths, so a run carries four or five trees and about one ordinary
  street in sixteen has any. Does a run read as *a planted street* or as two stray trees, and is
  a tree still ever in the way of spotting a yeller or a dog walker? The run count and the
  spacing are both pinned guesses. Record is `DECISIONS.md`, M115.
- **Find a fallen tree** (seed 4229, day 1 plans exactly one; `--spawn closure:0`). It lies only
  on a tree-lined street, and the pit it fell from is empty for the day: the whole prop is
  hidden, so what she sees is a gap in the row. Look down the street for the gap. Does it read
  as *the tree that was here is in the road*, or as nothing at all? If nothing, the bare pit
  drawn without its tree is one branch in the prop's drawing. Same record.
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

- **Walk a baby home in act III or IV** (`--day 9` or `--day 13`; settle the baby in a park, then
  walk back). Two patrol cars on day 9, three on day 13, now come down her own street toward her
  during the walk home, nine to sixteen seconds apart, on top of whatever the day already owed;
  none is lethal. Does the return read as pressure — a reason to pick the quieter street home —
  or as punishment for having found calm, and does the sleeping baby survive it often enough?
  Record is `DECISIONS.md`, M98, the return owes her patrols; the counts and the interval are
  `Tuning.RETURN_PATROLS_PER_ACT` and `RETURN_PATROL_INTERVAL`, both open to overturn.

- **Walk the whole escape end to end** (`tools/run.sh --start-escape --seed 4242`; debug only).
  She starts at her own door with the baby asleep, goes down past the barricaded lobby to the
  service exit, and the same run continues into the city and ends at the tunnel or the bridge.

  **What is in there now.** Rubble shuts the top floor east of her door, so the first descent is
  down the left shaft, where a fire closes one flight; the right shaft is the masked man's, and a
  new one starts up it `Tuning.FINALE_PURSUER_RESPAWN_SECONDS` (6s) after the last leaves its top,
  standing through his whole warning every time. The basement is entered down a one-tile
  front-facing stair and holds a mouse and three steam vents, each where the corridor is one tile
  wide, blowing for `FINALE_STEAM_BLOWS_FOR` (2s) out of periods of 4, 4.5 and 5.5 seconds. The
  hallway windows all flash together, with each loud explosion every 22 seconds and silently in
  between at gaps of 0.1 to 5 seconds, 1.3 on average. A lost section comes up on the brief screen
  before it starts again.

  **What only a walk answers.** Does rubble, fire, crossing over and the masked man read as a
  sequence of decisions, or as a corridor with no choice in it, and is six seconds between men a
  gap to plan in or a wait? Is stepping through a door a *usable* answer to him — a door tile is
  32px off his line against the 28px that takes the baby, and the farthest door is a 1.8 second
  walk against his 3.6 second warning. Does the steam now read as a gate worth timing, and is the
  worst pocket fair — shut at both ends for two seconds, it costs about half the meter. Are some
  forty-five flashes a minute atmosphere or strobing? Does the brief on a restart land as a beat or
  as a screen in the way? Does the basement stair, a gray tile with a dark line every four
  pixels, read as a stair at the scale it is played at?

  **And in the city:** she comes out with no danger mark over her head, though a screen-edge
  badge for something not lethal may still show: does that read as the same complaint? Walk south
  from the service exit to a roadblock: **does the guard read as having been there all along, his
  setting off as a man leaving a post, the catch at 28px as contact, and the barrier still shut
  behind him as right?** Nobody has watched one set off; no capture of it exists.

  Records are `DECISIONS.md`, M168, the escape after playtest 94, M165, the escape after the
  corrected stairs, and M102, the finale built behind the flag.
  [PLAYTEST-94](playtests/PLAYTEST-94.md) is the last walk of it and
  [PLAYTEST-96](playtests/PLAYTEST-96.md) is where the window flashes were settled.

- **Stand at the service exit and choose** (`tools/run.sh --start-escape city --seed 4242` boots
  section two on its own). Two chains leave the door, one north to the tunnel and one south to
  the bridge, each through its own three calm areas, and everything off them is sealed hard. **Does
  the choice at the door read as a choice** — is there enough in view at the moment of choosing
  for it to be a decision rather than a coin flip — and **do the three calm areas read as the only
  calm on the way**, the places to settle a woken baby, rather than as scenery she walks past?
  `Tuning.FINALE_PARKS_PER_CHAIN` (3) and the per-street densities `FINALE_TRUCKS_PER_STREET`,
  `FINALE_VANS_PER_STREET`, `FINALE_GUARDS_PER_STREET` and `FINALE_EXPLOSIONS_PER_STREET` (1, 1,
  2, 1) are the dials, all open to overturn. Same record.

- **Lose a section on purpose and read the clock while you do** (either boot, without
  `--invincible`). Each section has a day's own length on its own clock, started by its brief's
  continue and drawn to the millisecond, `%d:%02d.%03d` where a day draws `%d:%02d`; capture, the meter, or zero puts
  her back at the start of the section she was in with the baby asleep again and no Nerve spent.
  **Is the millisecond clock tension or noise** at the speed those digits move, and **is a restart
  at no cost the right feel** — *("sounds good at that point you earned it")* — or does a
  fourteen-day run deserve to be able to lose here? Same record.

- **Win day 14 with every task complete and follow it into the building.** The day's own summary
  comes first, then a scene reload, then the brief "Escape the building" over the hallway. **Does
  the summary read as a lead-in rather than an ending**, is the black frame of the reload
  acceptable, and does the brief sit well over the building, which fills only a narrow band of
  the frame behind it? Record is `DECISIONS.md`, M102, the finale is
  the run's ending.

- **Close the game inside each section and open it again** (a flagless windowed build; every
  dev flag and headless run refuses the save). It comes back through the title screen to that
  section's brief, which offers the section or a held restart for a new game, with a full clock
  and no Nerve spent; a game closed in the city comes back in the city. **Does the title before
  the brief read as the same game starting up?** Then **press `Esc` in each section**: the pause
  screen a day has, never over a brief or the epilogue, and the clock stops behind it. Record is
  `DECISIONS.md`, M102, the escape has what a day has around it.

- **Reach the tunnel or the bridge and read the epilogue.** After it a run's escape goes back to
  the title, with no good-ending screen between: **should "Silence." still follow it?** It is its own screen on `DaySummary`
  rather than a fourth ending: two lines and the clock. **Is anything in it triumphant?** The tone
  rule is `NARRATIVE.md`'s *no triumphalism in the good ending*, and this is the one screen written
  after the escape, so it is the place that rule is easiest to break. Same record.

- **Walk day 1 on the laptop at its own frame rate and watch her, not the crowd.** The
  physics tick is thirty a second now and she is drawn between ticks by the engine's own
  interpolation; the crowd and the events move per frame as before. **Does her walk read
  smooth at a hundred frames, and does the camera's follow?** And at every jump she makes —
  the day start, a door release, the escape's fade-and-teleport, a camera focus and its ease
  back — is there a one-tick slide from the old place, or does she simply appear? Record is
  `DECISIONS.md`, M141, the physics tick at thirty.

- **On the phone, on the release that carries the tick, load the four settings on seed 123
  again** — `?debug=1&seed=123`, then `&skip=crowd`, `&skip=motion`, `&skip=motion,crowd` —
  within the first ten seconds of the day, and read `fps` against playtest 74's table
  (`DECISIONS.md`, M140, the phone reading). The physics tick now runs half as often; the
  `physics` line is per tick and the `process` line is the worst frame of the last second, so
  `fps` is the number that says whether the frame moved. **Does it?** Same record, M141.

- **Pace a quiet ordinary sidewalk back and forth for a stretch, then hold its midline through a
  few oncoming walkers**, any seed, day 1 (`--seed 4242 --day 1`; `--invincible` if the timing to
  watch several passes through is otherwise hard to hold). `PEDESTRIAN_OUTER_RADIUS` came in and
  `EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER` came down to hold the main road's own price in its
  place. **Does pacing a quiet route sidewalk now read as recovery, closer to how an empty street
  already did, and do walkers stepping out of her way read as polite rather than as a crowd
  fleeing her?** Record is `DECISIONS.md`, M155, the crowd's reach comes in.
- **Walk a day's sealed streets, its side streets and a street with something parked on the
  pavement** — any seed, any day; `--spawn closure` puts the camera at the mouth of one of the
  day's own closed streets, and the streets off the day's route are the sealed ones. The crowd now
  turns only at what physically stops it: a walker walks a sealed street up to the bodies and
  about-faces there, turns into a side street that is sealed further along, is placed on sealed-off
  ground like any street, and a car is turned only by something across its roadway. Three questions
  only a person answers. **Do closed-off streets and the offshoots of the route now have people in
  them, and does that make the shut street stop reading as shut?** — the whole point of the empty
  street was that *the street with nobody on it is the street that is shut*, and half a street of
  walkers is a different picture. **Does a walker turning round at a barrier read as a person
  changing their mind, or as a body bouncing off a wall?** — watch one seal for a minute and count
  how many walkers pile up at it. **And do cars flow past a van or a café on the pavement without
  hesitating?** Record is `DECISIONS.md`, M156; the burst is
  `evidence/m156-crowd-turns-2026-09-19/`.
- **Walk day 1 along the tinted kerbs and look at both sides of every street.** Any body that
  leaves her less than 28px of lane is a wall by fit — the café tables, the market stall, the
  roadworks, the ice cream van and the parked van — so none of them stands on the sidewalk the
  route walks, and they are drawn to the far side of that same street. The walked side carries
  the dog walker, the shouting man, a playground and the poster crew, who stand against the
  building and leave the curb side free. Turn on `5` for the route lines, since the curb tint marks
  both sides: **is there anywhere a body on the purple line's own sidewalk cannot be walked
  past?** `tools/run.sh --seed 129420 --day 9` had a van closing the walked sidewalk at tile 90,74
  before the rule. Record is `DECISIONS.md`, M129, no body closes the walked sidewalk. **On a
  square, the poster crew pastes onto a free-standing advertising column**
  (`tools/run.sh --seed 4242 --day 11 --spawn event:poster_crew_square --no-save` stands her by
  one): does it read as an advertising column, is it too short beside the man, and can she
  walk into the drawn column, which is not solid — only the worker is? Two more
  questions a rig cannot answer. **Is the far side visible enough to
  be the answer** — a wall across the road is only a route decision if she can see it before she
  commits to the side she is on. And **does the shouting man read as something to time** rather
  than as a thing in the way: he stays on the route because his beat reaches the crossing at the
  junction, so the answer to him is to walk on while he paces away, or to cross where his beat
  ends. `tools/run.sh --seed 4242 --day 1`, layer 5 for the routes and layer 4 for the readout.

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
