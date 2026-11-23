# minty-quail — The two GDScript tools are typed · 2026-11-23

The queue files said the two scripts under `tools/` that carried untyped code, `tools/cost_table.gd`
and `tools/split-scenes-crop.gd`, would be typed by the pull request that next changed each. This one
types them.

**`tools/cost_table.gd` needed no change.** It carries no opt-out line, and it is run as a scene
(`tools/cost-table.sh`), which parses it under the project's three typing warnings as errors; every
declaration was already typed and every dictionary read goes through a typed name (`String(...)`
around `row.get`, `for id: String in`, `var row: Dictionary = t.rows[id]`). `tools/cost-table.sh
--check` reports `docs/COSTS.md` up to date, and `field-reads.md`'s sentence naming it as untyped was
already untrue.

**`tools/split-scenes-crop.gd` carried the opt-out line**, `untyped_declaration` and
`unsafe_method_access`, and loses it. What the engine flagged: `for frame in layer.frames.size()`
(an untyped loop variable) and `layer.frames.size()` (a method called off a Variant read from a
dictionary). The layers of a stem and the frames of a layer are now read once into a typed
`Dictionary` and a typed `Array`, and the loop variable is an `int`. Nothing the tool does changed.

**Measured on main and on the branch, the same way.** The crop tool is run only by
`tools/split-scenes.py`; `uv run python tools/split-scenes.py --metadata-output <file>` on each wrote a
byte-identical metadata record (`cmp`), and `--check` reports the thirty generated outputs (the
cropped SVGs, `event_scenery_parts.gd` and `membership.json`) current. `tools/cost-table.sh --check`
passes.

No script under `tools/` carries the opt-out line now; the queue files say so.
