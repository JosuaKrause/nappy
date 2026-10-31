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
##    (`EventCarDriving`), which take the step back; the crowd's hold on a step into a tile its body
##    may not stand on (`LaneMover._keep_out_of_a_body()`).
## 3. **Commit** (`commit()`): the pose the mover stands at from now, which it acts on — the end of
##    a route reached, a departure begun or ended, a catch — only once it is committed.
##
## **Between the proposal and the check is where another pass may change it**: a pass over the
## world's whole list (`ProposedMoves.all()`), which sees every mover's proposal and its committed
## pose, and whose change the mover's own check still holds to what may stand there. Nothing makes
## such a pass yet.
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
