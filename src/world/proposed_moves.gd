class_name ProposedMoves
extends RefCounted
## **One map's list of every mover's move** (`WorldMap.moves`): each mover that walks or drives
## the world joins its `MoveProposal` while it stands there and leaves when it goes, so a pass over
## every mover — changing a crowd body's proposal before its check, against everyone else's
## committed pose (`MoveProposal`'s doc says which moves can be changed) — has one list to pass
## over, in the order the movers joined. The world names no mover: what joins is the move, never
## the event, the walker or the officer making it.

var _moves: Array[MoveProposal] = []

## Puts a mover's own move on the list at `at`, the pose it stands at: it stands in this world from
## now, until it `leave()`s. A move already on it is not put on twice, and is placed at `at` all the
## same.
func join(move: MoveProposal, at: Vector2) -> void:
	move.place(at)
	if not move.on_the_list:
		move.on_the_list = true
		_moves.append(move)

## Takes a mover's move off the list: it no longer stands in this world.
func leave(move: MoveProposal) -> void:
	if move.on_the_list:
		move.on_the_list = false
		_moves.erase(move)

## How many moves stand on the list.
func size() -> int:
	return _moves.size()

## Whether `move` stands on this list.
func has(move: MoveProposal) -> bool:
	return move.on_the_list and _moves.has(move)

## **Every mover's move standing in this world, in the order they joined, as a copy of the list**,
## so a pass over it is safe against the list changing under its own loop: a mover freed or streamed
## out mid-pass leaves the list and not the copy, whose move then says `on_the_list` false, and a
## mover that joins mid-pass waits for the next pass. The copy shares the list's storage until the
## list is next written (Godot copies an array on write), so a pass in which nobody joins or leaves
## pays almost nothing for it, and one in which somebody does pays one copy of the references, less
## than an empty loop over them.
func all() -> Array[MoveProposal]:
	return _moves.duplicate()
