# Playtest 113 — Three obstacles weigh more, the halo follows the bar, and the ending is hooked up

2026-09-20. Said in conversation, in answer to [PLAYTEST-112](PLAYTEST-112.md)'s arithmetic and
the choice it put back. No run attached.

## What the player said

> "comparing to 0.13.1 obviously won't show you any changes since it was only really graphics
> changes then. let's increase the influence of those obstacles. notably, yeller, unleashed
> dog, walker with dog. also, let's fix what the halo reflects. lastly, let's also continue
> hooking up the end with an ending day brief for inside the apartment and the city escape (ie
> something along "Escape the building" and "Escape to the bridge or tunnel" or "Escape the
> city"). each the apartment and escape city are treated as their own "days" with brief and
> restart checkpoint. we keep the no nerve costs for now. the escape the building starts when
> the player has completed all tasks by the end of day 14"

## What is asked for, as statements

1. **The man shouting, the loose dog and the dog walker cost more to be near** —
   `homeless_yeller`, `loose_dog` and `dog_walker`. "Notably" names these three and does not
   close the list.
2. **The halo reflects what the bar does.** *Asked on 2026-09-08 for the gross points landed
   from a source ("trace an increase in excitement back to its constituents") · overturned by
   the player on 2026-09-20, because a source went deep red while the bar barely rose.*
3. **The finale is a run's ending, not a flag's** — M102's one open item, which waited on the
   player saying so. A run that has completed every task by the end of day 14 goes on to the
   building.
4. **The building and the city are each their own day**: each opens on a day brief — "Escape
   the building", and "Escape the city" or "Escape to the bridge or tunnel" — and each is a
   restart checkpoint.
5. **Losing either still costs no nerve**, "for now".

## What this collides with, and is asked back

M102's third answer of 2026-09-09 gives the whole sequence **one** clock, a day's 180 seconds
"counting down through both sections". Two sections that are each their own day read as two
clocks. The orchestrator builds a full day's clock per section, since that is what a day is,
and asks the player to confirm it.

## The answer, the same day

Asked with three options — a full 180 seconds per section, one 180-second clock through both
with the city checkpoint restoring the time left on arrival, or one clock with a floor on what
the city checkpoint restores — the player chose the first as it was put to them: **"180s per
section"**. Each brief starts a full `DAY_LENGTH_SECONDS` clock with milliseconds on it, and a
loss or a reopened game returns to that brief with a fresh one. *Asked on 2026-09-09 for one
clock "the same length" for the sequence · overturned by the player on 2026-09-20, because
each section is its own day and a shared clock could leave the city's checkpoint unwinnable.*
