extends Node

var failures: Array[String] = []
var checks := 0

func _ready() -> void:
	var suite: RefCounted = load("res://tests/test_resistance.gd").new()
	suite._test_a_trap_rechecks_the_camera_when_its_warning_expires(self)
	suite._assert_a_trap_row_is_announced_before_it_can_catch_her(self, "robber_giving_chase")
	suite._assert_a_trap_row_is_announced_before_it_can_catch_her(self, "van_guard_giving_chase")
	for id: String in ["robber_giving_chase", "van_guard_giving_chase"]:
		var row := EventCatalogue.by_id(id)
		for bearing: Vector2 in [Vector2.UP, Vector2.RIGHT]:
			var start := PendingWarning.just_out_of_sight(VisibleView.around(Vector2.ZERO),
					row, Vector2.ZERO, bearing)
			print("AFFORDABLE %s %s %s" % [id, bearing,
					suite._walk_the_trap(row, start, -Tuning.RUN_SPEED)])
	if suite._city != null:
		suite._city.free()
	for failure in failures:
		print("FAIL ", failure)
	print("Focused regression checks=%d failures=%d" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
