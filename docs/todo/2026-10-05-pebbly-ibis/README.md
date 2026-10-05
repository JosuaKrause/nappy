priority: now

# pebbly-ibis — The pelican is drawn from one shared bag per run · filed 2026-10-05

[feathery-lynx](../../playtests/2026-10-05-feathery-lynx.md) files inbox #575, said in a
conversation about the marble bags. It builds on the marble bag that olive-badger (what she meets
on her route is drawn from a marble bag, PR #565) has merged. **The band `now` is the player's**,
for right after the release (inbox #591 in [olive-hedgehog](../../playtests/2026-10-05-olive-hedgehog.md), of this entry with jolly-hare,
olive-badger's forced cases and sandy-ferret): "queue those items as immediately now after the
release (but don't start them this session)".

The idea, said unprompted:

> I have an idea of a shared marble bag -- the shared marble bag would contain its own marbles but can appear in regular bags multiple times. each time the shared on is drawn a marble *from* the shared one is drawn. if it's empty it gets refilled (unlike the nested one). we could use it for the biker vs pelican. have one shared biker/pelican marble bag with 399 bikers and 1 pelican and the same bag is used throughout the run. what are the expected stats on this? how likely would it be to encounter a pelican if the same bag is used throughout the run and if each day has its own shared bag for it? and how does it compare to the flat 1/400 chance?

Told that one bag per run can never give two pelicans in one run, which the flat chance does about
0.3% of the time at 30 cyclists:

> I think being able to get at most one pelican per full run is already a benefit of the approach

On a bag that outlives the run:

> if the bag outlived the run (forcing us to never delete a save but instead reset it for everything except the bag)

Asked whether to keep the bag per run, saved with the run and rewound on a retry, rather than a bag
outliving the run in a file of its own:

> let's do a bag per run but save it in the standard save file to reset the bag to the beginning of the day on a lost day. by how long does it take I meant the expected value of runs until you see at least one pelican do the p50, p90, p99

Offered a measurement of the real number of cyclists in a run, the player pointed at spry-llama
(the counter counts encounters: seen, influenced, and bouts of running), whose `seen-cyclist` and
`seen-pelican` events the counter adds up:

> that would be a good use of the telemetry for individual events ;)

**Asked for:**

- **A shared marble bag**, a kind of bag of its own: it holds its own marbles and "can appear in
  regular bags multiple times"; drawing it draws "a marble *from* the shared one"; "if it's empty
  it gets refilled (unlike the nested one)". Item `a-shared-bag.md`.
- **The pelican drawn from one shared bag of 399 cyclists and 1 pelican, the same bag for the
  whole run**, in place of today's flat 1/400 roll; at most one pelican in a full run is "already
  a benefit". It is kept in the standard save file, and a lost day sets it back to where it was at
  the beginning of that day. Item `the-pelican-bag.md`.
- **Not a bag that outlives the run**: the player chose "a bag per run", the other option needing
  the save never to be deleted, only reset "for everything except the bag".

**What it replaces.** `EventManager.rolls_a_pelican()` rolls each cyclist against
`PELICAN_SHARE`, whose doc reads "About one cyclist in four hundred, the player's own number"
(minty-hedgehog, statement 8: "One in ~400 bikers should be a pelican riding a bicycle instead.
Needs to be svg only"). Its own doc says when and how:

> Whether the rider about to be warned of for `def` is drawn as the pelican. Asked once per rider, **as its warning goes up** (`_warn_down_her_line()`), and handed to `spawn_warned()` when the warning is over, which is what keeps a rider one thing for its whole ride — and what lets the run log call it `pelican` from its first line, the badge going up, rather than only from the frame it is created *(inbox #527 in azure-tapir, the player: "logs should be correctly identifying it from the beginning")*.

> **One draw from the day's own `PELICAN_STREAM` per cyclist**, rolled whatever the answer, so the run's seed and the order the day sends its cyclists in decide which of them is the pelican, the same way they decide everything else the director sends. Nothing but a cyclist draws from it. `--pelican` (`DevFlags.pelican()`) answers yes for every one without changing what is drawn.

The roll is static and separate (`pelican_roll()`) so a test measures the share through the game's
own arithmetic, and `pelican_share` is a variable so a rig can make every rider one or the other.
Both go or change with the roll.

**What exists to build on.** `MarbleBag` (`src/city/marble_bag.gd`) is a queue of bags, refilled
from its ordinary set when empty, with nested bags: a bag marble draws from its inner bag, and an
inner bag of n is spent after n draws and never refilled, the "nested one" the player contrasts.
`MarbleBag.skip(count)` rebuilds a bag at a given number of draws, and the poster tears already
use it as a bag per run that the save keeps and a lost day rewinds: `PosterState.tears` counts the
tears drawn this run, and `PosterWalls._the_bag()` rebuilds the bag from the run's seed and skips
that many.

**Measured** ([pelican-cyclists-2026-10-05](../../evidence/pelican-cyclists-2026-10-05/README.md),
the marble-bag branch, 120 cities, days 2 to 14): a run meets 26.2 cyclists on average (median 26,
p10 22, p90 29, min 20, max 37). Runs until the first pelican, with the flat 1/400: 15.8 expected,
p50 11, p90 36, p99 70. With one bag per run: 15.3 expected, p50 11, p90 35, p99 69. A run draws at
most 37 of the bag's 400 marbles, so the bag never refills inside a run, and the chance of a pelican
in a run is exactly N/400 for N cyclists. The measurement walks one steady walk at walking pace, on
full-length days that are all won, without the real `EventManager`; the README has the rest of its
limits.

**Proposed, not asked for:**

- **The bag's state in the save is a count of cyclists drawn this run**, rebuilt from the run's
  seed and `skip()`ped to it, the way the poster tears' bag is. A lost day sets the count back to
  its value at that day's dawn, which the save already restores. The plainer alternative is saving
  the bag's marbles themselves.
- **The count rides beside the snapshot as an optional key**, read as 0 when absent, the way
  `escape_section` does in `GameSave`, so a save written before it still loads and
  `GameSave.FORMAT_VERSION` is not bumped.
- **The cyclist marbles of the route's bag become the shared bag's marbles**, so drawing a cyclist
  draws from the shared bag, the player's own picture of a shared bag that "can appear in regular
  bags multiple times". The alternative is drawing from the shared bag where `rolls_a_pelican()`
  rolls today, once per cyclist as its warning goes up. Either way the run log names the pelican
  from its badge, as inbox #527 asked.
- **A drawn shared-bag marble is spent like a plain marble**, so a regular bag holding k of them
  draws the shared bag exactly k times per fill. The alternative is the nested bag's rule, the bag
  marble going straight back into the bag it was drawn from.
- **`--pelican` still makes every cyclist a pelican**, and a rig still makes every rider one or
  the other.

**Open:** whether the measurement is checked against the real cyclists per run once spry-llama's
`seen-cyclist` and `seen-pelican` events are on the counter, as the player's "that would be a good
use of the telemetry for individual events ;)" suggests. Nothing here waits on it.
