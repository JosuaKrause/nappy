# Playtest 143 — The chimneys stand in front, nerves are stars, the fire is on the building, and every attempt is counted

2026-09-26. Said in conversation in several messages during the night of 2026-09-25 to 26, while
the agents for PLAYTEST-138 to 142 were running. The last message came the next morning, after
the machine had restarted. Four of the messages are about the GoatCounter counter that PR #368
builds (its playtest is PLAYTEST-141, on that PR's branch). Those answers went to that PR as
review comments and are recorded here in the player's words.

## What the player said

On buildings:

> "the chimneys of the power plant render behind the player. they should be in front. also, the
> small courtyard building needs the roofs to go around the corner (like I described with the other
> building types earlier) currently it doesn't read correctly."

On the nerves:

> "why are nerves sometimes stars and sometimes numbers? it should be consistent throughout
> (stars)"

On the burning building:

> "the fire of the burning building is on the street -- the building itself is not burning"

On the pedestrian street:

> "on the pedestrian street people don't turn around when their path is blocked so they accumulate
> on obstacles"

On the day 7 brief:

> "\"The same face is on most of them.\" should go on its own line completely"

On the chalk mark:

> "chalk marks don't get properly reset on failed days accumulating more and more chalk marks in
> the same alley"

On the red arrow:

> "the red arrow for the van does not end on the van"

On the counter:

> "does the nappy goatcounter properly count each individual entry? with websites a hash is
> generated so reloads don't get double counted. is that the case with nappy or is the hash tied to
> the current run?"

> "no, even current run wouldn't work if the player dies multiple times on the same day"

> "we need a telemetry item for ripping posters and pursuit triggered by poster ripping"

> "hmm it seems like the metrics collect only once for that hash -- so either the hash needs to
> change or we need to turn that off"

> "is there a way to do this without turning off sessions completely?"

> "is telemetry currently correctly identifying when a player plays with keys?"

The answers given: GoatCounter's session hash (site, browser and IP, kept 8 hours) counts each
path once per session; nappy computes no hash of its own. A run begun with a key is reported as
tap. Two ways were offered: a separate site with sessions off, or an attempt number in each path.
The player chose the first:

> "I create a new goatcounter account without session."

> "`<script data-goatcounter="https://nappy.goatcounter.com/count" async src="//gc.zgo.at/count.js"></script>`
> -- use this for nappy stats. for the site visit stat use the old account"

On the pause screen's held restart, answering the question whether it restarts the day or starts a
new game:

> "restart button restarts the game from scratch -- not sure why that was ever a question?"

## The statements

1. **The power station's chimneys are drawn in front of her** when she walks behind them.
   → M215.
2. **The small courtyard building's roofs go around the corner**, as a roof does on the other
   building types. The player's earlier description is PLAYTEST-138's roof that extends "from the
   bottom building above to the roof of the top building" (M203, PR #365). Today a courtyard
   block is split into separate rectangles around its hole, and their roofs meet edge to edge.
   → M216.
3. **Nerves are stars on every screen.** Today some screens say "3 nerves left". → M217.
4. **The burning building burns.** The fire is drawn on the building. Today it stands on the
   sidewalk in front of an unharmed facade. → M218.
5. **On a pedestrian street a walker whose path is blocked turns round**, as on any other street,
   instead of piling up at the obstacle. → M219.
6. **"The same face is on most of them." starts its own line** on the day 7 brief. → M220.
7. **A failed day leaves no chalk mark behind.** Retrying a day shows one mark, not one more mark
   per attempt in the same alley. → M221.
8. **The red arrow for the van ends on the van.** → M222.
9. **Every event is counted every time.** The game's events go to a separate GoatCounter site,
   `nappy.goatcounter.com`, with sessions off. The page visit stays on the old site, where a visit
   is still a unique visitor. → PR #368, review comments of 2026-09-26.
10. **Tearing a poster, and a pursuit a tear draws, are both counted.** → PR #368.
11. **A player who plays with keys is counted as a keys player.** Today such a player is counted
    as a tap player. → PR #368.
12. **The pause screen's held restart starts a new game from scratch.** It never restarts the
    day. PLAYTEST-142's statement 3 says "restarts the day"; that wording was the filing
    session's, not the player's, and M211 now says what the player means.
