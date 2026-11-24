class_name FakeCityState
extends CityState
## A stand-in for where every block is along its arc, whose answers a check sets: handed to
## `CityMap.recompute_calm()` on a hand-drawn map in place of the run's, so the check names the
## blocks that are calm and builds no arcs. It answers what the map asks while it re-reads its
## calm blocks and playgrounds: the calm blocks, and the purpose of each, which is never a park,
## so no playground is added on a hand map. The real state's own logic is checked in
## `tests/test_blocks.gd`. A helper, not a suite: the runner loads only `test_*.gd`.

var _fake_calm: Array[Vector2i] = []

## Sets the blocks that are calm, as the map reads them back after the next `recompute_calm()`.
func with_calm(blocks: Array[Vector2i]) -> FakeCityState:
	_fake_calm = blocks.duplicate()
	return self

## Overrides CityState.calm_blocks.
func calm_blocks(_plans: Dictionary) -> Array[Vector2i]:
	return _fake_calm.duplicate()

## Overrides CityState.purpose_of.
func purpose_of(_plans: Dictionary, _block: Vector2i) -> GameEnums.BlockPurpose:
	return GameEnums.BlockPurpose.RESIDENTIAL
