## Where to pick up — as it stood at the end of the M50 / playtest 16 session

*(`main` was `c82bcbb`. Superseded; the live version is [HANDOFF.md](../HANDOFF.md).)*

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
> and that is the correction worth carrying — see [PLAYTEST-12.md](../playtests/PLAYTEST-12.md), which is the
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
> [PLAYTEST-11.md](../playtests/PLAYTEST-11.md) and planned as **M41** (a main road with lights, a tunnel, a
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
> [PLAYTEST-07.md](../playtests/PLAYTEST-07.md). It is a `Building` sorting by its **south edge** while its mass
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
> [PLAYTEST-07.md](../playtests/PLAYTEST-07.md). The two worth knowing before touching anything: **solid
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
