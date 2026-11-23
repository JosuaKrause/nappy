class_name WholeWalkBag
extends UnitBags
## **One bag for the whole walk** (`DaySpec.walk_bag()`): every unit draws from the same
## `ViewBag`, so the mix is the bag's over each fill of it and not over each street, and a marble
## one street refuses is still there for the next. *(Inbox #785 in minty-lemur: "a marble bag is
## absolutely needed with empty events (nothing happening) as well. we need a fair mix".)* On its
## own stream, so drawing it takes nothing from any other. Model: no node.

var _bag: ViewBag

## One bag of `fill` (a marble -> how many of it one fill holds, `ViewBag.EMPTY` among them) on
## its own stream off `seed_value`.
func _init(fill: Dictionary, seed_value: int) -> void:
	_bag = ViewBag.new(fill, seed_value)

## Overrides UnitBags.bag_for.
func bag_for(_unit: PlacementUnit) -> ViewBag:
	return _bag
