# Playtest 114 — The man shouting did not change; everything around him did

2026-09-20. Said in conversation, about [PLAYTEST-112](PLAYTEST-112.md)'s finding that no number
of his differs between `v0.13.1` and `v0.14.0`. No run attached.

## What the player said

> "the reason you could find any difference is because we didn't change the yeller but we
> changed everything around him. the decay rate etc etc"

Read as *could not find*: the comparison found nothing because it looked at his row, and the
row is not what moved.

Later the same session, on the two pull requests the session's work ends in — M174, the man
shouting costs nothing to walk beside, and M102, the finale's open item:

> "merge all"

After the orchestrator's answer to the first message, on whether the drift can be designed out:

> "is there a better way than having four numbers to control what actually happens? we adjust
> one thing but then forget to adjust other things in lockstep the balance is off."

Two options were put back. **Option 1**: a row declares the net cost the player feels — what
the bar does walking beside it, baby awake, net of the walking decay — from a few named tiers,
and its gross `intensity` is computed from that, the decay and the pulse's mean, with one test
per row that the measured rise is what it declared; recommended. **Option 2**: keep the gross
numbers and add a test per row that its net rise stays above a floor, which catches the drift
and fixes nothing. The player's answer:

> "we can do option 1 and take the radius into account as well. meaning we compute numbers
> close by and at various distances. those numbers gets automatically computed/updated but
> also checked in so we can see in the diff where the balance changed"

That is M175, a row states what it costs, and the cost table is checked in, in `TODO.md`.

## What the repository says

**The player is right, and the record names the change.** `homeless_yeller`'s intensity has
been 14 since 2026-08-28, and at arm's length its five-second pulse averages 8.75 points a
second. M117, excitement decays visibly on quiet ground (`DECISIONS.md`), raised
`Tuning.EXCITEMENT_DECAY_WALKING` from 3.5 to 6.0 a second on 2026-09-12. Walking beside him
netted about 5.3 a second against the decay his row was tuned under and nets about 2.8 against
today's; with the baby asleep it went from little to nothing. `loose_dog` and `dog_walker` kept
their numbers across the same change.

## What follows for M174

1. **The rows move, not the ground.** M117's quiet-street recovery is the player's own
   priority fix from playtest 63 and stays where it is; the three named rows are re-tuned
   against the decay the game has now.
2. **The proposal is shown against what each row cost when it was tuned**: the net rise beside
   it under the 3.5 a second decay, under today's 6.0, and under the proposed numbers.
3. **Every other row that went the same way is measured and listed, and not changed.** A row
   whose walk-beside net rise is at or below nothing with the baby awake is in the same
   position as the man shouting. [PLAYTEST-113](PLAYTEST-113.md)'s "notably" names three rows
   without closing the list, and extending it is the player's call.
4. **"merge all" is the merge permission for this session's two pull requests.** The player
   asked earlier in the session to see M174's proposed numbers before they merge; the numbers
   are put in front of the player when the pull request is ready, and it merges on green after
   that.
