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

The shared bag and the pelican drawn from it are in the
[pebbly-ibis record](../../decisions/2026-10-05-pebbly-ibis.md). What stays open is
[check-against-the-counter.md](check-against-the-counter.md).
