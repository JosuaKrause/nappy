# bouncy-swan — The phone's lag spikes are found and fixed · 2026-10-11

[coral-lark](../playtests/2026-10-11-coral-lark.md), #670: "there are big lag spikes in the last few
days"; "I reported it earlier as soft lock but now I also encountered non-soft lock versions". Then
[velvet-marten](../playtests/2026-10-11-velvet-marten.md), #701: "the lag spike explanation might
also be the explanation for the soft lock -- let's audit the placement code for guaranteed and
bounded completion".

**What the spike was.** Day 9's longest frame in velvet-marten's phone record (775 ms, 748 ms of it
`events`) reproduces natively as one tick inside `EventManager._site_what_is_on_her_way`: once a
second the director asks `WalkSiting.ahead_of` for each of about twelve unplaced `poster_crew`
copies, each is offered one tile, and `EventScheduler._best_of` re-ran the whole rule chain on that
same tile `EVENT_PLACEMENT_TRIES` (24) times against every plan of the day before refusing it.

**What is built.** `_best_of()` judges each candidate once per call (the rule chain is `_judge()`),
and a director's look shares its verdicts across the copies it asks about
(`WalkSiting.begin_look()`/`end_look()`), dropping them whenever the look places or moves a plan;
`WalkSiting._offer_ahead()` works out a look's offer, widening included, once. Every random draw
still happens in the same order, so every placement is the same: the replayed day-9 looks match on
position and all three siting streams, a shadow copy of the old loop disagreed nowhere across days
6, 7, 9 and 12, and fourteen days of three seeds plan byte-identically. On an Apple M2 the stalled
day-9 look fell from about 280 ms to about 8 ms, and day 12's worst looks (seed 13) from up to 0.7 s
to under 17 ms. `tests/test_siting_judges_once.gd` fails if either memo goes. Beside it, two
super-linear rescans became once-per-call (`MastSites`' door points, the mouse's sack piles) and
`_a_beat_reaches_a_way_out()`'s `while true` is bounded by the run's length, all without moving a
placement. The evidence and the audit's table are in
[bouncy-swan-phone-records-2026-10-11](../evidence/bouncy-swan-phone-records-2026-10-11/README.md).

**What the audit says.** No placement loop can run for ever. Several refusals repeat every look or
every frame (the director's due head, the fire engine's summons, a leaving body's out-of-sight
search, day 13's column), and none holds up anything a day needs to end. Day 12's softlock (azure-koala,
finding 9) is very likely this family on v0.25.4, but nothing in placement locks the game outright;
it stays open in the entry until a phone frame record on day 12 settles it.

*Chosen by the implementer, open to overturn:* the memo keys (the row definition's own object, its
role, the tile and the path); verdicts are dropped before and after re-asking about a plan already
placed, which is then judged without its own body; the look-wide verdicts are used only inside the
director's look; a test rather than a probe pins it.
