class_name PlacementDensity
extends RefCounted
## **The declared density of the city's events**: how many events a bag holds for every hundred
## draw locations, for each view, kind of ground and act, and how many moments a day of each act
## owes her. A draw location is one a unit's draw speaks for with a small marble: a street's
## sidewalk location, a junction box, a third of an alley, a cell of a park or a square
## (`UnitRoom`). The empty marbles make up the rest of a bag (`UnitFills`); `docs/EVENTS.md`, "The
## density, and why it is a declared table", says what the numbers are and how they were set.
##
## **A cell is what the bag holds, not what the day places.** The day places less wherever its
## rules leave a row out of the draw (her route above all, whose rules keep it open), since each
## row left out makes empty likelier there (inbox #1185 in gentle-owl). There is one number, and
## it says what is in the bag: no number here corrects another. A value and nothing else.

## **The events a bag holds for every hundred draw locations**, `[view][ground][act - 1]`
## (`PlacementView.View`, `PlacementGround.Kind`, the acts of `Tuning.ACT_START_DAYS`). Seeded once
## from what main placed on 2026-11-09, each cell to two figures, and scaled once by one probe
## run where a view's total was off by more than a tenth, a scaled cell at most fifty and its last
## act no lower than its first (`docs/EVENTS.md`, "The density, and why it is a declared table").
const EVENTS_PER_HUNDRED := [
	[
		[4.8, 6.6, 7.1, 7.6],
		[9.7, 14.0, 12.0, 12.0],
		[0.0, 0.0, 0.0, 0.0],
		[4.7, 7.1, 7.3, 9.6],
	],
	[
		[8.2, 8.9, 8.9, 11.0],
		[2.5, 2.5, 2.5, 2.5],
		[6.0, 5.8, 7.9, 7.3],
		[24.0, 29.0, 34.0, 31.0],
	],
	[
		[4.2, 6.0, 7.9, 8.5],
		[6.4, 11.0, 14.0, 24.0],
		[5.1, 4.6, 12.0, 12.0],
		[27.0, 49.0, 49.0, 57.0],
	],
]

## **The moments a day of each act owes her** (`[act - 1]`): the rows the director sites in front
## of her rather than a unit draws (`DawnMoments`), as many a day as main bought on 2026-11-09,
## averaged over the act's days.
const MOMENTS_PER_ACT: Array[int] = [26, 27, 29, 32]

## **The events a bag holds for every hundred draw locations**, for a unit in `view` on `ground`
## on `day` (`UnitFills`).
static func events_per_hundred(view: PlacementView.View, ground: PlacementGround.Kind,
		day: int) -> float:
	var by_ground: Array = EVENTS_PER_HUNDRED[view]
	var by_act: Array = by_ground[ground]
	return float(by_act[Tuning.act_for_day(day) - 1])

## **The moments the day owes her on `day`** (`DawnMoments`).
static func moments_on(day: int) -> int:
	return MOMENTS_PER_ACT[Tuning.act_for_day(day) - 1]
