# minty-quail — The dev tools', the scene-recipe runtime's and the telemetry's members only their own class used become internal · 2026-11-06


minty-quail's `tests-own-class-members.md`, the underscore pass, for the dev tools (the scene-recipe
runtime, the dev flags, the debug layers, the zoom-out camera, the rig lock, the dev rig, the
auto-screenshot rig, the walk plan, the trailer text, the still watch), the telemetry (the frame
ledger, the observer, the map, the autoload) and the frame graph: a public member only its own
class and the tests use becomes internal and its tests move to what the class does outward
(curly-rabbit #1098), and one with no reader left is deleted (curly-rabbit #1095).

**Built.** Internal: the scene-recipe runtime's `scripted`, `settle_camera_on` and
`validate_runtime`, the last judged by loading a recipe as the game does
(`tests/recipe_runtime_errors.gd`); the dev flags' three parsers, the suites parsing a `RunConfig`
from the flag words; the zoom-out camera's `overview_zoom` and `pose_at`, driven on a handed clock;
the trailer text's `opacity_at`, read as the alpha on real frames; `DevRig.nearest_walkable`,
`FrameGraph.classify`, `TelemetryMap.role_mark`, `TelemetryObserver.spikes_on` and
`RigLock.is_the_rigs_own_press`; and `AutoScreenshot.can_photograph`, which a child headless
process now shows by its message, exit status and absent picture. Deleted, with no reader left:
`RigLock.has_a_deadline`, `WalkPlan.smoothed_turns`, `DebugLayers.body_outline_count`,
`Telemetry.SHOTS_PER_DAY` (the suites read `TelemetryShots.PER_DAY`), and the frame ledger's
`DRAWS_*` constants but `DRAWS_CROWD`, a kind's counter being `DRAWS_CROWD` plus its
`FrameTiming.Draw` value. Removed as holding nothing (curly-rabbit #1097): a read-back of the
observer's mandatory spikes flag, a debug-layer check comparing a list with itself, a settle-camera
check the booted camera probe repeats, the rig lock's six direct predicate checks, and the
auto-screenshot rig's desktop display cases, which a headless run never reaches.

**Kept public**, each with its reason beside its line in the list: the debug layers'
`collision_nodes_under`, `field_runs` and `open_runs` and `FrameGraph.classes`, which only feed
draw calls a headless run discards; `AutoScreenshot.recording_frame_needs_force`, which only feeds
`RenderingServer.force_draw()`; `DevRig.pavement_offset`, whose caller snaps away the axis it
decides; `StillWatch.facing_a_red_light`, which only decides whether a run-ending watch fires; and
the scene-recipe runtime's `hold_refusal`, `hold_refusal_message`, `charging_refusal` and
`relentless_refusal`, which show outward only as `install()` errors after a legal siting, one per
catalogue row. Open to overturn, the last group most of all, and the `DRAWS_*` constants deleted
rather than kept for a relationship.
