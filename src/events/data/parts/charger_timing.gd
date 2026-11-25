class_name ChargerTiming
extends RefCounted
## **How every charger's warning and notice are played in a run**: how long a charger warns before
## it charges, and how far its notice reaches against the radius its row is written with. The
## catalogue builds its rows from one of these (`EventCatalogue.use_charger_timing()`): the shipped
## one (`EventCatalogue.shipped_charger_timing()`), or the one a run asks for with `--chargers` or
## `?chargers=` (`RunConfig.charger_timing()`), so other numbers can be played on the released
## page without a rebuild (minty-dolphin #834).
##
## **What it reaches**: every charger that waits for her warns inside its one radius for
## `warning()` (`PursuitSpec.warns_for()`: the waiting dog, the alley robber and every man drawn
## as him, the hunting roadblock's guard), a door's crossing warns for it
## (`CheckpointController`), and every notice radius a charger is set off by is drawn at
## `notice()` of its written one (`EventDef.notice_within()`: those three, and the hunting vans
## that let their men out and the investigating patrol car that lets its policeman out,
## `EventDef.at_heat()`). **What it does not**: the masked man on the escape's stairs, whom a place
## sets off, the exception to the regular warning (curly-moose #803); and the heads-up of a man who
## gets out beside her or is sent at her, `Tuning.WARNING_ALONE_MAX`, already at the floor
## `Tuning.OFFSCREEN_WARNING_MIN` every charger's warning is held to.

## The least and the most a run may draw the notice radii at against their written ones
## (`DevFlags` refuses a factor outside them). Near the least, the waiting dog's radius comes down
## to its own stand-off, which the catalogue's pursuit contract refuses
## (`Tuning.validate_pursuit()`); at the most, the alley robber's reaches half the view's width
## (`Tuning.VIEW_HALF_EXTENT`), and a charger notices her only with his warning in her view, so a
## radius past it would never be met.
const LEAST_REACH := 0.85
const MOST_REACH := 1.4

## Seconds a charger warns before it charges; see `warning()`.
var _warning := 0.0
## The factor every written notice radius is drawn at; see `notice()`.
var _reach := 1.0

## A timing warning for `warning` seconds with every notice radius at `reach` times its written
## one.
static func of(warning: float, reach: float) -> ChargerTiming:
	var timing := ChargerTiming.new()
	timing._warning = warning
	timing._reach = reach
	return timing

## **How long a charger warns before it charges**, in seconds: a charger that waits for her, from
## the frame it notices her inside its one radius, and a door's guard, from the frame she crosses
## its line. Back out first, nothing comes; still in when it has run, he charges.
func warning() -> float:
	return _warning

## **The radius a charger written to notice her within `written` px notices her within**, in px.
func notice(written: float) -> float:
	return written * _reach

## **How far a charger's field reaches**, in px, for a field written to reach `written_outer`
## around a notice written at `written_notice`: it grows or shrinks by as much as the notice does,
## so she feels him as far before he notices her as the row is written for, and he never notices
## her from outside his own field (`Tuning.validate_pursuit()`).
func field_reach(written_outer: float, written_notice: float) -> float:
	return written_outer + notice(written_notice) - written_notice

## Whether `other` plays every charger exactly as this one does.
func same_as(other: ChargerTiming) -> bool:
	return is_equal_approx(_warning, other.warning()) and is_equal_approx(notice(1.0), other.notice(1.0))
