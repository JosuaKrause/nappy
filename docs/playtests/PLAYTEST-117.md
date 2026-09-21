# Playtest 117 — The fire nobody saw, loudspeakers nobody heard, and a resistance with a reason

2026-09-20. Said in conversation, in answer to a day-by-day list of the run's progression the
player asked for after [PLAYTEST-116](PLAYTEST-116.md). The run it draws on is that playtest's.

## What the player said

> "I have never seen a fire truck. I mentioned a couple of times that the fire should come
> first and be on your way *guaranteed* (a dynamic event dependent on the route you chose that
> day) then the fire truck should come and player better get away from the fire. posters need
> to be more obvious. the loudspeaker part was not apparent to me. since we don't have sound
> it's not clear that this is happening. loudspeakers should be placed in the city with a
> defined field. not sure about adding a floor. it just makes losing unfair because things that
> worked before don't anymore for no obvious (or visible) reason. yeah I agree 9-11 need some
> extra memorable content in addition to the tasks. I feel the overall length and pacing is
> fine but in the tail we reach a ceiling. also, currently when doing the mark it doesn't
> really feel that we would need to resist against anything since nothing really has visibly
> deterioated yet (well, a few things but very subtle). I'm thinking maybe we could move the
> chalk later a little bit and remove some re-chalk days. or, and I want to hear your opinion
> on it, we could do 1) chalk 2) it immediately shows the task 3) you have to do the task on
> the same day. that way we could always start with a chalk. also it needs to be obvious when
> a task was done correctly. if we do it that way we could start later and it would feel more
> like you actually have a reason to start resisting. also, again, chalk marks should only get
> pinned whenever you see them (and not at the edge of the screen really). they need to be a
> little bit more obviously visible. also, if we do the chalk and task in one day things we
> can 1) add more different tasks ie increase the number so we don't start *too* late with
> tasks 2) we could do a red arrow (like the blue home arrow but red) to point to tasks where
> we need to go to a specific location (unlike the yeller task where we can just go to any
> yeller). that way we can have tasks that are not "go to any instance of this event". if we
> start with chalk and tasks later we should also start with doors later since tasks should
> come first. yes, merge and patch"

"yes, merge and patch" answers the orchestrator's question in the same message: M176, M177 and
M178 merge as they go green, and a patch release follows them.

## What the repository says

**The fire.** [PLAYTEST-49](PLAYTEST-49.md), finding 6, asked for the fire before the engine,
and M101, the fire is found before the engine, built it: `burning_building` holds day 3's
one-shot slot and `fire_truck` spawns when she sees the fire. What was never built is *on her
way*: the fire is sited once at dawn. In PLAYTEST-116's run the roll reads `one-shot
burning_building: 0.84 <= 1.00 — waiting at (14,34)` with her doorstep at (80,84); she never
went near it, so the engine never came. No playtest file before this one carries the word
"guaranteed" about the fire; it is recorded here as asked for.

**The loudspeaker** is a `city_wide` row from day 5: no position, no picture (`Look.NONE`), 2.4
a second everywhere on a 22 second pulse. With no sound in the game it is a number under the
meter and nothing else.

**The marks and the doors.** The first mark is day 4, the day act II begins; marks and performs
alternate days to day 13 (`docs/NARRATIVE.md`, "Structure"); region walls and their doors
start on day 7 (`Tuning.REGION_WALL_FIRST_DAY`). Days 9 to 11 and 13 introduce nothing but
their resistance beat.

## What is asked for, as statements

1. **The fire is on her way, guaranteed**: sited on day 3 from the route she is actually taking
   that day, then the engine comes, and she had better get away from the fire.
2. **Posters are more obvious.**
3. **Loudspeakers are things in the city with a defined field**, since there is no sound to
   say they exist.
4. **The city-wide floor is doubted**: "not sure about adding a floor … things that worked
   before don't anymore for no obvious (or visible) reason".
5. **Days 9 to 11 get memorable content of their own**; the length and pacing are fine, the
   tail reaches a ceiling.
6. **Resisting needs a reason she can see**: the first mark comes before anything has visibly
   deteriorated.
7. **Proposed by the player, opinion asked:** a task is one day — the chalk mark, which
   immediately shows the task, which is done the same day — so every task day starts with a
   chalk mark, tasks start later, and there are more and more varied tasks.
8. **It is obvious when a task was done correctly.**
9. **A chalk mark is pinned only when she sees it, not at the edge of the screen, and is more
   obviously visible.**
10. **A red arrow, like the blue home arrow, points to a task that is at one specific place.**
    *No quest log or marker for the resistance · overturned by the player on 2026-09-20 for
    tasks with a specific location*; a task that any instance answers gets none.
11. **Doors start later than tasks**, since tasks come first.

## After the orchestrator's opinion and proposed shape

The opinion was yes to one day per task, with a proposed shape (tasks from day 6, five of
eight, doors from day 9, a red arrow for one-place tasks) and six questions. The player's first
answer:

> "since the task will be immediately announced when touching the mark there is no need to
> mention tasks in the day brief ata ll"

12. **A task is announced when she touches the mark, and the day brief does not mention tasks
    at all.** It also reads as the one-day structure being taken; the six questions are still
    open.

> "use the freed up day brief text to further the narrative. write about what happened that
> day -- curfew announced etc"

13. **The day brief tells the story**: the line the task used to take says what has happened
    in the city by that morning — the curfew announced, and so on.

On the first draft of the fourteen brief lines (in `TODO.md`, M181):

> "day 1: maybe mention park or calm area in the first note
> day 3: just "the streets smell of smoke today"
> day 4: too wordy. something along "it feels like there is more police around now" or
> something like this. focus on one thing only otherwise it becomes too dense
> day 6: A curfew was announced today. We don't have as much time. There are rumors of chalk
> messages in alleys. -- sormthing like that
> -- I have not seen a single poster in any playthrough -- I don't know what you're referring
> to here -- it needs to be way more obvious
> -- also please us american english throughout -- for example, I don't know what you mean by
> landing."

14. **A brief line is about one thing**, or it becomes too dense.
15. **Day 1's line mentions the park or a calm area.**
16. **Day 6's line says there are rumors of chalk messages in alleys.** *The first encounter
    comes with no hint at all · overturned by the player on 2026-09-20*: the brief names the
    rumor; nothing on the street points at a mark.
17. **The player has not seen a single poster in any playthrough.** PLAYTEST-116's run placed
    ten `poster_crew` rows on day 4 alone. "More obvious" in statement 2 means: today they are
    not noticed at all.
18. **American English throughout, in what is said to the player as well as in new names.**
    "Landing" was not understood.

On M177's acknowledgement, which said "Taken." for a touched mark and "Done." for a perform
step:

> "the mark already visibly shows that it was taken also we show the task so taken wouldn't fit"

19. **A touched mark says nothing**: its touched picture is the acknowledgement, and the line
    a touch earns is the task.

And a moment later:

> "yeller should just start walking offscreen -- no onscreen text for acknowledgements like this"

20. **No on-screen text acknowledges a task.** A finished task is shown by the world.
21. **The man shouting, handed the note, walks off screen.**

On hearing what M177 had changed about the mark — a touched picture bound in place of the
hand-drawn one, and the mark drawn a third larger:

> "the mark already visibly shows that it was taken also we show the task so taken wouldn't fit"
> (above) and then: "the mark doesn't have a problem for recognizing that it was taken!!!! no
> need to change anythign there!!!! where did you get that from?"

> "no larger mark!"

**Where it came from, and it was a misreading.** PLAYTEST-116's "(there should be an indication
that I did it correctly)" stands in parentheses after "then the yeller". The orchestrator read it
as covering the mark as well and wrote M177's second item that way; the player meant the man
shouting only. "A little bit more obviously visible" was read as larger and brighter; the player
rules out larger.

22. **The mark's taken state was never a problem and is not changed.**
23. **The mark is not drawn larger.** What "a little bit more obviously visible" does mean is
    asked back.

## The questions, as they were answered

Put to the player with options and a recommendation each, after "ask away":

- **The first chalk mark**, with days 5, 6, 7 and 8 offered: **"Day 6"**, the day the curfew
  is announced, leaving eight task days.
- **How many tasks earn the sabotage**, with all but three, all but one and half offered:
  **"All but 3"**, five of eight. And, unprompted: *"the sabotage is a must though"*.
- **When the doors arrive**, with three task days after the first task, day 8 and day 10 or
  later offered: **"Three task days after the first task"**, day 9.
- **The city-wide floor**, with removing it, keeping it near masts only and keeping it
  offered: **"Remove it"**.
- **New one-place tasks**, any number of four: all four — silence a loudspeaker mast, leave
  something at the burnt shell, warn a neighbor before a raid, cross a named door.
- **What happens once on days 9 to 11**, any number of four: all four — a park is taken in
  front of her, a raid on her own street, the market is gone, a column on the main road.
- **What makes a mark easier to notice**, after "no larger mark!", with its placement at the
  alley's mouth, more contrast at the same size, both, and leaving it offered: **"Leave it as
  it is"**.

And on the misread sentence from PLAYTEST-116, asked whether the indication was about the man
shouting only:

> "yes, that I did the yeller correctly."

## What ships, and what comes after

Asked whether the fixes from PLAYTEST-116 may merge and ship:

> "merge all and do the minor" · "once ready" · "sorry patch"

> "or did you already implement the whole new pacing of the story beats?"

Told that none of the pacing was built — M179, M180 and M181 were decided and written down
only:

> "that would be the next after this and warrants a minor release"

> "once the current patch release is done we will start a new session"

24. **The fixes ship as a patch release; the story's pacing is next and ships as a minor.**

On M176's pigeons, told that going up on touch had made walking through a flock several times
dearer and that the orchestrator had cut the flock's intensity to bring the cost back:

> "no keep the pigeon cost at 65. they fly away. the strategy is to wait them out at no cost"

> "not following the procedure should be costly"

The 65 was the agent's first measurement, from a faulty rig; with real birds the same intensity
nets about 45 through the middle. What the player decided is the intensity: it stays 42.

25. **The pigeons' procedure is to wait them out, which is free, and walking into them is
    costly on purpose.**
