extends RefCounted
## A shared marble bag *(pebbly-ibis, inbox #575 in feathery-lynx)*: a bag with marbles of its own
## that stands as a marble in regular bags, any number of times, and is one bag wherever it stands.
##
## What a draw cannot show at a glance: that the same shared bag in one regular bag several times,
## and in more than one regular bag, is drawn from as one bag; that it is filled again when empty,
## which the nested bag is not; that its marble is spent like a plain one; and that its draws are
## reproducible from its seed.

func run(t) -> void:
	_test_a_shared_bag_appearing_several_times_is_drawn_from_as_one_bag(t)
	_test_a_shared_bag_in_more_than_one_regular_bag_is_one_bag(t)
	_test_a_shared_bag_is_filled_again_when_empty(t)
	_test_a_shared_marble_is_spent_like_a_plain_one(t)
	_test_a_shared_bag_draws_the_same_from_the_same_seed(t)

## Three of its marbles in one regular bag, and the regular bag drawn through twice: the six draws
## are six draws of the shared bag, which hands out exactly its own marbles, once each.
func _test_a_shared_bag_appearing_several_times_is_drawn_from_as_one_bag(t) -> void:
	var shared := MarbleBag.shared(["a", "b", "c", "d", "e", "f"], 3)
	var regular := MarbleBag.new([], [shared, shared, shared], 11)
	var drawn: Array = []
	for _i in 3:
		drawn.append(regular.draw())
	t.check(shared.left() == 3 and regular.left() == 0,
			"three draws of a regular bag holding three shared marbles took three from the shared bag "
			+ "(%d left in it)" % shared.left())
	for _i in 3:
		drawn.append(regular.draw())
	drawn.sort()
	t.check(drawn == ["a", "b", "c", "d", "e", "f"],
			"and six draws are the shared bag's six marbles, none twice: %s" % [drawn])

## Two regular bags, each holding the shared bag, take from the same marbles.
func _test_a_shared_bag_in_more_than_one_regular_bag_is_one_bag(t) -> void:
	var shared := MarbleBag.shared(["a", "b", "c", "d"], 5)
	var first := MarbleBag.new([], [shared, "x"], 1)
	var second := MarbleBag.new([], [shared, shared], 2)
	var got: Array = []
	for _i in 2:
		var marble: Variant = first.draw()
		if marble != "x":
			got.append(marble)
	for _i in 2:
		got.append(second.draw())
	t.check(shared.left() == 4 - got.size(),
			"a draw of either regular bag draws the one shared bag (%d taken, %d left)"
			% [got.size(), shared.left()])
	var seen := {}
	for marble in got:
		seen[marble] = true
	t.check(seen.size() == got.size(),
			"so no marble comes out of it twice before it is empty: %s" % [got])

## Empty, it is filled again from its own marbles — where a nested bag of n is spent after n draws.
func _test_a_shared_bag_is_filled_again_when_empty(t) -> void:
	var shared := MarbleBag.shared(["a", "b"], 9)
	var regular := MarbleBag.new([], [shared], 4)
	var counts := {"a": 0, "b": 0}
	for _i in 10:
		counts[regular.draw()] += 1
	t.check(counts["a"] == 5 and counts["b"] == 5,
			"ten draws through a one-marble regular bag give its two marbles five times each, "
			+ "refilled every second draw: %s" % [counts])
	var nested := MarbleBag.new([], ["a", "b"], 9)
	var outer := MarbleBag.new([], [nested], 4)
	var nested_gave := 0
	for _i in 10:
		if outer.draw() != null:
			nested_gave += 1
	t.check(nested_gave == 2, "where a nested bag of two gives two and is gone (%d)" % nested_gave)

## A regular bag holding k shared marbles draws the shared bag exactly k times per fill, not for
## ever: the next draw is a plain marble of the next fill.
func _test_a_shared_marble_is_spent_like_a_plain_one(t) -> void:
	var shared := MarbleBag.shared(["a", "b", "c", "d", "e"], 2)
	var regular := MarbleBag.new([], [shared, shared, "x"], 6)
	for _i in 3:
		regular.draw()
	t.check(shared.drawn == 2,
			"a fill of a bag holding two shared marbles and a plain one draws the shared bag twice "
			+ "(%d)" % shared.drawn)
	t.check(regular.left() == 0, "and the fill is spent")
	for _i in 3:
		regular.draw()
	t.check(shared.drawn == 4, "the next fill draws it twice more (%d)" % shared.drawn)
	var peeked := MarbleBag.shared(["a", "b", "c"], 8)
	var through := MarbleBag.new([], [peeked, peeked], 1)
	var looked: Variant = through.peek()
	t.check(through.draw() == looked and peeked.drawn == 1,
			"a peek at it is the marble the draw takes, and the draw is one of the shared bag's")

## Rebuilding both bags from their seeds and skipping to a count draws what the first run drew next.
func _test_a_shared_bag_draws_the_same_from_the_same_seed(t) -> void:
	var marbles := []
	for i in 20:
		marbles.append(i)
	var one := MarbleBag.new([], [MarbleBag.shared(marbles, 77)], 5)
	var first: Array = []
	for _i in 30:
		first.append(one.draw())
	var two := MarbleBag.new([], [MarbleBag.shared(marbles, 77)], 5)
	two.skip(12)
	var rest: Array = []
	for _i in 18:
		rest.append(two.draw())
	t.check(rest == first.slice(12), "skipped to a count, a rebuilt bag draws on as the first did")
