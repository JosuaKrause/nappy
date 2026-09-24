class_name InteriorEvents
extends Node
## The escape's first section, inside the building: a mouse, a masked man coming up one stairwell
## again and again, a fire on the other, steam in the basement, and the explosions going off
## outside.
##
## **The smallest thing that can host an `EventInstance`**, and deliberately not an `EventManager`.
## That class is a day: a plan streamed around a walking player, a director owing rows ahead of
## her, one-shots, scars, successors, detentions and city-wide announcements, all of it stated over
## a `CityMap` this building does not have. What is wanted here is *"relatively minimal"* — at most
## one of each — so what this does is the four things an instance actually needs from whatever owns
## it: put it in the world, tell it where she is, sum what it contributes, and fire the hard fail
## when one of them reaches her. Everything else about an event — the telegraph, the field, the
## path, the pursuit, the drawing — is `EventInstance`'s own and works unchanged indoors. And what
## everything *around* the events reads — the badge, the halo, the debug view, the run log — is
## `instances()`, which this answers under the name `EventManager` does; see there.
##
## **The pressure is the same two meters.** `InteriorScene` is a `WorldContext` and asks this for
## its excitement, so the baby is woken by a mouse in the basement in exactly the way she is woken
## by a dog on a pavement.
##
## **The explosions have no position at all.** Outdoors they are placed on streets and leave
## craters where they land; indoors there is no street to land on and nothing to see, so what an
## explosion *is* in here is a beat: every `Tuning.FINALE_EXPLOSION_INTERVAL` the windows flash and
## the meter takes a hit, wherever in the building she is standing. That is the same row's field
## reduced to the only part of it that reaches through a wall.
##
## **And between them, light with no noise behind it.** A distant flash — on average about one a
## second and a third, never closer than a tenth of a second or further than five — lights every
## window exactly as a bang does and costs nothing at all, see `_light_the_far_windows()`. It is
## the night outside; the bangs are what she is charged for.

## How much an explosion outside costs her, as points on the meter, one bang at a time. Taken from
## the row's own field rather than invented: `finale_explosion` emits its `intensity` for its
## `duration`, and a building is not a place she can walk out of the blast's way in, so what lands
## indoors is that whole product — one charge, at the moment of the bang.
##
## **Applied through a source rather than written at the baby.** Excitement is a pure query
## (`docs/EVENTS.md`, "Excitement is a pure query") and nothing may write to `Baby.excitement` from
## outside, so the bang is a live `EventInstance` of the same row, standing where she is, for as
## long as the row says it lasts.
const _EXPLOSION_ID := "finale_explosion"
const _MOUSE_ID := "alley_mouse"
const _PURSUER_ID := "masked_pursuer"
const _STEAM_ID := "basement_steam"
const _FIRE_ID := "burning_building"

## One steam vent: where it stands, how often it blows, how long until it does again, and the
## floor grate it blows out of. A vent is not an event — what is an event is one blow, which this
## spawns and the instance owns to its end. While a vent is between blows there is no instance, so
## no body and no field, which is the whole of *"while it is off it has no body and costs
## nothing"*.
##
## **But the grate is there the whole time.** A gate she can only see while it is shut is a gate she
## finds by walking into its notice; a vent that lies in the corridor blowing or not is one she can
## see from the corner and time. So the grate is floor owned by the vent rather than part of any
## blow's picture — `EventInstance.STEAM_GRATE` — lying on the vent's own site, and the blow's
## cloud rises out of it.
class Vent extends RefCounted:
	var at := Vector2.ZERO
	var period := 0.0
	var until_the_next_blow := 0.0
	var grate: Sprite2D = null

var _interior: InteriorScene
var _instances: Array[EventInstance] = []
var _player: Node2D
var _hard_failed := false
var _seed := 0
var _until_the_next_explosion := 0.0
## The basement's vents, in the order she meets them walking the corridor. Rebuilt by `restart()`.
var _vents: Array[Vent] = []
## Seconds until the next distant flash in the hallway windows, and the stream the waits are drawn
## from. **Its own stream, seeded from the same run seed**, so a seed replays the same night and no
## draw here can ever move a placement: the placement rolls happen on a local generator inside
## `restart()`, and a shared one would make how often the windows flash a thing that decides where
## the fire is.
var _until_the_next_distant_flash := 0.0
var _flashes := RandomNumberGenerator.new()
## The masked man currently on the stairs, or null between his runs. Held so this can tell *his*
## instance retiring from any other row's — see `_send_the_masked_man_again()`.
var _pursuer: EventInstance = null
## Seconds until the next masked man comes up the shaft, counted only while there is none.
var _until_the_next_pursuer := 0.0
## Which stairwell the fire closes, and it is **always the left one**. *(2026-09-19: "there should
## be a fire on the left like it is right now but the top floor right side should be completely
## blocked off with rubble.")* The two have to agree: the rubble shuts the right stairwell off the
## top floor, so a fire that rolled onto the right as well would leave her nothing at all to walk
## down from her own door. The masked man takes the other shaft — which is the whole of why the
## fire is worth having: the way past a fire is the other egress, and the other egress has
## somebody on it.
const _BURNING_SIDE := "left"
## The shaft the masked man runs, which is the one the fire did not take.
const _PURSUED_SIDE := "right"

## Holds the `events` page for as long as this is in the tree, as `EventManager` does for a day:
## every blow, the fire, the mouse and the masked man draw from it, and the vents' grates are
## fetched from it the moment they are placed. In a booted escape it is a count on a page
## `main.RESIDENT_GROUPS` already holds; the pairing is what proves the page is there.
func _enter_tree() -> void:
	AtlasLibrary.acquire(EventInstance.ATLAS_GROUP)

func _exit_tree() -> void:
	AtlasLibrary.release(EventInstance.ATLAS_GROUP)

func setup(interior: InteriorScene, rng: RandomNumberGenerator) -> void:
	_interior = interior
	_interior.events = self
	_seed = rng.randi()
	restart()

## Clears whatever is standing and places the section again — called once at setup and again every
## time the section is lost. Deterministic from the run seed, so a retry is the same building
## rather than an easier one; `_seed` is drawn once in `setup()` and reused, not redrawn here.
func restart() -> void:
	for instance in _instances:
		instance.queue_free()
	_instances.clear()
	_hard_failed = false
	set_physics_process(true)
	_until_the_next_explosion = Tuning.FINALE_EXPLOSION_INTERVAL
	_pursuer = null
	_until_the_next_pursuer = Tuning.FINALE_PURSUER_RESPAWN_SECONDS
	_flashes.seed = _seed
	_until_the_next_distant_flash = _wait_for_the_next_distant_flash()
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	_place_the_fire(rng)
	_place_the_masked_man()
	_place_the_basement(rng)

## Everything in the building stops, because she is not in it any more: she has walked out of the
## service exit and section two is running. Called by `main` when the city section starts.
##
## **Without this the building goes on playing to an empty map** — the vents keep blowing, the
## windows keep flashing and a masked man comes up the shaft every few seconds for the rest of the
## sequence, none of it seen and all of it in the run log. `restart()` is what brings it back, and
## it is called on every entry into section one, fresh or retried.
func stand_down() -> void:
	set_physics_process(false)
	for instance in _instances:
		instance.queue_free()
	_instances.clear()
	_pursuer = null

## Which stairwell is shut. Read by `tests/test_interior.gd`, which asserts the other one is still
## walkable — *"there might be a fire on one staircase forcing us to use the other staircase (all
## buildings have two egresses)"* is a statement about both of them, not only the burning one.
func burning_side() -> String:
	return _BURNING_SIDE

## Everything standing in the building right now. **This and `total_excitement_at()` are the whole
## of what the world's readers ask of an event source** — the screen-edge badge, the excitement
## halo, the debug view, the readout and the run log's observer — so answering them under the same
## names `EventManager` does is what makes the building show what the city shows, with no adapter
## between them. *("The escape shouldn't behave any different than the rest of the game.")*
func instances() -> Array[EventInstance]:
	return _instances

# ----------------------------------------------------------------- placement ---

## The fire, on the **inner** cell of an intermediate floor's level approach.
##
## A level approach is two cells of `F` below its door. Standing on the outer one — the door's own
## cell — the fire's body would close the way out of the stairwell as well as the way down it, and
## the answer to it would be walking back up rather than stepping through a door. One cell further
## in it closes exactly the flight that approach leads onto, and every door in the shaft stays
## reachable: the way past is into the hallway and along to the other shaft, which is the reason
## the two stairwells are at opposite ends of the hallway in the first place.
##
## Its blocking reach is its own 30px body plus her 14px, and the door tile is 64px from the cell
## it stands on, so a door arrival lands clear of it.
func _place_the_fire(rng: RandomNumberGenerator) -> void:
	var approaches := _inner_floor_approaches(_BURNING_SIDE)
	if approaches.is_empty():
		return
	var at: Vector2i = approaches[rng.randi_range(0, approaches.size() - 1)]
	_spawn(_without_its_aftermath(EventCatalogue.by_id(_FIRE_ID)), _interior.tile_to_world(at))

## The masked man, at the foot of the stairwell the fire did not take, running its whole height.
##
## **One of him at a time, and there is always another.** *(2026-09-19: "then the pursuing guy
## should respawn forcing to switch the side again.")* The fire shuts the left shaft part way down
## and the rubble shuts the right one off the top floor, so the walk is left, across a hallway,
## right — and a man who was spent after one run left the second half of that with nothing in it.
## `_send_the_masked_man_again()` owns the clock; this is only the placement, called again with a
## fresh instance each time so the telegraph, the wait and the line are the ones the first man had.
##
## **His path is the staircase itself**, asked of the map rather than drawn between the two
## landings: the landings alternate between the grammar's two `F` columns, so a straight line from
## one to the other crosses the background and the solid `c`/`C`/`b` sides and meets each flight
## wherever it happens to cut it. `InteriorScene.stairwell_walk()` hands back the shaft's own
## branchless walk — the level `F` columns and the `t/m` and `T/M` diagonals, landing to landing —
## so every step he takes is ground she could be standing on.
##
## **Which is also what leaves her the answer the brief gives him**, *"going into a corridor and
## letting them pass"*: a shaft's walk never stands on a `D` cell, because each door's only walkable
## neighbour is the level approach below it, so a door is always further from his line than the
## radius that takes the baby. `tests/test_interior.gd` measures that gap rather than assuming it.
func _place_the_masked_man() -> void:
	var walk := _interior.stairwell_walk("stairwell_%s" % _PURSUED_SIDE)
	if walk.size() < 2:
		return
	var path := PackedVector2Array()
	for tile in walk:
		path.append(_interior.tile_to_world(tile))
	_pursuer = _spawn(EventCatalogue.by_id(_PURSUER_ID), path[0], path)

## The mouse a third of the way along the basement's own corridor, and the vents spread down the
## rest of it.
##
## Measured as a walk from the entry rather than written as tile offsets, so nothing here depends
## on the basement's three bands staying where they are: the corridor is one route with no
## branches, so "a third of the way along it" is a well-defined place however it is laid out, and
## everything sited this way stands somewhere she has to pass rather than somewhere she might.
func _place_the_basement(rng: RandomNumberGenerator) -> void:
	var walk := _interior.basement_walk()
	if walk.size() < 4:
		return
	var mouse_at: Vector2i = walk[walk.size() / 3]
	_spawn(EventCatalogue.by_id(_MOUSE_ID), _interior.tile_to_world(mouse_at))
	# The mouse's dash is built from the alley it stands in when there is a map to ask; indoors
	# there is none, so `EventInstance` gives it its own short crossing and the roll is spent here
	# only to keep this function's own stream advancing with the rest of the section.
	rng.randf()

	# **The vents are not rolled.** *"Multiple fixed locations"* — a corridor she has to time is a
	# corridor whose gates are in the same places every attempt, so a lost section is the same
	# puzzle again rather than a different one. The clocks are staggered so the three of them do
	# not open the whole corridor at once on the first pass; after that their own periods do it.
	_take_the_grates_up()
	_vents.clear()
	var sites := _vent_sites(walk)
	for i in sites.size():
		var vent := Vent.new()
		vent.at = sites[i]
		vent.period = Tuning.FINALE_STEAM_PERIODS[i]
		vent.until_the_next_blow = vent.period * float(i + 1) / float(sites.size())
		vent.grate = _lay_a_grate(vent.at)
		_vents.append(vent)

## A vent's floor grate, lying on its site for the whole section.
##
## **Ground, not something standing on it.** She walks over the grate between blows, so it is never
## drawn over her: it is a child of the building itself at the ground's own `z_index` (0), after
## the floor tiles in the tree so it lies on them, and under the walls (1) and the y-sorted layer
## (2) she and every blow stand in. A decal in that y-sorted layer, as the basement's puddles are,
## would be drawn over her feet whenever she stood on its northern half.
##
## **Centred on the vent's own point**, as a ground decal is, and that point is where each blow's
## cloud stands — the frames' bottom-centre anchor — so the column comes up out of the slots.
##
## No body: the grate is where the gate is, not a second gate. What stops her is the blow's own
## `STEAM_VENT_BODY`, which goes down at the end of its notice and comes up at the end of the blow.
func _lay_a_grate(at: Vector2) -> Sprite2D:
	var grate := Sprite2D.new()
	grate.name = "SteamGrate"
	grate.texture = EventInstance.steam_grate()
	grate.centered = true
	grate.z_index = 0
	grate.position = at
	_interior.add_child(grate)
	return grate

## The grates of the vents being replaced. A restart places the same vents on the same sites, but
## it builds them afresh like everything else it places, so the old grates go with the old vents
## rather than lying twice.
func _take_the_grates_up() -> void:
	for vent in _vents:
		if is_instance_valid(vent.grate):
			vent.grate.queue_free()
		vent.grate = null

## Where each vent stands: one on each of the corridor's one-tile-wide cells, at that cell's own
## centre, in the order she meets them.
##
## *(2026-09-19: "there are only two steams and they are not blocking in any way they should go in
## the narrow hallways.")* **A vent closes the corridor because of where it stands, not because of
## how wide it is** (see `EventCatalogue.STEAM_VENT_BODY`), and the one place a 32px cloud is the
## whole width is a passage one tile across: her centre has 16px of play either side of the middle
## and a blow holds it 30px out, so no line past one exists. In a two-tile band there is no such
## place — a body on the seam still leaves her the outside of it at the walls — which is what the
## player walked past.
##
## The cells are the layout's (`InteriorScene.basement_narrows()`) rather than found by scanning,
## so the gates are in the same three places every attempt: *"multiple fixed locations"*, and a
## lost section is the same puzzle again rather than a different one. Each is checked against the
## corridor's own walk here, because a gate she can go round is not a gate and nothing else would
## notice if the layout and the walk ever stopped agreeing.
func _vent_sites(walk: Array[Vector2i]) -> Array[Vector2]:
	var found: Array[Vector2] = []
	var on_the_walk := {}
	for tile in walk:
		on_the_walk[tile] = true
	var count: int = Tuning.FINALE_STEAM_PERIODS.size()
	var narrows := _interior.basement_narrows()
	if narrows.size() != count:
		push_error("the basement corridor offers %d one-tile gates for %d steam vents"
				% [narrows.size(), count])
		return found
	for tile in narrows:
		if not on_the_walk.has(tile):
			push_error("the steam vent at %s is not on the basement's own walk" % tile)
			return []
		found.append(_interior.tile_to_world(tile))
	return found

## Every vent's own clock, one blow at a time. A blow is an ordinary `EventInstance` of the steam
## row: it gives its notice with no body, closes the corridor for `Tuning.FINALE_STEAM_BLOWS_FOR`,
## and is over — `_retire_finished()` takes it away like anything else that has run its course.
## No event stands between blows, so a vent that is off is not an event that is quiet, it is an
## event that does not exist — only its grate is there, and a grate costs nothing and stops nobody.
func _blow_the_vents(delta: float) -> void:
	for vent in _vents:
		vent.until_the_next_blow -= delta
		if vent.until_the_next_blow > 0.0:
			continue
		vent.until_the_next_blow += vent.period
		_spawn(EventCatalogue.by_id(_STEAM_ID), vent.at)

## Where the vents stand, for `tests/test_interior.gd` — the contracts they owe are about the
## distance between them and about their clocks, and neither is answerable from outside.
func vents() -> Array[Vent]:
	return _vents

## The inner cell of each intermediate floor's level approach in one shaft. Asked of the plan
## rather than recomputed from the grammar's own arithmetic here, so a change to a flight's length
## moves the fire with it.
func _inner_floor_approaches(side: String) -> Array[Vector2i]:
	return _interior.inner_floor_approaches("stairwell_%s" % side)

# -------------------------------------------------------------- the instances ---

func _spawn(def: EventDef, at: Vector2, path := PackedVector2Array()) -> EventInstance:
	if not def:
		return null
	var instance := EventInstance.new()
	# No `CityMap`: every question `setup()` asks one of it — which pavement band to centre on,
	# which way a spread lies, which alley a mouse crosses — is about a lattice this building does
	# not sit on, and `EventInstance` already answers all three for a caller with no map.
	instance.setup(def, at, path)
	_interior.add_entity(instance)
	_instances.append(instance)
	return instance

## A row with the marks it leaves on a *run* taken off it — the scar it records and the row it
## calls in when it is first seen. The fire is the caller: outdoors a burning building leaves a
## shell on that corner for the rest of the run and summons a fire engine down the street, and
## neither means anything in a stairwell on the last night. A derived copy, never a mutation, for
## the reason `EventDef.at_heat()` gives; `shape` is carried by hand because it is a plain
## `RefCounted` field that `Resource.duplicate()` does not copy.
static func _without_its_aftermath(def: EventDef) -> EventDef:
	var variant: EventDef = def.duplicate()
	variant.shape = def.shape
	variant.scar_id = ""
	variant.spawns_on_sight = ""
	return variant

func _physics_process(delta: float) -> void:
	_retire_finished()
	_explode_every_so_often(delta)
	_blow_the_vents(delta)
	_send_the_masked_man_again(delta)
	_light_the_far_windows(delta)
	if not _find_player():
		return
	_tell_them_where_she_is()
	_check_hard_fails()

## The bang outside, on the shared clock. Section one has no street for an explosion to stand on,
## so what happens is the two halves of one that reach through a wall: every window in the building
## goes white for a frame or two, and a live instance of the same row stands where she is for as
## long as its own `duration` — so the meter is charged by an ordinary excitement source rather
## than by anything writing at the baby.
func _explode_every_so_often(delta: float) -> void:
	_until_the_next_explosion -= delta
	if _until_the_next_explosion > 0.0:
		return
	_until_the_next_explosion = Tuning.FINALE_EXPLOSION_INTERVAL
	_interior.flash_windows()
	if not _find_player():
		return
	# Its telegraph is spent before the flash rather than after it: what the windows say is *it has
	# already happened*, so the row is handed to the world with its notice already over.
	var burst := _spawn(EventCatalogue.by_id(_EXPLOSION_ID), _player.global_position)
	if burst:
		burst.resume(burst.def.telegraph_time, 0.0, INF)

## The rest of the night: something going off far enough away that only the light reaches her.
## *(2026-09-19: "the flashing lights in the window are too rare.")*
##
## **A picture and nothing else.** No `EventInstance`, no field, nothing on the meter — which is
## the whole reason this is not simply a shorter `FINALE_EXPLOSION_INTERVAL`: the player asked for
## the light and said nothing about the noise, and an explosion is loud by definition. A bang close
## enough to shake the building still costs her exactly what it did.
##
## **The same call a near bang makes**, so every window in the building lights together and goes
## dark together — *(2026-09-19: "all windows always need to flash together. a single window cannot
## flash by itself.")* What separates the far flashes from the near ones is how often they happen
## and what they cost, never which windows they reach.
##
## Nothing is logged for one either. The run log records what the code cannot recompute and what
## answers an open question; a line every few seconds saying the windows lit would be neither, and
## the loud bangs are already visible in the log through what they charge.
func _light_the_far_windows(delta: float) -> void:
	_until_the_next_distant_flash -= delta
	if _until_the_next_distant_flash > 0.0:
		return
	_until_the_next_distant_flash = _wait_for_the_next_distant_flash()
	_interior.flash_windows()

## How long until the next one: a scaled Kumaraswamy draw, short-biased and smooth, bounded by
## `Tuning.FINALE_DISTANT_FLASH_MIN_SECONDS` and `_MAX_SECONDS` with its mean set by the shape
## constant — see that constant's own doc for the formula and for why `B` is not a number to edit
## by feel. **Its inverse CDF is closed form**, which is why this is one expression and not a
## rejection loop: a loop would draw a variable number of values from the stream and make how many
## times the windows flash depend on how many times the dice were rolled, so a seed would stop
## replaying the same night.
func _wait_for_the_next_distant_flash() -> float:
	var u := _flashes.randf()
	var span := Tuning.FINALE_DISTANT_FLASH_MAX_SECONDS - Tuning.FINALE_DISTANT_FLASH_MIN_SECONDS
	return Tuning.FINALE_DISTANT_FLASH_MIN_SECONDS \
			+ span * sqrt(1.0 - pow(1.0 - u, 1.0 / Tuning.FINALE_DISTANT_FLASH_SHAPE_B))

func _retire_finished() -> void:
	var survivors: Array[EventInstance] = []
	for instance in _instances:
		if instance.is_finished:
			instance.queue_free()
		else:
			survivors.append(instance)
	if survivors.size() != _instances.size():
		_instances.assign(survivors)

## Another masked man at the foot of the same shaft, `Tuning.FINALE_PURSUER_RESPAWN_SECONDS` after
## the last one finished — for as long as she is in the building, which is for as long as this node
## is processing at all (see `stand_down()`).
##
## **A fresh instance rather than a rewound one**, which is what keeps him fair: a new
## `EventInstance` waits at the foot until she is within `masked_pursuer.pursues_within` and then
## spends its whole `telegraph_time` standing there before it moves, so every run he makes gives
## the same notice the first one did. Resuming an old instance would hand her a man already at
## speed, which is the one thing `still_while_telegraphing` exists to prevent.
func _send_the_masked_man_again(delta: float) -> void:
	if _pursuer != null:
		# **His run is over when he is off the end of it**, not when his instance is finally
		# deleted. A mobile row that has run out of path spends a leaving phase walking out of
		# sight (`EventInstance._leave()`), which ends on whichever of `Tuning.OUT_OF_SIGHT` and
		# `LEAVING_GIVES_UP` comes first — so a gap counted from the deletion would be the stated
		# interval plus a leaving phase, and would not be the same length twice.
		if is_instance_valid(_pursuer) and not _pursuer.is_leaving and not _pursuer.is_finished:
			return
		_pursuer = null
		_until_the_next_pursuer = Tuning.FINALE_PURSUER_RESPAWN_SECONDS
		return
	_until_the_next_pursuer -= delta
	if _until_the_next_pursuer > 0.0:
		return
	# Reset before the placement, not after it: a building with no shaft to run places nobody, and
	# a clock left at zero would try again on every frame for the rest of the section.
	_until_the_next_pursuer = Tuning.FINALE_PURSUER_RESPAWN_SECONDS
	_place_the_masked_man()

func _find_player() -> bool:
	if not _player or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	return _player != null

## Hands every instance her position, the same way `EventManager` does and for the same reason: she
## is found once a frame in one place, and an `EventInstance` has never had to know she exists.
func _tell_them_where_she_is() -> void:
	var stroller := _player as Stroller
	var running: bool = stroller != null and stroller.run_excess_ratio() > 0.0
	var awake: bool = stroller == null or stroller.baby_is_awake()
	for instance in _instances:
		instance.player_at = _player.global_position
		instance.player_running = running
		instance.baby_awake = awake

## Being caught on the stairs ends the section. `EventBus.hard_fail_triggered` is the same signal a
## day's own lethal rows fire, so `FinaleController`'s clock hears it through `DayController`
## exactly as it hears an abduction outdoors — nothing here has to know what a section is.
func _check_hard_fails() -> void:
	if _hard_failed:
		return
	for instance in _instances:
		if instance.is_lethal_at(_player.global_position):
			_hard_failed = true
			EventBus.hard_fail_triggered.emit(instance.def.id)
			return

# ------------------------------------------------------------ WorldContext ---

func excitement_sources_at(world_position: Vector2) -> Array:
	var sources: Array = []
	for instance in _instances:
		var contribution := instance.contribution_at(world_position)
		if contribution > 0.0:
			sources.append([instance, contribution])
	return sources

func total_excitement_at(world_position: Vector2) -> float:
	var total := 0.0
	for pair in excitement_sources_at(world_position):
		total += pair[1]
	return total
