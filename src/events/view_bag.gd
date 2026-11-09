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
	if _total() <= 0:
		_left = _fill.duplicate()
	var refused := {}
	for _round in 2:
		while true:
			var pick: Variant = _weighed(refused, scale)
			if pick == null:
				break
			var marble: String = pick
			if marble == EMPTY or accepts.call(marble):
				_left[marble] = int(_left[marble]) - 1
				return marble
			refused[marble] = true
		if _round == 0:
			for marble: String in _fill:
				_left[marble] = int(_left.get(marble, 0)) + int(_fill[marble])
	return EMPTY

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
