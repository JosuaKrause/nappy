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

**Problems the planned walks raised, each handled.** A solid can cut off the way outside the park (a
burst water main across the sidewalk and street on seed 34, burnt-out cars beside the officers'
arrival on seed 31), so a taper may cut along the park's own edge row where going round outside is
more than four tiles longer or impossible. His tape would then shut ground an officer still has to
cross, so **no taper waits for a taper and no escort waits for a taper**: a taper puts his stretches up in his own order once he
has walked past them, and a passed stretch stays owed while any officer still has to step on one of
its tiles (the taper on a later leg, the other taper's current walk and every leg still to come, an
escort's walk, the tile an officer stands on inside the park) and goes up the moment nobody does,
while its taper walks on (`_tape_what_he_can()`, `_still_stepped_on()`). The first build let one
taper wait for the other's current walk only, so a taper taped a stretch the other's later edge-row
leg had to cross, the second re-planned every frame and the first waited for him: with a busker in
the park's south edge row, seeds 19, 25, 35 and 39 never closed (the review of PR #840). A taper
still stands for her, for the park's people, for an escort beside the stretch he is about to tape,
and for those still to come out; an escort waits on no taper, so no wait cycle can form. Re-planning is bounded: an officer
whose walk is cut short 30 frames running walks the rest of it straight, noted in the run log under
the existing `contact` kind, and every new walk clears that fallback (`_set_path()`). An escort walks
straight up to the point beside his person where nothing stands between (`_way_up_to()`, through
`Navigator.trim()`); asked of the person's own tile, which their body takes, the check always failed
and he took the navigator's square steps (seed 37: about 760px against 575px). A taper's round ends off the park, the tile an officer stands on inside
holds its stretch, and the gap does not close while a taper stands inside (`_a_taper_inside()`).
Someone standing on the ground the way out crosses goes straight out from where they stand
(`_way_out_from()`): a busker standing in the gap otherwise walked back over his own body's tile and
stood for good, which hung the cordon on seeds 5 and 13, and `main`'s straight-walking cordon hangs
the same way on seed 5. An escort walks on up to his person in the same frame his way in ends. A wait
for her is made up: each leg is re-paced to the deadline, capped at the round's 0.3s-a-stretch speed;
with a person being walked out, the gap waits for them.

**Verified at test parity** (inbox #813 in curly-moose): `check.sh`, `lint.sh`,
`ci_telemetry_kinds.py`, and the whole suite shard by shard with 0 failures and no script error. With
nobody in the park and her not in the way, on all 41 parks `test_park_cordon_seeds` sweeps, the close
is within 0.25s of the deadline the cordon sets (no sooner than `Tuning.PARK_CLOSING_SECONDS`, and the
walk from where she stood to the gap plus 2s after the first officer comes into view, the plush-marten
record) and first sight within 0.25s of when it said. The busker run plays at four spots on each park
(25%/30%, 50%/94%, the middles of the east and north edge rows) until he is gone and the cordon has
closed, checking that it closes, that no officer steps onto a body's tile, and that none stalls or
re-plans; on the first build (711f5b9c) those runs failed 30 checks, 9 runs never closing. Every busker
run ends with the manager's retirement, which gives the walked-out busker's tiles back, so a later
spot on the same city meets no stale body. With a person walked out, the last gap waits for them and
their escort to come out, as plush-marten asks, so the close can come after the deadline, never
before. With her standing at the swing, all 164 busker runs close, 117 within 0.25s and 47 later:
most small parks 0.3–1.9s, the large parks up to 8.6s (seed 37 at 25%/30% 22.02s against 13.42s, the
same as `main`; seed 90210 at 25%/30% 21.70s; seed 34 in the east edge row 17.93s against 13.43s).
With her walking out from 4s, all 164 close within
0.25s of the deadline. On `main`'s straight-walking cordon,
seed 13 with a busker in the east edge row and her standing never closes; here it closes at its
deadline, 29.02s. Tests changed to hand the cordon `city.navigator`, and the busker run
in `test_park_cordon_seeds` plays at four spots and ends with the manager's retirement
(`city.events._retire_finished()`). New checks in `test_park_cordon_seeds`: no officer steps onto a tile a solid thing takes, and none stands stuck with
his walk still ahead; with the straight walks put back for one run, 19 of the 41 parks fail the first.

**Choices made where the design was silent, open to overturn:** an officer walks as a figure on foot
(`Mover.on_foot()`) with no body radius; a taper may use the park's edge row, never deeper; an owed
stretch goes up in order behind its taper, sometimes a few stretches behind him and several at once,
rather than the taper standing to wait; re-planning gives up after 30 frames; someone standing in the
gap goes straight out; each leg is re-paced, capped at the 0.3s-a-stretch speed; an escort sends his
person off once he reaches the end of his way up to them, within a tile and a half, and re-plans if
they move half a tile; a walk blocked by something put down after it was planned is re-planned from
where the officer stands (the seeds suite holds this at 0); where the spot 18px behind the first
taper is blocked, the second starts on the same spot.

**For the remeasuring step:** officers go round solid things on the park's sidewalk; where the way
outside is cut off, a taper steps into the park's edge row and back out; a stretch an officer still
has to step on goes up behind its taper, sometimes a few stretches back and several at once; a
stretch under a solid thing is taped from the nearest ground the officer can stand on, a tile or two
away; an escort walks up beside a person instead of into them; someone standing in the gap walks
straight out; a taper who was held up hurries afterwards, up to the top speed; with a person walked
out the close comes after the deadline while the gap waits for them, up to about 8.6s on a large park
with her standing (the runs above). Seed 13, a large
park, closes at 29.0s where the plush-marten record measured 26.3s over the straight walks: the
officers' way round a body counts when the deadline is set, and she still has her 2.0s beyond the
walk. Every other park matches the record: small parks at 12.0s, the large ones at 13.4–13.5s, seed
40 at 27.9s. Pictures of a taper stepping into the edge row and of an escort walking up beside the
busker.
