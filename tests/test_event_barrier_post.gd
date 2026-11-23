extends RefCounted
## `EventBarrierPost`, the barrier a roadblock's guards stand at and walk out of, and the far guard
## it sends off (`RoadblockFarGuard`): who stands posted, which side's guard sets off, and the walk
## of the guard at the far post once his partner starts to walk away. The post is composed as
## `EventBehaviours.compose()` composes it (`tests/roadblock_parts.gd`) over open ground, told
## where she is by hand and driven a frame at a time as the event's own tick drives it.

const STEP := 1.0 / 60.0

func run(t: TestRunner) -> void:
	_test_both_guards_stand_posted_until_one_sets_off(t)
	_test_the_guard_back_at_the_band_leaves_both_posts_manned(t)
	_test_the_far_guard_walks_off_when_his_partner_does(t)
	_test_a_barrier_restored_spent_stands_unmanned(t)

func _row() -> EventDef:
	return EventCatalogue.heated(EventCatalogue.by_id("roadblock"), EventDef.HEAT_HUNTS_LEVEL)

## The band and her, standing south of it inside his notice: the guard on her side is the south one.
func _stand(t: TestRunner, where: WhereSheIs) -> RoadblockParts:
	var band := Vector2(400.0, 0.0)
	var parts := RoadblockParts.on(t, _row(), band, WorldMap.open_ground(), where)
	where.tell(band + Vector2(0.0, 120.0))
	return parts

func _test_both_guards_stand_posted_until_one_sets_off(t: TestRunner) -> void:
	var where := WhereSheIs.nowhere()
	var parts := _stand(t, where)
	var post := parts.post
	t.check(post.chaser_side() == 0 and not post.has_left_its_body()
			and post.sides_still_posted().size() == 2 and post.save().is_empty(),
			"both guards stand at their posts and there is nothing to carry")
	var band := post.body_position()
	post.leave_the_body()
	t.check(post.has_left_its_body() and post.chaser_side() == 1,
			"the guard on her side, the south one, has set off")
	t.check(post.body_position().is_equal_approx(band),
			"and the barrier stays where it was built")
	var far_side: Array[int] = [-1]
	t.check(post.sides_still_posted() == far_side and not post.is_spent(),
			"only the guard on the other side is still posted, and nothing is spent yet")
	# Her partner has set off and has not started to walk away: the far guard stays at his post on
	# every frame of that, however long it lasts.
	var stays := true
	for _frame in int(3.0 / STEP):
		parts.tick(STEP)
		stays = stays and post.where_the_far_guard_walks() == Vector2.INF \
				and post.sides_still_posted() == far_side
	t.check(stays, "the far guard stays at his post on every frame while his partner is out and "
			+ "has not started to walk away")
	parts.release()

## The guard on her side steps back out of her radius and is back at the band: neither side is
## set off, nothing is left behind, and both guards are posted again.
func _test_the_guard_back_at_the_band_leaves_both_posts_manned(t: TestRunner) -> void:
	var where := WhereSheIs.nowhere()
	var parts := _stand(t, where)
	var post := parts.post
	var band := post.body_position()
	post.leave_the_body()
	t.check(post.has_left_its_body() and post.chaser_side() != 0, "the guard on her side has set off")
	post.back_at_the_band()
	t.check(post.chaser_side() == 0 and not post.has_left_its_body(),
			"he steps back and no side is set off, nothing is left behind")
	t.check(post.sides_still_posted().size() == 2 and post.save().is_empty(),
			"both guards are posted again and there is nothing to carry")
	t.check(post.body_position().is_equal_approx(band), "and the band's body is under him again")
	parts.release()

## The frame his partner starts to walk away, the guard at the far post sets off from it: away from
## her, at his partner's pace, gone once he is past `Tuning.OUT_OF_SIGHT` from her, with nobody left
## at the band from that frame on.
func _test_the_far_guard_walks_off_when_his_partner_does(t: TestRunner) -> void:
	var where := WhereSheIs.nowhere()
	var parts := _stand(t, where)
	var post := parts.post
	var her := where.at()
	var speed := _row().chase_speed()
	t.check(post.where_the_far_guard_walks() == Vector2.INF and not post.sides_still_posted().is_empty(),
			"the far guard stands at his post")
	parts.lose_the_guard()
	var set_off := post.where_the_far_guard_walks()
	t.check(set_off != Vector2.INF and post.sides_still_posted().is_empty(),
			"the far guard sets off from his post the frame his partner starts to leave")
	t.check(set_off.distance_to(her) > post.body_position().distance_to(her),
			"and he sets off from the far post, beyond the band from her")
	var paced := true
	var last := set_off
	var walked := 0
	while post.where_the_far_guard_walks() != Vector2.INF and walked < int(30.0 / STEP):
		parts.tick(STEP)
		walked += 1
		var now := post.where_the_far_guard_walks()
		if now == Vector2.INF:
			break
		paced = paced and now.distance_to(last) <= speed * STEP + 0.01 \
				and is_equal_approx(post.how_far_the_far_guard_has_walked(), speed * STEP * walked)
		last = now
	t.check(last.distance_to(her) > set_off.distance_to(her) and paced,
			"he walks away from her at his partner's pace (%d frames)" % walked)
	t.check(post.where_the_far_guard_walks() == Vector2.INF and post.sides_still_posted().is_empty(),
			"and he is gone, and nobody stands at the band")
	t.check(last.distance_to(her) > Tuning.OUT_OF_SIGHT - speed * STEP,
			"only once he is out of her sight (%.0fpx from her)" % last.distance_to(her))
	parts.release()

## **A barrier streamed back in after its guard was spent** (`restore()`) is only the barrier: his
## side's post empty and the far guard gone with him, and nothing walking.
func _test_a_barrier_restored_spent_stands_unmanned(t: TestRunner) -> void:
	var where := WhereSheIs.nowhere()
	var parts := _stand(t, where)
	var post := parts.post
	post.restore({"spent": true, "side": 1})
	t.check(post.chaser_side() == 1 and post.sides_still_posted().is_empty()
			and post.where_the_far_guard_walks() == Vector2.INF,
			"a band streamed back in after its guard was spent stands unmanned")
	t.check(post.save() == {"spent": true, "side": 1}, "and carries the side he left again")
	parts.release()
