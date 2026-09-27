extends RefCounted
## The trailer's own pure logic (M204): `DevFlags.parse_parent()`, `ZoomOutCamera`'s geometry and
## `TrailerText`'s fade and tree shape. Each is a getter or a builder deliberately kept out of the
## command-line-reading half of `DevFlags` — `parse_parent()`'s own doc says why — so a test can
## drive it directly rather than needing a second process launched with different argv, the same
## split `_validate_skip_words()`/`_readout_from_query()` already use in `tests/test_presentation_mode.gd`.
## `parent_override()`, `zoom_out_seconds()`, `zoom_out_delay()`, `caption_text()`,
## `title_card_text()` and `player_view_requested()` themselves read `OS.get_cmdline_user_args()`
## directly and are exercised end to end by `tools/trailer.sh`'s own render rather than by this
## suite, the same as every other command-line-only dev flag (`--seed`, `--zoom`, `--route`, ...).

func run(t) -> void:
	_test_parse_parent_accepts_mother_and_father(t)
	_test_parse_parent_refuses_an_unknown_word(t)
	_test_overview_zoom_fits_the_narrower_axis(t)
	_test_pose_at_interpolates_the_zoom_on_a_log_scale(t)
	_test_pose_at_holds_still_when_the_zoom_does_not_change(t)
	_test_pose_at_at_the_ends_is_exactly_the_start_and_end(t)
	_test_trailer_text_builds_nothing_for_two_empty_strings(t)
	_test_trailer_text_builds_only_a_caption(t)
	_test_trailer_text_builds_only_a_title_card(t)
	_test_trailer_text_builds_both(t)
	_test_trailer_text_opacity_fades_in_after_the_delay_then_holds(t)

# ------------------------------------------------------------ DevFlags.parse_parent ---

func _test_parse_parent_accepts_mother_and_father(t) -> void:
	t.check(DevFlags.parse_parent("mother") == "mother", "'mother' is read back unchanged")
	t.check(DevFlags.parse_parent("father") == "father", "'father' is read back unchanged")

## `--parent`'s own reasoning: "a shot of the wrong parent that said nothing about it would be the
## one failure the shot list exists to rule out" — so an unknown word is refused rather than
## silently taken as one parent or the other, the same way an unknown `--skip` word is refused.
func _test_parse_parent_refuses_an_unknown_word(t) -> void:
	t.check(DevFlags.parse_parent("dad") == "", "an unrecognised word is refused, not guessed at")
	t.check(DevFlags.parse_parent("") == "", "the empty word is refused the same way")
	t.check(DevFlags.parse_parent("Mother") == "",
			"the match is exact, not case-insensitive — a typo must not pass silently")

# ------------------------------------------------------------------ ZoomOutCamera ---

## `DevRig.make_overview_camera()`'s own zoom: whichever axis is the tighter fit wins, since the
## other axis then shows more than `bounds` rather than cropping it.
func _test_overview_zoom_fits_the_narrower_axis(t) -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(2000.0, 1000.0))
	var viewport := Vector2(1280.0, 720.0)
	var zoom := ZoomOutCamera.overview_zoom(bounds, viewport)
	t.check(is_equal_approx(zoom, 1280.0 / 2000.0),
			"the wider axis (2000 vs 1280) is the tighter fit (got %.6f)" % zoom)

	var tall_bounds := Rect2(Vector2.ZERO, Vector2(1000.0, 2000.0))
	var tall_zoom := ZoomOutCamera.overview_zoom(tall_bounds, viewport)
	t.check(is_equal_approx(tall_zoom, 720.0 / 2000.0),
			"and the taller axis wins when the bounds are tall instead (got %.6f)" % tall_zoom)

## "Equal steps of log(zoom) read as a constant pull back" — asserted directly: halfway through
## the move the zoom is the geometric mean of the start and end, not their arithmetic average.
func _test_pose_at_interpolates_the_zoom_on_a_log_scale(t) -> void:
	var pose := ZoomOutCamera.pose_at(0.5, Vector2.ZERO, 2.0, Vector2(100.0, 0.0), 0.5)
	var geometric_mean := sqrt(2.0 * 0.5)
	t.check(is_equal_approx(pose.z, geometric_mean),
			"halfway is the geometric mean of 2.0 and 0.5 (got %.6f, want %.6f)"
			% [pose.z, geometric_mean])
	t.check(pose.z != (2.0 + 0.5) / 2.0, "and not the arithmetic mean, which a linear lerp would give")

## "The centre then moves in step with how much wider the view has become" — held still (no
## `start_zoom`/`end_zoom` difference) the centre falls back to a plain lerp on `weight` alone.
func _test_pose_at_holds_still_when_the_zoom_does_not_change(t) -> void:
	var pose := ZoomOutCamera.pose_at(0.25, Vector2.ZERO, 1.0, Vector2(100.0, 200.0), 1.0)
	t.check(is_equal_approx(pose.x, 25.0) and is_equal_approx(pose.y, 50.0),
			"with no zoom change the centre is a plain lerp on weight alone (got %s)"
			% Vector2(pose.x, pose.y))
	t.check(is_equal_approx(pose.z, 1.0), "and the zoom itself never moves")

func _test_pose_at_at_the_ends_is_exactly_the_start_and_end(t) -> void:
	var start := Vector2(10.0, 20.0)
	var end := Vector2(500.0, -80.0)
	var at_start := ZoomOutCamera.pose_at(0.0, start, 2.0, end, 0.2)
	t.check(Vector2(at_start.x, at_start.y).is_equal_approx(start) and is_equal_approx(at_start.z, 2.0),
			"weight 0.0 is exactly the start pose (got %s)" % at_start)
	var at_end := ZoomOutCamera.pose_at(1.0, start, 2.0, end, 0.2)
	t.check(Vector2(at_end.x, at_end.y).is_equal_approx(end) and is_equal_approx(at_end.z, 0.2),
			"weight 1.0 is exactly the end pose (got %s)" % at_end)

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

## "Both fade in over FADE_SECONDS once DELAY_SECONDS of the shot has passed and then hold" —
## asserted at four points: nothing before the delay, rising during the fade, and full afterward.
func _test_trailer_text_opacity_fades_in_after_the_delay_then_holds(t) -> void:
	t.check(TrailerText.opacity_at(0.0) == 0.0, "nothing visible at the very start")
	t.check(TrailerText.opacity_at(TrailerText.DELAY_SECONDS) == 0.0,
			"still nothing right at the end of the delay, where the fade begins")
	var midpoint := TrailerText.DELAY_SECONDS + TrailerText.FADE_SECONDS / 2.0
	t.check(is_equal_approx(TrailerText.opacity_at(midpoint), 0.5),
			"halfway through the fade it is half visible (got %.4f)" % TrailerText.opacity_at(midpoint))
	var after := TrailerText.DELAY_SECONDS + TrailerText.FADE_SECONDS + 10.0
	t.check(TrailerText.opacity_at(after) == 1.0, "fully visible once the fade is well past")
