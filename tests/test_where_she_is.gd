extends RefCounted
## `WhereSheIs`: the one object that says where she is, and the timing a live event's handle on it
## keeps. A handle (`heard_from_now()`) knows nothing of her until the word after the one told when
## it was made; one that hears the word told so far (`heard_so_far()`, `hear_so_far()`) answers all
## six facts at once; the point an event sees itself (`see_her_at()`) is its own until the next
## word and reaches no other handle. Plain values only: no scene, no event.

const HER := Vector2(120.0, 40.0)
const PRAM := Vector2(134.0, 40.0)
const VIEW := Rect2(Vector2(-200.0, -100.0), Vector2(640.0, 360.0))

func run(t: TestRunner) -> void:
	_test_a_handle_knows_nothing_until_the_word_after_it_was_made(t)
	_test_a_handle_that_hears_so_far_answers_the_whole_word_at_once(t)
	_test_a_car_handle_hears_the_word_told_so_far(t)
	_test_a_point_an_event_sees_itself_reaches_no_other_handle(t)

## The word with all six facts set to something other than what nowhere answers.
func _told() -> WhereSheIs:
	var word := WhereSheIs.nowhere()
	word.tell(HER, PRAM, VIEW, true, false, true)
	return word

func _is_nowhere(t: TestRunner, handle: WhereSheIs, what: String) -> void:
	t.check(handle.at() == Vector2.INF and handle.pram_at() == Vector2.INF
			and not handle.view().has_area() and not handle.is_running()
			and handle.baby_is_awake() and not handle.is_held_at_a_door(),
			"%s answers nowhere on all six facts" % what)

func _is_the_whole_word(t: TestRunner, handle: WhereSheIs, what: String) -> void:
	t.check(handle.at() == HER, "%s knows where she stands" % what)
	t.check(handle.pram_at() == PRAM, "%s knows where her pram is" % what)
	t.check(handle.view() == VIEW, "%s knows the camera's view" % what)
	t.check(handle.is_running(), "%s knows she runs" % what)
	t.check(not handle.baby_is_awake(), "%s knows the baby sleeps" % what)
	t.check(handle.is_held_at_a_door(), "%s knows a door holds her" % what)

func _test_a_handle_knows_nothing_until_the_word_after_it_was_made(t: TestRunner) -> void:
	var word := _told()
	var handle := word.heard_from_now()
	_is_nowhere(t, handle, "a handle made after the tick's word")
	word.tell(HER, PRAM, VIEW, true, false, true)
	_is_the_whole_word(t, handle, "and, once the next word is told, it")

func _test_a_handle_that_hears_so_far_answers_the_whole_word_at_once(t: TestRunner) -> void:
	var word := _told()
	var handle := word.heard_from_now()
	handle.hear_so_far()
	_is_the_whole_word(t, handle, "an officer's handle, handed the word as he is let out,")
	var later := Vector2(300.0, 300.0)
	word.tell(later)
	t.check(handle.at() == later, "and it follows the words after")

func _test_a_car_handle_hears_the_word_told_so_far(t: TestRunner) -> void:
	var word := _told()
	_is_the_whole_word(t, word.heard_so_far(), "a car's handle")
	_is_nowhere(t, WhereSheIs.nowhere().heard_so_far(), "a car's handle before any word is told,")

func _test_a_point_an_event_sees_itself_reaches_no_other_handle(t: TestRunner) -> void:
	var word := _told()
	var seeing := word.heard_so_far()
	var other := word.heard_so_far()
	var there := Vector2(-50.0, 90.0)
	seeing.see_her_at(there)
	t.check(seeing.at() == there and other.at() == HER,
			"the point one event sees is its own and the other keeps the word")
	word.tell(HER, PRAM, VIEW, true, false, true)
	t.check(seeing.at() == HER, "and the next word replaces it")
