# snowy-kestrel — A red-arrow task's destination draws no chalk mark · 2026-10-10


[Azure-koala](../playtests/2026-10-07-azure-koala.md), finding 6, inbox #601:

> red arrow tasks show a chalk mark at their destination

And in this session, playing v0.26.0: "the alleys should have a chalk mark but the tasks also had
them which is wrong", then "let's do that since it shouldn't be a big change".

**Which days.** `ContactPoint._draw()` skipped the chalk picture only for a contact riding an event,
and `ResistanceDirector._begin_step()` builds a task standing on a bare point with no rider, so the
chalk mark was drawn under the red arrow at four destinations, and its touched picture stayed once
the task was done: day 9's district door (its gatehouse), day 11's loudspeaker mast, day 12's swing
and day 14's power station door. Days 6, 7, 8, 10 and 13 ride an event (the man shouting, the van,
the burnt shell, the neighbor, a roadblock) and never drew one.

**Built in PR #662**: `ContactPoint.draws_a_mark()` is true only for a pickup's own step, and
`_draw()` asks it, so only the alley's mark draws chalk, read or unread; a destination draws
nothing of its own. The arrow's target, the completion rules and the pickup's mark and touched
picture ([M100, the chalk mark is its picture](2026-09-24-M100-the-chalk-mark-is-its-picture-and-a-touch-changes-the-picture.md))
are unchanged. *Read as, open to correction:* "its own task item" is the thing the world already
draws there (the gatehouse, the mast, the swing, the door) with the arrow on it; no new destination
picture is added. `tests/test_destination_drawing.gd` plays days 6 to 14 in the real day order on
seed 4242 and holds that the mark draws, the read mark keeps its touched picture, a destination
draws nothing untouched or done, and the arrow ends on it; with the old rule back it fails on
exactly days 9, 11, 12 and 14. The before and after sheets of each day are in
[destination-2026-10-10](../evidence/destination-2026-10-10/README.md).
