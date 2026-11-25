class_name EventNoticeRun
extends EventBehaviour
## **A row that waits for her and then runs its own event, without chasing her**: the alley mouse
## and the pigeon flock (`EventDef.waits_for_her()`, not `EventDef.pursues()`). It stands
## unclocked until she is within its notice, so a `MAP` row placed at dawn well outside her view
## does not spend its telegraph off screen; then its telegraph runs, and its route after it. A flock
## goes up early once she is among the birds.

## How it travels (`RouteSpec`): whether it walks a route.
var _course: RouteSpec
## Its flock (`FlockSpec`): how many birds, and how far they spread.
var _flock: FlockSpec
## How it notices her (`NoticeSpec`): how near she comes before it notices her.
var _spec: NoticeSpec
## Its route walk (`EventRouteWalk`), which it walks once it has noticed her; null for a row that
## does not move.
var _route: EventRouteWalk

## Handed, as its event is set up, the figure it moves, where she is, how it travels, its flock, how
## it notices her and the route walk it walks once it has.
func _init(figure: EventInstance.Figure, where: WhereSheIs, course: RouteSpec, flock: FlockSpec,
		spec: NoticeSpec, route: EventRouteWalk) -> void:
	_figure = figure
	_where = where
	_course = course
	_flock = flock
	_spec = spec
	_route = route

## One tick: notice her, go up among her, and walk its route once noticed.
##
## Overrides EventBehaviour.step.
func step(delta: float) -> void:
	_check_for_notice()
	_flush_the_flock_if_she_is_among_them()
	if not _figure.is_waiting() and _course.moves() and _figure.walks().size() > 1 \
			and not _figure.is_telegraphing_still():
		_route.advance(delta)

## **It notices her within its notice radius**, with no clear line asked — the mouse's alley is the
## ground it watches — and turns to face her, which costs nothing: its route overwrites the heading
## the instant it starts moving.
func _check_for_notice() -> void:
	var her: Vector2 = _where.at()
	if her == Vector2.INF or not _figure.is_waiting():
		return
	var toward: Vector2 = her - _figure.place()
	if toward.length() > _spec.within():
		return
	_figure.notice_her()
	_figure.turn_to(toward.normalized())

## **Birds go up when she reaches them, and a clock cannot know when that is** (2026-09-20: they
## should basically start fluttering when I touch them, not after). The flush fires on her arrival
## at the birds' own spread plus her body, the distance at which she is among them — the same end of
## its notice a pursuer's lunge makes (`Phase.ACTIVE`). Its `telegraphs_for()` is the backstop for a
## flock she came near and never reached, not the wait.
func _flush_the_flock_if_she_is_among_them() -> void:
	var her: Vector2 = _where.at()
	if not _flock.is_a_flock() or _figure.notice_has_run() or her == Vector2.INF:
		return
	if _figure.is_waiting() or not _figure.is_telegraphing():
		return
	if _figure.place().distance_to(her) > _flock.spread() + Tuning.PLAYER_BODY_RADIUS:
		return
	_figure.begin(EventInstance.Phase.ACTIVE)
