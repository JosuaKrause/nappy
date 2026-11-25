# Event routes layer, seed 77, day 4

**Claim.** `--layers 5,7` draws both route layers at once: layer 5's purple lines are her day's planned routes, layer 7's hot-pink lines
are each live event's own route, a dot at its start and a square at its end (a patrol's street, a dog walker's block). Nothing about
how an event draws itself changes.

**Limit.** One still on one build, so it shows the layer drawn, not that a row's route is cut at its street and junction boxes; no
build before this branch has the layer to compare with.

**Source revision.** Branch `feature-route-overlay`, on `origin/main` da1daf08d.

**Command.** `RESOLUTION=1920x1080 tools/shot.sh out.png 8 --seed 77 --day 4 --walk 2s3e --invincible --layers 5,7 --zoom 0.35 --no-save`
(`--zoom 0.35` shows the view wider than a player sees; `--invincible` keeps the day running).

**Kept.** `layers-5-7-seed77-day4.png` alone; the run's log is not needed for the claim.
