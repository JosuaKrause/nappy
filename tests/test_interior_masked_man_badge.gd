extends RefCounted
## The screen-edge badge for the masked man with the camera interpolated, as the game runs it, from
## many places in the physics tick. Its own suite for its wall time (see `test_interior_masked_man.gd`).

const BuildingEvents := preload("res://tests/building_events.gd")
const InteriorRig := preload("res://tests/interior_rig.gd")
const MaskedManMeeting := preload("res://tests/masked_man_meeting.gd")

var _rig := InteriorRig.new()
var _meeting := MaskedManMeeting.new(_rig)

func run(t) -> void:
	await PhysicsTicks.settle(t)
	await _test_the_edge_badge_does_not_depend_on_when_in_the_physics_tick_she_starts(t)
	_rig.free_all()

## **The same checks with the camera interpolated, as the game runs it, from many places in the
## physics tick.** The case starts after a pause of a different length each time (seeded, so the
## list is the same every run) and a process frame, which fixes the interpolation fraction the
## camera's view is shifted by: the fraction the game's frames take every value of, and the one a
## slower machine took when the stairwell checks failed once on identical code. The badge must not
## depend on it. **A probabilistic extra, not the regression check** (that is `test_badge_model`'s
## deterministic case of this shape; the interior guard's own sensitivity is probabilistic: with the
## charger reset taken out, at an earlier head with the old 0.8 s timer, it failed in 2 of 3 review runs):
## it exercises the game's own interpolated camera. Walk pace is the case that failed (the masked man sets off while she is still
## walking, from inside the out-of-sight margin band).
func _test_the_edge_badge_does_not_depend_on_when_in_the_physics_tick_she_starts(t: Node) -> void:
	var pauses_ms := [0, 19, 43, 71, 83]
	var worst := 0
	var failures := 0
	var seen_fractions := {}
	for walk: Array in MaskedManMeeting.TURNS:
		for pause: int in pauses_ms:
			OS.delay_msec(pause)
			await t.get_tree().process_frame
			seen_fractions[snappedf(Engine.get_physics_interpolation_fraction(), 0.1)] = true
			var met := await _meeting.meet(t, walk, "walk", true, true)
			var ok: bool = int(met["badge_first"]) == 0 and int(met["badge_dropped"]) == 0 \
					and int(met["unseen_frames"]) > 0
			if not ok:
				failures += 1
				worst = maxi(worst, int(met["badge_dropped"]))
	t.check(failures == 0,
			"interpolated, from %d starts spread over the tick, the edge badge is up from the frame he runs until he is in view (%d failed, up to %d frames down)"
			% [pauses_ms.size() * MaskedManMeeting.TURNS.size(), failures, worst])
	t.check(seen_fractions.size() >= 3,
			"and those starts really took different interpolation fractions (%d distinct tenths)"
			% seen_fractions.size())
