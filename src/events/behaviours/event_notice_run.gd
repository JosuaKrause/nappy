class_name EventNoticeRun
extends EventBehaviour
## **A row that waits for her and then runs its own event, without chasing her**: the alley mouse,
## the pigeon flock and the masked man on the escape's stairs (`EventDef.notice` with no
## `EventDef.pursuit`). It stands unclocked until she is within its notice, so a `MAP` row placed
## at dawn well outside her view does not spend its telegraph off screen; then its telegraph runs,
## and its route after it. A flock goes up early once she is among the birds; the masked man runs
## his line once she is near.

## **His warning on his line** (`Warning`, read against the event's `age`): `Tuning.
## WARNING_ALONE_MAX` long, then held up with no length until he runs, called off throughout once
## she is back outside his notice. Not running before he has noticed her, nor once called off.
var _line_warning := Warning.new()
## Whether he noticed her already inside his run distance, so his run waits for his warning.
var _noticed_inside := false
## Its row: how near she comes before it notices her, whether it walks a route, and a flock's
## spread.
var _row: EventDef
## How it notices her (`NoticeSpec`): the distance a row that runs its own line runs from.
var _spec: NoticeSpec
## Its route walk (`EventRouteWalk`), which it walks once it has noticed her; null for a row that
## does not move.
var _route: EventRouteWalk

## Handed, as its event is set up, the figure it moves, where she is, its row, how it notices her
## and the route walk it walks once it has.
func _init(figure: EventInstance.Figure, where: WhereSheIs, row: EventDef, spec: NoticeSpec,
		route: EventRouteWalk) -> void:
	_figure = figure
	_where = where
	_row = row
	_spec = spec
	_route = route
	_line_warning.cancel_if = _she_has_left_his_notice
	_line_warning.on_expired = _keep_warning_once_it_has_run

## One tick: notice her, warn on its line, go up among her, and walk its route once noticed.
##
## Overrides EventBehaviour.step.
func step(delta: float) -> void:
	_check_for_notice()
	_warn_on_its_line(delta)
	_flush_the_flock_if_she_is_among_them()
	if not _figure.is_waiting() and _row.mobile and _figure.walks().size() > 1 \
			and not _figure.is_telegraphing_still():
		_route.advance(delta)

## **It notices her within its notice radius**, with no clear line asked — the mouse's alley and the
## masked man's shaft are the ground it watches — and turns to face her, which costs nothing: its
## route overwrites the heading the instant it starts moving.
func _check_for_notice() -> void:
	var her: Vector2 = _where.at()
	if her == Vector2.INF or not _figure.is_waiting():
		return
	var toward: Vector2 = her - _figure.place()
	if toward.length() > _row.notice_within():
		return
	_figure.notice_her()
	_figure.turn_to(toward.normalized())

## **A row that runs its own line runs on a distance, with no warning clock** (`NoticeSpec.
## runs_within`, the masked man): the one exception to the one-radius rule every waiting charger
## keeps (inbox #788 in minty-lemur), since in the stairwell his warning is off screen, so a delay
## before he runs buys her nothing she can see to answer. While it warns, she back outside its
## notice has it wait again, and she inside its run distance starts its run — at once if she came in
## from outside it, after `Tuning.WARNING_ALONE_MAX` of warning if it noticed her already inside, so
## it never runs at her with no warning at all. Its run is the end of its telegraph
## (`Phase.ACTIVE`), as a flock's flush is; its notice does not run out before then
## (`EventInstance._hold_the_notice_clock()`).
func _warn_on_its_line(delta: float) -> void:
	var her: Vector2 = _where.at()
	if _spec.runs_within <= 0.0 or _figure.notice_has_run() or _figure.is_waiting() \
			or her == Vector2.INF:
		return
	var range_to_her: float = _figure.place().distance_to(her)
	if not _line_warning.is_running():
		_noticed_inside = range_to_her <= _spec.runs_within
		_figure.warning_went_up()
		# From the start of this tick, since this tick's `delta` is already its first.
		_line_warning.start(_figure.age() - delta, Tuning.WARNING_ALONE_MAX)
	if _line_warning.tick(_figure.age()) == Warning.Outcome.CALLED_OFF:
		_figure.wait_for_her_again()
		return
	if range_to_her > _spec.runs_within:
		_noticed_inside = false
		return
	if not _noticed_inside:
		_figure.begin(EventInstance.Phase.ACTIVE)
		# His run is his charge, for his counter (`EventBus.pursuit_began`).
		_figure.charge_began()

## Once his warning has run, he runs the moment she is inside his run distance, wherever she was
## when he noticed her; his warning stays up, still called off by her leaving his notice.
func _keep_warning_once_it_has_run() -> void:
	_noticed_inside = false
	_line_warning.start(_figure.age())

## Whether she is back outside the masked man's notice: what calls his warning off.
func _she_has_left_his_notice() -> bool:
	return _where.at() != Vector2.INF \
			and _figure.place().distance_to(_where.at()) > _row.notice_within()

## **Birds go up when she reaches them, and a clock cannot know when that is** (2026-09-20: they
## should basically start fluttering when I touch them, not after). The flush fires on her arrival
## at the birds' own spread plus her body, the distance at which she is among them — the same end of
## its notice a pursuer's lunge makes (`Phase.ACTIVE`). Its `telegraph_time` is the backstop for a
## flock she came near and never reached, not the wait.
func _flush_the_flock_if_she_is_among_them() -> void:
	var her: Vector2 = _where.at()
	if _row.flock_size <= 0 or _figure.notice_has_run() or her == Vector2.INF:
		return
	if _figure.is_waiting() or not _figure.is_telegraphing():
		return
	if _figure.place().distance_to(her) > _row.flock_spread + Tuning.PLAYER_BODY_RADIUS:
		return
	_figure.begin(EventInstance.Phase.ACTIVE)

## His warning's start on the event's clock and its length (`INF` once it has run), and whether he
## noticed her inside his run distance.
##
## Overrides EventBehaviour.save.
func save() -> Dictionary:
	return {"line_warned_from": _line_warning.started_at(), "line_warning_for": _line_warning.length,
			"noticed_inside": _noticed_inside}

## Overrides EventBehaviour.restore.
func restore(state: Dictionary) -> void:
	_noticed_inside = bool(state.get("noticed_inside", false))
	var from := float(state.get("line_warned_from", INF))
	if from != INF:
		_line_warning.start(from, float(state.get("line_warning_for", INF)))
