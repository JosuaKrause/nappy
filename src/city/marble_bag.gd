class_name MarbleBag
extends RefCounted
## A random outcome drawn from a bag of marbles rather than rolled. *(PLAYTEST-125: "you randomly
## place "marbles" in a bag with the desired probability. then you draw the marbles when you need a
## random outcome ... if the bag is empty you fill it again. this has the advantage over a regular
## random number generator that it has the desired probability but feels "fair"".)*
##
## A bag holds a fixed set of marbles and each draw takes one at random and removes it, so over any
## one bag the share is exact where a roll at the same odds can run long streaks. A marble is any
## value — `true` for a torn poster that brings a pursuer, a row id for what she meets on her route —
## and a bag is a list of them, the same marble as often as its share asks.
##
## **It is a queue of bags.** *(quiet-yak, inbox #505: "we should have a queue of marble bags --
## normally it's just one and once its empty a new bag is created but for special events we can
## create a new bag with the desired distribution and then the current bag gets queue to be used
## again once the new bag is empty".)* Ordinarily there is one, the **ordinary** set, filled again
## whenever it runs empty. `put_in_front()` puts a special bag ahead of it, and `rig()` makes one out
## of the marbles a caller wants ensured and the bag being drawn from; the bag it interrupts keeps
## the marbles it had left and is drawn from again once the special one is empty. A
## **pre-bag** is the first such bag, put in front before the first draw: the tears' one "no
## pursuit" marble, so the run's first tear is always safe.
##
## **A marble may itself be a bag.** *(inbox #561 in coral-bunny: "a marble in a bag is itself a bag. when its drawn
## the bag marble gets drawn from and produces the actual event then the bag marble gets placed bag
## in the outer bag. this makes it very unlikely that two events from the inner bag happen right
## after each other" · asked whether a drawn bag marble goes back at once or with the next outer
## fill: "The inner bag becomes empty after n draws".)* Drawing a `MarbleBag` marble draws from it
## and answers what that draw gave, and the bag marble goes straight back into the bag it was drawn
## from. **An inner bag of n marbles is spent after n draws**: the draw that empties it takes the bag
## marble out for good — out of every bag in the queue and out of the ordinary set, so no later fill
## brings it back. So it gives exactly n events, each draw of the outer bag reaches it at its own
## share of what is left, and a bag marble left last in its bag drains its inner bag and stops rather
## than being drawn for ever. A rig that takes from a bag holding one draws from its inner bag and
## leaves the bag marble where it is (`rig()`), so a rigged bag only ever holds plain marbles and is
## spent in as many draws as its size.
##
## **A run's draws are reproducible from its seed**: the stream is the bag's own, and the marble a
## draw takes is chosen the first time it is asked about (`peek()`), so asking first and drawing
## later takes the same marble as drawing at once. With nothing put in front after the start, the
## whole state of a bag is how many marbles have been drawn from it, so `skip()` rebuilds a bag that
## a save or a lost day put back to an earlier draw.

var _ordinary: Array = []
## The bags waiting to be drawn from, the one being drawn from first. Empty until the first draw
## asks for the ordinary set, and again whenever the last bag has run empty.
var _queue: Array[Array] = []
var _rng := RandomNumberGenerator.new()
## Where in the bag being drawn from the next draw takes its marble, once `peek()` has chosen it;
## -1 before it has.
var _picked := -1
## Marbles drawn so far.
var drawn := 0

## `ordinary` fills every bag that is not put in front, and `pre_bag`, when it holds any marble, is
## drawn from first. `seed_value` is the bag's own stream.
func _init(pre_bag: Array, ordinary: Array, seed_value: int) -> void:
	_ordinary = ordinary.duplicate()
	_rng.seed = seed_value
	if not pre_bag.is_empty():
		_queue.append(pre_bag.duplicate())

## A bag of the keys of `weights` in proportion to their weights: `marbles_per_weight` marbles per
## unit of weight, rounded, and at least one of each, in `weights`' own order so a seeded draw over
## it is the same every time. A key in `counts` has that many marbles instead, its weight aside —
## for a caller that sets how often one thing comes in the bag rather than through the weight
## something else reads.
static func in_proportion(weights: Dictionary, marbles_per_weight: float,
		counts := {}) -> Array:
	var marbles := []
	for key: Variant in weights:
		var count: int = int(counts[key]) if counts.has(key) \
				else maxi(1, roundi(float(weights[key]) * marbles_per_weight))
		for _i in count:
			marbles.append(key)
	return marbles

## Whether there is anything to draw: a bag in front, or an ordinary set to fill one from.
func has_marbles() -> bool:
	return not _queue.is_empty() or not _ordinary.is_empty()

## The marble the next `draw()` gives, without taking it — for a caller that may not be able to use
## it yet and must not spend it. For a bag marble, what its own next draw gives. Null when there is
## nothing to draw.
func peek() -> Variant:
	var marble: Variant = _peek_the_marble()
	return marble.peek() if marble is MarbleBag else marble

## Draws one marble and removes it from the bag, filling a new ordinary bag first if every bag is
## empty; a bag marble is drawn from in turn and its draw is the answer. Null when there is nothing
## to draw.
func draw() -> Variant:
	var marble: Variant = _peek_the_marble()
	if _picked < 0:
		return marble
	if marble is MarbleBag:
		# Back in at once: the bag marble stays where it is until its inner bag is spent.
		var inner := marble as MarbleBag
		var given: Variant = inner.draw()
		_picked = -1
		drawn += 1
		if inner.ran_empty():
			_retire(inner)
		return given
	var bag: Array = _queue[0]
	bag.remove_at(_picked)
	_picked = -1
	if bag.is_empty():
		_queue.pop_front()
	drawn += 1
	return marble

## Whether the draws so far have emptied every bag in the queue — the last draw took the last
## marble there was, and only a fresh fill of the ordinary set could give another. A bag marble whose
## inner bag has run empty is spent and leaves the outer bag for good (`draw()`), whatever the inner
## bag's ordinary set holds.
func ran_empty() -> bool:
	return drawn > 0 and _queue.is_empty()

## Takes a spent bag marble out of every bag in the queue and out of the ordinary set, so it is
## never drawn again; a bag left empty by it is dropped from the queue.
func _retire(inner: MarbleBag) -> void:
	while _ordinary.has(inner):
		_ordinary.erase(inner)
	for i in range(_queue.size() - 1, -1, -1):
		var bag: Array = _queue[i]
		while bag.has(inner):
			bag.erase(inner)
		if bag.is_empty():
			_queue.remove_at(i)

## The marble itself the next draw takes out of the bag being drawn from — a bag marble as the bag.
func _peek_the_marble() -> Variant:
	if _queue.is_empty():
		if _ordinary.is_empty():
			return null
		_queue.append(_ordinary.duplicate())
	var bag: Array = _queue[0]
	if _picked < 0:
		_picked = _rng.randi_range(0, bag.size() - 1)
	return bag[_picked]

## Puts a bag of `marbles` in front of the one being drawn from, which keeps what it has left and is
## drawn from again once this one is empty. A marble already chosen by `peek()` from the bag being
## interrupted goes back into it untaken.
func put_in_front(marbles: Array) -> void:
	if marbles.is_empty():
		return
	_picked = -1
	_queue.push_front(marbles.duplicate())

## **Rigs the next `size` draws to hold `ensured`.** *(inbox #561 in coral-bunny: "when creating a new / rigged
## marble bag -- let's say you want to spawn in a yeller next: create a new marble bag with x
## holdings place the ensured item in the bag fill the remaining x-1 items by *drawing* from the
## currently active bag. x defines how soon we want to get the guaranteed event" · "you will be
## left with two initialized bags: 1 with x elements and one with n-x+1 elements where n is the
## number of elements that were previously in the already loaded bag".)* A bag of `size` marbles —
## `ensured` and the rest taken at random out of the bag being drawn from — goes in front, and the
## bag it was taken from keeps what is left behind it. No marble is made or lost but the ensured
## ones, so the mix over the bags either side of the rig is the mix the bag already had.
##
## The marbles are taken from the bag being drawn from, filled first if there is none; one that
## runs out part way is followed by the next bag in the queue, an ordinary one filled for it if need
## be. Taking them is not drawing: `drawn` counts only what `draw()` has handed out. **A bag marble
## is not taken whole**: the rig draws one marble from its inner bag, the way drawing it would, and
## leaves it in the bag it stands in — so the rigged bag holds `size` plain marbles and its ensured
## one comes within `size` draws ("x defines how soon we want to get the guaranteed event").
func rig(ensured: Array, size: int) -> void:
	put_in_front(ensured + _take(size - ensured.size(), []))

## **Rigs `ensured` to come after the next `before` draws and no sooner** — the two-bag shape, for an
## ensured marble that must not be met early. *(inbox #561 in coral-bunny: "day 3 have a 5 bag then a 1 bag with
## the dog" · "if you need guaranteed spacing use the day 3 trick otherwise just do the rigged bag
## directly".)* A bag of `before` marbles taken out of the bag being drawn from, none of them one of
## `ensured`, goes in front of a bag of `ensured`, in front of what is left. Like `rig()`, nothing
## is made or lost but `ensured`.
func rig_spaced(ensured: Array, before: int) -> void:
	var taken := _take(before, ensured)
	put_in_front(ensured)
	put_in_front(taken)

## Takes `count` marbles at random out of the bag being drawn from and the bags behind it, in queue
## order, leaving any that is one of `keep_out` where it is, and answers them. An empty queue is
## filled with the ordinary set first, and one more ordinary bag may be filled at the back when what
## is queued runs out; fewer than `count` come back only when even that has nothing left to give.
## A bag marble gives a draw from its inner bag and stays where it is (see `rig()`).
func _take(count: int, keep_out: Array) -> Array:
	var taken := []
	_picked = -1
	var at := 0
	# The fill an empty queue starts with is not the extra one: a queue that starts empty may be
	# filled twice, one that does not once.
	var fills_left := 2 if _queue.is_empty() else 1
	while taken.size() < count:
		if at >= _queue.size():
			if fills_left <= 0 or _ordinary.is_empty():
				break
			_queue.append(_ordinary.duplicate())
			fills_left -= 1
		var bag: Array = _queue[at]
		var open: Array[int] = []
		for i in bag.size():
			# A bag marble is open when what its inner bag gives next is.
			var next: Variant = bag[i].peek() if bag[i] is MarbleBag else bag[i]
			if not keep_out.has(next):
				open.append(i)
		if open.is_empty():
			at += 1
			continue
		var i := open[_rng.randi_range(0, open.size() - 1)]
		if bag[i] is MarbleBag:
			# Drawn from, not taken: the bag marble stays where it is until its inner bag is spent.
			var inner := bag[i] as MarbleBag
			taken.append(inner.draw())
			if inner.ran_empty():
				_retire(inner)
				# Retiring may have dropped a bag anywhere in the queue; the bags before `at` have
				# nothing open, so starting over finds the same place.
				at = 0
			continue
		taken.append(bag[i])
		bag.remove_at(i)
		if bag.is_empty():
			_queue.remove_at(at)
	return taken

## Takes one `marble` out of the bag being drawn from, filled first if there is none, without
## drawing it — for a caller that hands that marble out itself, ahead of the bag, and wants the bag's
## share of it to stay what it is. Answers whether the bag held one.
func take(marble: Variant) -> bool:
	if peek() == null:
		return false
	var bag: Array = _queue[0]
	var at := bag.find(marble)
	if at < 0:
		return false
	bag.remove_at(at)
	_picked = -1
	if bag.is_empty():
		_queue.pop_front()
	return true

## The size of every bag in the queue, the one being drawn from first. For a test, and for a scene
## that rigs a bag and wants to say what it left.
func sizes() -> Array[int]:
	var found: Array[int] = []
	for bag in _queue:
		found.append(bag.size())
	return found

## The marbles in the bag being drawn from, as a copy — what a rig has just put in front.
func bag_in_front() -> Array:
	return [] if _queue.is_empty() else (_queue[0] as Array).duplicate()

## Draws `count` marbles and throws them away — how a bag is brought back to where a run left it.
func skip(count: int) -> void:
	for _i in count:
		draw()

## Marbles still in the bag being drawn from.
func left() -> int:
	return 0 if _queue.is_empty() else (_queue[0] as Array).size()
