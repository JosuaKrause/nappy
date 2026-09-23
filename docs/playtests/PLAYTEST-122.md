# Playtest 122 — The cover is a baby who won't settle, five is trust, and a rig that walks the route

2026-09-23. Said in conversation, in answer to a review of the gaps and conflicts in the story
`TODO.md` carries under M181, the resistance has a reason, and a task is one day. No run was
played.

## What was put to the player

Eleven points, each with the orchestrator's recommendation. Four were conflicts between two
things already written down, the rest gaps nothing answered:

1. **The crying baby is the story's cover, and crying loses the day.** Day 13's row says "nobody
   looks twice at a screaming baby" and day 14's "only a parent with a crying baby reaches that
   door", while the meter at 100 is crying and a lost day. Recommended: the cover is a parent out
   walking a baby who won't settle — the game's own premise, and either parent's.
2. **Under five tasks, nothing says why day 14 is not offered or what the city does without
   her.** The story makes no task load-bearing, and `GameState.sabotage_available()` offers the
   door only at `Tuning.RESISTANCE_GOAL`. Recommended: five is the group's trust — only a proven
   courier is given the key — and on the neutral ending nothing happens that night: the uprising
   waits, and she goes home.
3. **The army arrives twice**: `military_convoy` from day 12, and day 13's row has the army
   arriving that morning. Recommended: the convoys start on day 13.
4. **Day 13's mark says "Walk straight through the roadblock. Not around it."**, and the task is
   walking into its band; a roadblock is solid. Recommended: "Walk up to the roadblock. See how
   close they let you come."
5. **Day 11 does not say how a mast is silenced when the only verb is walking.** Recommended: she
   reaches the mast's foot, as she touches a mark, and its field makes the approach cost while it
   broadcasts, so timing it between broadcasts is the skill.
6. **Day 10's raid is at her own building, and the doorstep is the day's goal.** Recommended: the
   vans stand in the street as a visible obstruction with a patrol, and the doorstep itself stays
   reachable.
7. **Day 12 needs two parks in a 144-second day**: the swing's park closes once she reaches it,
   and she settles the baby in another, which nothing guarantees open and in reach. Recommended:
   day 12's plan guarantees one, and a probe measures whether the late days fit their clock.
8. **The neighbor is never seen before day 10**, while the whole plot runs through them and the
   wanted notice's face is "drawn to match the figure she met or missed". Recommended: on days 1
   to 9 a figure in work clothes leaves her building each morning as she does, and walks off.
9. **Day 8's "it" is never shown.** Recommended: "Something was left in the stroller in the
   night. Take it to the burnt building."
10. **"Somebody else does it" is never visible when she skips a task.** Recommended, cheaply: the
    story's "if she skips it" column says somebody else answers.
11. **Pacing**: days 1 to 5 are thin and 9 to 13 crowded. Recommended: point 8 fills the first
    half; measure the second before cutting anything.

## What the player said

> "1. agree let's change that 2. sure 3. okay 4. okay 5. yes, there should be a visible
> indicator about when a mast is active / has a broadcast 6. sure, we will have to see how that
> one feels 7. let's check this. btw we should have a test-rig mode where she just follows the
> edges of a path that way we can test paths properly and do those timing checks without having
> to guess the right inputs 8. that sounds good 9. yes 10. sure, somebody else answers. btw, yes,
> the earlier guidance of not indicating the first task is overturned. we do now hint at the
> first task."

## Statements

1. **Her cover is a parent out walking a baby who won't settle**, never a crying baby: day 13's
   and day 14's rows are reworded, since crying is a lost day. *Proposed by the orchestrator ·
   agreed by the player.*
2. **Five tasks is the group's trust.** Only a courier who has proven reliable is given the key,
   which is why day 14 is offered only at the goal. **On the neutral ending nothing happens that
   night**: the uprising waits, and she goes home. *Proposed by the orchestrator · agreed.*
3. **The convoys start on day 13**, the morning the army arrives; `military_convoy`'s
   `first_day` moves from 12. *Agreed.*
4. **Day 13's mark reads "Walk up to the roadblock. See how close they let you come."** *Agreed.*
5. **A mast is silenced by reaching its foot**, as a mark is touched, and its field makes the
   approach cost while it broadcasts. **A mast shows when it is active and when it broadcasts** —
   the player's addition: *"there should be a visible indicator about when a mast is active / has
   a broadcast"*. That governs M180, posters she notices, and loudspeakers that are somewhere, as
   much as day 11.
6. **Day 10's raid is vans in the street at her building with a patrol, and the doorstep stays
   reachable.** *"we will have to see how that one feels"*: a played question once built.
7. **Whether the late days fit their clock is measured**, day 12's second park first: *"let's
   check this"*.
8. **A rig mode walks her along a path's edges without scripted inputs** — the player's own
   request: *"we should have a test-rig mode where she just follows the edges of a path that way
   we can test paths properly and do those timing checks without having to guess the right
   inputs"*. It is the instrument statement 7's measurement is taken with.
9. **The neighbor is seen from day 1**: a figure in work clothes who leaves her building each
   morning as she does and walks off, until the raid. *Agreed.*
10. **Day 8's mark reads "Something was left in the stroller in the night. Take it to the burnt
    building."** *Agreed.*
11. **A skipped task is answered by somebody else**: the story's column says so, and the world
    shows nothing for it. *Agreed.*
12. **The first task is hinted at.** *"yes, the earlier guidance of not indicating the first task
    is overturned. we do now hint at the first task."* *The first encounter comes with no hint at
    all · overturned by the player on 2026-09-23*; day 6's brief names the rumor of chalk, which
    [PLAYTEST-121](PLAYTEST-121.md)'s calendar already carried. `CLAUDE.md`'s list of things
    deliberately not done says so.
13. **Pacing is measured before anything is cut**, with statement 8's rig; statement 9 is what
    the first five days gain.
