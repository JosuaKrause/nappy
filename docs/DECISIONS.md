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


---

## The milestone log, as it stood on 2026-09-01

The full `docs/TODO.md` before it was cut back to a queue. Kept verbatim: every completed
milestone entry, with its measurements, its rejected options and its reasoning. The live queue is
[TODO.md](TODO.md); this is where its entries came from and where a closed item goes.

# Nappy — TODO

Status legend: `[ ]` todo · `[~]` in progress · `[x]` done

Each milestone is one git branch, merged to `main` when green.

**Where things stand:** M0–M16, M18, M19, M22, M23 and M27 are done and merged, and the game has
now been played four times by a human. The first playtest produced thirteen findings, planned
as M11–M17 in **[docs/PLAYTEST-01.md](PLAYTEST-01.md)**; the second produced twelve, planned as
M18–M26 in **[docs/PLAYTEST-02.md](PLAYTEST-02.md)**; the third, in
**[docs/PLAYTEST-03.md](PLAYTEST-03.md)**, is the first read off a run log and reorders some
of what the second one planned rather than adding milestones; the fourth, in
**[docs/PLAYTEST-04.md](PLAYTEST-04.md)**, adds one milestone and puts two that were already
queued at the front of the queue. All four are live plans and should be read before picking
anything up.

Execution order is numeric, with several exceptions already taken. **M18 was pulled ahead of
M16**, because closure counts tuned against a day that was about to halve would have been
tuned wrong. **M23 was pulled ahead of M17**, because it is the gate on M19's balance half and
on M24. **M27 was taken out of order and immediately**, because playtest 04's emphasised
finding — *"don't load everything upfront"* — turned out to be what was underneath three of the
other six, and because M21 and M22 both get judged against a street that now has traffic on it.

**Playtest 05 has landed and all six of its findings are done** — M28, M29, M30, M24 and M31.
Six findings in **[docs/PLAYTEST-05.md](PLAYTEST-05.md)**: two
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
**[docs/PLAYTEST-06.md](PLAYTEST-06.md)**, the first playtest ever taken on M28–M31: **the
difficulty is now right** — the first balance number in this game ever confirmed by a human —
plus two cues whose *condition was not the thing they claimed to mean*, a lost day that should be
**retried rather than skipped**, and the vocabulary asked for in the other direction: something
at the pram that says how the **baby** is. The one sentence to carry out of it is that M30
narrowed *which* things a cue is raised for and never looked at **when**: a cue is a claim about
a moment, and nothing in `tests/test_danger.gd` can see a moment.

**Playtest 07 has landed and M33 is its first half.** Nineteen things in
**[docs/PLAYTEST-07.md](PLAYTEST-07.md)**, reported as a running commentary rather than as a list,
and the one sentence under them is that **every cost in the game is paid on contact and almost
nothing else in it is real**. Nine are done; ten are queued behind them and listed there.

**Playtest 08 has landed and all five of its things are done (M35).** In
**[docs/PLAYTEST-08.md](PLAYTEST-08.md)**, taken on M34, and the run it came from ended on **day 3**
— the shortest any playtest has produced. Three of the five are one sentence, and it is playtest
07's own surviving a milestone meant to answer it: *a thing exists, and being near it changes
nothing.* The park spoiler denied three percent of a park, the pigeons were over before she arrived,
and the things that move stopped existing in front of her instead of going anywhere. The fourth is
the day-3 running lesson, which killed the run twice and whose fairness contract **passed every line
of itself while it was doing it** — because the contract was stated in speeds and durations and a
pursuit is played out in distances. The fifth is a number: five nerves.

**Playtest 09 has landed and all four of its things are done (M36).** In
**[docs/PLAYTEST-09.md](PLAYTEST-09.md)**, four sentences reported mid-session, and the one under
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
**[docs/PLAYTEST-10.md](PLAYTEST-10.md)**, off a session of five runs in which **no day was won**.
The sentence under them is that *the danger marks and the danger have come apart*: three of the
fourteen are one finding — a fire engine carries no caret and a burning building does — and the rule
underneath is M22's, which asks whether a danger *changes over time* and never asked how bad it is.
Under two more is the other one: **a retried day is not the same day**, which `docs/TODO.md` has
claimed since M32 and five seeds out of five disprove. And a thing nobody reported is in every
losing line of the trace — the crowd is supplying nearly all of the excitement that ends a day,
which is playtest 07's finding 17 arriving again after the milestone that answered it. That is
**the milestone after M39**, measured rather than argued.

**Playtest 11 has landed and is M41, M42 and M43.** Nine findings plus a design for the edge of
the map, in **[docs/PLAYTEST-11.md](PLAYTEST-11.md)**. The sentence under it: *several things in this
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
**[docs/PLAYTEST-12.md](PLAYTEST-12.md)**, taken on the branch while it was half-built, and the
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
**[docs/PLAYTEST-13.md](PLAYTEST-13.md)**, off one run that ended on day 4 with a bad ending, and
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

**What M27 leaves open.** Nobody has played it. The densities in `docs/PLAYTEST-04.md` came off
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
**[docs/PLAYTEST-15.md](PLAYTEST-15.md)** plus a re-report that belongs to playtest 14's finding 7.
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

---

## M0 — Project setup · `feature/project-setup`

- [x] Git repo, `.gitignore`
- [x] Design docs (DESIGN, MECHANICS, CITY, EVENTS, NARRATIVE, ARCHITECTURE)
- [x] `project.godot` with input map (arrows/WASD, shift, E, Esc)
- [x] Placeholder icon
- [x] `Tuning`, `EventBus`, `GameState` autoload stubs

## M1 — Movement & camera · `feature/core-movement`

- [x] `stroller.tscn` CharacterBody2D, walk/run, acceleration & friction
- [x] Procedural 2.5D drawing of mother + stroller, feet-anchored
- [x] Facing direction, stroller leads in the direction of travel
- [x] `Camera2D` follow with smoothing + movement look-ahead
- [x] Debug scene: 3x3 street grid matching the constants M3's generator will use
- [x] Y-sorting verified (player draws over a wall she is standing in front of)
- [x] `tools/shot.sh` — render a frame to PNG, since a headless boot never calls `_draw()`

### Deferred out of M1

- [ ] The pram has no collision of its own — only the mother's feet do, so the pram clips
      into walls when she hugs a corner. Options: a second body that trails her, or a
      capsule that rotates with `facing`. Not worth solving before the city exists.
- [x] Buildings taller than their lot depth would have no roof left to draw; `roof_depth()`
      clamps rather than warns. *(M12b: heights are whole tiles now, and the clamp is exact
      — the wall never takes the last row.)*

## M2 — Baby meters · `feature/baby-meters`

- [x] `baby.gd`: sleepiness + excitement, all rates from `Tuning`
- [x] Baby state machine AWAKE / ASLEEP / CRYING
- [x] Calm-threshold freeze rule
- [x] Running → excitement, idle → sleepiness drain
- [x] Wake-up rule + sleepiness penalty
- [x] `WorldContext` — the only three questions the baby may ask the world
- [x] `hud.tscn`: two meter bars with threshold markers, state + "not settling" hint,
      run header with nerves
- [x] Debug overlay: live incoming/decay/net breakdown
- [x] `tests/` harness + `tests/test_meters.gd` (57 checks)
- [ ] Day clock in the HUD — deferred to M6, which introduces the timer

### Deferred out of M2

- [ ] The HUD shows raw numbers. docs/TODO.md open questions asks whether a diegetic-only
      mode (baby face, no bars) should ship alongside. Revisit after M6 playtesting.

## M3 — City generation · `feature/city-generation`

- [x] `tile.gd` TileType metadata (walkable / calm / alley / road / colour)
- [x] `city_map.gd`: tile grid, layout maths, BFS distances
- [x] `city_generator.gd`: street grid, districts, alleys, plazas, parks, home
- [x] Carving as rect subtraction, so holes compose without special cases
- [x] Connectivity flood-fill + retry on failure
- [x] Generation guarantees (park count, spread, home distance, exact building coverage)
- [x] `city.gd`: procedural 2.5D buildings, ground, kerbs, crossings, park props
- [x] Building collision bodies + a boundary wall around the map
- [x] Calm zone + alley effects wired through `WorldContext` into `baby.gd`
- [x] `tests/test_generator.gd` over 200 seeds, plus a route-redundancy sweep
- [x] Dev flags: `--seed`, `--overview`, `--spawn park|alley|square|playground`

### Deferred out of M3

- [ ] Park trees are placed by rejection sampling and clump. Poisson-disc or a simple
      minimum-spacing check would spread them without much work.
- [ ] Districts affect building height and alley chance but nothing else yet. `INDUSTRIAL`
      and `CIVIC` should read differently at a glance before Act II makes them narrative.
- [ ] The generator is deterministic per seed but `generate()` retries with `seed + 1`,
      so a run's city is not strictly `run_seed` — it is the first nearby seed that passes.
      Fine, but worth remembering when reproducing a bug from a seed.

## M4 — Event system · `feature/event-system`

- [x] `event_def.gd` + `event_catalogue.gd` (defined in code, not `.tres`)
- [x] `event_instance.gd`: lifetime, telegraph phase, pulse envelope, path following,
      falloff contribution, hard-fail gating
- [x] `event_manager.gd`: live instances, retirement, `total_excitement_at`
- [x] `Tuning.validate_event()` asserted over the whole catalogue in a test
- [x] Telegraph visuals: `event_aura_layer.gd` under the entities, amber-and-flashing while
      telegraphing, red once active, tracking the pulse so the field breathes
- [x] `event_scheduler.gd`: budget, weights, one-shot spreading and consumption, determinism
- [x] "Always one usable calm zone" rule
- [x] `tests/test_events.gd` (149 checks)
- [x] Dev flags: `--day N`, `--spawn event`; `tools/shot.sh` now waits in seconds
- [~] Three representative events only (ambient / mobile burst / stationary pulse).
      M5 fills in the rest of Act I.
- [ ] Audio cues — no audio in the project yet; lands in M10

### Decisions taken during M4

- **No spatial hash.** The budget topped out near 22 concurrent events; a linear scan is
  free and a hash would be more code with more ways to be wrong. *(M19's density pass took
  that to ~25, and the decision is unchanged — the crowd has been doing 530 linear distance
  checks a frame since M13 and is not the bottleneck either.)*
- **No `impulse` field.** A sharp spike is a short `duration` at high `intensity`, which
  keeps the whole excitement model a pure query with nothing pushed at the baby.
- **Ambient events are exempt from the telegraph contract.** They never "appear", so there
  is nothing to warn about; the player learns them on day 1 of a fixed city.

## M5 — Act I events · `feature/events-act1`

- [x] `playground` (ambient), `busy_road` (ambient, sampled along two arterials)
- [x] `cat_dash` — the tutorial obstacle
- [x] `dog_walker` (mobile, slower than walking), `delivery_van`
- [x] `homeless_yeller` with pulsing intensity envelope
- [x] `busker`, `construction` (emits **and** physically blocks)
- [x] `fire_truck` one-shot: mobile siren that leaves a `burning_building` behind it
- [x] Supporting features: `PathMode` (cross-street / along-street), `obstructs_radius`,
      `spawns_on_finish`, `AmbientSource.MAIN_ROAD`, fire rendering
- [x] Fairness contract strengthened: an event faster than walking must be clearable
      across its **whole** radius, not just its falloff band
- [x] `tests/test_event_manager.gd` — integration against a real generated city
- [x] Dev flag: `--follow <event id>`, `--spawn event:<id>`

### Deferred out of M5

- [ ] The `burning_building` spawns exactly where the engine stopped, which is in the road
      rather than in a building. Nudging it to the nearest `BUILDING` tile would read much
      better and is a few lines.
- [x] `busy_road` is 14 separate instances. Fine for a linear scan, but a single
      polyline-shaped source would be tidier and cheaper. *(M13: retired entirely — the
      crowd is the arterial noise now.)*
- [ ] No audio, so every "you hear it coming" telegraph is currently visual only (M10).

## M6 — Day loop · `feature/day-loop`

- [x] Home tile: start, and return-with-sleeping-baby goal
- [x] Return phase after sleepiness hits 100, and reverting to walking if she is woken
- [x] Day timer, HUD clock, and dusk as a `CanvasModulate` over the city canvas
- [x] Win, cry-loss, timeout-loss, hard-fail-loss — each with its own text
- [x] Nerves, run end at 0, ending selection
- [x] `day_summary.tscn` between days, and the ending screen
- [x] Run state persists across days in memory; the city is built once and reused
- [x] `tests/test_day_loop.gd` (35 checks) — phases, all four outcomes, nerves, endings
- [x] Dev flag: `--day-length N`
- [ ] Save/continue a run to disk — M10

### Notes

- The tree is **paused** while the summary is up, so a day restart is just
  `events.start_day()` + reposition + `baby.reset()`; the city is never rebuilt.
- A day ends exactly once. `_end()` is a no-op after the first call, so a cry arriving on
  the same frame as dusk cannot spend two nerves — there is a test for it.
- The summary is reached from the timeout path in dev by `--day-length 10`. Winning needs
  the player to actually walk, so it is covered by tests rather than by a screenshot.

## M7 — Acts II–IV · `feature/acts`

- [x] Per-act colour cast, multiplied into the daylight
- [x] Act II: `police_patrol`, `poster_crew`, `loudspeaker`, `curfew_announce`, `checkpoint`
- [x] Act III: `quiet_road`, `abduction` (hard fail), `alley_robbery` (hard fail), `night_raid`
- [x] Act IV: `military_convoy` (leaves a barricade), `barricade`, `protest`, `firefight`
- [x] Persistent world scars — `scar_id` + `GameState.scars`; the burnt-out shell from
      day 3 is on the same corner on day 12
- [x] Street closures as obstructing events, revalidated so a park stays reachable
- [x] New mechanics: `city_wide` (no falloff), `intensity_ramp` (a protest swells),
      `scar_id`
- [x] `tests/test_acts.gd` — act gating, city-wide
      sources, protest growth, scar persistence, walkability under closures
- [ ] Per-act ambient audio bed — no audio in the project yet (M10)

### Notes

- ~~`busy_road` has `last_day = 7` and `quiet_road` `first_day = 8`~~ — both retired in
  M13. The handover they encoded is now `Tuning.CROWD_*_PER_ACT`, and the thing that would
  have silently doubled the noise on the main roads was keeping them *alongside* the crowd.
- `alley_robbery` is not exempt from the fairness contract — its radius is small enough
  (22/42px) that half a second satisfies it. The honest framing is that the alley is the
  warning.
- Passing an untyped `Array` into a parameter typed `Array[T]` leaks the arguments at
  shutdown ("N ObjectDB instances were leaked"). `tests/test_acts.gd` carries a note.

## M8 — Resistance subquest · `feature/resistance`

- [x] Chalk marks, drawn under everything that stands on them. No marker, no quest log.
- [x] Hold-to-interact with decay when you let go or walk away
- [x] All 6 steps, as a data table
- [x] Robbery-vs-contact alley roulette, seeded from run seed + day
- [x] Seen-by-patrol resets the hold *(changed from the planned progress penalty — see
      docs/NARRATIVE.md for why)*
- [x] Timed step failure (contact lost permanently for the run)
- [x] Resistance tally in the day summary; one terse HUD line otherwise
- [x] The good ending needs the goal **and** the day-14 sabotage
- [x] `tests/test_resistance.gd` (66 checks)
- [x] Dev flag: `--spawn contact`

### Notes

- `GameState.day_rng()` takes a `stream` now. Without it the events and the resistance
  would both start from the same day seed and their first rolls would move together.
- Building the step table with `set(key, value)` from a Dictionary silently DROPPED every
  `Array[int]` placement list — `set()` does not report a type mismatch — so three of the
  six steps had nowhere to go, with no error anywhere. It is an explicit factory now.

## M9 — Endings · `feature/endings`

- [x] Bad ending (nerves 0)
- [x] Neutral ending (day 14, sabotage not done)
- [x] Good ending (goal reached **and** day-14 sabotage completed)
- [x] Epilogue screens
- [x] The good ending's mechanical reward: **silence**. Completing the day-14 sabotage
      retires every city-wide source, so the last walk home is made without the floor the
      masts have held under the meter since day 5 — the easiest conditions in the game,
      and the only moment the HUD says anything out loud.

## M11–M17 — Playtest 01

See **[docs/PLAYTEST-01.md](PLAYTEST-01.md)** for the findings, the analysis and the
sequencing. Summary only here:

- [x] **M11 Playtest fixes** — home arrow, three graphics glitches, day-start position,
      spoiler-free README
- [x] **M12 Asset pipeline** — real asset files and tiles instead of `_draw()`. Gates M13,
      M15, M16, M17, so it goes first
  - [x] **M12a** ground: `assets/tiles/*.svg` + a `TileSet` + a `TileMapLayer`
  - [x] **M12b** buildings: `assets/buildings/*.svg`, assembled per lot; heights quantised
        to whole tiles
  - [x] **M12c** the rig, props and events: `assets/rig/`, `assets/props/`,
        `assets/events/`, plus `Sprites` for the feet-anchored draw rule
- [x] **M13 Density and life** — pedestrians and traffic as real agents; the crowd becomes
      the noise floor. `busy_road` / `quiet_road` retired: the arterial is loud because
      there are cars on it, and act III's empty city is empty pavement rather than a
      smaller number
- [x] **M14 Balance** — a day cannot be won without reaching calm ground. Street gain
      0.24/s (79 of 100 over a whole day), calm 3.5x, idle drain 0.6/s. Asserted against
      `day_length()` in `tests/test_meters.gd` and against a real city in
      `tests/test_balance.gd`
- [x] **M15 Block purposes** — four calm purposes (park, forest, quiet square, courtyard),
      three degraded ones (requisitioned, boarded up, burnt out), per-block arcs planned at
      generation, and the run-scoped `CityState`. Supersedes the "CityMap is immutable"
      invariant with "the lattice is fixed; what a block *is* is not", and keeps the half
      that is absolute: no purpose change moves a walkable tile
- [x] **M16 Route pressure** — a per-day pruned network with legible blockers, leaving at
      least two distinct routes to at least two distinct calm areas. Five kinds of closure,
      sealed at both mouths so a shut street is readable from the junction; the invariant
      checked by unit-capacity max flow on the junction graph before each closure is
      accepted. Canal dropped to M21. *(The invariant was weakened on 2026-08-31 to two calm
      areas still **reachable** — the two-routes half was never a hard rule. The max flow and
      the check-before-accepting are unchanged; see M50 and `docs/CITY.md`, "The invariant".)*
- [~] **M17 Route map** — the planning screen, rendering M15's block states. **Backlogged, by
      decision, at the end of the M29 session**: *"in case you have it still in your notes about
      showing a brief map at the start let's not do that for now — we might revisit later but
      for now let's put it in the backlog."* Nothing about the analysis below is withdrawn and
      the gap it closes is real — a player two junctions away still cannot know a street is
      shut, and `docs/CITY.md` states that as a gap rather than papering over it. It is simply
      not what the game needs next. M21 and the playtest-05 findings come first

## M18–M26 — Playtest 02

See **[docs/PLAYTEST-02.md](PLAYTEST-02.md)** for the findings and the reasoning. Six
findings from the second human playtest, queued behind M16 and M17. Summary only here:

- [x] **M18 The park has to be worth it** — finding 1. Calm ground fills the meter in 24s
      instead of 119s (10x the street, not 3.5x), and the day itself is 180s instead of 330s
      — aimed at a minute of play with a grace of three. Pulled ahead of M16, because
      closures tuned against a day that was about to halve would have been tuned wrong
- [x] **M19 Bodies on the street** — findings 2 and 3, **plus playtest 03 finding 1**.
      Pedestrians and the player collide and displace each other; a car strike is a hard fail
      with its own stated fairness contract (`Tuning.validate_traffic`); traffic gives way at a
      zebra somebody is waiting at; `cafe_tables` blocks a pavement from day 1 and `dog_walker`
      was re-pitched from −0.1 points to +21.6, so it owns the pavement instead of rewarding a
      player for ploughing into it. The collision bump is a short-lived *source on the person
      she walked into*, never a write to `Baby.excitement`.
      **Carried the event-density pass**: day 1 goes from 4 non-ambient events across
      forty-nine blocks to 13, day 14 from 22 to 25, with the number **measured** from what a
      day places rather than derived from the budget — a third of the budget is spent on events
      the day then throws away. See docs/MECHANICS.md, "The street has physics".
      **Two things were pulled in and one was left out**, all three deliberately:
      the exclamation mark over the player came forward from M22, because a lethal car has no
      telegraph phase to ring and it is the cue that makes the contract an instruction; the
      cost table in docs/EVENTS.md was regenerated and is now asserted by a test; and the
      *balance* half is still open, because setting it needs a human playing, which is what
      decision 11 says and what M23 exists for
- [~] **M20 Traffic that behaves** — finding 4. Cars follow, slow and overtake instead of
      driving through each other; 8-direction driving so they can turn; an overtake into
      oncoming traffic crashes, and the crash is a catalogue event with a real telegraph.
      **The half that mattered shipped in M27**: playtest 04 said *"cars still bump into each
      other"* and it is now measurably false — a minute of act I traffic has zero frames with
      one car inside another, down from 5.2 overlapping pairs per frame. What remains is
      overtaking, eight-way driving and the crash event — **asked for by name in this very
      finding**, and **parked with the player's agreement** on 2026-08-31: *"yes, I asked for cars
      overtaking each other and car crashes — not something we need to implement right now but
      something to discuss at a later time."* So it is parked as a **conversation that is owed**,
      not as a thing nobody wanted. The status line said *"none of which any playtest has asked
      for"* for twenty-odd milestones, which is how a parked request becomes an abandoned one
- [~] **M21 The city overhaul** — findings 5 and 6, plus the canal dropped out of M16, **plus
      playtest 03 finding 2**. Calm zones of four blocks, so the lattice grows T-junctions and
      can no longer be derived from a coordinate; main roads with traffic lights against side
      roads with zebras, where a main road is crossed rather than walked.
      **Raised above M20**: the four-block calm zone is the structural answer to twenty seconds
      of walking in a circle. That circling is not a length problem — progress requires motion
      and a calm block is a few tiles across, which is jointly sufficient for a lap, which is
      why M18's shorter stretch did not remove it and no further balance pass will.
      **The calm-zone half is done**: one or two 2×2 zones per city, 22 tiles square,
      crossed corner to corner in 10.8s against a full meter's 23.8 — so a stretch of calm is two
      or three traverses of somewhere with sides to it rather than six laps of a lawn. The
      lattice has holes in it, four T-junctions round each zone and a junction in the middle that
      nothing reaches, and **route redundancy stopped being true by construction** and is checked
      by search. Measured against `main` over 24 seeds and four walks each: placed per day 40.1
      → 40.1, live around her 4.87 → 4.79, on screen 2.74 → 2.75, met on a 40s walk 2.91 → 2.85,
      so playtest 06's *"I like the difficulty now"* survives it.
      **Two halves are not done and are deliberately left**: *main roads with lights against side
      roads with zebras* (finding 6), which decision 3 has largely been answered another way —
      *"a main road is crossed, not walked"* is enforced by M19's lethal carriageway and M27's
      density, and walking the arterial's length loses day 1 in fourteen seconds — and the
      **canal**, which is still the one feature that would move a walkable tile. Neither is
      blocking anything; both want a playtest of the zones first
- [x] **M22 Danger you can read** — findings 7 and 8. **Delete the aura circles.** How
      dangerous a thing is becomes visible from the thing itself; the rest is a small symbol
      vocabulary — above an entity when it needs one, at the screen edge when it is
      off-screen and closing, and above the *player*: **a flashing exclamation mark when they
      are standing in a soon-to-be danger zone** ("this spot is about to be bad, move"), plus
      a "too close" cue for danger already on them. The exclamation mark is the cue that
      turns the telegraph contract from information into instruction. Absorbs the "screen-edge indicator for fast movers" item from M10
      below. **The exclamation mark shipped early, in M19**, for the reason this entry gave:
      a lethal car arriving from off-screen is a breach of the telegraph fairness contract, not
      a polish item, and it has no telegraph phase to ring.
      **Done, after playtest 04 asked for it a second time** (*"I still see circles"*). The
      rings are deleted; `EventAuraLayer` no longer exists and a test asserts it cannot come
      back. What replaced it: a **caret over the entity**, shown for danger that *changes over
      time* and nothing else — lethal, telegraphing, pulsing, swelling — because a cue that
      marks a notice board as hard as an abduction is what the rings were; a **badge at the
      screen edge** carrying the thing's own silhouette, for anything lethal or faster than a
      walk that is off-screen and closing, which closes the `fire_truck` gap the ring could
      never cover; the exclamation mark over the player generalised to events and given its
      **second level** for danger already on her; and a **HUD line** for `city_wide` sources,
      which had no on-screen presence at all and were the most misleading thing in the game.
      The one thing the ring did well survives: the caret *breathes* with current emission, so
      a pulsing event is still something to time a pass through
- [x] **M23 Telemetry** — finding 10. A chronological plain-text log per run, in
      `user://telemetry/` and readable with `./tools/telemetry.sh`. Records what the code
      cannot recompute — the random outcomes that branch a run, the seed the generator
      actually settled on, the commit it ran on, what the player did, what came near them,
      and how each day ended. Full format and the entry table in
      [docs/TELEMETRY.md](TELEMETRY.md). **The gate is now open**: M19's balance half and M24
      both have their data source. On by default; `--no-telemetry` turns it off
- [x] **M24 The city remembers where you went** — finding 11, and playtest 05 asked for it
      again by name. Done: see the M28+ section below
- [ ] **M25 Patrols, and running that matters** — findings 9 and 12, **plus playtest 03
      finding 3**: the walk home is a formality — 26s, five crossings, zero encounters, 42% of
      the day left over. Patrols that were not there on the way out are the shape of the
      return phase's own pressure, which is why it is filed here rather than as a milestone.
      Patrols to put pressure
      back into the streets acts III and IV deliberately emptied, built around **encounter
      cost** rather than ambient emission. The prerequisite is structural: running is
      currently the wrong move against *every* event in the catalogue, so a patrol needs a
      mechanic running escapes (something that pursues, a lethal radius that grows, a window
      that shuts) and a fairness contract stated over `RUN_SPEED` rather than `WALK_SPEED`
- [ ] **M26 Teaching the controls, and one less control to teach** — two halves.
      **Delete the interact key:** `E` appears in exactly one line of the game
      (`contact_point.gd`), so the resistance hold becomes automatic on proximity. Nothing is
      lost — the cost was always standing still in an alley while a patrol might pass, not
      the keypress — and a player who wanders down an alley now discovers the difficulty dial
      by walking near it.

      **This half is M55's, and it stood unbuilt for twenty milestones because nobody read it
      back.** *(2026-09-01: "why are you still talking about holding E? we removed E early on in
      the development.")* The gate was M25, M25's own gate was a mechanic where running is the
      right answer, and that shipped in **M33** — after which this simply was not picked up, and a
      session designing the resistance in M55 read `contact_point.gd`, found the key, and reported
      it to the player as though it were the current design. Tick it from M55, which goes **further
      than this asked**: not automatic-on-proximity but instant-on-touch, so the hold goes as well
      as the key. **Teach the two that remain:** arrows/WASD at the start of day 1,
      then shift, then a scripted day-1-only event that requires a short run after the first
      block. **Comes after M25, for correctness not scheduling**: forcing a run before running
      is ever the right answer teaches a move that is never correct again

## M27 — Playtest 04

See **[docs/PLAYTEST-04.md](PLAYTEST-04.md)** for the seven findings, the measurements and the
reasoning. Two of the seven were milestones already queued (M22, M21) and are unchanged; one
was the summary of the rest. The other four are one milestone:

- [x] **M27 The world near you** — findings 1, 4, 5 and 6, and the emphasised one is finding 5:
      *"don't load everything upfront — only load / spawn things in the surrounding few blocks
      of the player when needed; consistency is not that important, nobody can run after cars
      anyway to confirm they are still there off screen."* It reads as a performance note and
      is not one — the game was already at 120fps with 530 agents. It is that **the population
      was being spent on the 99.2% of the city nobody is looking at**, which is why 110 cars
      read as a street you could ignore.
  - [x] **The crowd is a field.** A `CROWD_FIELD_RADIUS` box that travels with the player;
        agents recycle into a band outside the edge they will come back in through, and the
        `Tuning` populations became populations of the field. Measured, not converted: the
        table in PLAYTEST-04 is the record, and the two numbers that decide it are how often
        there is a gap to cross the arterial (one time in twenty, at act I) and the ratio
        between walking a lane centre and holding the midline (eleven contacts against one)
  - [x] **Events stream.** The day is still planned across the whole city — every guarantee is
        a property of the plan — and a plan becomes a node when the player is within
        `EVENT_STREAM_RADIUS`. Picks up playtest 03's finding 1 from the other side: a
        twenty-second event planted across the city at dawn is over before anybody could reach
        it, and that day's trace had **zero** `near` entries. An event that waits is an event
        she meets
  - [x] **The cat happens to you.** `EventDef.SpawnMode.AHEAD_OF_PLAYER` and `EventDirector`:
        the day budgets it at the usual cost and the director sites it across her line while
        she walks. Also fixed the six-milestone-old bug underneath the complaint — a mobile
        event starts moving when its telegraph does, so the cat finished its whole crossing
        *during* the crouch and the running sprite had never drawn
  - [x] **Traffic queues.** `CAR_HEADWAY_TIME` and `CAR_GAP_MIN`, and the separation is
        positional rather than a brake, because a brake cannot open a gap that does not exist.
        Takes the useful half of M20 with it
  - [ ] **Nobody has played it.** The whole thing is measured off a probe

## M28+ — Playtest 05

See **[docs/PLAYTEST-05.md](PLAYTEST-05.md)** for the six findings. One is done:

- [x] **M28 One event per block** — finding 6, taken first because the handoff named it and
      because it is a number rather than an argument: *"I want one event per block. The dog
      walker decision should happen meaningfully — I want to have to make that decision at least
      twice on day one. Also the same with a restaurant — I never saw one."* Day 1 goes from 13
      placed to **50 across 49 blocks**, from 1.8 live around her to ~11, and from ~1 on screen
      to **3.3**. **The caps moved first and the budget followed**: the day-1 pool's `max_per_day`
      values summed to 18, so no budget alone could ever have reached 49 — three dog walkers
      became twenty and three cafés eighteen. Repeats being fine meant no new catalogue rows.
      The rest of that measurement, over five seeds at 7×7, since `docs/EVENTS.md` no longer
      carries the before-and-after table: placed on day 14 **25 → 97**; on screen at once while
      walking **~1 → 3.3**, and 6.9 on day 14; met on a short errand out and back **1.0 → 2.0**,
      of which 0.8 were dog walkers; café tables seen on that errand **~0.2 → 3.2**.
      Two rules had to be invented to replace what the caps were quietly doing: a **spacing rule**
      at placement (`EVENT_SPACING_SAME` between two of a kind, `EVENT_SPACING_ANY` between any
      two), and **nothing else happens inside a lethal event's field**, which is playtest 05's
      "the contract composes badly when fields overlap" turned into something enforceable.
      It also caught a test that had been asserting more than the design promised since M15
- [x] **M29 Which side of the road** — findings 1 and 2, taken together because they are both
      `src/crowd/` and neither touches the meter. **Finding 2 was exactly as derived**: the
      driving convention was stated over the lane *offset*, and the side of the road that lands
      on flips with the axis, so the city drove on the right east-west and on the left
      north-south. `road_direction()` takes the axis now and has an inverse, `road_lane()`, and
      the test nobody had written asserts the real rule — for both axes and both directions,
      the lane a car is in is the one on its own right, checked against every live car in a real
      day. **Finding 1** is a car giving way *at a place*: it brakes toward a stop line a
      setback before the paint, on a gentle approach rate that keeps the easing visible from the
      kerb, and commits to clearing the crossing if it is already too close to stop. Two bugs
      turned up on the way that no analysis predicted — shaping the approach with `CAR_BRAKE`
      makes the onset of braking and the commit point the same instant so no car ever stops, and
      the crossing scan sampled world points every 32px, which aliases exactly when a car is
      stopped at the line, so it lost sight of the zebra and pulled away with somebody on it.
      Also fixed a rig bug that had been silently spoiling the give-way test since M27: the
      crowd is a field around the player and the rig has no player, so two of the three cars it
      measured were recycled on the first frame
- [x] **M30 The mark means one thing** — finding 3, settled the way the write-up said it had to
      be settled: as a **design decision**, not a threshold. The mark means *this will end your
      day*, so only a `hard_fail` event and a closing car raise it; everything else is left to
      the meter, which already says it continuously and proportionally. And the traffic carries
      its own cue at last — a car sounding its horn draws the same doubled lethal caret a
      `hard_fail` event does, breathing with the horn's decay, because the vocabulary's first
      row is *the entity itself carries most of it* and a car was carrying nothing. The accepted
      cost is stated rather than hidden: acts I and II have nothing lethal in them, so the mark
      is nearly silent before day 8 — which is the cue being honest about finding 5 rather than
      covering for it. The thing nobody had noticed: the caret was a **private method on
      `EventInstance`**, so "the entity carries its own cue" silently meant "the *event* entity
      does", and the one lethal thing outside the catalogue fell off that edge
- [x] **M24 The city remembers where you went** — finding 4, and playtest 02's finding 11. The
      calm block the baby actually fell asleep in is remembered and the next day plans one loud
      thing into it; the usable-park rule is told to protect a different one, or the two halves
      fight and it strips the very event that was the point. Measured over five seeds and a whole
      run: the chance the quietest calm block today is yesterday's goes from **28% of days to
      zero**. Kept from being a punishment for playing well by three things — it spoils with an
      avoidable, visible event rather than removing the ground, nothing lethal, obstructing or
      mobile is ever chosen for it, and it is one ordinary event from the same day's pool.
      **It does not read the telemetry**, which is what the write-up assumed it would: a rule
      that reads a trace would make the game play differently with `--no-telemetry`
- [x] **M31 Act I has teeth, and more to look at** — finding 5, the emphasised one, plus the
      request that came with it: *"try to come up with more variety, we need more
      events/entities in general."* Seven new rows, five of them on day 1, each with its own
      silhouette rather than another `person.svg`. **The shape was chosen against the obvious
      one**: a patrol was ruled out by the player — *"patrol shouldn't be there for act I"* —
      so the danger is the neighbourhood's own, a **cyclist** from day 2 and a **reversing
      lorry** from day 3, both `hard_fail` with the doubled telegraph the contract demands and
      teaching opposite lessons (one comes at you, one is static with the danger behind it).
      Lethal events per day now run **0, 3, 4** over days 1–3, so the escalation is a change of
      *kind* rather than of count and a person can feel it on day 2. Measured at 7×7 alongside it,
      and no longer carried in `docs/EVENTS.md`: events placed on days 1, 2, 3, 8 and 14 were
      **48, 49, 52, 69, 88**, of which **0, 3, 4, 11, 11** were lethal — day 2 places about one
      more event than day 1, which nobody could feel, and that is the point of the pair.
      Two bugs came out of it that no test could see: a re-streamed event was rebuilt from the
      tile the day chose at dawn, so a **dog walker teleported back to the top of its street**
      every time the player left its radius and returned; and an `EventInstance` had no gait at
      all, so a thing moving at 32px/s read as parked. Both were reported as *"dog walkers are
      not moving?"* and neither was the movement

## M32 — Playtest 06: the cues mean now

See **[docs/PLAYTEST-06.md](PLAYTEST-06.md)**. The first playtest taken on M28–M31, reported
part-way through M21 with the instruction to *"take note of those but continue implementing the
next item on the handoff first"*. **All five are done.** Three were small fixes in code M22, M30
and M6 already owned; one added a row to the vocabulary; and the four of them together are one
sentence — *a cue is a claim about a moment*, which is the axis M30 had not looked along.

- [x] **The difficulty is right.** *"I like the difficulty now — it actually became harder."*
      Not a task; recorded because it is the **first balance number in this game ever confirmed
      by a human**, and `CLAUDE.md`'s "no balance number has been felt by a human" has been true
      since M14
- [x] **The screen-edge badge measures the wrong speed** — *"they show events far away, and if
      you walk towards them they sometimes disappear; also they flicker a lot."* Two of the three
      symptoms were one defect: `DangerEdge` tested the *relative* closing rate against a 20px/s
      threshold and she walks at 92, so **walking towards anything lethal raised its badge**. It
      measures the event's own approach with the player held still now; the range cap is a
      *window* (`LEAD_TIME` seconds of its own approach, so the same 800px is a fire engine and
      not a dawdler); a raised badge is held; and the list is sorted by **arrival** rather than
      by distance, which is what `MOST_AT_ONCE` should be choosing between.
      **The flicker had a second cause the analysis did not predict**: a thing on the screen
      boundary trades places with its own badge every frame, which needed hysteresis on the
      *edge* — a margin outside the view before one may be raised — and no amount of it on the
      closing rate would have helped. Also caught by a trace: the director's `AHEAD_OF_PLAYER`
      events were eligible, so a cat whose entire content is that it is *not* announced was
      raising and dropping a badge inside a tenth of a second
- [x] **The exclamation mark outlives the car** — *"I get the flashing exclamation marks after
      the fact, at which point they're not useful."* `CAR_WARNING_HOLD` is 1.4s and nothing
      lowered the mark when she stepped off the carriageway, where a car cannot reach her at all.
      The hold has a real job — surviving the gap between two cars in one lane — so it is a
      second condition rather than a shorter hold: `Stroller.warn()` takes a **source** and
      `stand_down()` lets that source, and only that source, lower its own mark. A trace of a
      minute of day 3 now shows every span at 0.3–0.7s and **all of it on the road**
- [x] **A lost day is retried, not skipped** — finding 4, and it closes an open design question
      carried since M6. `GameState.finish_day()` no longer advances the calendar on a loss, the
      summary says *"You try day 3 again"*, and the attempt's `settled_in` record is forgotten
      with it — otherwise M24 would spoil a park the winning attempt never went to, and the
      record is written once a day. The run can no longer end by running out of days while
      nerves remain
- [x] **The meters are in the corner and the game is played at the pram** — finding 5, and the
      only one that adds to the vocabulary rather than fixing something in it. Four states over
      the pram — asleep, stirring, not settling, nearly crying — as *states with an instruction*
      rather than a gauge, in the vocabulary's own colours and its own motifs, anchored to the
      pram and stepped aside when the pram is on her own axis so it can never share a column
      with the exclamation mark. `Baby.Cue`, `Stroller._draw_baby_cue()`, three new sprites
- [x] **And the log can see a cue at last.** Not a finding: the gap playtest 05 named and
      playtest 06 walked straight into. Both cue defects were invisible to a trace, because
      every entry said what the *world* did and none said what the game **told her about it**.
      A `cue` entry per span, written when the span ends so the duration is on the line

## M33 — Playtest 07: the cost model was inverted, and running started to matter

See **[docs/PLAYTEST-07.md](PLAYTEST-07.md)** for all nineteen findings, the traces that confirm
three of them, and the ten that are still open. Nine are done.

- [x] **The falloff has a shoulder** — finding 18, and the one change that answers it for the whole
      catalogue at once. `(1−t)²` → `1−t²`, so a field holds three quarters of its intensity at the
      midpoint of its band instead of a quarter. No radius moved, so the telegraph fairness
      contract — which is stated over *distance* — is untouched. The trace said it in as many
      words: every `near` entry written at an event's own outer radius read `events 0.0`
- [x] **The crowd paid the shape back in radius** — the same change put the arterial floor at
      18.4/s against a 3.5 walking decay, which is a main road that fills the meter in six seconds.
      A pedestrian's outer radius came in 88 → 55 and a car's 170 → 104, which restores the floor
      to within 3% while leaving the close pass at 4.2/s. What is defended is M27's character:
      **careless is expensive and careful is free**
- [x] **Standing still settles nothing** — finding 3. `EXCITEMENT_DECAY_IDLE` was 6.0, the
      *fastest* of the three rates, so a full meter cleared in seventeen seconds anywhere. The
      ordering is motion-shaped now: walking 3.5, running 0.5, standing 0.0. And there is an
      `idle` telemetry span, because the player asked whether it was captured and it was not —
      standing still emits no entry of any kind, so the strongest move in the game showed up in a
      trace as a seventy-four-second **gap between two lines**
- [x] **A contact resolves** — finding 5. Two defects, either enough on its own: the separation
      resolved to exactly `BUMP_RADIUS`, which is the radius that *releases* the contact, so a
      resolved pair sat on its own threshold; and a walker steers back to its lane centre, which is
      where she is standing. Hysteresis band plus a sidestep. The longest single contact goes from
      1.0s to **0.1s**, backed against a wall included
- [x] **People get out of the way** — finding 17. M19 and M27 measured eleven contacts down a lane
      centre against one on the midline and built the crowd on that ratio; a probe re-run on `main`
      says it is gone — thirteen against fifteen — and it cannot be tuned back, because a midline
      is 16px from two lane centres and `BUMP_RADIUS` is 14. That line was two pixels wide when
      M19 measured it. So the careful line is a **behaviour**: somebody who sees a pram coming
      steps aside, hurries across, or waits. Same-axis contacts go from eleven to nought-to-four.
      A bump also costs 18 rather than 26, because the authored content now carries the share the
      crowd was carrying alone
- [x] **Running is the answer to exactly one kind of thing** — and it is two decisions, not one.
      The shoulder broke the old one by accident: a fatter field makes time-in-field matter more,
      so running became a point or two *cheaper* than walking through the four widest events. Not
      "running works" but "running is a coin flip". `EXCITEMENT_FROM_RUNNING` 9 → 14 restores the
      ordering, and `tests/test_events.gd` asserts it row by row — it had only ever been measured
      and written into a document, which is how it broke silently.
      Then the player asked for the opposite: *"the run button is a trap shouldn't be an invariant
      — there should be legitimate cases where running is required."* So `EventDef.pursues`:
      something that comes after **her**, faster than a walk and slower than a run, lethal, and it
      gives up. Walking and running give **opposite outcomes** rather than the same outcome at two
      prices, which is why it had to be a mechanic. `Tuning.validate_pursuit()` is its contract and
      it is stated over `RUN_SPEED`, exactly as this file said M25's would have to be. Verified by
      rig: a player who walks directly away from the first frame is still caught (1.6px), and one
      who runs escapes with 240px to spare
- [x] **Day 1 teaches walking, day 3 teaches running** — *"on day 1 we only introduce arrow keys.
      On day 3 we introduce the running key (it is possible to run before but not required), and
      have an incident at the start to force running."* `charging_dog` is gated to
      `Tuning.RUN_TAUGHT_DAY`; `EventDirector` moves the first one to the head of the queue on that
      day so the lesson is not left to a weight of 1.4; and the HUD says *Hold SHIFT to run* on the
      frame the dog telegraphs rather than at dawn. **This is half of M26 arriving before M25**,
      and the ordering constraint M26 was written with is satisfied rather than broken: the forced
      run is behind the thing that makes running right, and not on day 1
- [x] **The mark is for a beat you can actually play against** — finding 2's cue half. The rule was
      `pulse_period > 0` and six of the ten rows available on day 1 have a pulse, so the caret was
      over most of an ordinary street: the deleted ring's own mistake in the shape M22 invented to
      replace it. It is a relationship now — the period has to be shorter than the walk across the
      field, which is exactly when a pass can be slipped between two beats. Day 1 goes from six
      marked rows to two, and both are the ones whose counterplay is *go now*
- [x] **There is a pause** — finding 12. `Esc` opens it, `Esc` closes it, `Q` quits. It quit
      outright for thirty-three milestones and has been under known-shaky ground since M6
- [x] **Solid things are solid** — findings 16, 13, 7 and 15, done as **M34**. `obstructs_radius`
      was a list of five rows out of thirty and is a rule now: anything that stands still is solid
      at half its silhouette. A parked van moved off the carriageway to the kerb, where it takes a
      pavement instead of standing in a lane the crowd drives through; a reversing lorry got the
      building it reverses into, and is turned to face out of it; `alley_robbery`'s inner radius
      moved 22 → 30, because a lethal radius and a solid body are the same mechanism and a body
      that reaches the kill radius switches the kill off. Day 1: events placed unchanged at ~39,
      pavement-blocking obstacles 12.2 → 17.2
- [x] **One picture per row** — findings 2, 11, 4 and 14, done as **M37**. See the section below
- [ ] **The last four.** The cat crosses the wrong axis (1); a four-block concrete plaza (8); a car
      turning has no diagonal (6); and the crowd's own anonymity, which is deliberately *not* the
      same rule — see the bottom of `docs/PLAYTEST-07.md`

## M35 — Playtest 08: nothing vanishes, and the dog gives you a chance

See **[docs/PLAYTEST-08.md](PLAYTEST-08.md)**. Five things, all done.

- [x] **The spoiler covers the park rather than standing in it** — finding 1, which is playtest 07's
      finding 10 asked a second time. M24 placed **one** event and nobody did the arithmetic: what
      denies calm ground is out-emitting a decay the calm multiplier has raised to 7.7/s, so a
      busker at intensity 9 has a *useful* radius of 100px in a lot 704px across — three percent of
      a four-block zone. It is a crowd now, on a grid sized by `_denial_radius()` and capped by
      `Tuning.SPOILERS_TO_DENY_A_PARK`, with **each cell rolling its own def** so a spoiled park is a
      busker and a leaf blower and a market stall rather than nine copies of one sprite. Calm ground
      denied goes from 8–12% to **91%** of a courtyard and **99%** of a four-block zone, over five
      seeds and twenty lots. *"I can walk over the robber"* is the same finding from close up and not
      a regression of M34 — a probe confirms the body stops her at 25px exactly; what it does not do
      is cost her anything once she is there
- [x] **Nothing vanishes while you are looking at it** — findings 2 and 3, which are one rule.
      *"Things that move disappear on screen; they should at least run offscreen before despawning"*
      and *"pigeons are also completely ineffective"* — and playtest 07's *"birds just disappear"*, a
      milestone earlier. An event that is over now **leaves**: it stops emitting, it cannot end the
      day, it carries no cue, and it moves until it is past `Tuning.OUT_OF_SIGHT` before it is
      deleted. Anything mobile leaves at its own speed and needed no data; `EventDef.departs_at` is
      for a flock, which has to fly, and a pursuer that has lost interest. Two things never leave and
      both would break something that reads the finishing position — an event with a
      `spawns_on_finish`, and anything that was a place rather than a moment
- [x] **The pigeons are a thing to walk around** — the other half of finding 2. They sit on the
      pavement for their whole telegraph (a flock already in the air is a flock she has walked past),
      the burst outlasts her arrival instead of ending at it, and 20 over 140px moves the row from
      +22.9 to **+34.9** — between a reversing lorry and a dog walker, which is what a flock going up
      in a pram's face should be worth
- [x] **The dog gives her room to answer** — finding 4, and the one that ended the run. Two changes
      and they are the same change twice, the contract restated as **geometry**:
      `Tuning.pursuit_standoff()`, which the telegraph is spent closing to and *holding* — backing
      off if she walks into it, because she will, since it is sited in front of her and forward is
      where she was going — and a **break-off**, so the chase ends when it is beaten rather than when
      the clock says so. Without the second one the price of the right answer was
      forty points whether she reacted on the first frame or the last, and the trace has her running,
      doing exactly what the HUD asked, and losing to the meter with the dog 87px behind her. The dog
      also came down 148 → 130px/s (symmetric: walking loses 38px a second, running gains 38) and
      intensity 22 → 12, because it is lethal and does not also need to be the loudest thing in act I.
      Measured on a rig: walking loses either way, running costs **21–24 points**, and reacting
      sooner costs less
- [x] **And the log can see a chase** — the question the finding actually asked. Two `chase` entries
      per pursuit, carrying how close it got, how much of it she spent running, and whether it gave
      up or merely stopped. The old trace had an event being sited, four distances and a death, all
      of them about the **world**, while the question is about the **exchange**. `--flee` is the
      other half: a rig that can only hold a direction can only ever demonstrate the wrong answer
- [x] **Five nerves** — *"we need more nerves let's try 5?"* Three was the number from M6, when a
      lost day also advanced the calendar and a nerve cost a day of the fourteen as well as a life.
      M32 took that half away and left the number

## M36 — Playtest 09: the key that did nothing, and the man who did nothing

See **[docs/PLAYTEST-09.md](PLAYTEST-09.md)**. Four things, all done.

- [x] **`Esc` works** — and it had never worked. The guard read `visible` on a `CanvasLayer`, which
      is true from the moment the node is in the tree; the question it meant to ask is `is_showing()`.
      It opens **over** the between-days summary now as well, because `PauseScreen` puts back the
      paused state it found rather than assuming one — the first version refused there on the correct
      grounds that two things fighting over `get_tree().paused` is how a pause stops meaning
      anything, and the answer is to not fight. `tests/test_pause.gd` holds the trap itself as an
      assertion: *a fresh summary is not showing, and its own `visible` is true anyway*
- [x] **`--press <action> <seconds>`, so a rig can press a key** — the actual lesson. Neither the
      suite nor a screenshot could have caught the pause, because nothing in either has ever pressed
      one. Its own first version used `Input.action_press()`, which sets the polled state and nothing
      else: fine for `--walk`, useless for anything answered in `_unhandled_input`, and it produced a
      screenshot of the game carrying on — which looks exactly like the bug it was written to check
- [x] **The man shouting paces** — *"it didn't move and it took a long time to have any effect"*.
      `EventDef.paces`: a **beat** rather than a journey, so it walks its route, turns round at the
      ends, and neither departs nor expires, because it is a fixture that moves. Intensity 10 → 14
      (+17.7 → +31.2 in the cost table) and the body M34 gave him comes off, because anything mobile
      is exempt from "solid things are solid" — M19's `dog_walker` decision, unchanged
- [x] **The robber is a place that becomes a chase** — *"a robber should increase excitement on sight
      and getting close to them should be day ending"*, and *"if you get close they should start
      moving towards you"*. `EventDef.pursues_within`: three states rather than two, with the clock
      starting when it **notices** her and its notice **not** damping what it emits. 16 over 200px,
      lethal inside 30, 130px/s from 140. Standing, walking past and walking *away* all end the day;
      running shakes him off in ~1.5s for 21 points.
      **And a trap found by measuring:** while the chase ended at a *distance*, a trigger at or past
      that distance was a pursuit that lost interest the instant it started — at 170 against 170 the
      rig strolled away from him every time. A break-off stated as a rate cannot reproduce it
- [x] **And a scar could be tidied away by the usable-park rule** — exposed rather than caused by the
      above. `_ensure_one_usable_park` strips the spoilers off the least-disturbed calm block, and a
      burnt-out shell that had been on that corner since day 3 was one of them. Scars are exempt now,
      for the same reason ambient events are: a permanent feature of the map is not today's noise

## M37 — Playtest 07 again: one picture per row

See **[docs/PLAYTEST-07.md](PLAYTEST-07.md)**. Four of the six that were left, and they are all
"what you can actually see".

- [x] **One picture per row, and no two rows share one** — finding 2, and the fix is bigger than
      the finding because the finding was a symptom. `EventDef.Look` opened with five
      **categories** — `PERSON`, `VEHICLE`, `OBJECT`, `ANIMAL`, `FIRE` — and a category is a thing
      you can always put one more row into, so sixteen of the twenty-eight visible rows drew five
      pictures between them: five people on one man, six vehicles on one van.
      **It had already cost two findings and neither looked like an art problem.** M34 spent a
      milestone fixing `alley_robbery` for a complaint about `homeless_yeller`, because a player can
      only say *"the robber"*; playtest 09 then asked *"who is the person killing me?"*. And a third
      had gone unreported — `DangerEdge` kept its **own** table of which picture a look meant, so
      the screen-edge badge, whose entire content is *what* is coming, drew a delivery van for a
      fire engine and for the unmarked van that takes the baby.
      So it is a rule with a test rather than fifteen drawings: no two rows share a look, no two
      looks share a silhouette, `EventInstance.icon_for()` is the one table, and `look` has no
      default worth having. **The cost of adding an event is a drawing.** Same move as M34's
      `obstructs_radius`, on the other half of the vocabulary
- [x] **The robber has two postures** — `is_waiting()` picks between them. M36 gave that row three
      states and the screen showed one, so *a man is standing there* and *he has seen you* looked
      identical. The `cat_crouched` / `cat_running` rule, at the row where reading it wrong ends
      the run
- [x] **The protest is a crowd, and its body followed its picture** — the catalogue said of that
      row *"one person's worth, because one person is what it draws… the art is the fix"*, and it
      is 55px now, two ranks drawn across exactly the ground it takes. The clearest case in the
      game of art deciding a gameplay number. Measured over five seeds: events placed per day is
      **identical**, day for day, and so are protests placed
- [x] **The café has people at it** — finding 11. The tables were what obstructs and the
      conversation was what it emits, and only the first was drawn
- [x] **Buildings sort against nothing** — finding 4, diagnosed in M34. The fix is not the one the
      diagnosis pointed at: the comparison is **meaningless**, not merely wrong. Buildings tile
      their lots exactly and no lot tile is walkable, both asserted since M3, so nothing can ever
      legitimately stand behind a building. `Buildings` is a y-sorted layer under `Entities`.
      `building.gd` had claimed the opposite in a comment for twenty-two milestones
- [x] **The zzz stops dodging nothing** — finding 14. The baby's cue steps out of the exclamation
      mark's column, and that column is only occupied when there is a mark in it; unconditional, it
      put the zzz a body's width to one side of the pram on the commonest picture in the game.
      Playtest 06's own lesson again — *a cue is a claim about a moment* — reaching a player for
      the reason M32's two did: nothing in `tests/test_danger.gd` can see a `_draw()`. It is
      `Stroller.baby_cue_aside()` now, and the suite asks it

## M38 — Things that shipped and did not work · `feature/nothing-freezes`

Not a playtest: five reports and two design instructions, delivered in one sitting. What they have
in common is that every one of them had passed a green suite, a screenshot, or both — see the note
at the top.

- [x] **The birds are eleven birds** — *"they start the flying animation but then freeze. Turn them
      into individual entities and let each fly and make them dangerous."* A flock was one sprite
      drawn seven times at offsets derived from the instance's own position, sharing a single `rise`
      term that reached 1.0 at the end of the telegraph and then held — so the flock went up in one
      movement and hung motionless for the whole burst. `EventDef.flock_size` gives each bird its
      own heading, speed, height and wingbeat, **and its own contribution**, so the middle of a
      flock stacks five fields and the rim stacks one: +35 walked through the centre, +8 eighty
      pixels off it, nothing at the rim. It is the only row in the game that is more than one
      source, which is why `tests/test_events.gd` had to learn to price one — left as a disc the
      row read +97 and broke the running rule it in fact keeps. Two traps, both in `CLAUDE.md`:
      `flock_spread` comes out of `outer_radius` or the fairness contract is about a different
      disc, and `lerp` cannot turn a vector round
- [x] **The cat faces the way it is going** — *"the cat graphic is flipped horizontally."* Both cat
      SVGs were drawn facing **west** while every other sprite with a front faces east, and
      `_heading_is_west()` mirrors the art — so a cat bolting west was drawn running east and a cat
      bolting east was drawn running west. The convention was never written down anywhere; it is
      inferable from `dog.svg`, which is drawn ahead of the walker on a taut lead and only reads
      right facing east. The art was wrong, not the flip
- [x] **A car looks before it turns** — *"when a car turns into an occupied lane the other car just
      disappears."* `_divert()` chose an arm out of the tile map alone, so a car diverting round a
      closure materialised inside whatever was in that lane, and the M27 positional resolve then
      moved a body — front to back, compounding, up to 134px in one frame, on screen. `TrafficIndex`
      is the look; `claim()` closes two placements in the same frame; `_join_the_back_of_the_queue()`
      is the guarantee behind the six re-rolls. Measured at a closure over 90s: 1627 corrections and
      a worst of 134px, down to 146 and 66px. The queue was legal on every frame either way, which
      is why the test that has always been here passes both
- [x] **Calm ground is 20% faster** — `SLEEPINESS_CALM_ZONE_MULTIPLIER` 10 → 12, so the meter fills
      in 20s rather than 24. Every milestone since M28 has made the walk *out* harder and left the
      reward at the end of it the same length. Unfelt; it is in the known-shaky list
- [x] **A finished run has a key on it** — *"the lost screen doesn't allow for restarting the game.
      You can just cycle between pause screen and loss screen at that point."* The ending said
      `esc to quit`, `Esc` opened the pause, and the pause offered `Esc` and `Q`. `space` on the
      ending now goes back to the title, and `R` on the pause starts the run again from anywhere
- [x] **A title screen, with the game running behind it** — *"start on the pause screen, or create a
      game open screen"*, then *"just use the home and street in front without player and let act I
      events play out."* Not a menu and not a still: the doorstep of a real, planned first day, with
      the traffic driving and the events playing out on it and nobody pushing a pram through them.
      It needed the `process_mode` split used deliberately for the first time — the city on `ALWAYS`
      and the day paused, with the player pinned back to `PAUSABLE` because she is a child of the
      city — and `Stroller.stand_aside()`, which takes her out of the `player` group and with it
      every way the world can touch her
- [x] **`--press` can press a key, and can press more than one** — `Q` has quit from the pause
      screen since M33 and `R` restarts now, and neither is an input action, so the rig that exists
      because *nothing in the suite or a screenshot has ever pressed a key* could not press either
      of them. `--press key:r 3.5`, and the flag may be repeated

## M39 — Playtest 10: the cue that meant nothing, and the day that was not the same day · `feature/marks-that-mean-danger`

See **[docs/PLAYTEST-10.md](PLAYTEST-10.md)**. Fourteen findings, reported as a list after a session
of five runs in which **no day was won**. Eleven are work; two are answered in writing; one — the
difficulty — is deliberately the milestone after this one.

The sentence under it: **the danger marks and the danger have come apart, and a retried day is not
the same day.**

- [x] **The mark is raised by what a thing costs** — findings 1, 8 and 9, which are one finding with
      three faces. `wants_a_mark()` asks whether the danger *changes over time*, which is a true
      statement about a thing and not a statement about how bad it is: a fire engine (+115) carries
      no caret and a burning building (+56) does, the most expensive ordinary row in act I
      (`dog_walker`, +36) carries none and the leaf blower beside it does, and the man who ends day
      1 in three separate traces (`homeless_yeller`, +31) misses `can_be_timed()` by four tenths of
      a second. The colour half is streaming: `EVENT_STREAM_RADIUS` is 900px and no telegraph is
      longer than 4s, so amber is only ever seen on the two `AHEAD_OF_PLAYER` rows and therefore
      means *near* rather than *not yet*. New rule, with the invariant a test can hold: **if A is
      marked and B is not, A costs more than B**; amber for *go round it*, doubled deep red for
      *ends your day*, and the flash — not a colour — for *it has not started*. Accepted cost,
      written down as a decision: the crouching cat (+20) loses its caret
- [x] **The playground is the calmest ground in the city** — finding 2, and it has been true for
      twenty milestones. `PLAYGROUND` is calm ground, so the decay on it is 7.7/s, and the row emits
      **7.0/s at the peak of its pulse**: it has never once out-emitted the ground it stands on, and
      its denial radius is its own inner radius, 40px of 150. It was right in M5, when the calm
      multiplier was 3.5 and the decay 1.5/s; M18 took it to 10 and M38 to 12. Playtest 08 did this
      exact sum for the busker one function away, in `_denial_radius`, which carries the warning in
      its own docstring
- [x] **The dog follows for too long** — finding 13, *"the running tutorial dog is impossible to
      escape"*, and **the analysis in this session was wrong**. It read the finding as a *reaction
      window* — `pursuit_standoff()` buys `PURSUIT_REACTION` seconds of the dog's 130px/s while she
      is walking into it at 92, so the real window is 0.2s — and built the fix for that. The player's
      own account: *"the charging start earlier was fine — it was enough time to react properly"*,
      *"the issue was that the dog kept following for too long"*, and *"the dog now moves backwards
      before charging — that doesn't make any sense"*.
      The trace agrees with the player: she reacted, she ran, and she **died to the meter with the
      dog 63px away**. It is the **break-off**, which is M35's failure repeating. The work built on
      the wrong reading is in the tree, uncommitted, and `docs/HANDOFF.md` lists every constant to
      re-decide.
      **What was built instead**: `Tuning.PURSUIT_SHAKEN_OFF`, which ends a chase after 0.8s of the
      gap **opening** rather than after a fixed gap has been reached. Because a pursuer is faster
      than a walk and slower than a run by construction, only running can open the gap — so "walking
      away can never end a chase" and "running away always ends one" stop being two inequalities that
      fight over the same three numbers and become facts. The reaction, the stand-off (104px) and the
      chase (3.0s) all go back to what a player said was already right. Measured: the answer costs
      **0.86s of running, 12 points**, against 35 before.
      **Two things found on the way are kept**: a pursuer must stand off inside its own
      `outer_radius` (found by a rig — the dog was holding 174px out with a 150px field, so the phase
      that is supposed to *be* the warning emitted nothing and the `!` never went up), and
      `tests/test_events.gd` has a rig that **accelerates**, which the three that passed while the
      encounter was unplayable did not.
      **Still open, and written down rather than hidden**: the window to answer at the lunge itself
      is 0.1–0.2s, because she is walking into the thing. A player answers during the telegraph
      instead. Widening it means a wider stand-off, and a wider stand-off is the reversing dog
- [x] **A retried day is the same day, and the day-3 lesson always happens** — finding 5. Three
      independent causes and the third is the one that matters. `_place_one_shots` skips a consumed
      one-shot *before* drawing its `randf()`, so attempt 2 starts a value earlier in the stream and
      every later placement moves — five seeds out of five produce a different day 3, and one of
      them changes how many `charging_dog`s exist. `_place_scars` compounds it through
      `_room_around`. And **the tutorial is a weighted roll**: `_teach_the_run` says outright that
      if the day did not buy one, nothing happens, and whole day 3s with `charging_dog x0` exist.
      Also the director's clock only runs while she is moving, and the third attempt in the trace
      never left the doorstep
- [x] **The `!!` comes down when the danger has been avoided** — finding 11. The doubled mark is
      raised for any lethal event whose **outer** radius covers her, so a cyclist lethal inside 26px
      raises it across 145 and keeps it up while the bike rides away. Playtest 06's finding 3 at the
      half M32 did not fix — it gave the traffic a `stand_down()` and left the events on "inside the
      radius". Two conditions now: within a step of what ends the day, **and** closing. Deliberately
      the *relative* rate, where the screen-edge badge deliberately uses the thing's own — the two
      cues say different sentences and the difference is the reason
- [x] **The zzz over the pram** — finding 3, and the other half of M37's own fix
- [x] **`space` carries on, and the pause says which day and how many nerves** — findings 6 and 7
- [x] **Screenshots beside the trace** — finding 12. On the entries that are already *about a
      moment* — a day lost, a nerve, a hard fail, a chase — rate-limited, capped per day, named
      after the entry. In `TelemetryObserver`, because telemetry never touches gameplay
- [x] **Logs you can throw away** — finding 14, plus the follow-up that explains it: a run restart
      reloads the scene, so one sitting is several logs and that is correct. The commit goes in the
      **filename**, `tools/telemetry.sh` grows a prune, and the listing says which are stale
- [x] **The yellow person that did not approach** — finding 4, answered in writing rather than
      built: nothing in act I pursues, and a busker who chases prams is a different game. It is
      recorded because it is findings 1/8/9 from a fourth side — *I cannot tell what any of these
      things are going to do to me*
- [x] **Home at the centre** — finding 10, answered in writing. The city is already odd (7×7) and
      `_place_home` already sorts by distance to the centre; what pushes the home out is
      `MIN_HOME_TO_PARK_TILES`. The two rules compete for the same thing and at 7×7 both cannot
      hold. The recommendation is to take the trade **by growing the city to 9×9**, as its own
      milestone, because it re-measures every density number in `docs/PLAYTEST-04.md`

### And the thing nobody reported

- [ ] **The crowd is winning.** Nineteen days lost in the session, seventeen to `lost_crying`, and
      the breakdown on the losing line reads `crowd 39.4, events 0.0` / `crowd 44.4, events 3.1` /
      `crowd 28.8, events 0.0`. That is playtest 07's finding 17 after the milestone that answered
      it, and two of the fourteen are downstream of it. **The next milestone**, measured rather than
      argued — not this one

### And the tooling that is getting in the way

- [x] **The test suite takes too long to run.** Done as **M44**; it was 8.4 minutes and is 96
      seconds. Not one of the four things this entry proposed turned out to be where the time was —
      see the milestone for what measuring found instead.

## M40 — Documentation you can read, and history you can retrieve · `feature/timeless-docs`

Asked for directly: *"adopt a timeless documenting style. Things should be stated as what they are,
not where they came from. Keep a dedicated file for ideas that were rejected, decisions that were
made (and which options were rejected), and changes that happened."* And: *"especially for
docstrings make sure to document the why and the edge cases; don't restate the full
implementation."* And: *"we don't want to lose history/information — we just want to make the
current state more accessible and the history retrievable on demand instead of always in context."*

**The problem, stated plainly.** This project writes history into the thing itself. A docstring
opens with *"(M39, playtest 10 finding 13: …)"*, a constant's comment is three paragraphs about the
two numbers it used to be, and `CLAUDE.md` is 900 lines in which the rules and the archaeology are
interleaved. That was a deliberate bet — the reasoning is not recoverable from a diff — and it has
paid off repeatedly. What it costs is that **reading the current state means reading every past
state first**, and every reader of every file pays it whether or not they need it.

The fix is not to delete any of it. It is to **split by question**: *what is this and why is it like
this* stays with the code; *what was tried, what was rejected, and when it changed* moves to one
file that is read on demand.

**Sharpened on 2026-09-01, and the second half is new work rather than a restatement.** *"Before we
start implementing anything else we need to bring the codebase up to date with the decisions we
made. There is a lot of stale information where notes are outdated. Let's focus on that and the
timeless writing style so that reading outdated information as current information can never happen
again — all information should **only** reflect the current state **never** past states with
caveats."*

So M40 is **two jobs, and the restyle is the smaller one**:

- **A correctness pass.** Find and fix sentences that are no longer true. This is not a side effect
  of restyling — a stale claim survives a rewrite perfectly well if nobody checks it against the
  code. `docs/HANDOFF.md` opens with *"`main` is `c82bcbb`… 175380 checks"* against a suite that is
  at 202075, which is the failure in its purest form: the file whose whole job is *where to pick up*
  is the file most confidently wrong about where things are.
- **A style pass.** Present tense, current state only. **No "used to be", no "since M33", no "this
  was wrong for twelve milestones", no caveats about what a sentence meant before.** Where the story
  is worth keeping — and this project's whole bet is that it usually is — it goes to
  `DECISIONS.md`, which is *the* place the reader goes for it.

**The test is a reader, not a diff:** somebody who opens any single file and believes every sentence
in it is wrong about nothing.

**The size of it, measured rather than guessed** — `grep -rE '(M[0-9]{1,2}\b|playtest)'`:

| | files | history references |
|---|---:|---:|
| `src/**/*.gd` | 45 of 56 | 590 |
| `CLAUDE.md` | 1 | 141 |
| `docs/` minus the playtests and `TODO` | 8 | 528 |
| `docs/TODO.md` | 1 | ~1000 |

`src/autoload/tuning.gd` alone has 113, `event_catalogue.gd` 50, `event_scheduler.gd` 45. **This is a
multi-session milestone**, and the order below is by where a reader lands first, so that stopping
part way still leaves the project better rather than half-converted.

**Two calls taken here rather than asked, because M40's own text implies both.**

- **`docs/HANDOFF.md` splits along a line it already draws itself.** Its header says *"everything
  below the pick-up block is older history, newest first"* — so the pick-up block **is** the
  current-state document and the tail **is** `DECISIONS.md` in session order rather than decision
  order. HANDOFF keeps the block and nothing else; the tail is the first thing merged into
  `DECISIONS.md`. A third file would be a third place to go stale.
- **What timeless means for a to-do list**, which is the one document that is legitimately about
  time. An **open** item is current state and gets the full treatment. A **ticked** item is history
  the moment it is ticked — so it moves to `DECISIONS.md` with its measurement and its rejected
  options intact, and `TODO.md` keeps the queue. That is what takes 4550 lines back to something a
  person reads before starting work, which is what the file is for and has not been for some time.

**And M40 has been sitting unbuilt since before M41** — about fifteen milestones. It is the third
thing this session found filed-and-not-read, after the interact key (playtest 02, twenty milestones)
and the alley roulette. **Three in one session is not three oversights, it is the symptom this
milestone exists to cure**: the project writes things down faultlessly and cannot find them again,
because everything ever decided is interleaved with everything currently true.

- [ ] **`docs/DECISIONS.md`, the retrievable half.** One file, three kinds of entry, each dated and
      each linking to the milestone and the playtest that produced it: **decisions taken** with the
      options that were rejected and why; **ideas rejected** outright; and **changes that happened**,
      with the measurement that justified them. It is the destination for everything the restyle
      lifts out, so nothing is lost — the test is that every fact removed from a docstring can be
      found by searching this file for the symbol name
- [ ] **Restyle every docstring.** Say what the thing is, why it is that way, and what the edge cases
      are. Do **not** restate the implementation — the code is right there — and do not narrate the
      milestones it passed through. Where a number was tuned against something, keep the
      *relationship* (*"above the 7.7/s decay on the ground it stands on"*) and move the story of how
      it got there. `Tuning.PURSUIT_SHAKEN_OFF` and `Tuning.pursuit_standoff()` are the worked
      examples of what an edge-case docstring should read like
- [ ] **Revisit all documentation, not the code alone.** `CLAUDE.md`, `README.md`, and every file in
      `docs/` — `ARCHITECTURE`, `CITY`, `DESIGN`, `EVENTS`, `MECHANICS`, `NARRATIVE`, `TELEMETRY`,
      `TODO`, `HANDOFF`. The playtest files are already history and stay as they are; they are the
      primary source `DECISIONS.md` cites
- [ ] **`CLAUDE.md` becomes rules, and the rules get subfiles.** Working preferences, invariants and
      recipes stay; the war stories under each move out. Anything too long for one file becomes a
      rule file of its own rather than a longer `CLAUDE.md`
- [ ] **And notes live in the repo, not in a session's memory.** Anything worth remembering about how
      to work on this project goes in `CLAUDE.md` or a rule/skill file beside it — a note that exists
      only in an assistant's memory is a note that gets lost

### The order, and why it is this one

By where a reader lands, so that stopping part way leaves the project better rather than
half-converted. Each is its own commit.

1. **`docs/DECISIONS.md` exists and takes `HANDOFF.md`'s tail.** Nothing can move out of a file
   until there is somewhere to move it to.
2. **`docs/HANDOFF.md` becomes the pick-up block alone, and is made true.** It is the first file the
   next session opens and it is currently the most wrong.
3. **`CLAUDE.md`.** Read every session by everybody, 1500 lines, 141 history references. Rules and
   invariants stay in the present tense; the war stories go. Anything that unbalances the file
   becomes a rule file beside it, which this file already says.
4. **The design docs** — `CITY`, `EVENTS`, `MECHANICS`, `TELEMETRY`, `ARCHITECTURE`, `DESIGN`,
   `NARRATIVE`, `README`. These are the ones a person reads to learn what the game *is*, and the
   ones where a stale sentence is indistinguishable from a design.
5. **The docstrings**, 45 files, worst first: `tuning.gd`, `event_catalogue.gd`,
   `event_scheduler.gd`, `city_generator.gd`, `event_instance.gd`, `crowd_agent.gd`.
6. **`docs/TODO.md`.** Ticked items out to `DECISIONS.md`, queue stays. Last because it is the
   biggest and because every earlier step tells you what belongs in it.

**The playtest files are not touched.** They are primary sources — a player's words on a date — and
rewriting one into the present tense would be destroying the only record of what was actually said.
`DECISIONS.md` cites them; it does not absorb them.

### Completed 2026-09-01, merged to `main` from `feature/timeless-docs`

Everything above shipped except the number re-audit, which stayed open as M40's finishing pass in
`TODO.md`. What each part found, with the measurements:

- **`DECISIONS.md` exists** and took `HANDOFF.md`'s history tail; the test held — every fact lifted
  out is findable here by its symbol name.
- **`CLAUDE.md` became an index** over eleven skills in `.claude/skills/`, one per operational
  task, holding only what applies to every task and the rules a hook cannot trigger on.
- **The path-triggered rules became a hook, not an instruction.** *(2026-09-01: "if they are
  triggered by files then make them rules that trigger on those files.")* A skill somebody has to
  remember to load is not a rule. `.claude/hooks/project-rules.sh` fires on every `Edit`/`Write`,
  maps the path to the skills that govern it, and injects them before the edit is made — once per
  area per session, keyed on the session id. The three with no file to trigger on — `feedback`,
  `committing`, `session-cleanup` — stay invoked by hand, being about a *moment* rather than a
  place.
- **The design docs pass** — `EVENTS`, `CITY`, `MECHANICS`, `TELEMETRY`, `ARCHITECTURE`, `DESIGN`,
  `NARRATIVE`, `README` to zero history references, one commit each. **The style pass found nine
  stale claims, which is the argument for doing both passes at once**: `AHEAD_OF_PLAYER` "is the
  cat" (it was three rows), the pre-per-block event budget formula, `construction` as "the only act
  I event in the way", `cat_dash`'s duration, an 8×8 junction lattice and 112 streets, "nineteen of
  a hundred" signalled junctions, `PARK`'s sleepiness and decay multipliers, a 104×104 city, and a
  car population of thirty. **`charging_dog` had no row in the catalogue table at all.** Two
  obsolete measured tables moved here rather than being restyled in place.
- **The docstring pass** — every `.gd` file in `src/` to zero history references
  (`grep -rcE '(M[0-9]{1,2}\b|playtest|Playtest)' src --include='*.gd'` left four hits, all the
  ordinary word in `main.gd`'s is-this-log-a-playtest function). **The rewrite that works is
  turning a narrated fix into the mistake a reader could still make**: *a contract in seconds
  cannot describe a pursuit played out in distances*, *never guard on a `CanvasLayer`'s `visible`*,
  *a category in an enum is a list waiting to happen*. **The pass found five stale claims and one
  dead field**: the mark docstring's "fifteen of the eighteen rows" (the catalogue had thirty-one,
  six lethal) and its "no lethal events in acts I and II" (the cyclist is day 2),
  `street_network`'s "64 junctions and 112 segments" (144 and 264), `main`'s "eighteen kinds" and
  its list of "four things a picture cannot carry" that named three, two crowd sizes quoted as four
  and five hundred against a cap of 200, and `EventDef.act_tag`, set on eleven rows and read by no
  game code.
- **`TODO.md` became a queue again** — open work only, completed entries archived here whole.

### The number re-audit, run 2026-09-01

Run as its own pass, as designed — a stale claim survives a rewrite perfectly well if nobody checks
it against the code. Four audit agents checked every quoted number in the governed docs and
docstrings against `tuning.gd`, `event_catalogue.gd` and the code they describe, the tooling
against its own documentation, and the docs against each other, on a tree where the full suite was
green. **Found: eight wrong numbers, three docstrings pointing at `CLAUDE.md` sections that had
moved into skills, four pieces of history that outlived the restyle, and stale evidence
attributions** — filed as M40's finishing pass in `TODO.md`. **Verified correct, row by row**:
every other quoted figure in `CITY`, `EVENTS` (all 31 catalogue rows' intensities, radii,
telegraphs, speeds, durations, day windows, weights and caps), `MECHANICS` (the meter rates, the
contact and car geometry, the falloff, the pursuit tables), `ARCHITECTURE`, `NARRATIVE` (the
six-step resistance calendar) and `HANDOFF`. The audit also found the same session's tooling gaps
(M58's items) and the dead-code list (M58's sweep), and confirmed the rules hook's path→skill
mapping correct on all nine rows, all eleven skills' ~90 cited symbols resolving, and the
`PARTIAL RUN` marker working as documented.

### The finishing pass, built 2026-09-01 · `feature/numbers-against-the-code`

All of the re-audit's findings fixed, one commit each, suite green throughout. The outcomes worth
keeping: NARRATIVE's crowd drop and MECHANICS' contact measurement became relationships rather than
figures; ARCHITECTURE's concurrency literal was dropped entirely after **three sources gave three
different figures for the same formula** (22, 25, ~32) — the linear-scan argument never needed the
number, and `CLAUDE.md`'s and the events skill's copies were fixed in the same session; DESIGN's
nerves went 3 → 5 and CITY's calm-area floor 3 → 5 to match `STARTING_NERVES` and
`MIN_CALM_BLOCKS`; the phantom `sabotage_run` row left `EVENTS.md` (the day-14 sabotage is
`GameState` logic, not an `EventDef`); `act_tag`'s true sentence is now "no game code reads it; one
test holds it consistent with the calendar"; three docstrings that cited `CLAUDE.md` for rules that
had moved into skills now state the rule or name the skill; EVENTS' dated six-seed role-weighting
table moved here (M50's section); the city and events skills' "used to" narrations were restated in
the present tense; `_place_home`'s superseded sort-by-distance story (already here under M42) left
the docstring; and `evidence/README.md`'s rows now name the document that actually cites each file.

### Reassessed on 2026-09-01, and closed

- **The pending calm-ground multiplier is planned against a stale base** — *done.*
  `SLEEPINESS_CALM_ZONE_MULTIPLIER` is 21, which is the 1.5× taken on the correct base, and the
  correction travelled with it.
- **A bug closed inside a design finding was never closed out** — *done.*
  `CrowdLanes.PRECINCT_OFFSETS` is six lanes across the whole width. The shape is worth watching:
  **a finding with two halves gets closed when the louder half is done.**
- **M41's eight open boxes** — the milestone is merged and its work shipped; the boxes were never
  ticked. What genuinely remains is in M53 (T-junctions at the edge) and M49 (judged by eye).
- **M27's "nobody has played it"** — superseded. Seven playtests have happened since.
- **M20's overtaking, eight-way driving and the crash event** — **parked with the player's
  agreement**, as *a conversation that is owed*, not as a thing nobody wanted.
- **M17, the route map** — **backlogged by the player's decision.** The gap it closes is real and
  `docs/CITY.md` states it as a gap rather than papering over it.
- **M52's "should more junctions be signalled?"** — parked, unasked-for, and it would repeal *"a
  property of the street rather than a scattering of them"*.

## M57 — The docs cannot go stale · `feature/the-docs-cannot-go-stale`

Asked for on 2026-09-01 (playtest 18, findings 1–3): *"can we enforce that documentation is written
in a way that it cannot easily become stale? for example we don't need to state how many tests are
green in the claude docs"*, *"there should be no quest logs outside of decisions.md"*, and the
approvals *"drift guard sounds good. stats.sh sounds good."* The rules already existed in
`CLAUDE.md`; this milestone built the machinery, because a rule somebody has to remember is not a
rule. Built same-day, four commits:

- **`tools/lint.sh`** — flags, in the governed docs (everything but `DECISIONS.md`, the playtests
  and `evidence/README.md`), the five sentence shapes that go stale on their own: a backticked
  commit hash, a branch name, a check count, a ticked box, a status word after `·` in a heading.
  `lint-allow` in an HTML comment suppresses a deliberate hit. Tuned against the real tree until
  its output was only true positives — `CLAUDE.md`'s self-referential forbidden-style examples and
  `TODO.md`'s milestone identifiers and dated player quotes must not fire it.
- **A `PostToolUse` hook** (`.claude/hooks/lint-docs.sh`) runs the linter on a governed doc the
  moment it is edited and surfaces hits in the same turn — enforcement at the sentence, not at the
  commit. PostToolUse cannot block, so the committing skill carries the stop: a lint hit before a
  commit is a stop.
- **The drift guard**, session-cleanup step: if `tuning.gd` or `event_catalogue.gd` changed this
  session, grep the governed docs for what moved — the number re-audit found all of its drift
  around retuned constants whose doc sentences stood still.
- First run over the tree: **zero hits** — the linter's shapes and the re-audit's findings turned
  out disjoint (wrong figures and stale narration in prose are a different staleness than hashes
  and status markers), which is why both exist.

## M58 — The tooling tells the truth · `feature/the-tooling-tells-the-truth`

The 2026-09-01 audit's mechanical findings, built same-day, seven commits, each verified in
isolation and the full suite green after the sweep:

- The rules hook's matcher covered `NotebookEdit` (which sends `notebook_path`, so it could never
  match) and missed `MultiEdit` (which sends `file_path`, so batched edits silently skipped the
  rules). Now `Edit|Write|MultiEdit`. The hook also matched paths by substring anywhere on disk;
  it now exits early for anything outside the repo root — verified by feeding it literal hook JSON
  for `/tmp/elsewhere/src/events/x.gd` (silent) against an in-repo path (injects).
- `shot.sh` and `test.sh` gained the missing-Godot guard the other tools had; `test.sh`'s
  `/dev/null` import pass had been swallowing exactly that failure. `check.sh` now checks both its
  invocations' exit statuses — it could print `OK` over a crash that printed no error string.
- `README.md` documents `--ending bad|neutral|good`.
- **`tools/stats.sh`** — the consumer for playtest 17 finding 3's run tagging. Splits `run-*.log`
  (playtest) from `rig-*.log` (headless), defaults to playtest runs only, and counts only
  documented log entries: runs, days won/lost, loss causes, most-met events. First real output over
  the folder: 49 playtest runs, 14 days won / 20 lost (9 crying, 8 hard fails, 3 timeouts), the
  yeller, the cat and the dog the most-met events — against 55 rig runs that would have drowned
  those numbers, which is the skew the player named.
- **The dead-code sweep**, every symbol re-grepped over `src/` and `tests/` at deletion time, none
  skipped: `EventBus.day_ended`, `EventBus.event_finished`, `EventInstance.finished`,
  `Baby.fell_asleep`/`woke_up`/`started_crying` (all emitted, zero listeners —
  `EventBus.baby_state_changed` and `DayController.day_finished` carry the load),
  `DayController.stop()`, `Corridor`'s `Where` enum with `where()`/`is_inside()`/`holds_street()`
  (superseded by `depth()`), `TrafficIndex.lane_count()`, `BlockPlan.final_purpose()`,
  `Building.roof_depth()`. `GameState.finish_day()` now calls `is_final_day()` instead of inlining
  the same comparison three lines below the query it ignored.

## M59 — The chatting mother · `feature/the-chatting-mother`

Asked for on 2026-09-01 (playtest 18, finding 4: *"another mother with child. when getting too
close one gets caught up in a conversation that takes 5s and consumes 25% excitement. if the baby
is already sleeping it's a pure time loss if it's not it bears overstimulation risk"*). Built
same-day, seven commits, suite green. The readings that shaped it — "consumes 25%" adds 25 points
awake, "pure" means asleep the chat emits nothing at all — are in the playtest entry and were
implemented exactly: the chat's contribution bypasses `SLEEPING_SENSITIVITY` entirely rather than
scaling through it, because a scaled 13.75 could cross the wake threshold and would not be pure.

The numbers as built: intensity 4.5 over 34/70px (a person-scale ambient field, just over the
passer-by's 4.2), pacing at 26px/s over an 8-tile sidewalk beat, `detain_seconds` 5, `detain_radius`
26 (under the 32px lane spacing, so the far lane of a pavement can never trigger it),
`max_per_day` 2, `first_day` **1** — the balance suite measured green there, so the fallback to
day 2 was never needed. One conversation per instance; afterwards she departs like a `dog_walker`.
The lock zeroes the stroller's input for the duration, so the existing idle rules price the time.
`EventDef` carries the general machinery (`detain_seconds`/`detain_radius`, validated:
detain < inner ≤ outer, never on a `hard_fail` or a pursuer). A `chat` telemetry entry records
position, duration, baby state and what the meter did; the `blocked` watcher is gated on the
detained state so a conversation cannot log as a stall.

**Three rig-building traps found while writing its tests**, each the kind that passes vacuously:
a bare `Stroller.new()` has no `CollisionShape2D`, so `move_and_slide()` never moves it and a
position assertion proves nothing (assert on `velocity`); its baby lookup is by child name, so a
test's `Baby.new()` needs `name = "Baby"` or the awake query silently answers its no-baby default;
and hand-built nodes want explicit `.free()` or the suite reports leaked instances under a green
check count.

## M41 — The shape of the city: a spine, and an edge you can walk to · `feature/the-shape-of-the-city`

See **[docs/PLAYTEST-11.md](PLAYTEST-11.md)**, section C, and **[docs/PLAYTEST-12.md](PLAYTEST-12.md)**,
which is this milestone played while it was still on the branch. Three entries that are one
milestone, because they are the same sentence: **the city has no hierarchy.** Every street is the
same street, the arterials differ only by how many cars are on them, and the map stops at an
invisible wall.

This also closes the half of **M21** left open by decision — *main roads with lights* — and replaces
the earlier "cliff, fences, harbour" sketch with the design the player gave, which is better for the
reason they gave: *"that way it's not an artificial end but an emergent end."*

**All of it is done.** What follows is what each part turned out to be; the corrections marked
*(playtest 12)* are the ones a person found in it the same day.

- [x] **Three kinds of street, told apart at a glance.** A main road — dark asphalt, an unbroken
      double centre line, doubled clearway markings on its kerbs, signalled at every junction and
      **it does not give way to anybody** — against a retail precinct, which is brick from frontage
      to frontage with no kerb and no cars in it, against the ordinary street that is everything
      else. *(Playtest 12, findings 1, 2 and 7: there is **one** main road and it runs north to
      south, and there are **two** precincts of three blocks each, one along the southern shore.
      The first build made one of each per axis, which is three kinds of street and no hierarchy
      among them.)*
      **A wider main road was tried on paper and rejected**, and the reasoning is in `docs/CITY.md`:
      the corridor cross-section is uniform by construction, a 1-tile pavement is the width M1
      found unwalkable, and doubling a carriageway restates the traffic fairness contract for every
      street at once
- [x] **And the ground is a rate, not a category** — *(playtest 12, finding 8)*, the change that
      makes a route a **recovery rate**: calm 2.2, precinct 1.5, ordinary street 1.0, main road 0.6.
      `WorldContext` grows a fourth question, which generalises the half of `is_calm_zone` that was
      never a threshold. It is the first time since M14 that the ground has done anything except be
      calm or not, and it is what makes a precinct worth walking to although it is loud
- [x] **Traffic lights.** The cycle is **derived** from the block spacing rather than authored —
      `2 × SIGNAL_PROGRESSION_BLOCKS` junction-to-junction travelling times — which is what lets a
      green wave run both ways down the same street. Without a progression two thirds of the traffic
      stands still at any instant, measured. **The "both ways" half of that is wrong and M46
      measured it: the wave serves one direction and cannot serve two on this geometry.** The side
      street's green is the fairness contract
      (`Tuning.validate_signals`), because she crosses a main road while the main road is red; the
      amber is a clearance period, not a warning. *(Playtest 12, finding 4: the four heads at a
      junction are now two drawings — face-on for the arms running up and down the screen, edge-on
      for the ones running across it, so what you can see of the lamp is which street it means.)*
- [x] **A tunnel north, a bridge south, and the main road running out east and west**, plus a ring
      of frontages one block deep outside the whole boundary — and **the camera may see past the
      map**, which it could not, and which is why the edge would have gone on looking like a wall
      however much was built out there. The lattice already ended in T-junctions and nobody could
      see it: the outermost corridor is a whole street and every interior street runs into it and
      stops. No walkable tile moved
- [x] **Cars do not enter a junction they cannot leave.** Measured before: **3,776 overlapping
      crossing-axis pairs in ninety seconds of the arterial, one in half of all frames, the deepest
      39px into a 40px footprint** — with every assertion about the traffic passing throughout,
      because each car's own *lane* was legal. Four clauses, all load-bearing, in `CLAUDE.md`. The
      one that decides whether a grid queues or seizes is *nothing enters a box it cannot leave*
- [x] **And a car that does enter an occupied box is an accident** — built as the M19 mechanism
      rather than as a catalogue row: it **startles the cars it happened to**, so it is loud where
      it happened and composes by addition like every other body. Deliberate: with the box rationed
      it happens under one frame in twenty of the busiest street in the city, and an event nobody
      meets in a run is a silhouette and a fairness contract spent on decoration
- [x] **11×11.** *(Playtest 12, finding 9.)* The first resize taken for room rather than for a rule.
      The act I caps went up with it — a budget the catalogue cannot spend is not density (M28) —
      and the suite went from 96s to ~160s, which is the price of 49% more city
- [x] **Judged by eye.** Screenshots of all three kinds of street, a signalled junction across the
      cycle, the promenade, and all three exits. Two things were only visible that way: the tunnel
      opening into the void beyond the frontages, and the four identical signal heads at a junction
- [x] **And every route guarantee re-measured, not assumed.** Nothing moved a walkable tile, which
      is why `tests/test_blocks.gd` and `tests/test_routes.gd` are the measurement rather than a
      hope: a precinct is paving where pavement was, a main road is paint, and an exit is the last
      stretch of a street that was already there

### What playtest 12 changed on top of that

- [x] **One main road, north to south** — finding 2
- [x] **Two precincts of three blocks, one on the shore** — findings 1 and 7, and they are retail:
      `PRECINCT_BUSYNESS` for the foot traffic, `EVENT_PRECINCT_WEIGHT` for the cafés and stalls
- [x] **Walkers use the whole width of a precinct** — finding 1's *"people seem to not go in the
      middle"*, which was right and was not a steering bug: the middle two offsets are the
      carriageway on every other street, so nothing had ever been placed there
- [x] **The spine carries forty cars** — finding 3. It was not that thirty was too few; it was that
      there were two main roads and the weighting split between them. One spine is blocked 81% of
      the time
- [x] **Calm areas: one per day of the longest act, plus one** — finding 5, and the spoiler
      remembers the whole **act** rather than the night before, resetting when the act turns. One
      night's memory makes day 2 a fresh decision and day 3 the same decision as day 1
- [x] **Calm ground fills the meter 20% faster again** — finding 6, `SLEEPINESS_CALM_ZONE_MULTIPLIER`
      12 → 14

### The old plan, for what it said

- [ ] **Two kinds of street, told apart at a glance.** A main road — wide, fast, heavily trafficked,
      signalled — against an ordinary or pedestrianised street that is slow, crowded and has no cars
      in it. The point is not decoration: with one kind of street the route decision is only *which
      way*, and with two it is also *which kind*, which is the trade the whole game is made of. It
      needs a visual difference that reads without a legend
- [ ] **Traffic lights.** A signalled crossing is a **timing** problem where a zebra is a gap-hunting
      one, and it is the honest counterpart to *"the arterial has a safe gap about one time in
      twenty"*. Re-measure the mean wait at a kerb afterwards; that number is the whole of whether an
      arterial is crossable
- [ ] **A tunnel north, a bridge south, and the main road running out east and west.** One of each,
      carrying the spine off the map. **Walkable, and fatal when a car comes** — not a special case,
      just the traffic fairness contract on a stretch of carriageway with no pavement beside it. The
      player walks out of the world rather than being stopped by a wall
- [ ] **T-intersections everywhere else on the edge.** The lattice currently runs into the boundary
      and stops. A T says the street turns rather than being cut off
- [ ] **Cars do not enter a junction they cannot leave.** M38 made a car turning into an occupied
      *lane* look first (`TrafficIndex`); the **junction box** was never modelled, so two cars on
      crossing arms both see a clear lane ahead and both enter, and the positional resolve then does
      the only thing it can — move a body. Same shape as M38's fix, plus the thing a junction needs
      that a lane does not: a **priority rule.** Right-before-left, which settles the symmetric case
      without a negotiation; lights override it where they exist
- [ ] **And a car that does enter an occupied box is an accident**, which is an event, not a
      collision to be resolved away. Deliberate, and worth building rather than losing
- [ ] **Judged by eye.** A headless run never calls `_draw()`. Screenshots of both kinds of street,
      a signalled crossing, all four edges, and a junction under load, on several seeds
- [ ] **And every route guarantee is re-measured, not assumed.** Three walkable exits move the
      walkable set, which `tests/test_blocks.gd` asserts is identical tile for tile across every seed
      and block arc. A route that leaves through a tunnel must not count as a route to a calm area

## M42 — A city with a middle · `feature/a-city-with-a-middle`

Playtest 11, finding 4, asked as a question in playtest 10 and as an instruction now: *"let's make
the home be the center (with an odd number of rows/cols blocks) mandatory. I spawn too often at the
edge leaving only a few ways into the rest of the city."*

**The diagnosis is that two existing rules compete for the same thing.** The city is already odd at
7×7 and `_place_home` already sorts candidate blocks by distance to the centre; what walks the home
outward is `MIN_HOME_TO_PARK_TILES` = 30, and the centre of a 7×7 city is rarely 30 tiles from every
park. Both rules are about the same thing — the walk out has to be long enough to matter — and at
7×7 they cannot both hold.

- [x] **9×9.** Odd, and large enough that a central home is still a long walk from calm ground.
      Acceptance test: `MIN_HOME_TO_PARK_TILES` satisfied from a block within one of the centre, over
      200 seeds
- [x] **Re-measure every density number in `docs/PLAYTEST-04.md`.** 65% more blocks, one event per
      block since M28, and a crowd that is a field around the player since M27 — so placed per day,
      live inside the stream radius, on screen at once, and met on a route all move, and the budget
      with them. This is why it is a milestone and not a constant
- [ ] **And check what a wheel does to the return phase**, which playtest 03 already called a
      formality. Four ways out is four ways back

**Measured, ten seeds** — and this is the only copy of the table, since `docs/CITY.md` keeps the
rule rather than the 7×7-versus-9×9 comparison. Home offset from centre
1.97 blocks → **0.00**, central in 4/10 → **10/10**, calm areas lying in 2.9 of 4 directions → **3.7
of 4**, and directions with real city behind them 3.4 of 4 → **4.0 of 4**. The 30-tile guarantee got
*better* rather than worse — 32.0 tiles at 9/10 seeds → 39.4 at 10/10 — because the clearance rule
replaced the walk-outward rule. Events per block on day 1: 0.97 → **0.94**, which is the number that
had to not move, and `budget_for()` is stated per block now so it cannot drift on the next resize.

**One thing this changed and did not measure**, recorded in `docs/CITY.md`: the crowd is a field of
fixed population in a fixed-size box clamped to the city, so a doorstep at the boundary had the same
agents spread over fewer streets. A central doorstep should therefore be *thinner* per street, which
is the opposite direction from the open difficulty question — and it wants the crowd milestone's own
measurements rather than an assumption.

## M43 — Things that are in the way of nothing · `feature/in-the-way-of-nothing`

Playtest 11's remaining findings. See **[docs/PLAYTEST-11.md](PLAYTEST-11.md)**. The sentence under
the first three: **several things in this city are placed without asking what they are in the way
of** — which is `CLAUDE.md`'s first rule failing at *placement* rather than at design.

**Where it stands: three done, two answered by measuring rather than by building, and the two that
needed a played run have now had one.** Playtest 13 answered both — the cool-off is the wrong
*quantity* rather than the wrong constant, and dying at high excitement on a quiet street is the
crowd milestone — and added one more to this milestone, the day-4 dog. What follows is the plan
with what each part turned out to be.

- [x] **Nothing is placed on the home block** — finding 1. It is `ClosurePlanner`'s exemption
      applied to the other thing in the game that occupies ground, and it is stated over the
      **street segment** rather than a radius, because a segment is the unit the player can see the
      shape of and it ends at the junction where the choice is made. Measured before the change,
      eight seeds over days 1, 3, 7 and 14: **0.47 events a day** stood on the street outside the
      front door — one morning in two — and it is 0.00 after, with events placed per day unchanged
      at 155.9. The share was exactly the share of the pavement that street is (0.30% of both),
      which is placement being uniform and is why it needed a rule rather than a weighting
- [x] **The diagonal zzz comes back down** — finding 9, and see the entry further down
- [x] **The dog stands its ground** — finding 3's first half, and see the entry further down. What
      it left open is the number, and that is the decision below
- [ ] **A closure has to change a route** — finding 2, *"road blocks next to parks are pointless"*.
      The route-redundancy invariant is used as a **floor** (the day stays winnable two ways) and
      never as a **filter**: a closure that does not lengthen the best route to any calm area by a
      real margin is legal, invisible and pointless. Measure what fraction of today's closures do
      nothing before choosing the margin

      **Measured, and the filter is not the answer — there is nothing to filter to.** Ten seeds,
      fourteen days, 350 closures, each measured against the set accepted before it:

      | what it changed | share |
      |---|---|
      | streets on the best route to the nearest calm area | **+0 for 100%** (1 closure of 350 added one) |
      | streets on the best route to *any* calm area | **+0 for 97%** |
      | tiles actually walked from the door to the nearest calm ground | **+0 for 99%** (the worst four added 1, 2, 6 and 6) |

      Then the question the filter would have to answer: **of every street in three whole cities,
      how many would lengthen the walk at all if they were the day's only closure? Eight of 768** —
      and three of those eight seal the city off entirely, which the invariant already refuses. A
      *run* of consecutive streets is no better: 11 of 534 four-street runs move the number.

      The cause is structural rather than a bug, and it is the city that moved. A Manhattan lattice
      has many equal-length staircases between any two points, so removing one street almost never
      lengthens anything — and the city now has **8.9 calm areas** with the nearest **38.8 tiles**
      from the door, so there is always another destination in another direction. M16 built closures
      for a 7x7 city with far fewer parks in it. **A closure cannot change a route while there are
      nine destinations and a full grid**, and no margin, filter or run length fixes that.

      **Deferred to M45, with the design taken.** The answer is not a filter and not a margin: it
      is that the question was wrong. A closure's job is **direction, not distance** — see M45
- [ ] **A busker in a courtyard denies the courtyard** — finding 5, *"I can still walk around (and
      over him) while the sleepiness meter goes up"*. Two halves and both are arithmetic. **Around:**
      what denies calm ground is out-emitting the 7.7/s decay the calm multiplier has already raised,
      which is what `EventScheduler._denial_radius()` exists to compute — this is the third row to be
      caught by that sum (the busker in playtest 08, the playground in playtest 10). The suspicion is
      that a courtyard, the smallest calm area, gets a spoiler grid of one. **Over:** anything mobile
      is exempt from *solid things are solid*, and `EventDef.paces` made the pacing man mobile. Both
      need measuring before either is moved

      **Measured, and both halves come back negative on `main`.** Eight seeds, three days, every
      calm area spoiled in turn, counting a tile as denied when what the day emits there beats the
      calm decay:

      | calm area | denied | things in it | of them solid |
      |---|---|---|---|
      | courtyard, 16 tiles | **100%** | 1.0 | 1.0 |
      | one block, 64 tiles | **100%** | 3.4 | 3.1 |
      | four-block zone, 484 tiles | **98%** | 9.9 | 9.7 |

      So the suspicion is wrong in the most useful way: **a courtyard does get a grid of one, and
      one is the right number** — a busker's denial radius is 100px and a 16-tile courtyard is 128px
      across, so one of him covers it. M35's crowd and M41's act-long memory closed the "around"
      half between them. And the "over" half is a case of *check which event a complaint is about*
      (the M34 lesson): the **busker has a body** (`PERSON_BODY`) and does not pace. The only row in
      the catalogue that paces is `homeless_yeller`, which is mobile **by decision** — playtest 09
      asked for it by name, and mobile things have no body since M19. What is left of this finding
      is therefore not arithmetic at all: it is whether a *paced* man in a park should be walkable
      through, which is the `dog_walker` bargain and is already in the known-shaky list
- [x] **The dog stands its ground, and lunges on proximity rather than on a clock** — finding 3,
      *"it should be still"*. It reverses because it reaches its stand-off in a third of a second and
      then has two more seconds of telegraph to spend while she walks into it. *Standing still* alone
      is the thing M35 rejected and was right to: she then reaches it **before** the clock lets it
      fire, and it kills her from a standing start. Firing the lunge when she comes inside the
      stand-off — or when the telegraph runs out, whichever is first — gives both: it never reverses,
      and the chase always starts at the stand-off, which is the whole content of the contract.
      **`PURSUIT_MIN_NOTICE` has to be re-decided with it**: a player who walks straight in then gets
      about 1.2s of visible dog against a 1.5s floor that was authored rather than derived. Siting it
      further out is capped by the screen — 360px tall, so past ~180px a dog telegraphing north or
      south of her is off the top of it

      **Built, and it does what was asked: the reversing is gone and every lunge starts at the
      stand-off.** Walked on a rig, four ways of meeting it, sited at 184px against a 104px
      stand-off:

      | she | notice | lunges at | reverses |
      |---|---|---|---|
      | walks straight in | **0.38s** | 100px | 0.0px |
      | stands still | 0.63s | 102px | 0.0px |
      | walks away | 2.42s (the clock, not her) | 103px | 0.0px |
      | runs away at once | never lunges | — | it gives up at 1.5s |

      **And the estimate above was three times too generous, which is the part that matters.** The
      notice is not 1.2s, it is **0.38s**, and the arithmetic says it cannot be much more: she is
      walking *into* it at 92px/s while it comes at 130, so the 80px between where the director
      sites it and where it stops close at 222px/s. Siting it at the screen's own cap
      (`SIGHT_AHEAD`, 200px) buys 0.43s. Nothing reaches the 1.5s floor from that geometry.

      The floor still **passes on load**, because `validate_pursuit` reads `telegraph_time` off the
      def and the def still says 2.4 — which is M35's lesson arriving for the third time: *a
      fairness contract stated in seconds is not stated at all*, and the encounter changed while
      every line about it stayed true.

      **Decided: buy back what the geometry can, and leave the floor alone.** A pursuer is sited at
      `Tuning.SIGHT_AHEAD` (200px) now rather than at the clamp that produced 184 — the cat's
      reaction window was never a chase's, and everything between the siting and the stand-off is
      the whole of the notice a pursuit has left to give. It buys **0.38s → 0.43s**, and it is all
      that is available: the visible world is 360px tall and a dog telegraphing off the top of the
      screen has no telegraph at all.

      **Still open, and written down rather than quietly closed:** `PURSUIT_MIN_NOTICE` is 1.5s and
      the walk pays 0.43s, so the constant is a statement about `telegraph_time` and not about the
      encounter. What makes that survivable rather than a lie is that the *contract* was never the
      floor — it is `pursuit_standoff()`, which every lunge now starts at, so she is owed
      `PURSUIT_REACTION` from the moment it can touch her whatever she did to get there. The next
      person to touch this should state the notice **over the walk** and assert it with a rig, and
      the two ways to widen it both cost something: a narrower stand-off spends the reaction window
      at the lunge, and there is no more screen
- [ ] **And the cool-off is played, not re-derived** — finding 6. `Tuning.PURSUIT_SHAKEN_OFF` landed
      in M39, after this report was taken: 0.8s of the gap opening, and the measured price of the
      answer went from ~35 points to **12**. If it still reads as slow it is one constant

      **Played, and it is not one constant — it is the wrong quantity.** *(Playtest 13, finding 6:
      "the dog doesn't stop fast enough on day 3 — we talked about this! when running the pursuit
      should stop quickly — it **only** should keep going if the player doesn't run.")* Two chases
      in the trace lasted **5.4s**, nearly twice `PURSUIT_TIME`, while she was running for most of
      them; the first turned a meter reading 9 into a meter reading 95 and ended the day.

      | day | chase lasted | she ran | it cost |
      |---|---:|---:|---|
      | 3, attempt 1 | **5.4s** | 3.2s | exc 9 → 95, lost the day |
      | 3, attempt 4 | **5.4s** | 2.1s | exc 16 → 66 |

      The cause is that `_outrun_for` needs **0.8 continuous seconds** of the gap opening and any
      frame that does not open it resets the timer to zero. A real player does not hold a key down
      for a clean 0.8s: she ran in four separate bursts — 1.2s, 0.5s, 1.4s, 0.4s — and every gap
      between them put the counter back. Worse, the first `(WALK_SPEED + RUN_SPEED) / ACCELERATION`
      of every burst is spent turning round, during which the gap is still **closing**, so a 1.2s
      burst can contain well under 0.8s of opening.

      **So the break-off condition becomes *she is running away from it*, read directly.** M39's
      rate framing was the right fix for a different complaint and its guarantee still holds —
      *only running can open the gap*, so walking cannot fake it — but it buys that guarantee by
      measuring the **consequence** of running rather than running itself, and the consequence is
      polluted by acceleration, by diagonals and by a player who lets go of shift. Reading the
      state gives the same guarantee with none of the noise, and makes the player's sentence true.

      Two things must not be lost with it, both already written down: the chase may not end before
      it has been a threat (`PURSUIT_MIN_NOTICE` is the floor), and **walking away must never work
      at any distance** — the M36 trap, where a trigger sitting at the break-off distance let a rig
      stroll away from a robber every time
- [ ] **The tutorial dog is not a tutorial after day 3** — playtest 13, finding 8, *"I had a
      tutorial pursuing dog on day 4 — that should not happen"*. `charging_dog` is `first_day 3`
      with `spawn_mode = AHEAD_OF_PLAYER` and no last day, so the scheduler goes on placing it
      (three on day 4 of the trace) and the director goes on siting it in front of her, in the
      identical presentation to the day-3 lesson: `ahead charging_dog comes at her from 200px in
      front of her`. `_ensure_the_run_is_taught()` is correctly gated to `RUN_TAUGHT_DAY`; the row
      underneath it is gated to nothing.

      **Decided: it recurs, but is not sited ahead of her.** `AHEAD_OF_PLAYER` is for *"the small
      number whose entire content is the moment it happens to you"*, and after day 3 that is
      exactly what a charging dog stops being — the lesson is over and the row becomes a hazard
      with a place. `alley_robbery` is the shape: `pursues_within`, a thing that is *somewhere*,
      that can be seen and priced and routed around, and that becomes a chase if she walks up to
      it. Two constraints: a `MAP`-placed pursuer needs a `pursues_within` or it can never trigger
      at all, and `validate_pursuit`'s third clause puts that trigger inside `PURSUIT_BREAK_OFF`;
      and **day 3 keeps the placement it has**, because the lesson depends on being unavoidable
- [ ] **Dying at high excitement on a quiet street** — finding 8, and read the trace before touching
      anything.

      **Playtest 13's trace is that read, and the answer is the first of the three suspects: this
      finding *is* the crowd milestone.** The losing line is
      `lost_crying after 29.4s … exc 100, in 24.6/s (crowd 24.6, events 0.0)`, with the nearest
      catalogue row 272px away and out of range — playtest 10's own shape, one milestone later. It
      is **M46**, and this entry closes into it rather than being answered here. The other two
      suspects stay open and are cheap to check while M46 is being measured: whether the pram's
      `EXCITEMENT_NEARLY_CRYING` cue is shown and not read, and whether one contact at 90 is a
      cliff — at 22–34 points a second a single bump above ~89 ends the day on an empty street, and
      the trace has fifteen bumps in four days.

      What the entry said before the read, kept because the reasoning still holds and is now
      M46's: the strongest suspect is the **recovery**, and it is a rule taken on purpose —
      `EXCITEMENT_DECAY_IDLE` is 0.0, so above the calm threshold the only way down is walking
      somewhere quieter at 3.5/s — on a quiet street the meter sits where it is and any small source
      is a net climb with no floor under it. Three things to measure first: what the `lost` line's own
      `crowd X, events Y` breakdown says (if it reads like playtest 10's, this finding *is* the crowd
      milestone); whether the pram's `EXCITEMENT_NEARLY_CRYING` cue is being shown and not read; and
      whether **one contact at 90 is a cliff** — a pedestrian contact is ~10.8 points, so above 89 a
      single bump on an empty street ends the day. The first of the three is what the trace
      answered
- [x] **The diagonal zzz comes back down** — finding 9. `baby_cue_lift()` caught the diagonals
      because both cues asked *which axis is she mostly facing*, and that answer puts a diagonal on
      the vertical side of the line. It is one question now — `Stroller._pram_shares_her_column()`
      — and it is asked as **geometry**: `pram_offset` carries `facing.x` at full `PRAM_DISTANCE`,
      so the pram is 24px to one side on a diagonal and 34 on a due east or west, and only a due
      north or south leaves it in her column. That is six of the eight facings both cues have
      nothing to do on, where the axis test said four.

      It is a distance rather than `absf(facing.x) > absf(facing.y)` for a second reason worth
      keeping: `_turn_toward` rotates by an angle and normalises, so on a diagonal the two
      components are equal only to within float noise, and a strict comparison between them would
      have let the cue flicker between two positions while she walked in a straight line. This cue
      has been adjusted in M32, M37, M39 and now M43, and each of the last three was a facing the
      previous fix had not been asked about — so `tests/test_danger.gd` holds **all eight** now

### The two decisions this milestone could not take on its own

Both were taken in the session, and the first of them turned into a milestone of its own.

**~~What a closure is for.~~ Taken, and it is M45.** The measurement said no filter, margin or run
length can make a single closed street change a route, and the answer to that is not a better
closure — it is that *lengthening the route was never the job*. See **M45**.

**~~What notice a lethal thing owes when you walk into it.~~ Taken: site it at the screen edge.**
`SIGHT_AHEAD` rather than the 184px clamp, which buys 0.38s → 0.43s and is everything the geometry
has. The floor was deliberately left where it is; see the entry above for what that leaves open,
and the standing instruction that comes with it — a notice has to be **stated over the walk** and
asserted by a rig, or it will go on passing while the encounter changes underneath it.

## M44 — A suite you can run · `feature/a-suite-you-can-run`

**8.4 minutes to 96 seconds, with one check more than it started with.** The suite is the thing this
project checks most often, and at eight minutes it had stopped being run after each change and
started being run at the end — which tells you *that* something broke rather than *what*. M42's
larger lattice is what surfaced it: 7×7 to 9×9 took the suite from ~110s to 8.4 minutes, four times
the cost for 65% more city, and everything below was already there and already growing.

**The entry that asked for this proposed four things and every one of them was wrong**, which is the
part worth carrying. It guessed at cached maps, smaller seed sweeps, a fast/slow split and duplicated
per-day checks; the four suites it named as 90% of the cost were the right suites for the wrong
reason. Half an hour of a throwaway probe found something else entirely, and none of it cost a check.
**Time a thing before you speed it up** is a rule this project already applies to balance constants,
and it applies to its own tooling the same way.

- [x] **A rig that steps the parts is not running the whole** — 240 of the 495 seconds, inside a
      single test. `test_balance`'s day on the arterial walked the crowd by hand (`for agent in
      crowd.agents(): agent._process(step)`) and skipped the frame around them, so nothing ever
      rebuilt `TrafficIndex` — and `claim()` is written to be thrown away once a frame, so every
      recycle stayed. **64,796 cars in nineteen lanes after three thousand frames**, each one scanned
      six times per recycle, growing quadratically for the rest of the day. `Crowd.step()` is the
      whole frame and is what a rig calls now: 3.94 ms/frame at frame three thousand → **1.09**.

      **And it was not only slow, it was wrong**, which is why this is not a speed fix.
      `test_balance` and most of `test_crowd` were measuring a road with no separation pass on it
      while claiming to measure the real world. `tests/test_crowd.gd` now asserts the index holds
      exactly one entry per car, so the pathology cannot come back quietly — it never could have
      been seen otherwise, because a lane full of cars that left an hour ago is still a legal lane
- [x] **A cache whose lifetime is not stated is recomputed** — `EventScheduler._place_one` filtered
      every sidewalk tile in the city (five thousand of them, twice over) to find where an event may
      stand, and `_fill_with_recurring` asks that question **once per attempt** — over four hundred
      times on a fourteenth day. Nothing it depends on can move inside one `build_day`: the grid is
      repainted at dawn and the day's closures are already down. `_ground_for()` computes it once per
      distinct *question* — placement types plus side of the street, which most of the catalogue
      answers identically — threaded through the day rather than kept on the map, because a cache
      with a shorter life than its invalidation rule is the next bug. **`build_day` 515 → 71 ms**
- [x] **A `Vector2i`-keyed dictionary hashes a Variant per lookup** — `walk_distances` was the
      most-run arithmetic in the project (twice per generation attempt, once per day planned) and it
      asked a Dictionary about fifty thousand times what the tile grid answers by index.
      `CityMap.walk_field()` is the same sweep over a flat `PackedInt32Array`, with `blocked` painted
      into the grid before it starts rather than asked about per neighbour, and the four steps
      written out because the loop's own bounds test costs more than the arithmetic it guards.
      **16.3 → 4.5 ms.** `calm_tiles` and `count_walkable` lost their per-tile calls to the same
      pair of lookup tables — **8.9 → 0.6 ms**
- [x] **`CityGenerator.validate` does its cheap checks first** — it runs on every attempt, a third
      of them fail, and it opened with the two full sweeps of the map. A rejection that can be seen
      by counting calm blocks must not walk eleven thousand tiles twice first, and now does not walk
      them at all. Which reason comes back when several are true changes; whether a map is accepted
      does not. **`validate` on a map that passes 57.5 → 10.5 ms, and `generate` — 1.65 attempts of
      it, on average — 124.7 → 46.2 ms**
- [x] **`tools/test.sh crowd balance`** — the inner loop is now seconds. A filtered run prints
      `PARTIAL RUN` under its count, because a partial pass that reads like a green build is worse
      than no filter at all

| suite | before | after |
| --- | ---: | ---: |
| `test_balance.gd` | 255.1s | **25.6s** |
| `test_events.gd` | 74.6s | 12.7s |
| `test_crowd.gd` | 69.2s | 25.3s |
| `test_generator.gd` | 42.5s | 15.7s |
| `test_full_run.gd` | 18.8s | 4.4s |
| `test_telemetry.gd` | 12.6s | 2.1s |
| everything else, together | 22.2s | 10.3s |
| **whole suite** | **495s** | **96s** |

**What was deliberately not done.** No check was cut and no seed sweep shortened — every number
above is the same work done differently, which is why the count went *up* by one rather than down.
No map is cached across suites: a `CityMap` is mutable by design (a block arc repaints it, a day
closes streets on it) and sharing one between suites buys about seven seconds in exchange for a test
whose result depends on what ran before it. And `Crowd.step()` is the whole crowd frame minus the
player half — `_bump`, `_make_way`, `_strike`, `_horn` — which a rig with a stationary player would
also now be able to run. Whether `test_balance` *should* run it is a real question about what that
suite measures, and it is a design question rather than a speed one.

## M45 — A grid with fewer ways through, and closures that point · `feature/closures-that-point`

Not started. Taken as a design instruction in the M43 session, in answer to the measurement in
M43's closure entry above — read that first, because it is what makes this a milestone rather than
a tuning pass.

**The one sentence: a closure was being asked to lengthen a route, and lengthening a route is not
what it is for.** What it is for is *direction* — stopping a player from committing to a way that
cannot win today — and the reason it cannot even do that at the moment is that the city has no
shape to work with: 8 streets of 768 could lengthen the walk if closed alone, 11 of 534 four-street
runs, because a Manhattan lattice has many equal-length staircases and there are 8.9 calm areas
scattered across it.

The design, as given:

> *"In the beginning the player has a lot of freedom to find calm areas. As the game goes on the
> choices go down making it harder to find the calm areas. That causes an issue that later the
> player might walk into the wrong direction first making them not find the last remaining calm
> area in the time given. Closures can come in two ways: 1) a permanent restriction in the city's
> grid — we should have impassable blocks that are not technically a closure but just the city's
> layout, e.g. a cul-de-sac or a scrapyard, a city feature that naturally breaks up the grid; 2) an
> existing road gets closed later in the game for one or more days. 1) is to reduce the total
> number of valid paths making the graph less open. 2) is to guide the player to remaining calm
> zones — those closures should be placed to prevent the player from walking in a wrong,
> unwinnable direction. The goal is to guide/nudge the player to go into the right direction. This
> can be hard (full closure) or soft (multiple events forcing the player to turn around)."*

### The three parts

- [ ] **A city that is not a full grid, permanently.** Impassable blocks that are the *layout*
      rather than an event: a cul-de-sac, a scrapyard, a depot. They are what makes every route
      question downstream answerable at all — with a full lattice, no closure, cut or run of
      closures can change a route, which is measured rather than argued.

      **The mechanism already exists and should be reused rather than reinvented.** M21's calm
      zones absorb the streets between their own blocks: `CityMap.absent_segments` is the set of
      streets this city does not have, and `blocked_segments()` merges it with today's closures for
      **every** route search in the game. A permanent restriction is more absent segments plus
      ground that is not walkable — the same shape, decided at generation, fixed for the run.

      Four things it has to keep true, and each already has a test that will say so: route
      redundancy on day 0 (`StreetNetwork.route_count() >= 2` to two distinct calm areas — the
      thing M21 made true by search rather than by construction); no purpose change may move a
      walkable tile (`tests/test_blocks.gd`); the home's doorstep street stays reachable; and the
      crowd's lanes have to stop at whatever the new edge is, which is the M41 boundary problem one
      scale in — the lattice already ends in T-junctions at the map edge, and a cul-de-sac is that
      shape happening inside the city
- [ ] **A closure that points.** The acceptance test changes from *"does this lengthen the best
      route"*, which nothing can satisfy, to *"does this stop her committing to a direction that
      cannot win today"*. The information to do it already exists at dawn: `build_day` knows which
      calm areas are spoiled and `_ensure_one_usable_park` knows which one is protected, so the
      day knows which way is a wasted journey before the player takes a step.

      The trap to avoid, and it is the whole difficulty of this part: **a nudge that removes the
      decision is worse than a closure that does nothing.** The game's one verb is *where do I
      walk*; a day that fences her into the only right answer has taken the verb away. So this is a
      barrier on the way to somewhere unusable, not a corridor to somewhere usable, and the
      two-distinct-routes invariant stays exactly where it is
- [ ] **And a soft version, which is events rather than barriers.** *"Multiple events forcing the
      player to turn around."* The pieces are all there — `obstructs_radius` since M34, the spacing
      rules since M28, the density since M41 — and what is missing is the **intent**: nothing in
      `EventScheduler` has ever placed events in order to say *not this way*. Worth building second
      and measuring against the hard version, because a soft nudge she can push through is the one
      that keeps the decision hers

### The open question underneath it

**How fast should the choices narrow, and does `MIN_CALM_BLOCKS` survive it?** The narrowing is
half-built already and by a different mechanism: since M41 the park spoiler remembers **the whole
act** and resets when the act turns, so choice narrows within an act and is handed back at the
boundary. This design wants it to narrow across the *run*. `MIN_CALM_BLOCKS` is currently sized as
one per day of the longest act plus one, precisely so that the spoiler can never leave her with
nowhere to go — that sizing is playtest 12 finding 5 and it is the thing this would push against.
Decide it with a measurement, not an argument: the number that matters is how far the *last*
remaining calm area is from the door on the last day of an act, against the 180s she has.

**Absorbed into M47.** The two halves that are still open here — permanent restrictions and
closures that point — need the same machinery as playtest 13's bigger calm areas, and building
`absent_segments` twice is how the second one goes quietly wrong. The design above stands
unchanged and is the second half of M47; read it there.

## M46 — The crowd is not the game · `feature/the-crowd-is-not-the-game`

**Done.** Playtest 13's finding 1 — *"just walking around now increases excitement — this is
bad"* — which is playtest 07's finding 17 and playtest 10's *"the thing nobody reported"*, found
for the third time and said out loud for the first. See
**[docs/PLAYTEST-13.md](PLAYTEST-13.md)**.

**What it came to, in one paragraph.** Almost every item was answered by measuring rather than by
arguing, and four of them came back the opposite of what the item predicted. The crowd was not too
loud: an ordinary footway is **net recovery to walk**, and what is expensive is **standing**, which
is `EXCITEMENT_DECAY_IDLE` being 0 and stays that way for two measured reasons. The careful line was
not gone, it was **four pixels wide** — widened to twenty by moving the pavement's lanes apart, not
by shrinking the body — and that closed the separate problem that contacts and noise had been
pricing the same choice in opposite directions. The main road was quiet because a weighting could
not cross a split something upstream had already made, and it is a soft block now at about a third
of the meter to cross. And the green wave, which the docs had said served both directions since M41,
**serves one and arithmetically cannot serve two**. The population was honest, the box was not, and
the cost table did not move at all.

**The one sentence: the crowd is supplying almost all of the difficulty, and every authored system
in the game is being judged through it.** A day was lost in 29.4s reading `crowd 24.6, events
0.0`, with the nearest catalogue row out of range; the freeze threshold is reached within ten
seconds of the doorstep on **all five** attempts that got that far; and standing still for three
seconds on an ordinary pavement is worth eight points.

**What this must not become.** The noise floor is emergent, never a constant — that is an
invariant and it stays. *"The crowd is expensive to be careless in and free to be careful in"* is
the ratio the whole design rests on, and the finding is that **the careful line has stopped
existing**, not that the crowd is loud. M33 already measured the line away (eleven contacts down a
lane centre against one on the midline became thirteen against fifteen) and answered with a
behaviour — people step aside. Fifteen contacts in four days says the behaviour is not carrying it.

- [x] **Measure before touching anything, and measure the four things separately.** Playtest 04's
      recipe, re-run on `main`: contacts in forty seconds walked down a lane centre *against*
      forty seconds holding the midline, the mean crowd contribution at a standing point on
      ordinary / precinct / main-road pavement over a real minute, and the share of a losing day's
      excitement that came from the crowd. The ratio is the finding, not either number

      **Measured, and one of the four came back the opposite of what was feared.** Five seeds,
      act I, focused on the point being measured:

      | | value | against a 3.5/s walking decay |
      |---|---:|---|
      | ordinary corridors, standing | mean **5.82**, median 5.62 | **44 of 55 beat the decay** |
      | main road, standing | mean 11.90 | all five |
      | precinct, standing | 5.75 | net +0.50 after its 1.5x ground |
      | contacts, 40s down a lane centre | **73** | |
      | contacts, 40s on the midline | **5** | |

      So a typical ordinary street is **+2.1/s while walking and +5.8/s while standing** — 100
      points in 48 seconds of pavement with nothing authored anywhere near her, which is finding 1
      exactly. But **the careful line is not gone**: 73 against 5 is a ratio of **14.6:1**, better
      than the 11:1 M19 built the crowd on. `CLAUDE.md` has said since M33 that the ratio was
      measured away (13 against 15) and it is wrong — M41's crowd changes brought it back and
      nobody re-measured. **The finding is that the careful line is invisible, not that it is
      absent**: nothing tells a player that walking sixteen pixels to one side costs fourteen times
      less
- [x] **And the one test pinning the floor was measuring an empty street.** Found while measuring
      the above, and it is M44's lesson in the place it does the most damage.
      `_test_a_busy_street_never_lets_the_meter_fall` called `start_day(1, rng)` with **no focus**,
      which parks the crowd field on the map centre, and then measured at `quietest_pavement` —
      whichever north-south corridor the city made quietest, **1968px from that centre on seed
      4242**. Measured: **zero agents within 400px.** So *"a back street is somewhere she can
      recover"* was 0.00 against a decay of 3.50, and *"the arterial is a different place"* was
      7.58 against 0.00. **Three of that test's four checks were passing against a road with
      nobody on it**, and the fourth — the ceiling — was passing only because focusing the field
      is what pushes the arterial from 7.58 to 11.55, which is already over it.

      The crowd is a population of the box around the player, so **a floor is only a floor where
      she is standing**. `_floor_on()` focuses it
- [x] **The main road is the quietest thing in the city, and it is two defects** — finding 7's
      first half, done. `CrowdLanes.busyness` still weighted the middle corridor of *each* axis at
      `ARTERIAL_BUSYNESS` while `CityMap.main_road` is one vertical corridor, so the phantom
      east-west arterial held **14.6 cars against the spine's 11.2**. And underneath it,
      `_choose_lane` picked the axis 50/50 **before** the corridor, so no weight could ever put
      more than half the traffic on one north-south street.

      Both fixed: the spine holds **15.4 cars** and crossing it costs **~35 of the 100 meter**,
      worst of eight crossings — which is finding 7's *second* half arriving for free, because a
      third of the meter to cross is precisely the **soft block** that was asked for.

      Three things came with it. `CROWD_CARS_PER_ACT` went **40 → 34** (act II 30 → 26), because
      the concentrated spine put junction contention over the rate `test_crowd` allows: the car
      number is a capacity number now, and the honest answer to *"the main road is too quiet"* was
      fewer cars for the second time. The arterial ceiling is **stated over the crossing** rather
      than over the standing floor — a proxy that came apart the moment the spine got its traffic,
      and M35's *state it over the walk* arriving in the crowd's half of the game. And a car handed
      a corridor whose visible stretch is all precinct re-rolled its position eight times, found
      bollards every time, and was placed among them anyway: **a retry is not a guarantee, one
      scale out**, so `CrowdAgent.setup` re-picks the street rather than only the spot on it
- [x] **`EXCITEMENT_DECAY_IDLE` is 0.0 and there is no floor under her on ordinary ground.** M33
      set it there for a good reason — *what settles a baby is being pushed* — and the consequence
      nobody priced is that a stationary pram on a pavement is a pure climb at whatever the crowd
      is doing. Decide whether "standing still settles nothing" should mean "standing still is
      worse than walking", which is what it currently means.

      **Decided: it stays 0.0, and the question was pointing at the wrong number.** Two measured
      reasons, and the second is the one that was nearly missed.

      **It is not the lever for the case that matters.** The place the game *makes* her stand
      still is the kerb of the main road, waiting for the side street's green — and main-road
      ground is `EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER`, 0.6. So even handing idle the whole
      walking rate would give back 2.1/s of a 5.9/s bill. The number that decides what a wait
      costs is the crowd's, not the decay's.

      **And removing the zero re-opens what it was built to close, by a route that is easy to
      miss.** Sleepiness is **frozen, not drained**, above `EXCITEMENT_CALM_THRESHOLD` — see
      `Baby._update_sleepiness` — and that is exactly the state somebody would stop in. So above
      the threshold standing still already costs nothing on the other meter, and any non-zero
      idle decay makes waiting it out strictly better than walking on every ground quieter than
      the decay: every back street and every park. `SLEEPINESS_DRAIN_IDLE` looks like the guard
      and is not, because it is switched off precisely when the exploit would be used.

      *Standing still is worse than walking* is the right sentence for a game whose only verb is
      *where do I walk*. What it must not be is the game's answer to something the game made her
      do, which is the next item
- [x] **Waiting for the main road's light costs a third of the meter, and up to all of it.**
      Found by measuring the item above rather than arguing it. Twenty arrivals spread across the
      cycle, at a signalled junction on the spine, five seeds:

      | | value |
      |---|---:|
      | cycle | 17.1s = 8.1 main green + 2.0 amber + **5.0 side green** + 2.0 amber |
      | mean wait for the crossing arm | **5.7s** |
      | worst wait | **12.0s** |
      | mean cost of the wait | **33.4** of a 100 meter |
      | worst cost of the wait | **133.0** |

      So obeying the light is worth a third of the day's tolerance on average and can end the day
      by itself, and this is *before* the crossing, which the item above measured at up to 35
      more. That is not a soft block, it is a toll gate with a queue, and she has no choice about
      any of it: `Tuning.validate_signals` guarantees she can only cross on the side green.

      **And the diagnosis it was written with is wrong, which the measuring found and the
      arguing did not.** The suspect was *what she is standing next to*: a queue held at the stop
      line is worth what the same cars are worth streaming past, because `contribution_at` never
      looks at how fast a car is going. But **she waits while the main road has green**. The
      traffic beside her is moving by construction, and the queue is on the side street she is
      not standing on.

      **What is actually expensive is standing, and it is not specially expensive here.** The
      spine's junction kerb reads **5.9/s** during a wait — an ordinary pavement reads 4.5–5.1.
      So this is the item above's other half arriving with a bill: `EXCITEMENT_DECAY_IDLE` is 0,
      any six-second stop anywhere costs a quarter of the meter, and the spine is the one place
      the game *makes* her take one.

      Three candidates, all measured, all rejected, because two of them buy the wait with the
      thing finding 7 just fixed and the third buys it with the road itself:

      | | wait | worst | arterial floor | jaywalk | spine stopped |
      |---|---:|---:|---:|---:|---:|
      | today | 33.9 | 133.0 | 11.98 | 26.1 | 41% |
      | a stopped car idles at 0.35 | 32.9 | 122.6 | **8.55** | **11.0** | 41% |
      | `CAR_OUTER_RADIUS` 104 → 64 | 23.2 | — | **7.62** | **11.0** | 41% |
      | side green 5.0 → 8.0 | **15.3** | **56.3** | 11.98 | 26.1 | **63%** |

      - **The idling fraction does nothing for the wait** — 33.9 to 32.9 — for the reason above,
        and its real effect is to halve the arterial floor and the cost of jaywalking. That is
        M41's *"a car waiting at a light beside you is louder for longer than one going past"*
        answered at last, and it turns out to be an answer to a different question.
      - **A narrower car field does not make a careful line**, which is the surprise. The profile
        across an ordinary footway stays flat at every radius tried — 3.31 / 3.74 / 3.39 at 64 —
        because **the flatness is the pedestrians**, who are 3.3 of the 4.5 and whose spacing is
        arithmetic no radius can change. All it buys is the same halving of the spine.
      - **A longer side green works and the road pays for it.** It halves the wait and the worst
        case, and it takes the spine from two fifths stopped to two thirds.

      So the mean is left alone on purpose: **33 points to cross the spine is the soft block
      finding 7 asked for**, and every lever that lowers it lowers the crossing with it. What is
      wrong is the *worst* case — 133 for one unlucky arrival, which she cannot see coming — and
      the thing underneath it is the next item
- [x] **The main road is two fifths stopped, and that is where its noise comes from.** Measured
      while pricing the wait, over three seeds and thirty seconds of act I: the cars on the spine
      average **49 px/s of a 158 cruise, with 41% of them stationary**. `CLAUDE.md` says to
      measure exactly this alongside the floor *"or a road that reads as busy in a screenshot is
      a car park in motion"*, and nobody had.

      **The diagnosis this item was written with is wrong, and measuring it found a five-milestone
      error in the design record.** It is worth reading as an example of how confident a wrong
      cause can sound: the drift argument below is arithmetically correct and explains nothing.

      **The speed spread is real and is not the mechanism.** `CAR_SPEED` is 130–185 against a wave
      tuned for 157.5, so a slow car does drift 0.6s per junction. But it needs **13 junctions** to
      drift out of an 8.07s green band and a car lives **3.8 junctions** on the spine before it
      recycles — and measured over three seeds, the **fast** half stopped more often than the slow
      half (4.25 against 3.00, 4.29 against 3.00, 2.44 against 2.38). Both proposed shapes — a car
      holding the progression speed, a narrower range on the spine — treat the drift, so both were
      dropped.

      **What is actually wrong is that the wave only ever served one direction.** M41's note said
      both did, "because the cycle is an even multiple of the junction-to-junction travelling
      time", and that is the condition upside down. With offsets `j·travel`, a car passing
      junctions `j0 + d·h` at `t0 + h·travel` sees phase `t0 + j0·travel + h·travel·(1 + d)`: going
      *with* the wave the `h` term vanishes and the phase never moves, going *against* it the phase
      advances `2·travel` per junction, which is constant only if the cycle **divides** `2·travel`
      — true at `blocks = 1` and nowhere else. Measured on the signals alone with no traffic in
      them, twenty departures spread across a cycle:

      | | arrivals meeting a green |
      |---|---:|
      | with the wave | **93%** |
      | against it | **51%** |

      and 51% is the main green's share of the cycle, which is to say chance. `tests/test_crowd.gd`
      had asserted `cycle / travel` is an even multiple since M41 — **true, and not the property
      the sentence beside it claimed**, so it pinned nothing. It walks a car down the platoon now.

      **It cannot be fixed, and that is a fact about the geometry rather than a setting.** A
      two-way wave needs `cycle = 2·travel` = 5.7s; the side green plus its two ambers is 9.0s
      before the main road gets a second, and widening `travel` instead means a spine cruise under
      100px/s, barely above a walk. No offset does better on average either: `θ = travel` buys one
      direction a perfect run and leaves the other at chance (72% overall), while the
      symmetric-looking `θ = cycle/2` puts **both** directions on a three-phase sweep at 47% each.
      The asymmetry is the good answer, not a compromise.

      **So the light is the floor and density is what sits on top of it.** Dropping
      `CROWD_CARS_PER_ACT[0]` to 12 for one probe — a third of the traffic — took the spine to 79
      px/s and 33% stopped, so density is worth about ten points and more than half the stops, and
      the irreducible remainder is the main arm being red 53% of the cycle. The cars stay: the same
      probe took the arterial floor 9.95 → 7.40 and the crossing 29.7 → 19.0, which is finding 7
      undone to answer finding 1.

      **What did move it is a snapshot being read as a fact.** `Crowd._can_clear_the_box` compared
      a static `gap_ahead` against the room a car needs beyond a junction, so a car queued behind a
      leader that was *already accelerating away* refused to enter, stopped, and made the jam the
      rule exists to prevent. Crediting the leader's speed for one `CAR_HEADWAY_TIME` — the horizon
      the car-following rule already trusts it for — is the whole change:

      | | before | after |
      |---|---:|---:|
      | mean speed on the spine | 44.6 px/s | **53.6** |
      | stationary at any instant | 43% | **39%** |
      | stops per car per life | 3.28 | **2.05** |
      | junctions crossed per life | 3.9 | **4.1** |
      | arterial floor | 9.95–13.17 | 9.17–11.09 |
      | worst crossing of the spine | 29.7 | **30.2** |

      So the road moves half again as fast for a third fewer stops, and the two numbers the
      previous items fought for — the floor and the ~33 points to cross — do not move. The noise
      floor did not have to be bought back with `CROWD_CARS_PER_ACT`, which the item expected it
      would.

      **The half that had to be walked back is the instructive one.** Crediting the leader's speed
      *unconditionally* put **238 overlapping crossing-axis pairs in 3,600 frames** against a
      tolerance of 180 — `tests/test_crowd.gd` caught it on the first run — because it let a car
      follow its leader straight *into* the box. The credit is only sound once the leader is past
      the far side, where its speed answers "will the last 66px have opened up by the time I get
      there", a question about road this car is not yet on. **Ask what the number you are
      crediting is a fact about**: a leader inside the box is the obstacle, not evidence about the
      road beyond it
- [x] **A contact is 22–34 points a second and there were fifteen of them in four days.** Either
      the cost or the frequency is wrong and the trace cannot say which. `BUMP_RADIUS` is 14 and
      the M33 note says the careful line was two pixels wide when M19 measured it — so widening
      the *street* rather than narrowing the *body* may be the honest answer, and that is a
      question for `CrowdLanes.SIDEWALK_OFFSETS` and `_make_way`

      **Neither is wrong, and the question was asking about the wrong axis: what is wrong is the
      *place*.** Measured over three seeds, forty-second walks, with the whole frame run — the
      crowd stepped **and** the player half of `Crowd._physics_process`, so `_make_way` is in it:

      | | value |
      |---|---:|
      | one contact | **10.8 points** — 18.0/s fading linearly over 1.2s |
      | contacts, 40s down an **ordinary** footway | 2.7, whichever line is taken |
      | contacts, 40s down an **arterial** lane centre | **15.3** |
      | the same, on the arterial midline | **0.0** |

      **The cost is right.** 10.8 is a tenth of the meter, and `tests/test_crowd.gd` already pins
      the shape it has to keep — one is survivable, four freeze the meter, ten lose the day. The
      *22–34 points a second* in the trace is the instantaneous rate with the field underneath it,
      not what a contact costs.

      **The frequency is right too, and an ordinary street turned out not to be the problem at
      all.** Every line across an ordinary footway is **net recovery** while walking: the crowd
      charges 55–87 points over forty seconds and the walking decay pays back 140, so the net runs
      −53 to −85 at every offset from the frontage to the kerb. That is worth holding against the
      standing numbers three items up — 5.82/s on the same ground — because the gap between them is
      the whole of `EXCITEMENT_DECAY_IDLE` being 0 and of `_make_way` only running for somebody who
      is moving. **Walking an ordinary pavement is free; standing on one is not.**

      **So the contact question is an arterial question, and there the careful line was four pixels
      wide.** A contact fires inside `BUMP_RADIUS` of a lane centre, the lanes sat a tile apart, and
      `TILE_SIZE − 2 × BUMP_RADIUS` is 32 − 28 = **4**. That is not a line a player can aim at, it
      is one she is occasionally on — with **165 points of a hundred** riding on it, which is the
      M46 headline (*the careful line is invisible*) arriving with a number and a cause.

      **Fixed by widening the street, which is what the item guessed and is the honest direction.**
      `CrowdLanes.SIDEWALK_LANE_SPREAD` pushes the two lanes of a footway 8px apart toward its own
      edges, so the clear line goes **4px → 20px** while the lanes stay 8px inside the pavement.
      Nothing about a contact changed: `BUMP_RADIUS` is what makes one mean *walking into
      somebody*, and narrowing it would have bought the same line by making a contact require a
      near-perfect overlap.

      | | before | after |
      |---|---:|---:|
      | clear line between two lanes | 4px | **20px** |
      | arterial lane centre, 40s | 13.7 contacts | 15.3 |
      | arterial midline, 40s | 0.0 | **0.0** |
      | field over 40s at an ordinary midline | 74 | **56** |

      Two things came with it. The careless line stayed careless, which it had to — the crowd is
      only a decision if walking down the middle of it still costs. And the field got **quieter in
      the middle of the pavement** as well, because the walkers are further from it, so for the
      first time the two halves of the crowd want the *same* line: the item below found them
      wanting opposite ones, and that is what this closes. `tests/test_crowd.gd` holds the band
      against `PLAYER_BODY_RADIUS` — it has to be aimable, not merely non-empty — and holds the
      spread under half a tile, because `CrowdAgent._pavement_band` measures the footway from the
      **tile** centres and nothing else in the suite would notice somebody walking in a shopfront.

      Open, and it is the half a geometry change cannot reach: **nothing yet says the channel is
      there.** It is now wide enough to find by walking down the middle of a pavement, which is
      what most people do — but that is a claim about a player and no rig can settle it
- [x] **`CROWD_PEDESTRIANS_PER_ACT[0]` is 200 and it is a population of the field, not the city.**
      It has not been re-measured since the field's box last moved. Measure what is actually
      within a screen of her, not what the constant says.

      **Taken out of order, and on purpose: the two decisions above cannot be made until it is
      known whether the population is the lever.** It is not, and that is the finding.

      Measured over five seeds, act I, thirty seconds standing on each of eight corridors:

      | | value |
      |---|---:|
      | walkers in the box, every sample | **200.0** of 200 |
      | cars in the box, every sample | **34.0** of 34 |
      | walkers on a 1280×720 screen | **67.6** |
      | cars on a 1280×720 screen | **10.2** |
      | walkers within 200px of her | 9.4 |

      So **the constant is honest**: the box is 1600×1600 and never spills, the screen is 36% of
      it, and 34% of the population is on it. Nothing is hiding. And it must not come down —
      the same population is what put 15.4 cars on the spine and made crossing it cost a third
      of the meter two items ago, so cutting it undoes finding 7 to answer finding 1.

      **What the measurement actually found is where the floor comes from, and it is geometry
      rather than population.** The floor across a footway, same five seeds, in lane units —
      0 is against the frontage, 1 is the kerb:

      | | frontage 0.0 | midline 0.5 | kerb 1.0 |
      |---|---:|---:|---:|
      | mean over 20 ordinary standing points | **4.30** | **4.96** | **4.76** |

      **It is flat, and the midline — the careful line — is the loudest of the three.** Both
      halves fall out of arithmetic that nobody has re-checked since the corridor was last
      resized:

      - **A car's field is 208px across and a corridor is 192px.** Every tile of both footways
        is inside `CAR_OUTER_RADIUS` of a carriageway lane — the frontage lane is 64px from the
        nearer one. There is no line on an ordinary street that is out of the traffic's earshot,
        which is why the profile barely tilts.
      - **A walker's field is 110px across and a footway is 64px.** Lanes are 32px apart and
        `PEDESTRIAN_INNER_RADIUS` is 22, so the midline is 16px from two lane centres and inside
        the **full-intensity core** of both. `Tuning.PEDESTRIAN_INTENSITY`'s own comment says
        *"walking wide of them does not [cost] — the pavement is two tiles, so how close to pass
        is a real choice"*, and there is nowhere on a footway to be wide.

      This is the M46 headline finding — *the careful line is invisible* — arriving with a
      cause, and the cause is not that nothing tells her about it. **The careful line exists for
      contacts and does not exist for the field**, and the two want opposite lines: the midline
      is the only line with no head-on contact on it (`BUMP_RADIUS` 14 against a 16px half-lane)
      and it is the worst line for the ambient noise. A player who finds one has found the other
      one's punishment.

      **Closed by the contact item above, and by one change rather than two.**
      `CrowdLanes.SIDEWALK_LANE_SPREAD` moves the two lanes of a footway 48px apart, which widens
      the contact-free line from 4px to 20px **and** puts the midline 24px from each walker —
      outside `PEDESTRIAN_INNER_RADIUS` rather than inside it. The ordinary midline's field falls
      74 → 56 per forty seconds. The two halves of the crowd want the same line now
- [x] **The crowd bunches against the boundary wall, where the comment says it thins.** Found
      while measuring the above. `CrowdField.corridor_range` clamps to the city and says so:
      *"that is also why the crowd thins out honestly in the corner of the map instead of
      bunching against the wall — there are simply fewer streets to put anybody on"*. The
      population does not clamp with it, so fewer streets and the same two hundred people is
      **more people per street**, which is the opposite of what the comment claims.

      Measured, five seeds, walkers on screen against how much of the box is inside the city:

      | corridor | box in city | walkers on screen | mean floor |
      |---|---:|---:|---:|
      | 0 (against the west wall) | 53% | 67.0 | **7.50** |
      | 1 | 81% | **78.3** | 7.90 |
      | 3, 6, 8 (ordinary, mid-map) | 100% | 66–70 | 3.91–5.89 |
      | 5 (the spine) | 100% | 69.9 | 11.58 |
      | 11 (against the east wall) | 59% | 55.3 | 6.80 |

      **The count on screen is flat while the city on screen is halved**, so the density per
      street at the wall is about double and the outer corridors read as **1.6× an ordinary
      middle one** — loud enough that on two of five seeds a corridor beside the wall beat the
      main road.

      **Fixed on the box rather than on the population, which is what made it nine lines.** The
      first design was the obvious one — fewer agents live where there is less street — and it
      is the wrong one twice over: it needs a live count that varies, and a live count that
      varies has to sleep somebody, which is *"nothing vanishes while you are looking at it"*
      asking for a whole waking-and-sleeping protocol that only ever runs off-screen. Instead
      `CrowdField` **grows the box near the wall** until the amount of *city* in it is what a box
      mid-map holds: `contains`, `along_bounds` and `corridor_range` all read `radius`, so every
      one of them follows, and no agent is created, destroyed or hidden. Growing is always the
      safe direction — the only floor under `CROWD_FIELD_RADIUS` is that nothing may be seen to
      appear.

      Solved by iterating rather than in closed form, and that was a decision: the exact answer
      is a quadratic whose terms depend on which of the four sides are against a wall **and**
      which of them clip while it grows, which is four cases to get wrong. Scaling by the square
      root of the shortfall lands within a pixel in three passes.

      | | before | after |
      |---|---:|---:|
      | radius against the west wall | 800 | **1108** |
      | walkers per screen of city, at the wall | **105** | **64** |
      | the same, three blocks in | 58 | 58 |
      | mean floor, outer corridors (5 seeds) | 7.50 / 6.80 | **3.12 / 4.52** |

      So the wall now reads as an ordinary street rather than as a busy one, and the two
      corridors against it come in slightly *under* an ordinary middle corridor — an error in the
      safe direction, and the honest reason is that keeping the box's **area** constant does not
      keep its split between north-south and east-west street length constant. Held by
      `tests/test_crowd.gd`, "the crowd does not bunch against the wall", as two checks rather
      than one: the geometry, which is the mechanism and is free, and the density, which is what
      the player feels and is the half that could pass while the other fails
- [x] **Re-measure the whole cost table afterwards** — `docs/EVENTS.md`, "What an event actually
      costs" — because if the crowd's share moves, every authored row's share moves with it, and
      the table is the fastest way to see what a balance change did to the catalogue

      **Regenerated from `EventDef.walk_through_cost()` and compared row for row: identical, all
      thirty-one of them.** That is the result rather than the absence of one — it says M46 was a
      milestone about the *street* and not about the catalogue, and it is worth doing precisely
      because nothing would have told us otherwise. Nothing in the milestone touched an intensity,
      a radius, `Tuning.falloff` or a decay.

      What moved is the ground the rows stand on, and `docs/EVENTS.md` carries it above the table
      now: an ordinary footway is **net recovery** to walk (55–87 points of crowd over forty
      seconds against a decay paying back 140), the middle of a pavement went 74 → 56, and
      crossing the main road costs ~30 with ~33 more for the wait — between a `dog_walker` and a
      `loose_dog`, and neither is in the table because neither is an event

## M47 — A city with places in it · `feature/a-city-with-places`

Not started. Playtest 13's finding 2 and the second half of finding 7, **plus the whole of M45**,
which is absorbed here because it is the same machinery. See **[docs/PLAYTEST-13.md](PLAYTEST-13.md)**
and the M45 entry above, which is still the design for the closure half.

**The one sentence: the count of calm areas is right and their density is not, and the answer is
area rather than count.** The city went 7×7 → 11×11 across M42 and M41 — 49 blocks to 121 — while
the calm areas stayed at eight. The equation playtest 12 asked to keep was about *count*; what a
player experiences is *density*, and the two came apart when the map grew.

The decision taken on the finding, quoted, because it is not what the analysis expected:

> *"make more calm areas take up multiple blocks — I said a long time ago that an inner courtyard
> (surrounded by buildings) should have a footprint of 2x2 blocks (apartment complex) — this never
> got implemented. not all calm areas have to take up multiple blocks but add more that do. also,
> add calm varieties that take up 2x1 non-square shapes"*

- [x] **Calm ground is never at the edge of the map and never beside the main road** — the second
      lever on density, taken in the same session and **cheaper than everything below it**, because
      it is a placement rule rather than new geometry. *"Another way to get density is to make a
      rule to not have a calm area at the edge of the map or next to the main road."*

      **Today a single calm block has neither rule.** `_assign_purposes` constrains it three ways
      — unclaimed, no open-calm neighbour across a street, `_too_near_the_home` — so a quiet square
      can sit in the outermost block column against the boundary wall, or directly across the road
      from the spine. A 2×2 zone has half of one: `_zone_fits` refuses a footprint that would
      **absorb** a stretch of the arterial, which is about swallowing the street rather than about
      being beside it.

      **Measured on the lattice, for a single calm area, with the home clearance already applied:**

      | eligible blocks | count |
      |---|---:|
      | today (121 minus the 5×5 home clearance) | **96** |
      | + no calm in the outer ring of blocks | 56 |
      | + no calm in the two block-columns beside the spine | **48** |

      So it halves the field for the same 5–7 open calm areas, and **the count the player asked to
      keep does not move**. Two things about that table are worth carrying:

      - **The two halves are wildly unequal and the density argument is almost all the edge rule.**
        The outer ring is 40 blocks; the spine's two columns add only **8** on top, because the
        main road runs down the middle where `_too_near_the_home` has already taken a 5×5 out. So
        *"not beside the main road"* has to be justified on **design** rather than on density —
        where it is stronger: `decay_multiplier` is 0.6 on the spine, so a park you can hear it
        from is not calm ground, and if calm never sits beside it then **crossing it always leads
        somewhere worth crossing for**, which is what makes it a soft block rather than a wall.
      - **It recovers half the loss, not all of it.** At 7×7 the eligible field was ~24 blocks for
        the same 5–7 areas. This lever and the bigger calm areas below are complementary — one
        shrinks the field, the other enlarges each destination — and neither is sufficient alone.

      Three things to get right when building it. State both rules over a **footprint**, like
      `_too_near_the_home` and `_zone_fits` already do, so single blocks and zones obey one rule
      rather than two that drift. State the spine rule over **`map.main_road`**, never over
      `CrowdLanes.arterial_index` — `_zone_fits` currently uses the latter and so carries the same
      M41 defect as `CrowdLanes.busyness()` (see M46), protecting a horizontal arterial the city no
      longer has; adding a third copy of a fact that already has two, one of them wrong, is the
      `DangerEdge` mistake M37 found. And **decide courtyards separately**: a courtyard is *hidden*
      calm you have to know about, it is cut from `remaining` with only the neighbour rule on it,
      and an argument can be made either way for one against the boundary.

      Then **measure the room before committing**, because this is where it goes quietly wrong:
      48 blocks must hold 5–7 non-adjacent calm areas, 1–2 four-block zones needing a wholly
      unclaimed 2×2, and up to 3 courtyards — and `generate()` retries with `seed + 1`, so a rule
      that is too tight shows up as a slower generator rather than as an error.

      **The spine half is expendable and that is a decision, not a fallback.** *"The not next to
      main road rule is not that important, you can remove it if it loses too much freedom."* So
      the edge rule is the one that must land; if the measurement above says the field is too
      tight, the spine rule is what comes out, and it comes out **before** `MIN_CALM_BLOCKS` or the
      non-adjacency rule are touched — those two are what the player asked for by name

      **Built in M52 as one question over a footprint** — `CityGenerator._calm_may_sit_here`, asked
      by all three placement paths (the zone pass, the single-block pass and `_cut_courtyards`),
      which is what this entry asked for and is why the home clearance now reaches a courtyard too.
      **The field was measured before committing and the room is there:** 40 seeds, calm areas at
      the edge **4.42 per city → 0**, beside the spine **1.50 → 0**, areas per city 8.85 → 8.43
      (courtyards 3.00 → 2.55, open calm inside its 5–7 band throughout), and generation retries per
      city **0.50 → 0.00** — the courtyard beside the front door that used to fail the home-distance
      guarantee is refused at placement instead. The spine rule did not have to come out.

      **And the east-west guard came out with it.** `_zone_fits` refused a footprint that would
      absorb the middle east-west corridor, tested against `CrowdLanes.arterial_index` — the phantom
      arterial of M46, protecting a street that stopped being anything when playtest 14 deleted the
      east and west city exits. `tests/test_generator.gd` asserted the same phantom, and now asserts
      the sentence that is load-bearing: no zone swallows a stretch of the **main road**, which the
      new spine clause makes true by construction. Recorded rather than merely deleted, because it is
      a rule nobody took being removed rather than one somebody asked for
- [ ] **And no two calm areas are directly next to each other — including courtyards.** *"Also
      don't place calm areas directly next to each other."* Half of this is already true and half
      of it is a real gap, which is why it is its own item.

      `_has_open_calm_neighbour` tests `_OPEN_CALM` only — park, forest, quiet square — and
      `_cut_courtyards` runs **after** the open calm is placed. So a courtyard is correctly refused
      beside a park, and **two courtyards may sit directly across a street from each other**, with
      nothing in the generator able to see it: the open-calm pass cannot, because no courtyard
      exists yet, and the courtyard pass does not look for its own kind. The trace's day 1 planned
      **three** courtyards, so this is reachable rather than theoretical.

      Two things to decide while fixing it, and neither is obvious. **Whether a courtyard counts as
      calm for spreading purposes at all** — it is *hidden* calm, cut into a residential block, and
      the argument that two of them across a street are one awkward area is weaker than for two
      parks. And **whether diagonal counts**: `_has_open_calm_neighbour` walks the four edges and
      skips the corners, so two calm blocks meeting at a junction are legal today. That is
      probably right — they are a junction apart rather than a street apart — but it is currently
      an accident of the loop bounds rather than a decision, and it should become one either way
- [ ] **The 2×2 inner courtyard — an apartment complex.** Asked for *"a long time ago"* and never
      built. What exists is `COURTYARD_SIZE_TILES`, a 4-tile court carved inside **one**
      residential block. What is wanted is four blocks of buildings with a shared court in the
      middle of them, which is neither that nor M21's open four-block zone. **The mechanism is
      M21's** — absorb the streets between four blocks — with frontages around the outside
      instead of open ground, so it is a calm area you have to find a way *into*
- [x] **Calm areas that are not square.** `CALM_ZONE_BLOCKS` is one integer and everything
      downstream is that integer squared — the tile rect, which segments are absorbed, which
      junctions survive. It becomes a `Vector2i`, and `CityMap.anchor_of()` and `lot_rect()` are
      where it is felt. A 2×1 is the case to build first because it is the one that breaks every
      piece of arithmetic that assumed a square

      **Built in M52 as `Tuning.CALM_ZONE_SHAPES` — 2×2, 2×1, 1×2 — with the square placed first.**
      That ordering is the whole of how the variety arrived without repealing anything: M21's
      guarantee is not *multi-block calm*, it is that every city has somewhere with a **route**
      through it rather than a lap round it, and a shape rolled for the first zone would have made
      that a matter of luck. `validate()` asks the city for a square rather than trusting the
      ordering, because the ordering is the kind of thing a later change moves quietly.

      **`CALM_ZONE_BLOCKS` stayed**, as the square's side — it is what the sleepiness curve is
      normalised against and what every relationship test is pitched at. What moved is that counts
      are stated over the **footprint**: a `w × h` zone absorbs `w(h−1) + h(w−1)` streets (four for
      the square, **one** for a rectangle), has `2(w + h)` streets round it, and contains
      `(w−1)(h−1)` junctions, which is **none** for a rectangle. `tests/test_routes.gd` asserted
      all three as the square's answers, which agreed with the general ones for exactly as long as
      every zone was a square.

      Three things the shape actually broke, and only one of them was in the generator:

      - **`_inset_rect` rolled both offsets against `lot.size.x`**, which is the same number on both
        axes only while every lot is square. A playground in a 22×8 lot would have gone up to
        fourteen tiles south of a lot eight deep.
      - **`--spawn zone` could not photograph one.** It takes `zone:<n>` now, the way
        `closure:<n>` does, because `keys()[0]` is always the square and so the one thing the
        milestone added had no way to be looked at.
      - **The rate curve needed nothing at all**, which is what M52's item 2 bought: a 2×1 fills in
        8.0s and pays for about one traverse of its long side, exactly as the square pays for one
        diagonal. `tests/test_generator.gd` asserts the rectangle sits between the other two rather
        than restating the number
- [ ] **More of them are multi-block, and not all of them.** *"Not all calm areas have to take up
      multiple blocks but add more that do."* `MIN_CALM_ZONES` / `MAX_CALM_ZONES` are 1 and 2 and
      were sized for a 49-block city. Re-derive against 121, and keep single-block calm in the
      mix — *which* calm area to head for stays a real question only while a small quiet square
      close by competes with a big park further out
- [ ] **The main road as a soft block.** Finding 7's second half: *"think of the main road as a
      soft block to guide the player — they will avoid crossing it until it becomes necessary."*
      This is M45's *"a city that is not a full grid, permanently"* achieved without removing a
      walkable tile: the spine is already a line down the middle of the map with a hierarchy and a
      picture, and making it genuinely expensive to cross splits the city into two halves with a
      toll between them. **Build it before the cul-de-sacs**, because it costs no geometry and
      nothing downstream has to be re-proved
- [ ] **Then the rest of M45** — permanent impassable blocks, and closures placed to say *not this
      way today*. The design is in the M45 entry above and is unchanged. The trap it names is the
      one to keep in front of you: **a nudge that removes the decision is worse than a closure
      that does nothing**, because the game's one verb is *where do I walk*
- [ ] **Re-check `MIN_CALM_BLOCKS` and `MIN_HOME_TO_PARK_TILES` at the end, not the start.** Both
      are stated in a lattice that is about to change what a calm area *is*. `calm_areas_needed()`
      derives the floor from the act lengths and must go on doing so

## M48 — Things drawn where they stand · built 2026-09-03 · `feature/drawn-where-they-stand`

Playtest 13's finding 3 and playtest 19's repeat of it — *"random gray barriers placed half on the
street and half on the sidewalk — no clue what they are supposed to be but they raise excitement for
some reason?"*, and *"they're all placed with an offset that makes them clip into other things — the
only barrier that is consistently correct is the full street closure"* — which is `construction`, and
which was wrong in three separate ways that are each a rule rather than a row.

**Built ahead of M64 because M64 stands on it**: M64 seals every street off the day's corridor with a
thing lying *across* it, on the order of a hundred and fifty bodies a day whose entire content is
which way they face.

**The first pass at item 1 read "the pavement" as "the lane", and was redone.** Capping every
`SIDEWALK`-placed spread at 16px (half a tile) makes a body that fits inside whichever single lane
tile the scheduler rolled — and at 16px a pram walks past `construction` on the free lane, which
removes the obstruction the row exists to be. It also removes the property M64's **soft seal** needs:
two ordinary obstacles, one per side, leaving no line to walk. The defect in the player's own words is
the **offset**, not the width.

**The fix is that a pavement is one piece of ground rather than two lanes.**
`EventInstance._centred_on_the_pavement_band()` moves a stationary, unpinned (`pavement_side == ANY`)
body from its lane tile to the middle of the two-lane band before `setup()` hands its position to the
drawing or to the collision circle, so the two always agree. The cap that makes correct is **32px**
(half the 64px band): `construction`'s 34 trims to 32, and `market_stall` (28) and `cafe_tables` (24)
fit once centred and keep their original values. Rows pinned to an edge on purpose — `delivery_van`,
`reversing_lorry`, `pavement_side == AT_THE_KERB` / `AGAINST_THE_BUILDING` — are exempt by
construction, checked against `delivery_van` specifically so the exemption cannot quietly become
*everything gets centred*: a kerbed 44px body still leaves 26px to the frontage, narrower than the
28px pram.

**The arithmetic that makes `construction` the one act I event physically in the way**: she needs her
centre `obstructs_radius + PLAYER_BODY_RADIUS` = 32 + 14 = 46px from the barrier's centre, and the
band is 32px from that centre to either edge. 46 > 32 on both lanes, asserted directly in
`tests/test_events.gd` rather than left to a screenshot.

**Rotation is a property of the street, not a field on the row.** A per-row orientation field was
rejected: two rows on the same street have to face the same way for the same reason, so it is stated
once in `EventInstance.setup()` from `CityMap.corridor_offset()`. `_spread_is_vertical()` asks that of
both of a tile's coordinates, which is geometric rather than tile-type, so it answers a `ROAD` or
`CROSSING` tile (a checkpoint, the barricade a stopped convoy leaves) exactly as it answers a
`SIDEWALK` one.

**Open where the design was silent, and cheap to overturn:** a junction — both coordinates inside a
corridor band at once — and ground off any corridor at all (a square, a park, a courtyard) keep the
unrotated lay along local X, because neither has one street to be wrong about and X is what every
spread drew before the rule existed. `_draw_protest` and `_draw_firefight` have the same local-X-only
layout and are left unrotated for the same reason: their placement is `SQUARE` and `CROSSING`, open
ground with no single traffic direction to get wrong.

**The hazard colouring is not a new cue.** The **cues** vocabulary stays at four rows plus the entity
itself; this strengthens the first of them — *the entity itself carries most of it*.
`barrier_segment.svg` is now a cream board with diagonal red stripes, built the way
`checkpoint_block.svg`'s red-and-cream band already is, so the two read as kin without sharing a
picture: a street being mended against a street being held. `barrier_end.svg` is kept mostly
structural — the post rather than the board — so the repeated segments carry the warning rather than
every part competing for it.

- [x] **A body on a pavement has to fit on the pavement.** `construction` drew 68px wide on a 64px
      sidewalk from a tile centre 16px from one edge and 48px from the other, so it overhung by 18px
      whichever lane it landed in. This was M34's rule (*a body is half the silhouette*) meeting
      ground it was never checked against. `tests/test_events.gd` gains a catalogue-wide check,
      `_test_a_spread_body_fits_the_ground_it_stands_on`, so a future row with the same defect fails
      the build rather than waiting for a playtest, and `_test_a_kerbed_body_still_pins_the_frontage`
      pins the kerb exemption. The check's own comment records its blind spot: `burnt_shell` and
      `barricade` have no `def.placement`, so the loop never reaches them
- [x] **A spread is always drawn east–west, whatever street it is on.** `_draw_spread` spread along
      local X and nothing rotated an `EventInstance`, so the barrier that hangs into the carriageway
      on a north–south street lies *along* the kerb on an east–west one, parallel to the traffic,
      blocking a pavement it is not across. `_draw_spread` and `_draw_cafe` are rewritten in terms of
      `_spread_at` and `_spread_extent`, which swap the layout onto local Y when the instance's own
      `_spread_vertical` says to
- [x] **And it does not say what it is.** The sprite was blue-grey (`#6b7a8c`, `#4e5a68`) with no
      hazard marking. M37's rule — one picture per row, no two rows sharing one — passed here and the
      row still said nothing, which is that rule's own limit: *how dangerous a thing is has to be
      visible from looking at the thing*. Verified with `tools/shot.sh` against a live `construction`
      instance; the same screenshots incidentally show the rotation working, one instance drawn as a
      narrow vertical column on an east–west street

## M49 — A city that says what it is · `feature/run-and-it-backs-off`

Playtest 14, taken **before** M47 because four of its six are small and two of them are things a
player has now asked for twice. See **[docs/PLAYTEST-14.md](PLAYTEST-14.md)**.

**The one sentence: nothing here is about balance — five of the six are the city failing to say
what it is**, and the sixth is a mechanic that was answering a question about geometry when the
player was asking one about themselves.

**Merged to `main` unfinished, deliberately, and this is the third time** — see M43 and M47. What
is merged is the first round of playtest 14, finished and green: the dog, the border built to its
brief, the moving spine, calm areas that are not diagonal, and calm areas she has not visited
staying clean. What is **not** started is the whole second round, recorded below under *"Recorded
and not started"* — the traffic lights, the calm-ground multipliers, the fence drawn from the
camera's angle, and the four faults on the borders.

The reason to merge rather than hold: the first round contains the process fix in `CLAUDE.md` and
the design record in `docs/CITY.md`, and both of those are rules the *next* piece of work has to be
done under. A branch is the wrong place for a rule about how to work. The rest of M49 continues on
a branch of its own.

- [x] **The pursuing dog does not stop.** *"It's a very simple rule — when I run the dog backs down
      almost immediately."* Third report of this encounter. `PURSUIT_SHAKEN_OFF` counted seconds of
      the **gap opening**, and a run opens it at 38px/s against the day-3 dog — a fifth of a pixel
      a frame — so a corner, a kerb, a pedestrian or the 0.37s about-turn reset the timer and the
      dog chased somebody who was visibly sprinting. Confirmed off a trace first: `run  ran 1.3s,
      exc 57 -> 98`, escaped and lost the day doing it.

      It is a fact about **her** now. Measured with a rig that accelerates: **0.35s of running for
      5 points**, against 1.2s for 17 — which is also the answer to *"or make running less
      costly"*, without moving `EXCITEMENT_FROM_RUNNING`, which is the whole of why running is
      wrong against everything that does not follow her. The contract is untouched: it rests on
      the speed clauses, so walking still cannot end a chase and running always can
- [x] **The border is just black.** M41 built the ring of frontages and opened the camera onto it
      and neither put anything on the floor out there. Each outside tile clamps to the nearest tile
      *in* the map and takes its picture, so the edge continues outward and the spine's four exits
      get their road for free. `CityMap` is untouched — this paints the tilemap only
- [x] **The main road is always in the same place.** It was the middle corridor on **every seed
      ever generated**. Rolled from the city's street stream now, three corridors clear of either
      boundary so both halves are worth being in. Four places still derived it from the constant —
      the M46 defect exactly, *a fact about a city answered from an axis length*
- [ ] **Junctions are four-way where an arm dead-ends.** **Not reproduced.** Two candidates checked
      and correct: an absorbed street's T-junctions already carry no crossing on the missing arm
      (measured, two seeds), and a boundary junction's outward crossing is right rather than wrong
      — it is how somebody on the outer pavement gets over the road she is meeting. It read as a
      dead end because there was nothing beyond it, which is the item above and is fixed. **Needs a
      location from the player**, or a third candidate
- [ ] **Courtyards are still one block.** Asked for twice now. This is the M47 entry *"The 2×2
      inner courtyard — an apartment complex"* unchanged: M21's mechanism — absorb the streets
      between four blocks — with frontages around the outside instead of open ground, so it is a
      calm area you have to find a way **into**. The largest remaining piece of M47
- [x] **The 0.2s window at the lunge — offered and declined.** *"The pursuing dog is fixed now,
      the additional change you suggested is not needed."* The measured gap is real and stays
      recorded on `Tuning.pursuit_standoff`; what it no longer carries is a claim that anybody
      wants it closed. **Do not reopen without a player asking**
- [x] **The border, as briefed rather than as complained about.** Specific tiles per side: south a
      bulkhead then water and **no buildings**, east and west a fence then grass then forest, north
      scree then mountainside. The only things that cross are the **tunnel** — the carriageway
      carries on and darkens a step per tile until it is gone — and the **bridge**. M41's east and
      west road exits are deleted with it: they made sense as gaps in a ring of frontages and make
      none in a wood, and they were never on a main road anyway
- [x] **The fence is rotated the wrong way.** It is drawn running north-south now, the axis it is
      used on, and symmetric about its own centre line so one tile serves both sides
- [x] **Calm areas must not be diagonal from each other either.** *"We said they should not be next
      to each other — this includes the entire surrounding."* `_has_open_calm_neighbour` walked the
      four edges and skipped the corners, so two could meet at a crossroads. It is the whole ring
      now. This closes the M47 open question that called the diagonal case *"an accident of the
      loop bounds rather than a decision"*
- [ ] **A calm area she has never visited was already spoiled, and that can end a run a day
      early.** The most serious finding here, because it is an unwinnable-day bug. `MIN_CALM_BLOCKS`
      is derived as *an act's worth plus one* on the assumption that only **going** to an area
      burns it — which is what `_spoil_the_parks_she_used` does. But `_ensure_one_usable_park`
      protects exactly **one**, and ordinary placement can drop a busker or a market stall into any
      of the rest, so the pool falls below the derivation through no decision she made.

      **Make the guarantee match the derivation: every calm area she has not used this act stays
      clean.** Spoiling stays the answer to *returning* and nothing else. Then check what it costs
      the catalogue — parks are one of the few places several rows can go
- [ ] **Nothing guides her toward the calm, and hard/soft diversions were summarised away on day
      one.** *"I still don't feel the game guiding me to calm zones via obstacles — also tell me you
      have a note about hard and soft diversions."* The current logic is stated in `docs/CITY.md`,
      "Guiding her to the calm": the city **permits** routes to calm and **protects** them from
      becoming impossible, and never suggests one — closures are drawn at random from whatever
      keeps the two-routes invariant, so one is as likely to be behind her as across her route.

      **The design has now been given in full and is written up in `docs/CITY.md`, "Diversions —
      the design". Read it there rather than here.** In one paragraph: hard and soft mean
      **permanent** and **per-day**, not severity; hard blockers are pruned lattice edges
      (cul-de-sacs, big buildings) and soft ones are the day's placements (closures, fallen tree,
      restaurants); soft splits into **lethal**, **mild/benign**, and **road closures**, which are
      not lethal but prevent full access. **Hard and lethal form the paths; benign go on the path.**
      The main road paces the run — she exhausts her own side before she is forced across. Sealing
      a section is fine, because there is no calm in it.

      **Presentation is not the problem and must not be touched.** *"How they are presented is
      already solved. The issue is that they are not placed properly."*

      **And nothing in the invariants forbids it** — checked rather than assumed.
      `_park_is_reachable` requires **one** reachable calm area, not a connected city, so a sealed
      quarter is already legal; `ClosurePlanner`'s two-routes rule is about reaching calm, not
      about connectivity. This is a **placement** milestone end to end: no new blocker kinds, no
      new cues, no change to what a closure is.

      **All five opening questions are answered** and the answers are in `docs/CITY.md`, "How the
      corridor is built": the target is **every available calm area**, one **corridor** each, and
      the day's plan is a **tree** rooted at the doorstep; overlaps are wanted, and a **chokepoint**
      is a guaranteed placement; there is **no budget**, only the tree, and **placeholders** that
      resolve when she arrives; one-shots **bind late**. What is left is the build, in this order:

      1. **Hard blockers do not exist and have to be built first.** *"Cul-de-sacs and big buildings
         don't exist yet — but we need them to implement proper hard blockers."* This is the only
         piece that is **once per run** rather than per day, everything else is placed relative to
         what it leaves, and it has to work for every calm area the run will ever use. It is a
         `CityGenerator` change and it is the gate on the rest
      2. **The tree**, per day: doorstep to every available calm area, corridors and chokepoints
         computed and available to whatever places things
      3. **Placement by role** against the tree — walls out of hard blockers and lethal rows,
         friction inside the corridors, set pieces on candidate sets that every corridor touches
      4. **Placeholders**, so nothing is spent on ground she never reaches
      5. **The two invariant decisions** in `docs/CITY.md` — edge-disjointness versus chokepoints,
         and late binding versus the retried day. Neither is a coding problem and both block 3
- [ ] **Restate the main-road pacing question, which was not understood.** *(Asked badly the first
      time: "what paces the main-road crossing?")* What is meant: the design says she takes routes
      on **her side** of the spine until they are exhausted and is only then forced across. The
      question is **what makes that happen** — is it simply that calm areas exist on both sides and
      `_spoil_the_parks_she_used` burns the near ones over an act, so the far side becomes the only
      thing left? Or does something have to actively withhold the far side early on, and steer her
      across late? The first needs no new code and falls out of what exists; the second is a
      mechanism nobody has designed. **The answer decides whether the arc is emergent or authored**
- [ ] **Day 3 carries act I's whole payload, and the run lesson is the thing it crowds out.**
      *(Raised by the player: "does the fire truck conflict with the run tutorial? Should we move
      the run tutorial one day earlier to disentangle?")* **It conflicts, and it is three rows
      rather than two.** Everything in act I that is not day 1 or 2 arrives at once on day 3:

      | row | what it is | |
      |---|---|---|
      | `fire_truck` | `first_day = 3, last_day = 3` — the **only one-shot in act I**, and a set piece | mobile 190px/s, 340px radius, leaves a `burning_building` for the rest of the day |
      | `charging_dog` | `first_day = RUN_TAUGHT_DAY` — **the run lesson** | `hard_fail`, `AHEAD_OF_PLAYER`, pursues |
      | `reversing_lorry` | new that day as well | `hard_fail` |

      So the last day of act I introduces **two new lethal rows and the only set piece**, on the
      day it also teaches a key the game has spent two days punishing. And the two headline
      encounters teach **opposite answers**: the dog is the one thing in the game running beats,
      the fire engine is a thing to be off the road for. A player who learns "run" from day 3 has
      learnt it next to the one row where it is least relevant.

      **Day 2 is not empty, and the premise for moving there was that it is.** *("Day 2 might be a
      good option since it doesn't introduce anything else I think?")* Measured off the catalogue,
      **day 2 is the busiest introduction day in act I**: `busker`, `construction`, `cyclist` and
      `ice_cream_van` — four rows, and `cyclist` is **lethal**. Day 3 introduces three. So moving
      the lesson to day 2 does not give it a quiet day; it gives it a day with four other new
      things and an existing lethal row on it.

      That does not sink the move — **the argument was never about counts**. It is that day 3's two
      headline rows teach opposite answers, and that a set piece needs room. But it changes what
      the options are, so all three are worth having:

      | | | |
      |---|---|---|
      | **A. run lesson → day 2** | act I reads walk → run → set piece | day 2 gains a 5th new row and a 2nd lethal one; `cyclist` already teaches *fast things kill* |
      | **B. `reversing_lorry` → day 4** | day 3 keeps the lesson and the set piece, minus one lethal row | the two opposite lessons still share a day |
      | **C. `fire_truck` → day 2** | day 3 becomes purely the run lesson; the set piece gets its own day | act I loses its day-3 finale, which is where a one-shot naturally wants to be |

      **Decided: A.** *("Let's do A", 2026-08-31, taken with the corrected premise in front of
      it — day 2 is the busiest day in act I, not an empty one.)* It is the only option that
      separates the two opposite lessons *and* leaves the set piece where a finale belongs, and
      `cyclist` on day 2 is arguably the right neighbour for a running lesson rather than the wrong
      one. **Not implemented** — the change is `Tuning.RUN_TAUGHT_DAY` 3 → 2 plus the docs that
      state it, and it is the one code change queued out of this whole conversation.

      Three things to check rather than assume when it is made, because this is the most-reported
      encounter in the project and playtest 08 explicitly liked where it sits (*"I like the running
      tutorial on day 3"*):
      - `RUN_TAUGHT_DAY` gates **everything that pursues**, so moving it moves the robber's first
        possible day too — check act I is not made harder by a constant that was only meant to move
        a tutorial
      - `charging_dog` is `first_day = RUN_TAUGHT_DAY` **by reference**, so it follows for free;
        `reversing_lorry` is a literal `3` and would then be the only new lethal row on day 3
      - the day-2 difficulty was tuned without a `hard_fail` row on it

      And `docs/MECHANICS.md`, `docs/EVENTS.md` and `CLAUDE.md` all state *"day 1 teaches the arrow
      keys and day 3 teaches the run"* in prose. All three move with the constant, in the same
      commit, or the docs start lying about the day the game teaches its second verb

### Recorded and not started — the second round of playtest 14

Written down before anything is built, on the player's instruction (*"write those down — no fixes
yet"*) and under the `CLAUDE.md` rule the first round produced.

- [ ] **Traffic lights stand against the building instead of the kerb.** *"The traffic lights go to
      the side of the road not the building — they always stay close to the road."* A head belongs
      on the carriageway side of the footway and should stay there whatever the pavement is doing.
      M41 built them on the principle that *where it stands is what says which road it is talking
      about*, so a head against a shopfront has stopped pointing at anything
- [ ] **Calm ground is worth more, and a small calm area worth more still.** *"x1.5 the sleepiness
      effect of calm zones and double it for 1x1 calm zones."*
      `Tuning.SLEEPINESS_CALM_ZONE_MULTIPLIER` is 12. **Two readings, and they differ for the
      multi-block case** — (A) 18 for a zone and 24 for a single block, or (B) 18 and 36. A unless
      corrected. The design is the good part either way: a four-block zone is more than one lap
      wide and a single block is not, so the small ones have always been the weaker choice for
      reasons unrelated to what they are for. Re-check `docs/MECHANICS.md`'s "more than one lap"
      margin afterwards — M38's entry warns this is the constant that decides whether a day is
      winnable once the park is reached
- [ ] **The fence is drawn in elevation and turned on its side.** *"It just looks like a fence from
      the front but rotated sideways, which doesn't make sense."* Both attempts have been a side
      view — palings with a rail across them. The game looks straight down, where a fence is a thin
      line with post-heads and a shadow. Rotating an elevation does not make it a top-down drawing
- [ ] **The eastern border, four faults in one screenshot.** Seed 3225216943, day 2,
      tile (152,103):
      **a)** a calm area sits directly against the border, although M47 shipped *"calm ground is
      never at the edge"* — check `_zone_fits` and the single-block calm placement separately,
      they are different code paths;
      **b)** a road runs into the border and stops in the grass instead of teeing into the boundary
      corridor;
      **c)** people walk out onto the border as if it were pavement and vanish there — *"nobody
      should be walking there since it is not a walkable area, they need to turn like the cars on a
      t-junction"*, and the player is right: **`CrowdAgent._blocked_ahead` returns `false` for a
      tile out of bounds**, so the one wall that should stop them is the one it reports as clear.
      Every agent already runs the divert (`_process` calls it for walkers and cars alike), so the
      fix is likely to be *out of bounds is blocked* and nothing else — which would take **b)**
      with it. Check it against the **spine exits**, which are the one place a car is meant to
      leave the map. The first note here blamed M46 growing the crowd's box; that is how far they
      get, not why they are out there;
      **d)** the fence again
- [ ] **The same faults on the north and south borders.** *"Same issue with other borders."*
      Whatever fixes the east has to be stated over **a border** rather than over one side of the
      map: the first border pass wrote four sides four times, which is one bug per side waiting to
      happen, and this is it happening

## M69 — Reachability is a grid of two-tile cells · built 2026-09-03

*(2026-09-03, playtest 20: "barriers don't take into a account that parks can be entered where
normally buildings would be making them ineffective. (at the same time a courtyard can be completely
sealed off by a barrier because it blocks the entrance alley). the same applies to alleys. the
reachability checks need to take alleys and parks properly into account. it's not enough to reach a
block.")*

**The design moved twice before it was built, and the second move came from the player.** The first
shape was hand-modelled openings — *"alleys should become edges. parks should have edges at all 8
exits. courtyards only have one edge to one road section segment"*, with a follow-up that *"nodes and
edges need to be more granular"*. That was drafted as: a node per opening (alley mouth, courtyard
archway, park frontage), an edge per stretch of street between two consecutive openings. **It was
dropped in favour of a uniform grid** — *(2026-09-03: "how about making every 3x3 tile block a node?
that should cover it? … and the 2 wide alley just connects in two connections instead of 4")* —
because coarsening the tile map lets every geometric fact fall out of the tiles instead of being
enumerated by somebody, and it covers the cases nobody thought to enumerate: squares, the home notch,
precincts, big buildings, dead ends, and a park that stopped being calm this morning.

**The cell is two tiles, and three was rejected on arithmetic.** The lattice period is `BLOCK_SIZE`
(8) + `STREET_WIDTH` (6) = 14 tiles and the map is 160 tiles square. Three divides none of 6, 8, 14
or 160, so a three-tile cell straddles the kerb at a different offset in every block and a
part-building cell needs an invented threshold — the same physical situation getting different answers
in different parts of the map. Two divides all four, so every cell is wholly street or wholly block,
and it makes `ALLEY_WIDTH_TILES` (2) exactly one cell, which is the "two connections instead of four"
the proposal was after.

**A cell is not one node, and the first write-up of this was wrong.** *(2026-09-03: "doesn't the
content of the 2x2 super tile define which of the four sides are connected?")* The rule as first
written — a cell is walkable when any tile in it is — walks straight through a one-tile building
sliver, and `CityGenerator._keep_nonempty` keeps slivers on purpose because dropping them leaves
`BUILDING` tiles with no building node over them. So a cell contributes **one node per 4-connected
component of its walkable tiles**: sixteen masks, of which the two diagonals split into two
components. That makes the grid the tile graph contracted, which is also its verification — it has to
agree with `CityMap.walk_field` over a sweep of seeds.

**Measured, and the worry did not exist.** The diagonal-split masks occur **zero times in 76,800 real
cells** across a twelve-seed sweep. The lookup table is kept anyway, since a hand-built map forces it
and nothing guarantees a future block layout never will.

**Two findings from reading the code that made the rest safe.** Every production caller of
`StreetNetwork.route_count` — a unit-capacity max flow counting edge-disjoint routes — asks for a cap
of **one**, so nothing that ships counted distinct routes; only a test asked for two. That was the one
thing a cell grid would have broken, since a six-tile street is three parallel cell columns. And
`RoadClosure.tiles()` blanked the whole street on its own stated argument that *"the ground between
them is not somewhere anyone can get to"*, which is false wherever an alley mouth or a courtyard
archway opens onto the middle of it — and both land mid-segment by construction.

**What the grid is for is a placement rule, not a check**, and it is the player's own asymmetry:
*(2026-09-03: "the planner shouldn't put a barrier next to a park anyway (it will never close the
street) it only makes sense for courtyards (we need to check the entry and potentially move it)")*. A
park is walked *through*, so a barrier on any of its access streets closes nothing and reads as broken
to anybody standing beside the open ground; a courtyard is a pocket with one door, so a barrier beside
it is real except on the one street its archway opens onto. Built as an outright exclusion from the
candidate pool rather than a weighting, which is this project's rule that closures are checked before
they are accepted and never repaired afterwards. It refuses a mean of **33.4 of 264 lattice segments
per day**, and every one of 168 (seed, day) pairs refuses at least one.

**"Move it" was read as moving the barrier, not the archway**, since a block's purpose may never move
a walkable tile and the archway is generated once for the run. Recorded as a reading rather than a
quotation, and open to overturn.

**Drawing the corridor at cell granularity turned out not to be a drawing change.**
*(2026-09-03: "make sure to draw the paths in that granularity as well instead of the whole block side
what it does now")* A cell-snapped stroke over a tree made of whole block sides is the same shape two
tiles wide, so `RouteTree` had to grow on the grid for the picture to change. That also made it M64's
precondition: against a block-side tree, *closed everywhere off the path* would seal every park
crossing and every alley in the city.

**Four things the build found that the design, settled from outside the code, had wrong:**

- **"The two routes to one area share no street by construction" is no longer true.** They share no
  *cell*, and a street is three cells wide, so on a rare street both routes' cells resolve to the same
  `StreetNetwork.Segment` and one covering-set site legally covers both. `docs/CITY.md` and
  `docs/EVENTS.md` said the old sentence in three places; two tests moved from absolute assertions to
  measured floors.
- **A real bug in the access-street search**: it could stop on a street a calm zone had absorbed into
  its own interior — an apartment complex's archway crossing its own absorbed street — and call that
  the way in. Fixed by requiring the segment to still be in the lattice.
- **`Corridor.depth()` is a hybrid rather than pure cell depth.** Pure cells narrowed the on-corridor
  band to a third of a street's width and collapsed the event placement proportions (37% on-corridor
  against a required 45%, 12% gap-wall against 20%), so street tiles keep the junction-graph BFS and
  everything else uses cell depth.
- **`RouteTree.rim()` went back to the junction/segment computation.** Grid depth broke *"every gap is
  on the rim by construction"* once the tree could shortcut around a gap through calm ground, and that
  guarantee was always stated at the segment grain.

**One guarantee is knowingly weaker, and the player agreed to it on 2026-09-03.** M53's assertion that
nothing ever stands inside a hard blocker was `frames_with_one == 0`; it now tolerates one agent on
under 5% of frames, measured at 1.1% — one car on 27 of 2400 frames, against the eight-at-once on 87%
of frames that the original M53 fix addressed. The cause is in `src/crowd/`, which this milestone
never touched: `CityGenerator._place_hard_blockers` grows one reference route tree and hands it to both
the dead-end and the big-building placement, so a cell-grown tree moved a big building to where a
queued car's crawl-forward step grazes its footprint. Filed as its own queue item so the assertion can
go back to zero.

## M66 — The dusk map shows what the player did · built 2026-09-02

*(2026-09-02: "the dusk picture should contain the entire route a player took", and "prioritize the
telemetry update to show what the player actually did during the play on the second day picture —
where they went, which events they activated, where they ran.")*

**The plan with what happened to it drawn over the top**, which is the shape the dusk map already
had for the resistance marks. Three layers: the trail she left, the stretches she ran, and which
planned events actually reached her.

**Sampled by distance, not by frame**, so the trail is bounded and framerate-independent — a
180-second day is a few hundred points at one per tile, and a rig at 400fps and a player at 60
produce the same picture. It is a list in memory handed to the renderer at dusk; nothing is written
per sample and the log's format does not change.

**Met means she entered the event's own `outer_radius`**, the field she can feel — not that
`EventManager.stream_around` had loaded the row into the world at 900px, which is more than twice a
typical row's reach. *"Was near it" and "it reached her" are different days*, and only the narrow
question says whether a placement did anything. Kept keyed by the plan object itself so the map can
ask about the same list it is already drawing, and once met stays met: streaming a row out and back
does not un-meet it.

**The rig had to be fixed before the feature could be photographed.** `--walk` held one direction
for the whole run, so every dusk map was a speck at the first building on that heading. *(2026-09-02:
"why not allow for a sequence of button presses? like 1s5e meaning 1 second south then press 5
seconds east — that way you get a guaranteed path that is not stuck.")* `--walk` now takes a script
of timed presses, pressing the same `move_*` actions a keyboard does, backwards compatible with the
bare direction words. **Deterministic is the point**: the same script on the same seed walks the
same route, so a picture of it is reproducible evidence rather than one run that happened to go
somewhere.

**One map was diagnosed as a renderer defect and was not.** Pixel-diffing dawn against dusk showed
the trail drawn correctly, hugging the bottom tile row where nothing at a glance would find it. The
wrong diagnosis was the orchestrator's; recorded so the next reader does not go looking for a bug
that was never there.

**The committed evidence carries no met pip**, and that is stated rather than re-run for a
flattering picture: the only row that reached her was sited by the director ahead of her and has no
dawn position to draw. The pip is proven by the suite instead.

## She stops flickering on the diagonal · built 2026-09-02

*(2026-09-02: "when going diagonally the graphic flickers — only change the graphic once it goes
over 50 degrees or below 40 degrees and stick with the previous graphic otherwise.")*

**A hard switch on 45° with a facing that wobbles across it.** `_draw_mother()` and `_draw_pram()`
each asked whether the facing was more horizontal than vertical, so a diagonal walk flipped the
drawing frame by frame. The fix is a 40°/50° hysteresis band: side-on below 40° off the horizontal,
front-or-back above 50°, and in between whatever was drawn last.

**One decision, not two.** It is computed once a frame into a shared member both drawings read —
two independent hystereses would let her face one way while the pram faced the other, which is
worse than the flicker it would be fixing. A doorstep placement or a rewound day resets it rather
than carrying it, because a day that did not happen has no last frame.

**The east/west mirror needs none**, and this was reasoned rather than assumed: turning from mostly
east to mostly west sweeps through mostly north or south at 12 rad/s, deep inside the front-or-back
band, so the sign has settled long before the side view returns.

**Two neighbouring sign tests were left alone deliberately.** The pram's own column test already
argues for a distance rather than an axis test, and its boundary sits at due north; the y-sort check
flips at due east. Both are far from the diagonal and neither was ever exposed to this.

**The test is the interesting part**: `tests/test_stroller.gd` oscillates the facing between 40° and
50° and asserts the drawing never changes. One that only probed 0° and 90° would have passed before
the bug existed.

## M67 — The page is a thing people share · built 2026-09-02

*(2026-09-02: "use the pram logo for social media for the nappy.josuakrause.com page, too", "add
other social media info in the html head", and "the asset license is just an md file with custom
text — should we get a proper named license for the assets?")*

**The card image had to be published, not merely pointed at.** The Web export packs everything under
`assets/` into the `.pck`, and the deploy workflow uploads only `build/web`, so an `og:image`
pointing into `assets/` would have unfurled as a blank card while being perfectly correct markup.
`deploy.yml` copies the logo to `build/web/social-card.png` after the export, which is the path the
tag promises. **`assets/logo.png` over `assets/icon_stroller_1280x640.png`**, both being 1280×640:
the logo is already the game's public face on the README, so the shared link and the repo's front
door show one image rather than two, and it carries the wordmark for a client that renders only the
picture.

**Every attribute is single-quoted**, because `html/head_include` is one long double-quoted `.cfg`
value and a literal `"` inside it ends the string early — a failure that would have looked like a
broken export rather than like a quoting bug.

**The asset licence is CC BY-NC-ND 4.0, and the badge still will not say so.** The full legal text
ships in `LICENSE-ASSETS.md` with the project's own paragraph about which paths each licence
covers, which no licence supplies. **It is one deliberate loosening**: CC BY-NC-ND permits verbatim
sharing with credit, which "all rights reserved" did not; selling and altered versions stay
forbidden. What was asked for and did not arrive is the name on GitHub — its detector matches
against the choosealicense.com corpus, which carries CC BY 4.0, CC BY-SA 4.0 and CC0 and
deliberately excludes every NonCommercial and NoDerivatives variant, so **no filename makes it show
as a name.** *Open to overturn: the only way to a second named badge is a licence in that corpus,
which means giving up either the non-commercial or the no-derivatives half.*

## M60 — What a thumb can reach · built 2026-09-02

**Every lesson the game teaches named a key.** The run hint said *Hold SHIFT to run* on a phone,
found by playing the deployed build. The audit that followed — *"check all tutorial lines for mobile
versions"* — found exactly two more lines with no touch form: the day-1 walk lesson and the pause
lesson. **The negative half is the useful half**: the title and pause bodies, and every
*space*/*tap* hint on the title, the pause screen and the between-days summary, already chose their
wording from `TouchInput.available()`, and *q to quit* already appeared only where
`QuitOption.available()` says quitting does something. Recorded so nobody audits those screens again
to find nothing.

**The wording matches the control rather than inventing a name for it.** *Hold RUN to run* reuses
the pause screen's existing touch body character-for-character, and *Drag the stick to walk* does
the same, so two screens never call one control two things. The pause lesson says *Tap the pause
button to pause* — a description, because the button is drawn as two bars with no text on it, and a
line quoting a label that is not on screen is the defect the whole audit exists to fix.

**The pause button is the one control that cannot press its action.** The stick and the `RUN` circle
call `Input.action_press`, and `main._unhandled_input()` reads the pause off the propagated *event*
— so pressing the action would set the state and be heard by nothing. It sends an `InputEventAction`
through `Input.parse_input_event()`, the shape `tests/test_pause.gd` already builds by hand. It
fires on a clean release inside the button rather than on touch-down, so a thumb that lands wrong
can slide off without stopping the day. **A first test failed for the honest reason**: it asserted
polled `Input` state after sending an event, which is not set synchronously.

**Placed at (1250, 30) with a 26px disc and a 46px catch** — small, because it is pressed once a day
at most, unlike the stick's 60px reach and 100px catch. The two other things that live near an edge
were checked rather than assumed: the screen-edge danger badges, and `HomeArrow`, which draws no
closer than (1206, 74) while hugging an edge.

**The meters move to the top left on touch only.** *(2026-09-02: "let's also move the progress bars
to the top for mobile so they're not hidden by the finger.")* The bars sat 18px above the bottom
edge, which is the quietest corner of a desktop screen and the busiest part of a phone. The anchors
move on the one node rather than a second HUD scene existing to be changed twice forever; the
desktop layout is untouched, since nothing is in front of it there.

**Landscape is asked for, not enforced, because it cannot be.** `progressive_web_app/orientation=1`
is only read from an installed PWA manifest, which this build does not write. So `html/head_include`
carries a `screen.orientation.lock('landscape')` attempt — wrapped so a rejection or a missing API
is silent, since Chrome for Android needs fullscreen for it and iOS Safari has no such API — and,
because that lock cannot be relied on, a CSS overlay that asks. It keys on `orientation: portrait`
**and** `hover: none` **and** `pointer: coarse` together, so a narrow desktop window is never told
to rotate.

## M63 — It plays on a phone · built 2026-09-02

**Asked for by the site being live and unusable on a phone.** *("I can't start the game on mobile —
there is no space", "the title screen requires me to press space".)* Three screens were gated on
`ui_accept` and nothing anywhere handled a touch, so the page could be reached and not started; past
that there was no way to walk either.

**The fork that was put to the player**, because the two answers wanted opposite things from the
title screen: make it playable, or say honestly that it needs a keyboard and stop. **Playable.** A
third option — tap-to-start only — was offered and argued against here, on the grounds that it turns
a visible dead end into a quieter one: you would tap in and meet a game you cannot steer.

**The stick and the button press the same actions a keyboard does.** `Input.action_press(name,
strength)` on the four `move_*` actions and `run`, so `Stroller` never learns where its vector came
from and no gameplay code changed at all. That is the whole reason this was cheap.

**Running is a separate held button and may never be a stick threshold**, which is the one decision
in here that is about the game rather than about input. `Stroller` moves toward `input_dir *
top_speed` with the **raw** vector, so a partly deflected stick is *already* a slower walk — making
running the far end of that same push would turn the one deliberate act in the game into a gradient
a thumb crosses by accident. The two controls read independent touch indices and sit at the same
height on opposite screen edges, so a steering thumb never crosses a holding one.

**A touch device is `DisplayServer.is_touchscreen_available()`, not `OS.has_feature("mobile")`**, and
the reasoning generalises: this game ships as **one** Web export that runs unchanged whether the tab
is opened on a phone or a desktop, and a feature tag is baked in at export time — so it would answer
identically for every visitor and could never drive "the controls appear only where they are used".
*Cost accepted: a touchscreen laptop gets the overlay beside a perfectly good keyboard, which is the
smaller of the two mistakes next to a phone told to press a key it does not have.*

**Two teaching bugs were found by playing the same build and fixed alongside it.** The day-3 run
lesson was once per **run**, and a lost nerve is not a new run — `main._start_day()` restarts the day
on a HUD that is never rebuilt, so the second attempt at day 3 was the first one that had already
spent its lesson and every attempt after it stayed silent. The flag now belongs to the *attempt*: a
nerve is a rewind, and a rewound day has not been taught anything. *(This side's first hypothesis —
that the signal fires at instance creation rather than at the encounter — was wrong, and the player
supplied the actual cause.)* And `_teach_the_pause()` read a **detained** player as having stopped of
her own accord, offering the pause key at the exact moment her controls were taken away; it is now
stated over the class — *idle **and** nothing holding her still* — because the HUD also keeps
counting behind the title, the pause and the day summary, all of which pause the tree.

**What nobody has verified**, and it is most of the milestone: no thumb has touched any of it. The
controls are built, tested and screenshotted on a desktop, which proves only that they stay *off*
where they should.

## M60 — What the live site changed · 2026-09-02

**The first deploy went green on its first run** — gate, export, upload, publish — and
`https://nappy.josuakrause.com/` served the game: 5.4 KB of HTML, a 39.5 MB WASM binary, a 950 KB
pack and a 280 KB loader. That run is also the first time the Web export completed anywhere.

**Then it was played, and two things had got through the dev-flag gate.**

**The developer's readout was on screen for the whole run, in every build**, and the cause is worth
keeping because it is a shape rather than an oversight: `main._open_the_title()` hid the readout and
`_on_title_start()` — which fires every time the player presses space — set it back to an
unconditional `true`. A gate applied at one of two sites is not a gate. It is now read once into a
member both sites and `_ready()` share, the string is not assembled at all outside a debug build
(the readout scans every live event for its "nearest" line, sixty times a second), and
`tests/test_main.gd` drives `_process()` with that member flipped both ways.

**`Q` quit on a platform where quitting does nothing.** `SceneTree.quit()` on a Web export leaves
the tab exactly where it was, so the key was a screen telling the player to press something and
watching it fail. `QuitOption.available()` is the single answer, and **the axis is the platform, not
the build** — a debug web build has the same dead quit as a release one, which is the same axis the
run log already uses to stay silent on the web. *(Player, 2026-09-02: "**only** for the online
version, for the local version Q needs to exist still.")* The pause screen needed a second fix on
the way: its hint was never set in code at all, only baked into the scene, so it could not have
varied. Both scene files now bake only the half that is always true.

**And the window letterboxes.** *(2026-09-02: "everything that doesn't fit the aspect ratio should
be filled in with black bars.")* `window/stretch/aspect` was `expand`, so a wider window showed
**more city**. That is a fairness change and not only a framing one: `DangerEdge` — the chevrons
warning about what is coming while it is still off screen — is measured in screen pixels and asks
*is this on screen*, so a 21:9 monitor bought more warning than a laptop, on nothing the player did.
`keep` is the value that bars **both** axes; *rejected: `keep_width` and `keep_height`, each of which
letterboxes one axis and keeps growing on the other.* `tests/test_danger.gd` now pins the setting, so
a silent revert fails a test rather than only a screenshot.

**One brief was wrong and the agent caught it.** The letterbox agent was pointed at a `TODO.md` entry
that did not exist on its base — the entry had been written on an unmerged branch. It grepped the
whole queue, the archive and the playtests for it, found nothing, proceeded on the self-contained
specification in its prompt, and said so. That is the fork rule working in the direction that is
hardest to notice.

## M60 — Ready for a GitHub Pages launch · six of seven built 2026-09-02

Six items across two agents run in parallel — the deploy chain and the HUD — partitioned by file
rather than by topic, which is what made them safe to merge one after the other.

**The gate is `OS.is_debug_build()` and the point is that it is one gate.** `DevFlags` reads the
command line through a single choke point that returns nothing outside a debug build, so every
flag answers *not given* in an exported release rather than each getter remembering to check.
`AutoScreenshot` gates its own entry point in place, because `--screenshot`, `--after`, `--walk`,
`--flee` and `--press` are parsed there rather than in `main.gd` and moving them would have been a
rewrite. **`--no-telemetry` is deliberately not gated**: it is a documented player-facing opt-out,
not developer furniture.

**Two holes in that gate were found in review rather than by the agent.** `--no-title` read the raw
command line, so a release export could still be told to skip its own front door. And the deploy
workflow ran the export without running the suite: both workflows fire on the same push and neither
waits for the other, so a deploy inheriting CI's verdict would publish a red build to a public
address as often as not. The gate now runs inside the deploy job — a few minutes on the rare push
that reaches `main`, against publishing something nobody checked.

**The telemetry gate is on the platform, not on the build.** `Telemetry.begin_run()` returns early
when `OS.has_feature("web")`, inside the function rather than at its one caller, so a second caller
cannot reintroduce a run log on the one platform where nobody can read or clear it. *Rejected:
gating on `OS.is_debug_build()`, which is the wrong axis — a debug web build must be just as
silent.* The determinism invariant is untouched: the desktop test binary never carries the `web`
feature tag.

**Canvas policy: adaptive**, matching the `canvas_items`/`expand` stretch the desktop build already
uses. *Rejected: a fixed canvas, which would have been a second sizing behaviour to maintain
against a desktop build that already handles arbitrary windows.*

**The HUD is one HUD with a gate rather than two HUDs**, and the implementation detail that makes it
testable is the whole of the item's risk: a test process **is** a debug build, so a gate asking
`OS.is_debug_build()` at each use site would leave the release shape asserted by nothing at all. It
is read once into a member a test can set, and `tests/test_hud.gd` drives both shapes.

**The optional goal keeps `somewhere out there:` and loses the progress dots.** The dots were the
orchestrator's call, on the grounds that a count of how far in you are is the same category as
`nerves ***` in the header. The words were a correction in review: the release line had been the
step's title alone — *a chalk mark* — which says a noun where the whole content of what survives the
cut is *go and find this*.

**What nobody has proven, and both need the same event.** The export has never run to completion:
the templates are not installed on the machine it was built on, so what was verified is that
`tools/export-web.sh` reports their absence with an install pointer rather than a stack trace. And a
workflow only proves itself by running. Both resolve on the first push to `main`.

## M53 — The precinct is for walking · built 2026-09-02

*(2026-09-02: "there should be no zebra cross markings or cars in a pedestrianized precinct — all
roads leading up to a precinct should be t-junctions at the edge nothing should go in.")*

**The question that produced this should never have been asked.** The queue carried the item as
*two recorded instructions in tension, and the player decides*. Only one of them was recorded —
playtest 16's finding 2, which already named both answers. The other was
`CityGenerator._street_tile`'s own docstring defending what the code did, and a docstring is
evidence of what was **built**, never of what was **agreed**. The player's reply was *"where does
that question even come from?"*, and the answer is: from this side treating the two as equals.

**Two halves, and neither is correct without the other**, which is why they are one commit. Paving
the junction box removes the zebra; on its own it would have left a car on the crossing street
driving over unmarked pavement, which is worse than the paint and invisible. `is_driveable_at` now
asks **both** corridors that meet at a tile rather than only the one the car is following.

**The drawing needed no code at all.** The ground painter already gives any tile in a precinct band
the precinct's brick, so the repainted tiles picked it up — the shot in `docs/evidence/`
(`shot-2026-09-02-seed4242-4442e68-precinct-street-ends.png`) is the carriageway ending flush at the
paving with no zebra and no car in the band.

**M49's *junctions are four-way where an arm dead-ends* did not reproduce here, and structurally
cannot.** Once either corridor is a precinct the whole box is one flat sheet of paving with no
per-arm kerb or line art, so there is no directional drawing left to be wrong. Three candidates ruled
out, entry still open.

**The wall-share floor moved from 25% to 20%, and the first attempt at it was the wrong shape.**
`tests/test_events.gd` asserts that a real share of the gaps between adjacent route strands carry an
off-corridor wall. Measured on the same map and the same sampled days, that share fell from 26 of 89
to 21 of 89 once the box was paved: the rows that place on a carriageway — the patrol, the
checkpoint — cannot sit in a gap running through a precinct. *Rejected: taking those gaps out of the
denominator, which is what the check's meaning would want.* It cannot be determined honestly from
geometry — `EventScheduler._role_for` assigns the `WALL` role from a row's cost and lethality and
never consults where the row may be placed, and most rows place on `SIDEWALK`, which a precinct gap
still has. Answering *"could anything have walled this gap"* properly means cross-referencing every
active day's wall-eligible defs against their placement lists, machinery the rig does not have. An
exclusion built on geometry alone would have been wrong in the same direction as an unexplained
floor, with a better disguise. So the floor moved with the measurement recorded beside it — and the
direction is the design rather than a loss: fewer walls in the one stretch of city whose whole point
is that it is the safest ground in it.

**Found and not fixed**, filed in `TODO.md`: seed 24757 has two non-walkable tiles inside a precinct
span, because something with a footprint was placed across the corridor — pre-existing, and caught
by the new generation test rather than caused by it. And nothing in the game **draws a bollard**,
though six comments and two doc sentences explain a precinct by saying a driver meets a bollarded
street: the carriageway ends flush against paving, which reads as the road running out rather than
as a street closed on purpose.

## M56 — The resistance is noticed · `feature/the-city-notices`, partly built

Four of the six items shipped on 2026-09-02. "Other dangers like this" and the measurement against
the nerves are still queued; the design for both is in `TODO.md`.

### The van takes somebody, and then it takes you · built 2026-09-02

Two commits. `HEAT_HUNTS_LEVEL` is **3** of four, on the player's own instruction — *"after the
patrol but still early enough to happen more than just once"* — so the ladder's three steps land in
three separate moments rather than two of them arriving together.

**The victim is the event's own scripted figure and the precedent that matters is what it did not
do.** Nothing in the catalogue has ever acted on the crowd; the van still has not. The take is
drawing and one telemetry entry, it begins the first time she comes inside the van's own 250px
field — the design's sentence was *it only means anything where she can see it happen*, so a van she
never approaches takes nobody — and it refuses to start without enough of the van's remaining life
to finish in, because a take cut short by the van expiring mid-walk reads as a bug rather than as an
abduction.

**The heated shape moves only what the rung is about.** Population and intensity are `PRESSES`'s
axes and `HUNTS` touches neither; the test states that at *every* level rather than only below the
threshold. At and above it the derived copy gains `pursues`, 130px/s (the one speed everything in
this game pursues at), a 180px trigger sitting between its 132px stand-off and its 250px field, and
`Tuning.PURSUIT_TIME` as the chase length in place of the 34s idle. The 4.6s telegraph is unchanged
and that is deliberate: for a pursuer a telegraph buys the *notice of it coming* rather than an
escape distance, and 4.6 is comfortably over the 1.5s floor.

**The body is there exactly while it stands still**, which is the existing rule rather than a new
one. A heated van waiting at the kerb is solid at 22px like any parked vehicle; the frame it stops
waiting, the obstruction is freed, because a moving pursuer with a body is a wall that can pin her
against a building on a two-tile pavement.

**A consequence documented rather than fixed:** a heated van is *briefly less dangerous* than a cold
one. Nothing is lethal while it is only `is_waiting()`, so a van at the kerb can be brushed past for
free until she comes inside its trigger — the same shape `alley_robbery` has always had, now that a
second row carries it.

**The screenshots, and one of the two questions came back weaker than the report claimed.**
The hunting shot in `docs/evidence/` (`shot-2026-09-02-seed2422590514-5fa7bd8-abduction-hunting.png`)
answers the menacing-or-comic question well: the van end-on, closing, with the caret over her at a
zebra — it reads as a thing coming for you rather than as a van at a fast walk. The victim shot
(`shot-2026-09-02-seed2422590514-5fa7bd8-abduction-victim.png`) is the weaker one. It reads as
*a person standing beside a van*, not as a person being taken: the figure is upright and unheld,
and the whole of the
"taken" is carried by it walking in and vanishing over 2.5s, which a still cannot show. Worth a
second look from somebody watching it happen before deciding the posture is enough.

**And the hunting van drives on the footway.** A pursuer steers straight at her over any walkable
tile, so a van chasing her along a pavement is what the mechanic produces. It is what every pursuer
in the game already does and it is the first time the thing doing it is four metres of metal.

**Three choices open to overturn**, made where the design was silent. The walk takes **2.5s** from a
**32px** standing offset — both picked by the implementer, neither derived. The `taken` entry is
written by `EventInstance` itself rather than by `EventManager`, which is a new precedent for who
writes the log: the argument for it is that the scene needs nothing the instance does not already
carry, which is what lets a rig assert it with no map or city behind it. And the four copies of
`130.0` across the pursuing rows were deliberately *not* collapsed into one shared constant, being a
separate change from this one.

**The three forks that were put back to the player, and what each rejected.**

- **Heat is a declarative field on `EventDef` rather than extra days.** Adding
  `resistance_progress` to the day number the scheduler plans against would have reused
  `budget_for(day)` — the linear growth in the event budget — for nothing. Rejected because it also
  moves `first_day`: a player doing well at the optional path would meet act III's vans in act II,
  and the calendar `docs/EVENTS.md` publishes would stop being what the game does. A third option,
  heat raising only how many dangerous rows a day places, was rejected as unable to express "the
  van comes for you" at all.
- **The patrol's escalation moves population, intensity and whether it investigates — not its outer
  radius.** Widening the 185px field is the axis that most obviously changes routing and also the
  one that costs something invisible: `Tuning.required_telegraph_time` is stated over the gap
  between the inner and outer radii, so a wider field silently owes a longer telegraph than the
  1.7s the row ships with.
- **A pursuer is exempt from M28's clearance rule**, rather than the hunting van losing `hard_fail`.
  The alternative kept a rule intact by contradicting the instruction that produced the van.

**Why the heated row is a derived copy rather than a mutation**, which is the load-bearing
implementation choice. Mutating a row in place is fewer lines and breaks the one thing this project
checks on boot: `EventDef.validate()` and `Tuning.validate_pursuit()` run once, over the catalogue,
from data. A def that changed shape mid-run would be validated in the shape it booted in — the
harmless one — and the fairness contract would be stated about a version of the event that no
longer exists. Progress is a bounded integer, so the set of shapes is finite and all of them are
checked.

**What the pursuer exemption turned out to be, which is neither of the two answers expected.** The
clearance rule is `EventScheduler._keeps_its_field_clear`, and it read
`plan.def.hard_fail and plan.role != WALL`. Because `_role_for` routes *any* placed `hard_fail` row
that is not a `ONE_SHOT` to `WALL` before it ever asks whether the row pursues, every lethal pursuer
in the catalogue was **already exempt by accident of that classification** — `charging_dog` because
it is `AHEAD_OF_PLAYER` and never reaches the check at all, `alley_robbery` because `hard_fail`
always routes it to `WALL`. So the answer to "was it already true or did it need fixing" is both: it
held, and it held for a reason nobody had named, and a lethal `SET_PIECE` pursuer would have fallen
straight through it, since kind is checked before `hard_fail` in `_role_for`. The rule is now stated
over `pursues` directly, and `tests/test_events.gd` pins it by forcing a pursuer into a non-`WALL`
role, with a lethal non-pursuing row in the identical forced role as the control.

**Two things the implementing agent chose where the design was silent, and they are open to
overturn.** `is_telegraphing_still()`'s guard was left off the new patrol-while-waiting branch,
because `is_waiting()` implies `not is_telegraphing()` by construction and the check would be dead
code. And `docs/EVENTS.md`'s clearance paragraph had never documented the `WALL` exemption at all —
the agent filled that gap in the same edit rather than adding a third case beside two undocumented
ones, which is slightly more than the brief asked for.

**The finding carried forward rather than fixed**, and it is in `TODO.md`'s small items:
`EventInstance.resume()` restores age and travelled distance but not `_noticed_at`, so a
`pursues_within` row streamed out mid-chase comes back `is_waiting()`, having forgotten it. Shared
with `alley_robbery` since the mechanic was built and never reachable before, because a stationary
pursuer's field never moves far from where the day planted it. `tests/test_heat.gd` pins the actual
behaviour so a fix fails there first.

**Measured, not derived:** a day 9 planned at full heat places more `police_patrol` instances than
the same day cold, from the same seed. Asserted as a relationship rather than as a count, because
the population multiplier raising the cap does not by itself guarantee more of them get rolled
against everything else competing for the budget.

## Delegating is the default, and the rule that says so loads at `SessionStart`

Asked for on 2026-09-02: *"make more use of sub-agents — you write plans, sub-agents implement
etc."*, and immediately after it *"make sure this is properly triggered automatically"*. Then, after
the first attempt: *"firing on src / test edits is still too late. how about making it a rule that
loads at the beginning?"*

**Three trigger points were tried, and the two that failed each failed in a way worth keeping.**

- **On an `Agent`/`Task` spawn** — the original, from the M55 session. It cannot ever say *this
  should have been delegated*, because a spawn is the decision already going the right way. It only
  governs how a delegation is written, never whether one happens.
- **On the first `Edit`/`Write` under `src/` or `tests/`** — the first answer to *"triggered
  automatically"*, and the reasoning behind it was the rules hook's own principle: the moment a rule
  matters is the moment somebody is about to touch the file. It is the right principle applied to
  the wrong rule. By the first edit the implementation has already started, so the rule arrives as a
  reprimand rather than as a choice — which is what the player's *"still too late"* names.
- **`SessionStart`** — taken. `.claude/hooks/session-rules.sh` injects the skill before the first
  tool call, and writes the same one-shot marker `project-rules.sh` uses, so the two path triggers
  stay as backstops and no-op. Verified by running both hooks against one session id: the second
  injects only `godot`.

**The generalisation, and it is the reason this entry exists rather than a note in the hook:** a
rule about *what governs this file* can be hung on the file, and a rule about *who should be doing
this at all* cannot. The list loaded at `SessionStart` is deliberately one skill long, because
everything in it is paid for in every session whether or not it turns out to be relevant — which is
the exact cost the path-triggered hook was built to avoid.

**What moved out of the skill in the same pass.** The orchestrating skill had accumulated its own
history — *"Asked for on 2026-09-01"*, the dated player quotes for each of the three instructions
above, and the incident that set the headless-first rule (an agent burning several windowed runs on
a `--walk north` rig that stood against the home notch's back wall for the whole run, since the home
is a notch with one exit facing south). All of it is here; the skill keeps only the rules and the
reasons. *(2026-09-02: "the skill now reads like a quest log — keep the rationale etc in decisions
and clean up the skills — THIS is the proper way to write anything.")*

## M50 — The city points somewhere · `feature/the-city-points-somewhere`

**The plan for the diversion design.** The design itself is `docs/CITY.md`, "Diversions — the
design"; this is only *how*. Nothing here is started.

**The one sentence: the corridor already exists in the code and nothing is allowed to see it.**
`ClosurePlanner._streets_on_a_route` computes, today, the set of streets on a near-shortest way
from the door to some calm ground — distances from home, distances to each calm area's access
streets, and a street counts if the best route through it is within `CLOSURE_ROUTE_SLACK` of the
best route overall. **That is a corridor.** It is private, it is thrown away every time it is
computed, it is unioned across all calm areas so the individual paths are lost, and the only thing
it is used for is weighting *which street to close*. So this milestone is much less about inventing
a structure than about **promoting one that is already there** and letting everything place against
it.

And one thing found by reading it, now decided: **closures are currently biased
`CLOSURE_ROUTE_BIAS = 5.0` toward streets that are on a route, and that flips.** *"A road block
becomes guidance and is not a hindrance. It flips its role."* Today a closure is placed where it
will be **met**, which degrades the good ways; under the design it is a **wall**, placed off the
tree to prune the ways that lead nowhere she should go. The purpose changes with it: a closure
used to exist to make a route harder, and now exists to make a route **obvious**.

Two consequences worth having in mind while building, because they run opposite ways. Closures stop
being a threat to winnability almost by construction — a wall sited off the tree cannot cut the
tree — which takes pressure off the two-routes check from the closure side. And the old sanity rule
inverts: *"a closure nobody would have walked is pointless"* was right when a closure was an
obstacle, and is exactly backwards for one that is a signpost.

### Step 0 — the tree, and it is a tree on purpose

**A tree, not a bundle of shortest paths.** *"Don't take the strictly shortest path. Aim for paths
that share prefixes. The paths to some calm zones might not be optimal or short but that is
okay."* This is the instruction that decides the whole structure, and it is why the day's plan was
called a **tree** from the first sentence of the design rather than a set of routes.

`_streets_on_a_route` is exactly the wrong primitive for it: it keeps every street within
`CLOSURE_ROUTE_SLACK` of the **best route to that area**, computed per area and then unioned — which
is the definition of *independent* shortest paths. Run it on a day with five calm areas and you get
five rays fanning out of the doorstep sharing almost nothing, which is a star, and a star has no
bundles, no chokepoints, and a fan-out equal to the number of destinations. Everything the placement
depends on comes from the sharing.

**The construction is probes and colours, grown from the calm areas back toward the door.**
*(The player's algorithm. It replaces a greedy Steiner attachment proposed here first, which was
worse: it needed a global cost function, it made the trunk point at whatever calm happened to be
nearest home on every seed, and it had nothing to say about the second route.)*

- [x] **Two probes at each calm area, walking in random directions.** Not one probe from home —
      the growth runs **backwards**, from every destination toward the doorstep, and the trunk is
      what is left where they have all come together
- [x] **A path carries the colour of its origin**, and both probes from one calm area carry the
      same colour
- [x] **Same colours may not merge.** The two probes from one area can never become one path, so
      where a second route exists at all the area is reached **two genuinely distinct ways**. It is
      an offer rather than a guarantee — see below
- [x] **Different colours merge, and the colours add up.** A probe that touches a differently
      coloured path joins it, and the joined path carries the **union** of both colour sets. Which
      is the elegant half: once the `A`+`B` path exists, `A`'s other probe is locked out of it by
      the rule above, so the guarantee maintains itself as the tree grows and nothing has to police
      it
- [x] **"Touch" means *merge*, not *be near*.** Non-mergeable paths may run **directly adjacent** —
      *"the player can walk the beginning of path A and then switch to path B without noticing"*,
      and that is fine, because both go to the same place. Optionally they can be separated with a
      road block, *"but that is not a hard requirement"*. So the constraint is on the graph, never
      on spacing, and any implementation that enforces a distance between paths has misread it

**The five details, answered:**

1. **A probe stops on either** — reaching the doorstep, or merging. A probe that gets home unmerged
   is a direct route and is finished.
2. **A step is a segment on the `StreetNetwork` junction graph.** Not tiles: a corridor is a set of
   segment keys everywhere else in this design, and tile-walking would produce something no other
   part can consume.
3. **Loop-erased random walk.** Wilson's algorithm — walk randomly, delete loops as they close —
   rather than a drift toward home. It is the standard tool for exactly this shape and it gives
   variety without wandering.
4. **Probes go out sequentially, and the second one is optional.** *"No swapping — if we send out
   the probes sequentially we can check if there is another path left, via a shortest path
   algorithm that avoids path A. Having two distinct paths is really a niceness to the user. If we
   cannot construct a path B at all, let's not try."* So: grow probe 1, then ask whether a route to
   that area exists **avoiding probe 1's segments**. If it does, that is probe 2. If it does not,
   the area has one way in and the day is fine.
5. **Hard blockers are placed against a tree, not before one.** *"First construct an example tree
   from the initial map, then place the hard blockers — that way we can't block off regions
   entirely. Then when a day starts we construct a tree for real."* So generation runs: lay the
   city → grow a **reference tree** → place hard blockers that leave it intact → and only then does
   each day grow its own tree on what is left.

### Dropping the swap removes every hard case at once

The swap was proposed to rescue a probe that could not merge, and it carried three problems: it
could ping-pong with no decreasing quantity so nothing guaranteed termination; it was undefined
against a **merged** path, where re-designating a tail carrying `{A, B, C}` would silently re-route
`B` and `C` and could collapse *their* second routes; and it could not fix a pocket anyway. **All
three are gone** — sequential probes with an existence check have no collision to resolve, so there
is nothing to ping-pong, nothing to re-designate, and a pocket is simply an area with one way in.

**What it costs is a guarantee, and that is a deliberate trade.** *"Having two distinct paths is
really a niceness to the user."* So a second route is an **offer the day makes when the map allows
it**, not a promise. This is the right way round — the alternative was a construction bending
itself to preserve a property nobody had asked to be absolute — but it has to be taken with the
consequence below open-eyed, not discovered later.

**The consequence: winnability loses one of its two protections.** `MIN_CALM_AREAS_WITH_TWO_ROUTES`
existed so that no single closure could cut every route to the calm. Under this design that
protection comes instead from **where a wall is placed** — off the tree, by construction — so the
redundancy is no longer the backstop, the placement is. That is coherent, and it means one bug in
wall placement is now the whole distance between a normal day and an unwinnable one. *(Taken
2026-08-31: the constant is `MIN_CALM_AREAS_REACHABLE` and asks for reachability. The count of
areas deliberately stayed at two — see "The two invariant decisions" below.)*

- [x] **Keep a reachability check as the last line.** `_ensure_the_city_is_still_walkable` /
      `_park_is_reachable` already asks only that *some* calm area is reachable, which is exactly
      the weakened guarantee and costs one BFS. **It was not deleted when
      `MIN_CALM_AREAS_WITH_TWO_ROUTES` went** *(2026-08-31)*, and neither was the closure planner's
      own check — it asks for reachability now instead of for two routes. Two independent
      mechanisms rather than one, cheaply, which is the difference between a placement bug being a
      bad day and being an unwinnable one

**And this makes step 1's gate much weaker, which is a gift.** *(Taken 2026-08-31.)* Hard blockers
no longer have to leave two edge-disjoint routes to every calm area — only **reachability**.
Cul-de-sacs and dead ends were always the point of hard blockers and the old gate fought them; a
`route_count >= 2` requirement would have refused most of the interesting ones.
`CityGenerator._the_calm_survives` uses `route_count >= 1` now, over every calm area rather than
over a count, because a hard blocker holds for the whole run: a day can be bad, a run cannot be
dead.

**Decided: B is the shortest remaining path.** The same computation that answers *does a second
route exist* also is the route — no second walk.

The reason is not simplicity, and it is worth keeping because it points the other way from the
usual instinct: **a shorter B puts less of the map in play.** *"The shortest path also reduces the
overall number of available blocks, which makes the area more approachable — the player feels less
lost."* A wandering B would be more interesting per street and would spread the day's ground over
more of the city, and being spread thin is the thing that reads as *lost*. The tree is a way of
saying *here is where today happens*, and a tight second route says it more clearly than a scenic
one.

**The known risk, recorded rather than designed away: B may run alongside A.** A shortest path
avoiding A's segments is often the next street over. That is **not a correctness problem** — the
design already blesses it explicitly, *"non-mergeable paths can be directly adjacent… the player
can walk the beginning of path A and then switch to path B without noticing"* — so what is at
stake is only whether the pair **reads** as two options or as one thick one. A map question, for
the first day this can be drawn, and the answer if it reads badly is a separating road block, which
the design already offers as optional
- [x] **`RouteTree`, in `src/routes/`.** Built from `map`, the day's closed set and the available
      calm areas. It holds, per calm area, the **branch** that reaches it; over the whole day, the
      **bundles** — edges carried by two or more branches — and the **fan-out**, meaning the
      smallest set of sites touching every route, which is what a set piece needs
- [x] **Leave `_streets_on_a_route` alone for now.** It is not `RouteTree`'s constructor and
      swapping it would change what closures do as a side effect of a refactor. `RouteTree` lands
      beside it; the two converge in step 2, where what a closure is *for* is being decided anyway.
      `StreetNetwork.junction_distances` is the piece that genuinely is shared

**Built, and here is what it came out as.** `src/routes/route_tree.gd` and
`tests/test_route_tree.gd`, measured with a throwaway probe over 32 planned days (8 seeds × days
1, 5, 9, 14) and deleted before committing, per the rule in `CLAUDE.md`:

| | |
|---|---|
| calm areas per day / branches grown | 7.6 / 7.5 |
| areas offered a second route | **241 of 241** that the map allowed one to |
| streets on the tree per day | 68.9, of which **50% carry more than one area** |
| probe 1 length vs the shortest way | **13.2 streets vs 4.4** |
| probe 2 length | 6.6 streets |
| fan-out | 2–6 sites against ~15 routes |

Three things in it are worth carrying, and the first two are corrections to what was written here
before anything was built.

**The fan-out covers *routes*, not branches — and covering branches is the design's own warning
arriving through the back door.** The item above said "touching every branch", which reads as the
obvious meaning of *"make sure all routes touch at least one of them"* and is not it: a branch
counts as covered when **either** of its routes is, and measured that way nine days out of 32 came
back with a **single** street. That street is on route one of every area and route two of none, so
a fire engine placed there is met by a player who takes the first way out of everywhere and missed
entirely by one who takes the second. It is *"the tile she must cross"* — which this design names
as its first draft's mistake — restated as a bug. Covering routes gets the right answer for
nothing, because the two routes of one area share no street by construction, so **no single site
can ever cover both** and the *"at least two places"* arithmetic falls out rather than being
enforced.

**A tail is everything hanging off a stretch, not the stretch that was just walked.** The
same-colour rule is enforced by asking whether a junction's way home already carries this area's
colour, and the first version marked only the junctions the probe had walked. That under-reports
transitively — a junction upstream of a merge keeps a tail that does not mention the colour — so
an area's second probe merged at it and then ran straight back down into the streets its first
probe had spent. **The two routes shared ground while every explicit check in the construction
said they could not.** `RouteTree._resettle_the_tails` recomputes the lot from the doorstep
outwards after each adoption, which is O(the tree) a dozen times a day and is the version whose
correctness can be read off the definition.

**And one measurement is a question rather than a result: probe 1 is three times the shortest
way.** 13.2 streets against 4.4, and the corridor is about a quarter of the lattice. That is not
a bug — *"the paths to some calm zones might not be optimal or short but that is okay"* is
explicit, and detail 3's random walk is what produces the variety the design wants. But detail 3
also claims Wilson's *"gives variety without wandering"*, and on a 12×12 junction graph it
measurably wanders; and the reason given for making probe **B** the shortest — *"reduces the
overall number of available blocks, which makes the area more approachable — the player feels less
lost"* — is an argument that points the same way at probe A. **This is a question for the player
and not a number to quietly bias**, and the map picture below is what it should be asked against.

**Asked, and decided 2026-08-31: leave it.** *"Let's try it like this for now and keep the other
options as potential improvements in the future if playtesting shows issues with the design."* So
the wander ships, and the two answers that were on the table are recorded here rather than
discarded.

**What they are not is pre-approved, and the earlier wording of this paragraph implied they were.**
*(2026-08-31, the player: "I want to make very clear that saying 'I'm feeling lost' is not an
endorsement of those ideas and doesn't count as approval. The most it does is bringing those items
back to discussion.")* It said the thing that would make one of them right is a playtest sentence
about feeling lost — which reads as a **trigger**: hear the sentence, apply the fix. It is not one.
A complaint says the design has a problem; it says nothing about which of these two is the answer,
or whether the answer is either of them. **A parked option comes back as a question, never as a
plan.** The same holds for every other option parked anywhere in this file against a future
sentence:

- **Cap the wander, keep the walk.** Re-roll a probe whose route exceeds some multiple of the
  shortest way. One constant, still deterministic, and detail 3 stays literally true — it is still
  a loop-erased random walk, it is just rejected when it rambles. The first thing to reach for.
- **Bias the walk toward home.** Weight each step by whether it closes the distance. Tighter, and
  it is the *"drift toward home"* detail 3 rules out by name, so it would be an overturn rather
  than a tuning. Only if the tight map turns out to be worth more than the variety.

**And the knob this creates has to be watched, because it cuts against winnability.** Sharing is
what makes placement cheap, and it is also what makes **one closure decide the day** — a trunk that
every branch runs up is a bridge, and cutting it takes all the calm with it. The design already
bounds this: *"you have to account for things to be potentially in one of two places at the very
least, in the ideal case where there are exactly two distinct paths."* So the rule is **maximise
sharing subject to at least two genuinely distinct paths surviving**, and the tree is never allowed
to become a single trunk. That is the same quantity as the invariant decision below, approached
from the other side, and the two should be settled together

### Step 1 — hard blockers exist *(once per run, and it gates everything)*

*"Cul-de-sacs and big buildings don't exist yet — but we need them to implement proper hard
blockers."*

- [x] **A cul-de-sac is an `absent_segment` with a dead end at one end.** The mechanism is already
      built and proven: M21's calm zones absorb the streets between their blocks, `absent_segments`
      is the set of lattice edges this city does not have, and `blocked_segments()` merges it with
      the day's closures. What is new is **choosing** them for a reason rather than as a
      side effect of a zone. Note the M21 rule that comes with it: an absorbed street is still
      *ground* — so a cul-de-sac must be a street that genuinely stops, not a park to walk through
- [x] **A big building is a block whose lot is solid**, removing the streets around it from the
      lattice. This is a `BlockPurpose` and an arc, per the "Add a block purpose" recipe
- [x] **They are placed against a tree, not before one**, in `CityGenerator`, from the city RNG —
      so they hold still for the whole run and are what the player learns. Grow a **reference
      tree** on the finished lattice first, then place blockers that leave it intact, *"that way we
      can't block off regions entirely"*. The gate is **reachability**, for every calm area the run
      will ever use including act IV ones — not two routes, which a cul-de-sac would fail by
      definition. The reference tree is the readable sanity check beside it, not the check itself
- [x] **`CityGenerator.validate()` gains the new condition** and it runs on every seed, like the
      rest. `tests/test_blocks.gd` already asserts the walkable set is identical tile-for-tile
      across every block arc — hard blockers must not move a walkable tile after generation

**Dead ends are built. What they came out as, and the three things worth carrying:**

**The gate stayed the strong one while dead ends were built, and the plan above is why that needed
a decision.** *"The gate is reachability — not two routes, which a cul-de-sac would fail by
definition"* is written just above, and it is a **weakening of a guarantee three other things rest
on**: `MIN_CALM_AREAS_WITH_TWO_ROUTES`, `ClosurePlanner`'s day-level invariant, and
`tests/test_routes.gd`'s *"an open city has two routes to everywhere calm"* all assumed the
generator hands them a city where it holds. Taking that as a **side effect of adding dead ends**
is the exact shape of overturn `CLAUDE.md` has a rule about, so the gate kept demanding two routes
until the invariant itself was restated — which happened on 2026-08-31 and is where the gate moved
with it. And the fear turned out to be unfounded either way: with candidates already off the
reference tree, **99% of them pass either gate**, and a city gets **5.9 dead ends against a rolled
4–8**.

**A dead end is a claim on the lattice paid for on the tiles, and calm ground beside one breaks
it.** Found by building it: `tests/test_routes.gd` failed with *"the way in (5, 11, 0) is a real
street"*, because a dead end had been placed on one of a four-block zone's eight ways in. The
graph said the street was gone; the player walks on tiles, and a street with a park down one side
is one you walk into and step **sideways** out of. It is M21's *"an absorbed street is calm ground,
not a closure"* read backwards, and the fix is a candidate filter: nothing beside calm.

**And `absent_segments` stopped being the zone set, which broke a test's sentence rather than its
assertion.** `tests/test_generator.gd` asserted *"no zone swallowed a stretch of the arterial"*
over every absent segment, which was the same set right up until dead ends joined it.
`CityMap.dead_ends` is the split, and it is worth having for its own sake — the two are absent for
opposite reasons and the telemetry map needs to draw them differently. The general shape is one
this project already has a name for: **an identity standing in for the property.**

**The picture had to be fixed too**, and that is a note about tooling rather than about walls: the
first version left a dead end showing through as ordinary building, which is a dark slab inside a
dark street and is invisible. A hard blocker nobody can find in the one picture built to check
placements might as well not have been placed. It has its own colour now.

**Big buildings are built too, and the interesting part is what they exposed rather than what they
are.** One or two per city: **two neighbouring blocks joined into one mass**, twenty-two tiles
long, with the one street between them built over and every other street around them left alone.
Chosen late and converted rather than assigned with the other purposes, because the choice needs
the reference tree, the tree needs the calm areas and those need the block layouts — by the time it
can be decided the blocks have already been carved. Three things came out of it:

- **The first version took the whole ring, and the player corrected it.** *(2026-08-31: "why do big
  buildings close off four streets each? a big building just connects two blocks… we can add a
  building type with all four roads closed but that's a different building type. but I want one
  that just connects two blocks (closes one road)".)* A block with all four of its streets built
  over is an **island in the lattice** — one roll of the dice removing four streets — where what
  was asked for is a landmark that removes one. The four-sided kind is recorded below as a type of
  its own and is not built.
- **A candidate list is a snapshot; a placement is a change.** The pool was enumerated once and
  the first big building's streets were news to the second one's check, so two of them shared a
  street and drew two buildings on the same tiles. It is re-checked at placement now. The same
  shape as M38's *"two placements in the same frame cannot see each other"*, one scale out.
- **And a density floor failed for a reason that had nothing to do with hard blockers.** Day 1
  planned 93 events against a floor of 96 on two seeds of eight, and the cause was neither lost
  ground nor the walkability cull (which drops nothing): it was
  `EventScheduler._ensure_one_usable_park` **stripping twenty-one events** — the spoilers of every
  calm area she has not used, removed *after* the fill has spent its budget. So the day plans to
  target and then falls short of it, and the budget has never accounted for the strip. `69 → 76`
  per block, agreed with the player, puts a typical day 1 at **121–125 placed — which is the
  stated one-per-block target it had been sitting 12 under** — and the worst seed at 102. It
  lifts days 1–7 and leaves day 14 alone, because day 14 is bound by the catalogue's caps rather
  than by the budget.

**And a defect was found on the way past it that is not M50's to fix.**
`_ensure_one_usable_park` returns early if **any** calm area happens to come out clean — and the
rule written underneath that early return is playtest 14's, *"every calm area she has not used
this act stays clean, not just one of them"*. So the newer, stronger guarantee only fires on days
where the older one already failed, which is a coin flip: on seed 4242 it strips 21 events and on
seed 90210 it strips none. That is the **old rule silently defeating the new one written under
it**, and it is why the density shortfall looked like a hard-blocker problem — a big building
moves enough placements to tip the coin. Worth its own item; see "Open design questions".

- [ ] **A building type that closes all four of its streets.** *(2026-08-31, recorded rather than
      built: "we can add a building type with all four roads closed but that's a different building
      type".)* It is what the first version of the big building accidentally was, and the code for
      it is in this branch's history — a block whose lot is solid with its whole ring taken and the
      four corner junctions kept. What makes it a different type rather than a bigger one is what
      it does to the lattice: a landmark that joins two blocks removes one street and leaves the
      grid around it, and this removes four and makes an island. So it needs its own name, its own
      count, and its own answer to *how many of these can a city take before the corridor has
      nowhere to run* — none of which the two-block one has to answer

### Step 2 — placement by role

- [x] **`EventScheduler.build_day` takes the `RouteTree`.** The phase list stays and gains the tree
      as an input; each placement phase gets a **role** and asks the tree a different question —
      walls for segments just *outside* a corridor, friction for segments *inside* one, set pieces
      for a covering set. Keep `_stream(base, salt)` per phase; a phase whose consumption changes
      needs its own stream, which is M39's rule and this changes several

      **Built, and the role turned out to be a property of the *row* rather than of the phase.**
      The item above says "each placement phase gets a role", and written that way it is wrong in
      the one case that matters: the recurring fill is a single phase and it places both the walls
      and the friction, because what decides which a thing is is whether it ends the day.
      `EventScheduler._role_for` is four lines and no row in the catalogue carries a role field.
      *(The phase salts did not have to move for the same reason — no phase changed how much it
      draws, only which tiles the array it draws from contains.)*

      Four things worth carrying:

      - **The mechanism is the precinct weight, not a new one.** A tile is offered to the roll
        several times over, so the roll, the spacing and the room measurement all keep working
        unchanged and nothing new can refuse a placement. **One thing is a rule and not a weight**
        — a wall is never inside the corridor — and that one is safe to state absolutely only
        because the rest of the city stays available to it.
      - **`Corridor` is the translation, and it had to exist.** `RouteTree` is segment keys and a
        placement is a **tile**, and sixteen rows of the catalogue stand on alley, park, square or
        courtyard ground where `segment_containing` returns null. A classification written over
        segments alone would have made `alley_robbery` unplaceable while the whole suite passed. A
        block interior answers for the four streets around it; a junction for the streets that meet
        at it.
      - **Measured, and the two numbers that had to *not* move did not.** Placed per day is
        identical (111 / 145 / 175 / 201 over six seeds), and so is the count of lethal rows —
        which was the real risk, since a `hard_fail` placement must clear its whole outer radius of
        everything else with no fallback, and refusing it a quarter of the city could have quietly
        stopped placing it. What moved is where: costly rows on the corridor 34% → 64% on day 1,
        lethal rows on the rim 63% → 80% on day 5. Measured 2026-08-31 over six seeds, per day, with
        both weights flattened to 1 and then at 4 — flattened is the honest control, since it leaves
        the *rule* in place and takes only the *preference* away, so what the arrows show is what
        the weighting buys:

        | | day 1 | day 5 | day 9 | day 14 |
        | --- | --- | --- | --- | --- |
        | placed | 111 → 111 | 145 → 145 | 175 → 175 | 201 → 201 |
        | costly rows on the corridor | 34% → **64%** | 39% → **63%** | 33% → **53%** | 31% → **52%** |
        | lethal rows on the rim | — | 63% → **80%** | 40% → **64%** | 31% → **59%** |
        | lethal rows placed | — | 8.8 → 9.0 | 16.7 → 16.7 | 17.0 → 17.0 |

        The share drifting down with the day is the corridor filling up and `EVENT_SPACING_SAME`
        pushing the overflow outward — the spacing rule doing its job rather than the weight
        failing.
      - **And it cost the suite time, which is worth writing down because the first version cost
        twice as much.** Every `build_day` now grows a tree, and `tests/test_events.gd` plans a lot
        of days. The first version also keyed the *whole ground scan* by role, so two passes over
        every sidewalk in the city ran three times a day instead of once — 44s → 88s. The role only
        ever re-weights tiles the scan already accepted, so it is a second pass over a list already
        in memory (`_open_ground_for`), and `Corridor` caches its answer per lattice cell rather
        than allocating an array per tile. 88 → 68s, of which about ten is the new test itself
- [x] **`ClosurePlanner` places closures as walls, off the tree.** `CLOSURE_ROUTE_BIAS` inverts:
      the weight goes to segments that are *not* on a branch, and preferentially to those leading
      away from calm. Keep the `_invariant_holds` check on each candidate — a wall off the tree
      should never fail it, so a failure means the tree and the wall disagree about where she is
      going, which is worth an assertion rather than a silent skip

      **Built, and it was taken first rather than second.** The bullet above it needs the tree
      threaded from `City` into the scheduler, and doing that while closures were still biased
      *onto* the corridor would have left a commit in which friction is aimed at a route that a
      closure is aimed at cutting. The order is one commit's worth of difference and the transient
      is the kind of thing that gets shipped.

      Three things came out of it:

      - **The tree is excluded rather than weighted against, and that is what the rest of the
        milestone rests on.** A wall across the route is not a worse wall, it is the opposite of
        one — so `City.start_day` grows the corridor *before* the closures and every street on it
        is refused, which is what makes it still walkable when the barriers go up. It is also why
        `RouteTree.for_day` stopped taking the day's closures: a tree grown against them would be
        grown against decisions taken by consulting it.
      - **The rim is the unit both halves of step 2 needed**, and it is one method. `RouteTree.rim()`
        is the off-tree streets meeting an on-tree one at a junction, which is exactly *the turning
        she can see from the corridor*. A wall further out is legal and bounds less; a wall in the
        far corner of the map is the scenery the old bias existed to avoid, so the constant
        survived the inversion at the same strength with a different thing to measure against.
      - **The assertion asked for is a test rather than an `assert`.** A failing `assert` aborts a
        headless suite, which in this project prints nothing at all and looks exactly like a hang
        (`CLAUDE.md`). So the planner writes a `plan` line and skips, and `tests/test_routes.gd`
        proves the branch is dead by trying **every** off-corridor street of every day on four
        seeds rather than the one or two a day happens to reach.

      And one defect the first version of the test had, which is the same shape as several already
      in this file: it grew its own tree to check the planner's answer against, and grew it
      **before** `map.repaint(state)`. Which blocks are calm is what a tree grows from, so it was
      comparing against a corridor for yesterday's city — 26 failures that were all the test being
      wrong. A tree is a fact about a *repainted* map, and nothing in the type says so
- [x] **Set pieces get a covering set.** Candidate sites such that every corridor touches at least
      one — *not* a single site on her chosen route. `fire_truck` first, then the resistance
      note's alley. **A bundle is not a guarantee**: two distinct paths means at least two sites,
      and any code that assumes one is wrong

      **Built for the catalogue's one-shots, which is `fire_truck` and nothing else.** The day
      plans the row at **every** site and the placements share a `set_piece_group`; the first one
      to enter the world spends the rest, in `EventManager._stream_in`. That hook is where an
      event becomes real — it is where the scar is recorded and the block moves along its arc — so
      the alternatives have to stop being possible on the same frame rather than when it finishes.

      **The resistance note's alley is not done**, and it is deliberately left: `ResistanceDirector`
      places a contact rather than an event, on its own schedule and with its own expiry, so it is
      a second caller of this idea rather than a second row of the same one. It is written down as
      a to-do below rather than folded in silently.

      What it moved that was not obvious: **three counts came apart that used to be one.**
      `max_per_day` is a cap on *instances*, and the number of offers is not one — so a one-shot is
      exempt from the cap assertion in `tests/test_events.gd` and the real count moved to
      `tests/test_event_manager.gd`, where an instance actually exists. And *"the retry has one
      fewer of a spent one-shot"* became *"none"*, because the whole group goes with it. Both
      tests failed on the first run and both were the test being narrower than the sentence it
      was written from.

      **And a third thing it broke, which took a second commit and is the one worth reading.** With
      the offers spacing the rest of the day around all of them, *"a retried day is the same day"*
      stopped being true — the day after a set piece fires has two to six long routes' worth of
      ground freed rather than one, so the fill lands differently: `leaf_blower` seven to five and
      eight kinds moving, on seed 4242. It surfaced a commit late and by luck, because the calm-area
      fix below changed which city seed 4242 generates; the suite had been green on the old one.

      Two answers were tried and the first was wrong in an instructive way. **Placing the set piece
      after the fill** makes the fill identical by construction — and it cannot find its own sites:
      a fire engine's route is 1920px long and `_room_around` refuses anything within 64px of
      anything, so on a map with 120 events already on it every candidate on every covering site is
      illegal and only the fallback places. The rule that shipped is the other one: **an offer takes
      up no room**, because it is not in the world and only one of the group ever will be. That
      makes the fill *identical* between attempts rather than merely close, which is stronger than
      M39 could promise with a single one-shot — and it is the direction step 3 is going anyway,
      *"budget is not really used up if the player doesn't see it."*

- [~] **Off the corridor is not merely unweighted, it is closed.** *(2026-08-31, and it is the
      player's own sentence: "also make sure that areas that outside the paths should have blocking
      events all over — we don't want the player to step in those areas and it ranges from very
      costly to deadly.")*

      **This is a stronger instruction than what step 2 built, and the difference is the point.**
      What shipped weights walls onto the **rim** — the off-tree streets meeting an on-tree one at a
      junction, *the turning she can see from the corridor* — and leaves everything beyond the rim
      to whatever the fill happens to drop there. Measured, that put lethal rows on the rim 63% →
      80% on day 5, which is a bias. The sentence above is not a bias: **the ground off the paths is
      somewhere she must not go**, and it is priced so, from *very costly* at the edge to *deadly*
      further in.

      Recorded before it is built, with the two things it collides with named rather than resolved,
      because both are invariants somebody would have to move on purpose:

      - **A lethal row has to keep its whole `outer_radius` clear of every other event, with no
        fallback** — M28's rule, and the reason it exists is that the telegraph contract is stated
        per event while the player experiences the sum. "Deadly all over" and "nothing else happens
        inside a lethal event's field" are in direct tension, and the second one is what stops an
        abduction being walked into out of somebody else's field.
      - **The catalogue has few lethal rows and they have caps.** Saturating the off-corridor
        ground is a question about `max_per_day` and about how many silhouettes exist before it is
        a question about placement, which is `CLAUDE.md`'s *"a budget the catalogue cannot spend is
        not density"* arriving at the other end of the map.

      **Both were put to the player and both were answered on 2026-08-31.** The gradient is over
      **distance from the corridor** — *"stray one street and you pay, stray three and you die"* —
      and M28's clearance rule is **exempted off the corridor**, keeping its full strength on the
      ground she is being guided along.

      **Built, and here is what it came out as.** `Corridor.depth()` is the range's axis, a BFS in
      turnings over `RouteTree.depths()`; a **very costly** row is a wall now as well as a lethal
      one, `Tuning.WALL_WORTH_OF_COST`; and `_copies_of` pulls the costly end to the rim and the
      deadly end past it. Measured over five seeds:

      | day | placed | inside | rim | deep | lethal in / rim / deep |
      |---|---:|---:|---:|---:|---|
      | 1 (before) | 113.6 | 69.6 | 21.2 | 22.8 | 0 / 0 / 0 |
      | 1 | 113.6 | 60.0 | 29.2 | 24.4 | 0 / 0 / 0 |
      | 5 | 146.4 | 78.8 | 34.2 | 33.4 | 0 / 2.4 / 6.2 |
      | 9 | 177.6 | 88.8 | 44.8 | 44.0 | 0 / 4.2 / 12.8 |
      | 14 | 202.2 | 103.6 | 48.0 | 50.6 | 0 / 4.8 / 12.2 |

      Three things worth carrying, and the first is a mistake caught by measuring:

      - **The threshold was borrowed and it emptied the routes.** `WALL_WORTH_OF_COST` was
        `MARK_WORTH_A_DETOUR` — 25 points, the line where the game raises a caret — with a good
        argument beside it: the cue and the placement would say one sentence. What it did was make
        **two thirds of every day a wall**, taking day 1's corridor from 69.6 placements to 27.8.
        The player asked for the ground off the paths to be closed; nobody asked for the paths to be
        cleared. The line is set by one row instead: **`dog_walker` costs 36.5 and has to stay
        friction**, because *"the dog walker decision should happen meaningfully"* is the route
        decision this game is made of, so the line goes above it at 40 and the first row past it is
        `loose_dog` at 43.3.
      - **The exemption is the `WALL` role and that is by construction.** A wall is offered zero
        copies of any tile inside the corridor, so a lethal placement carrying the role is off the
        routes or it does not exist. A lethal set piece and a lethal `NONE` keep their clearance,
        and `tests/test_events.gd` splits rather than weakens: it checks the ones that keep it and
        asserts the run actually places some of both, so the exemption cannot become a way of
        asserting nothing.
      - **And the gradient is asserted as a relationship, not as two numbers.** *"It ranges from
        very costly to deadly"* is a claim about which end is further out, so the test is
        `deadly_deep > costly_deep`. Two thresholds would have passed on a day where both bands sat
        at the same depth, which is not a gradient.

      **What is left, and it is a catalogue question rather than a placement one.** *"Blocking
      events all over"* is not true yet: day 1 puts 60 placements on the ~25% of the lattice that is
      corridor and 53.6 on the other 75%, so the routes are still **six times denser** than the
      ground she is meant to avoid. Weights cannot close that — they redistribute, and
      redistributing away from the corridor is the mistake above. Only **16.2 of day 1's 113.6
      placements are walls at all**, because the expensive rows have low `max_per_day`, so this is
      `CLAUDE.md`'s *"a budget the catalogue cannot spend is not density"* arriving at the other end
      of the map. Raising those caps is a real balance change and wants its own measurement; day 1
      also has **no lethal row in the catalogue at all**, so its off-path ground cannot be deadly
      whatever the caps say

- [ ] **The resistance note's alley is a set piece too.** *(Split out of the item above rather
      than left implied.)* `ResistanceDirector` chooses where a chalk mark goes, and it has exactly
      the fire engine's problem — an authored thing placed somewhere she may never walk, with a
      run's good ending resting on it. What makes it a separate item rather than the same one is
      that a contact is not an `EventScheduler.Planned`: it has its own schedule, its own expiry
      and no streaming, so the mutual-exclusion mechanism above does not simply apply to it

### Step 3 — placeholders

**What the budget is for was misread here, and the player corrected it before anything was
built.** *(2026-08-31: "I think you are misunderstanding the role of budget. It is to provide
variety in encounters and make sure to not spam the same event over and over again. The amount of
placeholders is almost one per block sometimes multiple per block.")*

The misreading is worth keeping because it is what the three bullets below were about to be built
from. This side read the budget as a **density cap** — a pot of ground the day is allowed to
occupy — and from there the quote *"budget is not really used up if the player doesn't see it"*
can only mean *charge the pot late so the far side of the city is free*, which is order-dependent,
empties out a day the longer she walks, and contradicts the third bullet. The whole question that
went back to the player was built on that reading, and it was the wrong question.

**The budget is a variety ledger.** The count of *sites* is the density and it is roughly one per
block; the budget, the `max_per_day` caps and the weighted pick decide **what fills them**, so that
what she meets is a city rather than nine dog walkers. Which makes the quote mean something quite
different and quite simple: **variety should be measured over the encounters that happen, not over
the whole map.** Fix all ~121 rows at dawn and the twenty she actually walks past can be nine dog
walkers by chance, with the catalogue's caps perfectly satisfied across a city she never saw.

So a placeholder is a **site with a pool**, not an absence:

- [ ] **A `Planned` carries a pool of interchangeable rows**, chosen at dawn, and resolves to one
      of them when she comes within `EVENT_STREAM_RADIUS` — which is already the "she is about to
      be able to see this" boundary. It keeps a **provisional** `def` from the moment it is
      planned, so the day is fully legal at dawn exactly as it is today: every guarantee, every
      spacing rule and both culls run against a concrete row and none of them has to learn about
      pools. Resolution may only *swap* within the pool
- [ ] **The pool is what is interchangeable at that site**, and it is built from what already
      decides placements: the same **role** (so a wall never resolves to friction and the lethal
      spacing rule cannot be broken after the fact), ground that includes the tile, and the same
      `spawn_mode`. The chosen row is re-checked against the day's room and spacing before it is
      taken, which is the same check the provisional row passed — and the provisional row is the
      fallback, so a resolution can never fail
- [ ] **The caps become caps on what she meets.** Resolution prefers a row she has met least today,
      which is the whole of *"do not spam the same event over and over again"*, and a row already
      at its `max_per_day` **in encounters** is not offered
- [ ] **Resolution draws from the placeholder's own stream** — `_stream(base, salt)` keyed by the
      placeholder's identity, never from a stream shared with the rest of the day. Otherwise where
      she walked moves everything planned after it, which is M39's defect with a longer fuse
- [ ] **The test's sentence has to move with the correction, and this is the half that changes.**
      It read *"resolve every placeholder and require the result to match planning it with the
      player walking a different way"*, and under a variety ledger that is false by design: the
      ledger is consumed by encounters, so two walks legitimately meet different rows. What must be
      identical is **the offer** — the sites, the roles, the pools, the paths — which is the M39
      property and the one `docs/CITY.md` states: *"determinism is a property of the offer, never
      of what she did with it."* So: plan a day, walk it two ways, require the plan identical
      placement for placement and require both walks to respect the caps

### The two invariant decisions, which blocked step 2 — both taken 2026-08-31

**And the first of them should never have been a question.** *"I already clarified that the two
routes guarantee is not a hard rule — is that not in your notes?"* It was: step 0 above says *"a
second route is an offer, not a promise"* and *"what it costs is a guarantee, and that is a
deliberate trade"*, `RouteTree`'s own class comment says it, and `docs/CITY.md` carries the
player's *"having two distinct paths is really a niceness to the user"* and *"sealing off a
section of the map is allowed, and it is the point."* The decision was recorded correctly and
then re-opened from this stale heading, which is a smaller version of the failure `CLAUDE.md`'s
overturn rule is about: **a decision that is written down in one place and contradicted by a
to-do list in another is a decision that will be asked again.**

- [x] **Restate the two-routes guarantee.** Done. `MIN_CALM_AREAS_WITH_TWO_ROUTES` is
      `MIN_CALM_AREAS_REACHABLE`, the day-level check asks for one path rather than two, and the
      generator gate is reachability — which is what M50 step 1 deliberately left alone until
      somebody moved it on purpose.

      Two things were kept rather than swept along with it, because the weakening had to be
      deliberate on both sides. **The count of areas did not move**: two, because one of them may
      be the one the day just spoiled, and one reachable area is the unwinnable day the constant
      has existed to prevent since M16. And **the sentence edge-disjointness was standing in for
      is now asserted directly** — by Menger it meant *no single street is a cut*, so
      `tests/test_routes.gd` says that about the **city** rather than about each area: no one
      street cuts off all the calm. The per-area version is false by construction now, because a
      dead end is allowed to take one of an area's ways in
- [x] **`_ensure_one_usable_park` versus the tree.** Answered from the other end on 2026-08-31 and
      it never needed the tree: the guarantee is stated over **where she has been**, not over where
      today's corridor goes, and it is enforced at placement now rather than by a strip. See the
      closed item under "Open design questions"

### What this does not touch

Presentation, in any form. *"How they are presented is already solved. The issue is that they are
not placed properly."* No new cue, no new silhouette, no change to what a closure is, no change to
`City.total_excitement_at`. If this milestone finds itself drawing something, it has gone wrong.

## M51 — The city draws what it means · `feature/draws-what-it-means`

Playtest 15, in full in **[docs/PLAYTEST-15.md](PLAYTEST-15.md)**. Seven findings, and they split
into three that are the city lying about its own rules, two about the frame around the game, one
art bug and one report the player is not certain of.

**Nothing here is a balance change**, which is worth saying up front: every one of them is a place
where what is drawn and what is true have come apart, and the fix is to make the drawing agree
rather than to move a number.

- [x] **A cul-de-sac stops the crowd too** — finding 1, *"cars and people go through
      cul-de-sacs"*. Dead ends are `absent_segments`, which every route search takes through
      `CityMap.blocked_segments()`; the crowd is the one thing that travels the lattice without
      asking. Be precise about what is being fixed: a car that drives *down* a dead end and turns
      round is right, a car that drives out of the end that was built over is not, and neither is
      one that never diverts because the street it is aiming at is gone from the graph but not
      from its own view of the map. `CrowdAgent._divert` and `CrowdLanes` are where to look, and
      M38's rule applies — *a placement is not a separation* — so a recycled car must not be
      **placed** on a street that is not there either

      **And the answer was none of the things above.** The crowd never needed `blocked_segments()`:
      a dead end is a street with its far end **built over**, so the tiles already say so, and
      `_blocked_ahead` already reads tiles. What it could not do was *see* the wall. It was a
      single probe fired seven tiles ahead — right for *is there something coming up*, and it looks
      straight **past** a two-tile plug into the open road behind it. An agent that entered the
      street from the junction beside the wall therefore never saw it at all. **M29's invariant
      exactly**, in the one scan it had not reached: *sampling a tile grid by stepping world points
      aliases, and it aliases where it matters.*

      Four things worth carrying:

      - **The rig had to stand in the right place before it could see anything.** The first probe
        built the crowd field at the doorstep and reported **zero** agents in a wall on three
        seeds. The crowd is a population of the box around the player, so a dead end the box never
        contains is a wall nothing was ever going to reach. Standing the field at a dead end gave
        850 / 2091 / 821 frames of 2400 with somebody inside one, and 8 at once. A clean
        measurement of the wrong place looks exactly like a clean build.
      - **Walking the tiles is *cheaper* than the probe, once it is cached by tile.** The answer
        depends on the agent's tile, its axis and its direction, over a map that is fixed for the
        day, and an agent covers a tile in about twenty frames — so seven lookups per tile beats
        one probe per frame. `test_crowd` went 48.7s → 42.4s and `test_balance` 37.9 → 27.2 while
        gaining a correctness fix. The intermediate version, which added the near check *beside*
        the probe rather than replacing both, cost +28%.
      - **A car that turns round changes lane.** `_direction = -_direction` on its own left it
        driving the wrong way down its own queue, and `space_out_the_traffic` then had to resolve
        a head-on overlap the only way it can — by moving a body. `_turn_round()` is the one place
        that now happens.
      - **And a test that had been true by luck for eleven milestones failed for a reason that had
        nothing to do with this.** *"No car is standing in a precinct"* asked `street_kind_at`
        about the **precinct's** axis, and a precinct span covers the junctions between its blocks
        — so a car crossing it on a north-south street is legal and was being counted. Sixteen do
        in the forty-five seconds that test runs; the assertion passed only because none of them
        was inside a junction on the frame it sampled, and a few frames of timing change broke it.
        It asks whether the car is on ground **no** axis lets it drive on now
- [x] **The main road has dotted lines, not a zebra** — finding 2, and the design half outranks
      the art half. *"The main road shouldn't have zebra crossings (since they have traffic
      lights) it should be two dotted lines demarking the pedestrian safe zone."* A zebra means
      *traffic gives way to you* and on the spine it does not — what stops the traffic is the
      light, which is `Tuning.validate_signals`' whole contract — so the paint has been
      contradicting the rule at every junction of the one street where getting it wrong ends the
      day. Four places have to agree, per `CLAUDE.md`'s street-hierarchy recipe: `GroundTiles`,
      `CityGenerator`'s tile choice, whatever `CrowdAgent`'s crossing scan reads (it walks
      **tiles** and looks for `CROSSING`, which is the M29 invariant — so a new tile type or a
      changed one has to keep that question answerable), and the traffic's give-way rule, which
      must **not** start giving way on the spine

      **Built, and three of those four places needed nothing.** The tile type is unchanged, which
      is the whole shape of the fix: M41 had already considered painting the crossing away and
      rejected it — *"a walker crossing a side street would then be standing on open carriageway,
      and the one thing a zebra is for is saying where a person on a road is meant to be"* — and
      the player is not asking for that either. They are asking for **different paint**. So
      `GroundTiles._crossing_variant` picks four new tiles when either corridor is the spine and
      every rule that reads `CROSSING` goes on meaning what it meant: the crossing scan, the
      give-way rule (which already exempted `MAIN`), and where an event may stand.

      The one thing that did have to move is the **trace**, which said *"at a zebra"* on a street
      that has none — a line that would send the next reader looking for the wrong bug, on the one
      street where the difference between a negotiation and a wait is the difference between a day
      and a day lost.

      Two dotted lines per crossing and two crossings per junction, so a spine crossroads has four
      dashed rows across it: the lines run the way she is crossing, one at each edge of the
      two-tile band, which is what `% SIDEWALK_WIDTH` is asking in that function. Photographed once
      and played by nobody
- [x] **The police car has a rear view** — finding 3, *"the police car only has a sideview even
      when driving vertically"*. An art gap in the crowd rather than in the catalogue

      **It is in the catalogue, not the crowd**, and it is three rows rather than one. The crowd's
      own cars have had an end-on view since M12 — `car_end_body.svg`, with the note that at that
      angle the front and the back of a car are the same shape — and every vehicle in the
      *catalogue* was one side-on sprite mirrored east and west. `police_patrol`, `fire_truck` and
      `military_convoy` are the three mobile ones, so all three got one: answering the complaint
      and leaving the other two would be this file's own warning about the border brief.

      Each keeps its **own** end-on picture rather than borrowing the crowd's generic car. That is
      M37's rule and it bites hardest here — the whole content of a vehicle row is *which* vehicle
      it is, and a police car that becomes a saloon the moment it turns north is the one silhouette
      the screen-edge badge exists to show, gone at the moment it starts coming towards her. The
      badge itself keeps the **side** view: an icon is read at 40px against a row of other icons,
      and a vehicle end-on is a box at any size
- [x] **Say GAME OVER on the game over screen, in big letters** — finding 5. *"In addition to
      everything else that is already there"*, so the ending text, the reason and the keys all
      stay; this adds a heading

      **It is not the same word for all three endings, and that is a decision rather than the
      request being trimmed.** The screen the complaint came off is the `BAD` one, where the nerves
      ran out, and `GAME OVER` is what that is; stamping it over a run somebody *won* would be
      telling them they lost. `THE END` is the same size, the same weight and the same job on the
      other two. Say so if that reads wrong — it is one line of a dictionary.

      **And a dev flag came with it, because there was no way to look at the thing being changed.**
      An ending is at the far end of fourteen days or five spent nerves, so `--ending
      bad|neutral|good` puts the last screen of a run on screen at boot. It is the same argument
      `--press` was built on: nothing in the suite or in a screenshot had ever reached that screen.
- [x] **Change the colour of the title on the title screen** — finding 6. `Palette.TITLE_TEXT`, a
      brighter version of the doorstep the screen is standing in front of. It was the same warm
      off-white as the line under it and the controls below that, so the screen was four labels in
      one colour and the name of the game was only the biggest of them. Deliberately **not** one of
      the danger colours, for the reason the signal lamps are not: a title in `MARK_COSTLY` is a
      game named after a warning
- [x] **A car on the bridge drives off the map instead of vanishing** — finding 7. This is M35's
      *"nothing vanishes while you are looking at it"* arriving at the crowd, which has never had
      it: `Crowd` recycles a car when it leaves the corridor box and the box is smaller than the
      map, so the three holes in the boundary — the bridge, the tunnel, the road out — are exactly
      where a recycle is visible. The rule to state is the events' one: past `Tuning.OUT_OF_SIGHT`
      before it is taken

      **Built, and the interesting half is who is *not* allowed to.** Outside the map is water,
      forest and mountainside — painted ground with no road on it — so letting every agent overrun
      the boundary would drive cars into the sea at every corridor. `City._paint_outside_the_map`
      lays carriageway out there at the spine's own width and nowhere else, and that is exactly the
      condition: a **car**, on the **main road**, going **north or south**. Everybody else keeps
      the tile of slack they had. `CrowdField.along_bounds` is clamped to the map, so the second
      thing that had to move is the box test — asking it about a car on the deck of the bridge
      recycles the car on the deck of the bridge
- [~] **Did the day counter reset mid-run?** — finding 4, and it is recorded with the player's own
      doubt: *"maybe I died fully without noticing."* Read it **with** finding 5 rather than
      instead of it — if a run can end and restart without the player noticing it has, that is the
      game-over screen's complaint arriving from the other side, and fixing the screen may be the
      whole of it. What to check first is whether the ending path can reach the title screen and
      begin a new run without the ending screen having been readable

      **Checked, and there is no path that resets the counter inside a run.** `GameState.day` moves
      in exactly two places: `finish_day` increments it on a win, and `start_run` sets it to 1.
      `start_run` is only reached through `_restart_run`, which **reloads the scene** — so a day
      counter that reads 1 again is a new run and nothing else. The player's own alternative is the
      only explanation the code allows.

      **Left half-open rather than closed, because that is not the same as saying nothing
      happened.** What it says is that the run ended, and *"I can swear the counter reset"* is then
      a report that the ending was unreadable — three screens deep, in the fiction's own voice,
      dismissed with the same key as everything else. Finding 5 is the fix and this is the evidence
      for it. Reopen it if the counter is ever seen to move with nerves still on the HUD

## M56 — The resistance is noticed · the brief as it was drafted, before the forks came back

*(The outcome, and what the three forks settled, is under "M56 — The resistance is noticed ·
`feature/the-city-notices`" earlier in this file. This is the drafting that preceded it, kept for
the questions it raised rather than for the answers it guessed at.)*

**Given on 2026-09-01, as the answer to M55's fourth question rather than as a finding.** The
question was whether a resistance task may cost a nerve. The answer is no, and the second half of it
is a system this game does not have:

> **"how would that work? losing a nerve means repeating the day with the failed day erased. so no it
> cannot cost a nerve. but what should happen is that the more resistance tasks are completed the
> more dangerous the environment becomes. we need abduction vans that normally just abduct people
> but start trying to abduct the player if she is part of the resistance. and other dangers like
> this"**

**The refusal is better argued than this side's recommendation was**, and the difference is worth
keeping. M55 argued *not yet, because five nerves are five attempts and a step that spends one can
end a run for an optional reward* — a caution. The player's reason is structural: **a nerve is not a
resource, it is a rewind.** Losing one replays the day with the failure erased, so "spend a nerve"
does not mean *pay*, it means *have this day not have happened*. There is nothing to trade. Nothing
in the design should offer it, at any difficulty.

**And what replaces it is the same instruction as playtest 17's finding 9, one scale up.** Finding 9
is *pursuing the resistance should make the game harder*, and M55 answers it **at the chalk mark** —
a guard beside every mark. This answers it **in the city**: the further in you are, the worse the
place gets.

- [ ] **Danger scales with resistance progress.** `GameState.resistance_progress` is already the
      number; what it may move is the open question. The constraint is `CLAUDE.md`'s M50 rule — *the
      role is not a decision*, it is read off the def — so heat must not become a per-row switch
      somebody sets by hand
- [ ] **The patrol is the non-lethal rung of the ladder.** *(2026-09-01: "and the robber is a guard
      now — the patrol should be more dangerous when you're part of the resistance but not lethal
      like the van.")* Two instructions in one sentence, and the first explains the second.

      **The robber has been reassigned.** M55 makes `alley_robbery` the guard standing beside every
      chalk mark, which is a *fixed* cost attached to a *place*. So it is no longer available as the
      thing that gets worse as you go, and `police_patrol` takes that job.

      **And the ladder has two rungs on purpose: the patrol escalates but never kills, the van
      escalates and does.** That is the range the escalation is spent over — it is the same shape as
      M50's *"ranges from very costly to deadly"*, applied to progress instead of to ground.

      What `police_patrol` is today, so the escalation has a floor to be stated against: mobile at
      74px/s along roads and crossings, intensity 10, inner radius 44, outer 185, up to 12 a day,
      from day 4, and **not** `hard_fail`. Its own docstring is the design — *"not dangerous yet —
      the danger is that you start planning around it, which is the point."* The axes an escalation
      could move are intensity, radius, population, and whether it investigates rather than patrols;
      which of those, and how they read, is design work to draft and put back, and `hard_fail` is
      ruled out by the instruction

      **Not to be confused with the patrol rule M55 deletes.** That one is `ContactPoint`'s
      hold-reset, and it goes because there is no hold left to reset. This is a different mechanism
      on the same row, and it arrives *after* M55 rather than surviving it
- [ ] **The abduction van takes somebody, and then it takes you.** *"Vans that normally just abduct
      people but start trying to abduct the player if she is part of the resistance."* Two halves and
      the first is not the small one:

      **`abduction` today does neither** (`event_catalogue.gd:926`). It is an unmarked van that
      **idles** — static, 250px field, `hard_fail` inside 54px, a 4.6s telegraph, `first_day` 8. It
      never moves and nothing is ever taken; the abduction is entirely in the name and in what
      happens to *her* if she walks into it.

      - **"Normally just abduct people" is a first for this game.** Nothing in the catalogue has ever
        acted on the crowd. The one existing coupling runs the other way — M19's bump, where *she*
        startles an agent — and the excitement invariant is why: events never push, the world sums
        `contribution_at()`. A van that takes a pedestrian is the first authored event with a
        **victim**, and it is a precedent worth taking deliberately rather than as a side effect of
        a two-word phrase. It is also what makes the second half legible: a van you have watched take
        somebody is a van you understand is coming for you.
      - **"Starts trying to abduct the player" is `pursues`, conditioned on run state**, and that
        collides with a load-time contract. `Tuning.validate_event()` and `validate_pursuit()` check
        the whole catalogue **on boot**, from data. A def that changes shape mid-run is validated in
        the shape it booted in, so **both shapes have to be validated or only the harmless one is** —
        this is the M35 lesson (*a contract stated in seconds is not stated at all*) arriving as a
        contract stated about the wrong object.
      - **A van cannot chase at van speed.** `validate_pursuit` is stated over `RUN_SPEED`, and the
        two things that pursue both move at 130px/s — slower than a run, faster than a walk, by
        construction, because that is what makes running the right answer. A hunting van inherits
        that, which means an unmarked van creeping after her at a fast walk. Whether that reads as
        menacing or as comic is a **screenshot question**, not an arithmetic one
- [ ] **What it collides with, named rather than resolved.** M28's rule is that **nothing else
      happens inside a lethal event's field**, and M50 exempts only the off-corridor `WALL` role. A
      lethal field that *follows her* is neither: it goes wherever she goes, so it cannot be kept
      clear of anything by placement. Either the rule gains a third case for pursuers — which
      `charging_dog` and `alley_robbery` have quietly needed since M35 and M36 without anybody
      writing it down — or a hunting van is not a `hard_fail` and takes something else off her
- [ ] **"And other dangers like this"** — the same brief as playtest 17's finding 8, one level up:
      more rows of this shape, **drafted and put back** rather than built. The obvious candidates
      already in the catalogue are `police_patrol` (which already knows about the resistance, via
      `ContactPoint`'s patrol rule), `checkpoint` and `night_raid`. Do the drafting after the vans,
      because the vans are where the precedent gets set
- [ ] **And measure it against the nerves before believing it.** Five nerves are five attempts at a
      fourteen-day run, and this milestone makes the back half harder *precisely for the player who
      is doing well at the optional path*. The last human verdict on the difficulty is playtest 06's,
      and **nobody has ever reached act III**. A throwaway probe over a full run at each progress
      level, not an argument

## M55 — Off the paths is the dangerous place · partly built

### The resistance half, built 2026-09-01 · `feature/the-mark-is-touched`

All six decided items, three commits, suite green. The hold went whole — `interact` out of
`project.godot`, `ContactPoint` touch-completes, and `hold_seconds`, `progress`, `DECAY_RATE`,
`resistance_hold_changed`, the HUD's holding line and the patrol watch (`SEEN_RADIUS`,
`_patrol_is_watching`, `was_seen`, `resistance_seen`) all deleted. The calendar became eleven
steps — five tasks × (mark, perform) on days 4/5 through 12/13 plus the day-14 finale — with
`grants_progress` false on a mark, so `RESISTANCE_GOAL` stays 4-of-5 over the performs. The shared
plumbing is `ContactPoint.ride(step, instance, offset)`: a perform contact follows an
`EventInstance` and draws nothing, so it is indistinguishable from the ordinary row it rides on.
The guard became a **distance**: `TRAP_FIRST_DAY` 4, the district exemption out, the robber stood
in the 66–176px band computed live from `alley_robbery`'s own radii plus `ContactPoint.REACH`
(never hardcoded), seeded from the day so the pattern is learnable. The brief carries the
resistance's words via `GameState.pending_resistance_brief`, read once and cleared by the day
summary; the first encounter's no-hint exemption cost nothing because a pickup grants no progress.

**Three choices the design was silent on, taken by the implementer and open to overturn:**

- The package task's "the pram is heavier" got a number the design never gave:
  `Tuning.RESISTANCE_PACKAGE_DECAY_MULTIPLIER` (0.5) layered onto `City.decay_multiplier()` via a
  `GameState.resistance_carrying_package` flag, reset on every fresh attempt at a day.
- The package rides a spawned `delivery_van` — the closest existing row to "a package she picks
  up"; the design named no row.
- The poster wall's deadline runs on `deadline_fraction` (0.55) against the day clock rather than
  the crew's own progress, because `poster_crew` never finishes on its own today; the generic
  rider-finished expiry exists and will bite the moment the row can finish.

**Left open by decision, and the code's current behaviour recorded:** whether a
picked-up-but-unperformed instruction expires at the end of its day — **the code waits**: an
incomplete perform step is re-offered every subsequent day, and the only expiries are the poster
deadline and the rider finishing, both inside one day. Moved to the open design questions.

Playtest 17, in full in **[docs/PLAYTEST-17.md](PLAYTEST-17.md)**. Twelve findings, and everything
that is a change to the build is done and ticked below — the off-corridor cost, what goes between
two strands of corridor that run alongside each other, and the corners of the world. What is left is
the four resistance items, and drafting them turned up half of a second item already built and never
read back.

**The design work is finished and nothing in the resistance half is open any more.** The six drafts
went back, five were taken, and the four questions came back on **2026-09-01** with two answers that
changed their own questions — see "The answers" below. **The largest of them is that the hold is
gone**: every step in the subquest was `E` held for three to eight seconds, and the whole thing
becomes *touch it*. The cost moves out of the standing and into the approach, which is where the
player's own task design had already put it. What is left is a build.

**The one sentence is the player's own: *"leaving the path should be lethal or very expensive. right
now that is not the case… that is not as we planned."*** The design was agreed in M50 and the build
does not match it, so nothing here is a new decision — it is an admitted gap being closed, and the
project now has the instrument to say whether it closed.

- [x] **A log says whether anybody was playing it** *(finding 3)*. `run-` when a person is at the
      controls, `rig-` for a headless boot or anything driven by `--screenshot`, `--walk`, `--flee`
      or `--press`. The tool's old proxy — anything under 3kB is a boot — could not see a
      `shot.sh --walk 60`, which is a long busy entirely unplayed log
- [x] **The trace says whether she was on the corridor** *(finding 6)*. A `path` line each way and a
      share at dusk, in three states because a park is not "off the corridor". This is the
      instrument for the two findings below, and it went in first on purpose
- [x] **The word on the title screen has an outline** *(finding 4)*
- [x] **Evidence lives in `docs/evidence/`** *(finding 10)*, with the rule in `CLAUDE.md`. Three
      references the docs already carried were found to be dead
- [x] **Off the corridor has to cost what it was designed to cost** *(findings 1 and 12)*. **Closed
      from M50's own entry rather than given a second design** — see "What M50 still owes", which
      already carries the measurement (*day 1 is ~6× denser on the corridor than off it, and only
      16.2 of its 113.6 placements are walls at all*) and the reason (*the expensive rows have low
      `max_per_day`*, which is *"a budget the catalogue cannot spend is not density"* at the other
      end of the map).

      What playtest 17 adds is that **the gap is visible from outside** — a player read it off a
      telemetry map without being told what to look for — and that the observed effect is not merely
      "off-corridor is cheap" but that **the two are the wrong way round**: stepping off the paths
      is a step into quieter ground.

      **Built, and the measurement is the entry.** Cost per tile of street, five seeds, before and
      after:

      | | on corridor | rim (1 away) | deep (2+) |
      |---|---:|---:|---:|
      | day 1, before | **0.231** | 0.164 | 0.235 |
      | day 1, after | 0.202 | **0.253** | 0.216 |
      | day 5, before | **0.265** | 0.189 | 0.252 |
      | day 5, after | 0.211 | 0.263 | **0.263** |
      | day 9, before | 0.306 | 0.220 | **0.366** |
      | day 9, after | 0.261 | 0.286 | **0.388** |

      **The corridor is the cheapest ground on every day now, and it was the dearest on two of the
      three.** Lethal events off the corridor went from ~0 to 13.2 and 19.2 in the deep band on days
      5 and 9. Walls went from 13% of a day's placements to 24–28%.

      **Two levers, and which one binds is a different answer on different days — that is the part
      worth carrying.** The *cap* was binding on days 5 and 9: the lethal wall rows were capped at 4
      and 5 across 121 blocks, so the deep band had nothing deadly in it whatever the budget did.
      The *weight* binds on day 1, where the caps were never reached: a row is only offered as often
      as its weight, so walls were 13% of placements however high the ceiling went. Raising a cap
      the day never reaches is the other half of *"a budget the catalogue cannot spend is not
      density"*, and M50's entry named only the first half.

      Two costs, both accepted and both worth stating. A day places about six fewer events, because
      the budget now buys dearer rows. And a leaf blower is as common a sight as a dog walker, which
      is the price of day 1 having exactly **two** rows a wall can be made out of.

      **Day 1 is very costly and not deadly, and that is inside the design rather than short of
      it.** *(Confirmed 2026-09-01: "day 1 blocks can be non-lethal. the wording always allowed
      that.")* Day 1 has **no lethal rows at all** — M31 made act I's escalation a change of *kind*,
      0, 3, 4 lethal events over days 1–3 — so an off-corridor wall there is `loose_dog` or
      `leaf_blower` and the deadly end of the range starts on day 2.

      This side raised it as a shortfall; it is not one. *"It ranges from very costly to deadly"* is
      a **range**, and a day that spends only the cheap end of it is spending the range. Recorded so
      the next reader does not re-open it: **the escalation across the acts is where "deadly" comes
      from, and M31's teaching decision and M50's gradient were never in tension**
- [x] **Something between parallel strands of corridor** *(finding 2)*. Asked back because it
      overlapped `RouteTree`'s recorded instruction — *"the player can walk the beginning of path A
      and then switch to path B without noticing, and that is fine… the constraint is on the graph
      and never on spacing"* — and **answered on 2026-09-01**:

      > *"apply nuance here. sometimes put a blocker between (wall or event) and sometimes leave it
      > open -- this is not as important as going off the path completely."*
      > *"only directly adjacent paths (with a single street connecting both) counts for this case
      > obviously. everything further apart should just naturally be never connectable."*

      **The answer dissolves the contradiction instead of picking a side, and that is the part to
      carry.** Only *directly adjacent* strands — one street between them — are this rule's
      business. Anything wider apart is separated **by the map**, because once the item above is
      built the ground off the corridor is lethal or very costly, so two strands two streets apart
      already have something between them and nothing has to be placed. The old instruction is about
      the **tree** and stays exactly true; this is about a **placement** in one specific gap.

      So: *sometimes* a wall, *sometimes* an event, *sometimes* nothing — variety in what one gap is
      worth rather than a rule that closes them all. And it goes **after** the item above by the
      player's own ranking.

      **Built, and it is two weights on placements that already existed rather than a phase of its
      own.** `RouteTree.gaps()` is the question — a street off the tree with a strand of corridor
      crossing each of its two ends, at right angles, so that the two strands are parallel and one
      block apart. `Corridor.is_in_a_gap()` is that asked about a tile. Then
      `Tuning.CLOSURE_GAP_BIAS` aims the day's closure quota at one (the **impassable** half of
      *"wall or event"*), and `Tuning.EVENT_WALL_GAP_WEIGHT` offers a gap's pavement six times over
      to a very costly wall (the **costly** half).

      **A weight and not a per-gap roll, which is the decision worth writing down.** A roll reads
      more directly off the instruction — walk the gaps, roll three ways — and it needs a phase, a
      stream, a budget of its own and a share of the per-row caps, all of which are places the day's
      density can quietly move. A weight rides on the budget, the spacing and the caps unchanged and
      **cannot place more than the day can afford**. Measured over eight seeds, days 1/5/9: a day
      places 106.6 / 140.0 / 169.5 events before and 106.6 / 140.1 / 169.5 after, and walls are
      31% / 26–27% / 30% of them either way. Nothing moved except *where*.

      **What a day has, and what it does with it.** ~15 gaps, of which 7.9 / 8.2 / 8.5 end up
      carrying something — **about half, and about half left open**, which is the instruction rather
      than a compromise. Closures land in one 0.2 / 0.2 / 1.4 times, which is the quota talking: a
      day shuts one street in act I and four in act IV, so it can never shut fifteen.

      Cost per tile of street, eight seeds, before and after — the gap is now the dearest ground in
      the city and by a distance:

      | | on corridor | rim (not a gap) | **gap** | deep (2+) |
      |---|---:|---:|---:|---:|
      | day 1, before | 0.339 | 0.345 | — | 0.203 |
      | day 1, after | 0.343 | 0.318 | **0.547** | 0.188 |
      | day 5, before | 0.382 | 0.302 | — | 0.279 |
      | day 5, after | 0.385 | 0.257 | **0.595** | 0.262 |
      | day 9, before | 0.455 | 0.356 | — | 0.387 |
      | day 9, after | 0.445 | 0.322 | **0.670** | 0.368 |

      The *before* rows have no gap column because there was no such band: those streets are in the
      rim figure beside them, which is why the rim falls when they are taken out of it.

      **The correction this needed is the part to carry, and it was found by measuring rather than
      by thinking.** The first version multiplied the gap weight through the *whole* wall band. A
      gap is on the rim by construction, so a lethal row's weight there is 1 against
      `WALL_DEEP_WEIGHT` further out — and six times one beats four, which quietly made a gap **the
      best lethal ground in the city**. The deep band went from the dearest ground on day 9 to level
      with the corridor, and lethal placements in it fell 8.5 → 7.8 on day 5 and 16.8 → 15.6 on day
      9: M55's first item undone by its second, in one multiplication, with every test still green.
      Restricting the weight to the costly half fixed it and then some — lethal in the deep band
      comes out at **8.8 and 18.1**, above where it started, because the costly rows that left the
      rim were competing with it for the same budget. The gradient's own sentence is what says which
      half gets the weight: *stray one turning and it is expensive, stray further and it ends the
      day.*

      **The picture is the check, and it is the finding's own instrument.** The same day either side
      of the change is in `docs/evidence/`:
      [before](evidence/rig-2026-09-01T014558-seed4242-f604488-dirty-map-day01.png) and
      [after](evidence/rig-2026-09-01T014420-seed4242-f604488-dirty-map-day01.png), seed 4242, day 1.
      The yellow crosses gather onto the streets between the parallel purple strands and a good half
      of those streets are still bare. **Nothing was added to the map to show this**, deliberately:
      a gap that got a wall is a wall mark between two corridor lines and a gap that got nothing is
      a bare street between two corridor lines, so the picture already answered it. The vocabulary
      is short on purpose — *"don't draw the bundles white"* is the same decision one milestone
      earlier.

      **One thing this side could not do and is recording rather than papering over.** The table in
      the item above says *"cost per tile of street"* and does not say **which** tiles or **how** a
      placement's cost is attributed, and three plausible readings were tried against it without
      reproducing its numbers. The table here is a different measurement — cost of the placements in
      a band, over the street tiles of that band — so the two are comparable **in shape and not in
      value**, and the before/after columns are what carries the argument. The guard against the
      previous item is stated in that item's own numbers instead, which are unambiguous: placements
      a day, walls as a share of them, and lethal placements in the deep band. **A measurement whose
      formula is not written down is a measurement nobody can take twice**
- [x] **A switch between strands is a switch** *(finding 2's last clause: "make sure the log notes a
      path switch correctly if it happens — technically it's leaving a path and entering a new
      path")*. As first built, `path` could not see one: both strands answer `on`, so changing route
      appeared in the trace as nothing happening. It carries the branch colours now
- [x] **The corners of the world stop going diagonal** *(finding 11)*. Each band simply carries on:
      mountain stays mountain round the corner, sea stays sea. No new terrain and no corner feature
      — the player asked for the simpler thing, not a bigger one.

      **It is `City._border_source` and not `CityEdge`**, which this entry said until it was
      opened: `CityEdge` is the tunnel, the bridge and the road going into the dark, and the four
      bands are painted in `City`. Worth the correction rather than a silent fix — a to-do item
      that names the wrong file is a to-do item somebody starts by reading the wrong file.

      **One line, and the cause is worth more than the fix.** A corner belonged to *whichever side
      it was further out of*, ties to north or south. That reads as a sensible tie-break and it
      **is** the diagonal, spelled differently: the place where two distances are equal is a 45°
      line, so every corner had a stepped seam running out of it. North and south take the corners
      outright now and keep their own step, so a band runs the full width of the map and the east
      and west bands are what is left between them. The general shape: **a rule written as a
      comparison between two distances has a diagonal in it whether or not anybody drew one.**

      Checked by eye, which is this project's own policy for layout and colour, and the pictures
      are in `docs/evidence/`:
      [before](evidence/shot-2026-09-01-seed4242-d69631a-corner-nw-before.png) and
      [after](evidence/shot-2026-09-01-seed4242-d69631a-corner-nw-after.png) at the north-west
      corner, and [the south-east](evidence/shot-2026-09-01-seed4242-d69631a-corner-se-after.png)
      for the other pair of bands.

      **`--spawn corner:nw|ne|sw|se` is new and is half of why this was found by a player rather
      than here.** The border shipped in M41, was redesigned in M49 and there has never been a way
      to point a camera at the place where two of its bands meet — the same gap the `landmark` flag
      was added to close. It stands a couple of tiles inside the corner, on the pavement: the first
      shot taken with it was of the day ending, because `_nearest_walkable` will happily leave her
      on the boundary carriageway

### The resistance, which is three findings and one shape

*(Findings 7, 8 and 9. This is design work the player asked for by name — "let's think of more
tasks like this" — so it is drafted and put back rather than built.)*

**The shape, in the player's own terms: a resistance task is a thing that costs you meter or safety
on purpose, in exchange for progress on the optional path.** Every other cost in this game is
avoidable by routing; these are taken deliberately. That is what makes them affordable as an
optional path at all, and it is why *"pursuing the resistance should make the game harder"* is a
feature rather than a difficulty complaint.

#### The answers, 2026-09-01 — and one of them is a correction to the verb itself

The four questions at the bottom of this entry went back and came back with more than yes and no.
**The player's own words first, because three of the four are new design rather than an answer.**

> *(on "steps 1, 2 and 4 are the same alley hold three times")* **"not sure what you mean by 'same
> alley hold'? do you mean it is picking up instructions in an alley with a robber close by? let's
> keep them so the progression is (pick up instruction -> perform task the next day -> repeat) so I
> guess that would mean extend the list?"**
>
> *(on which drafts to build — all four offered were taken, plus)* **"let's also make sure the chalk
> mark is always guarded by a robber"**
>
> *(on this side's description of the existing steps)* **"'mark on an alley tile, hold interact for
> 3–6s,' this is incorrect in two ways: 1) there is no 'hold interact' button and 2) it should be
> instant when touching the mark. that should explain how the guard works"**
>
> *(on whether a task may cost a nerve)* **"how would that work? losing a nerve means repeating the
> day with the failed day erased. so no it cannot cost a nerve. but what should happen is that the
> more resistance tasks are completed the more dangerous the environment becomes. we need abduction
> vans that normally just abduct people but start trying to abduct the player if she is part of the
> resistance. and other dangers like this"**

Plus two straight answers: the **first mark moves to day 4** so the calendar fits, and the guard ramp
is **fixed both ways** — the trap starts at the first step rather than on day 8, and the
district-placed steps stop being exempt from it.

**The last answer is a milestone of its own and is written up as [M56](#m56--the-resistance-is-noticed--not-started).**
Nothing of it is dropped or narrowed; it is sequenced, because M55 already has five tasks and a new
verb in it.

##### The hold is gone, and that is the load-bearing change

**Every one of the six existing steps is `Input.is_action_pressed("interact")` held for 3–8
seconds** (`contact_point.gd:44`, `resistance_steps.gd:16`). That is the verb the whole subquest was
built on and it is being **removed**: touching the mark completes the pick-up, instantly.

**And "there is no interact button" is not a mistake about the code, which is what this side said
first and had to be corrected on.** *(2026-09-01: "why are you still talking about holding E? we
removed E early on in the development.")* The key is still bound — `E`, `project.godot:64`, added in
M0 and never touched since — but **the decision to delete it was taken in playtest 02 and was never
built**. `docs/PLAYTEST-02.md`, under *"Teach the controls; do not teach a key that exists once"*:

> **Delete the interact key.** The resistance contact is held with `E`, and `E` is used in **exactly
> one place in the entire game** — `contact_point.gd`, one line. A key that appears once is a key
> that has to be taught, and teaching it costs more than it is worth. Make the hold **automatic on
> proximity**: standing near the mark is the hold.

It is the first half of **M26**, which is still `[ ]` here. M26 waits on M25, M25 waited on *a
mechanic where running is the right answer*, and that shipped in **M33** — so the gate cleared
around twenty milestones ago and neither was picked up. **The player was remembering the decision;
the code is what is out of date.** M55 closes M26's first half as a side effect, and that is where
it should be ticked from.

**This is `CLAUDE.md`'s own rule missed for the second time in one entry** — *the first tool call of
a design task is a search, not a plan*. The alley-roulette correction three bullets down is the same
mistake found the same way. Both times the search that would have caught it was **grep the playtest
files for the noun**, and both times this side searched `src/` instead and treated what the code does
as what the project decided. **The code is evidence of what was built, never of what was agreed.**

Two things follow that are not just bookkeeping:

- **Playtest 02 went less far than the 2026-09-01 instruction, and the gap is the patrol.** It
  removed the *keypress* and kept the *hold* — "standing near the mark is the hold" — on the
  explicit argument that *"nothing is lost… the cost was always standing still in an alley while a
  patrol might pass, not the keypress."* Instant-on-touch removes the standing as well, so the thing
  playtest 02 named as the real cost goes too, and the guard's geometry is what replaces it. **That
  settles the patrol question below: delete it.** There is nothing left for a patrol to interrupt.
- **`E` lives in five places and the build has to take all five**: `project.godot:64` (the binding),
  `contact_point.gd:44` (the read), `tests/test_resistance.gd:98–108` (which presses it),
  `docs/MECHANICS.md:192` (which lists it in the controls) and `docs/ARCHITECTURE.md:57` ("a chalk
  mark, and hold-to-interact"). The last two are the ones a code-only change leaves lying.

What goes with the hold, listed because each is a thing somebody could otherwise put back by
accident:

- `ResistanceSteps.Step.hold_seconds`, and with it the only variation the six steps had besides
  *where* — 3.0, 6.0, 4.0, 3.0, 5.0, 8.0 seconds. The variation moves to the guard and to the task.
- `ContactPoint.progress`, `DECAY_RATE`, the progress arc in `_draw`,
  `EventBus.resistance_hold_changed`, and the HUD's `holding N%`.
- **And a recorded design becomes moot rather than wrong**: *"a reset rather than a deduction"* — a
  `police_patrol` inside `SEEN_RADIUS` resets the hold instead of taking a banked point, because
  *"taking away progress the player has already banked reads as a bug more than a consequence"*.
  With nothing banked there is nothing to reset.

  **It goes, and playtest 02 is what decides it rather than a preference.** This side first proposed
  keeping it as a *block* — a mark under a patrol's eye cannot be picked up until it has passed — on
  the grounds that waiting in an alley is the same sentence in a new grammar. Two things are wrong
  with that. Playtest 02's argument for automatic-on-proximity was that *the cost was always standing
  still in an alley while a patrol might pass*, and instant-on-touch removes the standing, so the
  patrol has nothing to interrupt: it would be an invisible refusal rather than a cost. And a blocked
  *hold* showed a bar that would not fill, where a blocked *touch* shows nothing at all — so keeping
  it would put a silent no-op on the one mechanic playtest 16 already failed to notice existed.
  `SEEN_RADIUS`, `_patrol_is_watching()`, `was_seen`, `EventBus.resistance_seen` and the HUD's
  `seen - wait for it to pass` all come out with the hold.

##### The guard, worked out from the numbers rather than chosen

*"Always guarded"* cannot mean what the trap does today. `ResistanceDirector._maybe_set_a_trap`
calls `spawn_extra(robbery, at)` — the robber is spawned **at** the contact, which is inside
`alley_robbery`'s 30px `hard_fail` radius, so at `TRAP_CHANCE` 1.0 every chalk mark in the game would
be a guaranteed lost day. What the finding actually liked was *"the robber **next to** the chalk
marking — that made it **hard**"*.

Three numbers on the row and one on the contact fix the band exactly, and this is where *"that should
explain how the guard works"* lands: **because the pick-up is instant, the guard cannot be priced in
standing time, so it has to be priced in geometry.**

| | |
|---|---:|
| `alley_robbery.inner_radius` — ends the day | 30 |
| `alley_robbery.pursues_within` — he stands up and comes | 140 |
| `alley_robbery.outer_radius` — his field, the meter cost | 200 |
| `ContactPoint.REACH` — how near she must get | 36 |

- Below **66** (`30 + 36`) touching the mark is death, always. Out of bounds.
- Above **176** (`140 + 36`) the pick-up can never wake him, from any direction. He is scenery.
- Between them, **which way she comes in decides whether he wakes**, because her distance to him is
  her distance to the mark plus or minus his offset. At ~120px, arriving from the far side she is
  156px from him when she touches the mark — *just* outside the trigger — and any lazier line trips
  it, buys her the 1.8s notice, and makes her run. That is the day-3 lesson arriving in act II
  because she chose to.
- The whole approach is inside his 200px field either way, so the meter is charged regardless. **The
  cost survives losing the hold**; only the risk moved from a clock to a bearing.

**So the alley roulette survives, on a different axis.** It was *whether* there is a robber (0.3,
seeded, learnable). It becomes *how near he stands* — a distance drawn in the 66–176 band from
`GameState.day_rng(day, "resistance")`, so 176 is a nuisance and 90 is nasty and the pattern is still
learnable across replays, which is the line this project has drawn between risk and a coin flip.
`docs/NARRATIVE.md` carries the name and needs the sentence under it changed, not removed.

##### The calendar, and why the day brief is now load-bearing

*"pick up instruction -> perform task the next day -> repeat"* is **two beats per task**, so the list
extends rather than replaces. The mark moves to **day 4** — which is where act II starts, so the
resistance opens on the day the city changes character — and the fourteen days come out exact:

| days | step | |
|---|---|---|
| 4 / 5 | mark → **A · give a note to a yeller** | act I row, so it works this early |
| 6 / 7 | mark → **E · carry the package home** | the existing step 3 is already called "A package" |
| 8 / 9 | mark → **D · walk through the checkpoint** | `checkpoint` is day 7+ |
| 10 / 11 | mark → **B · beat the poster crew to the wall** | keeps step 4's deadline, restated over a thing |
| 12 / 13 | mark → **C · stand in the protest** | `protest` is day 12+, so this is its only slot |
| 14 | **the last night** | the finale, unchanged, `needs_goal` |

Two consequences, and the first is the reason M54's day-brief item stopped being a convenience:

- **Miss the mark and there is no task tomorrow.** The brief is how she learns what the resistance
  wants, so *"during the day brief there should be instructions from the chalk marks"* is now the
  **mechanism** rather than a courtesy. The first mark keeps its absolute exemption — no hint — and
  that is free: `day_summary.gd:87` already gates the whole resistance line on
  `has_joined_resistance()`, which is `progress > 0`.
- **`RESISTANCE_GOAL` counts the perform half only**, so 4-of-5 keeps meaning exactly what it meant
  and the good ending's arithmetic does not move. This side's call, stated rather than asked.

**What is deliberately not decided here**: whether a picked-up-but-unperformed instruction expires
at the end of its day or waits. Step 4's `deadline_fraction` is the existing machinery for the first
answer and B's own design wants it. Left until the pairs are built and can be walked.

- [ ] **Give a note to a yeller** *(finding 7, and it comes fully specified)*. *"One task should be
      giving a note to a yeller. that is a risky move since the yeller causes the same level of
      excitement and there might be multiple candidates to test before finding the correct one."*
      Three clauses and each is load-bearing: approaching costs the meter, it costs it *whether or
      not this is the right man*, and there are several candidates so it is paid repeatedly
- [ ] **The day brief carries the chalk marks' words, and it is not a quest marker** *(finding 7's
      first half)*. This is the player **removing** a worry M54 recorded — telling her what the
      resistance wants next is not a marker on a map. M54's first bullet can proceed without the
      hedge it was written with
- [ ] **What guards a chalk mark is the point** *(finding 9)*. *"I did like the robber next to the
      chalk marking. that made it hard to actually get the chalk marking."* It happened by accident;
      it becomes deliberate. This is also the answer to M54's open item about siting the note
      dynamically — what should be near it is something that makes reaching it a decision.

      **Half of it is already built and this entry said it was not.** `ResistanceDirector.TRAP_CHANCE`
      puts an `alley_robbery` at an alley contact one time in three from day 8, seeded so the pattern
      is learnable, and `docs/NARRATIVE.md` calls it *"the alley roulette"*. So the work here is not
      *design a guard*, it is **two smaller things**: the trap starts on `TRAP_FIRST_DAY` 8 and the
      first chalk mark is day 5, so the three steps a player is most likely to reach have no guard at
      all; and the district-placed steps are exempt (`_step.district >= 0`), so half the subquest is
      outside the mechanism entirely.

      **Answered 2026-09-01: both, and the guard is now unconditional.** *"Let's also make sure the
      chalk mark is always guarded by a robber."* `TRAP_FIRST_DAY` goes to the first step's own day
      and the `_step.district >= 0` exemption comes out, so no mark is ever unguarded and no half of
      the subquest sits outside the mechanism. `TRAP_CHANCE` stops being a probability and becomes a
      **distance** — see "The guard, worked out from the numbers" above, which is where the arithmetic
      that makes *always* survivable is. `docs/NARRATIVE.md`'s "alley roulette" paragraph changes
      axis rather than being deleted
- [ ] **More tasks of that shape** — *drafted, put back, and answered.* **All four offered were
      taken**, so with the player's own yeller the set is five: A, E, D, B and C, one per pick-up/
      perform pair, on the calendar above. F (follow the van) is the one draft **not** taken and the
      reason is recorded with it. The counter-example below stands. Written after reading what the
      subquest already is — `docs/NARRATIVE.md`, "The resistance subquest", and
      `src/resistance/resistance_steps.gd` — because the first thing this asked for turned out to be
      half-answered there already

#### What the six steps already are, before anything is added to them

Worth stating first, because the brief reads differently once it is in view. **All six existing
steps are the same verb**: walk somewhere the routing game teaches you to avoid, then *stand still*
for three to eight seconds. The cost is the standing — an alley trickles, and standing is
`EXCITEMENT_DECAY_IDLE` rather than the walking decay, so the meter climbs while you hold. The
variation between them is *where* (alley, civic, industrial) and *how long*.

Two things already in there that the brief did not have to invent, and both should be reused rather
than re-designed:

- **The alley roulette** — from `TRAP_FIRST_DAY` 8, an alley-placed contact has a `TRAP_CHANCE` of
  0.3 of an `alley_robbery` waiting **at** it, seeded from the run and the day so that *the pattern
  is learnable*. `ResistanceDirector` is where it lives and `docs/NARRATIVE.md` has carried it since
  the subquest was written.

  **Which means finding 9 is a re-report and this file did not notice.** *"I did like the robber
  next to the chalk marking… pursuing the resistance should make the game harder"* is the mechanism
  above, and the analysis in `docs/PLAYTEST-17.md` says *"it happened by accident — the scheduler
  placed a robbery where the chalk mark was"* without looking. Both can be true — the trap starts on
  day 8 and a chalk mark is a day-5 step, so what the player met was probably the scheduler — but
  *the design was already on disk* and the item was written as though it were new. That is
  `CLAUDE.md`'s own rule, missed one milestone after it was written down: **the first tool call of a
  design task is a search, not a plan.** Corrected in the item below rather than quietly.
- **A reset rather than a deduction** — a `police_patrol` inside `SEEN_RADIUS` resets the hold
  instead of taking a banked point, because *"taking away progress the player has already banked
  reads as a bug more than a consequence"*. Any new task's failure mode should be this shape.

So what the brief is actually asking for is **a second verb**, not a seventh place to stand.

#### The pattern the yeller task establishes

Three clauses, and they are the test a drafted task has to pass:

1. **The cost is the approach**, not the destination. You pay to get *near* something loud.
2. **It is paid whether or not it worked.** A wrong candidate costs full price and returns nothing.
3. **There are several candidates**, so it is paid repeatedly and you cannot tell in advance which
   payment was wasted.

Note what clause 2 and 3 together add that nothing in the game has: **a cost with no route around
it and no way to price it in advance.** Every other decision in this game is legible before you
commit — that is the fairness contract — and this one deliberately is not, which is affordable
*only* because the whole path is optional. That is the line the drafts below must not cross:
uncertainty is the price of an optional reward, and it must never reach anything the run depends on.

#### Six drafts, cheapest to build first

Each says what it is, what it costs, where the uncertainty lives, what guards it, and what it needs
that does not exist yet. **A. is the player's own and is here for comparison rather than as a
proposal.**

- **A · Give a note to a yeller** *(the player's, finding 7)*. Several `homeless_yeller` rows are
  live; one is the contact. Approach and hold. **Cost:** the yeller's own field, paid per candidate.
  **Uncertainty:** which man. **Guard:** the man himself — he is +31 and the loudest ordinary row in
  act I. **Needs:** a contact that rides on an *event instance* rather than on a tile, which is the
  one piece of plumbing every draft below shares.
- **B · Read the wall before the poster crew reach it.** The chalk points at a stretch of frontage
  the `poster_crew` are working along; the message is under the next poster they paste. **Cost:** a
  clock — you have to cross the city rather than fold it into today's route — plus standing beside a
  paced, expensive row. **Uncertainty:** which of several walls, and how far along the crew already
  are. **Guard:** the crew. **Needs:** the shared plumbing, and a contact whose window closes when
  a specific instance passes a point, which is `deadline_fraction` stated over a thing instead of
  over the clock.
- **C · Stand in the protest.** The contact is *inside* a `protest` — a 110px wall of bodies, the
  densest thing in the city. **Cost:** the largest single field in the game, for the full hold.
  **Uncertainty:** none, deliberately. **Guard:** the protest. **Needs:** only the shared plumbing.
  This is the pattern at its purest and the cheapest of the six to build, and it is the one to build
  first if only one is taken.
- **D · Walk through the checkpoint.** Not round it — through. The one thing the whole routing game
  teaches you never to do. **Cost:** a `checkpoint`'s field taken head-on. **Uncertainty:** which of
  the day's checkpoints, and `police_patrol` already resets a hold, so being early is worse than
  being late. **Guard:** the patrol. **Needs:** the shared plumbing plus a hold that survives being
  *inside* an obstructing body, which today's holds have never had to.
- **E · Carry it home.** Picking the package up makes the pram heavier: `decay_multiplier` is
  reduced for the **rest of the day**. **Cost:** deferred and total rather than local — every street
  after this one is dearer, so it changes the afternoon's routing rather than one minute of it.
  **Uncertainty:** none; the price is known and enormous. **Guard:** the clock, since a day you
  cannot finish is a day you lose. **Needs:** a per-day modifier on `City.decay_multiplier`, which is
  a **new kind of thing** — every cost in this game is currently a field at a place. Flagged as the
  most interesting and the most dangerous of the six for exactly that reason.
- **F · Follow the van.** Stay within a radius of a moving `delivery_van` or `military_convoy` for a
  stretch. **Cost:** you walk where it goes, at its speed, and it goes down main roads. **Guard:**
  the carriageway. **Needs:** a *proximity-over-time* verb rather than a hold, which is the largest
  new mechanic in the list. Drafted for completeness and **not** recommended: it is the only one
  that would need the resistance to grow a second interaction model.

**And one counter-example, recorded because it is the way to get this wrong.** A contact in a
`burnt_shell` — the one row in the catalogue with a negative walk-through cost — is somewhere the
day is *cheap*. It reads like a resistance task and is the opposite of one: a step that does not
cost is a step that is not a decision, and the subquest's whole design intent is that joining it
costs the core resource.

**Taken: A, B, C, D and E. Not taken: F**, on its own drafted reasoning — it is the only one that
would make the resistance grow a second interaction model. It stays written down rather than
deleted, because a rejected option with its reason attached is a decision somebody can overturn.

**And every "hold" in the six bullets above is superseded**, by the answer at the top of this entry:
*"it should be instant when touching the mark."* It applies to the tasks as well as to the marks,
and it makes the whole subquest **one verb — get to a guarded place and touch it** — which is a
better design than the one the drafts were written against, not merely a simpler one. What each
draft becomes:

- **A** — touch the right yeller. A wrong one costs his field and returns nothing, which is the
  player's clause 2 with no timer needed.
- **B** — touch the wall before the crew paste over it. The deadline is the thing rather than the
  clock, exactly as drafted.
- **C** — reach the middle of the protest. The 110px of bodies is the cost, paid going in and coming
  out; standing in it was never what made it expensive.
- **D** — touch the far side of the checkpoint. A traversal is already instant at the moment it
  completes, so this draft loses nothing at all. Its "a hold that survives being inside an
  obstructing body" requirement simply evaporates.
- **E** — touch the package, then the rest of the day is the task. The only one whose cost was never
  in the contact.

#### The four questions, answered on 2026-09-01

**Kept with the answers under them**, because two of the four came back as something other than the
choice offered and a question whose answer changed the question is worth being able to read twice.

1. **Do these replace the six steps or extend them?** *Recommended: replace.* **Answered: extend,
   and for a reason the question did not anticipate** — *"let's keep them so the progression is
   (pick up instruction -> perform task the next day -> repeat)"*. So a task is **two** steps, the
   list roughly doubles, and `RESISTANCE_GOAL` survives untouched by counting the perform half only.
   The recommendation was arguing about which content to cut; the answer changed the unit.
2. **What does a wrong candidate cost — the meter only, or the day's clock too?** *Recommended: the
   meter only.* **Not contested, taken as read.** A wrong yeller costs his field and whatever the
   walking cost; nothing takes the day off you for guessing.
3. **Is the right candidate learnable on a replay?** *Recommended: yes, via
   `GameState.day_rng(day, "resistance")`.* **Not contested, taken as read** — and it gained a second
   job, since the guard's *distance* is now drawn from the same stream.
4. **May a task cost a nerve on purpose?** *Recommended: not yet.* **Answered: no, and here is what
   should happen instead** — *"losing a nerve means repeating the day with the failed day erased. so
   no it cannot cost a nerve."* Which is a better reason than the one this side gave: a nerve is not
   a resource you can spend, it is a **rewind**, so spending one deliberately is incoherent rather
   than merely dangerous. The replacement — the world getting more dangerous the further in you are
   — is **M56**.

## M54 — The resistance says something, and the robber stops at walls · not started

### Built 2026-09-01 · `feature/things-that-arrive` — all three items

- **The wall clamp.** A pursuer's chase step now goes through `_walkable_step()` against a
  `CityMap` handed to `EventInstance.setup()`: an unwalkable landing tile falls back to the step's
  x-only or y-only component (larger first), so it slides along a wall rather than stopping dead,
  and zero if neither opens. Deliberately not a physics body — `obstructs_radius` stays off
  pursuers. The map is null in the data-level rigs, so the pursuit contract's stand-off and
  break-off tests were untouched; a new test chases a rig around a real generated building corner
  and asserts the pursuer's tile stays walkable every frame.
- **The third spawn mode exists: `TOWARD_PLAYER`.** Sited on her own line 200px ahead
  (`SIGHT_AHEAD`), travelling back down it toward and past her — a collision course, not an ambush:
  no stand-off, no giving up, traffic rather than a pursuer. `cyclist` and `loose_dog` moved onto
  it (their MAP-only path fields deleted); the scheduler treats it like `AHEAD_OF_PLAYER` for role
  and budget; validation refuses one with a body or with an `outer_radius` reaching the siting
  distance (it would already be on her when it appeared). The screen-edge badge keeps announcing
  it — the fix to "the badge announces things that never arrive" is that they arrive.
  **`cat_dash`'s own defect was separate**: its telegraph crouch meant the flat lead undercounted
  her walking; `ahead_of_player_lead()` now prices the crouch in (~221px for the cat against the
  flat 184), and the siting test asserts the computed lead. A new encounter test drives a rig
  through the real director and asserts each of the three rows comes within its own outer radius.
- **The run hint is the lesson's**: once per run, first pursuit of `RUN_TAUGHT_DAY` only, same
  shape as the pause teaching line; a new HUD suite instantiates the real scene and holds it to
  that.
- **A balance question raised and deliberately not answered** (per "don't retune what the item
  does not require"): `cyclist` (`max_per_day` 14) and `loose_dog` (24) now share the director's
  single FIFO and its 11–26s pacing instead of being map-placed, so a day fields far fewer of them
  than the caps read as promising — the caps' meaning changed while their numbers did not. The
  suite is green under it; retuning wants its own measurement. Filed under M50's density entry.

Playtest 16's findings 6, 7 and 8, in full in **[docs/PLAYTEST-16.md](PLAYTEST-16.md)**. **This is
the first report anybody has ever made about the back half of the game**, and two of the three are
entries that have been sitting under "Known-shaky ground" waiting for exactly it.

- [ ] **The resistance never announced itself** — finding 7, and it is the answer to the open
      question "Things deliberately not done" has carried from the beginning: *"no quest log or
      marker for the resistance… a player may finish a run never knowing the good ending existed.
      `docs/TODO.md` lists it as an open question for playtesting."* The answer is that the risk did
      not pay off — *"I'm not sure if I ever did the resistance. I walked on one chalk symbol once
      but there was no indication at the end of the day or any guidance what to do next."*

      Four instructions, and they are not one instruction:

      - **The day brief carries the resistance's own words.** *"During the day brief there should be
        instructions from the chalk marks to tell me what the next task is."* In the fiction's
        voice, on the between-days screen.
      - **The first chalk mark is the one exception and it is absolute.** *"Only the first encounter
        (the chalk mark) should come without hint (yes, no hint even at the bottom left)."* The
        parenthesis pre-empts the obvious half-measure: today's HUD line does not count as *no
        hint*, and it goes for that first encounter.
      - **A chalk mark is placed against a route** — *"placed dynamically alongside a route"* —
        which is M50 step 2's own open item, the one that says `ResistanceDirector` places a
        **contact** rather than a `Planned` and so does not simply inherit the covering set. Close
        the two together
      - **And the end of a day says whether anything happened**, which is the sentence the finding
        opens with
- [ ] **The robber runs through walls** — finding 8, and the rest of that sentence is a verdict:
      *"the robber is very good and effective… the timing is good."* So M36's "Known-shaky ground"
      entry closes on everything except this. The bug is precise: a pursuing `EventInstance` moves
      by setting its own position and **nothing in the event system has ever collided with the
      city** — harmless while every mobile row travelled a route the scheduler had already checked,
      and not harmless the moment something steers at the player
- [ ] **The bike, the running dog and the cat never have an impact** — finding 9, and it is a
      complaint plus a design. Three rows whose whole content is *a moving thing meeting her*, and
      none of them ever does: `cyclist` and `loose_dog` are `MAP` rows sited at dawn with a 26- and
      24-tile route, so the day chose where they go before it knew where she goes and the offscreen
      badge announces something that was never aimed at her; `cat_dash` **is** already
      `AHEAD_OF_PLAYER` and is aimed **late**, crossing behind her at a walk because the lead is
      measured from where she is rather than where she will be.

      The design, in the player's terms: **place them when she gets close**; the biker goes **on the
      pavement she is walking on, coming toward her**, *"in a way like the placement of the pursuing
      dog"*; so that she **has** to answer it *"by changing the side of the road or make a turn"*;
      and the fairness is already paid — *"since there is an offscreen hint for the bike there is
      enough indication that the player doesn't need to run and has enough time to plan the route
      change."*

      **What it collides with, named rather than resolved.** `CLAUDE.md` says `AHEAD_OF_PLAYER` is
      *"for the small number whose entire content is the moment it happens to you"* and `MAP` is
      *"for anything the player could plan around"*. A bike aimed at her that she answers by
      **planning a turn** is neither, so this may be a **third spawn mode** rather than a
      reassignment of two rows. And `EventDef.validate()` refuses an `AHEAD_OF_PLAYER` row with a
      body — fine for a moving bike, but a rule to check rather than assume
- [ ] **The run hint belongs to the lesson, not to the mechanic** — finding 6, *"hold SHIFT to run
      randomly shows up sometimes after the running tutorial. it should only show up for the
      tutorial."* Once day 3 has taught the run, a line telling her to hold shift is the game
      explaining something she has already been made to do

## M53 — A junction is made of the streets that meet at it · not started, queued after M52's lights

### Built 2026-09-01 · `feature/junctions-ask-their-arms` — four of six, one fork left open

- **The missing-arm crossings.** Measured before touching code: zero `CROSSING` tiles ever landed
  *inside* a `built_over` rect, but dozens sat in the two-tile band just outside one — for dead
  ends and big buildings across every sampled seed. Zones already had the fix in
  `_absorb_streets`'s stub cleanup; the other two placements never got the equivalent. The shared
  piece became `CityGenerator._seal_stub_crossings()`, stated once over "ground that just stopped
  being a street", called from all three; a property test walks every zone, dead end and big
  building of 12 seeds. **The shore/park four-arm claim did not reproduce as a distinct bug** —
  boundary T/L-junctions are geometrically correct by construction (no tile grid exists past
  `map.size` for a phantom arm), matching M49's earlier "not reproduced" on a near-identical claim.
- **Off the map, both candidates checked.** "The junction should not be there" does not reproduce —
  `StreetNetwork` never enumerates past its own junction count. "The agent is recycled on screen"
  was real and general, not spine-specific: `_recycle`'s all-rolls-missed fallback used
  `ENTRY_SPREAD` (420px, a car's own reach) for every kind, so a walker could settle 238px past the
  true south edge. The fix clamps the settled position to the same room the *exit* side already
  grants (`_keep_within_the_room_beyond_the_map()`), measured down to one tile; a test at the east
  edge holds it away from the spine too, and another asserts a car on the spine still overruns by
  `OUT_OF_SIGHT`, so the bridge stayed lethal.
- **The crowd already agreed with the drawing** — `CrowdAgent._cannot_go_on` reads
  `CityMap.is_street()`, the same predicate the paint fix preserves. That was an inference from
  code, so it got a test: a real day's traffic at a zone, asserting no car ever stands on the
  absorbed corridor.
- **The precinct-junction item was not built, deliberately.** Two pieces of current documentation
  contradict each other: `_street_tile`'s docstring defends "a driveable street crossing [a
  precinct] does so over a zebra six tiles deep" as intentional, while the queue called the same
  junction a bug. Empirically (24 internal precinct junctions over 6 seeds) no `ROAD` tile is ever
  produced there — only `SIDEWALK`/`CROSSING` — so the fix requires deciding whether a real
  street's carriageway should survive through a precinct it merely crosses. Two recorded
  instructions in tension go back to the player; the open half stays in `TODO.md`.

**Ordered by the player: *"queue those fixes after the traffic light fix."*** So M52's third item
goes first and this follows it, which is the right way round for a reason worth writing down — the
lights are a decision about **which junctions are junctions at all**, and three of the four items
below are about what a junction is made of. Building them against a lattice that is about to be
re-asked the same question would be doing the work twice.


Playtest 16, in full in **[docs/PLAYTEST-16.md](PLAYTEST-16.md)**. Five findings; four of them are
one complaint: **the city draws a lattice it does not have, and the crowd walks it.** It walks onto a bridge with no
footway, off a bulkhead into the sea, and through crossroads whose arms are grass — and in every
case it then vanishes where somebody is looking at it. Underneath the first two is one missing
rule: the lattice draws a full crossroads wherever two corridors cross, whether or not the arms of
it are streets.

**Neither of these is news to the repo, which is the part worth noticing.** M41 has carried
*"T-intersections everywhere else on the edge — the lattice currently runs into the boundary and
stops"* as an unbuilt item for twelve milestones, and M51 finding 1 was this exact defect on a
cul-de-sac, fixed there for the crowd's *view* of the wall and not for the junction that should
never have been drawn. A finding that arrives twice from a player after being written down once by
the project is a to-do that was filed and not read.

- [ ] **Cars and people still go off the map** — finding 1, and *"still"* is the word to read.
      M51's fix was deliberately narrow: overrunning the boundary is for **a car on the main road
      going north or south**, because outside the map is water, forest and mountainside. Everybody
      else keeps "the tile of slack they had", and this report is that the slack is visible at an
      edge with nothing beyond it, for people as well as cars. Two candidate causes and they want
      different fixes — the agent is **recycled on screen** (M35's *"nothing vanishes while you are
      looking at it"*, which has never reached the crowd away from the three holes in the border),
      or the **junction should not be there**, which is finding 2
- [ ] **A junction between two precinct arms is still asphalt with zebras on it.** A precinct is
      laid `SIDEWALK` frontage to frontage by `CityGenerator._street_tile`; the junction between two
      of them was never included, so a pedestrianised stretch has a road crossing in the middle of
      it
- [ ] **A junction whose arm is not a street has three arms, not four.** The shore, a park, a calm
      zone's absorbed corridor, a dead end's plug — `CityMap.absent_segments`, `built_over` and the
      map edge already say which arms exist. Nothing that draws a junction asks
- [ ] **No crossing onto a wall** — finding 5, *"the backside of a cul-de-sac should not have a
      pedestrian crossing"*, and it is the item above stated where it cannot be argued with:
      `CityMap.built_over` names the tiles, and there is a zebra painted onto them with a traffic
      light beside it. A crossing marks **where to cross to**, so this one is worth doing even if
      the full three-armed junction is not — the paint is the promise
- [ ] **Only cars go over the bridge** — finding 3, and it is M51 finding 7's own sentence read
      back. A bridge is *"a stretch of carriageway with no pavement beside it"*, which is the whole
      design and is why she may walk onto it and be run over rather than be stopped by a wall. The
      **overrun permission** was narrowed to a car on the spine and the **lane** was not, so a
      walker's lanes still run the length of a corridor that at the boundary is a bridge. Note what
      is not being asked for: the bridge is not to be made safe
- [ ] **And the crowd has to agree with the drawing**, which is M51 finding 1's lesson arriving
      where it was pointing: a T-junction the paint knows about and `CrowdAgent._divert` does not is
      the same bug in the other direction
- [ ] **Calm areas at the edge of the map** — finding 4, *"which should be impossible"*, and it is
      **not this milestone's to build**. The rule is already written down, unbuilt, in M47: *"make a
      rule to not have a calm area at the edge of the map or next to the main road"*, with the
      measurement (96 eligible blocks → 56 with the edge rule → 48 with the spine rule) and the
      three things to get right already beside it. Recorded here so the finding is not lost, and
      **closed from M47** rather than re-designed. It is the third item in one session that this
      file had filed and not read

## M52 — The calm has a shape, and the lights have a reason · not started

**Asked for on 2026-08-31, in the player's own words and in this order:**

> *"The next steps after M50 are 1) 2x2 courtyard and rectangular calm zones 2) calm zone rate
> adjustments 3) traffic light placements."*

**That is the whole of what was said, and it is written down before anything is read into it**, per
the rule at the top of `CLAUDE.md`: a finding summarised on the way in has already lost the part
that was hard to work out. What follows is *this side's reading* of each, kept separate from the
sentence above, together with the questions that have to go back — because all three are single
clauses about systems that currently answer them with a constant, and a reading is not an
instruction.

**Where each of the three stands today**, so the questions below are asked with the work done up to
the fork:

1. **Calm zones are square and there is one size of them.** `Tuning.CALM_ZONE_BLOCKS` is `2`, and
   every piece of arithmetic that follows — the tile rect, which segments are absorbed, which
   junctions survive — is written in terms of it (`CityGenerator._zone_fits`, `_absorb_the_zone`,
   `CityMap.lot_rect`). A city gets one or two zones and the rest of its calm is single-block. A
   **courtyard** is a different thing again: `BlockPurpose.COURTYARD`, the court inside one
   residential block, and it has never been a zone.
2. **A calm area's rates do not depend on what kind of calm it is.**
   `SLEEPINESS_CALM_ZONE_MULTIPLIER` (14.0) and `EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER` (2.2) are
   asked of the *ground*, through `Baby`'s four questions, and every calm tile answers the same —
   a 22-tile zone and an eight-tile courtyard fill the meter at the same rate.
3. **Lights are on the spine and nowhere else.** `TrafficSignals.is_signalled` is
   `junction.x == _map.main_road`, one line, and M41's note beside it says that is deliberate:
   *"every junction on the spine is signalled and no other one is, which is what makes the lights a
   property of the street rather than a scattering of them."* Anything that moves it is moving that
   sentence, so it wants to be moved on purpose.

**And two of the four questions below were answered on disk before they were asked, which is the
thing to read first.** *(Found while recording playtest 16's finding 4.)* **M47 already holds item
1, unbuilt, in the player's own earlier words:**

> *"Make more calm areas take up multiple blocks — I said a long time ago that an inner courtyard
> (surrounded by buildings) should have a footprint of 2x2 blocks (apartment complex) — this never
> got implemented. Not all calm areas have to take up multiple blocks but add more that do. Also,
> add calm varieties that take up 2x1 non-square shapes."*

So *"2x2 courtyard"* is an **inner courtyard surrounded by buildings, an apartment complex, four
blocks**; *"rectangular"* is **2x1**; and the answer to *how many* is *"not all of them, but more
than now"*. The two questions this side had drafted are struck below rather than deleted, because
what they cost is the point: **the answer to "what exactly did you mean" was already on disk, and
asking again is what a to-do that was filed and not read costs.** It is the third such item in one
session, after M41's T-junctions and M51's cul-de-sac, and the M47 entry that answers it also
carries playtest 16's finding 4 — *"a calm area at the edge of the map should be impossible"* —
which is likewise recorded there and likewise never built.

**Build item 1 as M47's entry**, not as a fresh design. What is genuinely new in M52 is items 2 and
3.

**The questions that are still open**, and neither is a detail — each changes what gets written:

- [x] ~~A "2x2 courtyard": a courtyard lot four blocks across, or four blocks with a shared
      court?~~ Answered by M47: an **inner courtyard surrounded by buildings**, an apartment
      complex, 2x2 blocks.
- [x] ~~"Rectangular": which rectangles, and how many per city?~~ Answered by M47: **2x1**, and
      *"not all calm areas have to take up multiple blocks but add more that do"*.
- [x] **"Rate adjustments": neither kind nor a flat number — it is a curve over the lot's
      *size*, and it had already been written down.** *(Playtest 14, finding 11: "x1.5 the
      sleepiness effect of calm zones and double it for 1x1 calm zones", restated in playtest 16 and
      then given its middle: "2x1 calm zones have a proportional multiplier, the base is 2x2".)*
      This side asked the question the file answers, which is the second time in one session.

      **Built: `1 / sqrt(blocks)`, normalised so a 2x2 zone is the base — 21x, 29.7x, 42x for four,
      two and one blocks, i.e. 11.3s, 8.0s and 5.7s to fill from empty.** The base moved 14 → 21,
      and one correction travelled with it: `docs/PLAYTEST-14.md` recorded the request against a
      value of **12**, which had been wrong since M41, so the 1.5 is taken on the 14 that was
      actually there.

      Three things worth carrying:

      - **The two phrasings of the curve do not agree, and the arithmetic picks.** Dividing by the
        **number of blocks** cannot hold "a 2x2 is the base" and "a 1x1 is double it" at once —
        from a 2x2 base it makes a 1x1 *four* times as fast, and from a 1x1 base it makes a 2x2
        half of what it is today. Dividing by the **side** holds both, because a 1x1 against a 2x2
        is a factor of two in width and four in area while the rate doubles.
      - **And that is the design's own sentence: a lap is a length, not an area.** Paying inversely
        to width pays every size about the same for one traverse of itself — 1.4 traverses for a
        single block against 1.05 for a zone, where before the curve they were 2.75x apart. So a
        small calm area stops being the weaker destination for a reason that has nothing to do with
        what it is, which is what puts *which* calm area to head for back in play.
      - **`Baby` still asks four questions**, because this generalised one rather than adding a
        fifth: `WorldContext.is_calm_zone` (a bool) is `sleepiness_multiplier` (a rate). Exactly
        M41's move on the other half of the same question. `City` keeps an `is_calm_zone` of its own
        for the debug overlay and the telemetry, which do want the yes/no

      **And `tests/test_generator.gd`'s lap test was rewritten rather than repaired.** It said a
      single block is *not* worth a quarter of a meter to cross — "which is why one is a lap" —
      which was right while every calm area filled at one rate and is the thing the curve was
      built to remove. It asserts the ratio now
- [x] **"Traffic light placements": it was never a design question.** *(Playtest 16: "what is
      your problem with understanding the traffic light issue? currently the traffic lights are
      next to the building and not the street.")* `City._spawn_signal_heads` offset each head
      `half - inset` from the corridor's centre — 80px of a 192px street — so every one stood on the
      **outer** tile of the footway, against the frontage, the full width of the pavement from the
      road it was talking about. The doc comment above that line already said a head belongs *"on
      the kerb beside the carriageway it stops"*: the intent was written down and the arithmetic did
      something else. Measured from the kerb now — half the carriageway plus half a tile of pavement

      **What this does *not* answer, and it is left open rather than assumed closed:** whether more
      junctions should be signalled. M41's sentence that lights are *a property of the street rather
      than a scattering of them* is untouched, and M53 — which the player queued behind this — is
      about junctions whose arms are not streets, which is a different question again
- [ ] **The unasked half, parked rather than pursued: should more junctions be signalled?** Nobody
      asked for it and this file is not to treat it as implied. Recorded because the cost is real
      and would otherwise be discovered by building it: every signalled junction stops being a
      give-way zebra and becomes a **timing** crossing, `Tuning.validate_signals()` is a hard-fail
      contract so extending lights extends where death-by-timing applies, and M46 measured that
      arbitrary offsets stop two thirds of the traffic at every junction. It would also repeal
      M41's *"a property of the street rather than a scattering of them"*, which is a sentence to
      overturn on purpose or not at all

## Tooling for the diversion work · `feature/a-map-that-shows-the-plan`

Asked for alongside the diversion design, and it goes **first** for the reason the playtest-13
tooling did: the thing being built is a *placement*, and a placement is exactly what a trace in
words cannot show. Without this the only way to check that a corridor points anywhere is to play
the day and form an impression.

- [x] **Draw the corridor on the telemetry map.** `TelemetryMap` already writes a
      `<stem>-map-day<NN>.png` per day with the home, the calm areas, the spine, the precincts and
      the closures. Add the day's **corridor** — the routes from the doorstep to the calm areas
      that are still worth reaching — as a drawn path over the grid. This is the picture that
      answers *"is anything guiding her"*, which is the open question the whole milestone exists
      for, and it cannot be answered from a log line. **Built**: violet, junction centre to junction
      centre so it reads as a path. And it immediately earned itself — the first picture shows the
      trunk wandering west, north and back east before it arrives anywhere, which is the
      13.2-against-4.4 measurement above as something a person can look at
- [x] **And then it was read by the player, which changed three things about it.** *(2026-08-31,
      the first time anybody looked at one.)* Two were about the picture and the third was about the
      city; all three are in `docs/TELEMETRY.md` and the code, and the shape they share is worth the
      line: **a debug picture that decorates is a debug picture that lies.**
      - *"Marks disappearing is a problem"* — the corridor was drawn under four other marks and
        over one, so a stroke could simply not be there. It is **mixed into the ground** now rather
        than laid over it, which is also what *"keep the violet lines transparent"* asks for.
      - *"Don't draw the bundles white — don't make a distinction between path and bundle."* Gone.
        What goes with it is a diagnostic — a picture with no sharing in it is a star — and it is
        asserted in `tests/test_route_tree.gd` instead of being visible.
      - *"Why blue? Why not just take the sidewalk colour"* — the precinct mark is **deleted**. A
        precinct is laid `SIDEWALK` from frontage to frontage, so the ground pass already draws it
        as the one corridor with no asphalt stripe down it, and the blue line was an overlay
        repeating a fact the picture had
- [x] **Mark every placed event with its categorisation.** Not just *where* — **what kind**, in the
      vocabulary in `docs/CITY.md`, "The words for it": its **effect** (lethal / impassable /
      costly) and its **role** (wall / friction / set piece). A wall drawn on the corridor instead
      of beside it is the central defect this milestone can have, and it is one glance to see and
      invisible in every other tool. Distinguish placed-and-live from placed-and-never-reached, and
      keep it legible at 640px

      **Built: colour is the role, shape is the effect, a white pip is whether she reached it.** No
      row carries an effect the vocabulary did not already have — `EventDef.effect()` and
      `Planned.role` both existed by the end of step 2 — so this is a legend rather than a model,
      and `tests/test_telemetry.gd` asserts the legend *is* the drawing. Three things came out of
      building it, and two of them were found only by opening the PNG:

      - **"Distinguish placed-and-live from placed-and-never-reached" needs a second picture, and
        the second picture is the more useful half.** At dawn nothing has been reached, so the flag
        can only mean something at dusk — `-map-day<NN>-dusk.png`, written from `_on_day_finished`
        before `end_day()`. What the pair says that neither says alone: the dawn map shows a wall in
        the wrong place, and only the dusk one shows **a corridor with nothing on it ever met**.
      - **The first version faded what she never reached, and that is the picture whispering the
        thing it exists to shout.** A wall in the far corner of a map she never walked into is
        still a wall in the wrong place, and it is exactly the placement no trace can report. Drawn
        as a pip instead, every mark stays at full strength — and the pips turn out to be a **trail
        of where she actually went**, laid over the corridor the day planned for her, which is a
        second question answered for nothing.
      - **A faint mark can still be the loudest thing in a picture if it is the wrong shape.** A
        routed event draws a band along the ground it covers; at the mark's own strength, on a day
        with 175 placements, those bands read as *corridor* — thin coloured lines down the middle of
        streets, which is what the violet is. Dropping them was wrong too (a van that sweeps a whole
        street would be drawn as a point). 0.18 makes it a shadow you find when you look for it. The
        shape to carry: **a mark that can be mistaken for the one thing it has to be compared
        against is worse than no mark.**

Both obey the telemetry invariant — no RNG, nothing that changes a placement, no cost when
telemetry is off — and both are dev tooling under the same eventual debug-build gate.

## Tooling for playtest 13 · `feature/a-picture-of-the-city`

Findings 4 and 5. Small, asked for by name, and **built first**, because M46 and M47 both want
exactly what they provide. Neither is a game feature; both go with the dev flags and under the
same eventual debug-build gate.

- [x] **Render the whole city grid to a picture in the telemetry folder** — finding 4. Not
      `--overview`, which is a dev flag on a run somebody has to take and which photographs the
      *rendered* city: this is the grid itself, one small square per tile coloured by tile type,
      written beside the log every run without anybody doing anything. Everything needed exists —
      `Tile` decides the colour, `CityMap` holds the grid, `Telemetry` owns the directory and the
      naming. Mark what a trace cannot say in words: the home, the calm areas, the main road, the
      precincts, the day's closures. It must obey the telemetry invariant — **no RNG, nothing that
      changes a placement** — and it must cost nothing when telemetry is off
- [x] **A key that takes a screenshot and writes a note** — finding 5. `Telemetry.snapshot()`
      exists and is heuristic; what is missing is the player saying *look at this*. Its own key, it
      **bypasses `SHOTS_PER_DAY`** (a person asking is not a heuristic firing), and it writes a
      `note` alongside so the picture has a line in the trace to sit next to — position, day,
      meters, and what is near her. Note the M36/M38 lesson before wiring it: nothing in the suite
      or a screenshot has ever pressed a key, and a bare key is not an action — `--press key:<x>`
      is how it gets tested at all

**Both built, and it is `TelemetryMap` plus twelve lines in `main.gd`.** `P` (or `F9`, two
bindings because a bare F-key is the convention and is also what macOS hands to the volume control
unless a setting is changed) writes `<stem>-<clock>s-asked.png` and a `shot` entry; every day
writes `<stem>-map-day<NN>.png`, 640px square and about 5kB.

**Three things were found by building it, and two of them are the reason it has tests.**

- **A float colour does not survive `FORMAT_RGB8`.** The marks were authored as
  `Color(1.0, 0.25, 0.35)` and read back a fraction off, so the test that asked *is this mark in
  the picture* failed against the constant it had just drawn with. They are hex now, like
  everything in `Palette`, and the ground colours never had the problem because `Palette` already
  was.
- **`snapshot_now` guarded the note and the picture together, and the suite is the configuration
  that keeps the note.** `begin_memory_log()` produces a log with no path, which is a real state
  rather than an edge case, and one guard covering both halves made the entry vanish along with
  the PNG it could not write. They are guarded separately.
- **The home crosshair was built and taken back out.** It reached a block either way to make a
  few tiles of stoop findable in a 160-tile map — and it is the only red in a picture with no
  other red in it, so it was already the first thing the eye lands on. It was covering two streets
  to buy nothing. *(Reported directly: "the home cross hair is not needed — home was easily
  findable with just the red dot from before.")*

And the first two maps it drew already show M47's own finding without anybody measuring anything:
calm areas hard against the map edge, and one directly beside the spine.

## M10 — Polish · `feature/polish`

Not started. The game is complete without it; this is what would make it shippable.

- [~] **Finish the visual channel — before audio, not after.** House rule: audio is never
      the only channel, so every cue that will become a sound must already work silently
      (docs/EVENTS.md, "Showing the danger"). Two of the three gaps closed in M22:
  - [x] **HUD line for `city_wide` sources.** *(M22.)* The loudspeaker masts from day 5 and
        the curfew announcement had *no* on-screen presence at all — the aura layer skipped
        them, correctly, since a field with no edge cannot be a ring, and nothing took over.
        The player saw excitement refusing to drain and nothing said why. `EventBus` now
        announces what is holding the floor and the HUD says so.
  - [x] **Screen-edge indicator for fast movers.** *(M22.)* `fire_truck` and `military_convoy`
        are built around a long telegraph spent getting off that street, and at 190px/s most
        of that warning happened off-screen where the ring could not be seen. `DangerEdge`.
  - [ ] **Sound lines.** Concentric arcs thrown off a source on a pulse's rising edge —
        the visual form of a discrete noise. Would give the yeller, the dog and the
        reversing van a readable "that just happened" beat rather than only a swell.
  - [x] **The entities themselves.** *(M37.)* Every visible catalogue row draws something of
        its own, and it is a rule with a test rather than an art to-do: no two rows share a
        look, no two looks share a silhouette. The crowd is deliberately still anonymous — that
        is the opposite rule and it is what an authored event stands out from.
- [ ] **Audio**, once the above is done and judged on its own: per-act ambient beds,
      per-event cues, the baby's breathing and fussing as the diegetic version of the
      meters. Additive by design — the game must already be fully playable muted.
- [ ] Main menu and settings. The pause screen exists (M33, working since M36) and there is a
      **title screen** as of M38 — but it is a title, three lines of controls and two keys, with the
      street outside the home running behind it. No options, no seed box, no load game
- [ ] Save/continue a run — `GameState` is already shaped for it (seed + day + a few
      arrays), so this is serialisation, not design
- [ ] Accessibility: colourblind-safe meters, a telegraph-time multiplier, reduced motion
- [ ] Controller support
- [ ] The `--spawn`/`--follow`/`--day` dev flags should be gated behind a debug build
- [ ] `_first_event_position` and friends live in `main.gd`; a `DevFlags` helper would keep
      the boot scene about booting

---

## Audit of the feedback record · not started

Every human turn in this project's session history was read back against what is on disk, looking
for two things: feedback that was never properly recorded, and feedback that was **silently
overturned**. The recording discipline came out well — the two known failures (the border brief and
hard/soft diversions) are the ones already written up under M49, and almost everything else is in a
`PLAYTEST-NN.md` table in the player's own words. What follows is what the audit added, and it is
mostly the *second* category. It is the evidence behind the new `CLAUDE.md` rule, *"Never silently
overturn a decision the player took"*.

- [x] **M20's parking says no playtest asked for it, and playtest 02 did.** *(Resolved
      2026-08-31: the request is real, it stays parked, and it is a discussion that is owed rather
      than a dead item. Status line corrected.)* The entry above
      (`M20 Traffic that behaves`) parks eight-way driving, overtaking and the crash event as
      *"none of which any playtest has asked for"*. Playtest 02 finding 4 is the player asking for
      all three: *"faster cars should either slow down or when the opposite lane is clear overtake
      the slower car. this requires cars to be able to drive in 8 directions as well. if overtaking
      hits an oncoming car a crash should happen which is a very exciting event so the player has
      to clear the area fast."* It is recorded correctly in `docs/PLAYTEST-02.md`; only the status
      line is false. **Fix the line, then ask whether it stays parked** — parked with the player's
      agreement is a fine place for it to be, and that is not what it currently is
- [x] **The east and west spine exits were deleted, and three places still describe them.**
      *(Resolved 2026-08-31: **"east/west is a hard no. There is only one main road and it is from
      north to south."** The deletion stands, and it is now a decision rather than an inference.
      `docs/CITY.md` and `city_generator.gd` corrected; the generator's east-west calm guard is
      left in place with a note that it has outlived its stated reason.)* M49
      removed them, reasoning that playtest 12's *"there should be no east to west [main roads] at
      all"* took them with it. But the exits are their own brief, given separately: *"the side to
      side mainroad just going towards east west in one space. the player should be able to walk
      into those which would be certain death once a car comes. that way it's not an artificial end
      but an emergent end."* Two instructions in tension, resolved without asking. Either answer is
      defensible; taking it unilaterally is not. **Ask, then make the repo agree with itself** —
      `docs/CITY.md` "The edge of the world" still lists *"the road simply carrying on east and
      west"*, and `src/city/city_generator.gd:330` still protects *"the corridor the east and west
      city exits open onto"* and says *"it stays a constant because the exits do"*
- [ ] **The pending calm-ground multiplier is planned against a stale base.** The playtest-14 entry
      *"Calm ground is worth more"* reads `SLEEPINESS_CALM_ZONE_MULTIPLIER` as **12** and derives
      18 and 24 from *"x1.5 … and double it for 1x1"*. It has been **14** since M46 took it 12 → 14
      for playtest 12 finding 6. Applied to the real value the instruction gives **21**, not 18.
      `docs/PLAYTEST-14.md` carries the same stale reading, and `CLAUDE.md`'s known-shaky-ground
      note still describes the M38 10 → 12 move as the current state. Correct all three before the
      number is moved — this is the constant M38's own entry warns decides whether a day is
      winnable once the park is reached
- [x] **The routing brief was never captured, and reconstructing it from the record failed.**
      *(Resolved 2026-08-31 by the player restating it; `docs/CITY.md`, "Diversions — the design".)*
      Worth keeping for the shape of the failure. Playtest 14 recorded *"no note anywhere"*; an
      audit then found playtest 01 finding 12, which is about blockers and route pruning, and read
      it as the missing design. **It is not** — hard/soft there was inferred to mean *impassable
      vs. expensive*, where the player means **permanent vs. per-day**, and the real brief has a
      severity axis underneath it that nothing in the record hints at. Two lessons, and the second
      is the expensive one: **a finding marked done is never re-read**, so summarising one on the
      way in leaves a checkmark rather than a gap. And **a plausible reconstruction is worse than a
      blank**, because it gets built. The one thing that produced the actual design was asking
- [ ] **A bug reported inside a design finding was fixed and never closed out.** Playtest 12
      finding 1 is tagged *design + bug* and carries *"(also people seems to not go in the middle)"*.
      The design half drove M41; the bug half is fixed — `CrowdLanes.PRECINCT_OFFSETS` is six lanes
      across the whole width — but nothing anywhere connects the fix to the report. Bookkeeping
      rather than lost work, and the shape is worth watching: **a finding with two halves gets
      closed when the louder half is done**

## Open design questions

These need a human playing the game, not more code.

- [x] **`_ensure_one_usable_park`'s early return defeated the rule written underneath it — and the
      fix was to stop repairing and start refusing.** *(Found in M50 while chasing a density floor
      that had nothing to do with hard blockers; answered by the player on 2026-08-31.)*

      The function collected, per calm area, the events whose fields reach it, and **returned as
      soon as any one area came out clean** — so playtest 14's stronger rule, *"every calm area she
      has not used this act stays clean, not just one of them"*, only ran on the days the older one
      had already failed. Measured over 64 planned days: the early return fires on 25–75% of them,
      and on a raw day **6.4 to 7.6 of the seven-to-nine unvisited areas are spoiled**. So the real
      promise was *one of the nine is clean and you cannot tell which*.

      Four ways to price that were measured and put to the player, and every one of them was the
      wrong question: *"why are 7-9 unvisited calm areas spoiled? Just don't place events there!"*
      The whole framing was a repair — plan the day, then delete what landed badly — where the rule
      belongs at **placement**. `EventScheduler._calm_to_leave_alone` is the fix and it is four
      lines: the calm ground of every area she has not settled in this act is refused to
      `_place_one`, and the events that would have gone there go somewhere else.

      It is better on both axes at once, which is why the options were worth throwing away. Every
      unvisited area is clean on **64 days of 64**, and the density went **up** rather than down,
      because the budget is no longer spent on events that were about to be deleted: day 1 goes
      118.4 → **124.6** placed and day 14 204.9 → **223.4**. `_ensure_one_usable_park` stays as the
      last line for the one case placement cannot answer — she has settled in every area there is,
      so nothing was protected — and `tests/test_events.gd` holds the new rule over a whole run.

      The shape to carry, because this project already has the rule and did not apply it here:
      **check before accepting rather than repairing afterwards.** `CLAUDE.md` says it about
      closures, and the argument is identical — a repair spends the budget twice, makes the day's
      density depend on how many placements happened to land badly, and leaves the guarantee
      running only when something else has already failed.

- [~] **Is the nerve economy right?** **Half answered by playtest 08: three was too few**, and the
      evidence is a run that ended on day 3 with two nerves spent on the same charging dog. It is
      five since M35. M32 had already changed the shape of the question rather than answering it — a
      lost day no longer advances the calendar, so a nerve is an *attempt* rather than a day thrown
      away — and what is still open is the other side of it: with five attempts and a retry costing
      only time, is a lost day a punishment at all? The run log's `nerve` entries say where they
      went, and also say which day is being played again. Note that five was **asked for, not
      derived**, and the thing that made three too few was a defect (the day-3 dog) rather than a
      difficulty: if act I now reads as fair, five may be generous.
- [~] **Is the balance right?** *(M14 pitched it against the day rather than against itself;
      M18 then re-pitched it against a **minute of play**: day 330s → 180s,
      `SLEEPINESS_GAIN_WALKING` 0.24 → 0.42, calm 3.5x → 10x, idle drain 0.6 → 1.0. A whole
      day of street walking reaches 76 of 100 and a calm stretch takes 24s.)* The open
      question is now the opposite one: with the meter this generous once calm ground is
      reached, is anything standing between the player and a won day? **Playtest 03 answered
      that with a trace: no.** Day 1 was won in 103.9s of 180 with zero `near` entries — the
      player crossed the city and came back without encountering a single event.
      **M19 put things there and the question is now whether it put too many.** A day-1 map
      carries 13 non-ambient events instead of 4, walking into somebody costs ~15.6 points, and
      the carriageway ends the day. A scripted walking probe says a quiet pavement is close to
      break-even on excitement and the arterial is not survivable to walk the length of — which
      is the intent, but "the arterial is for crossing" is a claim about a player, not about a
      probe. Needs a run and a trace, not more arithmetic.
- [ ] **Is 14 days the right run length?** Act I is only 3 days, which may be too little
      time to learn a city before it starts changing.
- [x] **How visible should the resistance be to a player ignoring it?** *Resolved by playtest
      02, decision 14: as visible as it is now — a chalk mark and one HUD line, no marker, no
      quest log.* The resistance is the difficulty dial (decision 10), and **wanting the dial
      and finding the dial are the same behaviour**: a player who wants to be challenged
      explores, and exploring is what finds a chalk mark on an alley wall. Carried open since
      M8; closed by leaving it alone. What *does* change is the key — see M26. The run log's
      `contact` entries record whether a player ever went near one, because "nobody ever finds
      it" would falsify the reasoning.
- [x] **Should running ever be *required* (a forced chase), or always purely a player
      choice?** *Answered by playtest 02, finding 9: yes, for some entities.* The measurement
      that came with it is the surprising part — running is currently the wrong move against
      **every** event in the catalogue, because `EXCITEMENT_FROM_RUNNING` plus the collapsed
      decay (3.5/s → 0.5/s) outweighs the shorter exposure every time. The run button is a
      trap. Making running necessary is therefore a mechanic to build (M25), not a number to
      change.
- [~] Should there be a diegetic-only mode — a baby's face instead of two bars? **Half answered
      by playtest 06, finding 5, and built in M32**: not instead of the bars and not a face, but
      *at the pram* — four states with an instruction each. What is still open is whether the
      bars could now be turned off entirely, which is a question for somebody playing with them
      hidden rather than for more code.
- [x] Does a lost day advancing the calendar feel right, or should it repeat the day?
      **Answered by playtest 06, finding 4, and built in M32: it repeats the day.** *"We
      shouldn't advance the day, that's for sure."* So a nerve buys a **retry of the same day** — the same city,
      the same closures, the same event plan, because all of those are deterministic from the
      seed and the day number — and the calendar only moves when a day is won. Nerves stop being
      a second currency and become three failed attempts spread over the run. Carried open since
      M6; closed by being asked out loud. See [PLAYTEST-06.md](PLAYTEST-06.md) for what it does
      to the one-shots, the block arcs and the endings
