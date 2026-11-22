class_name EventDraft
extends RefCounted
## **The one way a row is written**: one statement per line a row declares, then `build()`, which
## hands back the `EventDef`. A row is made once from a draft and never changed after, so a part it
## holds is shared by reference between the row and every copy of it; a copy is a draft started
## from the row (`EventDef.redraft()`), the parts it changes written over it, built again.
##
## **A draft is written one statement at a time and checks nothing**: `build()` does not validate.
## `EventCatalogue.all()` validates every shape of every row on load, and a suite builds a partial
## row on purpose (a field and a telegraph, no body declared), which a validating `build()` would
## refuse. What a writer is handed is the row's own value, so a part is never copied here.
##
## A writer named for a part (`body()`, `field()`, `warning()`) takes that part's value, which is
## what a row says once per ability it has; the others write the row's own settings. A row that
## says nothing of a part holds that part's plain default, as `EventDef` always has.
##
## The `drafted_<setting>()` readers are asked by `EventDef` alone, when it takes a draft's
## settings, and by nothing else: a draft is written, and the row it builds is what is asked.

# ----------------------------------------------------------------- the row's own ---

var _id := ""
var _kind := GameEnums.EventKind.RECURRING
var _ambient_source := EventDef.AmbientSource.NONE
var _noun := ""
var _noun_plural := ""
var _first_day := 1
var _last_day := 0
var _scripted_day := 0
var _act_tag := 1
var _weight := 1.0
var _max_per_day := 1
var _ground_weights := {}
var _placement: Array[int] = []
var _repeat_every := 0.0
var _repeat_after := 0.0
var _duration := 0.0
var _spawn_mode := EventDef.SpawnMode.MAP
var _from_day_after: DaySwitch = null
var _on_her_way: OnHerWay = null
var _sent_ahead: SentAhead = null
var _departs_at := 0.0
var _pavement_side := EventDef.Pavement.ANY
var _spans_the_street := false
var _drawn_to_sack_piles := false
var _role := EventDef.Role.NONE
var _counts_charges_as := ""

# ------------------------------------------------------------------------ the parts ---

var _look := LookSpec.none()
var _body := BodySpec.none()
var _field := FieldSpec.of(6.0, 40.0, 150.0)
var _warning := WarningSpec.lasting(WarningSpec.DEFAULT_SECONDS)
var _route := RouteSpec.none()
var _flock := FlockSpec.none()
var _hold := HoldSpec.none()
var _lethal := LethalSpec.none()
var _pursuit: PursuitSpec = null
var _notice: NoticeSpec = null
var _hunts: HuntSpec = null
var _hunting: HuntSpec = null
var _vehicle: VehicleSpec = null
var _abduction: AbductionSpec = null
var _aftermath := Aftermath.none()


## A draft of the row called `row_id`.
func _init(row_id: String) -> void:
	_id = row_id


## A draft holding every setting and part this one holds, so writing the copy never writes this
## one (the dictionary and the array are copied; a part is a value and is shared).
func copy() -> EventDraft:
	var twin := EventDraft.new(_id)
	twin._kind = _kind
	twin._ambient_source = _ambient_source
	twin._noun = _noun
	twin._noun_plural = _noun_plural
	twin._first_day = _first_day
	twin._last_day = _last_day
	twin._scripted_day = _scripted_day
	twin._act_tag = _act_tag
	twin._weight = _weight
	twin._max_per_day = _max_per_day
	twin._repeat_every = _repeat_every
	twin._repeat_after = _repeat_after
	twin._duration = _duration
	twin._spawn_mode = _spawn_mode
	twin._from_day_after = _from_day_after
	twin._on_her_way = _on_her_way
	twin._sent_ahead = _sent_ahead
	twin._departs_at = _departs_at
	twin._pavement_side = _pavement_side
	twin._spans_the_street = _spans_the_street
	twin._drawn_to_sack_piles = _drawn_to_sack_piles
	twin._role = _role
	twin._counts_charges_as = _counts_charges_as
	twin._look = _look
	twin._body = _body
	twin._field = _field
	twin._warning = _warning
	twin._route = _route
	twin._flock = _flock
	twin._hold = _hold
	twin._lethal = _lethal
	twin._pursuit = _pursuit
	twin._notice = _notice
	twin._hunts = _hunts
	twin._hunting = _hunting
	twin._vehicle = _vehicle
	twin._abduction = _abduction
	twin._aftermath = _aftermath
	twin._ground_weights = _ground_weights.duplicate()
	twin._placement.assign(_placement)
	return twin


## The row this draft describes. It is handed a copy, so a draft written again after this call
## changes nothing already built.
func build() -> EventDef:
	return EventDef.new(copy())


# ------------------------------------------------------------------------- writers ---
# What a row says about itself.

## Names the row `row_id`: the new id a row derived from another takes (the lesson's dog, the two
## task guards).
func known_as(row_id: String) -> void:
	_id = row_id


## The first day the row may appear (1-based, inclusive) and the act it belongs to narratively,
## which only a scripted row's own first day reads (`EventDef.own_first_day()`).
func from_day(first: int, act: int) -> void:
	_first_day = first
	_act_tag = act


## The last day the row may appear (inclusive); a row that never expires writes none.
func until_day(last: int) -> void:
	_last_day = last


## A row that comes on a roll: the default, written where a copy says it again.
func recurring() -> void:
	_kind = GameEnums.EventKind.RECURRING


## A set piece a day owes once, which `validate()` requires to be sited from her walk.
func one_shot() -> void:
	_kind = GameEnums.EventKind.ONE_SHOT


## A row something places itself, on the exact `day` (0, the day nobody plays, for the rows only
## a director or a building places).
func scripted_on(day: int) -> void:
	_kind = GameEnums.EventKind.SCRIPTED
	_scripted_day = day


## A permanent feature of a fixed map, which `source` makes (`EventDef.AmbientSource`).
func ambient(source: EventDef.AmbientSource) -> void:
	_kind = GameEnums.EventKind.AMBIENT
	_ambient_source = source


## The tiles an instance may be placed on.
func ground(tiles: Array[int]) -> void:
	_placement.assign(tiles)


## How many times its weight the row weighs on one kind of ground (`EventDef.weight_on()`).
func weighed_on(on_ground: PlacementGround.Kind, times: float) -> void:
	_ground_weights[on_ground] = times


## The lane of a sidewalk the row wants.
func in_the_lane(side: EventDef.Pavement) -> void:
	_pavement_side = side


## The row takes a whole section of its street rather than one sidewalk location.
func spanning_the_street() -> void:
	_spans_the_street = true


## The row stands by a garbage-sack pile when the ground lets it.
func drawn_to_sack_piles() -> void:
	_drawn_to_sack_piles = true


## How often the row is drawn against the others (`weight`) and the most of it a day stands
## (`most`).
func drawn(weight: float, most: int) -> void:
	_weight = weight
	_max_per_day = most


## What the run log calls one of the row and several of it.
func counted_as(noun: String, noun_plural: String) -> void:
	_noun = noun
	_noun_plural = noun_plural


## The name its charges are counted under when it is not its own id.
func charges_counted_as(row_id: String) -> void:
	_counts_charges_as = row_id


## Seconds at full strength; 0 lasts the whole day.
func lasts(seconds: float) -> void:
	_duration = seconds


## How fast it removes itself from the scene when it is over, in px/s.
func leaves_at(speed: float) -> void:
	_departs_at = speed


## Seconds from one of its instances coming to the next, and from one being done to the next.
func comes_again(every: float, after: float) -> void:
	_repeat_every = every
	_repeat_after = after


## How the row is sited.
func sited(mode: EventDef.SpawnMode) -> void:
	_spawn_mode = mode


## From the day after `day` the row is sited as `mode` says and notices her as `how` says (null
## for no wait).
func switching_after(day: int, mode: EventDef.SpawnMode, how: NoticeSpec) -> void:
	_from_day_after = DaySwitch.after(day, mode, how)


## Her walk sites the row (`OnHerWay`): on a tile of its own ground, or at a building's front it
## pastes.
func sited_from_her_walk(at_a_front: bool) -> void:
	_on_her_way = OnHerWay.at_a_front() if at_a_front else OnHerWay.on_its_ground()


## The dawn or a unit's draw places the row, not her walk: what a copy of a row her walk sites
## says when its building alone places it.
func not_sited_from_her_walk() -> void:
	_on_her_way = null


## The director sends the row ahead of her on an ordinary day, the way `how` says.
func sent_ahead(how: SentAhead) -> void:
	_sent_ahead = how


## The part the row plays in a system beside the catalogue.
func plays(part: EventDef.Role) -> void:
	_role = part


# -------------------------------------------------------------------- part writers ---
# One per ability: the row holds each part's plain default until one is written.

## What it is on the ground.
func body(spec: BodySpec) -> void:
	_body = spec


## The noise it adds.
func field(spec: FieldSpec) -> void:
	_field = spec


## Whether its catch ends the day, and where it is measured from.
func lethal(spec: LethalSpec) -> void:
	_lethal = spec


## What it holds her for when she comes to it.
func hold(spec: HoldSpec) -> void:
	_hold = spec


## How it warns of its coming.
func warning(spec: WarningSpec) -> void:
	_warning = spec


## How it notices her; null for a row with no wait.
func notice(spec: NoticeSpec) -> void:
	_notice = spec


## How it comes after her; null for a row that does not pursue.
func pursuit(spec: PursuitSpec) -> void:
	_pursuit = spec


## How it travels.
func route(spec: RouteSpec) -> void:
	_route = spec


## How many creatures it is and how far they spread.
func flock(spec: FlockSpec) -> void:
	_flock = spec


## How it is drawn.
func look(spec: LookSpec) -> void:
	_look = spec


## The car that drives, or null for anything else.
func vehicle(spec: VehicleSpec) -> void:
	_vehicle = spec


## How it hunts her once the resistance has heated it; null for a row that answers to nothing.
func hunt(spec: HuntSpec) -> void:
	_hunts = spec


## The hunt a heated copy carries (`EventDef.at_heat()` writes it; no catalogue row does).
func hunting(spec: HuntSpec) -> void:
	_hunting = spec


## How it takes a bystander first; null for a row that takes nobody.
func abduction(spec: AbductionSpec) -> void:
	_abduction = spec


## The rows it brings after it.
func aftermath(spec: Aftermath) -> void:
	_aftermath = spec


# ------------------------------------------------------------------------- readers ---
# Asked by `EventDef` alone, when it takes this draft's settings.

## The weight on each kind of ground, as a copy.
func drafted_ground_weights() -> Dictionary:
	return _ground_weights.duplicate()


## The tiles it is placed on, as a copy.
func drafted_ground() -> Array[int]:
	var tiles: Array[int] = []
	tiles.assign(_placement)
	return tiles


func drafted_id() -> String:
	return _id


func drafted_kind() -> GameEnums.EventKind:
	return _kind


func drafted_ambient_source() -> EventDef.AmbientSource:
	return _ambient_source


func drafted_noun() -> String:
	return _noun


func drafted_noun_plural() -> String:
	return _noun_plural


func drafted_first_day() -> int:
	return _first_day


func drafted_last_day() -> int:
	return _last_day


func drafted_scripted_day() -> int:
	return _scripted_day


func drafted_act() -> int:
	return _act_tag


func drafted_weight() -> float:
	return _weight


func drafted_most_per_day() -> int:
	return _max_per_day


func drafted_repeat_every() -> float:
	return _repeat_every


func drafted_repeat_after() -> float:
	return _repeat_after


func drafted_duration() -> float:
	return _duration


func drafted_spawn_mode() -> EventDef.SpawnMode:
	return _spawn_mode


func drafted_switch() -> DaySwitch:
	return _from_day_after


func drafted_her_walk() -> OnHerWay:
	return _on_her_way


func drafted_sent_ahead() -> SentAhead:
	return _sent_ahead


func drafted_departs_at() -> float:
	return _departs_at


func drafted_lane() -> EventDef.Pavement:
	return _pavement_side


func drafted_spans_the_street() -> bool:
	return _spans_the_street


func drafted_is_drawn_to_sack_piles() -> bool:
	return _drawn_to_sack_piles


func drafted_role() -> EventDef.Role:
	return _role


func drafted_charges_counted_as() -> String:
	return _counts_charges_as


func drafted_body() -> BodySpec:
	return _body


func drafted_field() -> FieldSpec:
	return _field


func drafted_lethal() -> LethalSpec:
	return _lethal


func drafted_hold() -> HoldSpec:
	return _hold


func drafted_warning() -> WarningSpec:
	return _warning


func drafted_notice() -> NoticeSpec:
	return _notice


func drafted_pursuit() -> PursuitSpec:
	return _pursuit


func drafted_route() -> RouteSpec:
	return _route


func drafted_flock() -> FlockSpec:
	return _flock


func drafted_look() -> LookSpec:
	return _look


func drafted_vehicle() -> VehicleSpec:
	return _vehicle


func drafted_hunt() -> HuntSpec:
	return _hunts


func drafted_hunting() -> HuntSpec:
	return _hunting


func drafted_abduction() -> AbductionSpec:
	return _abduction


func drafted_aftermath() -> Aftermath:
	return _aftermath

