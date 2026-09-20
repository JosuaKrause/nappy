# Playtest 115 — The decay is what tuned the numbers; the dogs, the survey and the caret

2026-09-20. Said in conversation, in answer to M174's proposed numbers (the man shouting
costs nothing to walk beside) and to the questions left by M102, the finale is the run's
ending. No run attached.

## What the player said

On whether the hint line after a section's brief is redundant
([REVIEW.md](../REVIEW.md) asked):

> "Not redundant players might fast click through the briefs. The beginning of a day should
> always match"

Asked whether "always match" also meant a reopened game comes up through the title screen:

> "I meant only the hint (it always should show in the beginning even for a normal
> playthrough). The escape shouldn't behave any different than the rest of the game. If I
> load into the game and I'm at escape I see the title screen, then the brief (where I can
> play the escape or restart for a new game). increase the loose_dog and dog_walker as well.
> the "survey" should happen automatically every time and should show up in the commit diff
> if it changes. again, increasing the decay is what tuned the numbers so we need to correct
> for it! what matters for the dogs is walking past them. and it shouldn't be free. at the
> very least restore the net gain if not a bit more. caret communicates anticipated net gain.
> basically if I keep doing what I'm doing I very likely get that amount in net gain (so the
> halo will match roughly the caret if that happens)."

And a moment later, while that was being written down:

> "the same for the yeller btw. walking past (where both have different directions) is what
> matters. in my playthrough I walked next to him without effect which highlights an even
> worse drop in effect"

## What was put to the player

M174's agent raised only the man shouting: walking beside him nets +2.75 a second awake and
nothing asleep under today's 6.0 a second walking decay, +5.25 and +1.31 under the 3.5 his row
was tuned against, and +9.62 and +2.59 as proposed, by a core of 25 a second within 50px
rather than a higher `intensity`, which would have priced him as a wall. It left `loose_dog`
(+14.0 awake beside it) and `dog_walker` (+10.25) alone because both cleared the orchestrator's
walk-beside target. Both rows' intensities date from 2026-09-05, before M117 raised the decay
on 2026-09-12, so both lost 2.5 a second with everything else. The caret was left reading
gross points because the **cues** rule fixes her position in its projection, "so nothing about
her own walking can" move it; three options were offered — net of the fixed walking decay, net
of her actual state, or gross.

## What is asked for, as statements

1. **The hint line always shows at the beginning of a section**, in a normal playthrough as
   under the flag, because a brief can be clicked through. Only the hint was meant by "always
   match".
2. **The escape behaves no differently from the rest of the game.** A game loaded into the
   escape shows the title screen, then the section's brief, where the player plays the section
   or restarts for a new game. *The M102 agent's silent choice, a resume straight onto the
   brief, is overturned by the player on 2026-09-20.*
3. **`loose_dog` and `dog_walker` go up as well**: at the very least the net gain the decay
   took from them is restored, "if not a bit more".
4. **What matters for the dogs is walking past them, and it is not free.** The measure for a
   mover is the pass, where she and it go different ways, not walking beside it — and the
   man shouting is measured the same way. That walking next to him did nothing is the worse
   symptom, not the measure. *The orchestrator's walk-beside target is overturned on
   2026-09-20.*
5. **The decay is what tuned the numbers, so the rows are corrected for it** — said twice now,
   the first time in [PLAYTEST-114](PLAYTEST-114.md).
6. **The survey happens automatically every time and shows in the commit diff when it
   changes.** This is M175's checked-in cost table, a row states what it costs, and it comes
   before the rest of M175.
7. **The caret is the anticipated net gain**: what she very likely gets if she keeps doing
   what she is doing, so that the halo afterwards roughly matches what the caret said. *The
   cues rule that nothing about her own walking moves the caret is overturned by the player
   on 2026-09-20*, on the orchestrator's reading that "what I'm doing" is her current movement
   and the baby's current state; open to overturn.

## Later the same session

On what merges and ships, once the above was written down:

> "anyway. merge everything once it's complete (all the changes above that we discussed, too)"

> "and then cut a new minor release"

M174's pass figures came back with two rows short of "at the very least restore": walking
straight past, baby awake, `homeless_yeller` at about 94% of what it cost under the 3.5 decay
and `dog_walker` at about 80%, `loose_dog` at 106%. What stops the first two is
`Tuning.WALL_WORTH_OF_COST` (35 points), the walk-through cost past which a row is scheduled as
a wall and leaves the day's corridor; the line is set on purpose between `dog_walker`, which
"has to stay friction", and `leaf_blower` at 37.7, which "has to stay a wall", and a fully
restored dog walker costs more than the leaf blower does. Three options were put: merge as it
is and finish in M175, a row states what it costs; restore fully now, raising `leaf_blower` by
what the decay took from it and moving the line to sit between the two again; or let the dog
walker become a wall. The player chose **"Restore fully now"**, and added:

> "Once it's released we will do some runs and tweak the numbers by feel"
