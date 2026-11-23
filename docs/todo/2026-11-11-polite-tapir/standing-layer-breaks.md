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

**What is left.** `check_layers.py --list` lists no break and the events folder is split by layer, so what
remains is the closing, the rule that outlives the list:

- designing-classes, "Code is designed by layer": the sentence that the list of breaks standing in the map only
  shrinks becomes the rule that no break stands, and one that has to is listed in `tools/layer_map.py` with its
  reason and declared in that section with the same reason, in the pull request that adds it.
- `docs/ARCHITECTURE.md`'s paragraph on the map, which says the map lists by file every break that still stands,
  and pr-review's `references/architecture-questions.md`, which names its list of standing breaks, say the same
  rule in their own words.
- polite-tapir's `README.md` loses its bullet on the standing layer breaks.
