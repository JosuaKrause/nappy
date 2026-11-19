extends RefCounted
## The game's focus source for the crowd (`StrollerFocus`): it answers where she stands, read at
## each ask and not when it was made. She is a bare `Stroller` outside any tree; that the crowd is
## handed this source when she is handed in is held by `test_simulation_builder.gd`, and that a crowd
## follows whatever source it holds by `test_crowd_coverage.gd`.

func run(t: TestRunner) -> void:
	var her := Stroller.new()
	var focus := StrollerFocus.new(her)
	her.position = Vector2(480.0, 96.0)
	t.check(focus.where() == Vector2(480.0, 96.0), "the source answers where she stands")
	her.position = Vector2(-32.0, 1500.0)
	t.check(focus.where() == Vector2(-32.0, 1500.0),
			"and where she stands after she has walked on, asked again")
	her.free()
