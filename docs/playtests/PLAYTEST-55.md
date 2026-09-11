# Playtest 55 — 2026-09-10

A desktop debug run on `main` at the M61 field merge, started with `--day 7` to see the regions
and their checkpoints for the first time, on seed 3045005721. The run folder is copied under
`docs/evidence/` when the session ends. The first picture is `006s-attempt2-asked.png` from that
run: a roadblock band across the street south of a checkpoint hut and a boom gate, the robber's
silhouette on a roof, and a chalk mark on the carriageway behind the band.

## Barriers in front of a checkpoint

> the barriers are oddly placed. why would they be in front of a checkpoint? a path would create a
> checkpoint but the barrier suggests that the road is blocked and in fact there is no way to
> actually get to the checkpoint here.

> but the checkpoint suggests that there was a path planned through so there shouldn't be a
> barrier

> this shouldn't happen by construction

The bands are the `roadblock` row, which is placed on any road or crossing tile from day 7 and
knows nothing about the region wall's doors. Filed under M100's blocked-street defect, whose fix —
placement keyed on the segment — is the same fix, and the player's principle is the rule: a door is
where the day's route passes, so its ground is never among the candidate tiles a blocking row can
be offered, refused where the scheduler already refuses closed tiles rather than checked or
repaired afterwards.

## The robber on the roof, and the mark out of reach

> also the robber is inside the roof as usual and there is no way to even reach the chalk mark.

A re-report of M100's robber defect (playtests 50 and this one); the mark is behind the same
band, so the two findings share the first fix.

## The barrier does not read as one thing

> the barrier itself also doesn't read as a continuous element. is it using the texture of the
> other orientation and concatenating that one?

It repeats one picture — `checkpoint_block.svg`, a 22×30 concrete block with a hazard panel —
along the band, with no end cap and no orientation sibling, so a band is a row of identical
blocks. Filed under M100.

## Cars through barriers and checkpoints

> also cars go through the barriers and checkpoints

A re-report of playtest 52's finding, widened: not only the seals but the region walls, their
doors with the checkpoints on them, and the roadblock bands are driven through. Added to M110,
the crowd goes round a seal, which now covers every body that holds a street.

## The inspection

> the checkpoint itself, 2s should be enough -- both the guard and the player should disappear
> during the inspection, the camera should center on the hut (use a smooth ease in out for non
> player caused camera movement if possible) after the inspection the player and the guard should
> reappear

Filed as M113, the inspection reads as one. The hold today is `Tuning.CHECKPOINT_DETAIN_SECONDS`
at 6 seconds, and nothing else happens while she is held.
