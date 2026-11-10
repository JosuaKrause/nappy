class_name WhereSheIs
extends RefCounted
## **Where she is this tick, for every live event and its parts**: where she stands, where her
## pram's body is, the camera's view, whether she runs, whether the baby is awake, and whether a
## district door's hold has her. `EventManager` finds her once a physics tick and tells it in one
## call carrying the tick's whole word (`tell()`); every live event is handed it when it is set up
## (`EventInstance.setup()`) and hands it on to its behaviours and its excitement source. A fact
## found once in one place and handed around (inbox #1156 in gray-dolphin): an event never looks
## her up, it is handed a point, and everything it does with the point is a distance.
##
## **Nowhere** (`nowhere()`) is what it answers before anybody has told it anything, and what a
## live event is handed where nobody names one (a rig): no position (`Vector2.INF`), no pram, an
## empty view, not running, the baby awake, no door holding her.
##
## **A live event hears the word through a handle of its own** (`heard_from_now()`), with the
## timing every event's reads are built on:
##
## - **it knows nothing of her until the next word after it was made.** A car made where she
##   stands puts its body down at once, as it would with nobody there (`EventInstance._ready()`),
##   and an officer let out after the tick's word is told where she stands by hand
##   (`EventsAhead.let_the_officers_out()`);
## - **a point it is told itself** (`see_her_at()`: the halo once a drawn frame, a pursuer set on
##   her from outside, an officer let out) **is its own until the next word**, and reaches no
##   other event;
## - **with nobody in the world nothing is told**, and a handle keeps answering the last word.
##
## The count of words and the point a handle saw are that timing's only state.

var _at := Vector2.INF
var _pram_at := Vector2.INF
var _view := Rect2()
var _running := false
var _awake := true
var _held := false
## How many words it has been told (`tell()`).
var _words := 0

## The word a handle hears (`heard_from_now()`), or null for the one the manager tells, which
## answers from its own.
var _word: WhereSheIs = null
## How many words its word had been told when the handle was made: until there are more it
## answers nowhere.
var _heard_from := 0
## A point its own event was told itself (`see_her_at()`), and how many words its word had been
## told then: answered in place of the word's own point until the next word.
var _seen_at := Vector2.INF
var _seen_on := -1

## One nobody has told anything: it answers nowhere until it is told.
static func nowhere() -> WhereSheIs:
	return WhereSheIs.new()

## **The tick's whole word**, told once a physics tick by `EventManager._tell_them_where_she_is()`
## with her in the world: her position, her pram's body (`Vector2.INF` while she carries the
## baby), the camera's view, whether she runs, whether the baby is awake, and whether a door's hold
## has her. What is not given is what nowhere answers.
func tell(at: Vector2, pram_at := Vector2.INF, view := Rect2(), running := false, awake := true,
		held := false) -> void:
	_at = at
	_pram_at = pram_at
	_view = view
	_running = running
	_awake = awake
	_held = held
	_words += 1

## **A handle for one live event**, on the same word: it answers nowhere until the word after this
## one, and a point its event sees itself (`see_her_at()`) until the next word.
func heard_from_now() -> WhereSheIs:
	var handle := WhereSheIs.new()
	handle._word = _told()
	handle._heard_from = handle._word._words
	return handle

## **Its event has seen her at `at` itself**, ahead of the next word: what it answers for `at()`
## until then. Every other event, and every other fact, keeps the word.
func see_her_at(at: Vector2) -> void:
	_seen_at = at
	_seen_on = _told()._words

## Where she stands, in world space, or `Vector2.INF` for nowhere.
func at() -> Vector2:
	var word := _told()
	if _seen_on == word._words:
		return _seen_at
	return word._at if word._words > _heard_from else Vector2.INF

## Where her pram's own body is (`Stroller.PRAM_BODY_RADIUS`, on her circumference along her
## facing), or `Vector2.INF` with no pram: nowhere, or the escape's carrying.
func pram_at() -> Vector2:
	var word := _told()
	return word._pram_at if word._words > _heard_from else Vector2.INF

## The camera's whole view this tick (`VisibleView.view`), empty where nothing has looked through
## a camera.
func view() -> Rect2:
	var word := _told()
	return word._view if word._words > _heard_from else Rect2()

## Whether she is running right now.
func is_running() -> bool:
	var word := _told()
	return word._running and word._words > _heard_from

## Whether the baby is awake right now: awake with nobody to ask.
func baby_is_awake() -> bool:
	var word := _told()
	return word._awake or word._words <= _heard_from

## Whether a district door's hold has her this tick (`EventManager.door_holding_her_at()`).
func is_held_at_a_door() -> bool:
	var word := _told()
	return word._held and word._words > _heard_from

func _told() -> WhereSheIs:
	return _word if _word else self
