class_name ExcitementSources
extends RefCounted
## **A set of things that charge the baby**, answered as one: a day's events (`EventSources`) or
## the crowd on the streets (`CrowdSources`). The world hands the baby every set it holds
## (`WorldContext.excitement_sources`) and the halo is handed the same sets
## (`ExcitementHalo.setup()`), so the city and the building answer the same way, and a set the world
## does not have — the building's crowd — is simply not in the list.
##
## In the world layer, beside `ExcitementSource`: it names no event and no crowd; a set says how it
## finds its sources at a point and whether it holds her alone.

## Every source of this set whose contribution at `at` is positive, as `[source, contribution]`
## pairs, in a stable order: what the meter sums and traces each landed point back to.
func sources_at(_at: Vector2) -> Array:
	return []

## Every source of this set, whatever it contributes, appended to `into`: the candidates the halo
## lights rims among and asks for carets, and the ones whose `landed()` the netting sums.
func every_source(_into: Array) -> void:
	pass

## Whether this set is the whole of what charges her at `at` — she is inside a held door, paying its
## toll, and nothing else in the world reaches her there.
func holds_her_alone(_at: Vector2) -> bool:
	return false

## Summed excitement per second from this set at a point.
func total_at(at: Vector2) -> float:
	var total := 0.0
	for pair in sources_at(at):
		total += pair[1]
	return total

## Every set's pairs at `at`, in the sets' order — **unless one of them holds her alone, when its
## own pairs are the whole answer**: inside a region door she is in the hut for those seconds, not
## on the sidewalk, so the queue outside charges her no more than the street does. The one place
## the door rule is stated.
static func all_at(sets: Array[ExcitementSources], at: Vector2) -> Array:
	for set in sets:
		if set.holds_her_alone(at):
			return set.sources_at(at)
	var pairs: Array = []
	for set in sets:
		pairs.append_array(set.sources_at(at))
	return pairs
