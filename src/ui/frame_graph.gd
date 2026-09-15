class_name FrameGraph
extends Control
## The last `FRAME_GRAPH_FRAMES` frames' own lengths as a rolling bar graph, under the developer
## readout — key `4`, the same one that toggles `_status`. See docs/TELEMETRY.md, "The debug
## view", and docs/playtests/PLAYTEST-75.md, "A rolling graph of frame times": the readout's
## `process`/`physics` lines are the engine's own once-a-second worst (M138, what those lines
## measure), so a stutter reads as a number a second late and nothing on screen shows the frames
## themselves. This draws them.
##
## **Fed from `_process`'s own `delta`, never from `Performance`.** `FrameCost` reads the engine's
## per-second maximum, which cannot say *which* frame in that second was the long one; a bar graph
## exists to answer exactly that, so it needs the frame's own length, not a number that already
## discarded 239 of the last 240 readings before this class ever saw them.
##
## **Gated exactly as the readout is, and no tighter — `main._add_frame_graph()` builds this only
## while `_debug or _readout_requested` holds, and `visible` follows `_status.visible` everywhere
## it changes (`main._set_readout_visible()`).** `push()` also checks `visible` itself, the same
## belt-and-suspenders `main.gd`'s own comments describe for the readout's text: a caller that
## somehow pushed while hidden must still cost nothing rather than quietly warming a ring nobody
## can see.
##
## Plain shapes on a `Control`, not a picture — see the **cues** skill, "A picture is an asset,
## never code", which names a debug overlay alongside a scrim as the two things that rule does not
## cover.

## How far back the ring reaches — the interval a hitch is felt over, in frames rather than
## seconds, since a rolling window of *frames* is the whole point next to `FrameCost`'s own
## once-a-second one. Also the box's own width in design pixels: one bar, one design pixel wide,
## one frame.
const FRAME_GRAPH_FRAMES := 240
const _BOX_WIDTH := float(FRAME_GRAPH_FRAMES)
const _BOX_HEIGHT := 48.0

## The frame length the 60fps reference line is drawn at, and the two-character label beside it.
const _TARGET_MS := 16.7
## The frame length that reaches the top of the box and clips beyond it — also the ceiling
## `classify()` calls lethal, the same 33.3ms (30fps) the caret and the badge would call a frame
## too slow to call smooth. Doubles as the height scale's own denominator, so a frame at exactly
## this length draws a bar reaching the box's own top edge.
const _LETHAL_MS := 33.3

## `costly`: longer than `_TARGET_MS`, the 60fps line. `lethal`: longer than `_LETHAL_MS`, the 30fps
## line. Both absolute, against the two lines the box draws, and neither against the window's
## mean: a rule relative to the mean went blind whenever every frame was slow — under a burst's
## per-frame readback nothing was twice the mean and the amber vanished *(2026-09-14, the player:
## "picture taking shouldn't hide the amber")*. A slow frame is slow whatever its neighbours did. Kept as
## an enum rather than two bare booleans so `_bar_colour()` and a test can both name the three
## outcomes instead of re-deriving them from two comparisons.
enum FrameClass { NORMAL, COSTLY, LETHAL }

## The readout's own text colour, `Color(1, 1, 1, 0.7)` on `_status` today — read off `_status`
## itself by `main._add_frame_graph()` rather than duplicated here as a second literal, so the
## ordinary bars and the reference lines can never drift from what the label beside them reads in.
var text_colour := Color(1.0, 1.0, 1.0, 0.7)

## Oldest first, newest last — a plain `Array` rather than an index-and-wrap ring, the same choice
## `FrameCost._sample_times` already makes for a window two orders of magnitude smaller than
## anything a `pop_front()` a frame would be worth optimising.
var _deltas: Array[float] = []
## Each frame's `FrameClass`, decided once when it was pushed and never again — a bar's colour is
## a fact about the frame at the moment it happened, not about the window it later ends up in.
## Classifying at draw time against the window's *current* mean recoloured old bars as the mean
## moved: *(2026-09-14, the player: "I would assume that the graph adds a row on the right and
## moves the rest to the left. but I see things on the left side changing (notably adding yellow
## lines after the fact)".)* Kept beside `_deltas` in step, both trimmed together.
var _classes: Array[int] = []

func _ready() -> void:
	custom_minimum_size = Vector2(_BOX_WIDTH, _BOX_HEIGHT)
	# A bare `Control`'s default is `MOUSE_FILTER_STOP`, unlike `_status` (a `Label`, which
	# defaults to `IGNORE`) — without this a touch landing on the box would be swallowed here
	# instead of reaching the joystick or the world underneath it.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Records one frame's length (seconds, `_process`'s own `delta`) and asks for a redraw. A no-op
## while `not visible` — no ring fed, no redraw queued — so a graph the `4` key has turned off (or
## one a release page never built) costs nothing beyond the one property read.
func push(delta: float) -> void:
	if not visible:
		return
	# Classified once, here, against the two fixed lines; the answer travels with the frame.
	_classes.append(classify(delta))
	_deltas.append(delta)
	if _deltas.size() > FRAME_GRAPH_FRAMES:
		_deltas.pop_front()
		_classes.pop_front()
	queue_redraw()

## The window, oldest first — a copy, so a caller cannot reach in and edit the ring this class is
## the only writer of.
func frames() -> Array[float]:
	return _deltas.duplicate()

## Each surviving frame's class, in the same order as `frames()` — what the bars are actually
## drawn from, so a test can check a class stays what it was when the frame was pushed.
func classes() -> Array[int]:
	return _classes.duplicate()

## The arithmetic mean of the window, in seconds (the same unit `push()` takes), `0.0` on an empty
## window — there is no instantaneous reading to fall back to the way `FrameCost`'s own window
## does, since nothing has been drawn yet either.
func mean() -> float:
	if _deltas.is_empty():
		return 0.0
	var total := 0.0
	for value in _deltas:
		total += value
	return total / _deltas.size()

## `LETHAL` beats `COSTLY` when a frame is both — a frame past `_LETHAL_MS` is "the frame is gone"
## whatever the window's own mean happened to be doing, so the worse of the two vocabulary colours
## wins rather than whichever condition is checked first. Answers against the window as it stands
## `push()` stores the answer with the frame rather than asking again at draw time, so a bar keeps
## the colour it was born with.
func classify(delta: float) -> int:
	var ms := delta * 1000.0
	if ms > _LETHAL_MS:
		return FrameClass.LETHAL
	if ms > _TARGET_MS:
		return FrameClass.COSTLY
	return FrameClass.NORMAL

func _draw() -> void:
	# A near-opaque backing, not the faint fills `DebugLayers` draws over the world it outlines —
	# this box sits over a busy street rather than over the one thing it describes, and the
	# ordinary bar colour is already the readout's own text colour at *half* alpha (0.35): tried
	# at the same faint alpha the geometry layers use, an ordinary bar all but vanished into
	# whatever traffic or pavement happened to be under it on the desktop still this milestone's
	# evidence was judged from. `0.75` reads as a panel regardless of the scene behind it, the way
	# `_status`'s own outlined text does regardless of what is behind *that*.
	draw_rect(Rect2(0.0, 0.0, _BOX_WIDTH, _BOX_HEIGHT), Color(0.0, 0.0, 0.0, 0.75))
	var window_mean := mean()
	var count := _deltas.size()
	for i in count:
		var delta: float = _deltas[i]
		# Newest at the right: the oldest of `count` samples lands at `_BOX_WIDTH - count`, the
		# newest at `_BOX_WIDTH - 1`, so an under-full window leaves the *left* side of the box
		# empty rather than stretching what it has across the whole width.
		var x := _BOX_WIDTH - count + i
		var height := clampf(delta * 1000.0 / _LETHAL_MS, 0.0, 1.0) * _BOX_HEIGHT
		draw_rect(Rect2(x, _BOX_HEIGHT - height, 1.0, height), _bar_colour(_classes[i]))
	_draw_reference_line(_TARGET_MS, "60")
	_draw_reference_line(_LETHAL_MS, "30")
	if count > 0:
		var mean_y := _BOX_HEIGHT - clampf(window_mean * 1000.0 / _LETHAL_MS, 0.0, 1.0) * _BOX_HEIGHT
		draw_line(Vector2(0.0, mean_y), Vector2(_BOX_WIDTH, mean_y), text_colour, 1.0)

func _bar_colour(frame_class: int) -> Color:
	match frame_class:
		FrameClass.LETHAL:
			return Palette.MARK_LETHAL
		FrameClass.COSTLY:
			return Palette.MARK_COSTLY
		_:
			return Color(text_colour.r, text_colour.g, text_colour.b, text_colour.a * 0.5)

## A thin line at `ms` and its two-character label, drawn inside the box's own left edge rather
## than beyond its right one — the box stays exactly `_BOX_WIDTH` wide, one design pixel per frame,
## with nothing hanging off it for a neighbour to collide with.
func _draw_reference_line(ms: float, label: String) -> void:
	var y := _BOX_HEIGHT - clampf(ms / _LETHAL_MS, 0.0, 1.0) * _BOX_HEIGHT
	draw_line(Vector2(0.0, y), Vector2(_BOX_WIDTH, y), text_colour, 1.0)
	draw_string(get_theme_default_font(), Vector2(2.0, y + 9.0), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, text_colour)
