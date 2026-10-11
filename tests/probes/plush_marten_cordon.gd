extends RefCounted
## **Probe, not a suite** (`tools/test.sh probes/plush_marten_cordon.gd`): day 12's police cordon
## (`ParkCordon`) on every seed `tests/test_park_cordon_seeds.gd` sweeps, measured the way that
## suite measures it — with her at the swing and the camera on her — and printed as a table.
##
## For each seed it prints the park's size, the walk from the swing to the last gap and how long
## that takes at `Tuning.WALK_SPEED`, when the first officer comes into her view and when the
## cordon expected it (`ParkCordon.first_in_view`), the close it paced to, when the last gap
## is taped with her standing at the swing, the margin between the two beyond the walk, whether
## the gap's outside reaches home and the day's other calm ground with the park blocked and stands
## clear of the day's bodies and fields, and whether setting off at a walk a second after first
## sight gets her out. Run it again after changing any `PARK_CLOSING_*` constant.

const SWEEP := preload("res://tests/test_park_cordon_seeds.gd")

func run(t) -> void:
	var sweep: RefCounted = SWEEP.new()
	var seeds: Array[int] = []
	for seed_value in range(SWEEP.SEEDS_FROM, SWEEP.SEEDS_TO + 1):
		seeds.append(seed_value)
	seeds.append(SWEEP.LARGE_PARK_SEED)
	var margins := PackedFloat32Array()
	var closes := PackedFloat32Array()
	var walks := PackedFloat32Array()
	for seed_value in seeds:
		var m: Dictionary = sweep.call("measure", t, seed_value)
		if m.is_empty():
			print("seed %5d: no swing park" % seed_value)
			continue
		var size: Vector2 = m.park_size
		var walk_seconds: float = m.walk / Tuning.WALK_SPEED
		var margin: float = m.closed_at - m.first_seen - walk_seconds
		margins.append(margin)
		closes.append(m.closed_at)
		walks.append(walk_seconds)
		print("seed %5d: park %3.0fx%3.0f, walk %3.0fpx (%.1fs), " % [seed_value, size.x, size.y,
				m.walk, walk_seconds] + "first seen %4.1fs (expected %4.1fs), " % [m.first_seen,
				m.first_in_view] + "deadline %4.1fs, " % m.deadline
				+ "closed %4.1fs standing, %.1fs beyond the walk; " % [m.closed_at, margin]
				+ "gap reaches home %s, other calm %s, clear %s (%s); walked out %s" % [
				m.gap_reaches_home, m.other_calm_reached, m.gap_clear, m.gap_blocker, m.walked_out])
	if not margins.is_empty():
		print("over %d seeds: walk %.1f to %.1fs, closed %.1f to %.1fs, " % [margins.size(),
				_least(walks), _most(walks), _least(closes), _most(closes)]
				+ "first sight %.1f to %.1fs beyond the walk" % [_least(margins), _most(margins)])

static func _least(values: PackedFloat32Array) -> float:
	var found := INF
	for value in values:
		found = minf(found, value)
	return found

static func _most(values: PackedFloat32Array) -> float:
	var found := -INF
	for value in values:
		found = maxf(found, value)
	return found
