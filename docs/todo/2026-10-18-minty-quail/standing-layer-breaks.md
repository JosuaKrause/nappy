# Every listed layer break is fixed, moved in the map, or declared permanent with its reason

**The ask.** A design review of this entry, asked for by the player ("have a fable agent review the
design of the refactor", inbox #1265 in olive-ferret), found that the layer check (`tools/check_layers.py --list`)
prints 133 listed uses in 37 groups of a file naming a higher layer or fetching what it should be
handed, that `tools/layer_map.py` lists each as a break that still stands, and that no open item of
this entry owns them: the closing pull request only rewrites designing-classes' layering section.
Shown that as "133 listed layer breaks have no owner in any open item. Four groups have no home in
the design: the global signal bus, the city scene building the event manager and crowd, the map
interface's world half, and dawn planning reading live-event geometry", the player: "let's not
forget about those" (inbox #1268 in olive-ferret).

**Read as:** the entry does not close while `tools/layer_map.py` lists a break nobody has decided
about. Each group ends one of three ways: fixed by a named pull request, corrected in the map
because the file was in the wrong layer, or declared permanent in designing-classes with its
reason.

**The groups, as the review found them** (counts are `check_layers.py --list`'s on the day of the
review; a builder runs it again):

- **The signal bus** (37 uses in 11 files): the simulation reports on the global `EventBus`
  autoload, where this entry's README has a component handed its event sink. The observers are
  already handed the bus; only the emitters fetch it. The crowd is handed it (`Crowd.use_bus()`,
  the record 2026-10-18-minty-quail-minty-osprey).
- **The city scene as builder** (12 uses in `src/city/city.gd`): it builds the event manager, the
  crowd, the blackout and the poster walls, and relays dev flags to them through its own fields.
- **The map interface's world half** (5 uses in `world_map.gd`): it hands out the navigator and adds
  nodes on a draw layer, which follows from the map interface being the model's (inbox #904 in freckled-moose).
- **Dawn planning reading live-event geometry** (12 uses in the event scheduler and
  `walk_ground.gd`): the live event, its picture footprints and her class's constants.
- **The rest**, small misplacements: the dev rig named by the day director, the task calendar
  computing on the map, the city edge's kinds, the props'
  trees.

**How each group is settled.** The player approved the review's point that these are not forgotten
(inbox #1268 in olive-ferret); how each is settled is the review's worked-out detail:

- The bus is handed to the emitters, which is mechanical.
- Who builds the event manager and the crowd is decided in the third hand-ins pull request
  (`city-hand-ins.md`), which already rewrites `EventManager.setup(city, …)` and the readers of
  `City.events` and `City.crowd`, so the building and the city get their event manager the same way
  (`one-start-for-every-spec.md`).
- The map interface's world half is split off or declared a permanent exception in
  designing-classes.
- Dawn planning's reads go with the event scheduler's breakup (`scheduler-breakup.md`).
- `src/events/` holds data, model and simulation files side by side, so a new file there takes the
  most permissive of the three by default: the folder is split by layer, or the map names a
  default for it that a new file has to opt out of.

**Build:** one pull request per group, module by module with the rest of the entry (the README's
order), each deleting the breaks it fixes from `tools/layer_map.py`'s list. The closing pull request
lists what is left, each line with its reason in designing-classes.
