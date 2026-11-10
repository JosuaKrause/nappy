# Signals and the green wave

Read this before touching `TrafficSignals`, the signal cycle, `Tuning.SIGNAL_PROGRESSION_BLOCKS` or
the car population. What a light owes her when she crosses the main road is the fairness contract,
in `SKILL.md`.

**A signalled grid has a capacity, and the population has to respect it.** Signals with arbitrary
offsets stop a car at *every* junction, so the cycle is derived from the block spacing
(`SIGNAL_PROGRESSION_BLOCKS`). Junction control gives the road a throughput it did not have, so the
car population is a number about capacity as well as about noise: a car waiting at a light beside
you is louder for longer than one going past.

**The green wave serves one direction, and a two-way wave is not available at any setting.** The
arithmetic, and why the asymmetric offset is the best answer rather than a compromise, is the
`Tuning.SIGNAL_PROGRESSION_BLOCKS` docstring. Two things to carry, because the shape recurs:

- **An identity is not the property.** Asserting `cycle / travel` is an even multiple is *true* and
  pins nothing, because it is not the condition the sentence beside it claims.
  `tests/test_crowd_streets.gd` (its case in `tests/crowd_rig.gd`) walks a car down the platoon instead.
- **The stopped fraction is not the speed spread.** A car's speed drifts it against the wave, but
  it does not live long enough on the spine to drift out of a green band, and the fast half stops
  more than the slow half. The mechanism is the main arm's red share of the cycle and that only half
  the traffic gets the wave.
