# Decisions

**This file is the history. Nothing in it describes the game as it is now.**

Every other document in this repo states the current state and only the current state. When one of
them needs to say *why* something is the way it is, or *what was tried and rejected*, or *what a
number used to be*, the answer lives here and is fetched on demand. That split is the whole point:
a reader of `CLAUDE.md` or `docs/CITY.md` should never have to work out which sentences are still
true.

**How to use it.** Search for the symbol, the constant or the noun — `PURSUIT_SHAKEN_OFF`,
`absent_segments`, "flock", "corridor". Every fact lifted out of a docstring during the timeless
restyle is findable here by the name it was attached to. If it is not, that is a bug in this file.

**What belongs here**, and each entry is dated and names the milestone and the playtest that
produced it:

- **Decisions taken** — with the options that were rejected, and why. A rejected option with its
  reasoning attached is a decision somebody can overturn; a deleted one is not.
- **Ideas rejected outright** — the same thing for proposals that never became a decision.
- **Changes that happened** — with the measurement that justified them, so a later session can tell
  whether the measurement still holds.

**What does not belong here.** Anything that is currently true. If a sentence in this file describes
how the game works today, it is in the wrong file and belongs in the design doc it is about.

**The playtest files are not absorbed into this one.** `docs/PLAYTEST-NN.md` are primary sources — a
player's own words on a date — and this file cites them rather than restating them.

---

# The archive

Everything below is the chronological record inherited from `docs/HANDOFF.md`, newest first, kept
verbatim. It has not been rewritten into the entry shapes above; it is the raw material they are
drawn from, and it is here so that nothing was lost in the split. **Every dated claim in it was true
when it was written and none of it should be read as current** — that is what this whole file is
for.

## Where to pick up — as it stood at the end of the M50 / playtest 16 session

*(`main` was `c82bcbb`. Superseded; the live version is [HANDOFF.md](HANDOFF.md).)*

> ## Where to pick up
>
> `./tools/test.sh` → **175380 checks, 0 failures** (~200s); `./tools/check.sh` → OK;
> `./tools/run.sh` plays it; `./tools/telemetry.sh` reads back what the last run did.
>
> **The order, and it is the player's:** *"queue those fixes after the traffic light fix"* — so
> M52's remaining item, then M53. M54 and M50's leftovers are unordered against them.
>
> ### 1. M52, item 1 — the calm areas get shapes · `docs/TODO.md`, M52 and **M47**
>
> **Build it from M47's entry, not from a fresh design.** M52's items 2 and 3 are done (the calm
> rate curve and the light poles); item 1 is *"2x2 courtyard and rectangular calm zones"*, and that
> is verbatim an M47 to-do that has been sitting unbuilt with the player's own longer wording:
> *"an inner courtyard (surrounded by buildings) should have a footprint of 2x2 blocks (apartment
> complex) — this never got implemented… also, add calm varieties that take up 2x1 non-square
> shapes."* Two things ship with it:
>
> - **A calm area is never at the edge of the map or beside the main road** — playtest 16, finding
>   4, *"which should be impossible"*, and also already in M47 with its measurement (96 eligible
>   blocks → 56 with the edge rule → 48 with the spine rule). State both over a **footprint**, like
>   `_too_near_the_home` and `_zone_fits` already do, and state the spine rule over
>   `map.main_road` rather than `CrowdLanes.arterial_index`.
> - **The sleepiness curve is already waiting for the new sizes.** `Tuning.sleepiness_calm_multiplier`
>   is `1 / sqrt(blocks)` normalised to a 2×2 zone — 21× / 29.7× / 42× for four, two and one blocks
>   — so a 2×1 lot gets its rate for nothing the moment the generator can make one.
>
> ### 2. M53 — a junction is made of the streets that meet at it · playtest 16, findings 1, 2, 3, 5
>
> One sentence: **the lattice draws a full crossroads wherever two corridors cross, whether or not
> the arms of it are streets.** The southern arm of one is the sea; others open onto precinct paving
> and park grass; one has a zebra painted onto a cul-de-sac's plug. And the crowd walks all of it and
> then vanishes where somebody is looking at it. `CityMap.absent_segments`, `built_over` and the map
> edge already say which arms exist — nothing that draws a junction asks.
>
> **This was filed twelve milestones ago** as M41's *"T-intersections everywhere else on the edge"*,
> and M51 finding 1 was the same defect on a cul-de-sac.
>
> ### 3. M54 — the back half of the game, reported for the first time
>
> - **The resistance never announced itself.** The deliberate risk in "Things deliberately not done"
>   — *"a player may finish a run never knowing the good ending existed"* — has been run and did not
>   pay off. Four separate instructions, kept apart in the entry: the day brief carries the chalk
>   marks' own words; the **first** encounter is the one exception and it is absolute (*"no hint even
>   at the bottom left"*); the mark is placed dynamically alongside a route, which is M50 step 2's
>   own open item about `ResistanceDirector`; and the end of a day says whether anything happened.
> - **The robber runs through walls**, and the rest of that sentence is a verdict — *"very good and
>   effective… the timing is good"*. A pursuing `EventInstance` moves by setting its own position and
>   nothing in the event system has ever collided with the city.
> - **The bike, the loose dog and the cat never have an impact** (finding 9). Three rows whose whole
>   content is a moving thing meeting her. Comes with a design and one open question: a bike aimed at
>   her that she answers by **planning a turn** is neither `MAP` nor `AHEAD_OF_PLAYER`, so it may
>   want a third spawn mode. That is a design conversation, not a field.
> - **The run hint belongs to the lesson, not the mechanic** (finding 6).
>
> ### 4. What M50 still owes
>
> - **"Blocking events all over" off the paths is not true yet, and it is a catalogue question.**
>   The *gradient* is built — very costly at the rim, deadly beyond it, with M28's clearance rule
>   exempted off the corridor — but day 1 is still ~6× denser on the corridor than off it, and only
>   16.2 of its 113.6 placements are walls at all, because the expensive rows have low `max_per_day`.
>   That is *"a budget the catalogue cannot spend is not density"* at the other end of the map, and
>   raising those caps is a balance change that wants its own measurement.
> - **Step 3, placeholders.** Rewritten after the player's correction and **not** started: the budget
>   is a **variety ledger**, not a density cap. *"Its role is to provide variety in encounters and
>   make sure to not spam the same event over and over again. The amount of placeholders is almost
>   one per block sometimes multiple per block."* So a placeholder is a site with a **pool**, and
>   resolving late means variety is measured over the encounters that happen rather than over a city
>   she never saw. Read step 3's opening before touching it — the first reading of it was wrong and
>   the wrong reading is recorded there.
> - **The resistance note's alley as a set piece** — the same item as M54's third resistance bullet.
>
> ### Not queued, and deliberately so
>
> - **Should more junctions be signalled?** Nobody asked for it. Parked in M52 with its costs, since
>   it would repeal M41's *"a property of the street rather than a scattering of them"*.
> - **A building type that closes all four of its streets** (M50 step 1). Recorded, not built, and
>   a different type rather than a bigger one.
> - **M10, polish**, still after the playtest work.
>
> ### The two process rules this session added, and they cost the most
>
> - **Read the file before designing against it.** Four items in one session were things this
>   project had already written down and not built — M41's T-junctions, M47's edge rule and calm
>   shapes, M51's cul-de-sac — and one of them answered, word for word on disk, two questions this
>   side had just put to the player. `CLAUDE.md` has the rule now: **the first tool call of a design
>   task is a search for the words, not a plan.**
> - **A borrowed constant is not a measured one.** `WALL_WORTH_OF_COST` was set to
>   `MARK_WORTH_A_DETOUR` with a tidy argument and it emptied the corridor — two thirds of every day
>   became a wall. It is set by `dog_walker` now, which has to stay on the route because that
>   decision is what the game is made of.

> **M41 is the shape of the city, and its one sentence is: a hierarchy is only a hierarchy if there
> is one of the top thing.**
>
> The city had one kind of street. The arterials differed from the rest only by how many cars were
> on them, so the only route question a junction ever asked was *which way*. It now has **one** main
> road running north to south — dark asphalt, an unbroken double centre line, clearway markings on
> its kerbs, signalled at every junction, and it does not give way to anybody — **two** retail
> precincts of three blocks each, one along the southern shore, which are brick from frontage to
> frontage with no cars in them; and ordinary streets everywhere else.
>
> **The first build got the scale wrong and a person caught it the same day.** It made a main road
> of *each axis* and a precinct of one corridor in each, which is three kinds of street and no
> hierarchy among them: a spine that crosses itself is two spines, and a precinct you meet on every
> third street is what a street is. Two of the three kinds are **places** now rather than classes,
> and that is the correction worth carrying — see [PLAYTEST-12.md](PLAYTEST-12.md), which is the
> first playtest this project has ever taken *inside* a milestone rather than a milestone late.
>
> **The ground is a rate, not a category**, and it is the change that reaches furthest. Calm 2.2,
> precinct 1.5, ordinary street 1.0, main road 0.6, multiplying the excitement decay — so choosing a
> route is choosing a **recovery rate** and not only a set of things to walk past. `WorldContext`
> grows a fourth question, and the shape to copy is that it *generalises an old answer* rather than
> sitting beside it: `is_calm_zone` was a threshold doing a rate's job for the excitement half and
> genuinely being a threshold for the sleepiness half. It is also what makes a precinct worth
> walking to although it is loud, and it is most of what *"a main road is crossed, not walked"* now
> means arithmetically.
>
> **A lane is a queue and a junction is a box, and only the queue was ever modelled.** M38 made a
> car turning into an occupied *lane* look first; nothing modelled the box, so two cars on crossing
> arms each read a clear lane ahead and both entered. Measured over ninety seconds of the arterial:
> **3,776 overlapping crossing-axis pairs, one in half of all frames, the deepest 39px into a 40px
> footprint** — with every assertion about the traffic passing throughout, because each car's own
> lane was legal on every frame. That is the M44 lesson again from the other side: a green suite
> said nothing because it was asking about the wrong unit.
>
> Four clauses close it and each is a way it goes wrong without them. Only crossing traffic
> conflicts. A car that cannot stop is counted as *already in the box* rather than asked to brake —
> the zebra's commit rule, because braking too late means stopping in the thing. **Nothing enters a
> box it cannot leave**, which is the clause that decides whether a busy grid queues or seizes: five
> of forty-six cars were parked in a box without it. And nearest first, then right before left,
> because distance alone leaves a symmetric arrival undecided and right-before-left alone deadlocks
> four cars in a ring.
>
> **Signals have to be measured, not authored.** Arbitrary offsets stop a car at *every* junction it
> comes to — two thirds of the traffic stationary at any instant, and the mean speed on the arterial
> a quarter of a cruise. The cycle is derived from the block spacing now. The wave serves **one**
> direction — 93% of arrivals green with it, 51% against, and a two-way wave is arithmetically
> impossible on this geometry; M41 claimed both and M46 measured it. The fairness contract is the
> *side* street's green, since she crosses the main road while the main road is stopped, and the
> amber is a clearance period rather than a warning.
>
> **And junction control gave the road a capacity it never had.** With crossing cars driving through
> each other the network's throughput was unbounded, so the car population was only ever a noise
> number; the same forty-six put the arterial's floor over the ceiling `tests/test_crowd.gd` states,
> because a car waiting at a light beside you is louder for longer than one going past. It went to
> thirty, and then playtest 12 said the spine was too quiet — which it was, for a reason the number
> could not see: there were two main roads and the weighting split between them. One spine, forty
> cars, blocked 81% of the time.
>
> **The edge of the world was an invisible wall and the camera was the reason.** The lattice already
> ended in T-junctions and nobody could see it — the outermost corridor is a whole street and every
> interior street runs into it and stops — but there was nothing beyond its far pavement, and the
> camera was clamped to the last walkable tile, so anything built out there would have been drawn
> every frame and never once seen. There is a ring of frontages a block deep outside the map now, a
> tunnel where the spine leaves northward, a bridge where it leaves south, and the road simply
> carrying on east and west. **No walkable tile moved**, which is what keeps the route guarantees
> true rather than re-argued.
>
> **Two things about the drawing that a test could not have caught.** Each exit has to fill what it
> opens onto or the gap in the frontages shows the void behind them, which is the invisible wall
> again with a picture either side of it. And four identical signal heads at one junction say
> nothing about which road each of them is stopping: they are two drawings now, face-on for the arms
> running up and down the screen and edge-on for the ones running across it, so *what you can see of
> the lamp* is which street it means.

> **Playtest 11 arrived after M39 was built and before it was merged**, so two of its nine findings
> are about work the player was not running. It is written up in
> [PLAYTEST-11.md](PLAYTEST-11.md) and planned as **M41** (a main road with lights, a tunnel, a
> bridge, junctions that give way), **M42** (a 9x9 city with the home in the middle) and **M43**
> (the rest). The one sentence is *several things in this city are placed without asking what they
> are in the way of*, and the one to read first is the day-3 dog: **standing still is not the fix on
> its own** — it is what M35 rejected, correctly, because she then reaches the dog before the clock
> lets it fire. The lunge has to be triggered by proximity instead, and `PURSUIT_MIN_NOTICE`
> re-decided with it.

> **M39 is playtest 10, and its one sentence is: the danger marks and the danger had come apart,
> and a retried day was not the same day.**
>
> **A cue that marks the wrong things says something false.** M22's rule raised the caret for danger
> that *changes over time* — lethal, telegraphing, swelling, pulsing fast enough to be timed — which
> is a true statement about a thing and not a statement about how bad it is. Fifteen milestones on,
> the marked set and the danger had come apart completely: a fire engine (+115) carried nothing and
> a burning building (+56) carried a caret; the dog walker (+36, the most expensive ordinary row in
> act I and the subject of two playtests) carried nothing while the leaf blower beside it did,
> because its beat is 4.0s rather than 8.0s; and `homeless_yeller` (+31), the man who ends day 1 in
> three separate traces, missed the pulse rule by four tenths of a second — *"there is no danger
> indicator over the homeless person"*, exactly.
>
> The rule is the player's own expectation, stated as an invariant a test can hold rather than as a
> condition: **if A is marked and B is not, A costs more to walk through than B.**
> `EventDef.walk_through_cost()` is the order and `Tuning.MARK_WORTH_A_DETOUR` is where the line
> falls. Two things worth carrying beyond the row. The cost integral **moved out of the test and
> onto `EventDef`**, because the game now asks the question the test was asking, and two copies of a
> number the vocabulary depends on is the `DangerEdge` defect M37 found. And **a colour is the wrong
> channel for a phase**: amber meant *telegraphing*, but `EVENT_STREAM_RADIUS` is 900px and no
> telegraph is longer than 4s, so amber was only ever seen on the two `AHEAD_OF_PLAYER` rows and in
> play it meant *near*. The flash carries the phase now, because a flash is a property of the mark
> rather than of a moment she had to be present for. Accepted cost, written down as a decision: the
> crouching cat (+20) loses its caret.
>
> **One stream shared by several phases is a determinism bug with a long fuse.**
> *(Finding 5: "the tutorial dog on day 3 only appeared once (I died) then it didn't appear
> again".)* `EventScheduler.build_day` ran six phases off one RNG in sequence, so anything that
> changed how much an earlier phase drew moved everything after it — and **a one-shot the run had
> already spent was skipped before its `randf()` was drawn**. So the second attempt at day 3, the
> day the fire engine runs, started the recurring fill one value earlier and produced a different
> city's worth of events: `homeless_yeller` two to eight, `cyclist` none to three, between two
> consecutive attempts at the same day. `docs/TODO.md` had claimed since M32 that *"the retry is the
> same day"*. `_stream(base, salt)` is the fix and the rule: **a phase whose consumption can vary
> gets its own stream.**
>
> What is deliberately *not* closed: a scar, or a spent one-shot's route, genuinely frees ground, so
> placements rejected against it now fit. The composition of the day is identical and a handful of
> route rows start a few tiles along the same street — which is the run's own history showing
> through, and is the answer that should show through.
>
> **And the tutorial was a weighted roll.** `charging_dog` is weight 1.4 of a day-3 pool and
> `_teach_the_run` said outright what happens when the dice disagree. Whole day 3s with
> `charging_dog x0` exist, so a player could reach act II never having been shown the one control
> the game later requires. `_ensure_the_run_is_taught()` closes it.
>
> **The chase ends at a rate now, and that is the part to carry.** *(Finding 13: "the running
> tutorial dog is impossible to escape at the moment", clarified by the player as "the charging
> start earlier was fine — it was enough time to react properly" and "the issue was that the dog
> kept following for too long".)* This session's first answer was wrong and the way it was wrong is
> worth more than the fix: it read the finding as a **reaction window** problem, measured a real
> two-tenths-of-a-second window, and built for that — while the player had been talking about the
> **break-off** the whole time. **A probe that reproduces the numbers is not evidence that it
> reproduces the complaint.**
>
> `Tuning.PURSUIT_SHAKEN_OFF` ends a chase after 0.8s of the gap **opening**. A pursuer is faster
> than a walk and slower than a run by construction, so only running can open the gap — which means
> "walking away can never end a chase" and "running away always ends one" stop being two
> inequalities fighting over the same three numbers and become facts. That fight is what let a
> widened stand-off silently eat an escape, and what once left a robber's trigger eleven pixels to
> live in. Measured on a rig that accelerates: the answer costs **0.86s of running, 12 points**,
> against 35 before, and every wrong answer still costs the day.
>
> **Two things are open and are written down rather than hidden.** The window to answer at the lunge
> itself is 0.1–0.2s, because she is walking into the thing; a player answers during the telegraph
> instead, where it is visible and closing for two and a half seconds. And **the dog still backs off
> through its telegraph**, which a player has watched and called nonsense — it is what a stand-off
> costs while the lunge is fired by a clock rather than by proximity, and it is the first entry in
> the next plan.
>
> **The rest of the fourteen.** The playground had never once out-emitted the calm ground it stands
> on — 7.0/s against a 7.7/s decay, so its denial radius was its own inner radius, 40px of 150, and
> standing in one was a net benefit; it was right in M5 at a 3.5x calm multiplier and has been wrong
> since M18. The doubled `!!` is two conditions now, within `LETHAL_MARK_LEAD` of the radius that
> ends the day **and** closing, deliberately at the *relative* rate where the screen-edge badge uses
> the thing's own — the badge says *a thing is coming*, this says *the contract is about you*. The
> pause takes `space` and carries the day and the nerves. `Telemetry.snapshot()` puts a PNG beside
> the entries that are about a moment. And the commit is in the log filename, at the end, because a
> timestamp has dashes in it and so does `abc1234-dirty`.
>
> **The thing nobody reported, and it should be the next milestone:** five runs, no day won, and
> every losing line reads `crowd 39.4, events 0.0`. That is playtest 07's finding 17 after the
> milestone that answered it.

> **M38 is not a playtest — it is five reports and two design instructions in one sitting — and its
> one sentence is: every one of them had already passed a green suite, a screenshot, or both.**
>
> **The birds froze in mid-air and two playtests had already said so.** A flock was one sprite drawn
> seven times at offsets derived from the instance's own position, sharing a single `rise` term that
> reached 1.0 at the end of the telegraph and then held — so the seven birds *could not* move
> relative to each other and the whole animation was over before the burst began. M35 had rebuilt
> the **event** around exactly this complaint and never looked at the picture. It is
> `EventDef.flock_size` now: eleven birds, each with its own heading, speed, height and wingbeat,
> **and its own `contribution_at`**, so the middle of a flock stacks five fields and the rim stacks
> one. Three things to carry, all in `CLAUDE.md`: the excitement stays a pure query one level down
> (the world sums over instances, a flock sums over birds); `flock_spread` comes **out of**
> `outer_radius`, or the fairness contract was checked against a different disc; and **`lerp` cannot
> turn a vector round** — interpolating a unit vector toward its opposite runs down the same line to
> zero and back out the way it came, which is why the one bird the containment could not turn went
> 202px out of a 62px wheel while the code holding it ran every frame.
>
> **The cat was drawn facing the wrong way and the convention was written down nowhere.** Both cat
> SVGs faced **west** while every other sprite with a front faces east, and `_heading_is_west()`
> mirrors the art — so a cat bolting west was drawn running east. The art was wrong, not the flip,
> and the rule is inferable only from `dog.svg`, which reads right in one direction and one only.
>
> **And a car turning into an occupied lane made the other car vanish.** The diagnosis is the one
> worth keeping: **a placement is not a separation, and the separation must not be doing the
> placement's job.** `_divert()` chose an arm of a junction out of the tile map alone, so a car
> diverting round a closure materialised inside whatever was already in that lane, and M27's
> positional resolve then did the only thing it can — move a body. Front-to-back resolution
> **compounds**, so a bunched queue shunted the rearmost car several lengths backwards in one frame:
> 1627 corrections in ninety seconds at a closure, worst 134px, down to 146 and 66px once the turn
> looked first. **The queue was legal on every frame either way**, which is exactly why five years of
> "no two cars are inside each other" tests could not see it. `TrafficIndex` is the look and it is a
> frame stale on purpose; `claim()` closes two placements in the same frame; and
> `_join_the_back_of_the_queue()` is the guarantee behind the six re-rolls, because a retry is not a
> guarantee.
>
> **A finished run had no key on it at all.** The ending said `esc to quit`, `Esc` opened the pause,
> and the pause offered `Esc` and `Q` — *"you can just cycle between pause screen and loss screen at
> that point"*. `space` on the ending goes back to the title now and `R` on the pause starts the run
> again from anywhere.
>
> **The title screen is the doorstep of a real first day**, with the traffic driving and the events
> playing out on it and nobody pushing a pram through them — not a menu and not a still. It needed
> the `process_mode` split used **deliberately** for the first time: the city on `ALWAYS`, the day
> paused, and the player pinned back to `PAUSABLE` because she is a child of the city and would
> otherwise inherit the exemption. That last line is the M33 bug written out as a decision instead of
> a mistake. The thing that looked like the cause and was not: **a paused `Camera2D` with smoothing
> on never arrives** — smoothing is applied in the camera's own process callback, so a `PAUSABLE`
> camera under a paused tree sits wherever it last was, which on frame one is the world origin. The
> title screen showed an empty street for that reason and no other; ninety-five crowd agents were
> walking about the doorstep a thousand pixels off-camera and everything the screen was meant to show
> was working perfectly.
>
> **And `--press` could reach `Esc` and nothing else.** The rig that exists *because* nothing in the
> suite or a screenshot had ever pressed a key still could not press the two keys the pause screen is
> mostly made of: it pushed an `InputEventAction`, and `Q` and `R` are read as **keycodes**, the way
> a screen's own shortcuts usually are. `--press key:r 3.5` can, and the flag may be repeated,
> because one tap can only ever photograph one screen. The one thing it cannot do: `R` reloads the
> scene and the reloaded scene re-presses, so a rig restarting the game loops for ever — read the
> boot lines rather than waiting for the PNG.
>
> **One balance number moved and nobody has felt it.** `SLEEPINESS_CALM_ZONE_MULTIPLIER` 10 → 12, so
> calm ground fills the meter in 20s rather than 24. Every milestone since M28 has made the walk
> *out* harder and left the reward at the end of it the same length — but the last human verdict on
> the difficulty is playtest 06's, and this is the one number that decides whether a day is winnable
> once the park is reached. It is in the known-shaky list, with the flock.

> **M37 is playtest 07's finding 2, and its one sentence is: a category is a thing you can always
> put one more row into.**
>
> **`EventDef.Look` opened with `PERSON`, `VEHICLE`, `OBJECT`, `ANIMAL` and `FIRE`**, and those five
> names were doing the damage by themselves. Sixteen of the twenty-eight visible rows drew five
> pictures between them: a man shouting, a busker, a poster crew, a protest and the robbery that
> ends the day were one `person.svg`; a delivery van, a fire engine, a police car, a riot van, an
> army truck and the unmarked van that takes the baby were one van.
>
> **The part to carry is that it reads as an art chore and it had already cost two findings.** M34
> spent a milestone fixing `alley_robbery` for a complaint about `homeless_yeller`, because a player
> can only say *"the robber"* and the two drew the same man. Playtest 09 then asked *"who is the
> person killing me?"*, which is exactly the question row one of the vocabulary exists to answer.
> And a third had gone unreported: `DangerEdge` kept its **own** table of which picture a look
> meant, so the screen-edge badge — the one cue whose entire content is *what* is coming — drew a
> delivery van for a fire engine.
>
> **So it is a rule with a test rather than fifteen drawings.** No two rows share a look, no two
> looks share a silhouette, `EventInstance.icon_for()` is the single table and the badge reads it,
> and `look` has no default worth having. The cost of adding an event is a drawing. That is M34's
> `obstructs_radius` move arriving at the other half of the vocabulary, and the same sentence
> underneath it: **a field that is only ever *reached for* is a list wearing a rule's clothes.**
>
> **Three of the fourteen new pictures are more than a picture.** The **robber has two postures**,
> switched on `is_waiting()` — M36 gave that row three states and the screen showed one, so *a man
> is standing there* and *he has seen you* looked identical, which is the `cat_crouched` /
> `cat_running` rule arriving at the row where reading it wrong ends the run. The **protest is a
> crowd**, and its body followed its picture: the catalogue had said *"one person's worth, because
> one person is what it draws… the art is the fix"*, and it is 55px now, two ranks across exactly
> the ground it takes — the clearest case in the game of art deciding a gameplay number. And the
> **café has people at it** (finding 11), which is the tables being what obstructs and the
> conversation being what it emits, with only the first ever drawn.
>
> **Buildings sort against nothing now** (finding 4), and the fix is *not* the one M34's diagnosis
> pointed at. The comparison is **meaningless**, not merely wrong: buildings tile their lots exactly
> and no lot tile is walkable — both asserted since M3 — so nothing can ever legitimately stand
> behind one, and two things that can never be on opposite sides of each other have no business
> being sorted against each other. `building.gd` had claimed the opposite in a comment for
> twenty-two milestones, and it was true of the ground footprint and false of every sprite that
> overhangs it.
>
> **And the zzz stopped dodging nothing** (finding 14). The baby's cue steps out of the exclamation
> mark's column, and that column is only occupied when there *is* a mark in it — unconditional, it
> put the cue a body's width to one side of the pram on the commonest picture in the game. Playtest
> 06's own lesson a third time, *a cue is a claim about a moment*, reaching a player for the reason
> M32's two did: **nothing in `tests/test_danger.gd` can see a `_draw()`.** It is
> `Stroller.baby_cue_aside()` now and the suite asks it.
>
> **Measured, five seeds:** events placed per day is **identical**, day for day, on days 1, 8, 12,
> 13 and 14 — 48.0 / 66.8 / 79.2 / 84.6 / 86.6 — and so are protests placed and events carrying a
> body. A five-fold body on three events a day is absorbed, because placement never considers how
> wide a thing is; only `_ensure_the_city_is_still_walkable` could have refused it, and it had room.

> **M36 is playtest 09, and its one sentence is: two things in this build had been doing nothing at
> all for milestones, and both looked finished from the outside.**
>
> **`Esc` never opened the pause once.** It shipped in M33 with a screen, a key, a README line, a
> `TODO.md` entry and a line in the debug overlay. The guard read `_summary.visible`, and `_summary`
> is a **`CanvasLayer`, whose `visible` is `true` from the moment it is added to the tree** — what
> the summary shows and hides is the `Control` inside it, which is what `is_showing()` answers. So
> the guard was satisfied on every frame of every day. It asks `is_showing()` now and opens **over**
> the summary as well, with `PauseScreen` putting back the paused state it found rather than
> assuming one.
>
> **The lesson is the rig, not the guard.** Nothing in the suite or in a screenshot has ever pressed
> a key, so neither could have caught it. `--press <action> <seconds>` exists now — and its own first
> version used `Input.action_press()`, which sets the polled state and nothing else. That is fine
> for `--walk`, which the stroller polls every frame, and useless for anything answered in
> `_unhandled_input`: it produced a screenshot of the game carrying on, which looks exactly like the
> bug it was written to check. Use `Input.parse_input_event`.
>
> **The man shouting was killing runs by standing still.** *"Who is the person killing me in the
> third try of day 1? It didn't move and it took a long time to have any effect."* The trace names
> him six times at the same coordinates over twenty-one seconds, which is the finding written down
> before it was reported. `EventDef.paces` is the answer the player specified: a **beat** rather than
> a journey — walks its route, turns round at the ends, never departs and never expires, because it
> is a fixture that moves. He is 10 → 14 intensity, and he loses the body M34 gave him, because
> **anything mobile is exempt from "solid things are solid"** (M19's `dog_walker` decision, unchanged).
>
> **The robber is a pursuit that is a place before it is a moment.** *"A robber should increase
> excitement on sight and getting close to them should be day ending… and if you get close they
> should start moving towards you."* `EventDef.pursues_within`: three states rather than two, and
> both new ones needed saying out loud — **the clock starts when it notices her** (a telegraph run at
> dawn four streets away is not a notice) and **its notice does not damp what it emits** (the
> damping means *this has not started yet*, and a man standing in an alley has started; what has not
> started is the lunge). 16 over 200px, lethal inside 30, comes at 130px/s from 140.
>
> **`validate_pursuit` gained a third clause that was found by measuring, not by thinking.** The
> trigger must be inside `PURSUIT_BREAK_OFF`. At 170 against a break-off of 170 the rig **strolled
> away from him every time**, because she was already standing at the distance that means it has
> lost her. Walking away is the one thing that must not work.
>
> **And a bug the change exposed:** `_ensure_one_usable_park` could erase a **scar**. It strips the
> spoilers off the least-disturbed calm block, and a burnt-out shell that had been on that corner
> since day 3 was one of them — so it vanished for a day and came back the next. `tests/test_acts.gd`
> caught it by luck (one seed, day 9) rather than by design. Scars are exempt now, for the same
> reason ambient events are.
>
> **Measured:** `homeless_yeller` +17.7 → +31.2; robberies placed per day unchanged at 3.4; events
> placed per day 39.8 / 58.8 / 78.6 against 40.0 / 58.8 / 78.6. The density did not move.

> **M35 is playtest 08, and the run it came from ended on day 3 — the shortest any playtest has
> produced.** Five things. Three of them are one sentence and it is playtest 07's own, surviving the
> milestone meant to answer it: *a thing exists, and being near it changes nothing.*
>
> **The park spoiler denied three percent of a park, and nobody had done the arithmetic.** M24 put
> **one** event in the block she settled in yesterday. What denies calm ground is not reaching it —
> it is out-emitting the decay the calm multiplier has already raised to 7.7/s — so a busker at
> intensity 9 has a *useful* radius of 100px in a lot 704px across. It is a crowd now: a grid over
> the calm ground sized by `EventScheduler._denial_radius()`, capped by
> `Tuning.SPOILERS_TO_DENY_A_PARK`, **each cell rolling its own def** so a spoiled park is a busker
> and a leaf blower and a market stall rather than nine copies of one sprite. 8–12% denied → **91%**
> of a courtyard and **99%** of a four-block zone, five seeds, twenty lots.
>
> *"I can walk over the robber without issue"* is that same finding from close up and **not** a
> regression of M34 — a probe confirms the body stops her at 25px exactly. A busker at intensity 9
> against a 7.7/s decay nets +1.3/s **at his own feet**. The complaint was never that he has no
> body.
>
> **Nothing vanishes while you are looking at it.** The end of an event was `_finish()` wherever it
> stood, which for the two shortest-lived rows is directly in front of her. An event that is over
> **leaves** now: emits nothing, cannot end the day, carries no cue, and moves until it is past
> `Tuning.OUT_OF_SIGHT`. Anything mobile leaves at its own speed and needed no data. Two things
> never leave and both would break something that reads the finishing position — a
> `spawns_on_finish` event stops where the thing it leaves belongs, and a place was always simply
> over.
>
> **A fairness contract stated in seconds is not stated at all, and this is the one to carry.**
> `validate_pursuit` bought the day-3 dog 2.4s of telegraph and never asked *where it spends them*:
> `EventDirector` sites what the day owes 184px in front of her — which is where she was already
> walking — so it closed the gap in three quarters of a second and then stood **inside its own
> lethal radius**, unable to fire, for the rest of the phase whose entire purpose is to be a
> warning. Every line of the contract passed, three attempts running, while it killed her. The fix
> is the contract restated as geometry: `Tuning.pursuit_standoff()` (which it *holds*, backing off
> if she walks in) and `Tuning.PURSUIT_BREAK_OFF` (so the chase ends when it is beaten rather than
> when the clock says so — without it the right answer cost forty points however early it was
> given, and the trace has her running, doing exactly what the HUD asked, and losing anyway).
>
> **Measured on a rig:** walking into it or away from it both lose the day; running costs **21–24
> points** and reacting sooner costs less. Events placed per day unchanged at 40.0 / 76.0.
>
> **Two things found by doing it.** Clamping the approach at zero is *not* a stand-off — it leaves
> the dog standing politely still while she closes the last hundred pixels herself. And a rig that
> flees on a timer runs *into* the dog, because the director sites what it owes in front of the
> direction she is actually travelling; three traces of a lethal dog "arriving from nowhere" were
> the rig sprinting at it. `--flee` waits for the pursuit now.
>
> **Five nerves**, asked for by name. Three was the number from M6, when a lost day also advanced
> the calendar; M32 took that half away and left the number.

> **M34 is four of playtest 07's findings and one sentence: a thing that stands still is solid at
> the width it is drawn.** *"None of the non-moving obstacles do anything — I can freely walk over
> them"* (16), *"I can walk over the robber and he doesn't do anything"* (13), *"a still car
> standing on the road doing nothing"* (7), *"the backing out lorry does not connect to the
> building"* (15).
>
> **`obstructs_radius` was a list, not a rule, and that is the whole finding.** It had only ever
> been *reached for* — when one particular event wanted to block a pavement — so it was set on five
> rows out of thirty and a delivery van was scenery. Making it a rule sets a body on two thirds of
> the catalogue, and the number is not a balance value in any of them: it is **half the
> silhouette**, because `_draw_spread` has always drawn a blocking object at exactly the width it
> obstructs, and a body that disagrees with the picture is a lie about where she can walk whichever
> way it lies. Three exemptions, all written down: mobile (a moving wall pins her — M19's
> `dog_walker` decision), `AHEAD_OF_PLAYER` (`validate()` refuses it), and anything with no
> silhouette.
>
> **A lethal radius and a solid body are the same mechanism, and this is the trap in it.** She is
> stopped with her centre `obstructs_radius + PLAYER_BODY_RADIUS` from his, so a `hard_fail` event
> whose body reaches its own inner radius can **never fire**. That is not an unfair event, it is an
> event silently switched off, which is worse and reports nothing. `alley_robbery` is the case:
> giving a man a man's body meant moving the inner radius 22 → 30, or the pram would have been held
> three pixels outside the thing that takes the baby. `EventDef.validate()` refuses the arrangement
> on load now.
>
> **And the analysis in `PLAYTEST-07.md` was wrong about which robber.** The player never reached
> day 4 in either trace and `alley_robbery` is day 8 and alleys only. The man walked over is
> `homeless_yeller` — nineteen `near` entries — so finding 13 is finding 16 with a person in it,
> and finding 2's *"not sure what that person was supposed to be"* is the same man again. Check
> which event a complaint is actually about before fixing the one it names.
>
> **Findings 7 and 15 are both "it is standing somewhere that makes no sense of it".** A parked van
> was on a `ROAD` tile — a traffic lane the crowd knows nothing about and drives straight through,
> blocking a route nobody walks. A lorry whose entire content is *the danger is behind it* was
> sited on any pavement tile at all and drawn facing east. `EventDef.pavement_side` is the field
> both wanted: `AT_THE_KERB` puts a van on the footway she is using, `AGAINST_THE_BUILDING` gives
> the lorry a wall and turns it to face out of it.
>
> **Measured, five seeds:** events placed per day is **unchanged** (day 1: 38.8 → 39.6, day 14:
> 75.4 → 75.2), which is the number that had to not move, and pavement-blocking obstacles on day 1
> went **12.2 → 17.2**. One row of the cost table moved and it is the robbery's.
>
> **Finding 4 is diagnosed and deliberately not fixed** — see below, and
> [PLAYTEST-07.md](PLAYTEST-07.md). It is a `Building` sorting by its **south edge** while its mass
> extends a block north of it.

> **M33 is playtest 07, and it is one sentence: every cost in the game was paid on contact, and
> almost nothing else in it was real.** Sixteen of the nineteen findings are that sentence from
> one side or another, and two of them can be read straight off the traces the player left
> behind: a run that loses day 2 three times inside half a minute with the crowd supplying 82–100%
> of the excitement each time, and every `near` entry written at an event's own outer radius
> reading `events 0.0`.
>
> **The falloff had a shoulder missing.** `Tuning.falloff` was `(1−t)²`, which is a quarter of the
> intensity at the midpoint of the band and six percent three quarters of the way out — so a café
> at 12/s sat under the 3.5/s walking decay across the outer 60% of its own field. That is the
> whole of finding 18, *"I shouldn't have to get actual contact to get penalized"*, and fixing the
> **shape** fixed thirty rows at once where thirty hand-widened radii would have been thirty
> chances to break the fairness contract. It is `1−t²` now. The contract is stated over *distance*
> and no distance moved.
>
> **Three things had to move with it, and each is a trap for the next person.** The crowd took the
> same shoulder and did not want it — a field that bites from a distance is right for an authored
> event and wrong for one of 240 bodies — so it pays it back in *radius* (88 → 55, 170 → 104) and
> the close pass costs exactly what it did. Running stopped being a trap **by accident**, because
> a fatter field makes time-in-field matter more; `EXCITEMENT_FROM_RUNNING` 9 → 14 restores it and
> a test asserts it row by row now. And a contact costs 18 rather than 26, because the authored
> content finally carries the share the crowd was carrying alone.
>
> **A contact can end, and people get out of the way.** Two defects, either enough to trap her:
> the separation resolved to exactly `BUMP_RADIUS`, which is the radius that *releases* the
> contact, so a resolved pair sat on its own threshold; and a walker steers back to its lane
> centre, which is where she is standing. Longest single contact: 1.0s → **0.1s**. Then the
> larger thing — M19 and M27 built the crowd on *eleven contacts down a lane centre against one
> on the midline*, and a probe re-run on `main` says that ratio is **gone**: thirteen against
> fifteen. It cannot be tuned back, because a midline is 16px from two lane centres and
> `BUMP_RADIUS` is 14; that line was two pixels wide when M19 measured it. So the careful line is
> a **behaviour** now — somebody who sees a pram coming steps aside, hurries across, or waits.
>
> **Standing still settles nothing.** `EXCITEMENT_DECAY_IDLE` was 6.0, the *fastest* of the three.
> What settles a baby is being pushed. And the player asked whether the telemetry could see it: it
> could not, because standing still emits no entry of any kind, so the strongest move in the game
> appeared in a trace as a **seventy-four-second gap between two lines**. There is an `idle` span
> now.
>
> **And running started to matter.** *"The run button is a trap shouldn't be an invariant — there
> should be legitimate cases where running is required."* So there is one, and it had to be a
> mechanic rather than a number, which is what `TODO.md` has said about M25 since playtest 02.
> `EventDef.pursues`: faster than a walk, slower than a run, lethal, and it gives up. Walking and
> running give **opposite outcomes** rather than the same outcome at two prices.
> `Tuning.validate_pursuit()` is the contract and it is stated over `RUN_SPEED`. Verified on a
> rig: a player who walks directly away from the first frame is still caught (1.6px), one who runs
> escapes with 240px to spare.
>
> **The run is taught the day it starts to matter, and not before.** Day 1 says how to walk and
> nothing else. `charging_dog` is gated to `Tuning.RUN_TAUGHT_DAY` (3), `EventDirector` moves the
> first one to the head of the queue on that day so the lesson is not left to a weight of 1.4, and
> the HUD says *Hold SHIFT to run* on the frame the dog telegraphs rather than at dawn. That is
> half of **M26 arriving before M25**, and it satisfies rather than breaks the ordering constraint
> M26 was written with: the forced run sits behind the thing that makes running right.
>
> **And there is a pause.** `Esc` opens it, `Esc` closes it, `Q` quits. It quit outright for
> thirty-three milestones. The game mentions it once per run, the first time she stops of her own
> accord — not on the doorstep at dawn, which is somebody who has not started rather than somebody
> who has stopped, and not over the walking lesson, because the `Teach` label is one label.
>
> **Ten of the nineteen are open** and they are listed at the bottom of
> [PLAYTEST-07.md](PLAYTEST-07.md). The two worth knowing before touching anything: **solid
> objects are not solid** — `obstructs_radius` is set on five rows of thirty, so a delivery van, an
> ice cream van, a reversing lorry and a burnt-out shell can all be walked through — and **finding
> 4 is not diagnosed**. The warning indicators render below roofs and the geometry says they
> should not: a building's drawn mass fills exactly its own lot and `Entities` is y-sorted on the
> ground plane. Reading the code did not find it and two screenshots did not catch it. It needs
> the case reproduced, most likely in a carve or a courtyard passage.

> **M32 is playtest 06, and it is one sentence: a cue is a claim about a *moment*.** M30 spent a
> milestone deciding *which* things raise the mark over her head and never looked at **when** —
> and the next player's two complaints were both about when. The mark stayed up for 1.4s after
> she was over the kerb, where a car cannot reach her; the badge tested how fast the *gap* was
> shrinking, which is her 92px/s plus the thing's, so **walking towards anything lethal announced
> it**. Membership was right in both cases and neither could be seen by a test:
> `tests/test_danger.gd` asserts what is marked and cannot see a moment.
>
> **What that took, and the two things the write-up did not predict.** The badge measures the
> event's own approach with the player held still, caps its range as a *window* rather than a
> distance, holds a raised badge, and sorts by **arrival** rather than distance. Then a trace
> found the rest: *"they flicker a lot"* had a **second cause** — a thing on the screen boundary
> trades places with its own badge every frame, which needs hysteresis on the *edge*, in screen
> pixels, and no amount on the closing rate touches it. And the director's `AHEAD_OF_PLAYER`
> events were eligible, so `cat_dash` — the one kind of event whose entire content is that it is
> *not* announced — was raising and dropping a badge inside a tenth of a second.
>
> **The mark comes down at the kerb.** `Stroller.warn()` takes a source and `stand_down()` lowers
> only that source's own mark, which is the smallest thing that is not the setter the additive
> rule exists to prevent. The 1.4s hold is unchanged: bridging the gap between two cars in one
> lane is a real job, and the fix is a second condition rather than a shorter hold.
>
> **A lost day is retried, not skipped**, which closes a design question carried since M6. The
> calendar moves only on a win, so three nerves are three attempts wherever they are needed.
>
> **And the pram says how the baby is** — the vocabulary asked for in the other direction for the
> first time: four states, not a gauge, over the pram and never in the exclamation mark's column.
>
> **The log can see a cue at last.** Both defects were invisible to a trace, because every entry
> said what the *world* did and none said what the game **told her about it**. That was playtest
> 05's own suspicion about the gap in the format, and playtest 06 walked straight into it.
>
> **Three decisions from earlier sessions still govern things and are easy to miss.**
> **M17, the route map, is backlogged** — *"let's not do that for now, we might revisit later"*.
> **A patrol is wrong for act I** — *"patrol shouldn't be there for act I"* — which narrowed
> M25 to acts III and IV, where the streets are deliberately empty and the threat should follow
> rather than sit. And **two halves of M21 are open by decision**: main roads with lights, and
> the canal.

---

## Where things are

`main` is green and playable. `./tools/test.sh` → **175380 checks, 0 failures** (~200s);
`./tools/check.sh` → OK; `./tools/run.sh` plays it; `./tools/telemetry.sh` says what the last
run actually did.

**M50 is done except for step 3.** The day's corridor exists (`RouteTree`), the telemetry map draws
it *and* what was placed against it, the city has permanent structure — dead ends and big buildings
that join two blocks — and the day is **placed by role**: walls off the tree, friction on it, set
pieces offered at every site of a covering set with one of them happening. Off the corridor is a
**range** now rather than a bias, very costly at the rim and deadly beyond it. What is left is
**placeholders** (step 3, rewritten after the player's budget correction and not started), the
resistance note's alley as a set piece, and the catalogue-caps half of *"blocking events all over"*.
**Three invariant decisions are taken** *(2026-08-31)*: the two-routes guarantee is reachability,
the park rule refuses ground at placement rather than stripping events afterwards, and M28's lethal
clearance rule is exempted off the corridor. See `docs/TODO.md`, M50.

**M51 and M52 are done, M53 and M54 are the queue.** M51 is playtest 15 — the cul-de-sac the crowd
walked through, the spine's zebra, the police car's flank, the game-over heading, the title colour,
the bridge. M52 is the calm rate curve (`1 / sqrt(blocks)`, 21× / 29.7× / 42×) and the signal heads
moved to the kerb they were always documented as standing on; its remaining item is the calm
**shapes**, which is M47's entry. M53 and M54 are playtest 16, and the pick-up block at the top of
this file is the order.

*(The count went 202075 → 175380 in that session, and the drop is one assertion narrowing on
purpose: `_test_nothing_happens_inside_a_lethal_field` no longer walks every other placement past a
lethal **wall**, because a wall is exempt from that rule now. It still checks every lethal set piece
and asserts that a run places both kinds, so the exemption cannot become a way of asserting
nothing.)*

*(The count went 135308 → 202075 in that session. Most of it is one new test —
`test_calm_she_has_not_used_is_left_alone` walks three seeds through a whole run and asks the
question of every plan against every unused calm area — and the rest is that a day now places 5–9%
more events, so every per-event assertion runs more often.)*

**The count went 74540 → 122119 on M41, and it is the lattice rather than the milestone.** The
jump is +64% and it wanted checking rather than asserting, because a count that moves by that much
without a deletion or a new rule is usually a suite that started doing something else. Measured by
putting `CITY_BLOCKS` back to 9×9 with all of M41's code in place: **74362**, against `main`'s
74540 — the same suite asserting the same things about a smaller city. So M41's own new
assertions (the signal contract, the junction box, the ground rate, the boundary) are worth about
nothing on the count and the whole of it is 49% more city being asserted over per block, per
street and per seed. Two things came out of that measurement worth keeping: the run at 9×9 fails
three checks in `test_telemetry.gd` (*"the retry has 5 `delivery_van` where the day had 7"*), so
the retry-determinism assertion now has a **city size** in it — M41's act I caps went up with the
lattice and a smaller city cannot spend them — and the ~161s is the honest new cost of the inner
loop, which M44 had just brought down to 96s.

**The counts for M42 and M44 were never written down here** — that is the two milestones of
staleness this file opens by admitting — so the 74540 above is `main` as M44 left it and there is
no M42 figure to compare against.

**The check count went 46394 → 46498, and all of it is M37 asserting the new rule.** Two of those
checks run over the whole catalogue — one row per look, one silhouette per look — plus the baby
cue's four answers, which are a test at all only because the decision was pulled out of `_draw()`
and given a name. Nothing was removed and no plan moved: the density probe returns the same numbers
day for day against `main`.

**The count before that went 46563 → 46394, and almost all of the drop is one row changing shape.**
`homeless_yeller` is mobile now, so it needs an `ALONG_STREET` route and `_place_one` re-rolls when
one cannot be built — mostly on `SQUARE` tiles, where a corridor axis is not meaningful. Several
suites assert per *placed* plan over fourteen days, so a handful fewer men shouting is a couple of
hundred fewer checks about the same days. Events placed per day is unchanged over five seeds, which
is the number that says it is the same city. M36 added ~35 of its own: the pause, the paced beat,
the waiting pursuer, and the pursuit walk-through now running over the whole catalogue rather than
over one row.

**The count before that went 46522 → 46563.** M35 added forty-one: the three answers to a pursuit walked
rather than asserted, the leaving rule and its out-of-sight and backstop halves, and the two new
distance clauses on `validate_pursuit` running over the catalogue on load. Nothing was removed —
the spoiler crowd changes what is in one lot rather than how many events a day places, which the
probe confirms at 40.0 and 76.0 unchanged.

**The count before that went 46607 → 46522, and the drop is the same shape as the one before it.** M34 added
about 250 checks — the solidity rule over the whole catalogue, the lethal-body constraint, the two
placement rules asserted over fourteen days, and the pram's own radius against the scene it is
authored in — and removed about 330, all from one place: `delivery_van` and `ice_cream_van` want
the kerb lane now, so they are offered half as many candidate tiles and land slightly less often,
and several suites assert per placed plan. Events placed per day is unchanged over five seeds, so
this is the same suite asserting the same things about the same days.

**The count before that went 47085 → 46607, and that drop wants its own explanation.** M33 added ~50 checks —
the pursuit contract, the caret's timeable rule, the motion-shaped decay ordering, the running
ordering row by row — and removed ~530, all from one place: `_along_street_path` now refuses a
route that would *finish* jammed against the city wall, so fewer along-street routes are placed
and the per-route assertions run fewer times. That is a suite asserting the same things about a
smaller set, not a suite that stopped running. Before that it went 47062 → 47085 on M32, which is
the milestone where the whole point is
about *when* a cue fires, and almost none of that is assertable. What is assertable was made so
on purpose — the badge's two questions are **static functions** (`approach_speed`, `announces`)
so a test can ask them without a viewport, and the rest is a rig walked at a parked fire engine
and then a fire engine driven at a parked rig. Before that it went 31768 → 47062 on M21's own
tests, which loop over every street of every zone of every seed. A count that moves with what is
being asserted is doing that; a count that drops after anything but a deletion is a suite that
stopped running.

**M37 landed in this session and playtest 07 is down to three open findings**, none of them large.
The four it closed are the entry above; what is worth carrying forward is in "Gotchas learned in
M37" below, and the one to read first is the first: a category in an enum is a list waiting to
happen, which is M34's lesson arriving a second time from a direction that looked like art.

**M34, M33, M35 and M36 landed in the sessions before it**, and between them they are the rest of
playtests 07, 08 and 09.

**M32 closed playtest 06.** The five things it fixed are the entry further up; what is worth
carrying forward is in "Gotchas learned in M32" below.

**M21 landed in the session before it, and playtest 06 opened in the middle of it.**

**M21 made the calm big enough to walk in.** A calm **area** is now either one block or a
four-block **zone**, and every city has one or two zones. What that meant in practice was less
about parks than about the lattice: `block_plans`, `block_layouts` and `calm_blocks` are keyed by
the block that *anchors a lot*, so a zone is one entry with four blocks of ground and everything
counting calm areas counts it once; `CityMap.absent_segments` says which streets this city does
not have; and `CityMap.blocked_segments()` merges that with today's closures for every route
search in the game. **Measured against `main` over 24 seeds and four walks each, the density
playtest 06 had just approved is unchanged**: placed per day 40.1 → 40.1, live around her 4.87 →
4.79, on screen 2.74 → 2.75, met on a 40s walk 2.91 → 2.85.

**Five milestones landed in the session before it, all of them playtest 05's.**

**M28 put one event on every block.** Day 1 goes from 13 placed to **50 across 49 blocks**, from
1.8 live around her to ~11, and from about one on screen to **3.3**. The finding that matters
for next time: `budget_for()` was never the constraint. The day-1 pool's `max_per_day` values
summed to 18, so a budget of a hundred placed the same thirteen events — *"a budget the
catalogue cannot spend is not density"*, hit for real. Caps first, budget second, both measured.
Raising the caps took away the two jobs they were quietly doing, so both became rules:
`EVENT_SPACING_SAME`/`EVENT_SPACING_ANY` at placement, and **nothing else happens inside a
lethal event's field**.

**M29 made the traffic readable.** The city drove on the right east-west and on the left
north-south, because the convention was stated over the lane *offset* and the side that lands on
flips with the axis. And a car giving way now brakes toward a **stop line** instead of toward
zero speed, so it stops at the zebra rather than half a block short of it or on top of it.

**M30 made the mark over her head mean one thing:** *this will end your day*. Only a `hard_fail`
event and a closing car raise it. And the traffic finally carries its own cue — a car sounding
its horn draws the doubled lethal caret, because the caret was a private method on
`EventInstance` and "the entity carries its own cue" had silently meant "the *event* entity
does".

**M24 ended the same park twice.** The calm block she settled in is remembered and tomorrow puts
something loud in it; measured over a whole run, the repeat rate goes from **28% of days to
zero**.

**M31 gave act I teeth and six new things to look at.** Lethal events per day now run **0, 3, 4**
over days 1–3 — a **cyclist** from day 2 and a **reversing lorry** from day 3, both with the
doubled telegraph — so the escalation is a change of *kind* rather than of count. Plus
`loose_dog`, `market_stall`, `leaf_blower`, `pigeon_flock` and `ice_cream_van`, each with its own
silhouette. It also fixed the two things underneath *"dog walkers are not moving?"*: a
re-streamed event was **rewound to where the day put it at dawn**, and an `EventInstance` had no
gait at all.

**Two milestones before that, both playtest 04's.**

**M27 moved the world to where the player is.** The emphasised finding — *"don't load
everything upfront"* — reads as a performance note and is not one: the game was already at
120fps with 530 agents, and what it actually said is that every population number was being
divided by the 99.2% of the city nobody is looking at. The crowd is a **field** that travels
with her, events are **planned across the whole city at dawn and instantiated near her**, the
cat is the first `AHEAD_OF_PLAYER` event, and traffic keeps a headway. Day 1 is 11–13 events
of which 3–4 are live at any moment. [PLAYTEST-04.md](PLAYTEST-04.md) has the measured table.

**M22 deleted the circles.** `EventAuraLayer` no longer exists and a test asserts it cannot
come back. What replaced it: a **caret over the entity** for danger that *changes over time*
and nothing else, breathing with current emission; a **badge at the screen edge** carrying the
thing's own silhouette for anything lethal or faster than a walk that is off-screen and
closing; the exclamation mark over the player generalised from traffic to events and given a
**second level** for danger already on her; and a **HUD line** for the `city_wide` sources that
had no on-screen presence at all. The vocabulary is in [EVENTS.md](EVENTS.md), "The visual
vocabulary", and the standing decision is in `CLAUDE.md` next to the invariants.

**The one thing to carry into the next session is unchanged and is now louder: nobody has
played any of it.** M19's street, M27's densities and M22's cues are all measured off probes
and screenshots. *"The arterial is for crossing"* is still a claim about a player rather than
about a rig — and M22 sharpened it into a number that wants a human verdict: **walking north up
the arterial from a standing start loses day 1 in fourteen seconds.** The entries that settle
these already exist: `crowd` for contacts and horns, `near` for what came within reach — which
should now be a great deal more than playtest 03's zero — `road` for time in the carriageway,
`ahead` for what the director put in front of her, `lost` for what was around when a day ended.
**Read a run before touching a constant.**

- **M0–M9 complete.** Full 14-day run, four-act escalation, resistance subquest, three
  endings. Documented in `docs/`.
- **M11–M15 complete.** Playtest 01's first five milestones: the quick wins, the SVG asset
  pipeline, the crowd as the noise floor, the M14 balance re-pitch, and block purposes with
  planned arcs.
- **M18 complete** *(taken out of order — see below)*. A day is 180s instead of 330s, aimed
  at **a minute of play with a grace of three**. Calm ground fills the meter in 24s instead
  of 119s: 10x the street rather than 3.5x, so a second in a park is worth ten on the
  pavement. Street gain went *up* (0.24 → 0.42), because M14's relationships are stated over
  `day_length()` and a 45% shorter day would otherwise have stopped making "real progress on
  the way" true.
- **M16 complete.** Road closures. Five kinds, 1–4 streets a day by act, barriers at both
  mouths so a shut street is readable from the junction, and the day-level invariant — at
  least two distinct routes to at least two distinct calm areas — checked by max flow on the
  junction graph before each closure is accepted.
- **M23 complete** *(taken out of order — it was the gate)*. A chronological run log in
  `user://telemetry/`, on by default, read with `./tools/telemetry.sh`. It records what the
  code cannot recompute: the random outcomes that branch a run, the seed the generator
  actually settled on, **the commit it ran on**, what the player did, what came near them,
  and how each day ended. **The gate is now open** — M19's balance half and M24 both have
  their data source.
- **M19 complete.** Bodies on the street, plus the event-density pass. Collision that
  displaces both parties, a lethal carriageway with its own stated fairness contract, traffic
  that gives way at a zebra, `cafe_tables` blocking a pavement from day 1, `dog_walker`
  re-pitched from −0.1 points to +21.6, and `budget_for()` measured rather than derived. The
  exclamation mark over the player came forward from M22 with it.
- **M27 complete** *(taken out of order and immediately)*. The crowd is a field around the
  player, events stream in and out of a radius around her, the cat became the first
  `AHEAD_OF_PLAYER` event, and cars queue instead of driving through each other. It took the
  half of **M20** that was worth having; the rest of M20 is **parked**, not queued. The three
  new invariants it left in `CLAUDE.md` — the day is planned whole and only instantiated near
  her, separation between bodies is positional, and `EVENT_STREAM_RADIUS` stays wider than the
  widest field in the catalogue — are the ones a later milestone is most likely to break.
- **M22 complete.** The rings are gone and the symbol vocabulary replaced them: caret, screen-
  edge badge, the player's exclamation mark at two levels, a HUD line for `city_wide`. Also
  fixed a silent tooling failure — `tools/shot.sh` never forwarded its dev flags, so a shot
  taken to look at one event was of the doorstep and nothing said so — and added `--walk`,
  without which a screenshot of a post-M27 world is a screenshot of almost nothing.
- **M28 complete.** One event per block: 50 on day 1 across 49 blocks, ~11 live around her,
  3.3 on screen. The caps were the wall, not the budget. Left two new placement rules behind —
  spacing between events, and nothing inside a lethal event's field.
- **M29 complete.** The city drives on the right on **both** axes, and a car giving way brakes
  toward a stop line instead of toward zero speed.
- **M30 complete.** The mark over her head means *this will end your day* and nothing else, and
  a car sounding its horn carries the doubled lethal caret of its own.
- **M24 complete** *(playtest 05 asked for it by name)*. The park she settled in yesterday gets
  something loud in it today; the repeat rate goes from 28% of days to zero. It keeps its own
  record rather than reading the telemetry.
- **M31 complete.** Act I has two lethal things — a cyclist from day 2, a reversing lorry from
  day 3 — so lethal-per-day runs 0, 3, 4 over days 1–3 and the escalation is a change of kind.
  Plus five more act I rows for variety, each with its own silhouette. Fixed the streaming
  rewind and gave mobile events a gait.
- **M32 complete.** Playtest 06's five: the badge measures the thing's own approach (plus a
  window, a hold, a screen-edge margin and a sort by arrival); the mark over her head comes down
  at the kerb, via a source rather than a setter; a lost day is **retried** and the calendar only
  moves on a win; the pram carries the baby's four states; and the log has a `cue` entry, so the
  next cue defect is visible to a trace rather than only to a person.
- **M21 half complete.** Four-block calm zones: 22 tiles square, 10.8s corner to corner against
  a full meter's 23.8, one or two per city, never taking a stretch of the arterial and never
  beside other calm. The lattice grew holes and route redundancy stopped being true by
  construction. **The other two halves — main roads with lights, and the canal — are open by
  decision**, not forgotten; see `TODO.md`.
- **M33 complete.** Playtest 07's first nine: the falloff grew a shoulder, the crowd paid it back
  in radius, standing still settles nothing, a contact resolves and costs less, running started to
  matter, the run is taught on the day it does, and there is a pause.
- **M37 complete.** Playtest 07's finding 2 and three more, and one rule: **one picture per row,
  and no two rows share one.** `EventDef.Look`'s five categories were drawing sixteen of the
  twenty-eight visible rows; fourteen new silhouettes, a single icon table the screen-edge badge
  reads, and a test for both halves. Plus a café with people at it, a protest whose body followed
  its picture (11 → 55px, density unchanged), buildings that sort against nothing, and a baby cue
  that stops dodging a mark that is not there. Fifteen of playtest 07's nineteen are closed
- **M34 complete.** Playtest 07's next four, and one rule: anything that stands still is solid at
  half its silhouette. Two thirds of the catalogue has a body now where five rows did; a parked van
  is at the kerb rather than in a traffic lane; a reversing lorry has a building to reverse into;
  and a lethal event's body has to fit inside its own kill radius, which moved `alley_robbery`'s.
  Density unchanged, pavement-blocking obstacles up 41% on day 1.

## The decisions that govern the next milestones

Taken at the end of the M16/M18 session and easy to miss, because they are decisions rather
than code. All of them are written up in `PLAYTEST-02.md` (decisions 9–14).

1. **The beginning is challenging too.** Not extremely difficult, but a player who never
   meets danger never learns to deal with it. The measurement below says act I and act II
   currently cost nothing at all, and "the early game teaches events are safe, then act III
   kills you" is the worst of both. **M19 has to make an act I street cost something.**
   *(Done, and then some: M19 gave the street bodies and M27 put three or four times as many
   of them where she is looking. Whether act I now costs too much is the open question, and it
   is the one a human has to answer — see the fourteen seconds above.)*
2. **Difficulty is self-selected through the extra quests.** The resistance is the dial. That
   is why the base game has to be hard on its own — the dial *adds* difficulty, it does not
   supply it. Consequence: "how visible should the resistance be" stopped being a curiosity.
   A player who never finds the dial is locked to the easiest setting and never told there
   was one.
3. **The act I/II numbers are set from data, not argument.** Build the mechanisms (M19), ship
   telemetry (M23), read real runs, then pitch. This made M23 a gate rather than a
   recommendation, which is why it went first. **The gate is open** — M19's balance half is
   now waiting on runs, not on code.
4. **Telemetry is an ordered log, not a metrics dump** — what happened, in what order,
   readable top to bottom with no tool. It records what the code *cannot* recompute, above all
   the **random outcomes that branch a run** (a one-shot that fired, a block arc that
   advanced, an alley trap that was set): those depend on run history, so no seed reproduces
   them. Anything derivable from the seed, `Tuning` or the catalogue stays out. *(Shipped in
   M23; [TELEMETRY.md](TELEMETRY.md) is the version to work from now.)*
5. **The resistance stays hidden and loses its key.** *(Closes an open question carried since
   M8.)* No marker, no quest log — wanting the difficulty dial and finding it are the same
   behaviour. But `E` appears in exactly one line of the game, so the hold becomes automatic
   on proximity: the cost was always standing still in an alley, never the keypress. M26.

   **Overturned by the player on 2026-08-31, and only the first half of it.** *(Playtest 16, finding
   7: "I'm not sure if I ever did the resistance. I walked on one chalk symbol once but there was no
   indication at the end of the day or any guidance what to do next. During the day brief there
   should be instructions from the chalk marks to tell me what the next task is. Only the first
   encounter (the chalk mark) should come without hint.")* This is the first playtest ever to reach
   a chalk mark, so it is the risk in *"Things deliberately not done"* being run — *"a player may
   finish a run never knowing the good ending existed"* — and not paying off.

   What survives is decision 2 and the **first encounter**: finding the dial is still the player's
   own doing, with no hint at all, deliberately including the HUD line that exists today. What is
   overturned is everything after it — once she has found a mark, the resistance speaks to her in
   the day brief. See M54.

## Read this before touching the event or signalling code

**The cost table has been regenerated and is now asserted by a test.** `docs/EVENTS.md`, "What
an event actually costs". **Every row moved in M33**, because what changed was the *shape* of
`Tuning.falloff` rather than any one event. One row is now negative — `burnt_shell`, a reminder
rather than an obstacle — where three used to be; `tests/test_events.gd` names exactly that one
as the exemption and requires everything else to cost more to walk through than to walk around,
so a *second* negative event has to be a decision rather than an oversight. The table is only
about events, and since M19 that is no longer the whole cost of a street: a contact with a
pedestrian is ~10.8 points and a car's horn ~8, and neither is in the catalogue. **M27 widened
that gap and M33 narrowed it deliberately** — a balance argument that reaches for the cost table
alone is answering a narrower question than it thinks, but it is a much less narrow one than it
was.

**Running is the wrong move against every event you route *around*, and the right move against
the one kind of thing that follows you.** *(M33.)* `EXCITEMENT_FROM_RUNNING` (14/s) plus the
collapsed decay (3.5/s → 0.5/s) beats the shorter exposure for every row that merely emits, and
`tests/test_events.gd` asserts it **row by row** now. It had only ever been measured and written
into a document, and that is exactly how it broke: M33's change to the falloff shape made running
a point or two cheaper than walking through the four widest fields, silently, in four rows.

The exception is `EventDef.pursues`, and the shape of it is the point. Running cannot be made
correct by moving a constant, because against something that merely emits the two options are the
same outcome at two prices. Against something that **follows** they are opposite outcomes: walking
away loses the day and running away does not. That is why M25's half of this had to be built
rather than tuned, and `Tuning.validate_pursuit()` is the contract — stated over `RUN_SPEED`,
exactly as `TODO.md` said it would have to be.

**No circles, and the replacement has shipped.** *(M22 — this section used to say "has
started".)* The rings are deleted rather than restyled, `EventAuraLayer` is gone, and
`tests/test_danger.gd` asserts it cannot come back, because a comment in a deleted file cannot
stop the next person reaching for a ring when something new needs signalling. Two rules in the
replacement are the whole reason it is better, and both are easy to lose:

- **A cue that marks everything says nothing.** The caret is for danger that *changes over
  time* — telegraphing, lethal, pulsing, swelling — and **not** for whatever is loudest. A
  first pass used "louder than the walking decay", which sounds defensible and marked
  `poster_crew`, `barricade` and `burnt_shell`: the exact three rows the cost table calls
  scenery. That is the ring's own mistake in a new shape, and the test caught it.
- **The mark breathes** with current emission. Without it a pulsing event stops being something
  to time a pass through and becomes something that hurts at random.

The badge announces only what she cannot outwalk, and it **must carry a silhouette** — an arrow
that can only say "something" is an anxiety rather than a warning. Adding to this vocabulary is
a design decision, not a drawing one; read `docs/EVENTS.md`, "The visual vocabulary", first.

## Seven playtests, and the order they left behind

All seven are live plans: **[PLAYTEST-01.md](PLAYTEST-01.md)** (thirteen findings → M11–M17),
**[PLAYTEST-02.md](PLAYTEST-02.md)** (twelve → M18–M26), **[PLAYTEST-03.md](PLAYTEST-03.md)**
(the first read off a run log; it reorders rather than adds),
**[PLAYTEST-04.md](PLAYTEST-04.md)** (seven findings; adds M27 and moved M22 and M21 to the
front), **[PLAYTEST-05.md](PLAYTEST-05.md)** (six findings → M28, M29, M30, M24 and M31,
**all closed**), **[PLAYTEST-06.md](PLAYTEST-06.md)** (five things, **all closed** as M32), and
**[PLAYTEST-07.md](PLAYTEST-07.md)** (nineteen, **fifteen** closed — M33, M34, two picked up by
M35, and four as M37).
Read 07 and then 06 before picking anything up; the summaries here are not a substitute for them,
and each carries what its analysis got wrong as well as what it got right — 06's is at the bottom
of the file under "What the analysis missed", and 07's is inside the M34 section, where the finding
about a robber turned out to be about a different man entirely.

The queue is numeric except where something jumped it, and each jump had one practical reason:
**M18** because closure counts tuned against a day that was about to halve would have been
tuned wrong; **M23** because it was the gate on M19's balance half and on M24; **M27** because
playtest 04's emphasised finding turned out to be underneath three of the other six, and
because M21 and M22 are both judged against a street that now has traffic on it; **M22**
because the player asked for the circles a second time; **M28–M30 and M24** because a fifth
playtest arrived with six findings and four of them were cheap, self-contained and blocking
judgement of everything else — a player who cannot predict which side a car comes from cannot
learn a street, and a mark that fires for nothing teaches that marks mean nothing; and **M21**,
because four-block calm zones are the structural fix for twenty seconds of walking in a circle
and traffic that overtakes is not.

**Playtest 06 did not jump anything**, which is worth saying: it arrived part-way through M21
with the instruction *"take note of those but continue implementing the next item on the handoff
first"*, so M21 finished and its five things were done immediately afterwards, as **M32**.

**M17 left the queue rather than moving in it** — backlogged by decision, not deferred by
priority.

One piece of history worth keeping, because the file is now the only place it is legible:
**M22's exclamation mark was pulled forward into M19 and the rest of M22 was not** — a lethal
car has no telegraph phase to ring, and redesigning the signalling of eighteen events in a
session about physics was the wrong shape. M22 then generalised the cue rather than replacing
it.

## Gotchas learned in the playtest-05 session

- **A budget the catalogue cannot spend is not density, and this is what that looks like.** Four
  types with caps of three each is a hard ceiling of twelve however large the budget is. When a
  density number refuses to move, check the caps before checking the arithmetic.
- **Measure four numbers, not one.** Placed per day, live inside the stream radius, on screen at
  once, and met on a route. They moved by different multiples in M28 — 3.8×, 6×, 3.3×, 2× — and
  only the last is what a player is complaining about. Quoting whichever one flatters the change
  is the easy mistake.
- **`max_per_day` was doing a second job nobody had written down.** Placement is a uniform
  random tile with no minimum separation anywhere, so the cap of three was the only reason two
  dog walkers had never landed on one pavement. Raising a cap took a rule away.
- **Spacing measured tile-to-tile misses a mobile event entirely.** A dog walker's route is
  thirty tiles long; checking only the tile it starts on let it walk the length of an
  abduction's field. Measure whole route against whole route, from both ends — the closest point
  of two segments is an endpoint of at least *one* of them, and it need not be yours.
- **A convention stated over the wrong variable is invisible to every test.** "Offset 3 runs the
  positive way along the axis" is self-consistent and it is right-hand traffic on one axis and
  left-hand on the other. Separation, headway, capacity and noise are all true either way, and a
  still screenshot cannot see which way a car points. Only a human watching a junction could.
- **Braking toward zero speed is not stopping *somewhere*.** A car aimed at zero stops wherever
  the curve runs out, which with four times the room it needs is most of a block early. Aim at a
  place. And shape the approach with a **gentler** rate than the emergency brake, or the onset
  of braking and the commit point are the same instant and nothing ever stops.
- **Sampling a tile grid by stepping world points aliases where it matters.** The crossing scan
  probed every 32px, which is fine everywhere except at the stop line, where the car is a few
  pixels from the paint, both samples miss, and it pulls away with somebody on the zebra. Walk
  tiles. Now in `CLAUDE.md`.
- **A cue that lives in one class has an invisible edge.** The caret was
  `EventInstance._draw_mark()`, so "the entity carries its own cue" quietly meant "the *event*
  entity does", and the one lethal thing outside the catalogue — a car — had nothing at all.
- **A script error inside a test does not always fail the suite.** GDScript aborts the erroring
  *function* and carries on in the caller, so a `_physics_process` that died half way through
  still let the assertions after it run and pass. Four stack traces in the middle of a green
  run. `CLAUDE.md` says an error *hangs* the runner; that is the other failure mode, and this
  one is quieter.
- **A test can assert more than the design promises and nobody notices until the numbers move.**
  `_test_one_park_stays_usable` measured the whole block lot; `_ensure_one_usable_park` has
  protected only the calm *ground* since M15, deliberately. Invisible at thirteen events a day,
  false on nine days out of fourteen at fifty.
- **Where a trace and a rule want the same fact, the rule keeps its own copy.** M24 is the first
  rule that wanted to read the telemetry. Reading it would have been smaller and would have made
  the game play differently with `--no-telemetry`.
- **The give-way test had been measuring nothing since M27.** The crowd is a field around the
  player and the rig has no player, so two of the three cars it picked were recycled on the
  first frame and every measurement after that was of a different road. Any rig that steps
  crowd agents by hand has to `set_focus()` first.
- **A probe that disagrees with the game is wrong about the game.** M31's walk probe said a
  7,500px round trip peaked at 13 excitement while a real run of the same day died in fifteen
  seconds. It was stepping the agents but never `Crowd._physics_process`, so no contact and no
  horn ever fired — and the crowd is most of what a street costs. The instinct to trust the
  measurement over the observation is the one to resist.
- **Adding rows to a fixed density takes a share from every existing row.** M31 put seven new
  events into act I and the two playtest 05 had named by name immediately thinned out. Their
  weights had to go *up* to stay where the previous milestone had put them. Whenever the
  catalogue grows, re-measure the things an earlier milestone promised.
- **A single total over three seeds fails on noise.** The named-decision assertion broke at 17
  against a bar of 18 while the five-seed mean was comfortably over. A per-seed floor plus an
  average says the same thing and does not.
- **Only half of "a spent plan stays spent" was implemented.** Streaming may take a running
  event away and give it back — and it was giving it back *at the tile the day chose at dawn*.
  A dog walker at 32px/s against her 92 crossed the stream boundary constantly, so it teleported
  home over and over and read as never moving. The invariant now says *and a running one
  resumes*.
- **A thing that moves has to look like it moves.** The same complaint had a second cause with
  no bug in it: every crowd agent has a two-frame stride and an `EventInstance` had none, so a
  tile a second read as parked. A bob driven by distance covered, not by time.

## Gotchas learned in the M21 session

- **A turn is the one move that commits without looking, and it had been getting away with it.**
  A crowd agent's turn swaps the axes, so the coordinate it had *along* its old corridor becomes
  the one it has *across* the new one — the lane it then steers away from. Turning at the far
  edge of a junction therefore drops a car onto the pavement band for the next three tiles. That
  has been true since M13; four closures a day was too rare for anyone to see it, and four
  dead-end arms per calm zone was not. `_can_turn_here()` waits for the band the agent belongs
  in, and the lookahead went from 26px to a corridor's width so there is time to wait.
- **A spawn point is not a position an agent walked to.** An agent dropped into the middle of a
  junction rolls a turn on its first frame from wherever it was put, which can be the
  carriageway. Also true since M13, also only surfaced because the RNG order changed and
  reshuffled the crowd. `_settle_junction()` marks the junction it starts in so it does not.
- **Five seeds is not a measurement of a noisy number.** The first density comparison said M21
  had cut "events met on a walk" from 3.6 to 2.0, which would have been most of the difficulty
  playtest 06 had just approved. Over 24 seeds and four directions each it is 2.91 → 2.85. The
  handoff already said *"a single total over three seeds fails on noise"*; this is the same
  lesson costing an hour in the other direction.
- **The obvious tidy-up round a zone's edge was wrong, and only a tile-by-tile check said so.**
  A zebra whose road runs into a park looks like nonsense to remove — but a crossing sits where a
  *pavement* lane meets a *carriageway*, and both are still there. Repainting them put pavement
  in the middle of a junction cars turn through. What is genuinely dead is only the **stub**: the
  quarter of each T-junction on the zone's side, which is exactly `grow(SIDEWALK_WIDTH)`.
- **A repaint that clears as it goes cannot have two lots sharing ground.** `CityMap.repaint()`
  filled each block with building and then painted its carves, which is order-dependent the
  moment one lot's open rect covers another lot's block: whichever came later in the dictionary
  punched a building-shaped hole in the park. Clear everything, then paint everything.
- **A default in a lookup is a wrong answer waiting to be believed.** The generator's
  "no two calm areas adjacent" check read `owner.get(neighbour, member)`, so a block with no
  calm neighbour compared its own coordinate against its anchor and reported every zone as
  adjacent to itself. Every seed failed validation and the generator quietly fell through 64
  attempts and returned the last one.

## Gotchas learned in M32

- **A cue whose condition is not the thing it claims to mean is invisible to every test in the
  suite.** `tests/test_danger.gd` asserts *which* things are marked, over the whole catalogue,
  and both of playtest 06's defects were about **when**. Two milestones' worth of careful rules
  about membership, and the next complaint came from the other axis entirely.
- **A hold cannot tell "the danger is between two cars" from "the danger is over".** Only the
  system that raised it can, which is why the fix is a source and a `stand_down()` rather than a
  shorter hold — and why the source check matters: a caller that has been outbid finds nothing
  of its own to lower, so this is not the setter the additive rule exists to prevent.
- **Two hysteresis problems in one cue, in different units.** The closing test needed a hold, in
  seconds. The screen boundary needed a margin, in *screen* pixels — a thing on the edge trades
  places with its own badge every frame, and the world is drawn scaled, so the same question in
  world pixels has no fixed answer. The write-up predicted the first and not the second.
- **A range cap wants to be a window, not a distance.** The same 800px is a fire engine four
  seconds away and a dawdler twenty seconds away. Stated as `LEAD_TIME` seconds of the thing's
  own approach, the cap scales itself and is in the units the fairness contract is already
  written in.
- **A cap on how many cues show is a choice, and distance is the wrong basis for it.** Sorting by
  distance means `MOST_AT_ONCE` drops the thing arriving first in favour of a slow thing standing
  closer. Sort by arrival.
- **The thing whose whole content is that it is not announced was being announced.** The
  director's `AHEAD_OF_PLAYER` events were eligible for a badge, so the cat M27 rebuilt to
  *happen to her* got a pre-announcement — which flashed for a tenth of a second and vanished,
  because it walked into view immediately. Found in a trace, not in a test.
- **The observer must name the cause, not the nearest thing.** The first `cue` entry reused
  `_nearest()` and blamed an ice cream van 513px away for a car's horn — reproducing, inside the
  log written to settle it, the exact *"unattributable"* complaint playtest 05 made about the
  mark. Two things raise that mark and the observer can check both.
- **A cue span is written when it *ends*.** The complaint is a duration — "it is still up and
  the car has gone" — and a duration cannot be read off a line saying a cue went up. Every `cue`
  entry carries how long it lasted, and the mark's carries how much of that she spent on the
  road: **0.3–0.7s, all of it on the road**, is what the fix looks like in a trace.
- **`--walk south` can walk into a wall and stay there for seventy seconds.** A day-12 probe run
  produced one cue and a column of `crowd` bumps at the same tile. A walking probe is not a
  player; check the tiles in the trace before concluding anything about the density.

## Gotchas learned in M33

- **A falloff shape is a design decision wearing an implementation's clothes.** Thirty rows of
  hand-tuned radii and intensities, and the thing making three quarters of every radius free was
  one exponent nobody had looked at since M2. When a whole class of content "does not land", check
  the curve before checking the constants.
- **One shape change moves every consumer of it, including the ones that did not want it.** The
  crowd sums the same `falloff` the events do, and doubling what a body is worth at mid-range put
  the arterial floor at 18.4/s against a 3.5 decay — a main road that fills the meter in six
  seconds. It pays the shape back in **radius**, so the close pass is untouched and only the wide
  cheap middle went.
- **A measured fact written only in a document breaks silently.** *"Running is the wrong move
  against every event"* had been in `CLAUDE.md` since M19 and was false in four rows the moment
  the falloff moved. It is a test now. Anything the docs state as measured and load-bearing should
  be.
- **A ratio the design rests on can decay out from under it with nobody touching the numbers.**
  M19 measured eleven contacts down a lane centre against one on the midline and M27 re-measured
  it; by M33 it was thirteen against fifteen on `main`, because a midline is 16px from two lane
  centres, `BUMP_RADIUS` is 14, and every milestone since has given walkers more reason to be off
  their exact centre. Two pixels of clearance was never a mechanic. Re-measure the ratios a design
  claims, not just the numbers it sets.
- **A hysteresis that is one number wide is not a hysteresis.** The bump resolved to exactly
  `BUMP_RADIUS`, which is the value that releases the contact, so a resolved pair sat on its own
  threshold and re-fired. Resolve *past* the release, always.
- **Positional separation can be undone by steering.** The invariant says separation is positional
  and never a force, and it is — but a walker steers back to its lane centre at 90px/s, so the
  separation was being un-made every frame. The fix is not more separation, it is giving the other
  body somewhere else to want to be.
- **The obvious avoidance test is the wrong one for anything crossing your path.** "Is it within a
  lane's width of my line right now" is right for somebody sharing the pavement and useless for
  somebody crossing it — at 60px/s they enter that window a third of a second before the contact.
  Predict the **closest approach**. A probe said nine of every twelve contacts were exactly that
  walker, which is how the first version got caught doing nothing.
- **Measure the thing you are changing, not the thing next to it.** The probe first counted "is
  anybody touching", which chains one contact into the next on a busy pavement and reported a 3.8s
  contact that was really nine. Per-agent, or the number is a different number.
- **A rig that drives the player must turn the player's own `_physics_process` off.** The
  pursuit probe moved her twice a frame — once by the rig and once by `Stroller` — so she fled at
  157px/s instead of 92 and the chase looked unfair in the player's favour. `CLAUDE.md` already
  says a probe that disagrees with the game is wrong about the game; this is the cheapest way to
  make one disagree.
- **A rig cannot hold a reference to an event past the frame it finishes.** `EventManager` frees
  a finished instance, and `if not _dog: return` then silently swallows the whole measurement.
  Twelve minutes of a probe printing nothing.
- **A new catalogue row reshuffles every day's rolls.** Adding `charging_dog` changed which tile
  every later event landed on, which surfaced a latent bug in `_along_street_path`: a route
  truncated by a closure can *finish* jammed against the city wall even though the length check
  keeps a margin from it. That check had been passing by luck since M5.
- **The first cue rule you write about "changes over time" will mark everything again.** M22
  learned it with "louder than the walking decay"; M33 learned the same lesson with
  `pulse_period > 0`, which is six of the ten rows available on day 1. The question is never
  *does it change* — it is **can the player play against the change**.

## Gotchas learned in M34

- **A field that is only ever *reached for* is a list wearing a rule's clothes.**
  `obstructs_radius` existed from M5 and was set five times in thirty rows, every time because
  somebody wanted that particular event to block a pavement. Nothing was wrong with any of the five
  and the whole thing was wrong. When a field's value looks like a series of local decisions, ask
  what would decide it for a row nobody has thought about — here it was already decided, in
  `_draw_spread`'s own comment, and had been for four milestones.
- **A lethal radius and a solid body are the same mechanism.** She is stopped
  `obstructs_radius + PLAYER_BODY_RADIUS` from the centre, so on a `hard_fail` event a body that
  reaches the inner radius does not make it unfair, it makes it **never fire** — and nothing
  reports an event that quietly stopped working. It is `validate()`'s job now. The general shape:
  when two systems both measure a distance to the same point, check what happens when one of them
  wins.
- **Check which event a complaint is actually about.** *"I can walk over the robber"* was written
  up as an `alley_robbery` bug, and `alley_robbery` is day 8, alleys only, and both traces end on
  day 4. The man is `homeless_yeller`, with nineteen `near` entries. The write-up's arithmetic was
  wrong as well — nothing stopped her, so her centre reached his and the day ended — and the
  arithmetic only *became* true when he was given a body. A finding named after the wrong row sends
  the next person to the wrong file.
- **A rule that reads `obstructs_radius > 0` may mean two different things.**
  `_something_to_put_in_a_park` refused anything with a body, which meant "nothing that closes the
  ground" while only scaffolding had one and meant "no buskers" the moment everything did — which
  would have emptied the spoiler pool and retired M24 without a test failing on anything but the
  spoil rate. `OBSTRUCTION_A_PARK_CAN_HOLD` is the same rule stated as what it always meant.
- **"It does nothing" can be two complaints in one sentence.** The delivery van did nothing because
  it had no body **and** because it was in a traffic lane the crowd drives straight through,
  blocking a route nobody walks. Fixing either alone leaves *"a still car standing on the road
  doing nothing"* true.
- **A probe that divides inside the loop it accumulates in is off by a factor per seed.** The first
  density run said 1.68 events live around her against a documented 4.79, which reads exactly like
  a regression worth a milestone. It was five seeds' worth of dividing seed one's contribution five
  times. Before believing a number that disagrees with a document, run the same probe against
  `main` — which is the comparison that has to be made anyway.
- **`var x := load(...).instantiate()` does not parse**, and the failure is the quiet one: the
  suite dies at *load* time, prints nothing at all, and `tools/test.sh` sits there. `CLAUDE.md`
  already says a run with no output is an error rather than a slow suite; this is the cheapest way
  to cause one.

## Gotchas learned in M37

- **A category in an enum is a list waiting to happen.** `Look.PERSON` was not a wrong value on any
  one row; it was a name that made "one more thing that is roughly a person" always the cheap
  answer, sixteen times over five names. When a field's values look like a taxonomy rather than
  like identities, ask what the *next* row will be tempted to reuse. Same shape as M34's
  `obstructs_radius` and worth recognising faster next time.
- **A second table of the same fact is where the fact goes wrong.** `DangerEdge._icon_for` and
  `EventInstance._draw_body` both answered "what does this look like", and the badge's copy was the
  one nobody looked at — so the cue whose entire content is *what is coming* had been showing a
  delivery van for a fire engine, an army truck and an abduction, with no test able to see it and
  no player having reached day 8 to notice. `EventInstance.icon_for()` is the one table now and the
  badge asks it.
- **Before fixing a comparison, ask whether it should be happening at all.** Finding 4's diagnosis
  was correct and pointed at a better sort. The actual fix is that buildings and entities can never
  legitimately be on opposite sides of each other — nothing walkable is inside a lot — so they do
  not sort against each other. A comparison that is *always* wrong in one direction is usually a
  comparison that should not exist.
- **A comment can outlive the thing it was true of by twenty-two milestones.** `building.gd` said
  the layout *"keeps every extrusion off the street, so the player is never hidden under a roof
  while walking past one"*. The first clause was true of the ground footprint and the second did
  not follow from it, and nothing ever re-read the sentence because the first half kept passing.
- **A decision that only exists inside `_draw()` cannot be asked about a moment.** M32 learned that
  a cue is a claim about a moment, and then wrote a new cue's placement as four lines inside a
  `_draw`, where no test could reach it — and that is exactly the one playtest 07 complained about.
  `Stroller.baby_cue_aside()` is those four lines with a name. The badge's `approach_speed` and
  `announces` are static functions for the same reason; this is that rule not being applied twice.
- **Art can be the thing deciding a gameplay number, and the catalogue can say so and still be
  wrong for a year.** `protest` obstructed one person's width with a comment explaining that the
  body may not claim ground the picture does not and that *"the art is the fix"*. It was right, it
  was written down, and it sat there because the fix looked like a drawing rather than a change.
- **A contact sheet is worth a screenshot rig.** Fourteen sprites judged one gameplay screenshot at
  a time is a day's work and mostly photographs of pavement. A throwaway scene that instantiates a
  real `EventInstance` per `Look` in a grid — real defs, real `_draw`, `process_mode` disabled and
  `age` set past the telegraph — takes ten minutes and shows every row at once, including the
  composites a texture viewer cannot. Deleted before committing, like a `test_zz_*` probe.
- **A `git worktree` for the before-and-after has one trap.** `.godot/` is gitignored, so a fresh
  worktree has no `class_name` registry and every typed line in the probe fails to parse — which
  looks like the probe being broken. Run `--headless --import` in it first. And delete the other
  suites in the throwaway worktree, or the comparison run costs six minutes of tests you are not
  reading.

## What to do next, in order — *superseded; see "Where to pick up" at the top of this file*

**This section is M37-era and is kept as history rather than as a queue.** The live order is the
pick-up block at the top: M52's calm shapes, then M53's junctions, then M54, then M50's leftovers.
Two lists of next steps in one file is how a to-do gets filed and not read, which this session paid
for four times — so if these two ever disagree, the top of the file wins and this heading is the one
to correct.

What is still worth reading here is the **playtest questions**, which are not stale: most of them
have still never been answered by a person, and they are the shape of question a rig cannot answer.

### First: play it, and look at the people

**M37 drew fourteen silhouettes and a contact sheet is the only thing that has looked at them.**
Five of the fourteen are reachable before day 4 and the rest have never been met by anybody, so
this is the cheapest playtest the project has had in a while: walk a day and see whether the street
tells you what is on it. What a rig cannot answer:

- **Can you tell the man shouting from the busker without walking up to them?** That is the whole
  claim. Playtest 09's *"who is the person killing me?"* is the question this milestone exists to
  answer, and the answer is now supposed to be *look at him*.
- **Do the robber's two postures read at an alley's length?** *(Day 8, so probably not this run.)*
  The waiting one has no face in the hood and the coming one is leaning out over a forward leg, and
  the entire point is that they are told apart **before** the 140px trigger rather than after it.
  Nothing else in the game asks a silhouette to carry a state change.
- **Does the protest read as a wall?** It is 55px of body where it was 11, drawn as two ranks of
  placards across exactly that width, and it sits on crossings and squares from day 12. If it reads
  as an obstacle course rather than as a crowd, that is the one gameplay number M37 moved.
- **And does anything now hide behind a building?** Buildings sort against nothing, which is a
  strictly larger claim than *the bug is fixed*. If a sprite ever looks like it is floating in front
  of a wall it should be behind, that is this change and not the art.

### Then: play it, and look at a street that is solid

**M34 has still been walked by a rig and by nobody's eyes**, and it is the milestone that changed
what an ordinary pavement *is*: about two thirds of the catalogue has a body, and day 1 went from
12.2 things that take a 64px footway to 17.2. The count of events placed did not move, so the
question is not density — it is whether a street that stops you reads as a route decision or as an
obstacle course. Three specific things to watch, because a rig cannot:

- **Does a blocked pavement read as a decision?** A van at the kerb takes the footway and the
  answer is meant to be *the other side of the street*, the same answer `construction` has asked
  for since M19. If it reads as "walk into the road", that is the density of blockers, not the
  bodies.
- **Does anything trap her?** She is 14px and a van is 22, so the gap between a van and the
  frontage is smaller than she is: she stops. That is intended and it is also exactly the shape of
  M19's *"no line to walk"* mistake, which took a rig walking a real pavement to see.
- **Does the lorry read as backing into the yard?** It is turned to face out of the frontage it is
  against, and about half its box end is behind the building's front wall. That used to be finding
  4 happening and reading *correctly* by accident; since M37 the lorry is simply in front of the
  wall, so it is worth a second look at whether it still reads as reversing into something.

### Then: the three left from playtest 07

Listed at the bottom of [PLAYTEST-07.md](PLAYTEST-07.md), and none of them is large: **1**, the cat
crossing perpendicular to her *heading*, which is a run down the middle of the carriageway when she
is crossing a road; **8**, a four-block calm zone rolling `QUIET_SQUARE` and becoming a 22-tile
concrete plaza with thirty trees on it; and **6**, a car turning swapping axes in one frame with no
diagonal art to turn through.

### Then: play it, and read the `idle` and `cue` entries

Nothing is queued ahead of a person playing. Six of playtest 06's own findings and playtest 05's
before them came out of somebody walking around for a few minutes, and M32 in particular is five
changes to *when things appear on screen*, judged by a rig and a trace and by nobody's eyes.
What to look for, in the order it would show up:

- **Does the mark still turn up after the fact?** Every `cue` line for the mark says how long it
  was up and how much of that she spent on the road. In a probe run they are 0.3–0.7s and *all*
  of it on the road. A span with a road figure well under its duration is this bug coming back.
- **Do the badges still flicker?** A `cue` pair with a fraction of a second between them is a
  flicker with a name on it now. The "gone" line says where the thing was when the badge went,
  which is the difference between the badge doing its job and the badge giving up mid-approach.
- **Does the pram read?** The four states have been screenshotted in every facing and never
  watched. The one to distrust is *not settling* (amber waves): it is the only one that can be
  up for a long stretch, and a cue that is up for a long stretch is how the rings started.
- **Is a retry the right length of punishment?** Three nerves are now three attempts. Whether
  that is too soft is a question only a run can answer.

### Then: M25, patrols and running that matters

The biggest thing outstanding, narrowed in M31 to **acts III and IV** by decision — *"patrol
shouldn't be there for act I"*. See the section below and `docs/TODO.md`.

### And the questions the fifth and sixth playtests still have not answered

Playtest 06 settled the big one — ***"I like the difficulty now"*** — which retires *"no balance
number has been felt by a human"* and means the next balance argument starts from "this is
roughly right". These are the ones it did not reach, and every one is now being asked of a
**much busier street** than the one that prompted it, so they are worth re-reading off a trace
before anything is tuned:

- **Do the seven new entities read as what they are** without the caret telling you? That is the
  one thing no test can see and the reason each got its own silhouette.
- **Is a four-block calm zone a route?** M21's whole claim, and the number behind it — 10.8s
  corner to corner against 23.8s for a full meter — is arithmetic, not a verdict. The trace
  entry that says it is `settled`: whether she walks a line through it or laps it anyway.
- **Is the arterial crossable?** Walking its length loses day 1 in fourteen seconds, which is
  intended; crossing it at a zebra should be routine, and since M29 the giving-way is finally
  legible from the kerb. `road` and `crowd` entries say which happened.
- **Do bumps read as the player's fault?** Eleven contacts down a lane centre against one on the
  midline. Whether a person finds that line is a different question from whether it exists.
- **Does anybody get run over, and does it feel fair?** A `lost` line preceded by a `crowd` horn
  line is a fair death; one with no horn before it is a bug in M19's work. M30 gives the horn a
  picture now, so the trace and the screen should agree.
- **Do the cues get read?** A `run` or `turn` following a badge is the evidence, and nothing in
  a test can see it. *(M32 closed the half of this that was a missing instrument: there is a
  `cue` entry now, so the log finally answers "what was she warned about". Whether she then did
  anything about it is still a question for a person's trace.)*

### What is left of M21

The calm-zone half is done. Two halves are not, and both are open by decision rather than by
oversight:

- **Main roads with lights against side roads with zebras** — playtest 02's finding 6, where a
  main road is crossed rather than walked. Decision 3 of that document said the way to get there
  is *"making walking it hostile, reusing finding 3's hazard mechanism, rather than by deleting
  its pavement"*, and **M19 and M27 did exactly that**: the carriageway is lethal, the traffic
  is dense, and walking the arterial's length loses day 1 in fourteen seconds. So what is
  actually left is the *lights* — a signalled junction, which is a mechanic (a window that opens
  and shuts) rather than a piece of scenery, and which nobody has asked for since.
- **The canal**, dropped out of M16 into M21 because it is the one feature that would **move a
  walkable tile**, and M21 was going to be where a lattice with holes was already paid for. It
  is paid for now — `absent_segments` and `is_street()` are the shape a bridge would use — so
  this is cheaper than it was, and still unasked-for.

### M17 — the route map, **backlogged**

*Not the next thing, by decision taken in this session: "in case you have it still in your notes
about showing a brief map at the start let's not do that for now — we might revisit later but
for now let's put it in the backlog."* Nothing below is withdrawn and the gap is real; it is
simply not what the game needs next. Kept here so that when it is picked up, the argument for
it is still assembled.

The planning screen, rendering the block states M15 introduced *and* the closures M16 adds.
`CityState.changed_on(block)` is already recorded for exactly this — shading "this is new" is
what makes the screen worth opening twice.

M16 raised the value of this: closures are legible at the junction and **not** before it. A
player two junctions away cannot know a street is shut, and the map is the only thing that
can tell them. That gap is stated as a gap in `docs/CITY.md` rather than papered over.

M23 raised it again, and gave it a test: the log's `closure` entries say where a barrier was
seen from, and a `turn` following one says whether it changed the plan. If closures read as
scenery in the traces, that is the argument for the map screen — and afterwards, the same two
entries are how to tell whether the map fixed it.

### Then the rest, per PLAYTEST-02.md

M18, M19, M22, M23, M24 and M27 done; M21 half done (see above); M17 backlogged.
**M20 traffic that behaves** is **parked, not queued**: M27 shipped the half that mattered
(cars follow and queue; zero overlapping pairs a frame, down from 5.2), and what is left —
overtaking, eight-way driving, a crash as a catalogue event — is unasked-for by any playtest.
**M25 patrols, and running that matters** is the biggest thing outstanding and its scope
**narrowed** in M31: a patrol was ruled out for act I by decision — *"patrol shouldn't be there
for act I"* — so this is now specifically the answer for **acts III and IV**, where the streets
are deliberately empty and the threat should follow rather than sit. The `run` entries are the
measurement it will be judged by and today they all say the same thing: running is the wrong
move against every event in the game, so a patrol needs a mechanic running *escapes* — something
that pursues, a lethal radius that grows, a window that shuts — and a fairness contract stated
over `RUN_SPEED` rather than `WALK_SPEED`. It also picks up playtest 03 finding 3, the walk home
being a formality: patrols that were not there on the way out are the return phase's own
pressure.
**M26 teaching the controls** — delete the interact key, then teach walking and running,
ending in a scripted day-1 event that requires a short run. M26 must come after M25 for
correctness, not scheduling: forcing a run before running is ever the right answer teaches a
move that is never correct again.

**M21 was expected to rewrite the lattice enumeration in `src/routes/street_network.gd` and it
did not have to.** The prediction was right about the consequence and wrong about the shape: the
graph half of that file — route counting, the invariant, the doorway exemptions — did survive
untouched, and route redundancy did stop being true by construction. But the enumeration
survived too. A street a calm zone absorbed is one the lattice still *lists* and this city does
not *have*, and every route search already took a set of streets to ignore, because M16 built one
for the closures. `CityMap.absent_segments` joins that set and nothing else changed. The one new
function on `StreetNetwork` is `around_blocks()`, because "the ways into this calm area" stopped
being derivable from a block coordinate the moment a calm area could be more than a block.

---

## Standing decisions

Taken in the M12a session and still governing everything after it. All four are recorded in
`PLAYTEST-01.md`; repeated here because they change the design.

1. **Assets are SVG.** Confirmed. Graphics get refined later — *"for now we need something
   workable"*, so do not gold-plate the art. Generating images or using freely-licensed
   assets is also acceptable.
2. **An ordinary street makes sleep progress, but never enough** to finish a day alone.
   A day must be unwinnable on street gain and comfortably winnable with one calm stretch.
3. **Finding 12 narrows the route choice, it does not remove it.** Not a single forced path
   — several viable routes and *several quiet destinations to choose between*. The day-level
   invariant to enforce in M16: at least two distinct routes to at least two distinct calm
   areas.
4. **The city is mutable day to day, by recontextualising areas.** *(Implemented in M15.)*
   The generator plans each block's *purpose arc* up front so blocks transition coherently.
   This **superseded the "`CityMap` is immutable for the run" invariant in `CLAUDE.md`** —
   replaced by: the street lattice and block boundaries are fixed; what a block *is* may
   change, only along its planned arc. Rendering reads block state, so `City.start_day()`
   repaints the ground and re-dresses the blocks every morning.

---

## Gotchas learned in M22

- **A threshold that sounds defensible can be the old mistake in a new shape.** "Mark anything
  louder than the walking decay" marked `poster_crew`, `barricade` and `burnt_shell` — the three
  rows the cost table already calls scenery, and a set the rings would have marked too. The rule
  that works is not about magnitude: mark danger that **changes over time**.
- **Deleting a thing does not delete the habit.** `tests/test_danger.gd` asserts `EventAuraLayer`
  cannot come back and that the whole catalogue is never marked at once, because the failure this
  standing decision exists to stop is somebody reaching for a ring the *next* time something
  needs signalling, and a comment in a deleted file cannot stop that.
- **An additive `warn()` beats a setter, and the reason is ordering.** The crowd and the events
  both look at the ground she is standing on in the same frame. With a setter, whichever ran
  second cleared what the first said — silently downgrading a lethal event to nothing because no
  car happened to be coming. `Stroller.warn()` raises the level and never lowers it.
- **Force a cue's condition on, look at it, and put it back.** The screen-edge badge needs
  something lethal off-screen and closing, which a six-second screenshot cannot be asked for.
  Forcing it found three defects no test could see: it collided with the excitement meter, the
  icon was squashed by a square box, and some badges had no silhouette at all. That last one is
  the point of the badge — an arrow that can only say "something" is an anxiety, not a warning.
- **`tools/shot.sh` was silently eating its own flags.** Every dev flag passed to it was dropped,
  so a screenshot taken to look at one specific event was of the doorstep, and nothing said so.
  It forwards them now and has `--walk`, which holds a direction down for the whole run —
  necessary since M27, because a screenshot of a standing player is a screenshot of almost
  nothing.
- **The suite count went down, and that is correct.** 15890 → **15744**: the aura-layer checks
  went with the layer. A drop in check count after a deletion is fine; a drop after anything else
  is a suite that stopped running.

## Gotchas learned in M27

- **A brake cannot open a gap that does not exist.** Two cars that start inside each other both
  choose zero speed and stay there. Separation between bodies is **positional** — now an
  invariant in `CLAUDE.md`, and the same shape as M19's player bump.
- **Recycling everybody onto the same pixel is a pile-up generator.** Re-entering agents placed
  on the exact edge coordinate produced eight overlapping pairs a frame on a road nobody could
  see, and once cars keep a headway the pile never sorts itself out. They enter in a band.
- **A lane has a capacity.** At the first density the arterial wanted 194px of spacing per car
  and had 118px of lane per car: it jammed solid and no controller helped. Car counts come from
  what a lane can carry.
- **A weight whose denominator changed is a trap.** `ARTERIAL_BUSYNESS` used to mean one
  street's share of sixteen corridors and now means its share of the three or four inside the
  field box, so the *same number* put half again as much traffic on the arterial — 0.6%
  crossable, 22s at the kerb. That is a wall, not a hazard. It went 5.5 → 5.0.
- **Code after an unconditional `return` never runs, and the tests are what find it.**
  `CrowdAgent`'s lateral recycle check was written after the along-axis one, so a player walking
  north left everybody on every east-west street she crossed behind forever, and the pavement in
  front of her would have drained over a minute of play.
- **A mobile event starts moving when its telegraph starts**, which is right for a fire engine —
  its telegraph *is* the approach — and was catastrophic for the cat: a one-street crossing at
  240px/s finished during its own 1.6s telegraph, so it never reached full intensity and
  `CAT_RUNNING` had never drawn a single frame in six milestones. A green suite, a passing
  fairness contract and a screenshot all had nothing to say about it.
- **Streaming has two floors on its radius and the larger wins.** Half the viewport diagonal, so
  nothing is seen to appear; and wider than the widest field in the catalogue, so an event is
  outside its own outer radius the moment it becomes visible. Without the second, streaming is a
  way of dropping events on people and the telegraph contract is a lie.
- **Rejected: making the arterial quieter to make it crossable.** It has to stay above the idle
  decay or standing still on the busiest street in the city becomes a strategy, which is the one
  thing the crowd exists to stop. The resolution is the zebra, which the generator puts at every
  junction.

## Gotchas learned in M19

- **A green suite and a screenshot both passed a collision that was catastrophically wrong.**
  A pedestrian slower than the player was pushed *further along their own line of travel*,
  which separates nobody at 92 against 60 — so she accumulated a wedge of pedestrians in front
  of her, all permanently in contact, all permanently startled, at 150 excitement per second.
  Nothing in the test suite could see it and the screenshot showed a normal street. Forty
  seconds of a scripted walk down a real pavement showed it immediately. A bumped body **steps
  aside** now.
- **The contact radius is set by the lane spacing, not by a body's width.** The only line with no
  contact on it is the midline between two lanes. At 18px there was no such line anywhere on a
  two-tile pavement: the same forty-second walk cost eleven bumps however carefully it was done,
  which is a toll rather than a decision. At 14px it costs two. That relationship is the assertion
  in `tests/test_crowd.gd`, not the number.
- **And the line has to be wide enough to aim at.** *(M46.)* With the lanes on their tile centres
  it was `32 − 2 × 14` = **four pixels**, which is a line a player is occasionally on rather than
  one she chooses — while forty seconds down an arterial lane centre cost 15.3 contacts and the
  midline cost none. `CrowdLanes.SIDEWALK_LANE_SPREAD` pushes the two lanes of a footway apart to
  make it 20px. Widen the **street**, never the body: `BUMP_RADIUS` is what makes a contact mean
  walking into somebody.
- **A contact has to startle once, not once per frame.** She walks faster than a pedestrian, so
  a person bumped from behind stays inside the radius for the better part of a second.
  `CrowdAgent.touching` is the hysteresis; without it one person cost what a crowd should.
- **The throwaway probe is the headless stand-in for playing a minute.** A
  `tests/test_zz_*.gd` that prints numbers and is deleted before committing found both of the
  above and set `budget_for()`. `CLAUDE.md` carries it next to the screenshot rule.
- **A budget is not a count, and the gap is about a third.** `_ensure_one_usable_park` strips
  whatever reaches the calmest block and `_ensure_the_city_is_still_walkable` drops
  obstructions that would seal the city, so a budget of 18 places 13 or 14 events. Density has
  to be measured from what a day *places*, over several seeds. Deriving it from the formula
  gets you a number that is a third too small and looks right.
- **`move_and_slide()` owns `velocity`.** Folding the collision deflection into it made
  `is_idle()` and `run_excess_ratio()` answer for the crowd rather than for the player;
  restoring `velocity` afterwards was worse, because it discards the slide's own correction
  and walking into a wall stops reading as idle. The deflection goes through its own
  `move_and_collide()`.
- **A cue over the player's head has to stay near the player's head.** At 68px the exclamation
  mark drifted far enough up the screen to read as belonging to whatever was standing behind
  her — which, for the one cue in the vocabulary that means *this is about you*, is the single
  thing it must not do. She is 46px tall; the mark sits at 54.
- **A dead comment survives a deleted feature and then lies about its neighbour.**
  `busy_road`'s doc comment outlived it by six milestones in `event_catalogue.gd`, ending up
  attached to `_dog_walker()` and describing arterial traffic noise. Deleted here.

## Gotchas learned in M23

- **`process_mode` is inherited, so one `PROCESS_MODE_ALWAYS` exempts a whole subtree.** Found
  by playtest 03, present since M6. `main.gd` sets it on itself so Esc quits while the summary
  has the tree paused; every descendant defaults to INHERIT, so the city, the player, the
  crowd, the events and the resistance director all inherited the exemption and
  `get_tree().paused = true` paused nothing for six milestones. The player kept walking behind
  the screen saying the day was over — and the **resistance deadline kept running out**, which
  could lose a run its good ending while somebody read a summary. Fixed with
  `main._pauses_with_the_game()`; a new node under `Main` needs that call and nothing warns
  you. Also in `CLAUDE.md`.
- **The format only gets tested by the first real question asked of it.** M23 shipped, and the
  first question put to it the next day — *did I walk down the road, and did a car go through
  me* — it could not answer. Road time was not recorded (only road entry, so walking a mile
  down the carriageway looked identical to crossing at each junction), and the crowd was
  invisible by design. Both are entries now. Reasoning about which fields would be useful is
  not a substitute for being asked something.
- **A stretch in progress when the day ends is never written down.** The `road` entry fired on
  *leaving* the road, so a player killed by the traffic they were walking among got no entry
  at all, having never left it. Anything accumulated over a span needs flushing at day end.
- **A green suite says nothing about whether a log is any good.** The observer passed every
  test and its first trace of a minute's actual walking had four defects in it: a `run` entry
  claiming a six-hundred-pixel event was "in reach", two instances of the same event that the
  log could not tell apart, a duplicated field, and — the bad one — a meter breakdown reading
  `crowd 0.0, events 0.0` while excitement climbed, because the player was doing it to
  themselves with the run button and nothing said so. This is the screenshot rule with a
  different output format, and it is now in `CLAUDE.md` next to it.
- **The breakdown has to add up or it lies by omission.** Printing the two spatial sources was
  true and useless. It prints the baby's whole incoming rate alongside them now, so whatever
  the remainder is — running, an alley — is visible as a remainder.
- **Hoisting a roll to print it is the dangerous edit.** `if rng.randf() > threshold` becoming
  `var roll := rng.randf()` is identical, and *nearly* the same edit that consumes an extra
  value and moves every event placed afterwards. `tests/test_telemetry.gd` plans all fourteen
  days twice, with the log off and on, and compares event ids and positions to the pixel.
- **Telemetry must be inert by default, not disabled by a flag.** The suite creates schedulers
  and city states directly; if the log were on by default it would write a file per check.
  `Telemetry` is dormant until `begin_run()`, which only `main.gd` calls — so the suite pays a
  boolean and the game gets a trace with no flag to remember. The observer is not even added
  to the tree when telemetry is off.
- **A roll that passes and then fails to place is invisible.** `_place_one_shots` can roll a
  one-shot in and then find nowhere to put it, in which case it is *not* consumed and gets
  rolled again tomorrow. From outside that is indistinguishable from a roll that failed, so it
  gets its own line.
- **`user://` is somewhere nobody can find.** On macOS it is inside `~/Library`, which Finder
  hides. The path is printed at the start of every run *and* `tools/telemetry.sh` exists, and
  it still took someone asking where the logs were. Neither was sufficient alone.
- **macOS ships bash 3.2, so no `mapfile`.** `tools/telemetry.sh` reads `ls -t` in a `while`
  loop instead, like the rest of `tools/`.

## Gotchas learned in M16

- **Check before accepting, not after placing.** The obvious shape for closures — place N,
  then drop them until the day is legal — has an order-dependent answer and a window in
  which the day is illegal. Testing each candidate against the invariant *before* accepting
  it costs the same and has neither problem. The reason it is affordable is the next point.
- **Counting distinct routes is a max flow, not a search for routes.** Two edge-disjoint
  paths is what "two distinct routes" means, and by Menger's theorem the count is also "how
  many streets it would take to cut this off". Two BFS augmentations over a 64-node junction
  graph — not a flood fill over ten thousand tiles — which is why it can run on every
  candidate closure of every day inside a test suite.
- **A doorway is not a route, and that has to be said out loud.** The first version of the
  brute-force cross-check closed every street in turn and asserted the area survived. It
  failed on three courtyards, correctly: a courtyard has one archway onto one street.
  Two routes has always meant two routes *to the door* — the same exemption the home has
  had since M3 — and the test now excludes access streets and carries a second test that
  states the consequence rather than leaving it implicit.
- **A cross-script enum is not the same type as itself.** `f(side: Side)` called from
  another script with a `StreetNetwork.Side` value fails to parse. Widen to `int`.
- **The crowd made the closure legible for free.** Agents divert at the junction rather than
  driving through a barrier, so the street with nobody on it is the street that is shut —
  which reads from a block away, further than the barrier does. That was a side effect of
  making the crowd respect closures, and it is better than the thing it fell out of.

## Gotchas learned in M18

- **Cutting the day tests the tests.** Every M14 balance claim is written as a relationship
  over `day_length()`, and halving the day is exactly the change those relationships exist
  to survive. They did: nothing needed its shape changed, and the one that pushed back —
  "a whole day of street walking still makes real progress" — pushed back correctly, which
  is why street gain went *up* while the day got shorter.
- **A shorter day is a faster suite.** `tests/test_balance.gd` steps a real `Baby` through
  fourteen days at 1/60s; it went from 94s to 27s for free.

## Gotchas learned in M15

- **A carved interior needs a way in.** Courtyards were sealed rects the first time and the
  connectivity check failed on *every seed*. The archway is now part of `BlockLayout`, and
  it is paved as an alley on purpose: reaching hidden calm costs a few seconds of somewhere
  you would rather not be.
- **Put arc invariants in the arc, not in the callers.** A commercial block could be planned
  to go dark on day 10 and then burn on day 3, because two independent rolls wrote their own
  `from_day`. `BlockPlan.then()` now clamps each step to at least the previous step's day.
  `tests/test_blocks.gd` found it on 13 of 24 seeds.
- **Protect the calm ground, not the block.** `_ensure_one_usable_park` matched events
  against the whole block lot. For a courtyard — four tiles inside a residential block —
  that stripped every event off streets the player was never going to settle on. It matches
  `BlockLayout.open_rect` now.
- **Calm ground must not read as a rooftop.** From above, the first quiet-square paving was
  the same warm beige as the building roofs. Since M14 finding calm ground is the whole
  game, so the tile is deliberately cooler than anything else in the palette. This will
  matter more in M17, where the map screen *is* the view.
- **`var x := SomeEnum.keys()[i]` will not parse.** The value is a Variant, and "inferred
  from a Variant value" is an error, not a warning. Annotate: `var x: String = ...`.

## Where the suite's time goes

Per-suite timings are printed by `tools/test.sh`, and `tools/test.sh crowd events` runs a subset in
seconds. Since **M44** the whole run is ~96s for 74540 checks. `test_balance.gd` and `test_crowd.gd`
are ~26s each, `test_generator.gd` ~16s and `test_events.gd` ~13s; everything else together is ~11s.
Those four are the suites that generate cities and play days, and that weight is the cost that buys
the bugs a data-level test cannot see.

It was **8.4 minutes** before M44, and the thing to remember about that is that four plausible
explanations were all wrong: it was a rig that stepped the crowd without the frame around it (an
unbounded `TrafficIndex`), a filtered tile list recomputed four hundred times a day, a
`Vector2i`-keyed dictionary used as a flood fill, and `CityGenerator.validate` sweeping the map
twice before its cheap rejections. See `docs/TODO.md`, M44. No check was cut to get there — the
count went up by one.

One thing deliberately not swapped in, and still true: `test_generator.gd`'s route-redundancy sweep
closes each street segment in turn on the *tile* grid, where `StreetNetwork.route_count()` would
answer the same question by max flow on the junction graph far faster. The tile-level sweep checks
something the graph cannot — that the tiles agree with the lattice — so it stays.

## Gotchas learned in M14

- **Pitch balance numbers against the day, not against each other.** The old numbers were
  all mutually consistent and the day was still winnable by circling the block, because
  nothing tied the fill rate to `day_length()`. The two tests that matter now are written
  as `GAIN * day_length(day) < METER_MAX` and `METER_MAX / calm_gain < day_length * 0.6`,
  so lengthening the day cannot quietly make the street sufficient again.
- **Arithmetic is necessary and not sufficient.** Whether a park fills the meter depends on
  whether the crowd pushes it over the freeze threshold, which no data-level test can see.
  `tests/test_balance.gd` stands a real `Baby` in a real city with that day's crowd and
  events. It is what caught that the claim needed checking on all fourteen days, not one.
- **Check the short day.** A calm stretch of 139s looked fine against the 330s day and was a
  stopwatch race against the 264s curfew one. Every balance claim here is measured against
  `day_length(RUN_LENGTH_DAYS)`.

## Gotchas learned in M13

- **A runtime error in a test suite hangs the runner; it does not fail it.** `run_tests.gd`
  calls each suite synchronously and quits at the end, so an error aborts `_ready()` before
  the quit and the headless process sits there printing nothing. Deleting `busy_road` left
  three suites calling `by_id("busy_road").intensity`, and the symptom was a test run that
  produced *no output at all* for six minutes. No output means an error, not a slow suite.
- **A negative-width `Rect2` normalises** — already in `CLAUDE.md` from M12c, and it bit
  again here: it is the same helper the whole crowd draws through.
- **Moving a `Node2D` does not invalidate its draw list.** The transform is applied when the
  retained list is replayed, so 530 agents only need `queue_redraw()` when their *picture*
  changes — a turn, a flip — not when they move. That is the difference between 530 redraws
  a frame and a handful.
- **Give each agent its own RNG.** Seeded per agent from the day, not shared, so a turn
  taken at a junction cannot depend on the order agents happen to reach junctions in — which
  frame timing would otherwise decide, and determinism would be a lie.

## Gotchas learned in M12c

- **A negative-width `Rect2` does not flip `draw_texture_rect`** — it is normalised, so the
  sprite lands a full width sideways. It reads as art sliding off its own shadow rather than
  as a failed flip, which is how it was found. `Sprites.draw_standing()` mirrors the
  transform around the anchor instead, and is the only place that does.
- **A sprite cannot swing its own legs.** The mother's gait was a procedural stride and a
  bob; with the legs drawn into the art, both had to become a two-frame swap. The bob is
  baked into the second frame rather than added on top, or the two would compound.
- **Deleting the colours was part of the job.** Two thirds of `Palette` no longer painted
  anything once the art moved into SVG, and a constant that looks authoritative but controls
  nothing is a trap for whoever tries to retint the game next. What stayed is what the code
  still picks at runtime: light, act cast, aura, chalk, shadow, building variant.

## Gotchas learned in M12b

- **Edge overlays beat corner tiles.** The roof parapet is four edge tiles drawn on top of
  the roof fill, each transparent apart from its own band. A corner cell takes two of them
  and the parapet turns by itself — no corner tiles, and no combinatorial explosion when a
  roof is only one tile deep and a row has to be both its north and its south edge.
- **Multiply the colour, not the art.** Wall and roof fills are authored near-white and
  passed the variant colour as `draw_texture`'s modulate, so six roof colours cost one
  asset. Windows are drawn *after*, unmodulated: a lit window is the same warm colour
  whatever the building is painted.

## Gotchas learned in M12a

Beyond the ones already in `CLAUDE.md`:

- **`Sprite2D` with `centered = false` puts the node at the sprite's top-left.** Y-sorting
  then compares the wrong edge. Everything in this project is feet-anchored: put the node on
  the ground plane and use `offset` to draw upward.
- **A y-sort tie is broken by tree order.** The front door sits in the wall of the building
  above it at exactly the same `y`, so it has to be added to the tree *after* the buildings.
- **A tile cannot carry a line that falls on its own edge.** The road centre line sits on the
  seam between the two carriageway tiles, so it is authored as two halves that meet
  (`road_line_e`/`_w`, `road_line_n`/`_s`).

## How the asset pipeline is put together

- `assets/tiles/*.svg` — 17 ground tiles, 32×32, hand-editable. **There is no regeneration
  script**; they were emitted once and are now the source of truth.
- `assets/ground_tileset.tres` — one `TileSetAtlasSource` per tile. **Source ids are
  positional and `src/city/ground_tiles.gd` mirrors them by hand.** Adding a tile means
  appending to both, in the same order.
- `src/city/ground_tiles.gd` — the only place that decides which tile a cell gets.
- `assets/buildings/*.svg` — 11 building tiles, 32×32. `wall`/`roof` are fills (modulated);
  `wall_edge_*`, `wall_base`, `roof_edge_*`, `window_*` are alpha overlays drawn on top at
  full colour. No `TileSet` here: `Building._draw()` assembles them per lot, which keeps one
  node per building and lets a lot pick its own colour.
- `assets/rig/`, `assets/props/`, `assets/events/` — feet-anchored sprites, drawn through
  `Sprites.draw_standing()`: the node sits on the ground plane, the art rises from it.
  Anything whose size carries meaning (a fire's flames, a barrier's width) passes an
  explicit size rather than using the texture's own.

Run `./tools/check.sh` after touching assets; it does the import pass that generates
`.import` files.

---

## Working agreement

From `CLAUDE.md`, which is the fuller version:

- Feature branch per milestone, `--no-ff` merge to `main` when green.
- Run `check.sh`, `test.sh`, and a `shot.sh` screenshot before committing anything visual.
  A green `check.sh` says nothing about whether the game looks right.
- Commit the docs in the same commit as the code.
- Update **this file** at the end of each work session.
