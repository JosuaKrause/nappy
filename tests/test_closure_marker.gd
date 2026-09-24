extends RefCounted
## A closure's cause lies across the street it closes, whichever way the street runs. Headless runs
## never call `_draw()` (the **verify** skill), so this pins the two queries
## `ClosureMarker._draw_cause()` draws from — which picture, and where it stands — against the
## baked pictures' own sizes. Whether each picture reads as the thing it is lying the right way is
## a screenshot's question: the sheets under `docs/evidence/m187-closures-across-2026-09-23/`.

func run(t) -> void:
	_test_each_street_axis_has_its_own_picture(t)
	_test_a_cause_is_centred_on_the_street_it_closes(t)

## Across a north-south street a cause lies left to right, across an east-west one it lies down
## the screen, and the two are different pictures rather than one drawn for both.
func _test_each_street_axis_has_its_own_picture(t) -> void:
	for kind: int in ClosureMarker.CAUSES:
		var across := ClosureMarker.cause_picture(kind, true)
		var down := ClosureMarker.cause_picture(kind, false)
		t.check(down != &"" and down != across,
				"%s has its own picture for an east-west street (%s)"
				% [RoadClosure.display_name(kind), down])
		var across_size := AtlasLibrary.native_size(across)
		var down_size := AtlasLibrary.native_size(down)
		t.check(across_size.x > across_size.y,
				"%s's north-south picture lies across the screen (%s)"
				% [RoadClosure.display_name(kind), across_size])
		t.check(down_size.y > down_size.x,
				"%s's east-west picture lies down the screen (%s)"
				% [RoadClosure.display_name(kind), down_size])
	t.check(ClosureMarker.cause_picture(RoadClosure.Kind.CORDON, true) == &""
			and ClosureMarker.cause_picture(RoadClosure.Kind.CORDON, false) == &"",
			"a cordon leaves nothing in the road on either axis")

## Lying down the screen, a cause covers the same length of road its across picture spans, up
## from its feet — so the picture has to be at least that tall, and its feet have to stand far
## enough below the street's middle for that length to be centred on it, as the across picture is.
func _test_a_cause_is_centred_on_the_street_it_closes(t) -> void:
	for kind: int in ClosureMarker.CAUSES:
		var label := RoadClosure.display_name(kind)
		var lie := float(AtlasLibrary.native_size(ClosureMarker.cause_picture(kind, true)).x)
		var tall := float(AtlasLibrary.native_size(ClosureMarker.cause_picture(kind, false)).y)
		t.check(tall >= lie,
				"%s's east-west picture (%.0fpx tall) holds the %.0fpx of road it lies along"
				% [label, tall, lie])
		var feet := ClosureMarker.cause_feet(kind, false)
		var middle := feet.y - lie * 0.5
		t.check(is_zero_approx(feet.x) and is_zero_approx(middle),
				"%s's length of road down the screen is centred on the street (%.1f off)"
				% [label, middle])
		t.check(ClosureMarker.cause_feet(kind, true) == Vector2.ZERO,
				"%s across the screen stands on the street's middle" % label)
