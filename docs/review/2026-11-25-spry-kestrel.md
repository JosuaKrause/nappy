# spry-kestrel — See the escape building's flashes with and without a least gap · 2026-11-25

**What to do.** Play the escape's building twice from the same seed, once with no gap and once with
the city's gap, and compare how its windows flash:

- No gap, the building as it plays today: `tools/run.sh --seed 4242 --start-escape`
- With a gap of 0.4 s, the city's limit: `tools/run.sh --seed 4242 --start-escape --building-flash-gap 0.4`
- On the web (a local export served by `tools/serve-web.sh`, or the published page once a release
  carries the flag), the same two as `?debug=1&escape=1&seed=4242` and
  `?debug=1&escape=1&seed=4242&buildingflashgap=0.4`.

Stay in the building's hallways for a minute or two, near the windows, and let a few explosions go
off outside.

**Where to look.** The hallway windows: how often they light, whether two ever light close together
(with no gap a flash can follow another within a fraction of a second, and 6.3% of 20,000 simulated
walks hold four flashes in a second), and whether the building reads like the city's sky or like its
own, busier thing. Both runs flash all the windows together; only how soon one may follow another
differs.

**The question a run answers.** Should the building keep its own timing, the player's curve between
a tenth of a second and five seconds, or take the city's limit of no flash within 0.4 s of the last
one, so that the two escape sections flash alike?

**Proposed, not asked for:** the flag's name, `--building-flash-gap`, and its web twin
`?buildingflashgap=`. The game plays no gap until the player answers.
