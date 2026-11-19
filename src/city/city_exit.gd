class_name CityExit
extends RefCounted
## The city's two ways out: the tunnel at the north end of the spine and the bridge at its south
## end, as a value every layer may name.
##
## The escape's last section ends at one of them (`DaySpec.Goal.CITY_EDGE`): the finale grows one
## chain to each (`FinalePlanner`), the day's spec holds where each stands (`DaySpec.exit_points()`),
## the day reports which one she reached (`DayController.exit_taken()`, `DayEnd.exit_taken()`,
## `EventBus.escape_out`), and the ending screen's sentence is keyed on it (`Texts.FINALE_BODY`).
## The texts and the spec are data, so the kind is data too; drawing the tunnel and the bridge is
## `CityEdge`'s, whose own pieces (`CityEdge.Piece`) are not this type.
##
## **It travels as an `int`**, -1 for no way out taken, through the day's result and the signal:
## nothing stores its numeric value, so a reader compares it with `Kind`'s members, never a number.

enum Kind {
	TUNNEL,  ## North: the spine runs on under the mountain.
	BRIDGE,  ## South: the spine runs on over the water.
}

## The way out's word, "tunnel" or "bridge", for a line of the run log. `kind` is an `int`
## because the kind travels as one, and a parameter typed as this script's enum refuses a value
## another script typed as `CityExit.Kind` (**godot**'s rare traps, "A cross-script enum").
## **Any value but `TUNNEL` reads as "bridge"**, -1 included, so a caller checks for no way out
## taken (-1) first, as `TelemetryObserver._won_line()` does; a finale chain's kind is always a
## member.
static func name_of(kind: int) -> String:
	return "tunnel" if kind == Kind.TUNNEL else "bridge"
