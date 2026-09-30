extends RefCounted
## Supplemental unprofiled timing for event spread classification. The active-play comparison is
## the performance evidence; this isolates the enum match replaced by the cached read so profiler
## callback overhead cannot be mistaken for all of the CPU reduction.

const PASSES := 20000
const PAIRS := 5

func run(t) -> void:
	var defs := EventCatalogue.all()
	t.check(not defs.is_empty(), "the classifier benchmark has catalogue definitions to read")
	_measure_legacy(defs)
	_measure_cached(defs)
	for pair in PAIRS:
		var legacy_usec := 0
		var cached_usec := 0
		var legacy_hits := 0
		var cached_hits := 0
		if pair % 2 == 0:
			var legacy := _measure_legacy(defs)
			legacy_usec = legacy.x
			legacy_hits = legacy.y
			var cached := _measure_cached(defs)
			cached_usec = cached.x
			cached_hits = cached.y
		else:
			var cached := _measure_cached(defs)
			cached_usec = cached.x
			cached_hits = cached.y
			var legacy := _measure_legacy(defs)
			legacy_usec = legacy.x
			legacy_hits = legacy.y
		print("EVENT_SHAPE_CACHE pair=%d legacy_usec=%d cached_usec=%d reads=%d" % [
				pair + 1, legacy_usec, cached_usec, defs.size() * PASSES])
		t.check(legacy_hits == cached_hits,
				"pair %d: cached and legacy classifiers count the same spread reads" % (pair + 1))

func _measure_legacy(defs: Array[EventDef]) -> Vector2i:
	var began := Time.get_ticks_usec()
	var hits := 0
	for _pass in PASSES:
		for def in defs:
			if _legacy_has_a_spread(def):
				hits += 1
	return Vector2i(Time.get_ticks_usec() - began, hits)

func _measure_cached(defs: Array[EventDef]) -> Vector2i:
	var began := Time.get_ticks_usec()
	var hits := 0
	for _pass in PASSES:
		for def in defs:
			if def.has_a_spread:
				hits += 1
	return Vector2i(Time.get_ticks_usec() - began, hits)

## An equivalent uncached classifier, kept here as an independent timing and parity oracle.
static func _legacy_has_a_spread(def: EventDef) -> bool:
	match def.look:
		EventDef.Look.ROADWORKS, EventDef.Look.BURNT_SHELL, EventDef.Look.STALL, \
				EventDef.Look.ROADBLOCK, EventDef.Look.BARRICADE, EventDef.Look.CAFE, \
				EventDef.Look.FALLEN_TREE, EventDef.Look.CAR_ACCIDENT, EventDef.Look.BURST_MAIN, \
				EventDef.Look.SCAFFOLDING, EventDef.Look.COLLAPSED_FRONTAGE:
			return true
		_:
			return false
