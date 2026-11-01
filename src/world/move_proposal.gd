class_name MoveProposal
extends RefCounted
## **One mover's move for one tick: proposed, checked, then committed.** Every mover that walks or
## drives a world — an event's figure or car (`EventInstance`), a crowd walker or car (`LaneMover`),
## day 12's cordon officers (`ParkCordon`) — keeps one of its own, and puts it on its map's list of
## moves (`WorldMap.moves`, a `ProposedMoves`) for as long as it stands in that world. Each tick it
## steps in three parts:
##
## 1. **Propose** (`propose()`): the tick opens its move at the pose it stands at, and works out
##    where it would go (`to`).
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
## proposes its along and cross step without moving, and its check (`_keep_out_of_a_body()`) is what
## then holds whatever the move says to the tiles its body may stand on; a pass that changed `to` in
## between would be checked like the step itself. Every other mover's move is the pose it publishes
## for the others to read: an event figure and a cordon officer are walked through the navigator
## during the tick, so the move records a pose the figure already stands at, and an event car's
## check holds the step to her, the stop line and the turn onto her, never to a wall. That is the
## seam the player's rule for who gives way needs (inbox #884 in plaid-raven): the crowd yields,
## and an event figure keeps its course and its timing, so the crowd's moves are the ones a pass
## changes and everyone else's committed pose is what they yield to. **Each move carries what that
## pass reads about its mover**: how far its body reaches round its centre (`radius`) and whether it
## is one that gives way (`yields`). The pass is the map's `SeparationPass`, which each crowd body
## asks at its own step, between its proposal and its check.
##
## **Outside a step the move stands where its mover does** (`from` and `to` both at its pose): a
## mover joins at the pose it stands at, and anything that moves it outside its own step — a body
## recycled or pushed, a car through a turn, an event stood somewhere else — puts its move there too
## (`place()`). The list holds no mover, so its moves are the only poses a pass over it has.
##
## Positions are `Vector2`, a node's own type, so a proposal worked out here lands where the same
## sum written straight onto the node always did.

## The pose the move was opened at: where the mover stood when it was proposed, and once
## committed, where it stands.
var from := Vector2.ZERO
## Where the mover would go, then where its check let it go.
var to := Vector2.ZERO
## Whether the move is open: proposed and not yet committed.
var open := false
## How far its mover's body reaches round its centre, in px: the circle that holds the whole body
## (`GroundShape.reach()` for a crowd body, the radius an event walks or drives through the navigator
## at, a cordon officer's figure).
var radius := 0.0
## Whether its mover gives way to the others — a crowd walker or car — rather than keeping its own
## course and timing, as an event figure, an event car and a cordon officer do (inbox #884 in
## plaid-raven).
var yields := false
## **Whether a walker goes round it while it stands still**, not only while it moves: true for an
## object or a vehicle, false for a person or an animal, whom a walker may walk through while they
## stand (inbox #905). Read by the pass a walker gives way through (`SeparationPass`); a crowd car
## stands for a figure in its lane whichever it is. Set by the mover from what it is: an event from
## its row (`EventDef.stands_as`); a cordon officer is a person, so his stays false.
var stood_round := false
## Whether it is on a world's list of moves (`ProposedMoves`) now: set when it joins, cleared when it
## leaves, so a pass over a copy of the list can tell a move whose mover has since gone.
var on_the_list := false

func _init(gives_way := false) -> void:
	yields = gives_way

## Opens a move at `at`, proposing to stay there until the mover says where it would go.
func propose(at: Vector2) -> void:
	from = at
	to = at
	open = true

## Commits the move: the pose the mover stands at from now.
func commit() -> Vector2:
	open = false
	from = to
	return to

## **The mover stands at `at`, moved outside its own step**: joining a world, recycled, pushed, or
## carried along a turn. Both ends of the move are there, and an open move stays open.
func place(at: Vector2) -> void:
	from = at
	to = at
