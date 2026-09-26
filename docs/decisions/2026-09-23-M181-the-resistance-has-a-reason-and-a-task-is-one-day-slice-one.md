## M181 — The resistance has a reason, and a task is one day, slice one · built 2026-09-23

*([PLAYTEST-117](../playtests/PLAYTEST-117.md) to [PLAYTEST-122](../playtests/PLAYTEST-122.md).)* One
agent on `feature/a-task-is-one-day`, replaced after a usage limit and again after it went cold;
reviewed by the orchestrator, with two audit findings and four review follow-ups fixed on the
branch. Slice two stays open in `TODO.md`.

**What was built.** She touches the chalk mark, the task is announced there and then on the
teaching line, and it is performed the same day: `ResistanceDirector._on_contact_completed()`
activates the perform half the instant its mark is touched, from the same day's RNG stream. A
task counts only on a day she wins; a lost day gives both halves back and the retry starts at
the mark. Six of the eight tasks: day 6 a note for any `homeless_yeller`; day 7 the package at
the delivery van's drop; day 8 the burnt shell at the day-3 fire's own scar; day 9 a crossing at
a region door, with the doors starting that day (`Tuning.REGION_WALL_FIRST_DAY` 7 → 9); day 12
the swing on one open park's playground; day 13 into any roadblock's band. Days 10 and 11 are
placeholder rows in `ResistanceSteps` (`available = false`). The goal is five
(`Tuning.RESISTANCE_GOAL` 4 → 5), not softened for the two unbuilt days; the heat ladder follows
as absolute counts (`HEAT_INVESTIGATES_LEVEL` 2 → 3, `HEAT_HUNTS_LEVEL` = goal − 1). **The red
arrow** (`Palette.TASK_ARROW`, a second `HomeArrow` under `Hud`) points at a one-place task from
the mark's touch until it is done; `ResistanceDirector.red_arrow_target()` decides which.
**The day brief carries no task**: `DaySummary._DAY_BRIEF` is a static line per calendar day,
the draft table below as it stood, read off `GameState.day`, so a lost day's line reads the same
on retry. `pending_resistance_brief` and `_dawn_brief` are gone from `GameState`; an old save
still loads, and an old run's step indices that the new table does not know answer null, so the
resumed run offers whatever the new table has for its day
(`tests/test_save.gd::_test_a_save_from_before_a_task_was_one_day_still_loads`).
`docs/NARRATIVE.md` carries the story, "What the tasks are for — never said in the game", with
[PLAYTEST-122](../playtests/PLAYTEST-122.md)'s corrections to the cover, the trust the goal stands
for and the neutral night.

**Found in review and fixed on the branch.** The door-task test never ran
`EventManager.start_day()`, so it passed with the fix deleted; it now runs the real day order and
checks the chosen tile is held. The day-9 door could land on a street next to the home block
(1 of 6 seeds measured): `_place_at_a_door()` now drops doors on `StreetNetwork.around_blocks()`
of the home block, with its own test.

**Open to overturn, chosen by the agent where the design was silent.**
- Day 8 with no recorded `burnt_shell` scar falls back to an ordinary placement of the same row.
- Day 12's park is picked from `CityMap.playgrounds`, which names only open parks — narrower
  than "forced open whatever its state", which stays open in `TODO.md`.
- Day 9's door is picked by the day's RNG from `City.region_plan().doors`, filtered to reachable.
- A scar matches its instance within a tile's width (32px), since a solid shape's placement
  nudges it (16px measured).
- Day 14 gets no red arrow until the power station's door exists (M183).
- The mark and header wording for days 7, 8, 9 and 12 is the agent's own; days 8 and 13 are
  reworded by [PLAYTEST-122](../playtests/PLAYTEST-122.md), open in `TODO.md`.

**Verified.** `./tools/check.sh`, `./tools/lint.sh`, `./tools/cost-table.sh --check`; the
resistance, save, day-loop, main, finale, checkpoints, regions, HUD, protest, dev-rig and events
suites with no failures; CI's full suite on the merge result. Evidence:
`docs/evidence/m181-red-arrow-2026-09-21/`.

**The decision, as the queue held it when slice one was built:**

> "when doing the mark it doesn't really feel that we would need to resist against anything
> since nothing really has visibly deterioated yet" · "we could do 1) chalk 2) it immediately
> shows the task 3) you have to do the task on the same day" · "add more different tasks" ·
> "a red arrow (like the blue home arrow but red) to point to tasks where we need to go to a
> specific location" · "we should also start with doors later since tasks should come first" ·
> "9-11 need some extra memorable content in addition to the tasks"

[PLAYTEST-117](../playtests/PLAYTEST-117.md) has the whole message, the orchestrator's opinion
and the questions put back with their options; [PLAYTEST-118](../playtests/PLAYTEST-118.md) has
the answers on the calendar's order, the spare task and the walk home. **Decided by the
player, and its build starts now on the player's word** ([PLAYTEST-121](../playtests/PLAYTEST-121.md):
"start with the tasks redesign implementation"). Three of its tasks go to places other
milestones make: the burnt shell is day 3's fire's (`DECISIONS.md`, M179, the fire is on her way), a scar
the run already records; **day 11's mast waits on M180**, posters she notices, and loudspeakers
that are somewhere, **and day 14's front door waits on M183**, the power station and the
blackout, until when day 14 keeps the last night's contact it has. The mark's noticing rule is built (`DECISIONS.md`,
M177, the second mark is any alley she comes across), and the mark is drawn as it always was.

**Decided:**

- **A task is one day**: she touches the chalk mark, the task is announced there and then, and
  it is done that day. Every task day starts with a mark. *A mark one day and its errand the
  next · overturned by the player on 2026-09-20.* A task counts only on a day she wins, and a
  lost day offers it again, as today.
- **The first mark is on day 6**, the day the curfew is announced; tasks run on days 6 to 13,
  eight of them. Asked with days 5, 7 and 8 as the alternatives.
- **The goal is all but three**: five of eight. **The day-14 sabotage is a must** — *"the
  sabotage is a must though"* — which is what `GameState.earned_good_ending()` already asks:
  the goal and the sabotage, both.
- **Doors start three task days after the first task**: day 9 (`Tuning.REGION_WALL_FIRST_DAY`
  is 7 today). *"we should also start with doors later since tasks should come first."*
- **The task is announced at the mark and nowhere else.** *"since the task will be immediately
  announced when touching the mark there is no need to mention tasks in the day brief ata ll"*.
  The day brief carries no task, no mark's words from yesterday and no reminder.
- **Two kinds of task.** *Any instance* — the man shouting, a roadblock — gets no
  arrow. *One place* gets **the red arrow**, the home arrow's form in red, from the moment the
  mark is touched until the task is done. *No quest log or marker for the resistance ·
  overturned by the player for one-place tasks.*
- **Four new one-place tasks**, all four chosen by the player: silence a loudspeaker mast, which
  stays quiet for the rest of the run; leave something at the burnt shell from day 3; warn a
  neighbor before a raid, with a deadline; cross a named door. **The neighbor lives in her own
  building, so the arrow points at them out in the city**, and the deadline is the neighbor
  walking home into the vans (*the orchestrator's reading · taken by the player on 2026-09-21*,
  [PLAYTEST-121](../playtests/PLAYTEST-121.md)).
- **A task done is shown by the world and never by text** (M182, a finished task is shown by
  the world): the thing she reached visibly answers, the arrow goes out, and the day summary
  says so.
- **Days 10 to 13 get things that happen once**, all four chosen by the player, each leaving
  something permanent, and each sited from where she is walking as the fire is, except the raid,
  which is at her own building and is what she comes home to: a raid on her own
  street whose door is boarded the next morning, the market is gone, a park is taken once she
  has reached its swing, and a column on the main road.

- **The walk home after a task is an ordinary return.** Getting home is the stake, since a
  task counts only on a day she wins; the return leg has the patrols every return has.
- **The densest crowd is the task with no day.** *The orchestrator proposed the roadblock band
  as the spare · the player chose the densest crowd on 2026-09-20.* Nine tasks were on offer
  for eight days.
- **Day 9 is the doors and nothing else new, and the park is taken on day 12**, asked with
  both on day 9, the doors on day 10 and the park on day 8 as the alternatives.
- **Day 12's task is the swing on the playground of one specific park**
  ([PLAYTEST-119](../playtests/PLAYTEST-119.md)), by the red arrow; a swing because there is no
  bench picture. A calm area is not reusable, so the park she is sent to is forced open that
  day whatever its state. **Once she has reached the swing the park starts to close**, which
  is the day's once-only happening, and she settles the baby in another. *Reaching the poster
  wall before the crew finishes, and tearing down a marked wall · both set aside by the player
  on 2026-09-20 as not convincing*; the poster wall has no day, like the densest crowd.
- **The sabotage is the power station** (M183, the power station and the blackout). Day 14's
  task is its front door, by the red arrow. *The loudspeaker system, proposed by the
  orchestrator · refused by the player as "too low a stake. it doesn't warrant an air raid on
  the city afterwards".*

**Decided on 2026-09-23** ([PLAYTEST-122](../playtests/PLAYTEST-122.md), each proposed by the
orchestrator and agreed by the player unless it says otherwise):

- **The convoys start on day 13**, the morning the army arrives: `military_convoy`'s
  `first_day` moves from 12, so day 12 stays the parks.
- **Two marks are reworded.** Day 8: "Something was left in the stroller in the night. Take it
  to the burnt building." (the drawing arrives, rather than an "it" nothing showed). Day 13:
  "Walk up to the roadblock. See how close they let you come." (a roadblock is solid, and the
  task is its band).
- **Day 11's mast is silenced by her reaching its foot**, as a mark is touched; its field makes
  the approach cost while it broadcasts, so timing it between broadcasts is the skill. A mast
  shows whether it is live and when it broadcasts (M180, posters she notices, and loudspeakers
  that are somewhere).
- **Day 10's raid is vans in the street at her building with a patrol, and the doorstep stays
  reachable.** *"we will have to see how that one feels"*: once built it goes to `REVIEW.md`.
- **Day 12 guarantees a second open park she can reach from the swing**, checked when the day is
  planned; and **whether days 10 to 13 fit their clock is measured** — the mark, the task, the
  happening and the walk home — with M184, a rig that walks the route, before anything is cut.
- **The neighbor is seen from day 1**: on days 1 to 9, a figure in work clothes leaves her
  building each morning as she does and walks off, and nothing points at them; from day 11 they
  are gone. This is the figure day 10's arrow finds and day 12's wanted notice draws.
- **A skipped task is answered by somebody else**, and the world shows nothing for it.

**What the tasks are for. Never said in the game; written into `docs/NARRATIVE.md` with the
build so the story stays consistent** ([PLAYTEST-119](../playtests/PLAYTEST-119.md): "those
things need to never explicitly spelled out in the game but it needs to be spelled out in our
narrative"; the story below is [PLAYTEST-121](../playtests/PLAYTEST-121.md)'s, *proposed by the
orchestrator · agreed by the player on 2026-09-21*). A resistance group is forming and
recruiting like-minded people by chalk, because nothing spoken or sent is safe. **It wants her
because the neighbor down the hall works at the power station**: the group cannot approach a
watched worker, and a parent in the same building who is out every day with a stroller can.
Everything leads to one night: the city's power is cut, the blackout is the signal the uprising
waits for, since it reaches everybody at once with nothing spoken or sent, the regime answers
the uprising by bombing its own city, and the escape is her getting out from under it.

Four things hold across every row. **It is the same story for the mother and the father**
("the story needs to make sense for both the woman and man"): no row rests on which parent she
is. **Nothing in the stroller is dangerous to lie next to** (`docs/NARRATIVE.md`, tone rule 2:
the baby is never in narrative danger from the regime directly); what she carries is damning to
be caught with and harmless beside the baby. **She is never told the plan**: each errand is
small and deniable, and she learns what they were for when the windows go dark. And **nothing
before day 14 rests on her alone**: the group has other couriers, and a task she skips is done
by somebody else, which is why five of eight is enough. **Five is the group's trust**: only a
courier who has proven reliable is given the key, which is why day 14 is offered only at the
goal, and **on the neutral ending nothing happens that night** — the uprising waits, and she goes
home ([PLAYTEST-122](../playtests/PLAYTEST-122.md)). Day 14 has to be her, because under curfew
with the army on the streets only a parent out walking a baby who won't settle reaches that
door. **Her cover is never a crying baby**, since crying is a lost day: *proposed by the
orchestrator · agreed by the player on 2026-09-23*. *More mandatory tasks, offered by the player on 2026-09-21 ("we can also make more tasks
mandatory if it makes more sense") · not taken, since no row needs it.*

| Day | Task | What it accomplishes | If she skips it |
| --- | --- | --- | --- |
| 6 | The note for the man shouting | He is the group's lookout: everybody walks around him, so he sees everything and nobody sees him. The note is her answer, yes; walking up to noise with the baby is the test. He leaves because his corner has done its job. Whichever look-alike she reaches is him ("which one exactly is determined by how the player plays"). | Somebody else answers. |
| 7 | The package at the van's drop | From the group to the neighbor. The driver is a sympathizer; the package is tools and a lamp. She carries it home, which is where the neighbor lives. | Somebody else risks the building. |
| 8 | The burnt shell | From the neighbor to the group: a drawing of the station, which door and which shift. A cordoned ruin is where nobody goes, so it is the dead drop. Whether day 3's fire was an accident is never answered. | The drawing goes out another way. |
| 9 | Cross a named door | The districts closed that morning and the station is across one. She finds out whether a stroller gets through. | Somebody else finds out. |
| 10 | Warn the neighbor before the raid | The regime has found the worker. She reaches the neighbor out in the city before they walk home into the vans, which are at her own building when she gets back. Warned, the neighbor runs; not warned, the neighbor is taken, and theirs is the face crossed out on day 12's wanted notice (M180, posters she notices, and loudspeakers that are somewhere). The door is sealed the next morning either way, and the drawing already left on day 8. | The same sealed door, for the worse reason. |
| 11 | Silence a mast | The rehearsal: a mast's feed can be cut by hand, nobody comes, and the masts have no power of their own, so a blackout silences them. | Somebody else answers. |
| 12 | The swing | Feeling watched, the neighbor hid the station key at the swing before the raid, so it is there whether or not she warned them. The parks are being fenced one at a time and the group knows this one is next, which is why it is today; she gets the key out as the park is taken. | Another courier fetches it. |
| 13 | Into a roadblock's band | The army arrived that morning, which is the column on the main road. She finds out how close a parent with a baby who won't settle can come to a held street before its guard moves, because the last night's way passes one; nobody looks twice at a parent walking a baby who won't settle, so the cost of the task is its cover, and the guard's reach is still the guard's reach. | Somebody else answers. |
| 14 | The station's front door | A hand-over: she passes the key to the neighbor's colleague on the night shift and walks away. The minutes he needs are why the lights go out once she is at a distance. Blackout, uprising, bombing, escape. | The neutral ending. |

The tasks escalate: trust, carry, carry back, scout, protect, rehearse, retrieve, scout again,
act. **Day 12's morning line is about the other parks** (*taken by the player on 2026-09-21*,
[PLAYTEST-121](../playtests/PLAYTEST-121.md)): "They are fencing off the parks" is read before she
leaves, and what she then sees is the one she was sent to being taken in front of her. It is
not the last one open, since she settles the baby in another afterwards.

**The calendar, decided by the player:**

| Day | Task | What happens once |
| --- | --- | --- |
| 6 | A note for the man shouting — any of them | |
| 7 | The package at a van's drop · arrow | |
| 8 | Leave something at the burnt shell · arrow | |
| 9 | Cross a named door · arrow | The doors arrive. |
| 10 | Warn the neighbor, out in the city, before the raid · arrow, deadline | The raid on her own street, at her own building. |
| 11 | Silence a loudspeaker mast · arrow | The market is gone. |
| 12 | The swing in one park · arrow | That park is taken once she has reached the swing. |
| 13 | Walk into a roadblock's band — any of them | A column on the main road. |
| 14 | The power station's front door · arrow | The blackout. |

**The day brief says what happened, a draft for the player to rewrite.** *"use the freed up day
brief text to further the narrative. write about what happened that day -- curfew announced
etc"*. One or two plain sentences a morning, under `docs/NARRATIVE.md`'s tone rules — nobody
explains the politics, the danger is noise, nothing triumphant — each naming the thing that day
introduces, so the brief is also where a new obstacle is first heard of. **One thing a morning** (*"focus on one thing only otherwise it becomes too dense"*), in
American English, which the player asked for in everything said to them. Days 1, 3, 4 and 6 are
the player's own wording or close to it; day 6 names the rumor of chalk, which overturns *the
first encounter comes with no hint at all* on the player's word, confirmed on 2026-09-23
([PLAYTEST-122](../playtests/PLAYTEST-122.md): "we do now hint at the first task"); day 7 waits on M180 making a
poster something she has ever seen. Written against the proposed shape above, so the days move
if the shape does:

| Day | Draft |
| --- | --- |
| 1 | She won't settle indoors. It is quiet in the park. Walk until she sleeps, then bring her home. |
| 2 | There are bicycles on the sidewalk again. |
| 3 | The streets smell of smoke today. |
| 4 | It feels like there are more police around now. |
| 5 | They put up masts at the intersections overnight. |
| 6 | A curfew was announced today. There is not as much time. There are rumors of chalk messages in alleys. |
| 7 | There are more posters than yesterday. The same face is on most of them. |
| 8 | A van took someone from the next street before it was light. |
| 9 | They have closed the districts off from each other. There are huts at the crossings. |
| 10 | The stores on the square are boarded up. |
| 11 | A door down the hall was sealed in the night. The name is still on the bell. |
| 12 | They are fencing off the parks. |
| 13 | There are army trucks on the main road. |
| 14 | The last night. |

The lines for days 8 to 13 follow the calendar above and move with it. **A line is not tied
to its day's task or once-only happening** ([PLAYTEST-121](../playtests/PLAYTEST-121.md): "we
also don't need to stick to the same taglines in day brief. we can mention other things"), so
one that would give the day away says something else that is true that morning.
