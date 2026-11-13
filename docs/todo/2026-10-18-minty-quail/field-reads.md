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
is the files open work rewrites, typed by that work or after it, and three kept for a reason of their
own:

- The event scheduler, the walk's ground and the event director (`src/events/event_scheduler.gd`,
  `walk_ground.gd`, `event_director.gd`), which the placement rewrite and the scheduler's breakup
  rewrite, then rows 3a and 3b of `event-interface.md`; and the event manager (`event_manager.gd`),
  row 3b's.
- `src/main.gd` and the city scene (`src/city/city.gd`), which the third hand-ins pull request and
  who builds the event manager and the crowd rewrite (`city-hand-ins.md`), the city scene then row
  3c.
- The scene recipes' draft and runtime (`src/dev/scene_recipe_draft.gd`, `scene_recipe_runtime.gd`),
  row 3c's, and the map's capture and restore (`src/city/recipe_city_context.gd`), the design "The
  city's own classes" names below.
- **The screen-edge badge** (`src/ui/danger_edge.gd`, the record 2026-10-18-minty-quail-tawny-toad)
  holds its event source as a `Node` and asks it with `has_method()`, since three stand-ins for it
  extend a bare `Node`: `_Source` in `tests/test_badge_model.gd` and `tests/test_visible_view.gd`, and
  `Source` in `tests/probes/m226_arrival_timing.gd`. It waits for those suites' conversion to public
  seams (`tests-public-seams.md`), when the stand-ins extend `EventManager` and the badge's fallback
  to a view of its own goes.
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

- **A run's parts.** `RunState` hands out `header`, `calendar`, `resistance`, `attempt_spend`,
  `posters` and `facts`, and a read through one is two field reads (`RunHeader`, `RunCalendar`,
  `ResistanceRunState`, `RunFacts`, `SettledState`): the parts reached through methods and each
  part's fields behind methods; the vars are renamed, and the files the third hand-ins pull
  request touches and the tests read them, so it waits for that pull request.
- **The city's own classes** still have readers under `src/`, which `tools/field_reads.txt` lists
  by class: the city map's (`CityMap`) in the routes (the region and seal planners), the blackout, the streamed ground and the city's generator, besides the
  events', the run flow's and the rigs'; a building's (`Building`) in the city scene, the city's fronts, the poster walls, the blackout, the roof
  previews and the scene recipes. Two groups have a home of their own:
  - The authored-scene builder (`RecipeCityBuilder`) is the scene recipes' city. The scene recipes are placed by
    location (polite-tapir's `placement-by-construction.md`, "What is built"), so it waits for nothing there; its
    reads of the map are what is left, now that the map captures and restores itself (`CityMap.capture()`,
    `CityMap.restored()`). The map's recipe side (`RecipeCityContext`) still reads a block plan's steps
    (`BlockPlan.Step`), an inner class the check does not see.
  - A field only a test still reads outside its own class and the code that writes it
    (`CityMap.home_rect`, `courtyard_rects`,
    `Building.scenery_clock`, `door_world_x_range`, `station_door_col`, `station_yard_cols`,
    `BuildingShadows.streamed`, `falls_on`) keeps its direct write in the city and goes with the
    tests-one-module item (`tests-one-module.md`), when its tests read through a method the game
    also calls. `CityMap.home_block`, `Building.power_station` and `PosterState.pasted_through` are
    not in this group, since game code reads them outside their class, and they are converted with
    those readers: `home_block` by the day planner and the scene recipe runtime; `power_station` by the city scene's `assign_roof_extensions()`, which skips the
    station's yard columns when it extends a roof; `pasted_through` by the poster walls, which read
    and write it.
- **Her part that only tests read.** `Stroller.atlas` is handed in through `use_atlas()` and read by
  its own file and `tests/test_atlas_boot.gd`, which finds every node holding an atlas by the field's
  name (`"atlas" in node`, `node.get("atlas")`), so renaming it would make that walk skip her with no
  failure. It becomes underscore-private with the tests-one-module item (`tests-one-module.md`), when
  that suite reads through a method the game also calls.
- **A public field with no reader under `src/` outside its own class.**
  `SpreadLook.Slice.index` is read only by the look probe, by string (`canvas.get(&"index")` in
  `tests/probes/look_fingerprint.gd`), which row 4a's scripted rewrite of `event-interface.md` would
  not find; it goes private when the probe asks `SpreadLook.slices()` for a slice's place, with the
  probe's `LK` hash shown unchanged and a released slice not yet freed taken care of.
- **The flock's look reads a bird's fields.** `_draw_birds()` in `src/events/views/flock_look.gd`
  reads `at`, `lift`, `heading` and `phase` off `EventFlock.Bird`, an inner class
  `tools/check_field_reads.py` does not see, and four suites read the same fields. `Bird` gets its
  methods and those suites ask them in one pull request, since row 4a of `event-interface.md`
  changes no line under `src/`.
- **The lines the placement rewrite, the third hand-ins pull request and the events' interface
  touch** are converted after those land:
  - `src/events/`, which the placement rewrite rewrites (polite-tapir's `placement-by-construction.md`);
  - `day_director.gd` and `main.gd`, the third hand-ins pull request's smaller cases still left, and
    the reads of the city's event manager and crowd, which wait for who builds them
    (`city-hand-ins.md`); `run_session.gd`'s reads of `City.map`, `City.crowd` and `Crowd.sources`
    wait with them, for the city's and the crowd's passes (the record
    2026-10-18-minty-quail-dappled-chipmunk);
  - the readers already handed their parts in place of the city (the records
    2026-10-18-minty-quail-crisp-otter, 2026-10-18-minty-quail-calm-wombat and
    2026-10-18-minty-quail-plush-chipmunk), whose reads of an event wait for the events' interface
    (`event-interface.md`): the day planner's reads of a plan and its row with row 3a; the event
    manager's and `EventWorld`'s with row 3b; and with row 3c the developer's rigs' (the still
    watch, the debug readout, the developer's rig, the route rig and its planner). Their reads of
    other classes' fields wait for those classes' passes, as their typing records list them;
  - the region and seal planners' (`src/routes/`) reads of a plan and its row, with row 3a, which
    names both files;
  - the scene recipes' (`scene_recipe*`) reads of an event, with row 3c, and of the map, with the
    map's capture and restore above.

  The fields they read become underscore-private behind a method, which takes the field's name unless the field is a
  yes-or-no one (designing-classes, "Fields are not API").
  Each such pull request's description shows a search for the field's old name read without
  parentheses, across `src/`, `tests/` and `tools/`, listing every remaining hit with its reason (another class's field of the same name, a write, a read inside the class's own file, a comment), only a read of this class's field from outside its file failing the step (inbox #1385 in silver-tapir).
