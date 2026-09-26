# Playtest 145 — The warning comes first and the thing spawns where it points, following her until it does

2026-09-26. Said in conversation, after an explanation of PR #372 (M207, a warning comes shortly
before its danger). That PR had shortened the cyclist's warning by shrinking his field from 90px to
60px, since the siting of a `hard_fail` row that travels toward her is derived from its telegraph,
and the shortest telegraph the fairness contract allows is derived from its field and its speed
(`Tuning.required_telegraph_time()`). It had then raised his `intensity` from 18.0 to 21.5 to win
back the cost the smaller field had lost.

## What the player said

> "I don't like that the warning is tied to the size of the field or the speed. how offscreen
> warnings and placements should work is that the warning appears by itself with a reasonable
> position and when the time is right the object is spawned in at that location just offscreen.
> that way even if you keep moving the object will move with you until it is actually spawned"

Asked whether the waiting spawn point follows her off the thing's own line (the cyclist's sidewalk,
if she crosses the street), which events it covers (everything that travels toward her from off
screen, the fire truck and the convoy included, or not), what happens to PR #372, and whether this
waits behind M223, the file layout:

> "the spawn point follows her but must keep making sense. the firetruck needs to stay on the road
> traveling to the fire. the biker needs to stay on the sidewalk"

Then, while this file was being written:

> "add the new info to the PR so it becomes the new guidance *and* its implementation"

## The statements

1. **A warning is not tied to the size of a thing's field or to its speed.** → M207.
2. **An offscreen warning appears by itself first**, at a reasonable position, with nothing in the
   world yet. → M207.
3. **When its time comes, the thing is spawned at the place the warning points to, just off
   screen.** → M207.
4. **Until it spawns, that place moves with her**, so walking on neither brings it sooner nor
   leaves it behind. → M207.
5. **The place keeps making sense for the thing**: the fire truck stays on the road, travelling to
   the fire; the cyclist stays on the sidewalk. → M207.
6. **This goes on PR #372** as the new rule for offscreen warnings and placements and as its
   implementation, replacing the smaller field. → M207, on PR #372.

Then, asked how short a warning may be, since the fairness contract's minimum is worked out from
the field (about 2.9s for the cyclist at his 90px field, 1.95s at the 60px of the first build):

> "yes, all offscreen events should work like that. to a human 100ms feels instant, 1s is time
> needed to react to something, 2.9s is a fair time to react and *think* about what to do. so I'd
> file mark that as the minimum. what is the dogs timer right now? the dog timer is good"

7. **Every event that arrives from off screen works this way.** → M207.
8. **The minimum warning is 2.9s**, a human's time to react and think: 100ms feels instant, 1s is
   the time to react. → M207.
9. **The dog's timer is good.** Which dog, and what the 2.9s counts to (the spawn, or the moment
   the thing can reach her), went back to the player. → M207.

Then, answering which dog, after statement 9 had been filed as possibly the loose dog:

> "I think the agent responsible for 372 got my comment about the pursuit of the dog wrong. I meant
> the pursuing dog *not* the loose dog. the loose dog can stay as short as it wants since it is not
> lethal and relatively low impact. the pursuit dog timing from the day 3 lesson is the correct
> timing. other timings should be adjusted to fit that. and the new system should be made to work
> to retain that timing for the pursuing dog"

> "we can defer this change to a later PR though"

10. **"The dog timer is good" is the pursuing dog's**, `charging_dog`, not `loose_dog`. → M226.
11. **`loose_dog` may warn as briefly as it likes**, since it is not lethal and costs little; the
    2.9s minimum does not bind it. → M207.
12. **The pursuing dog's timing on the day-3 lesson is the correct timing, and other timings are
    adjusted to fit it.** → M226.
13. **The warning-first system is made to work for the pursuing dog while keeping that timing.**
    → M226.
14. **Statements 10, 12 and 13 are a later PR, not PR #372.** → M226.
