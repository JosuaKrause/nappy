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

*Proposed, not asked for:* a design on the board first, listing the reads by class and the methods
that replace them, then one pull request per area.

**Decided on the board** (inbox #1182 in gray-dolphin):

- **tests-read-fields, "yes":** a test counts as another object, so it too reads its subject through
  methods (`tests-one-module.md`).
- **field-read-check, "yes":** a script fails a change that adds a read of another class's plain
  field under `src/`, with today's reads listed once in a list that only shrinks. It is
  `tools/check_field_reads.py`, with the list in `tools/field_reads.txt`, run in CI's `gates` job.

**The check is made to see every read** (inbox #1268). `tools/check_field_reads.py` skips a read
whose receiver's class it cannot tell: `--summary` counted 1,220 listed reads beside 2,320 uses
skipped for an unknown receiver, so an empty list would not mean the rule holds. Shown "The
field-read check skips about two thirds of reads because it cannot tell the receiver's class", the
player: "isn't that the point of a class hierarchy? it should be made working".

**Read as:** every receiver under `src/` has a class the check can tell, so a read of another
class's field cannot hide behind an untyped name. **How** is the design review's worked-out detail, written after the player had approved its points
(inbox #1268): the engine sees
what the script cannot. GDScript's own warnings for an access the engine cannot type
(`unsafe_property_access`, `unsafe_method_access`, `untyped_declaration`) are turned into errors in
`project.godot`, with a file-level ignore at the top of every file not yet converted (the builder
checks first that the project's Godot version has a file-level ignore); the files carrying that
line are the list that only shrinks, a module's pass types its receivers and deletes the line, and
once none is left `tools/check_field_reads.py` fails on an unknown receiver. It matters beyond
tidiness: once a field has become a method of the same name, an untyped `thing.hard_fail` without
its parentheses is a reference to the function, which is always true, and nothing reports it. The
plainer alternative it replaces is the check listing the uses it skips in a group of its own, which
finds the reads but not that mistake.

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
  `src/routes/`, `src/dev/`, `scene_recipe*`, `day_director.gd`, `main.gd`, `day_planner.gd`,
  `run_session.gd`, the event manager and `EventWorld`, scenery residency and ground, the blackout,
  the still watch and the debug readout) are converted after those land, and the fields they read
  become underscore-private with the method taking the field's name.
