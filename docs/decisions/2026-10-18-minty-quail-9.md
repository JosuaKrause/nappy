# minty-quail — Day 12's cordon officers walk through the navigator · 2026-10-24


minty-quail's remainder of `world-passability.md`, the refactor's ninth PR (PR #840). Every mover went
through the world's one `Navigator` except day 12's cordon officers, the police who walk in from out
of her sight and tape the park shut: their walk in and the taper's walk round the park's edge were
laid straight, at a fixed offset outside the park, through whatever the day stood there (a
`collapsed_frontage` band on the park's sidewalk, a `busker` in the park), and the close was timed
over those straight walks. Put on the navigator as they stood, an officer stalled at such a body and
the cordon never closed; made to go round, the last gap closed 15–37s late on 9 parks (minty-quail-5).
The player had asked for this class of fix at some point, not then (minty-lemur #791).

**Built.** Each officer's walk is planned round the day's solid things before he sets off
(`ParkCordon._lay()`, through `Navigator.path()`), and every step goes through `Navigator.walk()`: the
walk in, each leg of a taper's round of the park's edge, and an escort's ways in, up to his person and
out. The close is timed and each taper paced over those planned walks, so going round something is
part of the walk the deadline is set over. The cordon is handed its navigator: the director, then
`ResistanceHappenings.setup(city, map, navigator)`, then `ParkCordon.new(map, navigator, city, park,
blocked)`. `Navigator.path()` gained two optional arguments: `avoid`, a tile rectangle the way never
enters, and `near`, which ends the way beside a goal whose own body takes its tile. The straight
walks and the comment explaining why the officers were off the navigator are gone.

**Three problems the planned walks raised, each handled.** A solid can cut off the way outside the
park (a burst water main across the sidewalk and street on seed 34, burnt-out cars beside the
officers' arrival on seed 31), so a taper may cut along the park's own edge row where going round
outside is more than four tiles longer or impossible. His own tape would then shut that row behind
him, so a stretch whose tiles a later leg of his still steps on is taped at the end of that leg, a
stretch another officer's walk still steps on waits for him (seed 31), and the stretches the way out
crosses wait for everyone to come out, as the last gap already did. A wait is made up: each leg is
re-paced to the deadline, capped at the round's 0.3s-a-stretch speed.

**Verified at test parity** (inbox #813 in curly-moose): `check.sh`, `lint.sh`,
`ci_telemetry_kinds.py`, and the whole suite shard by shard with 0 failures and no script error. On
all 41 parks `test_park_cordon_seeds` sweeps, the close is within 0.25s of the deadline the cordon
sets (no sooner than `Tuning.PARK_CLOSING_SECONDS`, and the walk from where she stood to the gap plus
2s after the first officer comes into view, the plush-marten record), first sight within 0.25s of
when it said, and the busker is walked out through the last gap. Tests changed only to hand the
cordon `city.navigator`. New checks in `test_park_cordon_seeds`: no officer steps onto a tile a solid
thing takes, and none stands stuck with his walk still ahead; with the straight walks put back for one
run, 19 of the 41 parks fail the first.

**Choices made where the design was silent, open to overturn:** an officer walks as a figure on foot
(`Mover.on_foot()`) with no body radius; a taper may use the park's edge row, never deeper; taping is
put off rather than a taper walking over his own tape; each leg is re-paced, capped at the
0.3s-a-stretch speed; an escort sends his person off once he reaches the end of his way up to them,
within a tile and a half, and re-plans if they move half a tile; a walk blocked by something put down
after it was planned is re-planned from where the officer stands (the seeds suite holds this at 0);
where the spot 18px behind the first taper is blocked, the second starts on the same spot.

**For the remeasuring step:** officers go round solid things on the park's sidewalk; where the way
outside is cut off, a taper steps into the park's edge row and back out, and a few stretches go up
together a moment later; a stretch under a solid thing is taped from the nearest ground the officer
can stand on, a tile or two away; an escort walks up beside a person instead of into them; a taper
who was held up hurries afterwards, up to the top speed. Seed 13, a large park, closes at 29.0s where
the plush-marten record measured 26.3s over the straight walks: the officers' way round a body counts
when the deadline is set, and she still has her 2.0s beyond the walk. Every other park matches the
record: small parks at 12.0s, the large ones at 13.4–13.5s, seed 40 at 27.9s. Pictures of a taper
stepping into the edge row and of an escort walking up beside the busker.
