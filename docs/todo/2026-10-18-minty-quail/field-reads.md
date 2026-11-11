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

**Every receiver gets a class the check can tell** (inbox #1268 in olive-ferret). Shown "The field-read check
skips about two thirds of reads because it cannot tell the receiver's class", the player: "isn't
that the point of a class hierarchy? it should be made working". **What is left of it** is the
typing itself: the files that carry the opt-out line (godot's "Types" gives its one form) are a
second list that only shrinks (`tools/check_field_reads.py --summary` counts them by folder and by
warning). Each area's conversion below types the receivers in its files and deletes their line;
`tests/` follows with the suites' conversion (`tests-one-module.md`), and the two scripts under
`tools/` that carry it (`tools/cost_table.gd`, `tools/split-scenes-crop.gd`) are typed by the pull
request that next changes each, or with the suites' conversion if none does first. The engine warns of nothing on a property read off a value it types as
Variant (an untyped array's element, what `back()` or `get()` returns), so such a value is read
through a typed name, and the check, not the engine, is what holds that.

**What is left: the conversion**, one pull request per area, each deleting the lines it converts
from `tools/field_reads.txt` (its `# [Class] path` groups say which class's fields are read and
from where; `--summary` prints the counts). The reads are heaviest on the event definition and
the event instance, then the city map and the city, so the events go first, as the ask says.

Left, each its own design question:

- **The strategies' calls on the mover's underscore methods.** The car and walker strategies still
  make 49 calls to 11 of `LaneMover`'s underscore methods (`_along()`, `_cross()`,
  `_set_along()`, `_set_cross()`, `_turn_round()`, `_tile_ahead()` and the like); a later pull
  request turns those into the strategy's questions on the narrow lane interface (`LaneMover.Lane`),
  named for what is asked and what happens.
- **A run's parts.** `RunState` hands out `header`, `calendar`, `resistance`, `attempt_spend`,
  `posters` and `facts`, and a read through one is two field reads (`RunHeader`, `RunCalendar`,
  `ResistanceRunState`, `RunFacts`, `SettledState`): the parts reached through methods and each
  part's fields behind methods; the vars are renamed, and the files the third hand-ins pull
  request touches and the tests read them, so it waits for that pull request.
- **`BlockedLayer`**, converted with the map's property wrappers in `src/city/`.
- **The city's own classes** have their readers converted except three groups, each with a home:
  - The authored-scene builder (`RecipeCityBuilder`) and the map's capture and restore
    (`RecipeCityContext`) are the scene recipes' city. They go with or after `placement-by-construction.md`'s bullet on the
    scene recipes assigning locations, which rewrites the scene recipes, so no work is done twice (inbox #1185 in gentle-owl); a design for the map
    capturing and restoring itself waits for it.
  - `City.events` and `City.crowd`, read by the poster walls and the frame recorder and trace, go with
    the third hand-ins pull request (`city-hand-ins.md`), which hands those readers their parts. An
    accessor on `City` would add uses of `EventManager` and `Crowd` to breaks `tools/layer_map.py` lists.
  - A field only a test still reads (`CityMap.home_rect`, `home_block`, `courtyard_rects`,
    `Building.scenery_clock`, `door_world_x_range`, `power_station`, `station_door_col`,
    `station_yard_cols`, `BuildingShadows.streamed`, `falls_on`, `PosterState.pasted_through`) keeps its
    direct write in the city and goes with the tests-one-module item (`tests-one-module.md`), when its
    tests read through a method the game also calls.
- **The lines the placement rewrite and the third hand-ins pull request touch** (`src/events/`,
  `src/routes/`, `src/dev/`, `scene_recipe*`, `day_director.gd`, `main.gd` past `_make_player()`, `day_planner.gd`,
  `run_session.gd`, the event manager and `EventWorld`, scenery residency and ground, the blackout,
  the still watch and the debug readout) are converted after those land, and the fields they read
  become underscore-private behind a method, which takes the field's name unless the field is a
  yes-or-no one (designing-classes, "Fields are not API").
