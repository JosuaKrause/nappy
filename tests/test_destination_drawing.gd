@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## What a resistance contact draws (snowy-kestrel, the player: "red arrow tasks show a chalk mark at
## their destination"): the chalk mark and its touched picture belong to the pickup alone, and a
## task's destination — a rider, or a bare point (day 9's district door, day 11's mast foot, day
## 12's swing, the last night's station door) — draws no chalk picture, untouched or done. A headless
## draw pass leaves no picture to read, so this asks `ContactPoint.draws_a_mark()`, the one question
## `_draw()` asks before it draws the chalk.
##
## **The module is `ContactPoint`, alone.** It is handed the real step table's rows
## (`ResistanceSteps.all()`, plain data) the way a director hands it one (`setup()`), and is never
## added to a tree, so no city, run, director or atlas page exists here. What the director does
## with the contact (the task on offer after a pickup is read, where the red arrow ends) is the
## director's suite's and not this one's.

func run(t) -> void:
	_test_only_a_pickup_draws_a_mark_and_a_done_one_keeps_its_touched_picture(t)

## On every step of the subquest: a pickup's contact draws its chalk, untouched and done (the read
## mark keeps its touched picture where she read it); a task's destination draws nothing, untouched
## or done.
func _test_only_a_pickup_draws_a_mark_and_a_done_one_keeps_its_touched_picture(t) -> void:
	var pickups := 0
	var tasks := 0
	for step in ResistanceSteps.all():
		var contact := ContactPoint.new()
		contact.setup(step, Vector2.ZERO)
		if step.is_pickup:
			pickups += 1
			t.check(contact.draws_a_mark(), "day %d: the mark on offer draws its chalk" % step.day)
			contact.is_done = true
			t.check(contact.draws_a_mark(),
					"day %d: the read mark keeps its touched picture" % step.day)
		else:
			tasks += 1
			t.check(not contact.draws_a_mark(),
					"day %d: the task's destination draws no chalk" % step.day)
			contact.is_done = true
			t.check(not contact.draws_a_mark(),
					"day %d: a done task draws no touched chalk" % step.day)
		contact.free()
	t.check(pickups > 0 and tasks > 0,
			"the table has pickups (%d) and tasks (%d) to ask" % [pickups, tasks])
