priority: later
after: 2026-10-18-minty-quail

# azure-marten — The simulation's five files that name nothing of it: whether each belongs a layer lower · filed 2026-11-23

**Where it comes from.** No words of the player's: the design of polite-tapir's standing layer breaks
(the refactor's design review, which the player approved, inbox #1268 in olive-ferret) found it while
splitting the events folder by layer, and left it "for the queue, not decided here". The filer
proposes the entry and its band.

**What was found.** `src/events/simulation/` holds five files that name nothing of the simulation
layer, so each would pass the layer check one layer lower: `sited_ground.gd` (names only what is up
to the model), `event_scenery.gd` (up to the world), and `warning.gd`, `where_she_is.gd` and
`views/event_pictures.gd` (data only). The folders are the layers, so the check holds a class where
its folder puts it and says nothing of a class that could stand lower.

**The question, one class at a time.** Whether a file belongs a layer lower is a question about
that class: the warning clock and where she is read as live state, which is the simulation's;
`SitedGround` reads as a plan-builder, which is the model's. For four of the files the answer is one
`git mv` into `src/events/model/` or `src/events/data/` that `tools/check_layers.py` then holds, with
the paths that name the file rewritten; a class that stays says why in its pull request.
`event_scenery.gd` is different: it names world-layer classes (`AtlasLibrary`, `SceneryDrawer`,
`SceneryLayer`), so its only lower layer is the world, which no events folder holds. Its answer is a
move under `src/world/`, where it leaves the **events** skill's path row, or a new events folder with
a line of its own in the map, and which of the two is part of its question.

**Proposed, not asked for.** That each file gets its own answer rather than all five moving or all
five staying, and the `later` band, are the filer's. The plainer alternative is to leave the five
where they are, since a class on a higher layer than it needs breaks nothing the check holds.
