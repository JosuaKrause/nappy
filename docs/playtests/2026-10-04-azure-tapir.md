# Playtest azure-tapir — Scenes, halos past the cap, the robber's lunge, the pelican's telemetry and the frame record's download

2026-10-04. Six notes from the inbox, #513, #514, #526, #527, #529 and #530, all said in sessions
on 2026-10-04 and captured as they were said. Each of the player's words is copied word for word,
after what it answered.

## #513 — busy-raven: scenes are recipes with live tasks

Asked on 2026-10-04 (busy-raven, playable scenes for each day's task target and the fire truck):
"how should a scene be built? Today's scene recipes (JSON under scene-recipes/, played with
tools/run.sh --recipe) can't place a chalk mark, offer a task, point the red arrow or install the
target events (mast, van, neighbor, burnt building, roadblock, fire truck)." Options: "Recipes with
live tasks (Recommended)" — recipes gain a field for a mark and its task: the day's task offered
from the start, its arrow live, the target events installed, so the task can be played to
completion; "Authored actors only" — mark and target placed with no task logic running.

> Recipes with live tasks (Recommended)

## #514 — M205 and M206: the player already gave the information; no further phone check

Asked on 2026-10-04: "M206 (the title screen after a game over is the right way up) and M205 (the
man shouting charges the meter again) are each waiting on a phone check by you on the released
page. M206: lose a day, then hold the restart; is the title upright? M205: walk beside a man
shouting; does the meter charge and does he light up? Native and headless runs can't reproduce
either. Have you checked them?" Options: "Not yet, park both"; "Run M205 in desktop Chrome" — an
agent builds a release export and walks beside him in desktop Chrome with ?debug=1&layers=1, M206
waiting for the player's check.

> hmm, I gave you all the info on that already. what else do you need?

## #526 — Answers: robber keeps the 108px stand-off; pelican merges; M159 choices accepted; recorder ships in the next release

Four questions on 2026-10-04. (1) tall-osprey, PR #524: the robber's catch went 30px to 26px;
turning after he notices gets away 74 of 200 instead of 68, because the lunge stand-off is catch +
78px. Options: "Keep the stand-off at 108px (Recommended)" — shrink only the catch, lunge stays at
108px, as a follow-up on this PR; "26px as built is enough"; "Smaller still". (2) The pelican
cyclist, PR #522, first-pass drawing: "Looks good, merge" or "Needs changes". (3) M159 frame
recorder, PR #521: accept the timing wraps in gameplay code as a telemetry-skill exception, the
released page's download as an M193 exception, and slow = above 1.5 display budgets? "Accept all
three (Recommended)" or "Change some". (4) How to try the recorder on the phone: "In the next
release (Recommended)" or "Local build on my Wi-Fi".

> 1. Keep the stand-off at 108px (Recommended)
> 2. Looks good, merge
> 3. Accept all three (Recommended)
> 4. In the next release (Recommended)

Asked on 2026-10-04 after the player asked "would increasing the lunge make sense? what would the
consequence of this be?" about tall-osprey (PR #524, keeping the robber's lunge at 108px while only
the catch shrinks). The assistant explained: the lunge (stand-off) is catch + his speed × 0.6s =
108px today; moving it out to 120–130px gives her more time and helps escapes more than the catch
does, but must stay clearly inside his 140px notice range so the sight of him coming still reads;
it would be a robber-only override, since the shared pursuit_standoff() also sets the day-3 dog,
whose encounter the player called right; the chalk mark stays out of his notice range. Proposed
measuring lunges of 108, 120 and 130px for the robber alone with the smaller catch, on the same
200-chase probe plus a check that standing still and walking are still caught, for the player to
pick from the table. "Shall I add the 108/120/130px measurement to the tall-osprey agent's task?"

> yes measure

Asked on 2026-10-04, about tall-osprey, the robber's lunge (PR #524). His catch is 26px. The probe
ran 200 chases for the alley robber alone. A rig that runs only once he lunges got away 14/200 with
the lunge at 108px (0.35s of walk from his 140px notice), 36/200 at 120px (0.22s) and 56/200 at
130px (0.11s). In every row, standing still and walking away were always caught and running at the
notice always escaped. 120 or 130 needs Tuning.TRAP_ARRIVAL_DISTANCE raised from 311px to 315 or
325px, and the van guard's arrival cone measured again. Options: "120px (Recommended)", "108px, as
built", "130px".

> pelican sounds good!
>
> Lunge: 120px (Recommended)
>
> what is blocking 521?
> when all four PR are ready, merge them and the let's cut a minor release

Asked on 2026-10-04, about tall-osprey (PR #524): a 120px lunge collides with record M137. Standing
still, he must lunge no sooner than 1.5s after he appears, which needs TRAP_ARRIVAL_DISTANCE of at
least 315px. M137 keeps half a second of chase to spare for a walker who leaves the moment he
appears, which caps the distance at 311px with the 26px catch. Turn-at-lunge escapes out of 200: 36
at 120px, 28 at 116px, 14 at 108px. Options: "120px, smaller margin (Recommended)", "116px, keep
every rule", "Longer trap notice", "Only the alley robber".

> 116px, keep every rule

## #527 — The pelican has its own GoatCounter events (spawn, on screen, hits her) and its own log lines, in the same release; telemetry means GoatCounter

Said on 2026-10-04 after the assistant answered "is the telemetry for the pelican set up?" with: the
pelican has no telemetry of its own; the run log records it as a plain `cyclist` and its warning
badge is the cyclist's, because whether a rider is a pelican is decided when it spawns; adding it
would be a small follow-up on PR #522 (the pelican cyclist).

> no I explicitly asked for specific pelican telemetry. when the pelican spawns, when it's on screen, and when it's hitting the player. it must appear as its own entry and it needs to be more granular than standard event telemetry
> by telemetry I mean goatcounter -- logs should be correctly identifying it from the beginning -- when it spawns it creates a log line, no? that's a very bad excuse.
> the telemetry must go out in the same release
> for future reference I primarily consider goatcounter telemetry. what you think of telemetry is just logs

## #529 — Halos past the cap: the top k by intensity show

Said on 2026-10-04 after M205 (the man shouting lights his halo on the web, PR #525) capped rims at
15 at once (EntityHalo.RIM_BUDGET, the web renderer reads only 16 instance-uniform blocks).
ExcitementHalo already picks at most 8 sources (MAX_SOURCES), strongest first; when 15 rims exist
(lit plus still fading out), a newly picked source waits in a line served oldest first.

> if we have a limit with number of halos the selection should be by intensity so only the top k most intensive halos show at any one time

## #530 — Frame record download: no feedback that the file was saved

Said on 2026-10-04 while uploading two frame records (M159, the frame recorder's page download)
from one phone run on v0.24.0, seed 478156010, saved 12:27:24 and 12:27:57: "Check which one is the
best to use". The later file holds the earlier one's 1510 frames as an exact prefix, plus 102 more.

> There is no feedback that the files were saved so I downloaded multiple copies.

## Routing

1. **#513, recipes with live tasks** → [busy-raven, playable scenes for each day's task target and
   the fire truck event](../todo/2026-10-03-busy-raven/README.md), whose README now states the
   answer; the scenes are being built on its branch.
2. **#514, no further phone check** → nothing new to file. M205's halo half was reproduced from the
   recorded evidence and built ([M205-3](../decisions/2026-09-25-M205-3.md)), and M206 was built
   ([M206](../decisions/2026-09-25-M206.md)). The review item for M205
   (`docs/review/2026-09-25-M205.md`) stays: it asks about the released fix, which did not exist
   when the player answered.
3. **#526, the four answers and the lunge** → built and recorded: the robber's 26px catch and
   116px lunge ([tall-osprey](../decisions/2026-09-27-tall-osprey.md)), the pelican
   ([feathery-bison](../decisions/2026-10-03-feathery-bison.md)), the frame recorder's three
   accepted exceptions ([M159-5](../decisions/2026-09-19-M159-5.md)); pull requests #521, #522,
   #524 and #525 merged and were released as v0.24.0.
4. **#527, the pelican's own GoatCounter events** → built in the same release
   ([feathery-bison](../decisions/2026-10-03-feathery-bison.md), `docs/TELEMETRY.md`); "telemetry
   means GoatCounter" is in `CLAUDE.md`.
5. **#529, the top k halos by intensity** → built on pull request #531 and recorded as
   [M205-4](../decisions/2026-09-25-M205-4.md) once it merges.
6. **#530, no feedback that the file was saved** →
   [spry-magpie, the frame record's download says it was saved](../todo/2026-10-04-spry-magpie/README.md),
   band `now` as a note from playing.
