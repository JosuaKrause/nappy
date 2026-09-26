## M60 — Ready for a GitHub Pages launch · six of seven built 2026-09-02

Six items across two agents run in parallel — the deploy chain and the HUD — partitioned by file
rather than by topic, which is what made them safe to merge one after the other.

**The gate is `OS.is_debug_build()` and the point is that it is one gate.** `DevFlags` reads the
command line through a single choke point that returns nothing outside a debug build, so every
flag answers *not given* in an exported release rather than each getter remembering to check.
`AutoScreenshot` gates its own entry point in place, because `--screenshot`, `--after`, `--walk`,
`--flee` and `--press` are parsed there rather than in `main.gd` and moving them would have been a
rewrite. **`--no-telemetry` is deliberately not gated**: it is a documented player-facing opt-out,
not developer furniture.

**Two holes in that gate were found in review rather than by the agent.** `--no-title` read the raw
command line, so a release export could still be told to skip its own front door. And the deploy
workflow ran the export without running the suite: both workflows fire on the same push and neither
waits for the other, so a deploy inheriting CI's verdict would publish a red build to a public
address as often as not. The gate now runs inside the deploy job — a few minutes on the rare push
that reaches `main`, against publishing something nobody checked.

**The telemetry gate is on the platform, not on the build.** `Telemetry.begin_run()` returns early
when `OS.has_feature("web")`, inside the function rather than at its one caller, so a second caller
cannot reintroduce a run log on the one platform where nobody can read or clear it. *Rejected:
gating on `OS.is_debug_build()`, which is the wrong axis — a debug web build must be just as
silent.* The determinism invariant is untouched: the desktop test binary never carries the `web`
feature tag.

**Canvas policy: adaptive**, matching the `canvas_items`/`expand` stretch the desktop build already
uses. *Rejected: a fixed canvas, which would have been a second sizing behaviour to maintain
against a desktop build that already handles arbitrary windows.*

**The HUD is one HUD with a gate rather than two HUDs**, and the implementation detail that makes it
testable is the whole of the item's risk: a test process **is** a debug build, so a gate asking
`OS.is_debug_build()` at each use site would leave the release shape asserted by nothing at all. It
is read once into a member a test can set, and `tests/test_hud.gd` drives both shapes.

**The optional goal keeps `somewhere out there:` and loses the progress dots.** The dots were the
orchestrator's call, on the grounds that a count of how far in you are is the same category as
`nerves ***` in the header. The words were a correction in review: the release line had been the
step's title alone — *a chalk mark* — which says a noun where the whole content of what survives the
cut is *go and find this*.

**What nobody has proven, and both need the same event.** The export has never run to completion:
the templates are not installed on the machine it was built on, so what was verified is that
`tools/export-web.sh` reports their absence with an install pointer rather than a stack trace. And a
workflow only proves itself by running. Both resolve on the first push to `main`.
