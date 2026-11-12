# Every listed layer break is fixed, moved in the map, or declared permanent with its reason

**The ask.** A design review of the refactor (minty-quail), asked for by the player ("have a fable agent review the
design of the refactor", inbox #1265 in olive-ferret), found that the layer check (`tools/check_layers.py --list`)
prints 133 listed uses in 37 groups of a file naming a higher layer or fetching what it should be
handed, that `tools/layer_map.py` lists each as a break that still stands, and that no open item of
minty-quail owns them: its closing pull request only rewrites designing-classes' layering section.
Shown that as "133 listed layer breaks have no owner in any open item. Four groups have no home in
the design: the global signal bus, the city scene building the event manager and crowd, the map
interface's world half, and dawn planning reading live-event geometry", the player: "let's not
forget about those" (inbox #1268 in olive-ferret).

**Read as:** the refactor does not close while `tools/layer_map.py` lists a break nobody has decided
about. Each group ends one of three ways: fixed by a named pull request, corrected in the map
because the file was in the wrong layer, or declared permanent in designing-classes with its
reason.

**The groups, as the review found them** (counts are `check_layers.py --list`'s on the day of the
review; a builder runs it again):

- **The signal bus** (37 uses in 11 files): the simulation reports on the global `EventBus`
  autoload, where minty-quail's README has a component handed its event sink. The observers are
  already handed the bus; only the emitters fetch it. The crowd is handed it (`Crowd.use_bus()`,
  the record 2026-10-18-minty-quail-minty-osprey).
- **The city scene as builder** (12 uses in `src/city/city.gd`): it builds the event manager, the
  crowd, the blackout and the poster walls, and relays dev flags to them through its own fields.
- **The map interface's world half** (5 uses in `world_map.gd`): it hands out the navigator and adds
  nodes on a draw layer, which follows from the map interface being the model's (inbox #904 in freckled-moose).
- **Dawn planning reading live-event geometry** (12 uses in the event scheduler and
  `walk_ground.gd`): the live event, its picture footprints and her class's constants.
- **The rest**, small misplacements: the task calendar
  computing on the map; the city edge's kinds; the props' trees; the danger badge's class named by
  the run log (`RunSession`, `TelemetryObserver`); the save indicator reading `GameSave`; the
  texts' `HelpText` token; her class's constants and type tests where she is not handed in
  (`city.gd`, `interior_scene.gd`, `visible_view.gd`); the run reading `ResistanceHappenings`' day
  of the neighbor's raid; the row's check against `SpawnSiting`'s least distance; `DrawnView`,
  named by two looks; the scheduler naming `City.BURNT_FRONTAGE_SCAR`; and the `player` group the
  blackout and the poster walls find her through.

**How each group is settled.** The player approved the review's point that these are not forgotten
(inbox #1268 in olive-ferret); how each is settled is the review's worked-out detail:

- The bus reaches each emitter that still fetches it from whoever builds that emitter, so the order
  is the builders': `main` hands it to the resistance director and to the event manager (as it hands
  it to the crowd through `City.crowd`, until the city scene stops building them), the manager
  hands it on to its encounter watch, its spawner, `EventsAhead` and, through the spawner, each
  live event; the happenings hand it to the park cordon; the blackout and the poster walls take it
  from whoever comes to build them (below). That each copies the
  baby's shape is the orchestrator's reading, open to the player's overturn: the bus script preloaded
  as the field's type, `use_bus()`, and one teller per signal that does nothing without a bus
  (minty-quail-fluffy-yak). The two classes already handed it, `ChargeRecord` and
  `CheckpointController`, take it in their constructor and emit with no guard.
- *Proposed, not asked for, the plainer alternative being that the builder of the third hand-ins
  pull request decides these:* who builds the event manager and the crowd gets a planning pass of
  its own, by Fable, reading `city.gd` and `main.gd` whole, once the third hand-ins step's other pull requests have taken the
  readers under `src/` away (minty-quail's `city-hand-ins.md`), so the building and the city get their event
  manager the same way (`one-start-for-every-spec.md`). Undecided until then: where the factory
  lives and what it is called; whether the blackout and the poster walls, which `City.build()` also
  builds, come with it; how the developer settings `main.gd` writes into `City`'s fields reach the
  parts; and what the tests ask in place of `city.events` and `city.crowd`.
- The map interface's world half is split off or declared a permanent exception in
  designing-classes.
- Dawn planning's reads move with the event scheduler's breakup (`scheduler-breakup.md`), each
  listed break following its file, and are settled by row 3a of minty-quail's `event-interface.md`.
- *Proposed, not asked for, the plainer alternative being to decide each when the pull request
  that finishes this item lists what is left:* **the rest** ends as follows. `DrawnView` goes on the world layer in
  the map, beside `VisibleView`: it names only the engine, as the halo's rim did. The `DangerEdge`
  uses in the run log (`RunSession`'s edge field and `watch()`'s edge parameter,
  `TelemetryObserver`'s edge field and `setup()`'s edge parameter) go in a pull request of their
  own, which hands the run log what its observer reads of the danger edge, the badges that are
  announcing (the orchestrator's proposal). The `player` group, and `city.gd`'s and `visible_view.gd`'s `Stroller`, go with who
  builds the event manager and the crowd, which hands her in; `interior_scene.gd`'s with the
  building's pass; the `CityEdge` kinds, read by `main.gd`, the rigs and the run log, after the
  third hand-ins step; `Prop` as a data constant, in a pull request of its own; `GameSave` and
  `HelpText` in the view's pass; `ResistanceHappenings` with a run's parts (minty-quail's `field-reads.md`); the
  calendar's map and `SpawnSiting` with rows 3c and 4b of minty-quail's `event-interface.md`; and the scheduler's
  `City.BURNT_FRONTAGE_SCAR` with its breakup (`scheduler-breakup.md`).
- `src/events/` holds data, model and simulation files side by side, so a new file there takes the
  most permissive of the three by default: the folder is split by layer, or the map names a
  default for it that a new file has to opt out of.

**Build:** one pull request per group, module by module with the rest of the refactor (minty-quail's
README's order), each deleting the breaks it fixes from `tools/layer_map.py`'s list. The pull request that finishes this item
lists what is left, each line with its reason in designing-classes.
