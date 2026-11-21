extends RefCounted
## Where the scheduler places the alley mouse relative to the garbage-sack piles: beside a pile more
## often than the alley ground alone would put it.
##
## **Why it plans real days on generated maps:** the preference is the scheduler's own draw over a
## whole last day (`GameDawn`, `RuledLocationGround.scale()`), and a count of where its mice land
## needs a hundred of them; a stand-in for the dawn would hand back the answer the check asks about.
## It is a suite of its own because twelve maps planned from eight rolls each are most of its time,
## and `tests/test_events_scheduler.gd` carries the scheduler's other rules.

## The seed of the first map; the maps are `+ i * 173` apart.
const BASE_SEED := 40200

func run(t: TestRunner) -> void:
	_test_the_mouse_prefers_a_pile(t)

## **The alley mouse lands beside a garbage-sack pile more often than the ground alone would put it
## there.** The last day is planned through `GameDawn` on pinned maps, each from several rolls,
## and every mouse it stands is asked whether it is within a tile of a pile
## (`GarbageSacks.alley_pile_tiles()`). Without the preference a mouse is a uniform pick of the
## alley ground it may stand on (`RowGround.tiles_for()`), so each lands near a pile with
## the probability of that ground's share of such tiles, and the count near is a sum of those
## chances: its mean is the sum of the shares and its variance the sum of share * (1 - share). With
## the preference an alley location beside a pile draws the mouse five times as often (itself and
## `_PILE_EXTRA_COPIES` more, `RuledLocationGround.scale()`) and the mouse it draws is offered
## the tiles beside the pile first. The bar is the mean plus five standard deviations of the
## no-preference count, far enough above chance that no pinned roll passes by luck; dropping the
## preference puts the count near the mean and fails it.
func _test_the_mouse_prefers_a_pile(t: TestRunner) -> void:
	var day := Tuning.RUN_LENGTH_DAYS
	var mouse := EventCatalogue.by_id("alley_mouse")
	var mice := 0
	var near := 0
	var expected := 0.0
	var variance := 0.0
	for i in 12:
		var map := CityGenerator.generate(BASE_SEED + i * 173)
		var piles := GarbageSacks.alley_pile_tiles(map, day)
		if piles.is_empty():
			continue
		var candidates := EventScheduler.row_ground(map).tiles_for(mouse)
		var beside := {}
		for tile in candidates:
			for pile in piles:
				if maxi(absi(tile.x - pile.x), absi(tile.y - pile.y)) <= 1:
					beside[tile] = true
					break
		var share := float(beside.size()) / float(candidates.size())
		for roll in 8:
			var rng := RandomNumberGenerator.new()
			rng.seed = 1000 + roll
			for plan in GameDawn.of(DaySpec.for_day(day), rng, map).plan().placements():
				if plan.row_id() != mouse.id:
					continue
				mice += 1
				expected += share
				variance += share * (1.0 - share)
				if beside.has(map.world_to_tile(plan.placed_at())):
					near += 1
	t.check(mice > 100, "the pinned last days stand enough mice to count (%d)" % mice)
	var bar := expected + 5.0 * sqrt(variance)
	t.check(float(near) > bar,
			"mice land beside a sack pile more often than their ground alone would put them (%d of %d, chance %.0f, bar %.0f)"
			% [near, mice, expected, bar])
