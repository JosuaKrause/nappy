extends "res://tests/events_shared_city.gd"
## Events that move on their own rather than waiting for her: a flock of birds (as birds, not one
## sprite drawn often), a mobile row that follows its own path, and a crouching row that holds
## still until it bolts.
##
## Split from `tests/test_events.gd` under M125, "the test suite is slow again". Extends
## `events_shared_city.gd` for `_test_a_flock_is_a_place_she_can_see`'s `_planned()`, the one test
## here that asks what the scheduler actually plans across a run rather than driving a bare
## instance by hand.

const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_a_flock_is_birds_rather_than_one_bird_drawn_often(t)
	_test_a_flock_goes_up_when_she_reaches_the_birds(t)
	_test_a_flock_walked_through_stays_in_relation_to_what_else_she_meets(t)
	_test_a_flock_is_a_place_she_can_see(t)
	_test_mobile_follows_its_path(t)
	_test_a_crouching_event_holds_still_until_it_bolts(t)


func _instance(t, def: EventDef, at := Vector2.ZERO,
		path := PackedVector2Array()) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(def, at, path)
	t.add_child(instance)
	instance.set_process(false)
	return instance

func _advance(instance: EventInstance, seconds: float) -> void:
	for i in int(round(seconds / STEP)):
		instance._process(STEP)

## Walks her past a flock at `offset` px to one side at `Tuning.WALK_SPEED`, telling the instance
## where she is every tick the way the world does, and answers how far from the middle she was on
## the first frame the birds were off the ground — `INF` if they never left it.
func _flock_flushes_at(t, def: EventDef, offset: float) -> float:
	var instance := _instance(t, def, Vector2.ZERO)
	var her := Vector2(-def.outer_radius - 120.0, offset)
	var answer := INF
	for _i in int(ceil(((def.outer_radius + 240.0) * 2.0 / Tuning.WALK_SPEED) / STEP)):
		instance.player_at = her
		instance._process(STEP)
		if not instance.is_waiting() and not instance.is_telegraphing():
			answer = her.distance_to(instance.position)
			break
		her.x += Tuning.WALK_SPEED * STEP
	instance.free()
	return answer

## Net points from walking a straight line past a flock at `offset` px to one side, at
## `Tuning.WALK_SPEED`, telling the instance where she is every tick the way the world does — the
## one thing `M174Pass`'s rig never does, and why `docs/COSTS.md` cannot price this row.
func _flock_walked_through(t, def: EventDef, offset: float) -> float:
	var instance := _instance(t, def, Vector2.ZERO)
	var her := Vector2(-def.outer_radius - 120.0, offset)
	var net := 0.0
	for _i in int(ceil(((def.outer_radius + 240.0) * 2.0 / Tuning.WALK_SPEED) / STEP)):
		instance.player_at = her
		instance._process(STEP)
		if her.distance_to(instance.position) <= def.outer_radius:
			net += (instance.contribution_at(her) - Tuning.EXCITEMENT_DECAY_WALKING) * STEP
		her.x += Tuning.WALK_SPEED * STEP
	instance.free()
	return net

## The greatest distance between any two birds, which is the cheapest single number that changes
## when they move independently and does not when they move as one shape.
func _widest_gap_between_birds(instance: EventInstance) -> float:
	var widest := 0.0
	for a in instance._flock:
		for b in instance._flock:
			widest = maxf(widest, a.at.distance_to(b.at))
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
## - **They stay inside `flock_spread`.** The telegraph fairness contract is stated over
##   `outer_radius` *from the instance*, so eleven moving emitters are only legal while their union
##   is inside the disc `validate_event` checked. This is the assertion that says so.
## - **The middle costs and the rim does not**, which is the whole reason a flock is worth eleven
##   sources: the price of one depends on whether you went through it or round it.
func _test_a_flock_is_birds_rather_than_one_bird_drawn_often(t) -> void:
	var def := EventCatalogue.by_id("pigeon_flock")
	t.check(def.flock_size > 1 and def.flock_spread > 0.0, "a flock is more than one body")
	t.check(def.flock_spread < def.outer_radius,
			"and the room it takes up comes out of the field it emits over, not on top of it")
	var instance := _instance(t, def, Vector2.ZERO)
	# Standing in it, so it notices her on the first step and the telegraph is the 1.7s it spends on
	# the ground about to go. Without a player position a flock waits for ever and every assertion
	# below would be made about eleven birds pecking — see `_test_a_flock_is_a_place_she_can_see`.
	instance.player_at = Vector2.ZERO
	_advance(instance, def.telegraph_time + 0.2)
	t.check(not instance.is_waiting() and not instance.is_telegraphing() and not instance.is_leaving,
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
		instance._process(STEP)
		if instance.is_leaving:
			break
		for bird in instance._flock:
			furthest = maxf(furthest, bird.at.length())
	t.check(furthest <= def.flock_spread + 2.0,
			"every bird stayed inside the %.0fpx flock for the whole burst (furthest %.0fpx)"
			% [def.flock_spread, furthest])

	var middle := instance.contribution_at(Vector2.ZERO)
	var rim := instance.contribution_at(Vector2(def.outer_radius - 6.0, 0.0))
	t.check(middle > rim * 4.0,
			"walking through the middle of a flock (%.1f/s) costs far more than skirting it (%.1f/s)"
			% [middle, rim])
	t.check(rim >= 0.0 and instance.contribution_at(Vector2(def.outer_radius + 80.0, 0.0)) == 0.0,
			"and nothing at all reaches past the radius the contract was checked against")
	instance.free()

## **A flock goes up when she reaches the birds, and a clock cannot know when that is.**
## *(2026-09-20: "birds are also very late to start. they shouldn't prematurely start but they
## should basically start fluttering when I touch them not after".)* The birds are on the ground for
## the whole telegraph by construction — `EventInstance._fly_the_flock()` has them pecking while
## `is_telegraphing()` — so under the clock alone a walk straight in put them up well past her.
##
## Two claims, and the second is what stops the fix being a way of deleting the telegraph. **Walked
## into, it flushes at the birds** — `flock_spread` plus her own body, the distance at which she is
## among them rather than near them — within a frame of her reaching that distance and not before
## it. **Walked past without being reached, it still goes up on its clock**, so a flock she skirted
## is startled rather than ignored, and `telegraph_time` still means something.
##
## Stated over the walk rather than over the numbers it was written from: the rig sets `player_at`
## every tick, which is the one thing the pass rig behind `docs/COSTS.md` never does and the reason
## that table dashes this row.
func _test_a_flock_goes_up_when_she_reaches_the_birds(t) -> void:
	var def := EventCatalogue.by_id("pigeon_flock")
	var touch := def.flock_spread + Tuning.PLAYER_BODY_RADIUS
	t.check(touch < def.pursues_within,
			"she is inside the trigger (%.0fpx) well before she is among the birds (%.0fpx)"
			% [def.pursues_within, touch])

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
## so `_build_the_flock()` never runs, `_flock` stays empty and `contribution_at()` falls back to
## the modelled ring on the def — which reads far higher than eleven birds that fly up and away
## from her actually charge. `_instance()` adds it, which is the whole reason this is a suite and
## not arithmetic.
##
## **Above a loose dog's pass**, because a flock going up in a pram's face is the louder of the two
## encounters and the rate is easy to cut too far while chasing something else. There is no upper
## bound: *"not following the procedure should be costly"* — the procedure being to wait the birds
## out, which is free — so what walking into them costs is the player's to set by feel.
func _test_a_flock_walked_through_stays_in_relation_to_what_else_she_meets(t) -> void:
	var def := EventCatalogue.by_id("pigeon_flock")
	var through := _flock_walked_through(t, def, 0.0)
	var dog := M174Pass.pass_net_averaged(EventCatalogue.by_id("loose_dog"), 0.0,
			Tuning.EXCITEMENT_DECAY_WALKING, 1.0)
	t.check(through > dog,
			"walking through a flock costs %.1f, above the %.1f a loose dog's pass costs"
			% [through, dog])
	# The rim is the other half of what a flock is for: a hot spot with a wide quiet margin, which
	# is the whole reason it is eleven sources rather than one. Outside the birds the flush never
	# fires at all, so what is left out there is a fraction of the rate against a decay she is
	# earning the whole way — the line can and does come out negative, and the claim is the gap
	# rather than its sign.
	var skirted := _flock_walked_through(t, def, def.flock_spread + Tuning.PLAYER_BODY_RADIUS + 30.0)
	t.check(skirted < through * 0.5,
			"skirting one costs %.1f, far less than the %.1f of walking through it"
			% [skirted, through])

## **A flock exists before it is seen, and the first frame of one is never inside the view around
## her.** *(PLAYTEST-69: "pigeons pop in on screen — they should exist before they are visible.")*
##
## The pop-in is a siting question rather than a drawing one, so this is stated over both halves of
## the siting and over the live row:
##
## - **Nothing sites it near her, on any day of the run.** A director-sited row is created at
##   `Tuning.AHEAD_LEAD_DISTANCE` (184px) in front of her, which is inside the 320px half-view on
##   every sideways heading — right for a cat, whose whole content is the three seconds it is there,
##   and the pop-in itself for eleven birds that are meant to be a patch of pavement. Checked over
##   `spawn_mode_on(day)`, the one query every placement asks, rather than over `spawn_mode` alone.
## - **The day gives it a tile**, so it is streamed in at `Tuning.EVENT_STREAM_RADIUS` — further
##   from her than the corner of the view even after the frame in which she crosses that boundary
##   at a run, which is what makes "the first drawn frame is off screen" true rather than likely.
## - **And it is on the ground, quiet, until she walks up to it.** A flock that streamed in already
##   bursting would have spent its whole event two screens away; one that emitted its full 42/s
##   while pecking would be a place nobody can walk past. The birds leave the ground only once she
##   is inside `pursues_within`, which is the telegraph contract paid in geometry.
func _test_a_flock_is_a_place_she_can_see(t) -> void:
	var def := EventCatalogue.by_id("pigeon_flock")
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		t.check(def.spawn_mode_on(day) == EventDef.SpawnMode.MAP,
				"day %d sites a flock on a tile rather than in front of her" % day)
	t.check(def.pursues_within > 0.0 and def.pursues_within < def.outer_radius,
			"it waits for her inside its own %.0fpx field (trigger %.0fpx)"
			% [def.outer_radius, def.pursues_within])

	var planned_flocks := 0
	for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
		for plan in _planned(day):
			if plan.def.id != def.id:
				continue
			planned_flocks += 1
			t.check(plan.is_placed(), "day %d's flock has ground of its own" % day)
	t.check(planned_flocks > 0, "the run's days plan flocks at all (%d)" % planned_flocks)

	# The far corner of the view, which is the furthest anything on screen can be from her.
	var corner := Tuning.VIEW_HALF_EXTENT.length()
	t.check(Tuning.EVENT_STREAM_RADIUS - Tuning.RUN_SPEED * STEP > corner,
			"a streamed row's first frame is %.0fpx away, outside the %.0fpx corner of the view"
			% [Tuning.EVENT_STREAM_RADIUS - Tuning.RUN_SPEED * STEP, corner])

	# As far off as `EventManager` ever first builds one, and five seconds of it.
	var instance := _instance(t, def, Vector2.ZERO)
	instance.player_at = Vector2(Tuning.EVENT_STREAM_RADIUS, 0.0)
	_advance(instance, 5.0)
	t.check(instance.is_waiting() and not instance.is_finished,
			"five seconds out of reach and the flock is still standing there")
	var still_grounded := true
	for bird in instance._flock:
		still_grounded = still_grounded and is_zero_approx(bird.lift)
	t.check(still_grounded, "every bird is on the pavement, which is what she can see from there")
	t.close_to(instance.current_intensity(),
			def.intensity * Tuning.TELEGRAPH_INTENSITY_FRACTION,
			"and pecking costs a fraction of what going up does", 0.1)

	# She comes inside the trigger: the notice starts here rather than at dawn.
	instance.player_at = Vector2(def.pursues_within - 10.0, 0.0)
	instance._process(STEP)
	t.check(not instance.is_waiting() and instance.is_telegraphing(),
			"walking up to it is what starts it")
	for bird in instance._flock:
		still_grounded = still_grounded and is_zero_approx(bird.lift)
	t.check(still_grounded, "and the telegraph is still eleven birds on the ground")
	# Read at the flock's own middle rather than at her: every bird is inside `flock_spread` of it
	# whatever the wheel is doing, so the two readings differ by the damping rather than by where
	# eleven birds happened to be on the frame each was taken.
	var on_the_ground := instance.contribution_at(Vector2.ZERO)

	_advance(instance, def.telegraph_time + 0.2)
	var up := 0
	for bird in instance._flock:
		if bird.lift > 0.0:
			up += 1
	t.check(up == instance._flock.size(), "then all %d of them are up" % instance._flock.size())
	t.check(instance.contribution_at(Vector2.ZERO) > on_the_ground * 3.0,
			"and the burst is what costs (%.1f/s through the middle against %.1f/s while they peck)"
			% [instance.contribution_at(Vector2.ZERO), on_the_ground])
	instance.free()

func _test_mobile_follows_its_path(t) -> void:
	# `military_convoy` rather than the fire engine: this is about the generic path-following
	# mechanic, not about fire, and it needs a row whose `_be_done()` finishes immediately rather
	# than driving on until it is out of sight — `spawns_on_finish` is what does that, which the
	# fire engine no longer carries now that `burning_building` calls it in rather than the other
	# way round (`EventDef.spawns_on_sight`).
	var def := EventCatalogue.by_id("military_convoy")
	var path := PackedVector2Array([Vector2(0.0, 0.0), Vector2(300.0, 0.0)])
	var instance := _instance(t, def, Vector2.ZERO, path)
	t.check(instance.position == Vector2.ZERO, "a mobile event starts at its first waypoint")

	_advance(instance, 0.5)
	t.close_to(instance.position.x, def.speed * 0.5, "a mobile event travels at its speed", 5.0)
	t.close_to(instance.position.y, 0.0, "a mobile event stays on its path")

	# Off the end of the route is over, whatever the nominal duration says.
	_advance(instance, 3.0)
	t.check(instance.is_finished, "a mobile event finishes at the end of its path")
	instance.free()

## The other kind of mobile event, and the reason the field exists. A telegraph that is an
## *approach* has to travel — a fire engine warns you by being audible three streets away. A
## telegraph that is a *posture* must not: the cat crouches, then bolts.
##
## Playtest 04 found the cat doing nothing, and this is half of why. Its route is one street
## wide, so at 240px/s it finished the whole crossing inside its own 1.6s telegraph — it never
## reached full intensity, and the running sprite never drew once in six milestones.
func _test_a_crouching_event_holds_still_until_it_bolts(t) -> void:
	var def := EventCatalogue.by_id("cat_dash")
	t.check(def.still_while_telegraphing, "the cat crouches rather than creeping")
	var path := PackedVector2Array([Vector2(0.0, 0.0), Vector2(400.0, 0.0)])
	var instance := _instance(t, def, Vector2.ZERO, path)

	_advance(instance, def.telegraph_time - 0.1)
	t.check(instance.position == Vector2.ZERO, "it has not moved while telegraphing")
	t.check(instance.is_telegraphing(), "and it is still telegraphing")

	_advance(instance, 0.5)
	t.check(not instance.is_telegraphing(), "then the telegraph ends")
	t.close_to(instance.position.x, def.speed * 0.4,
			"and it bolts at its full speed from where it was crouched", 20.0)

	# The duration has to outlast the crossing, or it expires in the middle of the road.
	var crossing := float(EventDirector.CROSSING_REACH_TILES * Tuning.TILE_SIZE) * 2.0
	t.check(def.duration >= crossing / def.speed,
			"it lives long enough (%.2fs) to cross the whole street (%.2fs)"
			% [def.duration, crossing / def.speed])
	instance.free()
