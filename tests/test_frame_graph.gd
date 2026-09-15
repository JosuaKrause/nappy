extends RefCounted
## `FrameGraph`'s own arithmetic — the ring, the mean and the classification — driven with literal
## deltas rather than a live `Performance` reading, the same reason `tests/test_performance.gd`
## drives `FrameCost`'s window that way. What a bar actually looks like is not tested here: see the
## **verify** skill, "layout, colour, readability" is checked by eye, and the milestone's own
## `tools/shot.sh` still.
##
## `FrameGraph` is a `Control`, so every instance this suite builds is freed by hand — nodes are
## not refcounted the way the `RefCounted` classes the rest of this file's neighbours test are.

func run(t) -> void:
	_test_more_than_the_window_pushes_only_the_last_240_remain(t)
	_test_the_mean_is_the_windows_own_mean(t)
	_test_classification_of_an_ordinary_a_costly_and_a_lethal_frame(t)
	_test_a_hidden_graph_records_nothing(t)
	_test_a_bars_class_is_fixed_when_it_is_pushed(t)

## `FRAME_GRAPH_FRAMES` (240) pushes would leave the whole window; 300 is 60 past it, so the first
## 60 pushed (indices 0..59) must have aged out and the last 240 (indices 60..299) must be exactly
## what remains, oldest first.
func _test_more_than_the_window_pushes_only_the_last_240_remain(t) -> void:
	var graph := FrameGraph.new()
	for i in range(300):
		graph.push(0.001 * i)
	var frames := graph.frames()
	t.check(frames.size() == FrameGraph.FRAME_GRAPH_FRAMES,
			"the ring holds no more than FRAME_GRAPH_FRAMES after 300 pushes (%d)" % frames.size())
	t.check(is_equal_approx(frames[0], 0.001 * 60),
			"the oldest surviving push is the 61st one made, the first 60 having aged out")
	t.check(is_equal_approx(frames[frames.size() - 1], 0.001 * 299),
			"the newest surviving push is the very last one made")
	graph.free()

## Three known deltas average to a known mean — the ring holds fewer than the window's own 240, so
## nothing has aged out and the mean is exactly their arithmetic mean.
func _test_the_mean_is_the_windows_own_mean(t) -> void:
	var graph := FrameGraph.new()
	graph.push(0.010)
	graph.push(0.020)
	graph.push(0.030)
	t.check(is_equal_approx(graph.mean(), 0.020),
			"the mean of three pushed deltas is their arithmetic mean (%.4f)" % graph.mean())
	graph.free()

## Against the two fixed lines, whatever the window holds: 0.025s (25ms, past the 16.7ms line but
## short of 33.3ms) classes costly, 0.040s (40ms, past 33.3ms) classes lethal, and 0.011s (11ms,
## past neither) classes neither. The steady 10ms window is there to show the mean plays no part.
func _test_classification_of_an_ordinary_a_costly_and_a_lethal_frame(t) -> void:
	var graph := FrameGraph.new()
	for i in range(10):
		graph.push(0.010)
	t.check(is_equal_approx(graph.mean(), 0.010),
			"the window's mean is the steady 10ms every frame in it was pushed at (%.4f)" % graph.mean())
	t.check(graph.classify(0.011) == FrameGraph.FrameClass.NORMAL,
			"11ms is past neither the 16.7ms line nor the 33.3ms one")
	t.check(graph.classify(0.025) == FrameGraph.FrameClass.COSTLY,
			"25ms is past the 16.7ms line and short of the 33.3ms one, whatever the mean")
	t.check(graph.classify(0.040) == FrameGraph.FrameClass.LETHAL,
			"40ms is past the 33.3ms lethal line whatever the mean says")
	graph.free()

## `push()`'s own gate, exercised directly rather than through `main.gd`'s call site: a graph the
## `4` key (or a release page that never built one) has turned off must feed nothing into the ring
## and queue no redraw, not merely stay invisible while quietly warming one nobody can see.
func _test_a_hidden_graph_records_nothing(t) -> void:
	var graph := FrameGraph.new()
	graph.visible = false
	graph.push(0.016)
	graph.push(0.033)
	t.check(graph.frames().is_empty(), "nothing pushed while hidden reaches the ring")
	t.check(is_equal_approx(graph.mean(), 0.0), "and the mean of an empty ring is 0.0, not a stale reading")
	graph.free()

## A frame's colour is decided once, when it is pushed, and stored — not re-derived at draw time.
## *(2026-09-14, the player: "I see things on the left side changing (notably adding yellow lines
## after the fact)".)* With the lines fixed the answer could not change anyway, so the check is
## that the stored classes exist, stay in step with the frames, and read what `classify()` says.
func _test_a_bars_class_is_fixed_when_it_is_pushed(t) -> void:
	var graph := FrameGraph.new()
	for i in range(10):
		graph.push(0.010)
	graph.push(0.025)
	var at_push: int = graph.classes()[10]
	t.check(at_push == FrameGraph.FrameClass.COSTLY,
			"25ms pushed after ten 10ms frames is classed costly at the moment it is pushed")
	for i in range(100):
		graph.push(0.030)
	t.check(graph.classes()[10] == FrameGraph.FrameClass.COSTLY,
			"the bar keeps the class it was given when pushed, however the window moved since")
	t.check(graph.classes()[0] == FrameGraph.FrameClass.NORMAL and graph.classes()[11] == FrameGraph.FrameClass.COSTLY,
			"a 10ms bar is ordinary and a 30ms bar is costly, each by the fixed lines alone")
	t.check(graph.classes().size() == graph.frames().size(),
			"and the classes stay in step with the frames (%d against %d)"
			% [graph.classes().size(), graph.frames().size()])
	graph.free()
