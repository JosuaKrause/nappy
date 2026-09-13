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
- **Run `--invincible` for a couple of minutes beside a loud event** (any day). The clock and the
  light stay where the day started and the excitement bar never rises, while the crowd, the
  events, the closures and the checkpoints all still run. Does anything still flash or darken, and
  is a held day still useful for looking at the rest of this list? Record is `DECISIONS.md`,
  M100, invincible freezes the clock and the meter.
- **Find a crossing alley walled at both mouths on day 7 or later** (`--seed 2199579682 --day 7`
  has one). No chalk mark and no robber ever stands on its paving; the mark is offered somewhere
  she can reach. Does the mark ever appear behind a band anywhere else — a closure, a soft seal?
  Record is `DECISIONS.md`, M100, a blocked-off alley has no chalk mark.
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
- **Reach any ending and read the last line.** The run clock is there, to the millisecond, and
  nowhere else — not the HUD, not the pause screen, not a day summary. It counts only while a day
  is being walked: a retried day's first attempt counts, a minute on the summary does not. Does
  the number feel like the run's length, and is *hidden until an ending* still the right call?
  Record is `DECISIONS.md`, M107.
- **Play or jump to day 5, day 9 and day 13 and look at the ground** (`--day 9`). The city
  degrades on one curve from day 5: cracks on pavement before road, in three levels; litter on
  pavements, alleys and squares; garbage sacks in alleys first and against building fronts from
  day 7; storefronts and windows shuttered on a boarded-up block and, later, on some commercial
  ones. None of it changes what a route costs. Does the decline read as *the acts*, is day 5 the
  right first day (the range was "day 4 or 5"), and does anything read as a bug rather than as
  decay — litter under a car, a sack in the way? **One decision is yours**: a sack pile in an
  alley has no body yet; whether an alley narrowed by rubbish should cost the route is decided
  when a pile is seen in an alley she has to use. Record is `DECISIONS.md`, M105.
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
  Inside: a mouse and a paced steam vent in the basement, a masked man on one stairwell and a
  fire on the other, and the hallway windows flashing every 22 seconds
  (`Tuning.FINALE_EXPLOSION_INTERVAL`) for `FINALE_WINDOW_FLASH_SECONDS` (0.12s). Two questions
  only a walk answers: does the fire actually force the other shaft, or is walking back up the
  obvious answer anyway; and does the paced steam leave a line to walk in a corridor two tiles
  wide? Record is `DECISIONS.md`, M102, the finale built behind the flag.

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
  `--invincible`). The clock is a day's own length counting down through both sections and draws
  to the millisecond, `%d:%02d.%03d` where a day draws `%d:%02d`; capture, the meter, or zero puts
  her back at the start of the section she was in with the baby asleep again and no Nerve spent.
  **Is the millisecond clock tension or noise** at the speed those digits move, and **is a restart
  at no cost the right feel** — *("sounds good at that point you earned it")* — or does a
  fourteen-day run deserve to be able to lose here? Same record.

- **Reach the tunnel or the bridge and read the epilogue.** It is its own screen on `DaySummary`
  rather than a fourth ending: two lines and the clock. **Is anything in it triumphant?** The tone
  rule is `NARRATIVE.md`'s *no triumphalism in the good ending*, and this is the one screen written
  after the escape, so it is the place that rule is easiest to break. Same record.

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
  interior graphics; what the finale lays on top of the building — its events, and the way out
  through the service door — is the escape walk in the list above.

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
- **A hunting van drives along the footway.** A pursuer steers straight at her over any walkable
  tile, which every pursuer in this game already does; this is the first time the thing doing it is
  a van. Whether that reads as menace or as a bug is a question for somebody watching it.
- **The social card has been unfurled once, in a messaging app, and it failed.** The cause was the
  image's alpha channel — its transparent pixels carry RGB `(0, 0, 0)`, so a client that ignores
  alpha paints the card black — and the published copy is now flattened onto an opaque background,
  with its dimensions and type declared and a `twitter:image` beside the `og:` pair. **The fix has
  not itself been unfurled.** Paste the address into a chat client and see what comes back; the
  record of what was wrong and what was ruled out is in `DECISIONS.md` under M80.
