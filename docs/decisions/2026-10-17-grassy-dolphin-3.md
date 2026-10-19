# grassy-dolphin — The meter does not fall in the escape's basement · 2026-10-17

Told that a rig walking the basement past its three vents from an empty meter lost the section only
when caught at a late vent in 1 of 11 arrival phases, and at all three in 2 of 11 (the measurement
in [grassy-dolphin](2026-10-17-grassy-dolphin.md)), the player (inbox #765 in minty-lemur): "Well you gotta time the vents that's the whole point. You shouldn't get
through without timing it". Offered a target — from an empty meter, walking straight through without
timing loses every time, one mistimed vent of three still gets her through, a well-timed walk stays
comfortable — and two ways to it keeping 40 to 50 a blow, (A) the meter does not fall in the
basement or (B) a blow stops her where she stands: "Sure let's not replenish the meter in the
basement it's a tense situation."

**Built (PR #766).** The ground's decay multiplier, the shape calm, alley and main-road ground
already have: `InteriorScene.decay_multiplier()` answers
`Tuning.EXCITEMENT_DECAY_BASEMENT_MULTIPLIER` (0.0) on basement tiles and 1.0 everywhere else in
the building, awake or asleep; sleepiness is untouched. Each blow still costs 44 awake and 24 asleep
at 30px from a vent, and the worst pocket between two vents 84 of 100.
`tests/test_interior.gd`'s `_test_the_meter_does_not_fall_in_the_basement` pins the decay.

**Measured** (`tests/basement_walk_rig.gd`, run by the probe `tests/probes/basement_meter.gd`: steam
alone, from an empty meter, 22 arrival phases 8.3s apart, 25 start delays each). Awake, a straight
untimed walk now peaks at 59 on average and loses in 2 of 22 phases (was 47 and 1), and in 4 of 22
no vent holds it at all; a walk no vent holds peaks at 53 at worst (was 37); one vent holding her
reaches 82 to 100 at worst. Asleep, at about 0.55 of awake, she never loses the section.

**The target is not met, and the player accepted it as it is** (inbox #765 in minty-lemur), told the result with
the options to retime the vents, have a blow stop her, or accept it, and asked whether a sleeping
baby should stay spared: "Also accept it how steam is I will mention it again if I notice
anything". Read as: nothing further changes about the steam or the vents, asleep included.

**Choices open to overturn:** a loss is the meter reaching 100, as grassy-dolphin measured it; the
rig and probe are not run by any suite, so the table above is a measurement, not a pin.
