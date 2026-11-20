# Every read of another object's fields goes through its methods

**The ask.** On the board's events-one-interface, asked whether "all aspects of events" means a pass
of its own over every place that still reads an event's details: "yes. also never read fields
directly. always read through a method (does gd support python style properties?) so you can swap
out a field with a computation if needed. fields are not API interaction between different objects
need to go through APIs" (inbox #1173 in gray-dolphin). On api-methods-or-properties, "yes" to methods across
objects and a property only inside its own class (inbox #1173 in gray-dolphin).

**Read as:** the rule is designing-classes' ("Fields are not API", "An event is asked through one
consistent interface"). This item is the survey and the conversion of the code that predates it,
events first: outside `src/events/`, 20 files under `src/` read an event definition's settings
directly (its body's width, whether it holds her again, how long, whether it ends the day), and many
more classes read each other's fields. An event's abilities (a body, a hold on her, a lethal field, a
pursuit) become parts it has, each answering its own questions, rather than subclasses or settings
read from outside: composition over inheritance, the half of events-one-interface's context the
player's "yes" accepted with the rest (inbox #1173 in gray-dolphin). It comes after the hand-ins (`city-hand-ins.md`), which move
many of the same reads.

**The events' design is `event-interface.md`**: the parts, the questions callers ask, what replaces
each read, and its pull requests in order, the first of which run beside the placement track.

**Decided on the board** (inbox #1182 in gray-dolphin):

- **tests-read-fields, "yes":** a test counts as another object, so it too reads its subject through
  methods (`tests-one-module.md`).
- **field-read-check, "yes":** a script fails a change that adds a read of another class's plain
  field under `src/`, with today's reads listed once in a list that only shrinks. It is
  `tools/check_field_reads.py`, with the list in `tools/field_reads.txt`, run in CI's `gates` job.
  Asked on the board whether the list may gain the lines of a read that only moved (into a new
  file, or with a class lifted out of another), the player answered "A", that it may
  (inbox #1350 in grassy-trout). Which moves count is the planning agent's proposal, written in the record
  minty-quail-breezy-bison.

**Every receiver gets a class the check can tell** (inbox #1268 in olive-ferret). Shown "The field-read check
skips about two thirds of reads because it cannot tell the receiver's class", the player: "isn't
that the point of a class hierarchy? it should be made working". **What is left of it** is the
typing itself: the files that carry the opt-out line (godot's "Types" gives its one form) are a
second list that only shrinks (`tools/check_field_reads.py --summary` counts them by folder and by
warning). A file is typed either inside its area's conversion below or ahead of it, by a pass that
types its receivers, deletes its line and converts no read. **The check fails a read it newly sees
once a file is typed**: `tools/field_reads.txt` only shrinks (inbox #1182 in gray-dolphin), and the
one growth the player allowed is a read that moved (inbox #1350 in grassy-trout). **A read that
typing a file reveals is not added to the list either**: asked whether it may be, the player chose
"B", the typing pass converting such a read or leaving the file untyped, and added "why would it
leave the file untyped? it should get picked up eventually if not immediately" (inbox #1429 in
minty-rabbit). *Read as:* a typing pass that meets such a read converts it, widening its search to
that read's class, as for the animated water (`SceneryWater`, the record
2026-10-18-minty-quail-sandy-hedgehog) and the excitement source (`ExcitementSource`, the record
2026-10-18-minty-quail-tawny-toad); where it cannot, the file keeps its opt-out line, a list that
only shrinks, and its area's conversion or a later typing pass types it and converts the read.
Every file under `tests/` is typed but the two that wait for polite-tapir's placement step 4
(`typed-everywhere.md`); the suites' conversion (`tests-one-module.md`) is still to come. The two
scripts under `tools/` that carry it (`tools/cost_table.gd`, `tools/split-scenes-crop.gd`) are typed by the pull
request that next changes each, or with the suites' conversion if none does first. The engine warns of nothing on a property read off a value it types as
Variant (an untyped array's element, what `back()` or `get()` returns), so such a value is read
through a typed name, and the check, not the engine, is what holds that. This paragraph is the
design review's (inbox #1268 in olive-ferret), and its mechanism is built: `project.godot` makes the
three typing warnings (`untyped_declaration`, `unsafe_property_access`, `unsafe_method_access`)
errors. What remains is this item's own conversion, which predates the review, so the item stays in
minty-quail rather than polite-tapir.

**What is left of the typing under `src/`** (`rg -l '@warning_ignore_start' src` lists the files)
is the files open work rewrites, typed by that work or after it, and two kept for a reason of their
own:

- The event scheduler, the walk's ground and the event director (`src/events/event_scheduler.gd`,
  `walk_ground.gd`, `event_director.gd`), which the placement rewrite
  rewrites, then rows 3a and 3b of `event-interface.md`; and the event manager (`event_manager.gd`),
  row 3b's.
- The city scene (`src/city/city.gd`), row 3c's.
- The scene recipes' draft and runtime (`src/dev/scene_recipe_draft.gd`, `scene_recipe_runtime.gd`),
  row 3c's.
- **The run log's observer** (`src/telemetry/telemetry_observer.gd`, the record
  2026-10-18-minty-quail-woolly-marten) keeps `unsafe_property_access` for one read, the event
  manager's `sources` in its breakdown of where the excitement comes from (`_meters()`), which waits
  for the event manager's parts (row 3b of `event-interface.md`).
- **The event bus** (`src/autoload/event_bus.gd`) keeps `untyped_declaration` for its six signals
  that carry a live event untyped, row 3b's choice (`event-interface.md`, "What the bus carries
  about an event"): typed `Node2D`, or the line kept with its reason.

**What is left: the conversion**, one pull request per area, each deleting the lines it converts
from `tools/field_reads.txt` (its `# [Class] path` groups say which class's fields are read and
from where; `--summary` prints the counts and the classes read most). The event definition's
fields are the most read, so the events go first, as the ask says.

Left, each its own design question:

- **The city's own classes** still have readers under `src/`, which `tools/field_reads.txt` lists
  by class: the city map's (`CityMap`) in the events, whose fields (`network`, `main_road`, `block_plans`,
  `calm_blocks`, `closed_tiles`, `power_station`, `boundary_wall_at_a`, `square_rects`, `playgrounds`)
  stay public until the events' pass, and in the scene recipes' draft and runtime (`stretch`,
  `stretch_active`, `tiles`, `recipe_bounds`), whose tests set what no game method sets. `RoadClosure.segment` stays public for one reader,
  the day planner's holds (`src/events/day_planner.gd`), which go with the events' interface
  (`event-interface.md`); every other reader asks `street_key()`, `street_words()`, `mouth_rects()`
  or `covers_tile()`, and the suites' and the probes' reads of `closure.segment` go with
  that read. Two groups have a home of their own:
  - The authored-scene builder reads the map through methods, and its recipe-side reads of a step and
    a closure's segment go through `BlockPlan.Step`'s and `RoadClosure`'s methods. It is no longer a
    `CityMap` reader, and `block_layouts`, `building_rects` and ten more of the map's fields are
    private.
  - A field only a test still reads outside its own class and the code that writes it
    (`CityMap.home_rect`, `courtyard_rects`,
    `Building.scenery_clock`, `door_world_x_range`, `powered`, `day`, `roof_extension_rows`,
    `tint_variant`, `poster_art`, `atlas`, `footprint`, `roof_object_parent`,
    `SceneryResidency.frame_locked`, `Crowd.view`, `timing`, `atlas`, `skip_motion`,
    `skip_agent_drawing`, `ClosureMarker.piece`, `kind`, `across`, `ParkFenceMarker.sign_offset`,
    `StillWatch.trace`, `TouchControls.rotated`) keeps its direct write in the game (the city, the
    city scene, the blackout, the poster walls, the roof previews, the simulation builder, `main`) and goes with the
    tests-one-module item (`tests-one-module.md`), when its tests read through a method the game
    also calls. `LaneMover.kind` goes with the same item for another reason: the game reads it
    outside the crowd only through `is_car()`, and sets it only in an agent's own setup, while
    suites set it on the agents they build by hand (its setter installs the car or walker rules),
    so a public writer would be called by tests alone.
- **The day spec's event readers.** The day spec (`DaySpec`) keeps `number`, `closes_streets`,
  `world`, `holds_the_home_streets`, `keeps_the_walk_open`, `keeps_unused_calm_clear`,
  `one_notice_at_a_time`, `owes_a_return` and `poster_pursuits` public for the events' reads (the
  day planner, the event manager, the dawn's context, the calm kept clean), which go with the
  events' interface (`event-interface.md`); every reader under `src/` outside the events asks its
  methods, and the first four already have one (`day_number()`, `closes_the_streets()`,
  `world_kind()`, `keeps_the_home_streets_clear()`). The suites' reads of `number`,
  `holds_the_home_streets`, `keeps_the_walk_open` and `poster_pursuits`, and their two writes
  (`tests/test_dawn_context.gd` sets `holds_the_home_streets` on a bare spec, `tests/finale_rig.gd`
  sets `owes_a_return`), go with that pass, which gives them another way to build their spec.
- **The world map's residue.** The world map (`WorldMap`, `src/world/world_map.gd`) still has fields
  read from outside its file: `separation`, `moves`, `obstructed_tiles`, `day_record_version`,
  `obstruction_version` and `size`, read by the crowd, the chase's way (`chase_way`), the resistance
  director and the rigs. *Read as* (the orchestrator's reading): they are converted with whatever
  pass gives the blocked tiles an owner of their own. The fields the events read of
  `MoveProposal` (`to`, `radius`, `parked`, `open`, `stood_round`), `GroundShape` (`kind`,
  `half_length`, `radius`, `half_extents`), `Stroller` (`carrying`, `facing`, `outright_moves`) and
  `VisibleView` (`view`, `controls`) stay public and go private with the events' interface
  (`event-interface.md`); every reader under `src/` outside the events asks their methods.
  `MoveProposal.yields` and `on_the_list`, which nothing outside its file reads (callers ask
  `gives_way()` and `is_on_the_list()`), and `Stroller.atlas` (below) are public too.
- **Her part and the badge's that only tests read.** `Stroller.atlas` and `DangerEdge.atlas` (the
  screen-edge badge) are handed in through `use_atlas()` and read by their own files and
  `tests/test_atlas_boot.gd`, which finds every node holding an atlas by the field's name (`"atlas" in
  node`, `node.get("atlas")`), so renaming either would make that walk skip it with no failure; the
  badge acquires no page, so no count of what it asked can stand in. Both become underscore-private with the tests-one-module item (`tests-one-module.md`), when
  that suite reads through a method the game also calls.
- **The lines other work touches** are converted with that work:
  - `src/events/`, what the placement rewrite left (closed, polite-tapir's record
    polite-tapir-feathery-kestrel) going with the events' own conversion;
  - `main.gd`'s reads of the city's own fields (its map, its navigator and the eight settings it
    hands the city), which go with the city scene's pass (`city-hand-ins.md`); `day_director.gd`'s
    reads of other classes' fields wait for those classes' passes;
  - the readers already handed their parts in place of the city (the records
    2026-10-18-minty-quail-crisp-otter, 2026-10-18-minty-quail-calm-wombat and
    2026-10-18-minty-quail-plush-chipmunk), whose reads of an event wait for the events' interface
    (`event-interface.md`): the day planner's reads of a plan and its row with row 3a; the event
    manager's and `EventWorld`'s with row 3b; and with row 3c the developer's rigs' (the still
    watch, the debug readout, the developer's rig, the route rig and its planner). Their reads of
    other classes' fields wait for those classes' passes, as their typing records list them;
  - the region and seal planners' (`src/routes/`) reads of a plan and its row, with row 3a, which
    names both files;
  - the scene recipes' (`scene_recipe*`) reads of the map, with the tests-one-module item or the
    scene recipes' own pass with `AuthoredScene` (`city-hand-ins.md`), since their tests set what no
    game method sets, and their one read of an event, a row's `id`, with row 4b of `event-interface.md`.

  The fields they read become underscore-private behind a method, which takes the field's name unless the field is a
  yes-or-no one (designing-classes, "Fields are not API").
  Each such pull request's description shows a search for the field's old name read without
  parentheses, across `src/`, `tests/` and `tools/`, listing every remaining hit with its reason (another class's field of the same name, a write, a read inside the class's own file, a comment), only a read of this class's field from outside its file failing the step (inbox #1385 in silver-tapir).
