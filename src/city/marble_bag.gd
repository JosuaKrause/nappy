class_name MarbleBag
extends RefCounted
## Whether a torn poster brings a pursuer, drawn from a bag rather than rolled. *(PLAYTEST-125:
## "you randomly place "marbles" in a bag with the desired probability. then you draw the marbles
## when you need a random outcome ... if the bag is empty you fill it again. this has the advantage
## over a regular random number generator that it has the desired probability but feels "fair"".)*
##
## The bag holds a fixed set of marbles and each draw takes one at random and removes it, so over
## any one bag the share is exact where a roll at the same odds can run long streaks. The first
## bag is a **pre-bag** of its own set — "no pursuit" marbles only, one per tear guaranteed safe —
## and every bag after it holds the ordinary set, refilled whenever it runs empty.
##
## **For poster tears and nothing else** (statement 4). It is a class of its own so a test can hold
## the arithmetic, not a facility the rest of the game draws from.
##
## **A run's draws are reproducible from its seed**: the stream is the bag's own, and the whole
## state of a bag is how many marbles have been drawn from it, so `skip()` rebuilds a bag that a
## save or a lost day put back to an earlier draw.

var _pre_bag: Array[bool] = []
var _bag: Array[bool] = []
var _rng := RandomNumberGenerator.new()
var _left: Array[bool] = []
var _filled_once := false
## Marbles drawn so far.
var drawn := 0

## `pre_bag` fills the first bag and `bag` every one after it; `true` is a marble that brings a
## pursuer. `seed_value` is the bag's own stream.
func _init(pre_bag: Array[bool], bag: Array[bool], seed_value: int) -> void:
	_pre_bag = pre_bag.duplicate()
	_bag = bag.duplicate()
	_rng.seed = seed_value

## Draws one marble and removes it from the bag, refilling it first if it is empty.
func draw() -> bool:
	if _left.is_empty():
		_left = _bag.duplicate() if _filled_once or _pre_bag.is_empty() else _pre_bag.duplicate()
		_filled_once = true
	drawn += 1
	return _left.pop_at(_rng.randi_range(0, _left.size() - 1))

## Draws `count` marbles and throws them away — how a bag is brought back to where a run left it.
func skip(count: int) -> void:
	for _i in count:
		draw()

## Marbles still in the current bag.
func left() -> int:
	return _left.size()
