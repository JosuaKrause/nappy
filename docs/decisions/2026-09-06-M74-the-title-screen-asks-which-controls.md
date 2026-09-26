## M74 — The title screen asks which controls · built 2026-09-06

Playtest 25's verdict on M68's experiment, which existed to find out which of the two control
schemes wins. **Neither did** — *"I like both control modes equally"* — so the experiment resolved
by handing the choice to the player: *"let the player choose on the title screen (instead of tap the
screen to start have two buttons to choose from)"*.

The title stopped being a single "tap to start" and became a choice that is also the start: one
press, not a menu and then a start. `ControlsMode` moved from a build-time resolution read once into
three `_ready`-time members — in `main.gd`, `hud.gd` and `title_screen.gd` — to an answer produced
by the title screen and read after it, because **a stale copy of the answer was the whole of the
work**. The existing flag order is unchanged and deliberate: `--controls tap|stick` behind
`DevFlags`, then the page's `?controls=` URL flag, then the question. **A flag is how you skip the
question, so a run started with one is not asked.**
