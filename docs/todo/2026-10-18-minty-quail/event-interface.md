# The event interface: every caller asks an event through methods, and an event is made of parts

**The ask.** `field-reads.md` converts every read of another object's fields to a method, the
events first, and an event's abilities become parts it is composed of (inbox #1173 in gray-dolphin). This
file is the design that item asks for before the conversion: which parts an event has, the questions
callers ask it, what replaces each read, and the pull requests in order. It is written for the
code as it stood on 2026-11-09 and is deleted piece by piece as its steps are built, the built
interface then being what `docs/EVENTS.md` and `docs/ARCHITECTURE.md` describe.

**Whose it is.** The design is a design agent's, from the player's rules below. The player, on
which model does what: "consider using fable for tasks that need planning / complex reasoning",
and "for code I'm fine with your choice as long as fable did the design" (inbox #1264 in olive-ferret); *read as*
a design being that model's work. **The player has not read this design.**

**Proposed, not asked for:** every mechanism in it that the player's words below do not name, among
them the settings objects (`...Spec`), the draft a row is written through (`EventDraft`), the row
no longer being a `Resource`, the narrow interface a behaviour asks its event through (`Figure`),
and the one object for where she is (`WhereSheIs`). The plainer alternative each replaces is a
method per field on the three classes as they stand.

**Its open points are answered.** Section 7 holds what the player's recorded words answer and
the six points the design put as questions, each with the player's answer from the board
(inbox #1278 in olive-ferret).

The rule it applies is the player's: "provide a consistent interface for events that can be used without
knowing details of the event. that applies to all aspects of events ... don't forget about
composition over inheritance", and "never read fields directly. always read through a method ...
so you can swap out a field with a computation if needed. fields are not API" (inbox #1173 in
gray-dolphin, statements 16 and 23).

Three objects are meant by "an event" below, and each is named this way throughout:

- **the row**: one kind of event as the catalogue declares it (`EventDef`, built by
  `EventCatalogue`): cafe tables, the alley robber, the patrol car;
- **the plan**: one row placed for a day, with its position, path and facing (today the inner
  class `EventScheduler.Planned`, about to be `EventPlan` in a file of its own);
- **the live event**: the thing standing or moving in the world while she is near it
  (`EventInstance`, a `Node2D`).

## 0. In short

1. **A caller asks the event, never a field.** The row, the plan and the live event each answer
   questions as methods. A caller holding a live event or a plan asks it directly, and never
   reaches through it to the row (`instance.def.hard_fail` becomes `instance.ends_the_day()`).
   Outside `src/events/` nobody is handed a part: which parts a row has is a detail of the event.
   Inside the folder, the code that runs one ability (its live half, its look, the builder of a
   plan's route) is handed that ability's part and asks the part itself.
2. **A part has two halves**: its settings on the row (a small immutable `...Spec` object) and its
   state on the live event (an `Event...` object). Four abilities already have this shape (the
   pursuit, the wait for her, a car's driving, the abduction). The design completes it for the
   rest: a body, the field of noise, ending the day, a hold on her, the warning, a route, a
   flock, a look. No ability is a subclass of the row or of the live event.
3. **A row is written through a draft and never changed once built.** The catalogue writes
   `row.body(...)`, `row.field(...)`, `row.pursuit(...)`: one line per ability, and a row without
   an ability has no line for it. A variant of a row (its heated copy, a seal's copy, a pacing
   copy) is a new draft started from the row with one part replaced. Nothing writes a built row,
   so what is worked out from its settings is worked out once.
4. **Many of the questions exist already.** The row has 48 public methods today
   (`lethal_reach()`, `field_reach()`, `line_reach()`, `obstructs_within()`, `notice_within()`),
   the plan 33 and the live event 76. The design adds about 50 questions to the row and one
   method per part, about 40 to the live event and 30 to the plan, and leaves no public field on
   any of the three: the row goes from 78 variables and 48 methods to about 110 methods.
5. **Seventeen places work an answer out from several fields that the event can give itself**;
   each becomes one question (section 2, "Several reads that become one question").
6. **The live event's own parts are bound by the rule too.** Its behaviours and looks read its
   fields 481 times today, underscore-private ones included. They ask it through one narrow
   interface and are handed what never changes, as the crowd's lane strategies ask their mover
   (the record brisk-lark).
7. **Where she is is one object** (`WhereSheIs`). The event manager tells it once a tick,
   and every live event, behaviour and excitement source is handed it; each live event hears it
   through a handle of its own, which keeps the timing its own fields had (section 2.10).
8. **Five steps, the first two of which start now beside placement**: the callers outside the
   events folder, then the live event's inside. The dawn, the walk and the manager's parts follow
   placement and the scheduler's breakup; then the row's parts and the draft; then the suites.
9. **The cost per frame is small and is measured**: a few dozen live events against the crowd's
   hundreds of agents, and rows that cannot change take per-frame reads out of the baby's sweep
   and the danger prediction. Section 6 names the probes.
10. **Nothing the player sees or the logs say changes.** Every step is at test parity, the run
    log and GoatCounter names included. The answers that are slightly wrong today are each
    made correct in a pull request of its own, after the step that names it (section 7, point 6).

## 1. The parts

### 1.1 What an event can do today, and what becomes a part

The row is one flat class of 78 variables, nine of them holding one of eight small settings
classes. The live event is composed already: `EventBehaviours.compose()` reads the row and gives
the live event the behaviours it needs (twelve classes under `src/events/behaviours/`), and
`EventLooks.for_row()` gives it one look (one of ten classes under `src/events/views/`, picked by
its picture). So composition exists on the live side and is missing on the row's side and at the
boundary: callers and the live event's own parts read the flat settings directly.

| Ability, as she meets it | Settings today (fields of the row) | State today (on the live event) | Becomes |
|---|---|---|---|
| **What it is on the ground**: a footprint, solid where it blocks. Cafe tables close half a sidewalk; a dog has a footprint and blocks nothing; the boom at a checkpoint is solid only while lowered | `shape`, `solid_parts`, `obstructs_radius`, `solid_when`, `stands_as`, `when_it_stops`, `has_a_spread`, `stands_along_its_street`, `lies_across_its_street` | `_obstruction`, `_own_tiles`, `_spread_vertical`, `_stationary_vehicle_side`, `_arm_was_open` | **`BodySpec`** (new, in 4b) and **`EventBody`** (new, taken out of `EventInstance` ok) |
| **The noise it adds**: the field of excitement the baby is charged for | `intensity`, `inner_radius`, `outer_radius`, `core_intensity`, `core_radius`, `falloff_power`, `pulse_period`, `intensity_ramp`, `from_outside`, `barrier_structure`, and `VehicleSpec.field_from_its_centre` | `EventExcitement` (the event as an `ExcitementSource`), `silenced` | **`FieldSpec`** (new) and `EventExcitement` (exists) |
| **Ending the day**: the reach inside which she loses | `hard_fail`, `catch_reach`, `PursuitSpec.catch_reach` | none | **`LethalSpec`** (new); no live half, the live event answers with it |
| **A hold on her**: the chatting mother's conversation, a checkpoint hut's inspection | `detain_seconds`, `detain_radius`, `redetains` | `EventHold` | **`HoldSpec`** (new) and `EventHold` (exists) |
| **A pursuit**: it comes after her | `pursuit` (`PursuitSpec`, 10 settings) | `EventPursuit`, `EventOfficer`, `ChargeRecord`, `gave_up` | as it is; `catch_reach` moves to `LethalSpec` |
| **A warning before it acts**: its telegraph, its badge at the screen edge, its wait for her | `telegraph_time`, `still_while_telegraphing`, `telegraphs`, `warned_first`, `offscreen_notice`; `notice` (`NoticeSpec`) | the `Warning` clock (`_notice`), `phase`, `came_under_a_warning`; `PendingWarning` before it exists | **`WarningSpec`** (new) beside `NoticeSpec` (exists); the clock and the phase stay the live event's |
| **A path it moves along** | `mobile`, `speed`, `path_mode`, `path_length_tiles`, `paces`, `stops_where_it_arrives` | `EventRouteWalk`, `path`, `_path_travelled`, `_heading` | **`RouteSpec`** (new) and `EventRouteWalk` (exists) |
| **A car that drives**: the patrol car, the fire engine | `vehicle` (`VehicleSpec`) | `EventCarDriving` | as it is |
| **Being several creatures**: the pigeon flock | `flock_size`, `flock_spread` | `EventFlock` | **`FlockSpec`** (new) and `EventFlock` (exists) |
| **A look** | `look`, `warning_picture`, `draws_body_shadow`, `trails_a_lead`, `hides_in_its_hold`, `may_be_a_pelican`, `guard_sides` | `EventLook` and the nine looks that extend it, `is_pelican`, `drawer` | **`LookSpec`** (new) and `EventLook` (exists) |
| **Answering to the resistance's heat**: more of them, then it hunts | `heat_response`, `hunts`, `hunting` (`HuntSpec`) | `EventInvestigation`, `EventBarrierPost`, `RoadblockFarGuard` | `HuntSpec` takes the rung (`heat_response`), so a row answers to heat exactly when it says how |
| **Taking a bystander first**: the unmarked van | `abduction` (`AbductionSpec`) | `EventAbduction` | as it is |
| **What it brings after it**: a scar, a successor, a row it calls in | `aftermath` (`Aftermath`) | none (the spawner acts on it) | as it is |
| **Going away**, which every event does | `departs_at` | `EventDeparture` | stays a plain setting of the row behind `departure_speed()` |

Two things are deliberately not reshaped. **A car's strike stays the car's** (`EventCarDriving`),
not the row's `LethalSpec`: `hard_fail` means a place that ends the day, and every placement rule
keyed on it (a wall off the routes, a field kept clear) is wrong for a car on a road. **The stored
phase stays on the live event** (the record minty-quail-10: one stored phase, changed only by
`transition()`); a part asks for a change of phase, it never holds one.

### 1.2 What each part owns and answers

A **spec** below is the settings half: a `RefCounted` with no public field, built by its own
factory, never changed afterwards. The **live half** holds the state and is handed its spec when
the live event is set up. The row holds every part always: a row without the ability holds the
part's "none", which answers nothing, so neither the row nor a caller tests for a part. The
questions in the last column are answered by the part, to the row or the live event that asks on
a caller's behalf, and to the code inside the events folder that is handed the part; section 2
lists who asks.

| Part | Its settings (the spec) | Its state (the live half) | What it answers |
|---|---|---|---|
| `BodySpec` / `EventBody` | the ground shape; its pieces (the crash is two cars with a gap, today `SolidPart`, renamed `BodyPiece` since "part" now means an ability); whether the shape is solid, and when (always, once it starts, while lowered); what it is to a crowd walker (somebody, something, nothing); whether it parks; how it lies on its street (as it faces, as a spread across it, along it, across it: one choice, where today three flags can contradict) | the collision body, the tiles it is recorded on, the axis it lies along on the street it landed on, whether the boom's arm is up | how far it closes ground; how far it stops her; whether it has a body at all; its pieces and where each stands; whether it is solid now; whether it is raised; whether a walker goes round it; whether a car behind it turns round |
| `FieldSpec` / `EventExcitement` | the peak rate, the two radii, the louder core, the falloff, the pulse, the swell over its duration, whether walls stop it, whether several of it count as the strongest one only (the checkpoint's huts and booms), whether it is priced from its body or its centre | what it has landed on her, the cached contribution and projection | the rate at a distance; how far it reaches; how far it charges more than a walk takes off; beyond what distance it is certainly silent; what a walk through it costs; the peak at this age; its rate at a point now; what it will land on her course |
| `LethalSpec` | whether entering its reach ends the day, and the reach (its field's core unless it says otherwise) | none | whether it ends the day; the reach that does; (live) whether a point is inside it now, which also asks the phase and, for a pursuer, a clear line |
| `HoldSpec` / `EventHold` | the seconds, how far past its edge it takes her, whether it takes her again | the seconds left, whether it has held her | whether it holds her; for how long; from how far; again or once; whether a hold is running |
| `PursuitSpec` / `EventPursuit`, `EventOfficer` | its speed, how the chase starts, its warning, its stand-off and lunge, a catch that is a stop, whether it leaves its body standing | the chase, the held lunge, the charge's record | whether it pursues; how fast; whether it is chasing, has charged, has given up, has stopped her |
| `WarningSpec`, `NoticeSpec` / the `Warning` clock | the telegraph's seconds, whether it holds still for it, whether its coming is announced at the screen edge, whether it is warned of before it exists and for how long; the wait: how close she comes before it notices her | the notice clock; the phase is the live event's | how long it telegraphs; the least it fairly may; whether it waits for her and within what; whether it is waiting or telegraphing now |
| `RouteSpec` / `EventRouteWalk` | its speed, how its route is built and how long, whether it paces a beat, whether it parks where it arrives | how far along it is, its heading | whether it moves; how fast; whether it paces; its beat; how much of its way is left |
| `FlockSpec` / `EventFlock` | how many creatures, how far they spread | each bird's place, heading and height | whether it is a flock; the birds |
| `LookSpec` / `EventLook` | its picture, its warning picture, whether it casts a shadow, a trailing lead, hiding in its hold, the pelican chance, which sides its guards stand on | the look object and what it has drawn | which picture; the box it draws in; whether its picture is in her view |
| `VehicleSpec` / `EventCarDriving` | (none of its own once the field's datum is `FieldSpec`'s) | standing for her, the proposed frame | whether it drives; whether it is closing on a point; whether it strikes there |
| `HuntSpec` / `EventInvestigation`, `EventBarrierPost` | the rung (presses, hunts), how many men it lets out or how its man pursues | the men out, the spent guard, the post he left | whether it answers to heat; whether it investigates; how many it lets out |
| `AbductionSpec` / `EventAbduction`, `Aftermath` | as today | as today | as today, through methods |

### 1.3 What stays where

- **On the row itself**, as private settings behind methods: its id and what the run log calls
  one or several of it; the days it is available on and its act; its kind (recurring, one-shot,
  scripted, ambient); how the day draws and places it (which ground takes it, the sidewalk lane it
  wants, whether it takes a whole section of a street, how often it is drawn and the most a day
  stands, whether dawn, her walk or the director sites it, with the one switch by day the charging
  dog has); how long it lasts; how fast it leaves; whether it comes again; its role beside the
  catalogue (scenery, the mast). And its parts.
- **On the plan**: its row; where it stands, its route and its facing; the role the day gave it; the
  marks of a fixed part (a region door, the wall, a seal, a mast and its id); how it repeats;
  whether it is spent, permanent or silenced; and, while its live event is out of the world, that
  event's saved state as **one value** (`EventSave`, a name this design proposes: age, distance
  travelled, when it noticed her, each behaviour's state), where today four plan fields carry it
  and streaming copies them out and back one by one.
- **On the live event**: its place and heading (it is the node), its clock, its phase and the one
  place the phase changes, its published move (`MoveProposal`, what the crowd reads of it), and
  its live parts.
- **In streaming** (`EventStreaming`, the part of the event manager that brings a plan's live event
  in when she comes near and takes it out again): which plan is kept in the world, has been there
  once, or waits to come again (the plan fields `kept_live`, `was_live`, `comes_in` and
  `wait_began` today). These are its own bookkeeping. The plan keeps only a private handle on the
  node standing for it, so it can answer `is_in_the_world()` and `where_it_stands_now()`.

### 1.4 How a row declares its parts

A row is written through **`EventDraft`** (a name this design proposes: a row being written). Each
line names one ability; `build()` validates the whole and hands back the row, which has no
setter. Two real rows, as they are and as they become.

**Cafe tables** (a spread of tables that closes half a sidewalk and hums), today:

```gdscript
static func _cafe_tables() -> EventDef:
	var def := EventDef.new()
	def.id = "cafe_tables"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.CAFE
	def.stands_as = EventDef.StandsAs.SOMETHING
	def.when_it_stops = EventDef.WhenItStops.PARKS
	def.has_a_spread = true
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.intensity = 12.0
	def.inner_radius = 38.0
	def.outer_radius = 64.0
	def.telegraph_time = 1.6
	def.pulse_period = 6.0
	def.solid(GroundShape.band(24.0))
	def.weight = 4.0
	def.max_per_day = 24
	return def
```

and as its parts:

```gdscript
static func _cafe_tables() -> EventDef:
	var row := EventDraft.new("cafe_tables")
	row.ground([GameEnums.TileType.SIDEWALK])
	row.drawn(4.0, 24)                 # its weight in a bag, and the most a day stands
	row.look(LookSpec.of(EventDef.Look.CAFE))
	row.body(BodySpec.solid(GroundShape.band(24.0)).as_a_spread().walked_round().parked())
	row.field(FieldSpec.of(12.0, 38.0, 64.0).pulsing_every(6.0))
	row.warning(WarningSpec.lasting(1.6))
	return row.build()
```

**The alley robber** (he waits in an alley, warns when she comes within 180px, then chases her; his
catch ends the day), today:

```gdscript
static func _alley_robbery() -> EventDef:
	var def := EventDef.new()
	def.id = "alley_robbery"
	def.display_name = Texts.EVENT_NAMES[def.id]
	def.look = EventDef.Look.ROBBER
	def.stands_as = EventDef.StandsAs.SOMEBODY
	def.when_it_stops = EventDef.WhenItStops.GOES_ON
	def.warning_picture = EventDef.WarningPicture.ROBBER_ALERT
	def.shape = GroundShape.point(9.0)
	def.first_day = 8
	def.act_tag = 3
	def.placement = [GameEnums.TileType.ALLEY]
	def.intensity = 16.0
	def.inner_radius = 26.0
	def.outer_radius = 200.0
	def.telegraph_time = 1.8
	def.duration = Tuning.PURSUIT_TIME
	def.pursuit = PursuitSpec.at(130.0)
	def.pursuit.lunge_reach = 38.0
	def.notice = NoticeSpec.at(180.0)
	def.pursuit.walk_speed = 40.0
	def.pursuit.warns_for = CHARGER_WARNING
	def.departs_at = 100.0
	def.hard_fail = true
	def.weight = 1.5
	def.max_per_day = 4
	return def
```

and as its parts:

```gdscript
static func _alley_robbery() -> EventDef:
	var row := EventDraft.new("alley_robbery")
	row.from_day(8, 3)                 # first day, act
	row.ground([GameEnums.TileType.ALLEY])
	row.drawn(1.5, 4)
	row.lasts(Tuning.PURSUIT_TIME)
	row.leaves_at(100.0)
	row.look(LookSpec.of(EventDef.Look.ROBBER).warning_as(LookSpec.WarningPicture.ROBBER_ALERT))
	row.body(BodySpec.footprint(GroundShape.point(9.0)).walked_through().going_on())
	row.field(FieldSpec.of(16.0, 26.0, 200.0))
	row.warning(WarningSpec.lasting(1.8))
	row.notice(NoticeSpec.at(180.0))
	row.pursuit(PursuitSpec.at(130.0).walking_at(40.0).lunging_from(38.0)
			.warning_for(CHARGER_WARNING))
	row.lethal(LethalSpec.at_its_core())
	return row.build()
```

What the form buys, beyond the rule:

- **A variant is a draft started from a row** (`EventDraft.from(row)`), with the parts it changes
  replaced. It serves every place that copies a row today with `Resource.duplicate()` and then
  writes fields, or builds it again to give it another id: the heated copy (`at_heat()`), the copy
  for a later day (`for_day()`), the copy warned of first, the row without its aftermath, the
  building's fire, the explosion outside, the neighbor heading home, the men a vehicle lets out,
  the lesson's dog and the two task guards (a new id), a seal's copy and the wall's unguarded
  middle body (`SealPlanner`), the alley mouth's wall body (`RegionPlanner`), the raid's pacing
  patrol car (`ResistanceHappenings`), and the director's two (a patrol sent toward her, a forced
  row given ground). Each site that duplicates carries `shape` and `solid_parts` across by hand
  today because `duplicate()` does not copy them, and a site that forgets draws and charges
  nothing with no error. A draft copies parts, so the trap is gone.
- **`validate()` loses the pairing checks a part makes unwritable** (a spread that also lies
  across its street, a catch reach set on the row and on its pursuit at once, a hunt with no
  rung) and keeps the checks that span parts (a hold on a row that ends the day, a body reaching its own
  lethal reach, the telegraph fairness contract).
- **The row stops being a `Resource`.** It is a `RefCounted` value built in code; nothing saves it
  and nothing duplicates it. `EventCatalogue.all()` validates every shape on load as today.
- `display_name` and `act_tag` are absent from the examples on purpose: the first has no reader
  (section 7), the second is `from_day()`'s second argument.

## 2. The interface

### 2.1 Four rules every method below keeps

1. **The event answers.** A caller asks the row, the plan or the live event it holds. The plan and
   the live event answer for their row what callers ask through them, so no caller writes
   `plan.row().x()` or `instance.row().x()` to read a setting. `row()` stays on both for the code
   that passes a row on (spawning another of it, starting a draft from it, the bags). **Inside the
   events folder, code that runs one ability asks that ability's part**: the row hands a part out
   through one method each (`body()`, `field()`, `lethal()`, `hold()`, `pursuit()`, `warning()`,
   `notice()`, `route()`, `flock()`, `look()`, `hunt()`, `abduction()`, `aftermath()`) to the
   composer, which hands it to the live half and the look, and to the plan builder. That is the
   approved wording, the abilities "become parts it has, each answering its own questions"
   (inbox #1173 in gray-dolphin, statement 22's context, answered "yes"). A question that spans
   parts (how far the field reaches, which needs the body and the route too) stays the row's.
2. **An event without a part answers that part's questions with nothing**: a reach of zero,
   `false`, an empty list. No caller tests whether a part is there.
3. **A name says what the caller wants, and a yes-or-no question never takes the name of the field
   it replaces** (designing-classes' rule for every conversion, "Fields are not API"): `hard_fail`
   becomes `ends_the_day()`, `is_finished` becomes `is_gone()`, `mobile` becomes `moves()`. The reason is the trap the godot skill's "Types" names: once a method
   has a field's old name, a read left behind without its parentheses (`thing.is_finished`) is a
   reference to the function, which is always true; the engine reports nothing, and the field-read
   check fails it only through a receiver whose class it cannot tell, in a file under `src/` that
   no longer carries the opt-out line; on a typed receiver nothing reports it
   (`method-without-parentheses.md`). With a new name the stale read names nothing and fails: at
   the parse on a typed receiver in a file that does not silence `unsafe_property_access`, when
   the line runs everywhere else. A number may keep its name (`speed()`), since a function used
   as a number fails at once. The rule stops at yes-or-no questions: a field of another kind whose
   accessor point 1 lists under the field's own name can be read in a way that takes a function
   as silently (the row's `pursuit`, tested against null; its `look`, read in a `match`), and
   whether such an accessor takes a new name too is open (`method-without-parentheses.md`).
4. **A change is told as what happened, never set as a value**: `silence()`, `spend()`,
   `notice_her_at()`, `place_at()`; the event works out what it already knows (the record
   brisk-lark's "events instead of setters").

In the tables, "ok" marks a method that exists today and stays; every other method is new. "Row",
"plan" and "live" say which object is asked.

### 2.2 The placement rules and the dawn

Asked by the event scheduler and what it is being broken into (the dawn phases, `PlanBuilder`,
`RowGround`), the street rules, the location draw, the walk's ground (`WalkGround`), the mast
sites, and the seal and region planners under `src/routes/`.

| What is asked | Method | Answered by |
|---|---|---|
| Is the row available on this day | row `available_on(day)` ok | the row |
| Is it placed at dawn, sited from her walk, or sited by the director, on this day | row `spawn_mode_on(day)` ok, `is_sited_from_her_walk()`, `is_handed_to_her_walk()` ok, `is_a_set_piece_on_her_way()` | the row |
| Which kind of row is it | row `is_ambient()` ok, `is_a_one_shot()`, `is_scripted()`; `ambient_source()` | the row |
| Which ground takes it | row `stands_on(tile_type)`, `ground_kinds()`, `stands_only_in_alleys()`, `sidewalk_lane()`, `stands_at_a_front()` | the row |
| Does it need one street to lie across (so a corner is no site) | row `lies_as_a_spread()` | body |
| Does it take a whole section of a street | row `spans_the_street()` ok | the row |
| How often is it drawn, here, and how many may stand | row `drawn_as_often()` ok, `drawn_as_often_on(ground)`, `most_in_a_day()` ok | the row |
| Does it close ground, and how far | row `closes_ground()`, `obstructs_within()` ok | body |
| Does it stop her, how far, and where are its pieces | row `has_a_body()`, `solid_reach()` ok, `body_pieces()` (today `parts()`), `ground_shape()` | body |
| Is its body recorded on the ground for the whole day (a standing body that is no door and no boom) | row `stands_as_a_fixed_body()` | body, hold |
| Does entering it end the day, and within what | row `ends_the_day()` ok, `lethal_reach()` ok, `effect()` ok | lethal |
| How far does its field reach, and how far does it charge more than a walk takes off | row `field_reach()` ok, `line_reach()` ok, `reach_above(rate)` ok, `has_a_field()` ok, `reaches_the_far_lane()` ok | field (with body and route) |
| What does walking through it cost | row `walk_through_cost()` ok | field |
| Does a zero-cost line have to get past it | row `has_a_line_to_avoid()` ok; plan `counts_against_the_line()` ok | the row; the plan |
| Does it wait for her, and within what | row `notice_within()` ok | notice |
| Does it move, pace a beat, pursue | row `moves()`, `paces_a_beat()`, `pursues()` | route, pursuit |
| How is its route built (asked by the plan builder, which is handed the part) | the route part's `kind()`, `tiles()` | route |
| Is it scenery, is it the mast | row `is_scenery()`, `is_a_mast()` | the row |
| What does it leave or call in | row `scar_id()`, `leaves_behind()` ok, `calls_in()` | aftermath |
| Where does a plan stand, walk, face | plan `is_placed()` ok, `placed_at()` ok, `walks()` ok, `stands_still()` ok, `ends()` ok, `faces()` | the plan |
| How far is a plan from a point or another plan | plan `distance_from(at)` ok, `gap_to(other)` ok | the plan |
| Does a plan block her way, and what disc does it shut | plan `obstructs()` ok, `blocking_radius()` ok, `clearance(her_reach)` ok | the plan, asking body and lethal |
| Does a plan deny a point, touch a rect, reach a rect, spoil a calm area | plan `denies()` ok, `reach_touches()` ok, `reaches()` ok, `spoils()` ok | the plan, asking field and route |
| Does a plan keep its lethal field clear of other events | plan `keeps_its_field_clear()` ok | the plan, asking lethal and pursuit |
| Is a plan a fixed part, a door, in the wall, a mast | plan `is_a_fixed_part()` ok, `is_door()` ok, `is_in_the_wall()` ok, `is_a_mast()`, `mast_id()` | the plan |
| Are two plans the same row (one of a row per street) | plan `is_the_same_row_as(other)`, `row_id()` ok | the plan |
| The role the day gave it | plan `role()`, `give_role()` ok | the plan |

### 2.3 The crowd and the traffic

The crowd's tick reads no field of an event. It reads each live event's published move
(`MoveProposal` on the map's list of moves), the map's record of blocked tiles, and a boom's
shared state. What it asks, and what the event is asked on its behalf:

| What is asked | Method | Answered by |
|---|---|---|
| Which door bodies hold a walker (asked once as a day starts, `Crowd`) | plan `detains_her()` ok, `placed_at()` ok | hold |
| The discs of the wall's and the doors' bodies, for siting (`DayStreets.siting_region()`) | plan `obstructs_within()` ok, `placed_at()` ok | body |
| Is a figure standing still walked round or walked through; has it parked for good | asked by the live body as it fills its event's move: the body part's `is_walked_round()`, `parks()` (the row's until the body part exists, asked by `EventBody`; the event writes the move from its answers ok) | body |
| Which tiles a standing body takes (the map's blocked record, written by `EventSpawner`) | row `stands_as_a_fixed_body()`, `body_pieces()` | body |
| Is the boom up | live `is_raised()` ok | body |

### 2.4 Her and the baby

| What is asked | Method | Answered by |
|---|---|---|
| What the baby is charged at a point | `EventManager` sums `ExcitementSource.contribution_at(at)` ok over the live events' sources; live `source()` ok hands the source to the manager | field |
| Has anything ended her day, and what | live `is_lethal_at(her)` ok, `logged_name()` ok, `row_id()` ok | lethal (a car: its driving) |
| Does a row hold her, from how far, for how long, again | live `detains_her()` ok, `detain_distance()` ok, `detains_for()` ok, `detains_again()` ok | hold |
| Is a hold running, has it held her; start one | live `is_chatting()` ok, `has_chatted()` ok, `start_chat()` ok | hold |
| Is this door body the boom | live `is_a_boom()` ok, plan `is_a_boom()` | body |
| Where she is, for every event and part | `WhereSheIs` ok (section 2.10): `at()`, `pram_at()`, `view()`, `is_running()`, `baby_is_awake()`, `is_held_at_a_door()`, all ok | the event manager tells it |

### 2.5 The danger cues and the HUD

| What is asked | Method | Answered by |
|---|---|---|
| Does its coming get a badge at the screen edge | row `announces_its_coming(walk_speed)` ok | warning, lethal, route, pursuit |
| How fast does it come at her | row `approach_speed()` ok | pursuit, route |
| How far out is its field's edge (the badge's gap) | row `heard_within()` ok | field |
| Which colour, which icon | row `ends_the_day()` ok, `picture()` ok | lethal, look |
| Is it gone, did it come under a warning, is it charging, is it in view | live `is_gone()` ok, `was_warned_of()` ok, `has_charged()` ok, `drawn_box()` ok | the live event |
| A warning with nothing in the world yet (`PendingWarning`) | `row()` ok, `points_at()` ok, `seconds_left()` ok, `logged_name()` ok | the warning |
| The run lesson's hint: is this a pursuer, how long does it telegraph | live `pursues()` ok, `telegraphs_for()` ok | pursuit, warning |
| The halo, the caret and the mark over her head | `ExcitementSource` ok: `contribution_at()`, `expected_gross_at()`, `will_be_lethal()`, its rim | field |
| The debug view's fields layer | live `field_rings()` (the radii it draws), `ends_the_day()`, `field_shape()` ok, `solid_axis()` ok, `ground_shape()` | field, body |

### 2.6 The run log and GoatCounter

| What is asked | Method | Answered by |
|---|---|---|
| What an event is called | live `logged_name()` ok, `row_id()` ok; plan `row_id()` ok | the row |
| What raised the mark over her head | live `closes_on(point)` ok (a car warning her), `ends_the_day()` ok, `field_reaches(point)` ok | car, lethal, field |
| A chase's log lines | live `pursues()` ok, `is_waiting()` ok, `is_telegraphing()` ok, `is_chasing()` ok, `is_gone()` ok, `is_on_its_way_out()` ok, `has_stopped_her()` ok | pursuit, the live event |
| Which planned events she has met | plan `is_in_the_world()` ok, `field_reaches(point)` ok | the plan, asking field |
| The telemetry map's marks | plan `is_placed()` ok, `role()`, `walks()` ok, `placed_at()` ok, `ends_the_day()` ok | the plan |
| The day's counts by row | plan `row_id()` ok | the plan |
| The nearest event, for the readouts | live `row_id()`, `age()`, `telegraphs_for()`, `field_reaches(point)` | the live event |
| What an encounter was (`EncounterWatch`, inside the events) | live `detains_her()` ok, `source()` ok; its own record kept in its own table, not on the live event | hold, field |

### 2.7 The resistance

| What is asked | Method | Answered by |
|---|---|---|
| Does a contact's rider have a body, and how far out does a touch count | live `has_a_body()`, `solid_reach()` ok | body |
| Is she inside its core (a task completed at the core) | live `core_reaches(point)` | field |
| Is the task's event still there, parked, and where is its beat | live `row_id()`, `is_gone()`, `has_parked()`, `beat()` | the live event, route |
| A street's door: its boom and its huts | plan `is_a_boom()`, `detains_again()`, `placed_at()` ok, `faces()` | body, hold |
| A mast still speaking | plan `is_a_live_mast()`, `mast_id()`, `placed_at()` ok | the plan |
| A row's reach and speed for a task's arithmetic | row `core_within()`, `speed()`, `for_day(day)` ok | field, route |
| Who in a closed park is walked out (today five fields in `ParkCordon`) | live `is_ambient()`, `was_sent_at_her()`, `drives()`, `departure_speed()` ok, `is_on_its_way_out()` | the row, pursuit, warning |
| The raid's patrol car made to pace | `EventDraft.from(row)` with its route replaced | route |

### 2.8 The scene recipes and the developer's rigs

| What is asked | Method | Answered by |
|---|---|---|
| May a row be staged, held, made to charge or made relentless | row `pursues()`, `drives()` ok, `investigates()` ok, `parks_where_it_arrives()`, `leaves_behind()` ok, `leaves_its_body()` ok, `notice_within()` ok, `starts_by()` ok, `is_a_mast()`, `spawn_mode_on()` ok, `available_on()` ok, `most_in_a_day()` ok, `field_reach()` ok | each part |
| Stage a plan at an age, keep it in the world, make it a mast | plan `arrive_aged(seconds)`, `keep_in_the_world()` ok, `stand_as_a_mast(id)` | the plan |
| The live event of a plan, to name or command it | `EventManager.event_of(plan)`; then live `notice_her_at()` ok | streaming |
| The route rig's hazards and bodies | live `is_a_standing_lethal_place()`, `lethal_reach()`; plan `stands_as_a_fixed_body()`, `body_pieces()`; plan `detains_again()`, `detain_distance()`, `where_it_stands_now()` ok, `faces_now()` | lethal, body, hold |

### 2.9 The tests

A test is a caller like any other ("yes", inbox #1182 in gray-dolphin): it asks the same methods.
Nothing is added for tests alone. A test that sets a row's field today builds the row it needs
with a draft; a test hands the live event a `WhereSheIs` and tells it where she is; a
test that reads `phase` asks the question it means (`is_waiting()`, `is_telegraphing()`,
`is_active()`, `has_stopped_her()`, `is_on_its_way_out()`, `has_parked()`,
`is_only_its_barrier()`, `is_gone()`).

### 2.10 The live event's own parts, and where she is

The behaviours and the looks are parts of the live event, and they are other objects: the rule
holds for them (inbox #1173 in gray-dolphin, statement 23, "interaction between different objects
need to go through APIs"). Today they read the live event's fields 481 times (of 541 reads from
inside the folder), among them `_heading`, `_path_travelled`, `_navigator`, `_mover`,
`_obstruction`, `_charge` and `_notice`, and they reach each other through it in about twenty
places (`event.car`, `event.on_foot`, `event.barrier_post`). They change as the crowd's lane
strategies did (the record brisk-lark):

- **What never changes is handed in, not asked for.** When the live event is set up, each part is
  handed its own spec, the map, the navigator, what it walks as, `WhereSheIs`, and the sibling
  parts it works with (the car is handed the investigation, the departure the barrier post, the
  roadblock's look the barrier post). No part looks a sibling up through the event.
- **What changes is asked through one narrow interface the live event builds for its parts**,
  `EventInstance.Figure` (a name this design proposes: the figure a behaviour moves). Questions:
  `place()`, `heading()`, `travelled()`, `age()`, `chase_age()`, `walks()`, the phase questions.
  What happened, each carrying the whole change: `turn_to(heading)`, `walk_on(distance)`,
  `step_by(delta)`, `begin(phase)`, `be_done()`, `drop_its_body()`, `charge_began()`,
  `hold_the_notice(delta)`. The body's collision shape, the notice clock and the charge record
  stay private to the live event. `Figure` has these, of the phase questions the ones the
  behaviours below ask (all of section 2.9's but `is_active()` and `has_stopped_her()`), and not
  `drop_its_body()`, which no behaviour that asks through it calls yet; it has further questions
  and events the records minty-quail-tiny-alpaca, minty-quail-tawny-swan and
  minty-quail-striped-hawk list. Every behaviour, and the barrier post's far guard, asks through it
  and is handed its parts; none holds its event.
- **A look asks the same questions outside callers ask**, plus its own few (`is_silenced()`,
  `is_its_guard_warning()`, `is_drawn_as_a_pelican()`, `boom_openness()`), and is handed its
  `LookSpec` and its drawer. The base look (`EventLook`) is so handed ok: its row (until `LookSpec`
  exists), its drawer and whether it draws, and it asks the live event through methods. The figure,
  pursuer, vehicle, flock, checkpoint and fire looks, `SpreadLook` and `RankLook` ask the same way
  ok; `RoadblockLook` follows.

**`WhereSheIs`** (a name this design proposes) is the one object that says where she is
this tick: her position, her pram's, the camera's view, whether she runs, whether the baby is
awake, whether a door holds her. The event manager tells it once a tick in one call, and the
events' world holds it. A fact derived once and handed around (inbox #1156 in gray-dolphin). Each
live event hears it through a handle of its own, so that an event made after the tick's word
knows nothing of her until the next one, as its own fields did; the halo's word once a drawn
frame, an officer's first sight of her and a notice's point go to that event's handle and not to
the shared object. The handle is the builder's choice, open to the player's overturn (the record
minty-quail-olive-finch): it keeps today's answers, three of which are slightly wrong (section 7,
point 6).

### 2.11 Several reads that become one question

| Today | Where | One question |
|---|---|---|
| `pursuit.speed if pursuit else (speed if mobile else 0.0)`, three times | `EventDef` | one private helper of the row |
| a distance compared with `def.outer_radius` | the unmarked van's take | live `field_reaches(point)` ok, which the run log's observer already asks |
| `distance <= def.inner_radius` | the resistance's contact point | live `core_reaches(point)` |
| `not is_finished and def.hard_fail and not def.mobile` | the route rig | live `is_a_standing_lethal_place()` |
| `shape != null and obstructs_radius > 0 and not mobile and detain_seconds <= 0 and solid_when != WHILE_LOWERED` | the route rig, and the spawner's own record in other words | row `stands_as_a_fixed_body()` |
| `kind != AMBIENT and pursuit == null and vehicle == null and not warned_first and not starts_by(ARRIVES_CHASING)` | the park cordon | live `is_ambient()`, `was_sent_at_her()`, `drives()` |
| `solid_when == WHILE_LOWERED`, five places; `redetains` read as "this is a door's hut or post", six places | the live event and its hold, the spawner, the resistance, the route rig (the checkpoint controller asks already) | row and live `is_a_boom()` ok, `detains_again()` ok; the plan's `is_a_boom()` and `detains_again()` |
| `on_her_way != null and on_her_way.at_a_front`, three times; `on_her_way != null and kind == ONE_SHOT`, twice | the scheduler, streaming | row `stands_at_a_front()`, `is_a_set_piece_on_her_way()` |
| `placement.size() == 1 and placement[0] == ALLEY` | the scheduler | row `stands_only_in_alleys()` |
| `vehicle and vehicle.field_from_its_centre`, three times | `EventDef`, `EventInstance` | the field part's `datum()` (the row's `datum()` until the field part exists ok) |
| the ramp over its duration and the pulse, five fields | `EventInstance.current_intensity()` | the field part's `peak_through(age, into_its_burst)` (the row's `peak_through(age, into_its_burst, beat)` until the field part exists ok; the caret passes its closed-form mean as `beat`) |
| `mast_id == "" or def.role != MAST or silenced`, twice | the resistance | plan `is_a_live_mast()` |
| `plan.row().id == candidate.row().id` | the street rules | plan `is_the_same_row_as(other)` |
| `age`, `travelled`, `noticed_at`, `behaviours` copied out and back one by one | streaming, the scene recipes | live `save()`, `restore(save)`; plan `keep(save)`, `saved()` |

### 2.12 The skill's two tests, applied

**Would any caller miss it.** Deleted, since nobody would: `display_name` (and the table
`Texts.EVENT_NAMES` it is read from, section 7); the plan's
`kept_live`, `was_live`, `comes_in` and `wait_began` as plan fields (streaming's bookkeeping); the
four saved-state fields (one `EventSave`); `VehicleSpec.field_from_its_centre` as a vehicle
setting (it is the field's); `EventInstance`'s twelve public behaviour fields. Not added, since
nobody asks: a way to read a part from outside the events folder, any setter on a built row, and a
question per setting where one question carries the answer (the badge, the fixed body).

**Can the implementation be swapped.** Three answers already have several implementations behind
one question, which is the sign the skill looks for: what ends the day (a place's core, a
pursuer's catch along a clear line, a car's strike ahead of its nose, all behind
`is_lethal_at()`), the field's distance (a disc, a capsule about a body's spine, an ellipse
stretched ahead of a mover, a sum over a flock's birds, all behind `contribution_at()`), and when
a body is solid (always, once it starts, while lowered, behind `is_solid()`). Two swaps the
interface makes possible that the fields do not: `field_reaches(point)` can answer with the real
field, where its five callers compare a distance with one radius; and where a row stands
(`stands_as_a_fixed_body()`, `body_pieces()`) can be worked out once per row, where two files
re-derive it.

## 3. What the placement track needs from it

The placement track owns `src/events/street_rules/`, `location_draw.gd`,
`day_locations.gd`, `view_bag.gd` and the scheduler's blocks, and it is being built now. Its files
ask a row and a plan almost only through methods already (`row()`, `line_reach()`,
`obstructs_within()`, `notice_within()`, `counts_against_the_line()`, `reach_touches()`,
`denies()`, `obstructs()`, `blocking_radius()`). What is left in them is `row().paces` in five
places, `row().id` in one, and the cache keys the scheduler builds out of a row's settings. **The
rule for the track: a new line there asks a method, and where the method is missing the placement
pull request adds it to `event_def.gd` or to the plan under the name below**, so the events'
conversion finds nothing to redo in those files.

| Step of `placement-by-construction.md` | What it asks | Method |
|---|---|---|
| 1, the route's ground rule (no body's disc and no lethal row's inner disc on a route's tile off the sidewalks) | does a plan block; the disc it shuts; where it stands | plan `obstructs()` ok, `blocking_radius()` ok, `placed_at()` ok |
| 1 | is a row asked the route rules at all (not scenery, not a pursuer, not a mast, not a door) | plan `counts_against_the_line()` ok |
| 1 | does a row pace, and where is its beat | row `paces_a_beat()` (new; replaces the five `row().paces`), plan `walks()` ok |
| 2, a street drawn as one unit | at most one of a row per street | plan `is_the_same_row_as(other)` (new; replaces `row().id == row().id`) |
| 2 | is a drawn row one with a body, so the crowd recycles a car standing where it lands | row `closes_ground()` (new), `stands_as_a_fixed_body()` (new), `body_pieces()` (today `parts()`) |
| 2 | does a row take a whole section | row `spans_the_street()` ok |
| 2 | the same rows on the same tiles along two walks (the step's test) | plan `row_id()` ok, `placed_at()` ok |
| 3, one declared density table | a row's weight, and its weight on one kind of ground | row `drawn_as_often()` ok, `drawn_as_often_on(ground)` (new: its weight times its own factor for that ground, 1 where the row names none) |
| 3 | which ground takes a row | row `stands_on(tile_type)` (new), `ground_kinds()` (new), `stands_only_in_alleys()` (new), `sidewalk_lane()` (new), `lies_as_a_spread()` (new) |
| 3 | rows that take the same ground share one cached answer (today a key built from `placement`, `pavement_side`, `hard_fail` and `has_a_spread` in five places) | row `ground_key()` (new: one string the row gives) |
| 3 | a row's role by view (wall, friction, set piece), which `EventScheduler.role_for()` works out | row `ends_the_day()` (new), `walk_through_cost()` ok, `is_scenery()` (new), `is_a_one_shot()` (new), `spawn_mode_on(day)` ok, `line_reach()` ok |
| 3 | a row's act, for the table's act column | row `act()` (new) |
| 3 | the most of a row a day stands | row `most_in_a_day()` ok; once step 2 drops the caps for drawn rows its callers are the director's moments and the scene recipes, and the step says whether any is left |
| 4, the beats as rigged marbles | is a row sited from her walk, at a building's front; is it the set piece | row `is_sited_from_her_walk()` (new), `stands_at_a_front()` (new), `is_a_set_piece_on_her_way()` (new), `is_handed_to_her_walk()` ok |
| 4 | a rigged marble takes its location | plan `place_at(at)` (new; today `plan.position = ...`) |
| the breakup's `PlanBuilder` | how a row's route is built; the lane it stands in; its body's pieces | the route part's `kind()` and `tiles()`, handed to the builder by `row.route()`; row `sidewalk_lane()`, `ground_shape()`, `body_pieces()` (all new) |
| the breakup's `RowGround` | which tiles a row may stand on | the step-3 ground questions and `ground_key()` |
| every step | how far a row's field, body, lethal reach and notice reach | row `field_reach()`, `line_reach()`, `obstructs_within()`, `solid_reach()`, `lethal_reach()`, `notice_within()`, all ok |

Two notes for the track. **`blocking_radius()` reads a lethal row's field core
(`inner_radius`), not `lethal_reach()`**; the two differ only for a row whose catch is narrower
than its core (the masked man on the escape's stairs, a hunting roadblock's guard). The placement
track keeps it as it is, under its name; it is made correct in a pull request of its own (section
7, point 6). **Where a plan's body stands on its
sidewalk band and which tiles it takes** is worked out today by the live event's picture geometry
(`EventFootprints.stands_at()`, `body_axis()`), which the dawn reads across a layer
(`tools/layer_map.py` lists it); the breakup's `PlanBuilder` is where that answer moves, and the
plan then answers `stands_at()` and `body_tiles()` itself.

## 4. The reads, by class, with what replaces each

Counted on `main` as it stood on 2026-11-09 with `uv run python tools/check_field_reads.py --list`
and `--summary`, and with `rg` for what the check cannot see.

- **The check's list**: 1,187 lines in 77 classes. 687 have their reader in `src/events/`; 655 are
  reads of a class declared in `src/events/`, 589 from inside the folder and 66 crossing in from
  outside (`src/dev/` 31, `src/resistance/` 19, `src/routes/` 9, `src/city/` 6, `src/ui/` 1).
- **A line is one reader file and one field**, so the uses are more: 1,504 of the row's fields
  (974 of them the catalogue writing its rows), 583 of the live event's, 57 of `PursuitSpec`'s.
- **The plan record is not in the list at all**: the check does not see an inner class. `rg` by
  receiver name finds about 400 reads of its fields in some 20 files, 113 of them in
  `event_streaming.gd` (the search guesses receivers by name, so the builder counts again once
  `EventPlan` is a class the check sees).
- **Reads through an untyped receiver, which the check skips**, found with `rg '\.def\.'` outside
  `src/events/`: `city.gd` (`id`), `debug_layers.gd` (five), `dev_rig.gd` (seven),
  `region_planner.gd` (one write). In all `rg` finds 51 reads of a row's field through `.def.` in
  14 files outside the events folder, 24 of them `id`.
- **The tests**: 138 files under `tests/` read an event's field. `.def.id` 258 times,
  `.is_finished` 154, `.live` 144, `.is_leaving` 133, `.def.obstructs_radius`
  46, `.phase` 40; 11 files build a row with `EventDef.new()` and 18 write a row's field.
  `tools/cost_table.gd` reads 28 and the probes name the plan record or a row's field 130 times in
  48 files.

"In" and "out" below are the check's reader files inside and outside `src/events/`, the catalogue
counted where it only writes.

### 4.1 The row (`EventDef`)

| Field | Reader files | Replaced by |
|---|---|---|
| `id` | 9 in, 5 out (the readouts, the route rig, the scene recipes, the still watch, the resistance), 24 untyped | row `id()`; through a live event `row_id()` and `logged_name()` ok; through a plan `row_id()` ok, `is_the_same_row_as()` |
| `display_name` | written by the catalogue; no reader in `src/`, `tests/` or `tools/` | deleted, nobody would miss it (section 7) |
| `noun`, `noun_plural` | 2 in (`EventsAhead`'s run-log lines) | row `noun(count)` |
| `counts_charges_as` | 2 in | row `charges_counted_as()` (its own id where it names none) |
| `act_tag` | 1 in, 1 out (`SealPlanner`) | row `act()`; set by `EventDraft.from_day(first_day, act)` |
| `kind` | 3 in, 2 out (the park cordon, `SealPlanner`), the dev rig untyped | row `is_ambient()` ok, `is_a_one_shot()`, `is_scripted()` |
| `first_day`, `last_day`, `scripted_day` | the catalogue; `SealPlanner` copies `first_day` | row `available_on(day)` ok; a draft for the copy |
| `weight` | the catalogue; `at_heat()` | row `drawn_as_often()` ok, `drawn_as_often_on(ground)` |
| `max_per_day` | 3 in, 1 out (the scene recipes) | row `most_in_a_day()` ok |
| `placement` | 4 in (the scheduler nine times, the director, the pending warning) | row `stands_on(tile_type)`, `ground_kinds()`, `stands_only_in_alleys()`, `ground_key()` |
| `pavement_side` | 2 in, 1 out (`SealPlanner`) | row `sidewalk_lane()`; a draft for the seal's copy |
| `_spans_the_street` | private already | row `spans_the_street()` ok; the draft's `spanning_the_street()` replaces `span_the_street()` |
| `spawn_mode`, `from_day_after` (`DaySwitch`: `after_day`, `spawn_mode`, `notice`) | 2 in; 7 lines of `DaySwitch`, all in | row `spawn_mode_on(day)` ok, `for_day(day)` ok, `comes_down_her_line()` ok, `crosses_ahead_of_her()`; `DaySwitch` becomes private to the row |
| `on_her_way` (`OnHerWay.at_a_front`) | 2 in | row `is_sited_from_her_walk()`, `stands_at_a_front()`, `is_handed_to_her_walk()` ok, `is_a_set_piece_on_her_way()` |
| `role` | 2 in, 1 out (the scene recipes), the resistance untyped | row `is_scenery()`, `is_a_mast()`; plan `is_a_mast()` |
| `ambient_source` | 1 in (the scheduler) | row `ambient_source()` |
| `duration` | 3 in | row `lasts_for()`; the field asks it for its swell |
| `departs_at` | the catalogue | row `departure_speed()` ok |
| `repeat_every`, `repeat_after` | 2 in | row `comes_again_every()` ok, `comes_again_after()`, asked once as a plan is made; plan `repeats()` ok |
| `shape` | 11 in, 3 out (the route rig, the happenings, `SealPlanner`) | row `ground_shape()` ok; the field part's `datum()`; a draft for the copies; the live body and the look are handed the body part |
| `solid_parts`, `_default_parts` | 1 in, 2 out (both copying it into a variant) | row `body_pieces()` ok; a draft copies parts, so the hand copy goes |
| `obstructs_radius` | 10 in, 2 out (the route rig, `SealPlanner`) | row `obstructs_within()` ok, `closes_ground()`, `has_a_body()` ok, `solid_reach()` ok; the looks ask `drawn_width()` (the row's, asked by the footprints ok) |
| `solid_when` | 4 in, 1 out (the route rig), the resistance untyped | row `is_a_boom()` ok, `stands_as_a_fixed_body()`; the body part's `solid_from()` for the live body (the row's until the body part exists ok); live `is_solid()` ok |
| `stands_as`, `when_it_stops` | 2 in each (the live event filling its move) | the body part's `is_walked_round()`, `parks()`, asked by the live body (the row's until the body part exists ok) |
| `has_a_spread`, `stands_along_its_street`, `lies_across_its_street` | 3, 2 and 2 in (the scheduler, the footprints) | row `lies_as_a_spread()`; the body part's `lies()` (one choice of four) for the footprints (the row's `lies()`, an `EventDef.Lie`, until the body part exists, ok) |
| `vehicle` (`VehicleSpec.field_from_its_centre`) | 8 in, 2 out (the scene recipes, the park cordon); 3 lines of the spec | row `drives()` ok; the field part's `datum()` |
| `intensity` | 7 in | row `has_a_field()` ok; the field part's `peak()` and `peak_through()` for the live event and the looks (the row's `peak()` and `peak_through()` until the field part exists ok) |
| `inner_radius` | 6 in, 2 out (the resistance's contact point and director) | row `core_within()` ok (the canvas looks ask it); live `core_reaches(point)`; the flock and the looks are handed the field's spec |
| `outer_radius` | 7 in, the dev rig untyped | row `heard_within()` ok; live and plan `field_reaches(point)` ok; live `field_rings()` |
| `core_intensity`, `core_radius`, `falloff_power` | 2 in each | inside `FieldSpec`: `emission_at_distance()` ok, `reach_above()` ok, `silent_beyond()` ok |
| `pulse_period`, `intensity_ramp` | 4 and 2 in | the field part's `peak_through()`, `pulses_every()` (the looks' flicker); the live event asks the row's ok, the looks and the spawner still read `pulse_period` |
| `from_outside` | 2 in | the field part's `passes_walls()`, asked by the event's source (the row's ok) and the spawner |
| `barrier_structure` | the manager, untyped | the field part's `counts_as_one_barrier()` ok (the row's and the live event's until the part exists), asked by `EventSources` |
| `hard_fail` | 5 in, 1 out (the route rig), three untyped | row `ends_the_day()` ok, `effect()` ok; live `ends_the_day()` ok, `is_lethal_at()` ok |
| `catch_reach` (and `PursuitSpec.catch_reach`) | the catalogue, `EventDef` | row `lethal_reach()` ok, stored once in `LethalSpec` |
| `detain_seconds` | 6 in, 2 out (the route rig and its planner) | row and plan `detains_her()` ok, live `detains_her()` ok; `detains_for()` ok |
| `detain_radius` | the catalogue | row `detain_distance()` ok |
| `redetains` | the live event and its hold; the resistance and the route rig's planner out | row and live `detains_again()` ok, plan `detains_again()` |
| `pursuit` | 12 in, 3 out (the auto screenshot, the scene recipes, the park cordon) | `pursues()` on all three (the live event's exists); row `chase_speed()` ok, `approach_speed()` ok, `starts_by()` ok, `standoff_reach()` ok, `was_sent_at_her()`; the pursuit behaviour is handed the spec |
| `PursuitSpec`: `speed`, `start`, `warns_for`, `stands`, `walk_speed`, `lunge_reach`, `stop_excitement`, `leaves_its_body`, `warns_over_the_street` | 25 lines, all in (the row, the live event, two behaviours) | methods of the spec of the same names, the yes-or-no ones renamed (`stands_for_its_notice()` ok, `leaves_its_body_standing()`, `is_drawn_over_the_street()` ok); built by `PursuitSpec.at(speed).walking_at(...)` |
| `notice` (`NoticeSpec`: `within`, `quiet`, `runs_within`) | 4 in; 7 lines of the spec, all in | row `waits_for_her()` ok, `notice_within()` ok; the spec's `within()`, `is_quiet()` ok, `runs_within()`; meanwhile the row's `runs_its_own_line()` (a notice that runs its own line) and `warns_quietly()` (no notice, or a quiet one) ok, which the live event asks; `runs_its_own_line()`'s expression is still written out in `EventInstance.counts_a_charge()`, which asks it when the live event's notice section is converted, and in `EventDef.validate()`, with the row written as its parts (4b) |
| `hunts`, `hunting`, `heat_response` (`HuntSpec`: `lets_out`, `pursuit`, `ends_the_day`) | the row itself, `EventsAhead`; 3 lines of the spec | row `answers_to_heat()`, `investigates()` ok, `lets_out()` ok, `at_heat(level)` ok |
| `telegraph_time` | 4 in, 1 out (the readout) | row and live `telegraphs_for()` ok; row `warning_time()` ok, `warned_for()` ok |
| `still_while_telegraphing` | 3 in | the warning part's `holds_still()` (the row's, asked by the live event ok); row `ahead_of_player_lead()` ok |
| `telegraphs` | 2 in | row `telegraphs_its_coming()`, `announces_its_coming(walk_speed)` ok |
| `warned_first`, `offscreen_notice` | 1 in and 1 out (the park cordon); 2 in | row `warns_before_it_exists()` ok, `warned_for()` ok, `was_sent_at_her()`, `as_warned_first()` ok |
| `mobile` | 10 in, 1 out (the route rig) | row `moves()`, `approach_speed()` ok |
| `speed` | 7 in, 2 out (the resistance; the badge, for a warning with nothing in the world yet, which section 7's point 6 makes `approach_speed()`) | row `speed()` |
| `paces` | 4 in, 1 out (the happenings), the resistance untyped | row `paces_a_beat()`; live `beat()` |
| `path_mode`, `path_length_tiles` | 3 and 2 in | the route part's `kind()`, `tiles()`, asked by the plan builder |
| `stops_where_it_arrives` | 3 in, 1 out (the scene recipes) | row `parks_where_it_arrives()`; live `has_parked()` |
| `flock_size`, `flock_spread` | 5 and 4 in | row `is_a_flock()` ok; `EventFlock` is handed `FlockSpec` |
| `look` | 13 in (every look) | row `picture()` ok; each look is handed its `LookSpec` |
| `warning_picture`, `draws_body_shadow`, `trails_a_lead`, `hides_in_its_hold`, `may_be_a_pelican` | 2 or 3 in each (the footprints, the looks, the spawner) | methods of `LookSpec`, asked by the looks, the footprints and the spawner only (meanwhile the row's `casts_a_shadow()`, `drags_a_lead()` and `vanishes_into_its_hold()` ok, asked by the footprints; `warning_picture` still a listed read) |
| `guard_sides` | 2 in, 1 out (`SealPlanner`), `RegionPlanner` writing | `LookSpec.guard_sides()`; a draft for the wall's copies |
| `abduction` (`AbductionSpec`: `taken_over`, `standing_offset`) | 5 in; 5 lines of the spec | the abduction behaviour and the van's look are handed the spec; its two methods; meanwhile, until the look is handed the spec, the van's look reads it off the row it is handed (`_row.abduction`), its two fields under their own names |
| `aftermath` (`Aftermath`: `scar`, `on_finish`, `on_sight`) | 4 in, 2 out (the scene recipes, `SealPlanner`); 10 lines of the spec | row `scar_id()`, `leaves_behind()` (asked by the live event ok), `calls_in()`, `has_an_aftermath()`; a draft's `without_its_aftermath()` |
| `_cost_cache` | private | stays inside `FieldSpec`, worked out when the spec is built |

### 4.2 The live event (`EventInstance`)

| Field | Reader files | Replaced by |
|---|---|---|
| `def` | 29 in, 8 out | the questions of section 2 on the live event; `row()` ok for passing the row on |
| `is_finished` | 12 in, 6 out; 154 reads in tests | `is_gone()` ok (the base look asks it ok) |
| `is_leaving` | 13 in; 133 in tests | `is_on_its_way_out()` ok |
| `is_parked` | 3 in, 1 out (the resistance) | `has_parked()` |
| `phase` | 2 in; 40 in tests | the phase questions (`is_waiting()` ok, `is_telegraphing()` ok, `is_active()`, `has_stopped_her()` ok, `is_only_its_barrier()`); `transition()` reached by its parts through `Figure.begin()` ok; fifteen lines of six suites call `transition()` to put an event in a phase that sets a check up, kept public for them (`tools/test_only_members.txt`), and each goes when its suite reaches the phase the way the game does or is handed a fake event: step 5's `FakeEvent` covers the crowd-yield and resistance suites, and nothing is named yet for `test_scenery_animation` and `test_prediction_reuse` |
| `age` | 7 in, 1 out (the readout); set by rigs and recipes | `age()`; set only by its own tick and by `resume()`, which becomes `restore(save)` in 3b |
| `path` | 7 in | `walks()` ok, `beat()`, `way_left()` ok |
| `_heading`, `_path_travelled`, `_gait_phase`, `_gait_moving` | 8, 4, 1 and 1 in (the behaviours) | `Figure.heading()` ok, `travelled()` ok, `turn_to()` ok, `walk_on()` ok; outside: `facing_now()` ok, `path_travelled()` ok, `gait_phase()` ok |
| `_map`, `_navigator`, `_mover` | 4 in each | handed to each part at setup |
| `_obstruction`, `_spread_vertical` | 2 in each (the barrier post, the car, the far guard) | `EventBody` ok: `drop()` ok, `pin_where_it_stands()` (built as `pin_at(at)`), `runs_vertically()` ok; the barrier post, the far guard and the car reach them through `Figure` ok |
| `_charge` (`ChargeRecord`: `began`, `ended`, `warned`), `_notice` (`Warning`: `length`, `cancel_if`, `on_expired`), `_telegraph_ended`, `_chase_way`, `_guard_spent`, `gave_up` | 1 to 3 in each (four behaviours) | `Figure.charge_began()` ok, `charge_ended()` ok, `hold_the_notice()` ok, `notice_has_run()` ok, the behaviours reach the rest only through `Figure` ok; `has_charged()` ok, `is_chasing()` ok, `has_given_up()` ok (`gave_up` stays public while suites and probes read it) |
| `hold`, `abduction`, `departure`, `route`, `car`, `barrier_post`, `investigation`, `pursuit`, `on_foot`, `notice_run`, `flock`, `unreachable` | 30 lines in (the composer, behaviours reaching siblings, three looks) | private; siblings handed to each other by the composer; outside callers ask the live event (`closes_on(point)` ok, `is_taking_a_victim()` ok, `how_long_its_victim_has_walked()` ok) |
| `excitement` | 4 in | `source()` ok |
| `drawer`, `atlas`, `timing`, `trace`, `signals`, `skip_draw`, `points_at`, `is_pelican` | 1 to 9 in (written by the spawner after it makes the event, read by the looks) | handed in at setup in one call; the looks are handed the drawer; `is_drawn_as_a_pelican()` ok; the unmarked van's take is handed `trace` at setup ok; the car asks `signals` through `Figure.lights()` meanwhile, since the spawner sets them after `setup()`, and `lights()` goes when the one setup call (3b) hands them in |
| `gate_state` | 2 in (two looks) | `is_raised()` ok, `boom_openness()`; handed in at setup from the plan's `gate()` |
| `guard_warns_her` | the looks (the checkpoint controller asks already) | `raise_its_guards_hand(on)` ok, `is_its_guard_warning()` ok; the field is private |
| `silenced` | 2 in; written by streaming | `silence()`, `is_silenced()` ok |
| `came_under_a_warning` | the live event itself | `was_warned_of()` ok |
| `look` | 2 in (two looks reading another's) | private; a look is handed the look it needs; a slice is handed its look ok, the roadblock's band and far guard still read the field |

### 4.3 The plan (`EventScheduler.Planned`, to be `EventPlan`)

Reads by `rg`, since the check does not list it.

| Field | Reads | Replaced by |
|---|---|---|
| `def` | about 100 | `row()` ok for passing it on, `row_id()` ok, and the row's questions answered by the plan where callers ask through it (`pursues()`, `ends_the_day()` ok, `detains_her()` ok, `detains_again()`, `detain_distance()`, `is_a_boom()`, `obstructs_within()` ok, `field_reaches(point)` ok, `stands_as_a_fixed_body()`, `body_pieces()`) |
| `position` | about 80 | `placed_at()` ok, `is_placed()` ok, `distance_from()` ok; `place_at(at)` for the one writer, her walk's siting |
| `path` | 18 | `walks()` ok, `stands_still()` ok, `ends()` ok |
| `facing` | 18 | `faces()`; set as the plan is built |
| `live` | about 60 (streaming, the route rig, the scene recipes, the resistance) | plan `is_in_the_world()` ok, `where_it_stands_now()` ok, `faces_now()`; `EventManager.event_of(plan)` for the live event itself; streaming tells the plan `enter_the_world(node)` and `leave_the_world(save)` |
| `spent` | 18 | `is_spent()` ok, `spend()` ok |
| `mast_id`, `silenced` | 17 and 5 | `is_a_mast()`, `mast_id()`, `stand_as_a_mast(id)`, `is_silenced()`, `silence()`, `is_a_live_mast()` |
| `age`, `travelled`, `noticed_at`, `behaviours` | 7, 3, 4 and 3 | one `EventSave`: `keep(save)`, `saved()`; `arrive_aged(seconds)` ok for a recipe that stages an event part-way through |
| `role` | 6 | `role()`, `give_role()` ok |
| `comes_in`, `wait_began`, `kept_live`, `was_live` | 6, 3, 3 and 5 (streaming) | streaming's own state per plan; `keep_in_the_world()` ok stays as the way to ask for it, and `come_first_in(seconds)` ok, by which the building's plan says when an event first comes, tells streaming rather than writing a field |
| `repeat_every`, `repeat_after`, `at_her`, `arrives_aged` | 5 (streaming) | `repeats()` ok; `come_again_every(seconds)` ok, `come_where_she_stands()` ok, `arrive_aged(seconds)` ok as the building's plan is made; `comes_where_she_stands()`, `arrives_aged()` |
| `gate_state` | 2 | `gate()`, set as the region's doors are made |
| `permanent` | 1 | `is_permanent()` ok, `make_permanent()` |
| `_is_door`, `_in_the_wall`, `_is_a_seal` | private already | as they are |

Other classes of the folder with listed lines, each converted in the pull request that owns its
file: `EventWorld` (55 lines, the context the event manager hands its own parts), `EventManager`
(8, read by the city scene and waiting on the third hand-ins pull request), `ChargeRecord` (7),
`PendingWarning` (6), `RoadblockFarGuard` (4), `EventStreaming` (3), `Warning` (3),
`EventBarrierPost`, `EventsAhead` (2 each), `EventPursuit`, `EventFlock`,
`EncounterWatch`, `EventSpawner` (1 each).

## 5. The pull requests, in order

The order follows from one constraint the player has set: no getter or forwarder is kept under a
field's old name so that old readers go on working ("Don't let legacy implementations prevent you
from establishing a clean design", minty-dolphin #852). So a field can go private only when its
last reader asks a method, and the row's parts, which make every field private at once, land after
the readers. The interface is in use from the first pull request; the parts arrive behind it
without a caller changing, which is the swap the player's rule is for.

Two things come from other tracks and are not this design's: the Tools track's change that makes
the field-read check see every read (`field-reads.md`: untyped access as an error, a file-level
ignore per file not yet converted), and the scheduler breakup's scripted rename of the plan record
to `EventPlan`. Every pull request below types the receivers in the files it owns, deletes those
files' ignore lines and their lines in `tools/field_reads.txt`, answers the architecture
questions, and is at test parity with the run log and GoatCounter's names unchanged.

| # | What | Files it owns | When |
|---|---|---|---|
| **1** | **Two reads left of the callers outside the events folder**, which otherwise ask the event (the record minty-quail-rosy-lynx). A method and a variable cannot share a name, so the plan's `role`, read by the run log's map, becomes `role()` when the plan's fields go private in 3a. The row's `speed`, read where a badge is made for a warning with nothing in the world yet, is the fourth of the slightly wrong answers (section 7, point 6): the pull request that makes it `approach_speed()` removes the read | `src/telemetry/telemetry_map.gd` (in 3a); `src/ui/danger_edge.gd` (in point 6's pull request for it) | With 3a; after this row's first step has merged |
| **2a** | **The live event's behaviours ask it through `Figure`, and are handed the rest.** `EventBody` taken out of `EventInstance` ok; the composer hands each behaviour its settings, the map, the navigator and its siblings ok; the eight existing specs get their methods as far as a converted reader asks them ok. Built (the records minty-quail-velvet-owl, -olive-finch, -tiny-alpaca, -tawny-swan, -striped-hawk, -striped-magpie and -silver-marmot). Left to later rows: the traffic lights, the gate's state and `_spread_is_vertical()`, handed in by the one setup call (3b); the specs' remaining methods, with the steps that convert their readers | `src/events/event_instance.gd`, `behaviours/*` (all ask through `Figure` ok), `event_excitement.gd`, `charge_record.gd`, `warning.gd`, the eight spec files (methods added) | **Now, beside placement**, after 1 (both add to `event_instance.gd`). The third hand-ins pull request, which rewrites the manager's setup, meets `WhereSheIs` there: the events' world holds it and `EventSpawner.create()` hands it to each live event |
| **2b** | **The looks ask the live event and are handed their settings.** | `src/events/views/*`, `event_footprints.gd`, `event_scenery.gd` (handed its atlas and its drawer ok) | **Now**, beside 2a once `Figure` and the outward questions are in |
| **3a** | **The dawn and the walk's ground ask rows and plans.** The plan's fields go private. Small where placement wrote against section 3 | `event_plan.gd`, `event_scheduler.gd` and what the breakup made of it (`dawn_phases/`, `plan_builder.gd`, `row_ground.gd`, `dawn_context.gd`), `street_rules/*`, `street_invalidation.gd`, the location files, `view_bag.gd`, `walk_ground.gd`, `day_events.gd`, `walk_events.gd`, `day_reach.gd`, `mast_sites.gd`, `day_planner.gd`, `src/routes/seal_planner.gd`, `region_planner.gd` | After placement and the scheduler's breakup close |
| **3b** | **The event manager's parts.** Streaming keeps its own state per plan, tells the plan what happened and carries a live event's state out and back as one `EventSave`; the spawner hands a live event everything in one setup call; `EventWorld`'s 55 lines | `event_manager.gd`, `event_world.gd`, `event_streaming.gd`, `event_spawner.gd`, `event_director.gd`, `events_ahead.gd`, `warning_board.gd`, `pending_warning.gd` | After placement (its step 4 rewrites the director's and `EventsAhead`'s siting) and the third hand-ins pull request. Beside 3a and 3c |
| **3c** | **The resistance, the scene recipes and the rigs.** | `src/resistance/*`, `src/dev/*`, `src/city/city.gd` | After placement's bullet on the scene recipes and the third hand-ins pull request. Beside 3a and 3b |
| **4a** | **The tests, the probes and the cost table read through the methods.** One scripted rewrite, each replacement a line of section 4's tables, the script in the description so a branch merging main reruns it. No line under `src/` changes | `tests/**`, `tools/cost_table.gd` | After 3a to 3c |
| **4b** | **A row is written as its parts.** `EventDraft`, the eight new specs, the row with no public field and no `Resource` base, the catalogue rewritten row by row, every variant made from a draft, `validate()` without the pairings a part makes unwritable; the tests that build or change a row use a draft. `docs/EVENTS.md`'s "Adding a new event" and the events skill's "Adding a row" say the new form | `event_def.gd`, `event_catalogue.gd`, `event_draft.gd` and the spec files, the variant sites in `seal_planner.gd`, `region_planner.gd`, `happenings.gd`, `event_director.gd`, `event_spawner.gd`; the tests that write a row | After 4a |
| **5** | **The events' and the resistance's suites test one module each** (`tests-one-module.md`, entry 7), in the groups below | `tests/**` | After 4b; its groups beside each other |

**What runs beside the placement track and the scheduler's breakup**: 1, 2a and 2b. They own no
file either of those owns; 1 and 2a add methods to `event_def.gd`, where placement has been
adding its own, and such additions merge without a conflict of meaning. Everything from 3a on
waits, because it converts the files those two tracks are rewriting.

**A live half before its spec exists.** Until 4b the body, the field, the hold, the route and the
flock have no spec of their own, so in 2a their live halves are handed the row and ask the row;
4b hands each its spec, one constructor line apiece. The eight specs that exist are handed over
from 2a on. The field's live half is so handed: the event's source takes the row and where she is
at setup (`use_row_and_where_she_is()`), ok. So is the look's: `EventLooks.for_row()` hands the base
look its row and its drawer at setup, ok, until `LookSpec` (4b).

**Skills and docs.** 4b rewrites the events skill's "Adding a row" and its field names, and
designing-classes' sentence that much of `src/` still reads fields goes with the last line of the
list; the report to the player names each skill change (woolly-finch 24).

**Parity for 4b**, beyond the suites: `tools/cost-table.sh --check` (the cost table worked out
from the rows is unchanged), `tests/probes/placement_rows.gd` and
`tests/probes/excitement_fingerprint.gd` identical before and after, and
`uv run python tools/ci_telemetry_kinds.py`. After 4b `tools/field_reads.txt` holds no group for
the row, the plan, the live event or a spec, and `baseline-measurements.md` takes its reading
"after the events' field-read conversion".

**How the suites are converted (5).** The interface is what a mock mirrors, so the mocks are
written once, after it is final.

- **What is mocked and what is built as it is.** A row and a plan are plain values and are built
  as they are (a draft, `EventPlan.new(row, at)`), as writing-tests says of plain data. The live
  event and the event manager do things, so a suite that is not about them hands in a fake.
- **`FakeEvent`** (`tests/fake_event.gd`, extending `EventInstance` as the existing fakes extend
  their class): every outward question of section 2 overridden to answer what the test set, and
  nothing otherwise. Each override carries its `## Overrides EventInstance.<method>.` line, so
  `tools/check_overrides.py` fails the fake the moment a question is renamed or removed: the mock
  cannot drift from the interface. It is a node, so a test frees it. `FakeEventManager` (it
  exists) hands out fakes and plain plans through `instances()`, `plans()` and `event_of()`.
- **Each fake's answers are read off the real event in the same situation first** (the two steps
  of writing-tests), and only the mock is committed.
- **The groups**, each its own pull request with the suites' times before and after:
  the row (`test_events_catalogue`, `_costs`, `_emission`, `_solid`, `test_acts`: real rows, no
  node, and only relationships between settings asserted); the live event and its parts
  (`test_event_phase`, `test_event_behaviours`, `test_events_pursuit`, `test_car_driving`,
  `test_police_car`, `test_fire_truck_body`, `test_car_front`, `test_protest`,
  `test_events_chat`, the drawing suites: one real live event on open ground or a hand-drawn map,
  a `WhereSheIs` the test moves, a fake navigator where a wall matters); the event manager and its
  parts (`test_event_manager*`, `test_event_parts`, `test_events_fire`: the manager real, plans
  plain, a real city only in the suite whose header gives the reason); the dawn
  (`test_events_scheduler`, `_placement`, `test_event_spacing`, the day 6, 7 and 13 suites: rows
  and plans plain, through the breakup's one helper that builds a `DawnContext`); the event halves
  held in other modules' suites, which move to the event suites or take a `FakeEvent`
  (`test_danger`'s twenty or so, `test_crowd_yields`' four checks, `test_wall_shield`,
  `test_heat`, `test_masts`, `test_crowd_bodies_on_a_real_day`'s one); and the resistance
  (`resistance_*`, `spent_park`, `park_cordon`, `burnt_door`: `FakeEventManager` and
  `FakeEvent`).

## 6. What it costs per frame

A field read that becomes a method call costs a call. Where the calls would be many, the design
does not turn each read into a call; it asks one question whose answer is the whole computation,
or hands the value in once. The paths that run every tick or every drawn frame:

| Path | What reads events there today | How it stays cheap |
|---|---|---|
| **The events' physics step** (`EventManager._physics_process()`, each live event's `step()` and its behaviours) | the behaviours read their event's heading, distance travelled, her position and their row's settings: the car's driving alone reads its event's and its row's fields 97 times | settings, the map, the navigator and siblings are handed in at setup and held as members, so reading them is reading a member; `WhereSheIs` is asked once a tick per behaviour; only what changes goes through `Figure` ok, but for the traffic lights, which the car asks through `Figure.lights()` until the one setup call (3b) hands them in |
| **Streaming** (`EventStreaming.stream_around()`, every plan of the day, every tick) | five plan fields per plan | streaming's own state per plan in its own members, and one `distance_from(at)` per plan that is neither spent nor waiting. It is the loop with the most turns in the events' tick, so the first place to look if the step's time moves |
| **The baby's sweep** (`Baby._physics_process()`, through `EventSources.sources_at()` to each source's `contribution_at()`) | a far event: five row fields to work out the distance beyond which it is silent, on every call; a near one: about eight row fields in `current_intensity()`, then `emission_at_distance()` | the silent distance is worked out once when the `FieldSpec` is built, since a built row cannot change (today it is worked out on every call because a rig may change the row); the ramp and the pulse are one question to the field (to the row, until the field part exists, ok); the kernel is the method it is today |
| **The danger prediction** (the caret: `ExcitementSource.expected_gross_at()`, twenty samples a source a drawn frame, behind a cache) | the cache's key copies nine values of the row and its shape every frame, to notice a row that was changed | the key holds the field's spec and the shape by reference; the samples call the same two methods as today. Fewer reads than now |
| **The fields layer** (the debug view's overlay, `DebugLayers._draw_fields()`) | three row fields and the shape per live event per redraw | one `field_rings()` |
| **Drawing** (each visible event's look, every drawn frame) | `def.look` sixteen times in `event_look.gd`, the shape, the body's width | the look holds its `LookSpec` and the width from construction (the base look holds its row ok, until `LookSpec`); the mark's question (`walk_through_cost()`) is cached in the field's spec |
| **The crowd's tick** | no event field: the published moves, the blocked tiles, a boom's state | nothing changes; measured as the control |

**How big it can be.** The events skill's own figure is a few dozen live events at once, on the
last day. The crowd's lane strategies, converted the same way for hundreds of agents reading their
mover about 330 times each a tick, measured +6.7% and +8.8% of the crowd's tick in a debug build
with every position identical (the record brisk-lark).

**What is measured**, before and after 2a and 2b and again after 4b, main and the branch side by
side in two worktrees at the same time, the totals over a probe's configurations compared (one
configuration alone moves between rounds, as that record found):

- `tools/test.sh probes/m159_tick_sweep_events_cost.gd`: the baby's sweep and the events' physics
  step per tick, on fixed seeds and days.
- `tools/test.sh probes/excitement_fingerprint.gd`: what every source charges her, tick by tick.
  Its `XF` lines are identical or the step is not done; its `XF_COST` line is the halo's frame.
- `tools/test.sh probes/calm_pelican_fields_layer_cost.gd`: the fields layer.
- `tools/test.sh probes/m159_crowd_tick_cost.gd`: the control; its chain over every agent's
  position is identical.
- `tools/test.sh probes/look_fingerprint.gd`: what every row's look draws, the catalogue's rows,
  their full-heat and last-day copies and the rows the game stands from them; its `LK` lines are
  identical or a step of 2b is not done. It cannot see what a look draws straight on the canvas,
  nor a term of a look's picture key taken out alone (the record minty-quail-polite-newt).

**The bar.** The design's: in a step that changes no behaviour, the fingerprint and the chain are
identical, always, and in a step of 2b the looks' `LK` lines too. On the times, the player's answer (section 7, point 5) is read as: they are
measured and reported in the pull request and listed for the end remeasure, and no step is held or
tuned for them.

## 7. Open points

### Answered by the player's recorded words

1. **Does a caller ask the event or one of its parts?** Outside the events folder, the event:
   "provide a consistent interface for events that can be used without knowing details of the
   event" (inbox #1173 in gray-dolphin, statement 16). Which parts a row has is such a detail.
   *Read as* (the design's): inside the folder, the code that runs one ability is handed its part
   and asks it. The words it rests on are the assistant's, in the context the player answered
   "yes" to: the parts "each answering its own questions" (the same note, statement 22's context).
2. **A method or a property?** A method across objects, a property only inside its own class:
   "yes" to that pick (inbox #1173 in gray-dolphin, statement 28).
3. **Are the live event's own behaviours and looks bound by the rule?** Yes: "interaction between
   different objects need to go through APIs" (inbox #1173 in gray-dolphin, statement 23). The
   shape, a narrow interface built by the owner with what never changes handed in, is the record
   brisk-lark's, which is the orchestrator's reading there and open to the player's overturn here
   as well. Folding the behaviours into `event_instance.gd` as inner classes would escape the rule
   and is rejected for the reason that record gives.
4. **May a getter stay under a field's old name, so the parts could land first?** No: "Don't let
   legacy implementations prevent you from establishing a clean design" (minty-dolphin #852).
   Hence readers first and parts last (section 5).
5. **Do the tests read through the methods too?** "yes" (inbox #1182 in gray-dolphin).
6. **Is `display_name` deleted, with `Texts.EVENT_NAMES`, the table of the rows' names it is
   read from?** *Read as* (the design's) under the player's standing rule on dead code, which
   `dead-code-sweep.md` carries for the rest of the tree. Nothing in `src/`, `tests/` or `tools/` reads the field; the table's comment says it is
   what "a day summary or a codex would call the thing", and neither shows a name. "remove dead
   code or code needed for features that don't exist anymore ... if we want a feature back we can
   just implement it fresh" (inbox #1180 in gray-dolphin). It is deleted in 4b, and that pull
   request's record keeps the names, since they are written text.
### Answered by the player on the board

Six points the design put as questions, each with the player's answer (inbox #1278 in olive-ferret, which holds
each question as it was shown).

1. **Where do the settings files live?** Offered a new folder `src/events/parts/` for the
   seventeen small files, with the full split of the events folder by layer after placement closes
   (a), or the whole folder split by layer now (b): "a".
2. **Does a car's strike become the row's lethal part?** Offered `ends_the_day()` keeping its
   meaning, a place that ends the day, with the strike staying its driving's (a), or one part for
   everything that can end her day (b): "a".
3. **How does a caller get a plan's live event?** Offered the plan answering what callers want of
   it (`is_in_the_world()`, `where_it_stands_now()`, `faces_now()`) with the event manager handing
   out the live event (`event_of(plan)`) to the few that command it (a), or the plan handing out
   its live event, at the price of a listed layer break (b): "a".
4. **Are the tests touched twice?** Offered a script that rewrites their reads first, with the
   suites converted to one module each later (a), or each test file opened once, the row's parts
   waiting behind every suite (b): "a".
5. **Is the cost per frame acceptable?** Offered a rise measured, reported and listed, with a
   builder sent back to the loop above about a twentieth of the events' step (a), or no rise
   accepted (b): "get the clean design first no matter the cost. We can optimize back down later.
   We have the numbers to know where to look". **Read as:** neither bar. Every step measures the
   events' step and the baby's sweep with the probes of section 6 and reports the numbers in its
   pull request, so that there are numbers to look at later; no step is held, tuned or sent back for
   its cost.
6. **Does a step fix an answer that is slightly wrong today?** Offered keeping the three answers
   the board named (the first three below) and listing them for the end remeasure (a), or (b), in
   the board's words, "fix each in the step that names it, as a change made on purpose with
   pictures": "the shape change is desired. as I said earlier the main real measure will be
   playtests. This will tell us what needs fixing. Let's not obsess over theoretical numbers. We
   currently have no established base anymore since we changed a lot. Playtest will decide which
   deviations need to be fixed". Read back on the board as "I read this as b, not a: each of the
   three is made right, the field's real shape first, and nothing is kept wrong to hold old
   numbers. Each is its own small pull request after the step that names it, saying what it
   changes, and playtests decide what then needs fixing. Tell me if you meant only the field's
   shape.": "whatever is the *correct* implementation. if that is b then let's do that" (inbox
   #1278 in olive-ferret). **Read as:** every answer below is made correct. The timing is the
   read-back's, which is what the player answered: each is a pull request of its own after the step
   that gives it a name, not a change inside that step, saying what it changes in play and in the
   run log, with its pictures. Playtests decide what then needs fixing. The fourth answer below was
   found in review after the player answered, and the last three in building where she is as one
   object; *read as* (the orchestrator's, open to the player's correction) covered by the same
   words.
   - `field_reaches(point)` compares the distance to the event's centre with its outer radius, as
     its five callers do, though the field of a row with a long body is a capsule about that body.
     Answering with the real field changes when the run log says "out of range" and when the
     unmarked van stops its take.
   - `blocking_radius()` shuts a lethal row's field core, not its lethal reach (section 3).
   - The ground a row that ends the day shuts is stated four ways (`clearance()`,
     `blocking_radius()`, the scheduler's clearance round where she starts, the walk ground's
     lethal disc less her radius). *Read as* (the filer's, open to the player's correction):
     made correct means they become one stated fact, asked under one name.
   - A badge for a warning with nothing in the world yet is made with the row's plain `speed`,
     which a pursuer warned of first does not set: the run log says the day-3 charging dog's badge
     is "closing 0px/s" while the dog comes at its chase speed. The badge asks the row's
     `approach_speed()` as a badge for a live event does.
   - A car made after the tick's word knows nothing of her in its first frame, so it puts its
     body down at once even where she stands, though the comment at that place promises it holds
     the body back round her.
   - An officer let out of a car is told her position and none of the other five facts (her
     pram's place, the view, whether she runs, whether the baby is awake, whether a door holds
     her) until the next tick's word.
   - The halo's word once a drawn frame reaches only the events it lights; every other live event
     keeps the tick's word.
