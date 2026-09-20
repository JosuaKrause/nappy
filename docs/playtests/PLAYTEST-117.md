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
