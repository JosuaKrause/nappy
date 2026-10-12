# pebbly-ibis — The pelican is drawn from one shared bag per run · 2026-10-11

[feathery-lynx](../playtests/2026-10-05-feathery-lynx.md), inbox #575: "I have an idea of a shared
marble bag -- the shared marble bag would contain its own marbles but can appear in regular bags
multiple times. each time the shared on is drawn a marble *from* the shared one is drawn. if it's
empty it gets refilled (unlike the nested one). we could use it for the biker vs pelican. have one
shared biker/pelican marble bag with 399 bikers and 1 pelican and the same bag is used throughout the
run"; "I think being able to get at most one pelican per full run is already a benefit of the
approach"; "let's do a bag per run but save it in the standard save file to reset the bag to the
beginning of the day on a lost day".

**A shared bag.** `MarbleBag.shared(marbles, seed)` (`src/city/marble_bag.gd`) is a bag with its own
stream that may stand in any number of regular bags, once or several times each, and is one bag
wherever it stands: drawing a shared marble draws from it, and that is the answer. It refills from
its own marbles when empty and is never retired, unlike the nested bag. A drawn shared marble is
spent like a plain marble, so a regular bag holding k of them draws the shared bag k times per fill.
`tests/test_shared_bag.gd` holds it.

**The pelican.** `EventManager.rolls_a_pelican()` draws one marble per cyclist, as its warning goes
up, from a shared bag of 399 cyclists and 1 pelican kept for the whole run, so a run meets at most
one pelican. Its state is a count of cyclists drawn (`GameState.pelican`, `src/city/pelican_state.gd`),
rebuilt from the run's seed and `skip()`ped to it as the poster tears are; it is reset on a new run,
photographed at dawn and on a won day, and given back on a lost day, and the save carries it as an
optional `"pelican"` key read as 0 when absent, without a format bump. `--pelican` and a rig
(`PelicanRig`) override the answer without changing what is drawn. `PELICAN_SHARE` and the flat roll
are gone. `tests/test_pelican.gd` holds one pelican per 400, none twice in a run, the seed deciding,
and a lost day and a resumed save drawing the same.

*Chosen by the implementer, open to overturn:*
- **Where the draw is made.** The entry proposed that the route bag's cyclist marbles become the
  shared bag's marbles, the player's own picture of a shared bag appearing in regular bags; the
  implementer took the entry's named alternative, drawing where `rolls_a_pelican()` rolled, because
  the route bag sits in siting code another branch was editing. Which cyclists the player meets is
  the same either way; the shared bag stands in no regular bag yet.
- The pelican bag is the shared bag itself rather than a regular bag holding it; the bag is rebuilt
  whenever the run's seed or the saved count disagrees with its own draws.
