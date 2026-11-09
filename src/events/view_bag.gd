class_name ViewBag
extends RefCounted
## **One view's bag** (inbox #1185 in gentle-owl: "each of the views has their own bag to draw from", "all possible
## events for that view multiplied by their probability/weight. empty is also a possible event"):
## every row possible in the view as many times as its weight, and the empty event, drawn without
## putting back and filled again once it runs empty, as every marble bag of the game is
## (`MarbleBag`, PLAYTEST-125). `ViewBags` makes the day's three.
##
## **A draw considers only what the location it fills accepts** (`draw()`): a row the street's
## earlier draws or the location's own ground leave invalid is not considered, and stays in the bag
## for the next location (inbox #1185 in gentle-owl: "the bag itself doesn't change just that the invalid events
## don't get considered when drawing"). And **each row's share is scaled by the location's own
## weight** (`scale`; the player's "yes" to a weight per location that scales its view bag's weights,
## inbox #1185 in gentle-owl), so a precinct's location draws its rows more often than an ordinary street's.
##
## Kept as how many of each marble are left rather than a list of marbles, since a draw weighs every
## row the location accepts by its count and its scale, and the empty marbles outnumber the rest many
## times over. Its own stream: a draw takes nothing from any other. Model: no node.

## The empty event's marble.
const EMPTY := ""

var _fill := {}
var _left := {}
var _rng := RandomNumberGenerator.new()

## A bag of `fill` (a marble -> how many of it one fill holds, `EMPTY` among them) on its own stream
## off `seed_value`.
func _init(fill: Dictionary, seed_value: int) -> void:
	_fill = fill.duplicate()
	_left = fill.duplicate()
	_rng.seed = seed_value

## **Draws one marble** among those `accepts` (the marble) answers true for, each weighed by how many
## of it are left and by `scale` (the marble, a weight; 1 for the empty event), takes it out, and
## answers it. The empty event is always accepted. `accepts` is asked of a marble only once it comes
## up, and once per marble at most: one it refuses is not considered again in this draw, which draws
## exactly as weighing only the accepted ones from the start would. A bag with nothing it accepts
## left is given a second fill beside what it still holds, so the marbles refused here stay for the
## locations after it; `EMPTY` where even that holds nothing accepted.
func draw(accepts: Callable, scale: Callable) -> String:
	var drawing := begin(accepts, scale)
	while not drawing.step():
		pass
	return drawing.drawn

## What share of one fill `marble` is: its count over the fill's.
func share_of(marble: String) -> float:
	var total := 0
	for each: String in _fill:
		total += int(_fill[each])
	return float(_fill.get(marble, 0)) / float(total) if total > 0 else 0.0

## **The same draw, a step at a time** (`Drawing.step()`): what a walk spreads over ticks. `accepts`
## may also answer null, still weighing the marble, and is asked of the same marble again on the next
## step, so one marble's ask can be spread over steps too. Asked to the end, it draws exactly what
## `draw()` would; `draw()` with an `accepts` that answers null steps it until it answers.
func begin(accepts: Callable, scale: Callable) -> Drawing:
	if _total() <= 0:
		_left = _fill.duplicate()
	return Drawing.new(self, accepts, scale)

## One draw from the bag, under way: each `step()` asks one marble, or asks again of the one still
## being weighed, and `drawn` is the marble taken,
## `EMPTY` for the empty event or a bag that ran out of marbles to ask twice over.
class Drawing extends RefCounted:
	var drawn := ""
	var _bag: ViewBag
	## The marble `_accepts` is still weighing, or null.
	var _weighing: Variant = null
	var _accepts: Callable
	var _scale: Callable
	var _refused := {}
	var _round := 0
	var _done := false

	func _init(bag: ViewBag, accepts: Callable, scale: Callable) -> void:
		_bag = bag
		_accepts = accepts
		_scale = scale

	## Asks the next marble, or asks again of the one still being weighed, and answers whether the
	## draw is over.
	func step() -> bool:
		if _done:
			return true
		if _weighing != null:
			return _answer(_weighing)
		var pick: Variant = _bag._weighed(_refused, _scale)
		if pick == null:
			if _round == 0:
				# Every marble left refused: a second fill beside what is left, so what this
				# location refused stays for the next one.
				for marble: String in _bag._fill:
					_bag._left[marble] = int(_bag._left.get(marble, 0)) + int(_bag._fill[marble])
				_round = 1
				return false
			drawn = EMPTY
			_done = true
			return true
		var marble: String = pick
		if marble == EMPTY:
			return _take(marble)
		return _answer(marble)

	## Asks `accepts` of `marble`, and takes it on yes.
	func _answer(marble: String) -> bool:
		var accepted: Variant = _accepts.call(marble)
		if accepted == null:
			_weighing = marble
			return false
		_weighing = null
		# A marble weighed over steps may have been taken by another draw from the bag meanwhile.
		if accepted and int(_bag._left.get(marble, 0)) > 0:
			return _take(marble)
		_refused[marble] = true
		return false

	func _take(marble: String) -> bool:
		_bag._left[marble] = int(_bag._left[marble]) - 1
		drawn = marble
		_done = true
		return true

	## Whether the draw is over.
	func is_done() -> bool:
		return _done


## One marble left, weighed by its count and its scale, none refused, or null where none is.
func _weighed(refused: Dictionary, scale: Callable) -> Variant:
	var total := 0.0
	var weights := {}
	for marble: String in _left:
		var count := int(_left[marble])
		if count <= 0 or refused.has(marble):
			continue
		var weight := float(count) * (1.0 if marble == EMPTY else float(scale.call(marble)))
		if weight <= 0.0:
			continue
		weights[marble] = weight
		total += weight
	if total <= 0.0:
		return null
	var roll := _rng.randf() * total
	var last: Variant = null
	for marble: String in weights:
		roll -= float(weights[marble])
		last = marble
		if roll <= 0.0:
			return marble
	return last

func _total() -> int:
	var total := 0
	for marble: String in _left:
		total += int(_left[marble])
	return total
