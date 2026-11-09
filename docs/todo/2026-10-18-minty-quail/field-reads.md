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

**What is left: the conversion**, one pull request per area, each deleting the lines it converts
from `tools/field_reads.txt` (its `# [Class] path` groups say which class's fields are read and
from where; `--summary` prints the counts). The reads are heaviest on the event definition and
the event instance, then the city map and the city, so the events go first, as the ask says.

Left outside the events, the city and the routes, and each its own design question:

- **A strategy and its mover.** `LaneMover`'s underscore fields and callables are read by
  `CarStrategy` and `WalkerStrategy`, and `LaneStrategy`'s by `LaneMover`: the reading is a narrow
  interface the mover builds for each strategy, with methods named for what it asks; about 330
  uses, in the per-agent per-frame code, so measured against the crowd's cost.
- **A run's parts.** `RunState` hands out `header`, `calendar`, `resistance`, `attempt_spend`,
  `posters` and `facts`, and a read through one is two field reads (`RunHeader`, `RunCalendar`,
  `ResistanceRunState`, `RunFacts`, `SettledState`): the parts reached through methods and each
  part's fields behind methods; the vars are renamed, and the files the third hand-ins pull
  request touches and the tests read them, so it waits for that pull request.
- **`BlockedLayer`**, converted with the map's property wrappers in `src/city/`.
- **What the fence kept for the third hand-ins pull request and the placement rewrite**: every line
  whose owner or reader is under `src/events/`, `src/routes/` or `src/dev/`, a `scene_recipe*` file,
  or a file the third hand-ins pull request touches, and the fields those still read (`DaySpec`,
  `RunConfig`, `MoveProposal` and `WorldMap`, in part).
