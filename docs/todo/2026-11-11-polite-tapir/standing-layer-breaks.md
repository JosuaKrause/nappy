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

- **The rest**, small misplacements: the task calendar
  computing on the map; the save indicator reading `GameSave`; the
  texts' `HelpText` token; her class's type tests where she is not handed in
  (`interior_scene.gd`); the run reading `ResistanceHappenings`' day
  of the neighbor's raid; and the row's check against `SpawnSiting`'s least distance.

**How each group is settled.** The player approved the review's point that these are not forgotten
(inbox #1268 in olive-ferret); how each is settled is the review's worked-out detail:

- The plan's hold on its live event goes with row 3b of minty-quail's `event-interface.md`, whose
  streaming keeps that state per plan; the geometry dawn planning read is `BodyStance`'s, a model
  class (the record minty-quail-azure-ferret).
- *Proposed, not asked for, the plainer alternative being to decide each when the pull request
  that finishes this item lists what is left:* **the rest** ends as follows. `interior_scene.gd`'s `Stroller` goes with the
  building's pass; `GameSave` and
  `HelpText` in the view's pass; the
  calendar's map and `SpawnSiting` with rows 3c and 4b of minty-quail's `event-interface.md`.
- `src/events/` holds data, model and simulation files side by side, so a new file there takes the
  most permissive of the three by default: the folder is split by layer, or the map names a
  default for it that a new file has to opt out of.

**Build:** one pull request per group, module by module with the rest of the refactor (minty-quail's
README's order), each deleting the breaks it fixes from `tools/layer_map.py`'s list. The pull request that finishes this item
lists what is left, each line with its reason in designing-classes.
