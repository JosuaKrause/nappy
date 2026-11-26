extends RefCounted
## **`JunctionBoxes`, where the junction boxes lie along a street.** Its answers are the lattice's
## arithmetic, so the suite holds the relationships a car sent from box to box rests on (`WayOn`,
## `EventDirector`): a box holds the coordinates from where it starts to just short of where it
## ends, a car a pixel short of a box comes to that box next, one inside a box has that box behind
## it and the next one past it, and one where it leaves a box has that box behind it. Plain values
## only: it builds nothing.

func run(t: TestRunner) -> void:
	_test_a_box_holds_its_span(t)
	_test_short_of_a_box_that_box_comes_next(t)
	_test_inside_a_box_it_is_behind_her_and_the_next_one_past(t)
	_test_where_a_car_leaves_a_box_that_box_is_behind_it(t)

## Each box holds its own span, from where it starts to a pixel short of where it ends, and nothing
## a pixel outside it; its middle lies inside it.
func _test_a_box_holds_its_span(t: TestRunner) -> void:
	for index: int in [1, 3]:
		var low := JunctionBoxes.entry(index, true)
		var high := JunctionBoxes.exit(index, true)
		t.check(JunctionBoxes.holding(low) == index and JunctionBoxes.holding(high - 1.0) == index
				and JunctionBoxes.holding(JunctionBoxes.centre(index)) == index,
				"box %d holds %.0f to %.0f and its middle" % [index, low, high - 1.0])
		t.check(JunctionBoxes.holding(low - 1.0) == -1 and JunctionBoxes.holding(high) == -1,
				"and not a pixel either side of it")

## A pixel short of a box, driving either way, the box ahead is that box and the box behind the
## one before it, so a leg asked from there crosses it.
func _test_short_of_a_box_that_box_comes_next(t: TestRunner) -> void:
	for forward: bool in [true, false]:
		var along := JunctionBoxes.short_of(2, forward)
		var before := 1 if forward else 3
		t.check(JunctionBoxes.ahead(along, forward) == 2
				and JunctionBoxes.behind(along, forward) == before
				and JunctionBoxes.past(along, forward) == 2,
				"short of box 2 driving %s, box 2 is ahead and box %d behind"
				% ["up" if forward else "down", before])

## Inside a box she stands in it: it is the box ahead of her and behind her, and the first box
## wholly past her is the next one along.
func _test_inside_a_box_it_is_behind_her_and_the_next_one_past(t: TestRunner) -> void:
	var along := JunctionBoxes.centre(2)
	for forward: bool in [true, false]:
		var next := 3 if forward else 1
		t.check(JunctionBoxes.ahead(along, forward) == 2
				and JunctionBoxes.behind(along, forward) == 2
				and JunctionBoxes.past(along, forward) == next,
				"inside box 2 going %s, it is ahead and behind and box %d is past"
				% ["up" if forward else "down", next])

## Where a car leaves a box, every leg's end, that box is the one behind it, so the next leg
## starts from it.
func _test_where_a_car_leaves_a_box_that_box_is_behind_it(t: TestRunner) -> void:
	for forward: bool in [true, false]:
		var along := JunctionBoxes.exit(2, forward)
		t.check(JunctionBoxes.behind(along, forward) == 2,
				"leaving box 2 going %s at %.0f, it is behind" % ["up" if forward else "down", along])
