# minty-quail — Row 3b's first pull request: the bus carries a live event typed Node2D · 2026-11-20

**What was asked.** Row 3b of minty-quail's `event-interface.md` (the event manager's parts); code is typed wherever the
language can type it (inbox #1280 in olive-ferret). Six signals of the bus carried the live event untyped, the whole
of what `src/autoload/event_bus.gd`'s opt-out line was for, and the bus is on the model layer, so typing them
`EventInstance` would make the model name the simulation. An Opus design cut row 3b into twelve pull requests (kept
in the orchestrator's design folder); this is the first, built by a Sonnet agent (#1577).

**What was built.** `event_telegraphed`, `event_activated` and the four `pelican_*` signals take `instance: Node2D`,
and the bus's opt-out line is deleted, so the bus is typed. The run log's observer takes `Node2D` and reads
`as EventInstance`; GoatCounter's visit counter takes `Node2D` in its four pelican handlers. Nothing a player sees or
the run log records changes, and no field became a method.

**Open to overturn (the designer's fork F5, built on its pick):** `Node2D` as the signals' type. The plainer
alternative is the opt-out line kept on the bus with its reason.

**The item.** Row 3b stays open until its last pull request; `field-reads.md` loses the bus from its list of untyped
files, and section 2.6 of `event-interface.md` says what the bus now carries.
