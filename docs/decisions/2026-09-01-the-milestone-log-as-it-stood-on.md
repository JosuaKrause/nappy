## The milestone log, as it stood on 2026-09-01

The full `docs/TODO.md` before it was cut back to a queue. Kept verbatim: every completed
milestone entry, with its measurements, its rejected options and its reasoning. The live queue is
[TODO.md](../TODO.md); this is where its entries came from and where a closed item goes.

# Nappy — TODO

Status legend: `[ ]` todo · `[~]` in progress · `[x]` done

Each milestone is one git branch, merged to `main` when green.

**Where things stand:** M0–M16, M18, M19, M22, M23 and M27 are done and merged, and the game has
now been played four times by a human. The first playtest produced thirteen findings, planned
as M11–M17 in **[docs/playtests/PLAYTEST-01.md](../playtests/PLAYTEST-01.md)**; the second produced twelve, planned as
M18–M26 in **[docs/playtests/PLAYTEST-02.md](../playtests/PLAYTEST-02.md)**; the third, in
**[docs/playtests/PLAYTEST-03.md](../playtests/PLAYTEST-03.md)**, is the first read off a run log and reorders some
of what the second one planned rather than adding milestones; the fourth, in
**[docs/playtests/PLAYTEST-04.md](../playtests/PLAYTEST-04.md)**, adds one milestone and puts two that were already
queued at the front of the queue. All four are live plans and should be read before picking
anything up.

Execution order is numeric, with several exceptions already taken. **M18 was pulled ahead of
M16**, because closure counts tuned against a day that was about to halve would have been
tuned wrong. **M23 was pulled ahead of M17**, because it is the gate on M19's balance half and
on M24. **M27 was taken out of order and immediately**, because playtest 04's emphasised
finding — *"don't load everything upfront"* — turned out to be what was underneath three of the
other six, and because M21 and M22 both get judged against a street that now has traffic on it.

**Playtest 05 has landed and all six of its findings are done** — M28, M29, M30, M24 and M31.
Six findings in **[docs/playtests/PLAYTEST-05.md](../playtests/PLAYTEST-05.md)**: two
traffic defects (cars stop at arbitrary points for a zebra; the two axes drive on opposite
sides of the road), M22's exclamation mark firing unattributably and without consequence, the
same park being usable on day 1 and day 2 (M24), **"day two doesn't feel more difficult than
day one… there is never *any* danger"** (M31), and a stated density target: **one event per
block** (M28) — day 1 now places ~49 events across 49 blocks and 3.3 are on screen at any
moment, and the thing it confirmed is that the binding constraint was the **per-type caps, not
the budget**. **Read it before picking up anything below**: the write-ups carry what each
analysis got right and what it got wrong, which is the half that is not in the diffs.

**M21's calm-zone half has landed.** One or two four-block calm zones per city, 22 tiles square,
with the streets between their blocks absorbed — so the lattice has holes in it, route
redundancy stopped being true by construction, and a stretch of calm is a route rather than a
lap. The other two halves of M21 (main roads with lights; the canal) are deliberately still
open; see the entry below.

**Playtest 06 has landed and all five of its things are done (M32).** In
**[docs/playtests/PLAYTEST-06.md](../playtests/PLAYTEST-06.md)**, the first playtest ever taken on M28–M31: **the
difficulty is now right** — the first balance number in this game ever confirmed by a human —
plus two cues whose *condition was not the thing they claimed to mean*, a lost day that should be
**retried rather than skipped**, and the vocabulary asked for in the other direction: something
at the pram that says how the **baby** is. The one sentence to carry out of it is that M30
narrowed *which* things a cue is raised for and never looked at **when**: a cue is a claim about
a moment, and nothing in `tests/test_danger.gd` can see a moment.

**Playtest 07 has landed and M33 is its first half.** Nineteen things in
**[docs/playtests/PLAYTEST-07.md](../playtests/PLAYTEST-07.md)**, reported as a running commentary rather than as a list,
and the one sentence under them is that **every cost in the game is paid on contact and almost
nothing else in it is real**. Nine are done; ten are queued behind them and listed there.

**Playtest 08 has landed and all five of its things are done (M35).** In
**[docs/playtests/PLAYTEST-08.md](../playtests/PLAYTEST-08.md)**, taken on M34, and the run it came from ended on **day 3**
— the shortest any playtest has produced. Three of the five are one sentence, and it is playtest
07's own surviving a milestone meant to answer it: *a thing exists, and being near it changes
nothing.* The park spoiler denied three percent of a park, the pigeons were over before she arrived,
and the things that move stopped existing in front of her instead of going anywhere. The fourth is
the day-3 running lesson, which killed the run twice and whose fairness contract **passed every line
of itself while it was doing it** — because the contract was stated in speeds and durations and a
pursuit is played out in distances. The fifth is a number: five nerves.

**Playtest 09 has landed and all four of its things are done (M36).** In
**[docs/playtests/PLAYTEST-09.md](../playtests/PLAYTEST-09.md)**, four sentences reported mid-session, and the one under
them is that **two things in the build had been doing nothing at all for milestones and both looked
finished from the outside**: `Esc` had never once opened the pause it shipped with in M33, and the
man shouting was killing day 1 by standing still. Plus two design instructions — a man who paces,
and a robber who is worth crossing the road for and comes after you if you do not. The lesson to
carry is about the *rig* rather than either bug: nothing in the suite or in a screenshot has ever
pressed a key, so neither could have caught the first one. `--press` exists now.

**Playtest 07 is down to four.** M37 closed findings 2, 11, 4 and 14 — one picture per row (and a
test that keeps it one), a café with people at it, buildings that sort against nothing, and a baby
cue that stops dodging a mark that is not there. What is left is the cat's axis (1), a four-block
concrete plaza (8) and a car turning with no diagonal (6).

**M38 is a batch of reports rather than a playtest**, and the sentence under all of them is the one
this project keeps rediscovering: *a thing that ships and looks finished is not a thing that works.*
The birds started their flying animation and then hung motionless in the air for the whole of the
event, three milestones after two separate playtests said they were ineffective; the cat's art faced
west while every other sprite in the game faces east, so the flip drew it running backwards; a car
turning into an occupied lane teleported the other one hundreds of pixels backwards while the queue
stayed legal on every frame; and a finished run had **no key on it at all** — the ending offered
`Esc`, `Esc` opened the pause, and the pause offered `Esc` and `Q`. Done: eleven birds that each fly
and each emit, a mirrored cat, a turn that looks before it commits, a title screen with the street
running behind it, `R` to start again, and calm ground 20% faster. See the entries under M38 below.

**M38 and M39 are both merged**, and the pursuit half of M39 is the second answer rather than the
first: the session's own analysis read finding 13 as a reaction-window problem, measured a real
two-tenths-of-a-second window, and built for it — while the player had been talking about the
break-off the whole time. *A probe that reproduces the numbers is not evidence that it reproduces
the complaint.* All of it was reverted and replaced with `Tuning.PURSUIT_SHAKEN_OFF`, which ends a
chase at a **rate**. Two things about the day-3 dog are still open and are written down in M43.

**Playtest 10 landed as M39.** Fourteen findings in
**[docs/playtests/PLAYTEST-10.md](../playtests/PLAYTEST-10.md)**, off a session of five runs in which **no day was won**.
The sentence under them is that *the danger marks and the danger have come apart*: three of the
fourteen are one finding — a fire engine carries no caret and a burning building does — and the rule
underneath is M22's, which asks whether a danger *changes over time* and never asked how bad it is.
Under two more is the other one: **a retried day is not the same day**, which `docs/TODO.md` has
claimed since M32 and five seeds out of five disprove. And a thing nobody reported is in every
losing line of the trace — the crowd is supplying nearly all of the excitement that ends a day,
which is playtest 07's finding 17 arriving again after the milestone that answered it. That is
**the milestone after M39**, measured rather than argued.

**Playtest 11 has landed and is M41, M42 and M43.** Nine findings plus a design for the edge of
the map, in **[docs/playtests/PLAYTEST-11.md](../playtests/PLAYTEST-11.md)**. The sentence under it: *several things in this
city are placed without asking what they are in the way of* — an event on the home block, a closure
beside a park, a busker in a courtyard she can walk round, a car turning into a junction another car
is already in. Underneath three more is a larger one: **the city has no hierarchy.** Every street is
the same street, the home sits wherever two competing generator rules leave it, and the map stops at
an invisible wall. That splits into a **spine and an edge you can walk off** (M41, which also closes
M21's open half), a **9×9 city with the home in the middle** (M42), and the rest (M43).

**M41 is done, and playtest 12 landed in the middle of it.** The city has a hierarchy now: one
main road running north to south, signalled at every junction and bad ground to recover on; two
retail precincts of three blocks each, one along the southern shore; ordinary streets everywhere
else; junctions that ration their own box; a lattice grown to 11×11; and a boundary with frontages
on the far side of it and a tunnel, a bridge and a road running out of the map. Nine findings in
**[docs/playtests/PLAYTEST-12.md](../playtests/PLAYTEST-12.md)**, taken on the branch while it was half-built, and the
sentence under them is *a hierarchy is only a hierarchy if there is one of the top thing* — the
first build put a main road on each axis and a precinct in every corridor, which is three kinds of
street and no hierarchy among them.

**M41 is merged.** It landed at `c4e18d2` after the session that built it, and the suite is
122119 checks green on it.

**M43 is merged half done, on purpose, and it produced a milestone.** Three of its seven are built
(nothing on the home block, the diagonal `zzz`, a dog that does not reverse), two were **answered
by measuring rather than by building** — the busker's arithmetic is already right at every size of
calm area, and a closure cannot change a route in this city at all — and the closure half turned
into **M45**, on a design taken in that session: a closure's job is *direction, not distance*, and
the grid has to stop being a full grid before anything can point anywhere.

It is on `main` unfinished because **what is left of it cannot be done at a keyboard**: the pursuit
cool-off and dying at high excitement on a quiet street both need a *played run*, and holding five
green changes on a branch until somebody has time to play the game is how a branch goes stale. The
branch stays open for the two findings; the work that is done is on `main` where the next
screenshot and the next playtest will be taken against it.

**Playtest 13 has landed and it overrides that order.** Eight findings in
**[docs/playtests/PLAYTEST-13.md](../playtests/PLAYTEST-13.md)**, off one run that ended on day 4 with a bad ending, and
the sentence under it is *the crowd is supplying almost all of the difficulty and every authored
system in the game is being judged through it* — reported this time by a person, in the plainest
possible words: **"just walking around now increases excitement — this is bad."** The trace has
her standing still for three seconds on an ordinary pavement outside her own front door and
gaining eight points, and a day lost in 29.4s reading `crowd 24.6, events 0.0`.

**So the crowd milestone exists, it is `M46`, and it is next.** The note below said to re-read the
traces before assuming it survived M41. The traces were re-read; it survived. It has now been
found by playtest 07, by playtest 10 and by a human sentence, and deferred three times.

**And the process finding is the one to read first.** The player opened by saying they could not
comment on much *"since you didn't actually finish your work"*, and closed with:
*"don't tell me to playtest again unless all the things we discussed have been implemented — there
is otherwise not really any point in playtesting since it will just surface the already mentioned
things again."* M43 was merged half done on the argument that what was left needed a played run.
This is what that bought: five nerves spent rediscovering things already written down.
**A playtest is a scarce resource. Do not spend one on a build known to be incomplete.**

**The order from here is: the tooling (findings 4 and 5), then M46, then M47, then the rest of
M43, then M48, then M40 — and only then a playtest.** The tooling goes first because M46 and M47
both want exactly the two things it provides: a picture of the grid, and a screenshot on demand
with a line in the trace beside it. M45 is absorbed into **M47**, because the permanent
restrictions it needs and the bigger calm areas playtest 13 asked for are the same mechanism —
`absent_segments`, and what a lot is.

**What that leaves.** M46, M47, M43's last two, M48, M40, a playtest, and then M25's other half —
patrols, which is unaffected by M31 and is now specifically the answer for **acts III and IV**,
where the streets are deliberately empty and the threat should follow rather than sit. *M25's
first half shipped in M33*: running that matters exists now, as a mechanic with a fairness contract
stated over `RUN_SPEED`, which is what that entry always said it would have to be.

**Playtest 04 set the order that stands now.** M27 and M22 are done. **M21 is next**
(four-block calm zones). M20 is **absorbed into M27**: cars follow and queue now, and what is
left of it — eight-way driving, overtaking, a crash as a catalogue event — is unasked-for and no
longer urgent. **M17, the route map, is backlogged by decision** — *"let's not do that for now,
we might revisit later"* — so it is no longer the thing behind M21.

**What M27 leaves open.** Nobody has played it. The densities in `docs/playtests/PLAYTEST-04.md` came off
a probe, and *"the arterial is for crossing"* is still a claim about a player rather than about
a rig. Read a run before touching a constant: `crowd` for contacts and horns, `near` for what
came within reach — which should now be a great deal more than playtest 03's zero — `road` for
time in the carriageway, `ahead` for what the director put in front of her, and `lost` for what
was around when a day ended.

**M50's steps 0, 1 and 2 are done and step 3 is what is left.** Step 0 — `RouteTree` grows the
day's corridor by the player's algorithm, and the telemetry map draws it, which is what turns *"is
anything guiding her"* from an impression formed while playing into a picture written every
morning. Step 1 — the city has permanent structure in it, four to eight dead ends and one or two
big buildings, placed against a reference tree. **Step 2 is placement by role**: a closure is a
**wall** placed off the corridor (the `CLOSURE_ROUTE_BIAS` inversion), a lethal event is a wall
too, a costly one is **friction** weighted onto the corridor, and a one-shot is a **set piece**
offered at every site of a covering set with exactly one of them happening. The tooling that draws
the roles on the map is done with them — colour is the role, shape is the effect, a white pip is
whether she reached it, and there is a **dusk** picture now, because that last one cannot mean
anything at dawn. **What is left is step 3, placeholders**, plus the resistance note's alley as a
set piece.

**Step 2 also gained an item after it shipped**, and it is a strengthening rather than a fix:
*"areas that outside the paths should have blocking events all over — we don't want the player to
step in those areas and it ranges from very costly to deadly."* What shipped biases walls onto the
**rim**; what is asked for is that the ground off the paths be **closed**, on a gradient. It
collides with M28's rule that nothing else happens inside a lethal event's field, and with how few
lethal rows the catalogue has — both named in the entry, neither resolved, plus the one question
that has to go back.

**And read step 3's own opening before touching it**, because the thing it is for was misread here
first: *"the role of budget is to provide variety in encounters and make sure to not spam the same
event over and over again"* — a variety ledger, not a density cap. The count of sites is the
density; the budget decides what fills them, and the point of resolving late is that **variety gets
measured over the encounters that happen rather than over a city she never saw.**

Read the M50 entry before picking any of it up: the things that went wrong there are worth more
than the things that went right, and two of them are the same shape — **a test that was true by
luck**. The retry guarantee broke and the suite stayed green because seed 4242 happened to
generate a different city; a crowd test asserted the wrong predicate for eleven milestones and
failed on a few frames of timing.

**Playtest 15 landed in the middle of it and is `M51`, and six of its seven are done** — the
cul-de-sac the crowd walked through, the spine's zebra, the police car's flank, the game-over
heading, the title colour and the car that vanished on the bridge. The seventh is half-open by
evidence rather than by neglect; see the entry.

**And the three corrections that came out of the player reading the first telemetry map are the
ones to read first**, because none of them was a bug report and all three were the session having
asked the wrong question. The picture drew bundles white and a precinct blue, where the ground was
already saying both; a big building closed four streets where what was wanted joins two blocks; and
the park rule *deleted* events off calm she had not used, where the answer was **"just don't place
events there"** — which keeps every unvisited area clean and raises the density, because a repair
spends the budget twice.

**Playtest 15 has landed, mid-M50, and it is `M51`.** Seven things in
**[docs/playtests/PLAYTEST-15.md](../playtests/PLAYTEST-15.md)** plus a re-report that belongs to playtest 14's finding 7.
The sentence under it is *the city is drawing things it does not mean*: a cul-de-sac is a wall on
the graph and nothing on the pavement, the spine has a zebra painted under a traffic light —
two contradictory promises about who gives way, on the one street where getting it wrong ends the
day — a police car drives north showing its flank, and a car reaches the bridge and blinks out.
Two of the seven are about the frame rather than the game, and one is a report the player is not
sure about and is recorded as exactly that.

**Playtest 16 landed live and is `M53`, queued by the player *after* M52's traffic lights.** Three
findings and one complaint: **the crowd travels a lattice that is not the city** — onto a bridge
with no footway, off a bulkhead into the sea, through crossroads whose arms are grass, vanishing
each time where somebody is looking at it. Underneath two of the three is a missing rule: a
junction is drawn wherever two corridors cross, whether or not its arms are streets. None of it is
news to this file, and that is the part to read: M41 has carried the T-junction item unbuilt for
twelve milestones and M51 finding 1 was the same defect on a cul-de-sac. **A finding that arrives
twice from a player after being written down once by the project is a to-do that was filed and not
read.**

**And playtest 16 also carries the first report anybody has ever made about the back half of the
game: `M54`.** The robber works — *"very good and effective… the timing is good"* — and walks
through walls, because nothing in the event system has ever collided with the city. The resistance
is invisible: *"I'm not sure if I ever did the resistance… there was no indication at the end of the
day or any guidance what to do next."* Both are entries that have sat under "Known-shaky ground"
waiting for exactly this, and the resistance one is the **deliberate risk** this file has named
since the beginning — *"a player may finish a run never knowing the good ending existed"* — being
run and not paying off.

**So the running order is `M52`, then `M53`**, on the player's instruction, and the third of M52's
three items is the one M53 waits on. `M54` is unordered against them and its robber half is a
one-line-shaped bug on a row a player has just called good.

**And the next three are asked for and written down: `M52`.** *"2x2 courtyard and rectangular calm
zones, calm zone rate adjustments, traffic light placements."* Recorded in the player's own words,
with this side's reading kept separate from it and four questions that have to go back before any
of it is built — see the entry. Nothing is started.

**M55's resistance half is designed and unblocked as of 2026-09-01**, and two of its decisions reach
further than the milestone. **The hold is gone** — every step of the subquest was `E` pressed for
three to eight seconds against a key the game never once mentions, and it becomes *touch the mark*,
so the whole optional path is one verb: get to a guarded place. And **a task is two steps now** —
pick up the instruction, perform it the next day — which turns M54's day brief from a courtesy into
the mechanism that tells her what the task is. Five tasks were chosen from six drafts; the calendar
they sit on is exact and starts on day 4.

**And `M56` exists because the fourth question was answered with a system.** A resistance task may
not cost a nerve — *"a nerve is a rewind, not a resource"* — and what replaces it is the city getting
worse the further in you are, starting with abduction vans that take somebody else until you join
and then come for you. Read its entry before M55's, if only for the two things it names and does not
resolve: the first authored event with a **victim**, and a lethal field that **follows her**, which
is the one shape M28's spacing rule cannot be stated about.

M10 (polish) still stands but now sits *after* the playtest work — there is no point
polishing a loop that is about to be re-pitched.

`tools/test.sh` runs 202075 checks (~200s, and `tools/test.sh crowd balance` runs one suite in
seconds); `tools/check.sh` boots the project; `tools/run.sh` plays it; `tools/telemetry.sh` reads
back what the last run did.
