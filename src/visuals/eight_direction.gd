class_name EightDirection
extends RefCounted
## The eight-sector heading selector shared by every eight-view actor family.
##
## Every such family draws one of eight upright projections indexed clockwise from east
## (`heading.angle() == 0`): 0 E, 1 SE, 2 S, 3 SW, 4 W, 5 NW, 6 N, 7 NE. Y grows downward on this
## screen, so a clockwise angle sweep runs east then south rather than east then north. Sectors 3,
## 4 and 5 mirror sectors 1, 0 and 7 about the feet anchor — the explicit west-mirror convention
## `docs/GRAPHICS.md` records for every eight-view family, so only the east-facing half of one is
## ever authored.
##
## `SECTOR_DEGREES` and `HYSTERESIS_DEGREES` were `Stroller`'s own two constants before this file
## existed; they moved here so `CrowdAgent`'s walkers pick a view the identical way instead of a
## second, slightly different, if-chain. A 5° hold past each 22.5° boundary stops float noise
## chattering the artwork while the facing underneath stays continuous — see
## docs/DECISIONS.md, "Eight-direction style transfer".
##
## Kept stateless and static rather than an instance a caller holds: the sector actually shown is
## the caller's own state (`Stroller._view_direction`, `CrowdAgent._walker_view`), and each caller
## already has its own place to keep one int — a wrapper object here would only be a second name
## for the same field.

const SECTOR_DEGREES := 22.5
const HYSTERESIS_DEGREES := 5.0

## The nearest of the eight sectors for `heading`, with no hold. For a fresh placement — a day
## start, a new spawn, a recycle — there is no previous facing worth preserving, so the caller
## wants the exact nearest view rather than whatever a hold would carry in from before.
static func nearest(heading: Vector2) -> int:
	var angle := fposmod(rad_to_deg(heading.angle()), 360.0)
	return int(floor((angle + SECTOR_DEGREES) / 45.0)) % 8

## The sector to show this frame, given the one shown last frame and this frame's heading.
##
## `current` is kept in three cases: `heading`'s length is at or below `idle_threshold` (a body at
## rest keeps facing however it stopped, rather than snapping to whatever direction a near-zero
## residual velocity happens to point in — the caller passes `0.0`, the default, when its own
## heading is never actually zero, the way `Stroller.facing` never is); the nearest sector has not
## changed; or it has, but by less than `SECTOR_DEGREES + HYSTERESIS_DEGREES` of arc from the
## sector already shown — the hold that keeps a facing sitting exactly on a boundary from
## flickering between its two neighbours.
static func update(current: int, heading: Vector2, idle_threshold: float = 0.0) -> int:
	if heading.length() <= idle_threshold:
		return current
	var candidate := nearest(heading)
	if candidate == current:
		return current
	var angle := fposmod(rad_to_deg(heading.angle()), 360.0)
	var current_angle := float(current) * 45.0
	var difference := absf(fposmod(angle - current_angle + 180.0, 360.0) - 180.0)
	if difference > SECTOR_DEGREES + HYSTERESIS_DEGREES:
		return candidate
	return current

## Whether `sector` mirrors its east-authored partner about the feet anchor.
static func is_mirrored(sector: int) -> bool:
	return sector == 3 or sector == 4 or sector == 5
