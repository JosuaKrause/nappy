## M76 — The title asks with buttons, and a release carries no modifiers · built 2026-09-06

Playtest 26's first two findings, plus two instructions that arrived beside them. The milestone's
other half — the summary's tap target and the held restart — is the entry above.

**The two title buttons already were `Button` nodes; they did not read as any.** *"the choice on the
title screen is not at all obvious. those should be proper buttons"*. The scene gave them a minimum
size, a font size and wrapping, so they took Godot's default flat theme and looked like the label
text above them. **Three attempts, and the first two failed on the same mistaken constraint.** The
brief forbade SVG to keep the work clear of the deferred graphics overhaul — but the player had
already ruled that *"this is not game graphics. buttons are just UI"*, so the constraint protected
nothing and cost two rounds: a rectangle with a corner badge that overlapped its own body text, then
a circular disc whose glyphs were assembled from primitives and read as a lollipop on a bar and a T
with a wedge. **The rule that came out of it is in the cues skill** — a picture is an asset, never
code — and `ModeButton` ended with no `_draw()` at all: three `StyleBoxFlat` states with circular
corner radii for the disc, and the button's own `icon` for the glyph.

**The paragraph moved out of the button rather than being laid out around the glyph.** *"remove the
text (or put it under it without it being clickable)"*. It is a plain `Label` beside each button
with `mouse_filter = MOUSE_FILTER_IGNORE`, so a click on the caption falls through instead of
becoming a dead zone in the middle of the screen.

**Sizing came from the game rather than from a mouse**: the disc's 46px radius is the floor of
`TouchControls`' own three catch radii, so nothing on the title screen is harder to hit than the
least generous control already in play.

**The icons went through a defect that was invisible in the source.** Both carried
`shape-rendering="crispEdges"` on a 32-unit grid while rendering into a 46px radius — antialiasing
off, upscaled about 3x — so every curve quantised to a staircase and the tap ripples collapsed into
bars. Dropping it and re-authoring on a 128 grid fixed the arcs outright. What remained after that
was shape rather than resolution: straight lines and square corners everywhere, which is why the
hand read as a letter. The silhouettes were rebuilt on the three things that carry a glyph at that
size — a narrow finger with a rounded tip against a much wider palm, a thumb breaking the outline on
one side only, a flat wrist — and the joystick's ball was made round rather than as wide as its base
is deep. The reference is `docs/evidence/reference-buttons-2026-09-06.jpeg`, colours excluded on
instruction.

**The input principle is the player's and is stronger than its two mappings**: *"on the local
clicking should choose the tap and arrow keys should choose the controls"* — the device you answer
with is the device you are answering about, so each choice is made by doing the thing it selects.
`t` was dropped on the player's own reasoning (*"it's a move from keyboard to mouse"*), `space` and
the arrows choose the stick, and a click chooses tap. **Both fallbacks went**: a pointer press
landing on neither button now does nothing — *"clicking anywhere else should do nothing"* — which
also removed a touch-anywhere path that had been silently choosing the stick on the one device the
screen actually opens on. **A flag still skips the question entirely**, and that path is
byte-for-byte what it was.

**A release build carries no modifiers; a debug build carries all of them from the start.**
*(2026-09-06: "for dev you need it to be controllable from the getgo -- for release there should be
no modifiers".)* Both URL flags — `?controls=` and `?telemetry=1` — are kept for testing and gated
behind `DevFlags.enabled()`.

**This overturns a line written into M73 four days earlier**, which said the telemetry override
*"has to work in a release build, because the deployed page is exactly where `DevFlags.enabled()`
cannot reach"*. That was the milestone's own inference rather than a request, and the player said so
plainly: *"I never asked for telemetry on web. you added that to debug in a browser. that browser
build should be dev only the CI build is release."* Three docstrings had been arguing the ungated
case in some detail and now argue the opposite.

**The gating would have been a deletion without the other half**, since `tools/export-web.sh` only
ran `--export-release`, so no web build existed where `OS.is_debug_build()` is true. It takes a
`release|debug` argument now, defaulting to release so the deploy workflow is untouched. And
`tools/serve-web.sh` exports debug and serves it, because **a Godot web export cannot be opened from
`file://`** and nothing in the project served one — so until now the only way to run this game's web
build was to deploy it, which is a large part of why a runtime error reached the live site.

**The promise is tested rather than assumed.** The guard's predicate is a pure function taking
`is_debug` and `on_web`, so all four combinations are asserted directly with no build type to fake —
which matters because the untestable version of exactly this gate is what hid M73's invincibility
bug.
