extends RefCounted
## The lane mover's recycle (`LaneMover`, which every crowd body is), for a walker. A recycle is the
## mover asking the walker's strategy it is composed of (`WalkerStrategy`) for a lane and placing the
## body by the answer, so the two are the part under test together: the heading is the strategy's
## roll, and where it comes in is the mover's.
##
## On a hand-laid lattice of nine by nine junction boxes, laid as every city's streets are
## (`StreetLayout.lay()`), with a crowd field of its own centred on it (`CrowdField`): the ground and
## the patch the walker stands in, plain state, which a fake would only restate. The lattice is wider
## than the field, so every edge a walker comes in at is street. The walker is recycled through its
## lane's own event (`Lane.be_recycled()`, which its strategy calls when it cannot go on), so no
## crowd ticks and no frame passes.

## Nine junction boxes along each axis: eight periods of the lattice and a street's width.
const SIZE := 8 * Tuning.BLOCK_SIZE + 9 * Tuning.STREET_WIDTH
## How many times the one walker is recycled.
const RECYCLES := 40

func run(t: TestRunner) -> void:
	_test_a_recycled_walker_rolls_its_heading_again_and_walks_in(t)

## **A recycled walker is a fresh person walking in from the edge of the field**: each recycle rolls
## its lane again, so over the recycles of one seeded walker it comes in along both axes and both
## ways along each, the even split a walker's choice keeps; and each time it comes in from behind the
## edge of the field it walks in through, heading into the field, not out of the patch it was just
## put in.
func _test_a_recycled_walker_rolls_its_heading_again_and_walks_in(t: TestRunner) -> void:
	var map := CityMap.new(Vector2i(SIZE, SIZE))
	map.index_posts()
	StreetLayout.lay(map)
	var field := CrowdField.new(map, map.world_size() * 0.5)
	var walker := CrowdAgent.new()
	walker.setup(CrowdAgent.Kind.WALKER, map, field, 7, 0.0)
	var headings := {}
	var walking_out := 0
	for i in RECYCLES:
		walker.lane().be_recycled()
		var heading := walker.heading()
		headings[heading] = true
		var vertical := heading.y != 0.0
		var bounds := field.along_bounds(vertical)
		var along := walker.position.y if vertical else walker.position.x
		var in_from_behind := along <= bounds.x if heading.x + heading.y > 0.0 else along >= bounds.y
		walking_out += int(not in_from_behind)
	t.check(headings.size() == 4,
			"over %d recycles the walker comes in both ways along both axes (%s)"
			% [RECYCLES, headings.keys()])
	t.check(walking_out == 0,
			"and each time from behind the field's edge it walks in through (%d did not)" % walking_out)
	walker.free()
