class_name WarningSpec
extends RefCounted
## **How a row warns of its coming**, as one value: the seconds of telegraph it gives, whether it
## holds still through them, whether its coming is announced at the screen edge, whether it is warned
## of before it exists, and how long that badge is up alone. A row holds one (`EventDef.warning()`);
## nothing changes it once it exists (a refinement returns a new value), so a row's copies share it
## by reference.
##
## **The warning time is the row's own number** (PLAYTEST-145 1): nothing about where a thing is
## created is derived from its telegraph. The fairness contract that holds it against the row's
## geometry (`Tuning.validate_event()`) is asked of the row, which spans the field and the speed.

## Seconds of visible warning before full intensity, during which it emits only
## `Tuning.TELEGRAPH_INTENSITY_FRACTION` of its peak. The catalogue's rows write their own.
const DEFAULT_SECONDS := 2.5

## Seconds of visible warning before full intensity.
var _seconds := DEFAULT_SECONDS

## **Holds still until the telegraph is over, then goes.** Right for a telegraph that is a *posture*:
## the cat crouches and then bolts, and a crouch already travelling is not a crouch. The default is
## to move from the first frame, right for anything whose telegraph is *the approach* (a fire engine
## is audible three streets away and has to cover them).
var _holds_still := false

## Whether its coming is announced (PLAYTEST-145 21). A thing telegraphs its coming only if it goes
## fast, comes toward her, and carries a heavy penalty. **One that does not is outside the
## screen-edge badge and warning-first placement, rather than exempted from them**: nothing
## announces its coming before she can see it.
var _announced := true

## Whether it only ever enters the world under a warning that runs before it exists
## (`EventManager.warn_first()`), held by the fairness contract to a flat minimum rather than a
## floor worked out from its field and speed, and its badge alone to `Tuning.WARNING_ALONE_MAX`.
var _warned_first := false

## Seconds of notice from off screen before it can be seen: its badge up alone for a pursuer warned
## of first, the closing lead of a row created at once from beyond the edge of the view.
## `charging_dog` sets it to 0.5 (`badged_for()`), the half second its badge is up alone before it is
## placed: the pursuing dog's day-3 timing is the one the others are fitted to (PLAYTEST-145 9). The
## resistance's two pursuers read the dog's own.
var _badge_notice := Tuning.OFFSCREEN_NOTICE

## A warning that lasts `seconds`: announced, moving through it, not warned of first, with the
## default notice.
static func lasting(seconds: float) -> WarningSpec:
	var spec := WarningSpec.new()
	spec._seconds = seconds
	return spec

## The same warning, holding still through its telegraph.
func holding_still() -> WarningSpec:
	var spec := _copy()
	spec._holds_still = true
	return spec

## The same warning with its coming not announced at the screen edge.
func unannounced() -> WarningSpec:
	var spec := _copy()
	spec._announced = false
	return spec

## The same warning for a row warned of before it exists.
func warned_first() -> WarningSpec:
	var spec := _copy()
	spec._warned_first = true
	return spec

## The same warning with its badge up alone for `seconds`. The day-3 dog's half second is the timing
## the other pursuers are fitted to (PLAYTEST-145 9); `_badge_notice` says which rows read it.
func badged_for(seconds: float) -> WarningSpec:
	var spec := _copy()
	spec._badge_notice = seconds
	return spec

## The same warning, no longer than `seconds`: the copy warned first has its badge cut to
## `Tuning.WARNING_ALONE_MAX`.
func cut_to(seconds: float) -> WarningSpec:
	var spec := _copy()
	spec._seconds = minf(_seconds, seconds)
	return spec

## How long its telegraph lasts, in seconds.
func telegraphs_for() -> float:
	return _seconds

## Whether it holds still through its telegraph.
func holds_still() -> bool:
	return _holds_still

## Whether its coming is announced at the screen edge.
func telegraphs_its_coming() -> bool:
	return _announced

## Whether it only enters the world under a warning that runs before it exists.
func is_warned_first() -> bool:
	return _warned_first

## How many seconds of notice it gives from off screen: its badge alone, for a row warned of first.
func badge_notice() -> float:
	return _badge_notice

func _copy() -> WarningSpec:
	var spec := WarningSpec.new()
	spec._seconds = _seconds
	spec._holds_still = _holds_still
	spec._announced = _announced
	spec._warned_first = _warned_first
	spec._badge_notice = _badge_notice
	return spec
