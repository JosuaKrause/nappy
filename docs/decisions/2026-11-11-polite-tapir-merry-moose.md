# polite-tapir — The run log reads the danger badges through EdgeBadges and names no view · 2026-11-19

**What was asked.** polite-tapir's `standing-layer-breaks.md` holds the layer breaks
`tools/check_layers.py --list` prints, which the player asked not be forgotten (inbox #1268 in
olive-ferret). This group is the run log naming `DangerEdge`, the screen-edge danger badges: the
observers and the view are siblings that do not name each other (inbox #904 in freckled-moose). The
item's sentence for it, the orchestrator's proposal, gave it a pull request of its own that hands the
run log what its observer reads of the badges. Fable's quota is out and the player answered "yes,
continue with one fable task at a time and use opus for it" (grassy-bison #1560), so an Opus agent
designed and built it in Fable's place; the pull request (#1567) carries the `fable-only` label. It was
held unmerged for Fable's review of the design (entry grassy-ibis) until the player lifted that
hold while Fable's quota is out (inbox #1571 in teal-quail), and merged on its Opus review.

**What was built.** The run log read one thing of the badges each frame, `announcing()`, taking each
badge's id, distance and approach for its two `edge badge` lines; `DangerEdge` passed the call through
to its `BadgeModel`, which decides which dangers get a badge. `EdgeBadges` (`src/ui/edge_badges.gd`,
placed in the model layer by its own entry in `tools/layer_map.py`) is a read-only interface with that
one method, reporting no badges when nothing is handed in. `BadgeModel` extends it; `DangerEdge.badges()`
hands out its model typed as the interface; `main` hands that to `RunSession.watch()`, which hands it to
`TelemetryObserver.setup()`. The observer reads the same object at the same point in the frame, and the
run log's lines are unchanged (one short headless day before and after matched line for line but for
one measured frame time). `DangerEdge.announcing()` is deleted, since only tests called it once the run
log stopped; eleven tests, helpers and probes read `edge.badges().announcing()`. A new case in
`tests/test_telemetry_observer.gd` holds the exact `edge badge` and `edge badge gone` lines, which no
test held before. The four listed uses leave `tools/layer_map.py`'s list and no break is added.

**Rejected.** A plain callback handed to the run log, the smaller change, which Fable may prefer; the
root building the badge model and handing it to both the edge and the run log.

**Open to overturn (the designer's, and Fable's to judge):** the model layer rather than data; the
name `EdgeBadges`; the edge handing out its own model through `badges()`; deleting
`DangerEdge.announcing()`.

**The item.** The group leaves `standing-layer-breaks.md`'s list and its sentence there; the item stays
open for its other groups.
