class_name CrowdSources
extends ExcitementSources
## **The crowd, as one set of things that charge the baby** (`ExcitementSources`), made by the
## `Crowd` that owns it and handed to the world it walks. **The whole crowd, not only a startled
## body** *(2026-09-08, the player: "a busy street is noisy because of cars and a busy sidewalk is
## noisy because of people ... that will allow us to attribute the source exactly")*: an ordinary
## walker is as much a source as a honking car, and `ExcitementHalo`'s floor and cap are what keep a
## busy sidewalk legible rather than a special case here.

var _crowd: Crowd

## The widest jolt any of this crowd's bodies has carried — it only ever grows, through
## `widen_to()`, however a body's jolt radius is written. What `silent_beyond()` is stated over, so a
## jolt wider than any `CrowdExcitement.startle()` passes today still counts the moment it exists.
var _widest_jolt_outer := 0.0

func _init(crowd: Crowd) -> void:
	_crowd = crowd

## Told by a body whenever its jolt's outer radius is written (`CrowdExcitement`).
func widen_to(jolt_outer: float) -> void:
	_widest_jolt_outer = maxf(_widest_jolt_outer, jolt_outer)

## A distance from any of this crowd's bodies beyond which its field is exactly zero: the reach a
## body's own early-out rejects past, over both kinds and the widest jolt there has been.
func silent_beyond() -> float:
	var outer := maxf(maxf(Tuning.CAR_OUTER_RADIUS, Tuning.PEDESTRIAN_OUTER_RADIUS),
			_widest_jolt_outer)
	return outer / (1.0 - Tuning.FIELD_ECCENTRICITY_MAX)

## **A body past `silent_beyond()` is skipped without a call into it**: no body's own early-out
## reaches further, so the answer is the same, and the several hundred bodies of a busy day out of
## earshot cost one distance each.
func sources_at(at: Vector2) -> Array:
	var sources: Array = []
	var reach := silent_beyond()
	var reach_squared := reach * reach
	for agent in _crowd.agents():
		if agent.global_position.distance_squared_to(at) > reach_squared:
			continue
		var source := agent.excitement
		var contribution := source.contribution_at(at)
		if contribution > 0.0:
			sources.append([source, contribution])
	return sources

func every_source(into: Array) -> void:
	for agent in _crowd.agents():
		into.append(agent.excitement)
