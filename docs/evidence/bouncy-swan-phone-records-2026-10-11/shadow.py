"""Adds a shadow check to a scratch checkout of the branch. Never applied to the branch itself.

Every `_best_of()` call also runs the loop that judges every try afresh, on a copy of the stream,
and every `_offer_ahead()` answered from the last question is worked out again; each prints a
SHADOW line counting agreements and disagreements.

usage: shadow.py <checkout>
"""
import sys

path = sys.argv[1] + "/src/events/event_scheduler.gd"
s = open(path).read()


def sub(old, new):
    global s
    assert s.count(old) == 1, old[:60]
    s = s.replace(old, new)


sub("""	var verdicts := {}
	for _try in Tuning.EVENT_PLACEMENT_TRIES:
		var tile: Vector2i = open_candidates[rng.randi_range(0, open_candidates.size() - 1)]""",
"""	var shadow_rng := RandomNumberGenerator.new()
	shadow_rng.seed = rng.seed
	shadow_rng.state = rng.state
	var shadow_best: Planned = null
	var shadow_room := -INF
	for _try in Tuning.EVENT_PLACEMENT_TRIES:
		var s_tile: Vector2i = open_candidates[shadow_rng.randi_range(0, open_candidates.size() - 1)]
		var s_candidate := _build_placement(def, map, s_tile, shadow_rng)
		if not s_candidate:
			continue
		var s_room := _judge(s_candidate, role, map, s_tile, already, reach_context, ground,
				leave_alone, corridor, doors)
		if s_room == INF:
			shadow_best = s_candidate
			break
		if s_room > shadow_room:
			shadow_room = s_room
			shadow_best = s_candidate
	var real := _best_of_kept(def, rng, map, open_candidates, role, already, ground, leave_alone,
			corridor, doors, reach_context)
	var same := (real == null and shadow_best == null) or (real != null and shadow_best != null
			and real.position == shadow_best.position and real.path == shadow_best.path
			and real.facing == shadow_best.facing and real.role == shadow_best.role)
	same = same and rng.state == shadow_rng.state
	if same:
		shadow_agreed += 1
	else:
		shadow_disagreed += 1
		print("SHADOW_MISMATCH best_of %s" % def.id)
	return real

static var shadow_agreed := 0
static var shadow_disagreed := 0
static var shadow_offers_agreed := 0
static var shadow_offers_disagreed := 0

static func _best_of_kept(def: EventDef, rng: RandomNumberGenerator, map: CityMap,
		open_candidates: Array[Vector2i], role: GameEnums.BlockerRole,
		already: Array[Planned], ground: Dictionary, leave_alone: Array[Rect2],
		corridor: Corridor, doors: PackedVector2Array, reach_context: Array[Planned]) -> Planned:
	var best: Planned = null
	var best_room := -INF
	var verdicts := {}
	for _try in Tuning.EVENT_PLACEMENT_TRIES:
		var tile: Vector2i = open_candidates[rng.randi_range(0, open_candidates.size() - 1)]""")

sub("""		if question == _last_offer_question:
			return _last_offer""",
"""		if question == _last_offer_question:
			var kept := _last_offer
			_last_offer_question = []
			var fresh := _offer_ahead(def, at, heading, near, far)
			offers_worked_out -= 1
			if fresh[0] == kept[0] and fresh[1] == kept[1]:
				EventScheduler.shadow_offers_agreed += 1
			else:
				EventScheduler.shadow_offers_disagreed += 1
				print("SHADOW_MISMATCH offer %s" % def.id)
			return kept""")
open(path, "w").write(s)

mgr = sys.argv[1] + "/src/events/event_manager.gd"
m = open(mgr).read()
old = "\t\tprint(\"JUDGE n=%d"
assert m.count(old) == 1
m = m.replace(old, "\t\tprint(\"SHADOW n=%d best_of_agreed=%d disagreed=%d offers_agreed=%d disagreed=%d\" % [_director.looks, EventScheduler.shadow_agreed, EventScheduler.shadow_disagreed, EventScheduler.shadow_offers_agreed, EventScheduler.shadow_offers_disagreed])\n" + old)
open(mgr, "w").write(m)
print("shadowed", sys.argv[1])
