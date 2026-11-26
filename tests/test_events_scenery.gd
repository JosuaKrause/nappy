extends RefCounted
## Events that move on their own rather than waiting for her: a flock of birds (as birds, not one
## sprite drawn often), a mobile row that follows its own path, and a crouching row that holds
## still until it bolts.
##
## The suite stands on bare `EventInstance`s it steps by hand (`_instance()`) and builds no city; what the scheduler plans
## for a flock is asked in `tests/test_events_scheduler.gd`.

const STEP := 1.0 / 60.0

func run(t: TestRunner) -> void:
	_test_a_flock_is_birds_rather_than_one_bird_drawn_often(t)
	_test_a_flock_goes_up_when_she_reaches_the_birds(t)
	_test_a_flock_walked_through_stays_in_relation_to_what_else_she_meets(t)
	_test_mobile_follows_its_path(t)
	_test_a_crouching_event_holds_still_until_it_bolts(t)


func _instance(t: TestRunner, def: EventDef, at := Vector2.ZERO,
		path := PackedVector2Array(), where: WhereSheIs = null) -> EventInstance:
	var instance := EventInstance.new()
	var surroundings := EventSurroundings.new()
	if where != null:
		surroundings.hearing(where)
	instance.setup(def, at, path, Vector2.RIGHT, surroundings)
	t.add_child(instance)
	instance.set_process(false)
	return instance

func _advance(instance: EventInstance, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		instance.step(STEP)

## Walks her past a flock at `offset` px to one side at `Tuning.WALK_SPEED`, telling the instance
## where she is every tick the way the world does, and answers how far from the middle she was on
## the first frame the birds were off the ground — `INF` if they never left it.
func _flock_flushes_at(t: TestRunner, def: EventDef, offset: float) -> float:
	var instance_where := WhereSheIs.nowhere()
	var instance := _instance(t, def, Vector2.ZERO, PackedVector2Array(), instance_where)
	var her := Vector2(-def.heard_within() - 120.0, offset)
	var answer := INF
	for _i in int(ceil(((def.heard_within() + 240.0) * 2.0 / Tuning.WALK_SPEED) / STEP)):
		instance_where.tell(her)
		instance.step(STEP)
		if not instance.is_waiting() and not instance.is_telegraphing():
			answer = her.distance_to(instance.position)
			break
		her.x += Tuning.WALK_SPEED * STEP
	instance.free()
	return answer

## Net points from walking a straight line past a flock at `offset` px to one side, at
## `Tuning.WALK_SPEED`, telling the instance where she is every tick the way the world does — the
## one thing `M174Pass`'s rig never does, and why `docs/COSTS.md` cannot price this row.
func _flock_walked_through(t: TestRunner, def: EventDef, offset: float) -> float:
	var instance_where := WhereSheIs.nowhere()
	var instance := _instance(t, def, Vector2.ZERO, PackedVector2Array(), instance_where)
	var her := Vector2(-def.heard_within() - 120.0, offset)
	var net := 0.0
	for _i in int(ceil(((def.heard_within() + 240.0) * 2.0 / Tuning.WALK_SPEED) / STEP)):
		instance_where.tell(her)
		instance.step(STEP)
		if her.distance_to(instance.position) <= def.heard_within():
			net += (instance.source().contribution_at(her) - Tuning.EXCITEMENT_DECAY_WALKING) * STEP
		her.x += Tuning.WALK_SPEED * STEP
	instance.free()
	return net

## The greatest distance between any two birds, which is the cheapest single number that changes
## when they move independently and does not when they move as one shape.
func _widest_gap_between_birds(instance: EventInstance) -> float:
	var widest := 0.0
	for a in instance.birds():
		for b in instance.birds():
			widest = maxf(widest, a.at().distance_to(b.at()))
	return widest

## **The birds move, one at a time, and they stay inside their own event.** *(M38: "the birds are
## broken — they start the flying animation but then freeze. Turn them into individual entities and
## let each fly and make them dangerous.")*
##
## Three claims, and the middle one is the one that could go wrong silently. A flock used to be one
## sprite drawn seven times at offsets derived from the instance's own position, sharing a single
## rise term — so the seven birds *could not* move relative to each other and the whole animation was
## over at the end of the telegraph. Nothing could see that: it has a duration, it emits, it departs,
## and every test it had passed while it hung in the air.
##
## - **They move apart**, which is the difference between eleven birds and one bird drawn eleven
##   times, and it is checked during the burst rather than the departure — a flock that only comes
##   alive on its way out is the original bug with a longer fuse.
## - **They stay inside the flock's spread.** The telegraph fairness contract is stated over
##   outer radius *from the instance*, so eleven moving emitters are only legal while their union
##   is inside the disc `validate_event` checked. This is the assertion that says so.
## - **The middle costs and the rim does not**, which is the whole reason a flock is worth eleven
##   sources: the price of one depends on whether you went through it or round it.
func _test_a_flock_is_birds_rather_than_one_bird_drawn_often(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("pigeon_flock")
	t.check(def.flock().spread() < def.heard_within(),
			"and the room it takes up comes out of the field it emits over, not on top of it")
	var instance_where := WhereSheIs.nowhere()
	var instance := _instance(t, def, Vector2.ZERO, PackedVector2Array(), instance_where)
	# Standing in it, so it notices her on the first step and the telegraph is the 1.7s it spends on
	# the ground about to go. Without a player position a flock waits for ever and every assertion
	# below would be made about eleven birds pecking — see the scheduler suite's
	# `_test_a_flock_is_a_place_she_can_see`.
	instance_where.tell(Vector2.ZERO)
	_advance(instance, def.telegraphs_for() + 0.2)
	t.check(not instance.is_waiting() and not instance.is_telegraphing() and not instance.is_on_its_way_out(),
			"the flock is up")

	var spread_before := _widest_gap_between_birds(instance)
	_advance(instance, 1.0)
	var spread_after := _widest_gap_between_birds(instance)
	t.check(not is_equal_approx(spread_before, spread_after),
			"the birds move relative to each other rather than as one shape (%.1f then %.1f)"
			% [spread_before, spread_after])

	# Two full seconds of wheeling: whatever they do, they may not leave the event. Reported as one
	# check with the worst reading in it, rather than one per bird per frame — thirteen hundred
	# identical passes tell a reader nothing and the one number that matters does.
	var furthest := 0.0
	for i in int(2.0 / STEP):
		instance.step(STEP)
		if instance.is_on_its_way_out():
			break
		for bird in instance.birds():
			furthest = maxf(furthest, bird.at().length())
	t.check(furthest <= def.flock().spread() + 2.0,
			"every bird stayed inside the %.0fpx flock for the whole burst (furthest %.0fpx)"
			% [def.flock().spread(), furthest])

	var middle := instance.source().contribution_at(Vector2.ZERO)
	var rim := instance.source().contribution_at(Vector2(def.heard_within() - 6.0, 0.0))
	t.check(middle > rim * 4.0,
			"walking through the middle of a flock (%.1f/s) costs far more than skirting it (%.1f/s)"
			% [middle, rim])
	t.check(instance.source().contribution_at(Vector2(def.heard_within() + 80.0, 0.0)) == 0.0,
			"and nothing at all reaches past the radius the contract was checked against")
	instance.free()

## **A flock goes up when she reaches the birds, and a clock cannot know when that is.**
## *(2026-09-20: "birds are also very late to start. they shouldn't prematurely start but they
## should basically start fluttering when I touch them not after".)* The birds are on the ground for
## the whole telegraph by construction — `EventFlock` has them pecking while
## `is_telegraphing()` — so under the clock alone a walk straight in put them up well past her.
##
## Two claims, and the second is what stops the fix being a way of deleting the telegraph. **Walked
## into, it flushes at the birds** — the flock's spread plus her own body, the distance at which she
## is among them rather than near them — within a frame of her reaching that distance and not before
## it. **Walked past without being reached, it still goes up on its clock**, so a flock she skirted
## is startled rather than ignored, and `telegraphs_for()` still means something.
##
## Stated over the walk rather than over the numbers it was written from: the rig tells where
## she is (`WhereSheIs.tell()`) every tick, which is the one thing the pass rig behind
## `docs/COSTS.md` never does and the reason that table dashes this row.
func _test_a_flock_goes_up_when_she_reaches_the_birds(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("pigeon_flock")
	var touch := def.flock().spread() + Tuning.PLAYER_BODY_RADIUS
	t.check(touch < def.notice_within(),
			"she is inside the trigger (%.0fpx) well before she is among the birds (%.0fpx)"
			% [def.notice_within(), touch])

	var straight_in := _flock_flushes_at(t, def, 0.0)
	t.check(not is_inf(straight_in), "a flock walked straight into goes up at all")
	t.close_to(straight_in, touch,
			"it goes up as she reaches the birds (%.0fpx out, against a %.0fpx flock)"
			% [straight_in, touch], Tuning.WALK_SPEED * STEP * 2.0)

	# Past the edge of the wheel and never among them: nothing fires the flush, so the telegraph is
	# what ends the wait, and it still does.
	var skirted := _flock_flushes_at(t, def, touch + 30.0)
	t.check(not is_inf(skirted) and skirted > touch,
			"a flock she skirted still goes up, on its own clock, at %.0fpx" % skirted)

## **What a flock costs is what walking through one costs, and only a walked instance can say.**
## *(2026-09-20: "but keep things in relation to each other".)* The rate on the def is shared out
## between eleven birds and the burst starts when she reaches them, so neither
## `EventDef.walk_through_cost()` nor `docs/COSTS.md` prices this row — the table dashes its pass
## columns for exactly that reason. The number is set by walking it, which makes this the place the
## relationship has to be held.
##
## **And the instance has to be in the tree.** A bare `EventInstance.new()` never gets `_ready()`,
## so `EventFlock.build()` never runs, its birds stay empty and `contribution_at()` falls back to
## the modelled ring on the def — which reads far higher than eleven birds that fly up and away
## from her actually charge. `_instance()` adds it, which is the whole reason this is a suite and
## not arithmetic.
##
## **Above a loose dog's pass**, because a flock going up in a pram's face is the louder of the two
## encounters and the rate is easy to cut too far while chasing something else. There is no upper
## bound: *"not following the procedure should be costly"* — the procedure being to wait the birds
## out, which is free — so what walking into them costs is the player's to set by feel.
func _test_a_flock_walked_through_stays_in_relation_to_what_else_she_meets(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("pigeon_flock")
	var through := _flock_walked_through(t, def, 0.0)
	var dog := M174Pass.pass_net_averaged(EventCatalogue.shipped().by_id("loose_dog"), 0.0,
			Tuning.EXCITEMENT_DECAY_WALKING, 1.0)
	t.check(through > dog,
			"walking through a flock costs %.1f, above the %.1f a loose dog's pass costs"
			% [through, dog])
	# The rim is the other half of what a flock is for: a hot spot with a wide quiet margin, which
	# is the whole reason it is eleven sources rather than one. Outside the birds the flush never
	# fires at all, so what is left out there is a fraction of the rate against a decay she is
	# earning the whole way — the line can and does come out negative, and the claim is the gap
	# rather than its sign.
	var skirted := _flock_walked_through(
			t, def, def.flock().spread() + Tuning.PLAYER_BODY_RADIUS + 30.0)
	t.check(skirted < through * 0.5,
			"skirting one costs %.1f, far less than the %.1f of walking through it"
			% [skirted, through])

func _test_mobile_follows_its_path(t: TestRunner) -> void:
	# `military_convoy` rather than the fire engine: this is about the generic path-following
	# mechanic, not about fire. At its path's end the truck is done with it (`_be_done()`): it
	# drives on out of sight, leaving, with nothing left to do on the path.
	var def := EventCatalogue.shipped().by_id("military_convoy")
	var path := PackedVector2Array([Vector2(0.0, 0.0), Vector2(300.0, 0.0)])
	var instance := _instance(t, def, Vector2.ZERO, path)
	t.check(instance.position == Vector2.ZERO, "a mobile event starts at its first waypoint")

	_advance(instance, 0.5)
	t.close_to(instance.position.x, def.speed() * 0.5, "a mobile event travels at its speed", 5.0)
	t.close_to(instance.position.y, 0.0, "a mobile event stays on its path")

	# Off the end of the route is over, whatever the nominal duration says.
	_advance(instance, 3.0)
	t.check(instance.is_gone() or instance.is_on_its_way_out(),
			"a mobile event is done with its path at its end")
	instance.free()

## The other kind of mobile event, and the reason the field exists. A telegraph that is an
## *approach* has to travel — a fire engine warns you by being audible three streets away. A
## telegraph that is a *posture* must not: the cat crouches, then bolts.
##
## Playtest 04 found the cat doing nothing, and this is half of why. Its route is one street
## wide, so at 240px/s it finished the whole crossing inside its own 1.6s telegraph — it never
## reached full intensity, and the running sprite never drew once in six milestones.
func _test_a_crouching_event_holds_still_until_it_bolts(t: TestRunner) -> void:
	var def := EventCatalogue.shipped().by_id("cat_dash")
	var path := PackedVector2Array([Vector2(0.0, 0.0), Vector2(400.0, 0.0)])
	var instance := _instance(t, def, Vector2.ZERO, path)

	_advance(instance, def.telegraphs_for() - 0.1)
	t.check(instance.position == Vector2.ZERO, "it has not moved while telegraphing")
	t.check(instance.is_telegraphing(), "and it is still telegraphing")

	_advance(instance, 0.5)
	t.check(not instance.is_telegraphing(), "then the telegraph ends")
	t.close_to(instance.position.x, def.speed() * 0.4,
			"and it bolts at its full speed from where it was crouched", 20.0)

	# The duration has to outlast the crossing, or it expires in the middle of the road.
	var crossing := float(EventDirector.CROSSING_REACH_TILES * Tuning.TILE_SIZE) * 2.0
	t.check(def.lasts_for() >= crossing / def.speed(),
			"it lives long enough (%.2fs) to cross the whole street (%.2fs)"
			% [def.lasts_for(), crossing / def.speed()])
	instance.free()
