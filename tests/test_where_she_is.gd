extends RefCounted
## `WhereSheIs`: the one object that says where she is, and the handle every live event hears it
## through (`handle_for_an_event()`). A handle answers the word told so far, all six facts, and
## every word after it, nowhere until the first is told; the point an event sees itself
## (`see_her_at()`) is its own until the next word and reaches no other handle. Plain values only:
## no scene. **The one combined check** is `EventInstance.setup()`'s choice of handle, which only an
## instance can show: a man made after the tick's word, built out of the tree on open ground.

const HER := Vector2(120.0, 40.0)
const PRAM := Vector2(134.0, 40.0)
const VIEW := Rect2(Vector2(-200.0, -100.0), Vector2(640.0, 360.0))

func run(t: TestRunner) -> void:
	_test_a_handle_answers_the_whole_word_told_so_far(t)
	_test_a_handle_follows_the_words_after(t)
	_test_a_handle_answers_nowhere_before_any_word(t)
	_test_a_point_an_event_sees_itself_reaches_no_other_handle(t)
	_test_a_forgotten_word_is_nowhere_for_every_handle(t)
	_test_an_event_made_after_the_tick_word_knows_where_she_is_at_once(t)

## The word with all six facts set to something other than what nowhere answers.
func _told() -> WhereSheIs:
	var word := WhereSheIs.nowhere()
	word.tell(HER, PRAM, VIEW, true, false, true)
	return word

func _test_a_handle_answers_the_whole_word_told_so_far(t: TestRunner) -> void:
	var handle := _told().handle_for_an_event()
	t.check(handle.at() == HER, "a handle made after the tick's word knows where she stands")
	t.check(handle.pram_at() == PRAM, "and where her pram is")
	t.check(handle.view() == VIEW, "and the camera's view")
	t.check(handle.is_running(), "and that she runs")
	t.check(not handle.baby_is_awake(), "and that the baby sleeps")
	t.check(handle.is_held_at_a_door(), "and that a door holds her")

func _test_a_handle_follows_the_words_after(t: TestRunner) -> void:
	var word := _told()
	var handle := word.handle_for_an_event()
	var later := Vector2(300.0, 300.0)
	word.tell(later)
	t.check(handle.at() == later and not handle.is_running(), "a handle follows the next word")

func _test_a_handle_answers_nowhere_before_any_word(t: TestRunner) -> void:
	var handle := WhereSheIs.nowhere().handle_for_an_event()
	t.check(handle.at() == Vector2.INF and handle.pram_at() == Vector2.INF
			and not handle.view().has_area() and not handle.is_running()
			and handle.baby_is_awake() and not handle.is_held_at_a_door(),
			"a handle before any word is told answers nowhere on all six facts")

func _test_a_point_an_event_sees_itself_reaches_no_other_handle(t: TestRunner) -> void:
	var word := _told()
	var seeing := word.handle_for_an_event()
	var other := word.handle_for_an_event()
	var there := Vector2(-50.0, 90.0)
	seeing.see_her_at(there)
	t.check(seeing.at() == there and other.at() == HER,
			"the point one event sees is its own and the other keeps the word")
	word.tell(HER, PRAM, VIEW, true, false, true)
	t.check(seeing.at() == HER, "and the next word replaces it")

func _test_a_forgotten_word_is_nowhere_for_every_handle(t: TestRunner) -> void:
	var word := _told()
	var before := word.handle_for_an_event()
	before.see_her_at(Vector2(5.0, 5.0))
	word.forget()
	var after := word.handle_for_an_event()
	for handle: WhereSheIs in [before, after]:
		t.check(handle.at() == Vector2.INF and handle.pram_at() == Vector2.INF
				and not handle.view().has_area() and not handle.is_running()
				and handle.baby_is_awake() and not handle.is_held_at_a_door(),
				"after the walk's word is forgotten a handle answers nowhere on all six facts")

## **Every event made after the tick's word hears it as it is made**, whatever made it: a man put
## down on foot (an officer let out, a successor set off in a step, a door's guard) has the way to
## her at once, before the next word.
func _test_an_event_made_after_the_tick_word_knows_where_she_is_at_once(t: TestRunner) -> void:
	var out := EventCatalogue.out_of_the_car(DaySpec.for_day(8))
	var told := WhereSheIs.nowhere()
	told.tell(Vector2(80.0, 0.0))
	var man := _instance(out, told)
	t.check(man.sight_line_to_her() != Vector2.ZERO,
			"a man made after the tick's word has her in sight before the next word")
	man.free()

## An instance of `def` out of the tree, hearing `where`.
func _instance(def: EventDef, where: WhereSheIs) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO, PackedVector2Array(), Vector2.RIGHT, null, null, where)
	return instance
