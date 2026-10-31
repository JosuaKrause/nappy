class_name ProposedMoves
extends RefCounted
## **One map's list of every mover's move** (`WorldMap.moves`): each mover that walks or drives
## the world joins its `MoveProposal` while it stands there and leaves when it goes, so a pass over
## every mover's proposal, between its proposal and its check, has one list to pass over, in the
## order the movers joined. The world names no mover: what joins is the move, never the event, the
## walker or the officer making it.

var _moves: Array[MoveProposal] = []

## Puts a mover's own move on the list: it stands in this world from now, until it `leave()`s. A
## move already on it is not put on twice.
func join(move: MoveProposal) -> void:
	if not _moves.has(move):
		_moves.append(move)

## Takes a mover's move off the list: it no longer stands in this world.
func leave(move: MoveProposal) -> void:
	_moves.erase(move)

## Every mover's move standing in this world, in the order they joined.
func all() -> Array[MoveProposal]:
	return _moves
