priority: now

# olive-badger — What she meets on her route is drawn from a marble bag · filed 2026-09-27

> "also, events should use the marble bag approach as well. that way we can control what the
> player sees on their route. right now the first mark I almost never see a yeller. after touching
> the mark a marble bag with 1/3 chance of yeller should be put in so the yeller is guaranteed to
> encounter a yeller in the next three events"

[olive-koala](../../playtests/2026-09-27-olive-koala.md), statement 2. The marble bag (`src/city/marble_bag.gd`, [PLAYTEST-125](../../playtests/PLAYTEST-125.md)):
a bag holds a fixed set of marbles in the wanted proportion and each draw removes one at random, so
over one bag the share is exact; a pre-bag can guarantee the first draws. PLAYTEST-125, statement
4 limited it to poster tears ("for now let's use this technique only for poster rips and nothing
else"); this statement extends it to events, by the player. Today a day's events are planned at
dawn by a weighted roll over the whole city (`EventScheduler`), with a few `AHEAD_OF_PLAYER` plans
placed later out of where she walks. Day 6's task, a note for the man shouting, relies on several
`homeless_yeller` rows already being live, and the player rarely meets one after the first mark.
The bags reach the events placed on her route only (the player's answer, 2026-09-27).
