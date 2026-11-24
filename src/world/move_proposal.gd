class_name MoveProposal
extends RefCounted
## **One mover's move for one tick: proposed, checked, then committed.** Every mover that walks or
## drives a world — an event's figure or car (`EventInstance`), a crowd walker or car (`LaneMover`),
## day 12's cordon officers (`ParkCordon`) — keeps one of its own, and puts it on its map's list of
## moves (`WorldMap.moves`, a `ProposedMoves`) for as long as it stands in that world. Each tick it
## steps in three parts:
##
## 1. **Propose** (`propose()`): the tick opens its move at the pose it stands at, and works out
##    where it would go (its proposed end).
## 2. **Check**: the mover's own checker passes the proposal or changes it — the navigator's swept
##    step for a figure, taken as each part of the step is, which is why a figure's proposal reaches
##    its end already checked; a car's own checks once its whole tick is proposed
##    (`EventCarDriving.check()`), which take the step back where it would bring the body into her or
##    her pram, past a red light's stop line or into a turn across her, and check no wall; the
##    crowd's hold on a step into a tile its body may not stand on
##    (`LaneMover._keep_out_of_a_body()`).
## 3. **Commit** (`commit()`): the pose the mover stands at from now, which it acts on — the end of
##    a route reached, a departure begun or ended, a catch — only once it is committed.
##
## **Only a crowd body's move can be changed between its proposal and its check.** `LaneMover`
## proposes its along and cross step without moving, and its check (`_keep_out_of_a_body()`) is
## what then holds whatever the move says to the tiles its body may stand on; a pass that
## changed the proposed end in between would be checked like the step itself. Every other
## mover's move is the pose it publishes for the others to read: an event figure and a cordon
## officer are walked through the navigator during the tick, so the move records a pose the
## figure already stands at, and an event car's check holds the step to her, the stop line and
## the turn onto her, never to a wall. That is the seam the player's rule for who gives way
## needs (inbox #884 in plaid-raven): the crowd yields, and an event figure keeps its course and
## its timing, so the crowd's moves are the ones a pass changes and everyone else's committed
## pose is what they yield to. **Each move carries what that pass reads about its mover**: how
## far its body reaches round its centre (`body_radius()`) and whether it is one that gives way
## (`gives_way()`). The pass is the map's `SeparationPass`, which each crowd body asks at its own
## step, between its proposal and its check.
##
## **Outside a step the move stands where its mover does** (`stands_at()` and `steps_to()` both
## answer its pose): a mover joins at the pose it stands at, and anything that moves it outside its own step — a body
## recycled or pushed, a car through a turn, an event stood somewhere else — puts its move there too
## (`place()`). The list holds no mover, so its moves are the only poses a pass over it has.
##
## Positions are `Vector2`, a node's own type, so a proposal worked out here lands where the same
## sum written straight onto the node always did.

## The pose the move was opened at: where the mover stood when it was proposed, and once
## committed, where it stands.
var _from := Vector2.ZERO
## Where the mover would go, then where its check let it go.
var _to := Vector2.ZERO
## Whether the move is open: proposed and not yet committed.
var _open := false
## How far its mover's body reaches round its centre, in px: the circle that holds the whole body
## (`GroundShape.reach()` for a crowd body, the radius an event walks or drives through the navigator
## at, a cordon officer's figure).
var _radius := 0.0
## Whether its mover gives way to the others — a crowd walker or car — rather than keeping its own
## course and timing, as an event figure, an event car and a cordon officer do (inbox #884 in
## plaid-raven).
var _yields := false
## **Whether a walker goes round it while it stands still**, not only while it moves: true for an
## object or a vehicle, false for a person or an animal, whom a walker may walk through while they
## stand (inbox #905 in freckled-moose). Read by the pass a walker gives way through (`SeparationPass`); a crowd car
## stands for a figure in its lane whichever it is. Set by the mover from what it is: an event from
## its row (`BodySpec.is_walked_round()`); a cordon officer is a person, so his stays false.
var _stood_round := false
## **Whether it has parked: stands where it is for good** (inbox #909 in freckled-moose). A crowd car standing behind
## a parked figure in its lane turns round, as at a blocked street, and waits behind any other
## (`SeparationPass.edge_ahead()`). Set by the mover as it goes: an event from its row's
## `BodySpec.parks()` and where it is in its life (`EventInstance`); a cordon officer walks on,
## so his stays false.
var _parked := false
## Whether it is on a world's list of moves (`ProposedMoves`) now: set when it joins, cleared when it
## leaves, so a pass over a copy of the list can tell a move whose mover has since gone.
var _on_the_list := false

func _init(gives_way := false) -> void:
	_yields = gives_way

## Opens a move at `at`, proposing to stay there until the mover says where it would go.
func propose(at: Vector2) -> void:
	_from = at
	_to = at
	_open = true

## Commits the move: the pose the mover stands at from now.
func commit() -> Vector2:
	_open = false
	_from = _to
	return _to

## The pose the mover stands at now: where the step began.
func stands_at() -> Vector2:
	return _from

## Where the step proposed would put the mover.
func steps_to() -> Vector2:
	return _to

## Proposes the step to `at`, in place of the one proposed so far.
func step_to(at: Vector2) -> void:
	_to = at

## The mover's body radius, which keeps it clear of the other bodies; zero for a mover with none.
func body_radius() -> float:
	return _radius

## Gives the mover its body radius.
func use_body_radius(reach: float) -> void:
	_radius = reach

## Whether the mover gives way to every other body instead of being kept clear of.
func gives_way() -> bool:
	return _yields

## Whether the move stands on a world's list of moves.
func is_on_the_list() -> bool:
	return _on_the_list

## Puts the move on a world's list or takes it off, as that list does.
func stand_on_the_list(now: bool) -> void:
	_on_the_list = now

## Whether a walker goes round the mover while it stands still: an object or a vehicle, not a
## person or an animal.
func is_walked_round() -> bool:
	return _stood_round

## Says whether a walker goes round the mover while it stands still: an object or a vehicle, not
## a person or an animal.
func be_walked_round(now: bool) -> void:
	_stood_round = now

## Whether the mover has parked: stands where it is for good.
func has_parked() -> bool:
	return _parked

## Says whether the mover has parked: stands where it is for good.
func be_parked(now: bool) -> void:
	_parked = now

## Whether the step is open: proposed and not yet committed.
func is_mid_step() -> bool:
	return _open

## **The mover stands at `at`, moved outside its own step**: joining a world, recycled, pushed, or
## carried along a turn. Both ends of the move are there, and an open move stays open.
func place(at: Vector2) -> void:
	_from = at
	_to = at
