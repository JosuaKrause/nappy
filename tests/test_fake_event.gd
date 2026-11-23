extends RefCounted
## **`FakeEvent.answering_as()` copies every answer the fake gives**, so a suite that hands a
## look a copy of a real arrival cannot measure less than the game draws because the fake gained
## a question the copy leaves at its quiet default. The two sets compared are read off
## `tests/fake_event.gd` itself: the questions it overrides (each carries an `## Overrides
## EventInstance.x.` line) and the questions `answering_as()` asks the instance it copies. A suite
## that reads source is the exception here, since what is held is the fake's own completeness and
## no behaviour of the fake could show it.

## The overridden answers `answering_as()` leaves out, each for its reason: a spread's points are
## asked by offset, so a copy of one answer would not be a copy of the spread, and the two
## `add_` calls record what a look put beside it and answer nothing, and `core_reaches` is asked
## about a point and answers what the suite sets, so no copy of one answer is a copy of the disc.
const NOT_COPIED: Array[String] = ["spread_at", "add_beside_it", "add_slices_beside_it",
		"core_reaches"]

const SOURCE := "res://tests/fake_event.gd"

func run(t: TestRunner) -> void:
	_test_every_answer_the_fake_gives_is_copied(t)

func _test_every_answer_the_fake_gives_is_copied(t: TestRunner) -> void:
	var source := FileAccess.get_file_as_string(SOURCE)
	var copy_from := source.find("static func answering_as(")
	var copy_to := source.find("\nfunc tick(", copy_from)
	t.check(copy_from >= 0 and copy_to > copy_from, "answering_as() is found in the fake's source")
	var copy_body := source.substr(copy_from, copy_to - copy_from)
	var overridden := _matches("## Overrides EventInstance\\.(\\w+)\\.", source)
	var copied := _matches("instance\\.(\\w+)\\(", copy_body)
	t.check(overridden.size() > 20, "the fake overrides many answers (%d)" % overridden.size())
	t.check(copied.size() > 20, "answering_as() copies many answers (%d)" % copied.size())
	var missing: Array[String] = []
	for answer in overridden:
		if not copied.has(answer) and not NOT_COPIED.has(answer):
			missing.append(answer)
	t.check(missing.is_empty(), "every answer the fake overrides is copied or named as left out: "
			+ "%s are not" % [missing])
	var invented: Array[String] = []
	for answer in copied:
		if not overridden.has(answer):
			invented.append(answer)
	t.check(invented.is_empty(), "every question answering_as() asks is one the fake answers: "
			+ "%s are not" % [invented])
	for answer in NOT_COPIED:
		t.check(overridden.has(answer) and not copied.has(answer),
				"%s is left out of the copy and is an answer the fake gives" % answer)

## The first group of every match of `pattern` in `text`, each once.
func _matches(pattern: String, text: String) -> Array[String]:
	var regex := RegEx.new()
	regex.compile(pattern)
	var found: Array[String] = []
	for hit in regex.search_all(text):
		var name := hit.get_string(1)
		if not found.has(name):
			found.append(name)
	return found
