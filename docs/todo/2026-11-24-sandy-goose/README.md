priority: now
after: 2026-10-18-minty-quail

# sandy-goose — Do the escape city's trucks, explosions, vans and roadblocks show up on her way · filed 2026-11-24

The player, of what they saw in the escape (inbox #1733 in spry-ferret): "from what I saw that was
the only actual obstacle showing up", said of the dog walker. The band `now` is the filer's
proposal, since the player named none, and it waits for minty-quail (the refactor rule). A filer
never proposes `bug` (**playtest-feedback**); a defect the check finds is filed as its own `bug`
entry.

**Read as:** the escape city's bag (`DaySpec._place_the_escape_city()`) holds 23 danger marbles, 10
military convoys, 8 finale explosions, 3 abductions and 2 roadblocks, against 9 empty over the
city's streets, so a walk through it should meet more than a dog walker. If the trucks, explosions,
vans and roadblocks do not show up on a build with minty-quail's escape work, that could be a
regression from the work that made the escape a day spec. It may also be lilac-marten's "basically
empty" (curly-moose #803), which was said of v0.29.1's bag, and then it is already queued.

**The dog walkers are explained.** The player (inbox #1741 in tawny-raven): "I was watching your
measurement runs". **Read as, the filer's:** the escape they saw was the end remeasure's picture captures,
windowed `--start-escape` runs on main, a direct boot on day 1, where the event director's day-one
rig sent two dog walkers among her first three encounters; the event director now sends nothing of
an ordinary day's rows in the escape (`DaySpec.director_sends()`), so those encounters are gone.
This check no longer asks where the dog walker came from or which build the player played.
**What remains is whether the escape's own trucks, explosions, vans and roadblocks show up on her
way**, measured on a build with the director's fix.

**Build:** a check, with a number, of whether the escape city's trucks, explosions, vans and
roadblocks appear on her way in play, on main. If the rows do not show on a build that has
minty-quail's escape work, that is a defect to file as
its own `bug` entry and fix; if they do, this entry closes with the measurement in a record.
