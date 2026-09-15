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

## A ten-frame window at a steady 10ms sets the mean at 0.010s, so 0.025s (25ms, past twice that
## mean but short of 33.3ms) classes costly, 0.040s (40ms, past 33.3ms regardless of the mean)
## classes lethal, and 0.011s (11ms, past neither line) classes neither.
func _test_classification_of_an_ordinary_a_costly_and_a_lethal_frame(t) -> void:
	var graph := FrameGraph.new()
	for i in range(10):
		graph.push(0.010)
	t.check(is_equal_approx(graph.mean(), 0.010),
			"the window's mean is the steady 10ms every frame in it was pushed at (%.4f)" % graph.mean())
	t.check(graph.classify(0.011) == FrameGraph.FrameClass.NORMAL,
			"11ms is past neither twice the mean nor the 33.3ms lethal line")
	t.check(graph.classify(0.025) == FrameGraph.FrameClass.COSTLY,
			"25ms is past twice the 10ms mean and short of the 33.3ms lethal line")
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
