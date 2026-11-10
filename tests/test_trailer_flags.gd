@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## The trailer's own logic (M204): the `--parent` flag, `ZoomOutCamera`'s move and `TrailerText`'s
## fade and tree shape, each driven the way the game drives it: a `RunConfig` parsed from the words
## a trailer shot is launched with, a camera moved by the clock it is handed (`simulation_clock`, the
## physics time a saved recipe supplies) and a text node on real frames. `zoom_out_seconds()`,
## `zoom_out_delay()`, `caption_text()`, `title_card_text()` and `player_view_requested()` are
## exercised end to end by `tools/trailer.sh`'s own render rather than by this suite, the same as
## every other command-line-only dev flag (`--seed`, `--zoom`, `--route`, ...).

func run(t) -> void:
	_test_parent_accepts_mother_and_father(t)
	_test_parent_refuses_an_unknown_word(t)
	await _test_the_pull_back_fits_the_narrower_axis(t)
	await _test_the_zoom_is_interpolated_on_a_log_scale(t)
	await _test_the_centre_is_a_plain_lerp_when_the_zoom_does_not_change(t)
	await _test_the_ends_are_exactly_the_start_and_end(t)
	_test_trailer_text_builds_nothing_for_two_empty_strings(t)
	_test_trailer_text_builds_only_a_caption(t)
	_test_trailer_text_builds_only_a_title_card(t)
	_test_trailer_text_builds_both(t)
	await _test_trailer_text_fades_in_after_the_delay_then_holds(t)

# ------------------------------------------------------------------------- --parent ---

## The parent a debug build given `--parent word` shows.
func _parent(word: String) -> String:
	return RunConfig.parse(PackedStringArray(["--parent", word]), "", true).parent_override

func _test_parent_accepts_mother_and_father(t) -> void:
	t.check(_parent("mother") == "mother", "'mother' is read back unchanged")
	t.check(_parent("father") == "father", "'father' is read back unchanged")

## `--parent`'s own reasoning: "a shot of the wrong parent that said nothing about it would be the
## one failure the shot list exists to rule out" — so an unknown word is refused rather than
## silently taken as one parent or the other, the same way an unknown `--skip` word is refused.
func _test_parent_refuses_an_unknown_word(t) -> void:
	t.check(_parent("dad") == "", "an unrecognised word is refused, not guessed at")
	t.check(_parent("") == "", "the empty word is refused the same way")
	t.check(_parent("Mother") == "",
			"the match is exact, not case-insensitive — a typo must not pass silently")

# ------------------------------------------------------------------ ZoomOutCamera ---

## The clock a saved recipe hands the move (`simulation_clock`), moved by the test.
class Clock:
	var now := 0.0

	func read() -> float:
		return now

const _VIEWPORT := Vector2(1280.0, 720.0)

## The camera a zoom-out over `bounds` has made current `at` seconds into a one-second move with no
## delay, started from her camera at `start` zoomed `start_zoom`; the nodes are freed before it
## returns, so it answers the pose as `[position, zoom]`.
func _pulled_back(t, start: Vector2, start_zoom: float, bounds: Rect2, at: float) -> Array:
	var hers := Camera2D.new()
	hers.position = start
	hers.zoom = Vector2.ONE * start_zoom
	t.add_child(hers)
	hers.make_current()
	var clock := Clock.new()
	clock.now = at
	var move := ZoomOutCamera.new()
	move.simulation_clock = clock.read
	move.setup(hers, bounds, _VIEWPORT, 1.0, 0.0)
	t.add_child(move)
	# The move runs in the frame after the one that signals; the second frame has run it.
	await t.get_tree().process_frame
	await t.get_tree().process_frame
	var camera := move.get_node("ZoomOutCamera") as Camera2D
	var pose := [camera.position, camera.zoom.x]
	move.free()
	hers.free()
	return pose

## The move ends on the zoom that fits all of the bounds: whichever axis is the tighter fit wins,
## since the other axis then shows more than `bounds` rather than cropping it.
func _test_the_pull_back_fits_the_narrower_axis(t) -> void:
	var wide := await _pulled_back(t, Vector2.ZERO, 2.0, Rect2(Vector2.ZERO, Vector2(2000.0, 1000.0)), 1.0)
	t.check(is_equal_approx(wide[1], 1280.0 / 2000.0),
			"the wider axis (2000 vs 1280) is the tighter fit (got %.6f)" % wide[1])
	var tall := await _pulled_back(t, Vector2.ZERO, 2.0, Rect2(Vector2.ZERO, Vector2(1000.0, 2000.0)), 1.0)
	t.check(is_equal_approx(tall[1], 720.0 / 2000.0),
			"and the taller axis wins when the bounds are tall instead (got %.6f)" % tall[1])

## "Equal steps of log(zoom) read as a constant pull back" — asserted directly: halfway through
## the move the zoom is the geometric mean of the start and end, not their arithmetic average.
func _test_the_zoom_is_interpolated_on_a_log_scale(t) -> void:
	# Bounds that fit at 0.5, centred on (100, 0).
	var bounds := Rect2(Vector2(100.0 - 1280.0, -720.0), Vector2(2560.0, 1440.0))
	var pose := await _pulled_back(t, Vector2.ZERO, 2.0, bounds, 0.5)
	var geometric_mean := sqrt(2.0 * 0.5)
	t.check(is_equal_approx(pose[1], geometric_mean),
			"halfway is the geometric mean of 2.0 and 0.5 (got %.6f, want %.6f)"
			% [pose[1], geometric_mean])
	t.check(pose[1] != (2.0 + 0.5) / 2.0, "and not the arithmetic mean, which a linear lerp would give")

## "The centre then moves in step with how much wider the view has become" — with no zoom change
## the centre falls back to a plain lerp on the move's own weight.
func _test_the_centre_is_a_plain_lerp_when_the_zoom_does_not_change(t) -> void:
	var bounds := Rect2(Vector2(100.0, 200.0) - _VIEWPORT * 0.5, _VIEWPORT)
	var pose := await _pulled_back(t, Vector2.ZERO, 1.0, bounds, 0.5)
	t.check(pose[0].is_equal_approx(Vector2(50.0, 100.0)),
			"with no zoom change the centre is a plain lerp on the move's weight (got %s)" % pose[0])
	t.check(is_equal_approx(pose[1], 1.0), "and the zoom itself never moves")

func _test_the_ends_are_exactly_the_start_and_end(t) -> void:
	var start := Vector2(10.0, 20.0)
	var end := Vector2(500.0, -80.0)
	# Bounds that fit at 0.2, centred on `end`.
	var bounds := Rect2(end - Vector2(6400.0, 3600.0) * 0.5, Vector2(6400.0, 3600.0))
	var at_start := await _pulled_back(t, start, 2.0, bounds, 0.0)
	t.check(at_start[0].is_equal_approx(start) and is_equal_approx(at_start[1], 2.0),
			"the move's start is exactly her camera's pose (got %s)" % [at_start])
	var at_end := await _pulled_back(t, start, 2.0, bounds, 1.0)
	t.check(at_end[0].is_equal_approx(end) and is_equal_approx(at_end[1], 0.2),
			"and its end is exactly the pose that frames the bounds (got %s)" % [at_end])

# --------------------------------------------------------------------- TrailerText ---

## Neither flag given builds nothing at all, the same as `main.gd`'s own `_add_trailer_rigs()`
## expects so an ordinary run adds no node for either flag.
func _test_trailer_text_builds_nothing_for_two_empty_strings(t) -> void:
	t.check(TrailerText.build("", "") == null, "no caption and no title card builds no node")

func _test_trailer_text_builds_only_a_caption(t) -> void:
	var node := TrailerText.build("Every walk is a choice.", "")
	t.check(node != null, "a caption alone still builds a node")
	var root: Control = node.get_node("Root")
	t.check(root.get_node_or_null("Caption") != null, "the caption label is present")
	t.check(root.get_node_or_null("Title") == null, "and no title label was built")
	t.check(root.get_node_or_null("Scrim") == null, "nor its scrim")
	node.free()

func _test_trailer_text_builds_only_a_title_card(t) -> void:
	var node := TrailerText.build("", "Nappy")
	t.check(node != null, "a title card alone still builds a node")
	var root: Control = node.get_node("Root")
	t.check(root.get_node_or_null("Title") != null, "the title label is present")
	t.check(root.get_node_or_null("Scrim") != null, "and its scrim behind it")
	t.check(root.get_node_or_null("Caption") == null, "no caption label was built")
	node.free()

func _test_trailer_text_builds_both(t) -> void:
	var node := TrailerText.build("On foot.", "Nappy")
	t.check(node != null, "both flags together still build one node")
	var root: Control = node.get_node("Root")
	t.check(root.get_node_or_null("Title") != null and root.get_node_or_null("Scrim") != null
			and root.get_node_or_null("Caption") != null, "all three parts are present at once")
	node.free()

## Reads the text node's alpha after it has run its own frame (a later `process_priority`), with the
## seconds of frames it has seen: the same `delta` the node counts its fade in.
class Watcher extends Node:
	var text: TrailerText
	var elapsed := 0.0
	var seen: Array = []

	func _ready() -> void:
		process_priority = 1000

	func _process(delta: float) -> void:
		elapsed += delta
		seen.append([elapsed, (text.get_node("Root") as Control).modulate.a])

## "Both fade in over FADE_SECONDS once DELAY_SECONDS of the shot has passed and then hold" —
## asserted on real frames: at every frame the text's alpha is nothing until the delay, a linear
## rise over the fade, and full after it.
func _test_trailer_text_fades_in_after_the_delay_then_holds(t) -> void:
	var node := TrailerText.build("On foot.", "")
	t.add_child(node)
	var watcher := Watcher.new()
	watcher.text = node
	t.add_child(watcher)
	var frames := 0
	while watcher.elapsed < TrailerText.DELAY_SECONDS + TrailerText.FADE_SECONDS + 0.2 and frames < 100000:
		await t.get_tree().process_frame
		frames += 1
	var off := 0
	var wrong := 0
	var between := 0
	for sample: Array in watcher.seen:
		var expected := clampf((sample[0] - TrailerText.DELAY_SECONDS) / TrailerText.FADE_SECONDS, 0.0, 1.0)
		if not is_equal_approx(sample[1], expected):
			wrong += 1
		if sample[0] <= TrailerText.DELAY_SECONDS and sample[1] != 0.0:
			off += 1
		if sample[1] > 0.0 and sample[1] < 1.0:
			between += 1
	var last: Array = watcher.seen[watcher.seen.size() - 1]
	t.check(wrong == 0, "every frame shows the delay, then a linear fade, then full (%d of %d frames differ)"
			% [wrong, watcher.seen.size()])
	t.check(off == 0, "nothing is visible through the delay")
	t.check(between > 0, "the fade is seen part-way (%d frames)" % between)
	t.check(last[1] == 1.0, "and the text is fully visible once the fade is well past")
	watcher.free()
	node.free()
