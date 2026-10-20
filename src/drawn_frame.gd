class_name DrawnFrame
extends RefCounted
## The wait for a frame the viewport has actually drawn, shared by every capture: the run log's
## stills and bursts, `AutoScreenshot`'s still, `--quit-when-still` and the previews. Below all of
## them, so the run log waits through it without depending on the dev rig that also uses it.

## Returns once the viewport texture holds a frame drawn since the call, and whether that frame had
## to be forced. Every capture under `src/` waits here rather than on `RenderingServer.frame_post_draw`
## alone, which `tests/test_auto_screenshot.gd` holds.
##
## **A window that cannot be seen is not drawn at all.** On macOS the main loop skips its draw step
## whenever no window of the process is visible by the system's own occlusion test — fully covered
## by another app's opaque window or minimized, and by that test's definition also on another Space
## or behind a locked screen — while processing and physics carry on in real time. So a bare
## `await frame_post_draw` in a covered rig waits for a signal that never comes, the walk and the
## clock run on, and the rig ends on its own wall-clock limit with no picture. A rig's window takes
## no focus, so whatever the operator has in front of it is enough to cover it.
##
## So each frame this checks `DisplayServer.window_can_draw()`, and when it is false draws one frame
## on demand with `RenderingServer.force_draw()`, which renders every viewport into its texture —
## the one a capture reads — and emits `frame_post_draw` like any other frame. It is forced from
## `process_frame`, before this frame's scripts run, so it shows the state the skipped draw would
## have shown. `swap_buffers` is off because there is nothing on screen to present to. Its frame
## step is 0, so shader `TIME` and particles do not advance on a forced frame — nothing the game
## draws uses either.
##
## A coroutine: callers write `await DrawnFrame.wait(get_tree())`. Never called headless — the null
## display server can draw nothing, forced or not, which is `AutoScreenshot.can_photograph()`'s
## question.
static func wait(tree: SceneTree) -> bool:
	var state := {"drawn": false}
	var on_drawn := func() -> void: state["drawn"] = true
	RenderingServer.frame_post_draw.connect(on_drawn, CONNECT_ONE_SHOT)
	var forced := false
	while not state["drawn"]:
		await tree.process_frame
		if not state["drawn"] and not DisplayServer.window_can_draw():
			RenderingServer.force_draw(false)
			forced = true
	return forced
