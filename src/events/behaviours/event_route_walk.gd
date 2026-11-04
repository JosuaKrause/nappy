class_name EventRouteWalk
extends EventBehaviour
## **Following a route, or pacing a beat**: a mobile row walks its `path` at its `speed`, every step
## through the navigator, and leaves from the end of a journey; a row that `paces` folds its walk
## back and forth over the route for ever. The route and how far along it the event is are the
## event's body (`path`, `_path_travelled`), which streaming carries; this is how it moves along it.
## A pursuer, an investigating vehicle and a row that waits walk their routes through this too.

## One tick of a plain mobile row that walks its route: not while it holds still through its
## telegraph, nor once it has parked.
func step(delta: float) -> void:
	if event.path.size() > 1 and not event.is_telegraphing_still() and not event.is_parked:
		advance(delta)

## Walks `delta` seconds of its route at its row's `speed`.
func advance(delta: float) -> void:
	var def: EventDef = event.def
	var path: PackedVector2Array = event.path
	# Movement starts when the telegraph does, so an approaching siren is audible and
	# visible while it is still far away — which is what makes the warning usable.
	event._path_travelled += def.speed * delta
	var remaining: float = event._path_travelled
	# **A beat rather than a journey.** The distance covered is folded back and forth over
	# the route, so the same walk up and down happens for ever and the end of the path is never
	# reached — which is what stops a fixture that moves from departing like something that was
	# passing through. Folded rather than reset, so streaming it out and back in resumes it mid-beat
	# exactly as `resume()` promises.
	var back := false
	if def.paces:
		var beat := length()
		if beat <= 0.0:
			return
		var cycle := fmod(event._path_travelled, beat * 2.0)
		back = cycle > beat
		remaining = beat * 2.0 - cycle if back else cycle
	for i in range(1, path.size()):
		var segment := path[i] - path[i - 1]
		var segment_length := segment.length()
		if remaining <= segment_length:
			event._heading = segment.normalized()
			# Facing the way it is actually walking. Without this a man pacing a pavement moons
			# along it backwards for half of every beat, which is worse than not moving at all.
			if back:
				event._heading = -event._heading
			_keep_to(path[i - 1] + segment.normalized() * remaining)
			return
		remaining -= segment_length
	if not _keep_to(path[path.size() - 1]):
		return
	if def.paces:
		return
	# A mobile event that has driven off the end of its route is done, whatever its
	# nominal duration says — and it keeps going until it is out of sight, rather than stopping
	# dead on the pavement she is walking down. See `EventInstance._end_its_route()`.
	event._end_its_route()

## **Moves this figure to `on_the_route`, the point its route has reached, through the navigator**:
## the whole way where nothing solid stands between (`Navigator.move_to()`), which is every frame of
## a route checked before it was accepted. Where a solid put down since stands in the way, a figure
## that paces a beat holds where it is until the beat brings the point back to its side, and any
## other has come to the end of its route there (`EventInstance._end_its_route()`), leaving from it the way every route
## that runs out leaves. Answers whether it reached the point.
func _keep_to(on_the_route: Vector2) -> bool:
	var reached: Vector2 = event._navigator.move_to(event.global_position, on_the_route,
			event._mover)
	event.global_position = reached
	if reached == on_the_route:
		return true
	if not event.def.paces:
		event._end_its_route()
	return false

## The length of the whole route, in px.
func length() -> float:
	var path: PackedVector2Array = event.path
	var total := 0.0
	for i in range(1, path.size()):
		total += path[i].distance_to(path[i - 1])
	return total
