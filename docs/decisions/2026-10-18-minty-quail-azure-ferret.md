# minty-quail — Row 3a's planned body stands through BodyStance, a model class · 2026-11-20

**What was asked.** Row 3a of minty-quail's `event-interface.md` (the dawn and the walk's ground ask rows and plans):
the model reached up into the simulation for where a planned body stands on its street (`EventFootprints`, which
otherwise measures the baked pictures, and a private static of the live event), a listed layer break
(`standing-layer-breaks.md` of polite-tapir; **designing-classes**, the layers). This pull request (#1585) is the row's
"where a body stands on its street is the model's", from the Opus design of row 3a (kept in the orchestrator's design
folder), built by a Sonnet agent.

**What was built.** `src/events/body_stance.gd` (`BodyStance`, model, a class of statics) holds `stands_at()`, the
recentring on the sidewalk band, `lies_vertically_at()` (the live event's private `_spread_is_vertical()`, public under a
name of its own), `stands_side_on()`, `solid_axis_of()` and `body_axis()`, with no forwarder under an old name. The live
event, its body, the spawner's record, the plan builder and two rigs ask it; the plan builder is no longer handed
`stands_at` as a function. The walk's ground asks rows, plans and `BodyStance` through methods and is typed, its opt-out
line gone. `tools/layer_map.py` drops the `EventFootprints` exception and narrows the `EventInstance` one to the plan's
hold on its live event; `tools/field_reads.txt` loses fourteen lines. The placement probe prints the same on the base and
the branch; nothing a player sees or the run log records changes.

**Open to overturn:** fork F2 of the design (the geometry lives in a model class rather than being handed in as
functions), and its name, `BodyStance`, the design's proposal.

**The item.** Row 3a stays open until its last pull request; section 3's paragraph on where a planned body stands, rows
2a, 3a and 3c, `field-reads.md`'s untyped files and polite-tapir's dawn-planning group say what is left.
