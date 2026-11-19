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

- **The map interface's world half** (5 uses in `world_map.gd`): it hands out the navigator and adds
  nodes on a draw layer, which follows from the map interface being the model's (inbox #904 in freckled-moose).
- **Dawn planning reading live-event geometry** (12 uses in the event scheduler and
  `walk_ground.gd`): the live event, its picture footprints and her class's constants.
- **The rest**, small misplacements: the task calendar
  computing on the map; the danger badge's class named by
  the run log (`RunSession`, `TelemetryObserver`); the save indicator reading `GameSave`; the
  texts' `HelpText` token; her class's type tests where she is not handed in
  (`interior_scene.gd`); the run reading `ResistanceHappenings`' day
  of the neighbor's raid; the row's check against `SpawnSiting`'s least distance; and the scheduler naming `City.BURNT_FRONTAGE_SCAR`.

**How each group is settled.** The player approved the review's point that these are not forgotten
(inbox #1268 in olive-ferret); how each is settled is the review's worked-out detail:

- The map interface's world half is split off or declared a permanent exception in
  designing-classes.
- Dawn planning's reads of live-event geometry stand in `src/events/walk_ground.gd`
  (`EventFootprints` three times, `EventInstance` once); row 3a of minty-quail's `event-interface.md`
  settles them.
- *Proposed, not asked for, the plainer alternative being to decide each when the pull request
  that finishes this item lists what is left:* **the rest** ends as follows. The `DangerEdge`
  uses in the run log (`RunSession`'s edge field and `watch()`'s edge parameter,
  `TelemetryObserver`'s edge field and `setup()`'s edge parameter) go in a pull request of their
  own, which hands the run log what its observer reads of the danger edge, the badges that are
  announcing (the orchestrator's proposal). `interior_scene.gd`'s `Stroller` goes with the
  building's pass; `GameSave` and
  `HelpText` in the view's pass; the
  calendar's map and `SpawnSiting` with rows 3c and 4b of minty-quail's `event-interface.md`; and `RowGround`'s
  `City.BURNT_FRONTAGE_SCAR` (`src/events/row_ground.gd`, read by `_burns_its_front()`) when placement
  closes, since no step of `placement-by-construction.md` rewrites that read.
- `src/events/` holds data, model and simulation files side by side, so a new file there takes the
  most permissive of the three by default: the folder is split by layer, or the map names a
  default for it that a new file has to opt out of.

**Build:** one pull request per group, module by module with the rest of the refactor (minty-quail's
README's order), each deleting the breaks it fixes from `tools/layer_map.py`'s list. The pull request that finishes this item
lists what is left, each line with its reason in designing-classes.
