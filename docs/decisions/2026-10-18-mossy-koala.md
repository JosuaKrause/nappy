# mossy-koala — The escape's roadblocks, and one radius per waiting charger · 2026-10-18 · not from an entry


The player (minty-lemur #771): "The roadblock in escape shouldn't appear on the path or it should be
in a way that luring away the guard is enough. Right now there are for guards and the player adds
excitement by just being close. Luring away one guard (the challenge) is not enough to make the
obstacle survivable"; then, of the seed given for testing, "still unwinnable. two roadblocks are right
next to each other and the second guard is invisible (hidden) until it already charges"; asked
whether the far guard should leave too, "He leaves too (Recommended)". On placement (minty-lemur
#785): "does the escape use the same placement rules as the regular game? ... it should, though. I saw
wood on the roof for example", and for the escape, "Don't apply" the calm-park rule and "Keep the
escape's rules" for the home's streets and per-day caps. On chargers (minty-lemur #788): baiting must
be possible, "the barrier itself *still* causes excitement" with "No cost at all, ever", "band costing
nothing should also apply to a normal day", "the challenge is the guard not the concrete", the far
guard "Days too", and then the player's own design: "We should do one radius and warn inside it for
2s. If the player leaves the radius nothing happens and the warning stops. If they stay within the
charge starts", the radius "Before we started implementing two radii" / "If the bigger of the two
makes now sense let's go with that", crossings "similar", "So we need to time each case since there
is now a heads-up", and for the stairwell guard "No delay, as on main" and "Let's show that at least"
for his screen-edge badge.

**Built (PR #781, merged for v0.29.0):**
- **The escape's roadblocks:** one a street (`Tuning.FINALE_GUARDS_PER_STREET` 2 to 1); no two
  escape roadblocks closer than twice the one radius (360px), refused at placement; a warning guard is
  drawn above the street's other figures and starts warning only with his whole picture in her view.
  The hidden guard was draw order: the second band's guard stood behind the first band and was drawn
  under it.
- **The day's ground rules in the escape:** the escape's placement asks the day's own
  `_open_ground_for()` per street (closed tiles, held streets, trees, sidewalk side, corners), with
  the escape's own exceptions the player kept. Its fixed counts per street stayed; the player later
  rejected those (minty-lemur #785), filed in downy-tapir and minty-quail.
- **The wood on the roof** was two things: the escape's alley walls (a street-sized collapsed
  frontage across a 64px alley) and the barricade's pieces centred in even shares of the street, both
  reaching over the buildings. Alley walls take the widest piece that fits the mouth; the barricade's
  outer pieces stand flush with the street's edges, on every day too, with no change to cover.
- **The band costs nothing, ever**, on a day and in the escape: the roadblock's `intensity` is 0;
  only its guard is the danger. Once the guard on her side leaves, the far guard walks off with him on
  every day, and both go round the band.
- **One radius per waiting charger, on a warning clock:** the waiting dog 130px, the alley robber
  180px, the roadblock guard 180px from his band, each the bigger of its two radii before the
  two-radius change; inside it he warns for `Tuning.CHARGER_WARNING` (2.0s); leaving resets it and
  nothing comes; staying, he charges. Running during the warning counts for nothing; only after the
  charge does running shake him off. Measured (`tests/probes/charger_warning.gd`, a 0.3s reaction):
  for warnings from 1s to 3s, turning back is never charged, standing is caught, and running 0.3s
  after the charge gets away.
- **Crossings:** walking under a raised boom (or an alley post) raises the hand of the guard across
  the road and starts the same 2s clock; back across, it is called off; still across, that hut's
  guard comes out. Day 9's door counts a walked crossing only if she is still across that door's line
  when a guard is set on her for it; a crossing made during another door's warning is held with it
  and dropped if she crosses back.
- **The stairwell guard is the one exception:** he keeps his 426px and runs the moment she comes
  within it, with no warning, as on `main`; the screen-edge badge points at him from his first
  running frame (the badge's smoothing no longer lags a charge's first frame, for every charger).

**Deferred by the player:** events walking through buildings and barricades, the guard's walk-off
included ("not now", minty-lemur #791), filed in minty-quail's `world-passability.md`.

**Choices open to overturn:** at the boom there is no approach warning, only the crossing's; a region
wall's bands cost nothing too; a guard who chased does not return to his post.
