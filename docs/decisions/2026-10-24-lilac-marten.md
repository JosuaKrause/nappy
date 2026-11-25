# lilac-marten — Every charger warns for 1.75s and notices her from a quarter farther, with a flag to play other pairs · 2026-11-25

Built for curly-moose #803 (every charger, the stairwell masked man the one exception) and
minty-dolphin #834 (the numbers found by playing them).

**What is built.** `ChargerTiming` holds one warning and one factor on every written notice radius;
the catalogue builds every row from the run's (`EventCatalogue.use_charger_timing()`), shipped as
1.75s and x1.25 (`CHARGER_WARNING`, `CHARGER_REACH`). The written radii stay what they were (the
waiting dog 130px, the alley robber and every man drawn as him 180px, `EventDef.HEAT_HUNTS_WITHIN`
180px, `EventDef.HEAT_INVESTIGATE_WITHIN` 150px), so `--chargers 2 1` (or `?debug=1&chargers=2,1`)
plays the numbers shipped before. A door's crossing warns for the same warning. A charger's field
grows with its notice; a vehicle never notices her past its own field (the patrol: 185px).

**The alley robber at 225px.** Placed in the day out of her view, a guard no longer also refuses his
notice round her (`ResistanceDirector._refused_round_her()`): out of view he notices nothing until
she brings him into it. With the notice refusal kept, a mark moved into an alley she has come near
was left unguarded wherever all of the alley lay within 225px of her (`test_resistance_alley_siting`).
Measured with `tests/probes/m213_far_end.gd` over its six cities, 717 relocations and 6 guarded
tasks: unguarded 0 at 180px and 0 at 225px with the rule as built, and 0 at both with the old
refusal too, since the probe's relocation walk does not reach the failing case; the unguarded share
of the old rule at 225px is not measured. Rejected: refusing a relocation into an alley whose guard
would stand within his notice of her, which stopped the mark moving onto the alley she stands in
(the relocation's own design). The roadblock guard's farthest spot follows his band
(`ResistanceDirector.task_guard_farthest()`), since a 225px band left no ring past it inside the
fixed 448px (`test_day13_guard`).

**The patrol's policeman.** Stopped at 185px, the car pulled away into her once its man was back
and struck her when its horn ran out; `EventCarDriving.stand_for_her()` keeps it standing while she
is in its lane within the radius it stopped at (`test_police_car`).

**The escape's roadblock.** A walker straight past a posted band is now caught some 20 to 60px past
it rather than some 260px, so the corner case of `tests/finale_rig.gd` stands its band 48 to 112px
short of the cross street.

**Open to the player:** the pair itself; a charger's field growing with its notice; a vehicle's
notice capped at its field; the view standing in for the notice refusal in the day.
