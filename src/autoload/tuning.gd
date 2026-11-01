extends Node
## Central balance table. Every gameplay constant lives here so tuning is one file.
##
## See docs/MECHANICS.md for the reasoning behind these numbers.

# ---------------------------------------------------------------- movement ---

const WALK_SPEED := 92.0
const RUN_SPEED := 168.0
const ACCELERATION := 700.0
const FRICTION := 900.0
## Below this speed the player counts as idle (sleepiness drains).
const IDLE_SPEED_THRESHOLD := 12.0

# ------------------------------------------------------------- sleepiness ---

const METER_MAX := 100.0

## The pitch these three make together is the whole loop: **an ordinary street makes real
## progress and never enough.** A whole day of clean street walking reaches 88% of the meter
## (a 210s day at this rate — `DAY_LENGTH_SECONDS`), so the walk out is worth something and the
## walk out alone can never finish. Only calm ground can, which is what stops a day being winnable
## by circling the doorstep and the city being decoration.
##
## `tests/test_meters.gd` holds both halves in terms of `day_length()` rather than in numbers,
## so a change to the length of a day cannot quietly make the street sufficient again.
const SLEEPINESS_GAIN_WALKING := 0.42
## Standing still has to be strictly worse than walking, or waiting is a strategy. It also
## has to stay cheaper than a calm zone gives, because stopping is the counterplay to a loud
## event and pricing it above the park's own rate would take that move away.
const SLEEPINESS_DRAIN_IDLE := 1.0
## How much faster calm ground fills the meter than an ordinary street. A four-block zone is
## **11.3s from empty**, against a whole day of clean pavement reaching three quarters of the bar.
##
## Deliberately generous once the park is reached, because **the day is meant to be lost on the
## way there and not in it.** That makes this the constant that decides whether a day is winnable
## at all once she arrives, and it is why it moves whenever the walk out gets harder: leaving the
## reward the same length while adding to the journey turns a park from a reward into a wait, and
## a calm stretch that reads as a wait is the failure this number exists to prevent.
##
## It also has to be visibly faster than the pavement, not merely faster. A small multiple of a
## rate nobody can see does not read as a reward at all.
const SLEEPINESS_CALM_ZONE_MULTIPLIER := 21.0

## How much faster again a **small** calm area fills it, as a curve over the lot's size.
##
## The rate goes as `1 / sqrt(blocks)`, normalised so a `CALM_ZONE_BLOCKS`-square zone is the base:
## **21x for four blocks (11.3s from empty), 29.7x for two (8.0s), 42x for one (5.7s)**.
##
## **It divides by the side and not by the area, because a lap is a length.** A four-block zone is
## 22 tiles square and has a route through it; a single block is eight tiles across and has a lap
## round it. Paying inversely to the *width* of a lot pays each of them about the same for a lap, so
## a small area stops being the weaker destination for a reason that has nothing to do with what it
## is for, and *which* calm area to head for stays a real question — which is `docs/CITY.md`'s own
## argument for keeping single-block calm in the mix.
##
## The trap, since the two formulas look equally reasonable: dividing by the **block count** makes a
## single block *four* times a four-block zone rather than twice it, because a factor of two in
## width is a factor of four in area.
func sleepiness_calm_multiplier(blocks: int) -> float:
	var side := sqrt(float(maxi(blocks, 1)))
	return SLEEPINESS_CALM_ZONE_MULTIPLIER * float(CALM_ZONE_BLOCKS) / side
## Sleepiness the baby keeps after being woken up. Half the bar, which is now about twelve
## seconds of park — a fifth of a well-played day, which is what it was before and should
## stay whatever the rates are.
const WAKE_SLEEPINESS_PENALTY := 50.0

## Sleepiness per second on calm ground, for a lot of `blocks` blocks. The default is the
## `CALM_ZONE_BLOCKS`-square zone, which is the size every other constant here is pitched against.
func sleepiness_gain_calm(blocks := CALM_ZONE_BLOCKS * CALM_ZONE_BLOCKS) -> float:
	return SLEEPINESS_GAIN_WALKING * sleepiness_calm_multiplier(blocks)

# ------------------------------------------------------------- excitement ---

## While excitement is at or above this, sleepiness is frozen.
const EXCITEMENT_CALM_THRESHOLD := 35.0
## A sleeping baby woken above this goes back to AWAKE.
const EXCITEMENT_WAKE_THRESHOLD := 60.0

## The two the *pram* says out loud, stated as **states with an instruction attached** rather than
## as points on a gauge — which is the whole difference between a cue and the HUD moved over the
## player's head. The other two states the pram shows need no constant at all, because the game
## already has them: the calm threshold, where the day stops progressing, and asleep.
##
## Nearly crying is the last band before `METER_MAX` ends the day. Far enough up that it is not
## a second name for "loud street" — a pavement sits under the calm threshold and a bad moment
## reaches the fifties — and far enough from 100 to be worth acting on: the forty-five points back
## to the calm threshold are about four seconds of a park, or seven and a half of a quiet street.
const EXCITEMENT_NEARLY_CRYING := 80.0
## And how far below the wake threshold a sleeping baby starts to stir. Waking costs
## `WAKE_SLEEPINESS_PENALTY` — half the bar — so this is the most expensive thing in the return
## phase, and without a cue at the pram the only warning is a bar climbing in a corner.
const EXCITEMENT_STIR_MARGIN := 12.0
## Incoming excitement multiplier while the baby is asleep.
const SLEEPING_SENSITIVITY := 0.55

## The bar may reach and sit at `METER_MAX`; the day ends crying only once a further mass of
## excitement this many points has arrived **while she is already sitting at the cap**, within
## `EXCITEMENT_OVERFLOW_WINDOW`. *(2026-09-23, playtest 126, statement 1: "the bar can reach 100
## but we need also like 10 over 3s to actually end the day … those numbers are just me
## spitballing -- we would need to test it".)* That gave 10 over 3s, `docs/DECISIONS.md`'s M96
## measurement.
##
## **Tightened once**, on playtest 128's "we can make the extra push needed to end the day a tiny
## bit more aggressive/tighter" (M100, `docs/TODO.md`). `tests/probes/m96_crying_at_the_top.gd`
## swept 9.5/3s, 10/4s and 9.5/4s against one bump at the cap and the loudest stationary rows
## (`night_raid`, `curfew_announce`, `abduction`), walked past and stood in: widening the window to
## 4s changed no measured outcome, since every scenario's own mass already clears its threshold
## well inside 3s once she is actually in a source's field, so only the mass moved. 9.5 still
## leaves one bump at the cap (8.9 points of overflow, the same measurement M96 made) a real 0.6
## points short of crying, and shortens every loud row's own time to cry over the shipped 10.
##
## **What it counts, and why.** `Baby._update_excitement()` already nets `incoming − decay` every
## frame; while the bar is below the cap that net is simply added and clamped, same as always.
## Once she is sitting at `METER_MAX`, a further positive net is what the clamp would otherwise
## have piled on top of 100 — the bar's own would-be overflow, in the same units the bar itself
## already uses — and that is what this mass sums, in a sliding window the same shape
## `Baby.decay_in_window()` already sums the decay side in. **Not the raw incoming**: charging the
## raw arriving points would make a loud but well-recovering street cry exactly as fast as a
## source with nothing fighting it, which is the "undeserved failure" the player asked to remove
## in the first place. One walker's bump barely reaches the cap and leaves almost nothing for the
## clamp to eat; a sustained source at the top keeps feeding it every frame it stays loud.
const EXCITEMENT_OVERFLOW_TO_CRY := 9.5

## The window `EXCITEMENT_OVERFLOW_TO_CRY` is summed over, in seconds — the player's own "3s".
## Long enough that two contacts in quick succession at the top add up to one push; short enough
## that leaving the source behind lets the mass drain out of the window at close to the pace she
## walked away in, rather than a push from a minute ago still counting against her.
##
## **Left at 3s** measuring playtest 128's "a tiny bit more aggressive/tighter" (M100,
## `docs/TODO.md`): `tests/probes/m96_crying_at_the_top.gd` swept a 4s window alongside 3s against
## one bump at the cap and the loudest stationary rows, and it changed no measured outcome — each
## scenario's mass already clears its own threshold well inside 3s once she is actually in a
## source's field, so the extra second of history never has anything old enough to matter yet.
## `EXCITEMENT_OVERFLOW_TO_CRY` carries the tightening instead.
##
## **The bar itself is untouched by any of this.** The moment incoming drops under decay, the net
## rate goes negative and `excitement` falls back from 100 at its ordinary ground-and-motion rate,
## exactly as it always has — nothing here freezes the bar at the cap or holds it up. The mass is
## a second, independent quantity read alongside it, and it drains the same way `decay_in_window()`
## already does: no reset, just entries aging out of the window as `Baby._clock` advances, whether
## or not she is still at the cap to add to it.
const EXCITEMENT_OVERFLOW_WINDOW := 3.0

## **What settles a baby is being pushed.** The pram is a rocking chair with wheels on, and
## rocking it is the only thing that calms her.
##
## **Zero and not merely low**, because standing still must *freeze* the excitement rather than
## clear it: the day then stops moving in both directions at once, which is the honest version of
## "waiting is not a plan". Any positive idle decay makes standing the strongest move in the game
## — a full meter cleared for a few points of sleepiness, anywhere, including the middle of a
## street she has no business being on.
##
## The counterplay this removes has a better replacement: **walk somewhere quiet**, which is what
## `City.EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER` is for and what the whole route is about.
##
## Running still decays, barely — it is motion, and `EXCITEMENT_FROM_RUNNING` is what makes it a
## bad idea. The ordering is motion-shaped rather than arbitrary: walking calms most, running calms
## a little, standing calms nothing.
const EXCITEMENT_DECAY_IDLE := 0.0
## **The bar has to be seen falling on ground with nothing on it.** The walking rate is set from a
## *net* measurement rather than from taste: the quietest ordinary pavement with the day's own
## crowd on it and nothing authored in range loads about 2.5/s, so this is what is left over, and
## what is left over is what the player watches. At 6.0 a quiet street nets about 3.8/s downward —
## a full meter in a little over twenty-five seconds of walking — where 3.5 left 1.2/s and
## eighty-five seconds, which reads as a bar that is not moving.
##
## **Its ceiling is the catalogue, and it is close.** A row costs more to walk through than around
## exactly while its mean emission along the line beats this number, and the two quietest rows that
## still have to cost — `busker` and `alley_mouse` — mean 6.71 and 6.75. Above about 6.7 they turn
## free and the catalogue loses two rows rather than gaining a rate; `tests/test_events.gd` is what
## says so out loud.
const EXCITEMENT_DECAY_WALKING := 6.0
const EXCITEMENT_DECAY_RUNNING := 0.5
## **The meter does not fall in the escape's basement** *(inbox #765 in minty-lemur: "let's not replenish the meter
## in the basement it's a tense situation")*: walking there earns no decay, awake or asleep, so a
## blow's 40 to 50 points stay on the meter and the blows add up. It is the ground's
## multiplier like the others, `InteriorScene.decay_multiplier()`, and it is the only ground inside
## the building that is not 1.0.
const EXCITEMENT_DECAY_BASEMENT_MULTIPLIER := 0.0

## Excitement per second at full sprint, scaled by how far above walk speed we are.
##
## **The run button is a trap by design**: running is the wrong move against every row that merely
## emits, and the right move only against the things that follow you. This constant is what keeps
## that ordering true across the whole catalogue.
##
## It is sensitive to the shape of `Field.falloff` and not only to the radii. A fatter field makes
## time-in-field matter more, so a shoulder that is too generous makes running *out* of the widest
## rows cheaper than walking — which is not "running works" but "running is a coin flip", the worst
## of the two. `tests/test_events.gd` asserts the ordering row by row rather than leaving it in a
## document, because that is how it can break silently.
const EXCITEMENT_FROM_RUNNING := 14.0
## Constant dread while standing in an alley, and it is set against the ground it is felt on: an
## alley gives back 3.5/s, so the trickle sits just under its own decay and an empty alley is very
## nearly flat rather than a place to recover in. The pressure is that it is never quite recovery.
const EXCITEMENT_FROM_ALLEY := 3.0

## What a `chatting_mother` conversation adds over its whole `detain_seconds`, while the baby is
## awake — "consumes 25%" in the player's own words (`docs/playtests/PLAYTEST-18.md` finding 4, read as
## *adds 25 points*, because the same sentence calls the awake case an overstimulation risk).
## Divided by `detain_seconds` for the flat per-second rate a captured player is charged while she
## is inside the conversation; zero while asleep, which is what makes it a *pure* time loss then —
## see `EventInstance.current_intensity()`.
const CHAT_EXCITEMENT := 25.0

# ----------------------------------------------------------------- the mark ---

## Points of the meter a source has to be *projected* to land on her, held still, before it earns
## an amber caret — and the same points a source's halo rim reads fully red once it has *actually*
## landed them. One number for both directions, because an amount means the same thing whether it
## already happened or is about to. *(2026-09-08, the player, on a five-second horizon and a line
## at 40 of the 100-point meter: "both sound good to me".)*
##
## The rule is about **expected impact**, not about whether a danger changes over time or what a
## row is declared to cost on paper — asking either of those marks a burning building and not the
## fire engine that made it, or a pedestrian who never does. See
## `ExcitementSource.expected_impact_at()` and `EventLook.wants_a_mark()`.
const EXPECTED_IMPACT_POINTS := METER_MAX * 0.4

## How far forward a source's own motion is projected for the caret, and — the same figure read
## backward — how wide every source's sliding window of `landed()` points is
## (`ExcitementSource.WINDOW`). *(2026-09-08,
## the player, confirming both halves of the same figure: "both sound good to me".)* One horizon
## serves past and future alike: the halo is red at `EXPECTED_IMPACT_POINTS` landed over the last
## five seconds, the caret is amber at the same points expected over the next five.
const EXPECTED_IMPACT_HORIZON := 5.0

# ---------------------------------------------------------------- telegraph ---

const TELEGRAPH_TIME_DEFAULT := 2.5
## Hard-fail events must give twice the escape margin of an ordinary event.
const TELEGRAPH_HARD_FAIL_MARGIN := 2.0

# ---------------------------------------------------------------------- run ---

const RUN_LENGTH_DAYS := 14
## How many days a run may lose before it is over.
##
## **A nerve is an attempt, not a day thrown away.** A lost day is retried and the calendar does
## not advance, so a nerve costs only the time it took to lose — which is why the number can be
## this generous. It is the budget for *learning* a day, and a run that ends before act II ends
## before the game has shown what it is.
##
## Asked for rather than derived, and still unmeasured: the run log's `nerve` entries say where
## they went. See `docs/TODO.md`'s open question.
const STARTING_NERVES := 5
## A day is aimed at **about a minute of play**, with dusk as the grace rather than the target: a
## day walked well is over in a minute, and the rest of the clock is there for a day that goes
## wrong — a bad route, a park that turned out to be spoiled, a baby woken on the way home. An
## ordinary day (1 to 5) carries three and a half minutes of that grace; curfew trims it to three,
## which is what keeps a curfew day reading as visibly shorter.
##
## **Dusk must not become the typical length.** A day long enough that the clock is what stands
## between the player and the end of it is a game about waiting rather than about routing.
const DAY_LENGTH_SECONDS := 210.0
## Curfew (day 6 on) day length — kept shorter than an ordinary day so the curfew still reads as
## a tightening once it starts.
const CURFEW_DAY_LENGTH_SECONDS := 180.0

## Five of the eight tasks the calendar carries (`ResistanceSteps._build()`, days 6 to 13), so a
## player who skips or fails three still reaches the good ending. The day-14
## sabotage is a must on top of it: `GameState.earned_good_ending()` asks for both.
const RESISTANCE_GOAL := 5

## How long the neighbor's walk home takes on day 10, from the moment her mark is touched: the
## director starts them this far from her door along the walk (`ResistanceDirector.
## _send_the_neighbor_home()`), and reaching the door is the deadline — walked home into the
## vans. Chosen, not measured, and open to overturn once the late days are timed: at
## `EventCatalogue.NEIGHBOR_WALK_SPEED` (46px/s) it is about eighty tiles of walk, which puts
## them several blocks out in the city on every city, while she, at twice that pace, can
## still meet them on their way in from anywhere she found the mark. A curfew day is 180s.
const NEIGHBOR_WALK_HOME_SECONDS := 55.0

## **The once-only happenings of days 11 to 13** (`ResistanceHappenings`), each arriving a different
## way. Chosen, not measured, and open to overturn once the late days are timed (M184).
##
## Day 11's market is sited ahead of her on her route once she has walked as long as day 3's fire
## waits (`EventDirector.ON_HER_WAY_AFTER`); if nothing on her way has qualified by this far into
## the day, it goes where she is not looking, so the city has lost it whichever way she walked.
const MARKET_GONE_BY := 90.0
## Day 12's park is cordoned off by the police once she has reached its swing (`ParkCordon`): the
## last gap in their tape closes at the soonest this long after the touch, however long their walk
## in took — the taping is paced to it. It closes later where the first officer would come into
## her view of the swing too late for `PARK_CLOSING_WARNING` (a park larger than the view), or
## where the taping would go faster than `PARK_CLOSING_STRETCH_MIN` a stretch. Staying in the park
## until then shuts her in, which ends the day. Open to overturn once the day is played.
const PARK_CLOSING_SECONDS := 12.0
## How long, beyond the walk from where she stood at the touch to the cordon's last gap, the first
## officer is in her view before the gap closes: time to see him and decide, so the officers'
## arrival is a warning she can act on at a walk on every park (`ParkCordon._time_the_close()`).
const PARK_CLOSING_WARNING := 2.0
## The fastest the cordon is taped: a stretch (about a tile of the edge) in no less than this.
const PARK_CLOSING_STRETCH_MIN := 0.3
## How fast the cordon's officers walk in and away: a brisk walk, slower than hers
## (`WALK_SPEED`), so they never read as coming after her.
const PARK_CLOSING_OFFICER_SPEED := 80.0
## How many officers come to walk the park's people out; anyone past that many is sent off when
## the cordon starts.
const PARK_CLOSING_ESCORTS := 2
## How fast the park's people walk out once an officer has sent them off: an unhurried walk, under
## the officers' own pace so the officer walks out behind them.
const PARK_CLOSING_LEAVE_SPEED := 50.0
## Day 13's column: this many army trucks down the main road, one behind the other this far apart.
const COLUMN_TRUCKS := 3
const COLUMN_SPACING := 128.0
## The column comes once she is this close to the main road's middle, across it — about a screen's
## half-width and a block — or at `COLUMN_BY` into the day whatever she is doing.
const COLUMN_WITHIN := 480.0
const COLUMN_BY := 100.0

# ---------------------------------------------------------------- the heat ---
# **How much worse the city gets for a player who is doing well at the optional path.** A row says
# *that* it answers to the resistance with `EventDef.heat_response`; these say what answering costs.
# Keeping the numbers here rather than on the rows is what stops heat becoming a per-row difficulty
# dial — there is one ladder and every row that climbs it climbs the same one.
#
# **All of it is spent between progress 0 and `RESISTANCE_GOAL`**, so the escalation is finished at
# the moment the subquest qualifies rather than trailing past it.

## How long the stop lasts: he stands with her while his field lands `EventCatalogue.OFFICER_STOP_EXCITEMENT`,
## fading from twice its mean to nothing, and then walks back to the car. Short and sharp — "a
## sharp spike is a short duration at high intensity" (the **events** skill) — so the cost is the
## moment he reaches her rather than a field she can stroll out of.
const OFFICER_STOP_SECONDS := 1.0

## How fast it hunts once it starts — the same 130px/s every other pursuer in the game moves at
## (`charging_dog`, `alley_robbery`, the policeman an investigating patrol lets out).
## `validate_pursuit` allows the band
## `WALK_SPEED + PURSUIT_MIN_MARGIN` to `RUN_SPEED - PURSUIT_MIN_MARGIN` — 112 to 148 — and a
## second speed inside it would be a second answer to "can I outrun this", which is the one
## question a pursuit is allowed to ask.
const HEAT_HUNTS_SPEED := 130.0

# --------------------------------------------------------------------- city ---

const TILE_SIZE := 32
const BLOCK_SIZE := 8
## Sidewalk(2) | road(2) | sidewalk(2). A 1-tile sidewalk left only 2px of clearance for
## the rig, which made walking a street feel like threading a needle.
const STREET_WIDTH := 6
const SIDEWALK_WIDTH := 2
## Odd on both axes, and that is a constraint rather than a coincidence: an odd lattice has a
## **middle block**, and the home goes in it. See `CityGenerator._place_home`.
##
## **Eleven is room rather than a rule.** Nine is the smallest lattice on which the home can be
## central; eleven is what a city with one spine, two precincts and a ring of frontages needs in
## order to have a middle you can get lost in the middle of.
##
## The size is what lets the two rules about the home both hold. It has to be central, and it has to
## be `CityGenerator.MIN_HOME_TO_PARK_TILES` of walking from calm ground — and those pull against each other, so
## the lattice has to be wide enough that the centre is still a long walk from the edge of anything.
## On a lattice too small for both, the home gets walked outward until it is far enough, landing
## against the boundary, where most directions are a wall.
##
## Everything downstream of this is stated over it — the event budget per block, the crowd
## population per corridor, the arterial index — so a change here is a change to the whole density
## table. **Re-measure rather than convert.**
const CITY_BLOCKS := Vector2i(11, 11)

## How far a route curbstone's own pixels are blended toward `Palette.ROUTE_KERB_TINT`
## (`GroundLayers._tint_opaque`/`_tint_matching`, `City.tint_the_route()`) — the whole of the
## M145 trial's own dial. The player sets it by eye against a still, not this comment: raise it
## while the cast reads as invisible, lower it while it reads as a drawn hint rather than a cast,
## and zero is the trial's off switch, with nothing else to change. The strip the blend applies to
## is two or three pixels wide (the SVG art's 2px band, the illustrated `curbstone.png`'s 3px one),
## so the number that read as nothing spread over a whole tile has to run higher to register within
## its own width.
const ROUTE_KERB_TINT_ALPHA := 0.45

# ------------------------------------------------------------- street trees ---
# How rare a street tree is, in four numbers. **Trees read like obstacles** — *(2026-09-12, the
# player: "trees read like obstacles (they add noise) so it makes detecting actual obstacles
# harder … trees must be quite rare to be able to still place vans restaurants etc.")* — and a
# tree and an event never share ground, so every pit here is a tile the day's vans, cafés,
# yellers and seals may not use. These four are what keeps that bill small.

# -------------------------------------------------------- the street hierarchy ---
# Three kinds of street: a main road, two retail precincts, and ordinary streets everywhere else.
# With one kind, the only route question a junction asks is *which way*; with three it also asks
# *which kind*, and that is the trade this game is made of.
#
# The lattice itself does not move. Every corridor is still `sidewalk | road | sidewalk` and the
# layout maths is still a modulo — see the note on `STREET_WIDTH`.

## How long a precinct is, in blocks. **Three, with an end you can see, because a precinct has to
## be a place rather than a kind of street.** A whole corridor of it is not a precinct — a kind of
## street you meet every third block is simply what a street is.
const PRECINCT_BLOCKS := 3

## Seconds the **side** street gets, and the amber between the two arms. The main road gets
## whatever is left of the cycle, which is most of it.
##
## The side green is the one the player is actually spending: she crosses a main road while the
## main road is red, which is while the side street is green. So it has to be long enough to walk
## the carriageway with the doubled hard-fail margin a lethal thing owes — a light that turns
## while she is on the paint is the traffic contract broken by the one thing that was supposed to
## be keeping it. `tests/test_tuning_fairness.gd` states exactly that.
##
## The amber is a clearance period rather than a warning — the crossing arm stays red through it,
## and a car too close to stop is treated as already in the box — so it only has to be long
## enough for a committed car to be out the far side. At `CAR_SPEED.x` two seconds is 260px
## against a 192px junction.
const SIGNAL_SIDE_GREEN_SECONDS := 5.0
const SIGNAL_AMBER_SECONDS := 2.0

## How many junctions apart a green wave repeats. **The whole cycle is derived from this**, and
## it is the difference between a signalled spine and a car park.
##
## Signals with arbitrary offsets stop a car at every junction it comes to: measured at act I
## density, two thirds of the traffic was stationary at any instant and the mean speed on the
## arterial was a quarter of a cruise. What fixes it is a *progression* — each junction's cycle
## starts one junction's travelling time after the last.
##
## **The wave serves one direction, not two, and no setting of this constant changes that.** With
## offsets `j·travel`, a car passing junctions `j0 + d·h` at `t0 + h·travel` sees phase
## `t0 + j0·travel + h·travel·(1 + d)`. Going **with** the wave (`d = -1`) the `h` term vanishes and
## the phase never moves — a perfect progression. Going **against** it the phase advances `2·travel`
## per junction, which is constant only if the cycle *divides* `2·travel`, and that is true only at
## `blocks = 1`.
##
## Measured on the wave alone, twenty departures spread across a cycle, no traffic in it:
## **93% of arrivals green with the wave, 51% against it** — and 51% is chance, because the main
## green is 47% of the cycle.
##
## **A two-way wave is not available at any price here.** It needs `cycle = 2·travel` = 5.7s, and
## the side green plus its two ambers is 9.0s before the main road gets a second. Widening `travel`
## instead means a spine cruise under 100px/s, barely above a walk. Nor does another offset scheme
## do better on average: `θ = travel` buys one direction a perfect run and leaves the other at
## chance (72% overall), while `θ = cycle/2` puts *both* directions on a three-phase sweep at 47%
## each. **The asymmetric answer is the best one, not a compromise.**
##
## Three is what makes the cycle come out near a quarter of a minute: shorter and the side street's
## share stops being long enough to cross on, longer and a red is a wait a player will not spend.
const SIGNAL_PROGRESSION_BLOCKS := 3

const MAX_CALM_BLOCKS := 7

# ---------------------------------------------------- multi-block calm zones ---
# A calm area has to be big enough to have a *route* through it. Progress requires motion —
# standing still *drains* sleepiness — and a calm block is eight tiles across, which is jointly
# sufficient for a **lap**: the player circles inside it until the meter fills. That is not a
# balance problem and no balance pass removes it.
#
# A square zone is 2x2 blocks with the streets between them absorbed, so it is
# `2 * BLOCK_SIZE + STREET_WIDTH` = 22 tiles square — 704px, against a block's 256 — and a stretch
# of calm becomes a traverse of somewhere with sides to it. See docs/CITY.md, "Calm zones".

## Blocks per side of the **square** calm zone, which is the size every rate here is pitched
## against. Two. It is a constant rather than a literal because a great deal of arithmetic follows
## from it — the normalisation of the sleepiness curve above, and every test that states a
## relationship in terms of a full-sized zone — and a 2 buried in five different files is how the
## next person changing this discovers the sixth.
const CALM_ZONE_BLOCKS := 2

## The footprints a multi-block calm area may have.
##
## **A zone is a shape rather than a square**, and that is what the arithmetic has to respect:
## anything downstream of `CALM_ZONE_BLOCKS` written as that integer squared is the square's answer
## wearing a general one's clothes. What a footprint costs the lattice is stated over the rect — a
## `w x h` zone absorbs `w*(h-1) + h*(w-1)` streets, which is four for the square and **one** for a
## rectangle — so a 2x1 is a lot of two blocks with the single street between them painted over.
##
## Both orientations are here on purpose. A city whose rectangles all run the same way is a rule
## somebody learns once rather than a place, and the two are genuinely different to walk: a 22x8
## strip is a length with two ends, and which end you come in at is a route decision.
##
## The rate curve covers them without a case: `sleepiness_calm_multiplier` is `1 / sqrt` of the
## block count, so two blocks fill in 8.0s against the square's 11.3s and a 2x1 pays for about one
## traverse of its long side, exactly as a square pays for one diagonal.
const CALM_ZONE_SHAPES: Array[Vector2i] = [
	Vector2i(CALM_ZONE_BLOCKS, CALM_ZONE_BLOCKS),
	Vector2i(CALM_ZONE_BLOCKS, 1),
	Vector2i(1, CALM_ZONE_BLOCKS),
]

const MAX_CALM_ZONES := 2

# ------------------------------------------------------------- hard blockers ---
# A hard blocker is a pruned edge the layout cannot traverse, permanent for the run: cul-de-sacs and
# big buildings. Soft blockers re-cut the map every morning; these hold still and are therefore the
# part of the city a player can **learn**. See docs/CITY.md, "Diversions — the design".

const MAX_CUL_DE_SACS := 8

## The day she is sent to the power station's front door, which is the last day of the run. On this
## day only, the corridor reaches the door (`RouteTree.for_day`) and the closures may not cut it off
## (`ClosurePlanner`); on every other day nothing leads her there.
const POWER_STATION_DAY := RUN_LENGTH_DAYS

# ---------------------------------------------------- block purposes and arcs ---
# A city that becomes a different city while you walk around in it. Every block is generated with an
# arc — the ordered purposes it may pass through — so the transitions are always coherent and the
# whole run can be checked at generation instead of rescued day by day. See docs/CITY.md, "Block
# purposes".

const MAX_COURTYARD_BLOCKS := 3

const MAX_APARTMENT_COMPLEXES := 1

const ALLEY_WIDTH_TILES := 2

# ----------------------------------------------------------- road closures ---
# The road network is pruned per day, so the route is a real decision — avoidable, but clearly "not
# that way". See docs/CITY.md, "Road closures".

## Streets closed per day, by act. Deliberately light, because closures are **not** the main source
## of route pressure: that is at the scale of a *block* — which side of the road to walk down, forty
## times a day — and a closure count tuned as though it were the only pressure would be far too
## heavy underneath it. Four closed streets of a few hundred is a city that has had a bad morning,
## not a city under siege.
const CLOSURES_PER_ACT: Array[int] = [1, 2, 3, 4]

## How much likelier a closure is to land on a turning off the day's corridor than on a street
## somewhere else entirely. **A closure never lands on the corridor at all** — that is a rule in
## `ClosurePlanner._shuffled_candidates` rather than a weight, because a wall across the route is
## not a worse wall, it is the opposite of one.
##
## **The same number pointing the other way is a different design**, and it is the easy mistake:
## aiming closures **at** the streets the player would have used treats a closure as an obstacle,
## and an obstacle nobody meets is scenery. A wall's job is to prune the ways that lead nowhere she
## should go. What survives from the obstacle reading is the reason for the rim: a wall nobody can
## see from the route prunes nothing, so the far corner of the map is what this weight exists to
## avoid.
const CLOSURE_WALL_BIAS := 5.0

## The day-level invariant, and the whole reason the planner is allowed to close anything:
## **at least this many calm areas are still reachable.** Two areas, because a choice of
## destination is what makes a choice of route mean anything — and because one of them may be the
## one she used yesterday, which the day has deliberately spoiled.
##
## **It does not demand two *distinct routes* to each of them.** Edge-disjointness is a **stand-in**
## for winnability, by Menger: two routes means no single street is a cut. That protection comes
## instead from where a wall is *placed* — off the day's tree, so it cannot cut the tree — and the
## second route is a niceness the day offers when the map allows one, measured by `RouteTree` (241
## areas of 241 that the map allowed one to) and gating nothing. Sealing off a section of the map is
## allowed, and it is the point.
##
## What is deliberately **not** weakened is the count. Dropping to one reachable area lets a day
## arrive where the only calm left is the one it spoiled this morning, which is the unwinnable day
## this constant exists to prevent.
const MIN_CALM_AREAS_REACHABLE := 2

## How deep the barrier across a closed street's mouth is, in pixels. Thin enough to read as
## a line drawn across the road, thick enough that nothing walks through it in one frame.
const CLOSURE_BARRIER_DEPTH := 24.0

## Streets closed on a given day.
func closures_for_day(day: int) -> int:
	return CLOSURES_PER_ACT[clampi(act_for_day(day) - 1, 0, CLOSURES_PER_ACT.size() - 1)]

# ------------------------------------------------------------------- the seals ---
# `SealPlanner` closes the streets off the day's route tree — every one of them before
# `REGION_WALL_FIRST_DAY`, `GATEHOUSE_DAY_SEAL_SHARE` of them from it. See docs/CITY.md, "Sealing the
# tree".

## The fraction of the day's **soft** seal pairs that lose one body in the final thinning pass, so
## a wrong turn stays open long enough to be taken and discovered rather than reading as a wall on
## sight. *(Playtest 22, finding 6: "the guidance is there and properly pushes the player in the
## right direction but it feels a bit on guardrails… subtlety is key".)*
##
## **This is the dial the whole pass is about, and it is started small on purpose.** Too low and
## the walls stay too visible to ever be walked into by accident; too high and the corridor stops
## being the way through, which is M64's central claim. `SealPlanner._thin_soft_pairs` is the pass;
## move this against a played day rather than an argument.
const SEAL_THINNING_FRACTION := 0.08

## The chance a through-alley disconnected from the day's tree actually gets walled at both mouths,
## rolled once per qualifying alley. *(Playtest 25, finding 5: "the probability of blocking off
## alleys should be way lower" — and, on which half of "alley" that covers, "at least for full
## blockages -- robbers can be frequent".)* Before this it was 1.0 in code rather than in a
## constant: `SealPlanner._seal_alley_mouths` walled every qualifying alley, every day, with no roll
## at all.
##
## **Started low rather than derived**, the same way `SEAL_THINNING_FRACTION` was: too high and
## alleys read as closed off wholesale again, which is the complaint; too low and the class doc's
## own reason for sealing one at all — an alley walled at neither end, with both its streets sealed,
## is a shortcut between two places the day has already said no to — stops mattering. Move this
## against a played day rather than an argument. `alley_robbery`'s own frequency is untouched: the
## player was explicit that the event and the physical blockage are two different things wearing one
## word.
const ALLEY_MOUTH_SEAL_CHANCE := 0.15

# ------------------------------------------------------------------- regions ---
# `RegionPlanner` partitions the lattice's junctions once at generation and turns that partition
# plus a day's `RouteTree` into a wall with doors in it. See docs/CITY.md, "Regions and the wall".

## How many regions the lattice's junctions are partitioned into. Four, the milestone's own
## recommendation: two is a single dividing line and offers no real choice of which way round it;
## eight or nine — one per calm area — puts most of the lattice's segments behind a wall and would
## almost never let "a region with no calm area gets no doors" have anything to say, since nearly
## every region would hold exactly one calm area and none would be empty.
const REGION_COUNT := 4

## The day the region wall starts standing. Before it the regions exist — the partition is a fact
## about the city from generation on — but nothing is drawn: `RegionPlanner.plan_day` returns no
## walls and no doors. Three task days after the first one, day 6 — *"we should also start with
## doors later since tasks should come first"* — so the resistance has a reason to exist before
## the city starts dividing itself against her. Day 9 is also the day `ResistanceSteps` sends her
## across one of the doors this opens, on purpose: it is the day she finds out whether a stroller
## gets through.
const REGION_WALL_FIRST_DAY := 9

## **From the gatehouse day on, fewer hard blockers off the day's route tree** — *(azure-puffin,
## point 4: "when the guard houses are set up the city gets much harder to navigate let's loosen the
## density of the hard blocking events in that case"; asked which, "fewer of all three. gatehouses
## stay and remain on the actual paths".)* The region wall and its doors divide the city into regions
## from `REGION_WALL_FIRST_DAY`, so the three things that close the ground off the tree are thinned
## from that day on, each by one share below. Nothing about the tree, the routing or the region plan
## changes: these only take blockers away, and a blocker taken away only adds ground she can reach
## (the **city** skill's one monotonic exception), so every reachability guarantee stays true.
##
## **How much is a proposal, not something the player asked for** — they said *fewer*, not how many
## — so each share is a half and each is its own constant, to be moved against a played day.
##
## The share of off-tree streets `SealPlanner.plan_day` still seals, rolled once per street that
## would otherwise carry a seal; the same share multiplies `ALLEY_MOUTH_SEAL_CHANCE` for a
## through-alley's mouths.
const GATEHOUSE_DAY_SEAL_SHARE := 0.5

## The share of `closures_for_day()` that `ClosurePlanner` still closes, rounded to the nearest
## street, a half up (`ClosurePlanner.closures_wanted`).
const GATEHOUSE_DAY_CLOSURE_SHARE := 0.5

## How much clear ground a region door keeps around each of its own bodies — a hut, a boom or an
## alley post. No event may be sited so that its own field (`EventDef.field_reach()`) reaches inside
## this radius of one, and no mover's beat or path may run through it: `EventScheduler._place_one()`
## refuses the candidate and rolls again, and `EventDirector.due()` waits rather than siting one in
## front of her there. *(2026-09-20, the player: "there should be a gap for events immediately
## surrounding the gates".)*
##
## **Stated over the body, not over the release point, because a door works in both directions.**
## There are two release points, one each side of the crossing, and a gap measured from the body
## covers both without either having to be computed at placement.
##
## **The number is the door's own field plus the clearance the release sets her down at.** She comes
## out `obstructs_radius + PLAYER_BODY_RADIUS + CheckpointController.CHECKPOINT_RELEASE_MARGIN` (54px) from the body that
## let her out, and the widest field a door's own structure carries is the gate's 120px
## `outer_radius` — so from either release point she walks the full width of the door's own field,
## and then some, before anything else can start charging her. At `WALK_SPEED` that is about a
## second and a half of reading a street she has just been put down on, unpriced.
##
## **It is a refusal at placement and never a pass that clears the ground afterwards**, the same
## rule every closure and every event in this game is placed under: a row that cannot find ground
## outside every door simply is not placed that day, which is the failure direction the rest of the
## scheduler already has. The wall's own `roadblock` bodies are **not** given a gap — a wall is
## structure, it stands where the boundary is, and dropping one would open a street the partition
## means to hold. What keeps a wall from summing with the door it stands beside is
## `EventDef.barrier_structure` instead.
const CHECKPOINT_EVENT_GAP := 176.0

## Seconds a camera move that is not her walking — currently only the checkpoint's own ease onto
## the hut and back — takes to arrive. The move is smooth-stepped rather than linear so it reads
## as an ease rather than a slide or a cut; short enough that most of `EventCatalogue.CHECKPOINT_DETAIN_SECONDS`
## is spent settled on the hut rather than still travelling to it. See `Stroller.focus_camera_on()`.
const CAMERA_EASE_SECONDS := 0.5

## Below this speed a car counts as actually stopped rather than still easing toward the line —
## `Crowd._stop_for_gates()`'s own clock for `Crowd.GATE_STOP_SECONDS` only runs while a car is this
## slow, or a car that merely eased off on its approach would bank wait time it never spent
## waiting.
const CAR_STOPPED_SPEED := 5.0

# --------------------------------------------------------------- the crowd ---
# The crowd is why a street is loud and a park is quiet, and it is the base noise floor a day needs
# so that standing in one place cannot work. It is emergent rather than a city-wide constant,
# because a number nobody can see means nothing.

## People, then cars, on the streets in each act. The city empties as the acts turn, and
## this is the cruellest number in the game: from act III the streets are *quieter*, because
## there is nobody left going out on them. The city becomes an easier place to put a baby to
## sleep, and that is the horror. Act IV puts a little back, but it is not the same traffic.
##
## The emptiness has to be **the empty pavement**, not an ambient band on the arterials: a city that
## empties out invisibly is a difficulty change the player feels and cannot see.
##
## **These are populations of the *field*, not of the city.** The crowd lives in a
## `CROWD_FIELD_RADIUS` box that travels with the player, so the number here is what is on the
## streets *around her* rather than what is scattered over ten thousand tiles. A whole-city figure
## reads about a third as dense as it looks — a hundred cars over sixteen corridors is one every six
## seconds in your lane, which is a road you can ignore. **Measure these, never convert them by
## area**: `tests/test_crowd.gd`, "the road has to be waited for".
##
## **A junction is a place a car can be stopped, which is what gives the road a capacity.** Without
## it two cars on crossing arms drive through each other, the network's throughput is unbounded, and
## a car count means whatever it happens to look like. With the box rationed, a car waiting at a
## light beside you is louder for longer than one going past, so the same population puts the
## arterial floor over the ceiling `tests/test_crowd.gd` states — *"expensive to cross, not
## impossible"*.
##
## **The honest answer to "the main road is too quiet" has twice been something other than more
## cars.** The spine's share is decided by `CrowdLanes.busyness` and by the axis roll, not by the
## population: with the arterial weight spent on one axis rather than split across a phantom
## east-west one, the spine holds more of the same total and adding cars only puts junction
## contention over the rate the suite allows.
const CROWD_PEDESTRIANS_PER_ACT: Array[int] = [200, 150, 42, 70]
const CROWD_CARS_PER_ACT: Array[int] = [34, 26, 8, 16]

## Half-extent of the box the crowd lives in, in px. Everything inside it is simulated;
## anything that leaves it is recycled to the far edge and walks back in.
##
## The floor is the screen: an agent recycled at 800px from the camera is always off-screen when it
## appears, whichever way the player is facing. The ceiling is honesty — a box much larger than this
## spends frames on pavement nobody can see, which is the whole reason the crowd is a field.
const CROWD_FIELD_RADIUS := 800.0

## Speed range, min..max. Walkers are slower than the player on purpose: passing someone is
## something *she* does, at a distance she chooses.
const PEDESTRIAN_SPEED := Vector2(46.0, 74.0)
## Ordinary traffic outpaces a walk but never quite matches the fire engine: an emergency
## vehicle has to stay the fastest thing on the road, or its long telegraph stops reading as
## urgency and starts reading as ordinary traffic.
const CAR_SPEED := Vector2(130.0, 185.0)

const PEDESTRIAN_INNER_RADIUS := 22.0
const PEDESTRIAN_OUTER_RADIUS := 30.0

const CAR_INNER_RADIUS := 38.0
const CAR_OUTER_RADIUS := 104.0

# ------------------------------------------------- walkers at a region door ---
# What a walker does when its street crosses a region wall at a door. *(Playtest 58: "walkers walk
# through checkpoints..."; asked which rule they get, "Held at the hut like her"; then "a small
# fraction can do that"; "others can turn back"; "don't want a queue that is long".)* The answer is
# drawn once per walker, when it is placed, so a walker's answer at a door can never change halfway
# down the street it is walking.

# ------------------------------------------------- walkers round a solid body ---
# What a walker does about a stationary solid body standing on its own lane — a café's tables, a
# construction band, a kerbed van, a stall. *("yes every solid body should do that -- not
# necessarily force a turn around but at least avoid the solid".)* It steps into the other lane of
# its own footway and steps back after; only a body that takes **every** lane of that footway turns
# it at the last junction, the way a seal does. See `WalkerStrategy._step_around_a_body()` and
# `CityMap.obstructed_tiles`.

# ------------------------------------------------------- bodies on the street ---
# A crowd you can walk through is a field with a picture attached: every pavement is identical, none
# of them can hurt you, and the route is not a decision. See docs/MECHANICS.md, "The street has
# physics".

## The pram's own collision circle, in px. Authored in `scenes/player/stroller.tscn`; this is
## the copy the rules that reason *about* it can read, and `tests/test_events.gd` asserts the two
## agree, because a duplicated number that nothing checks is a lie waiting to happen.
##
## It is the same 14 as `Crowd.BUMP_RADIUS` and they are not the same quantity: that one is a tuning of
## when a *crowd contact* fires and is stated against the lane spacing, this one is how much room
## she physically takes up. Either may move without the other.
const PLAYER_BODY_RADIUS := 14.0

## How far into a building the straight line from a source to her has to reach before the building
## stands between them and the source's excitement stops reaching her, in px measured from the
## nearest open ground — `CityMap.wall_between()`. *(plaid-wombat, inbox #554: "the blocking should
## happen in the middle of the wall (or one tile deep)"; inbox #568: "half a tile was only supposed
## to be done if the wall is only one tile wide otherwise it should be one tile".)*
##
## **One tile, wherever the building is thicker than one tile.** So a line that clips a corner, runs
## along a face or crosses only a building's outer tile blocks nothing, and a building two tiles
## thick blocks a line across it only along its middle and not within a tile of an open end of it
## — see `CityMap.wall_between()`. It has to stay **at most `TILE_SIZE`**, the
## depth `CityMap.wall_between()` can answer from a tile's eight neighbours alone, and at least
## `THIN_WALL_SHIELD_DEPTH`. `tests/test_wall_shield.gd` holds both.
const WALL_SHIELD_DEPTH := float(TILE_SIZE)

## The same depth inside a wall only one tile thick, which never has a point a whole tile from open
## ground: **half a tile, its middle**, so a line across it is still blocked there, square or
## slanted, anywhere but within half a tile of an open end of it. It has to stay **over
## `PLAYER_BODY_RADIUS`**, or a pram whose body pokes into a thin wall's edge is shielded by its own
## overlap, and **at most half a tile**, or a one-tile wall could never block anything.
## `tests/test_wall_shield.gd` holds both.
const THIN_WALL_SHIELD_DEPTH := TILE_SIZE * 0.5

## How far apart a contact is pushed, and how far apart it has to get before it counts as over.
##
## **The two numbers that make a bump end**, and they have to be two.
##
## Resolving the separation to exactly `Crowd.BUMP_RADIUS` — the distance at which `touching` flips back
## to false — parks a resolved contact precisely on its own release threshold, where it flickers
## across it and fires a fresh `Crowd.BUMP_INTENSITY` jolt every couple of frames for as long as the pair
## are near each other. A contact that costs its jolt once is a decision; one that costs it ten
## times in two seconds is being stuck to somebody, and three of those in half a minute is a lost
## day.
##
## So it is a hysteresis band: pushed apart to `BUMP_CLEAR_RADIUS`, and `touching` is only released
## past it. A bump therefore ends the frame it is resolved, and it can never re-fire without a
## genuine second approach.
##
## Deliberately a small band. Widening it would widen the corridor she has to thread down a
## pavement, and the note on `Crowd.BUMP_RADIUS` is what happens when that number grows.
const BUMP_CLEAR_RADIUS := 19.0

## How far across their own pavement somebody she walked into steps, and for how long.
##
## **The half the hysteresis alone cannot fix.** A walker steers to its lane centre at
## `CrowdAgent.STEER_SPEED`; if she is standing on that centre, the walker resolves out of the
## contact and then immediately steers back into her, forever. The separation being positional is
## what stops them being *inside* each other and cannot stop them being *against* each other.
##
## So the person she walked into gets out of the way, which is what a person does. Positional
## still — it is a target the walker steers to, not a force on the player — and clamped inside its
## own pavement band by `CrowdAgent.step_aside`, because a walker that yields into the carriageway
## is a walker under a car.
##
## A tile is the width of one pedestrian lane, so this is exactly "they move over one".
const BUMP_STEP_ASIDE := float(TILE_SIZE)
const BUMP_STEP_ASIDE_TIME := 2.5

## How far ahead somebody notices a pram coming and moves over, and how near her line they have
## to be to bother.
##
## **This is what keeps pedestrians from being the thing that kills every run.**
##
## The design is that the crowd is *expensive to be careless in and free to be careful in*, and the
## **ratio** between those is what makes a pavement a decision — eleven contacts in forty seconds
## down a lane centre against one holding the midline. Without a yield the ratio collapses to
## thirteen against fifteen on the arterial and eleven against nine on a back street: no careful
## line, so the crowd is a toll rather than a decision, and at ~30 points a contact it is a toll
## that ends the day.
##
## **A careful line cannot be defended by geometry alone**, because anything that gives walkers
## reason to be off their exact centre — junctions, recycling, the sidestep above — eats it. So the
## careful line is a **behaviour**: somebody who sees a pram coming moves over. It prices the right
## thing, a contact being what carelessness costs rather than what walking costs, and it stays
## honest three ways: they only move a lane, they cannot move into the carriageway
## (`WalkerStrategy._pavement_band`), and at `RUN_SPEED` she covers the notice distance in 0.57s against
## the 0.36s they need to clear a lane, so **running still hits people**.
const CROWD_YIELD_DISTANCE := 96.0

## The car's body, as a box rather than a circle: a car is two tiles long and one wide, and a
## radius that covered its length would kill people standing beside it. The body is symmetric about
## the car's centre, but only its *front half* kills (`Crowd._strike()`): the box runs from the
## centre forward `CAR_STRIKE_HALF_LENGTH` and `CAR_STRIKE_HALF_WIDTH` either side of the axis, so
## nobody dies behind a car that drives away from them.
const CAR_STRIKE_HALF_LENGTH := 26.0
const CAR_STRIKE_HALF_WIDTH := 14.0
## Below this a car cannot run anybody over, however close they stand to it. A car halted at a
## zebra is scenery, and walking into one must not end the day.
const CAR_STRIKE_MIN_SPEED := 20.0

## Seconds of travel at which a car sounds its horn at somebody standing in its lane. This is
## the traffic fairness contract, and `tests/test_tuning_fairness.gd` checks it: the warning has to be
## long enough to walk out of the carriageway before the car arrives, with the same doubled
## margin every other hard fail gets.
const CAR_HORN_TIME := 1.6
## The horn itself, as a jolt on the car that sounded it. A near miss costs something even
## when it is only a near miss.
const CAR_HORN_INTENSITY := 18.0
const CAR_HORN_DURATION := 0.9
const CAR_HORN_INNER_RADIUS := 45.0
## Tight for the same reason as the rest of the crowd's radii, and still a good deal wider than the
## car itself: a horn is meant to be heard from further away than an engine.
const CAR_HORN_OUTER_RADIUS := 132.0

## Traffic that queues instead of driving through itself. A car keeps `CAR_HEADWAY_TIME` seconds of
## clear road in front of it and never closes to less than `CAR_GAP_MIN`, which is a car's own
## length plus a nose.
##
## The relationship that matters, and the one `tests/test_crowd.gd` states: the headway has to
## be longer than the *braking* time from cruise, or a car physically cannot honour it and the
## queue resolves by interpenetration again. `CarStrategy.CAR_BRAKE` is shared with the zebra, so this is
## free to check and cheap to get wrong.
const CAR_HEADWAY_TIME := 0.85
const CAR_GAP_MIN := 66.0

const CAR_ZEBRA_SIGHT := 200.0
## How far before the paint a car giving way comes to rest, measured to the car's centre. Its
## nose is `CAR_STRIKE_HALF_LENGTH` in front of that, so it stops a few pixels short of the
## zebra rather than over it.
##
## **Giving way is aimed at a place, and this is the place.** Braking toward *zero speed* from
## wherever a car happens to notice leaves it wherever the curve runs out — and `CAR_ZEBRA_SIGHT`
## is nearly four times the distance it needs, so that is usually most of a block short — while
## saying nothing about not stopping on the paint. A car half a block back and a car parked on the
## crosswalk are the same missing thing.
##
## Why it matters more than it sounds: the painted carriageway is one of the two things standing
## in for a telegraph in the traffic fairness contract. A car halted on the zebra is scenery by
## `CAR_STRIKE_MIN_SPEED` and cannot hurt anybody — but it is *unreadable* scenery sitting on the
## one place the game has told the player is the safe way across.
const CAR_STOP_LINE_SETBACK := 34.0
## How close to the crossing the player has to be for the traffic to yield. Roughly "standing
## at the kerb waiting", which is the gesture the crossing is for.
const CAR_ZEBRA_WAIT_RADIUS := 56.0

## How far out a car starts watching the junction it is coming to.
##
## The relationship, the same one `CAR_ZEBRA_SIGHT` keeps and for the same reason: it has to
## exceed `CarStrategy.braking_distance(CAR_SPEED.y)` by the setback, or a car that has only just seen a box
## it must wait at cannot stop before it. Below that the give-way turns into a car standing in the
## middle of the junction, which is the failure it exists to prevent rather than a milder version
## of it.
const CAR_JUNCTION_SIGHT := 200.0

## How fast a car takes a turn, and the tightest arc it will take one on.
##
## **The radius is the city's geometry rather than a dial** — a lane centre sits 16px from its own
## kerb and the two lanes of a carriageway are 32px apart, so the arc joining one lane to another
## comes out at 16px on the near-side arm, 48px on the far-side one, and 16px for an about-face. The
## minimum is the floor under all three: below the car's own half width (`CAR_STRIKE_HALF_WIDTH`,
## 14px) an arc sweeps the body's inner flank backwards through the centre of its own circle, which
## is a pivot rather than a turn, and 16 is both a little over that and the exact radius an
## about-face already has to use. A turn that cannot be taken at this radius or wider is refused, not
## squeezed.
##
## The speed is what makes a turn *read* as one. At the tightest arc the quarter turn is 25px of
## road, so 60px/s spends 0.42s in it and the far-side arm 1.25s — both long enough to watch, where
## a car taking the same corner at its 130px/s cruise is through it in 0.19s and reads as the swap
## this replaced. The relationship under it, which `tests/test_turns.gd` states: `CAR_TURN_SPEED² /
## CarTurn.CAR_TURN_RADIUS_MIN` is 225px/s² of lateral acceleration, under `CarStrategy.CAR_BRAKE`'s 320 — a car is
## never asked to corner harder than it can brake. It is also well over `CAR_STRIKE_MIN_SPEED`, so a
## turning car is still a lethal one and a junction is not a safe place to stand.
##
## **A car does not always reach it.** The approach eases from the moment the car knows it is
## turning, at `CarStrategy.CAR_ZEBRA_APPROACH_BRAKE`, and what it knows is bounded by `CrowdAgent.LOOKAHEAD` —
## about a hundred pixels of warning at an ordinary closure, which from cruise leaves it entering
## the arc at around 130px/s and still braking. Lengthening the lookahead would buy the rest, and
## would also move which junction a car turns at, which is a route decision rather than a turn.
const CAR_TURN_SPEED := 60.0

# ------------------------------------------------------- the world near you ---
# The world is populated around the player rather than authored across a map she mostly never
# visits: nothing is loaded upfront, and a thing whose whole content is a moment is sited in front
# of her while she walks. See docs/MECHANICS.md, "The world near you".

## How close the player has to get before a planned event is actually put in the world.
##
## Two floors, and the larger wins. The **screen**: half the viewport diagonal is 735px, so at
## 900 an event always appears off-camera and never pops into an empty pavement. The **fairness
## contract**: the widest field in the catalogue is 380px, so an event that streams in is
## already outside its own outer radius when it becomes visible — which is what makes streaming
## an event legal at all. `tests/test_events.gd` checks the second against the catalogue.
const EVENT_STREAM_RADIUS := 900.0
## And how far past it an event has to get before it is taken away again, so an event on the
## boundary does not flicker in and out as the player paces.
const EVENT_STREAM_HYSTERESIS := 260.0

## Far enough from the player that nothing there can be seen, which is what *nothing vanishes while
## you are looking at it* is measured against.
##
## The camera sits on her at zoom 2 over a 1280x720 viewport, so the visible world is 640x360 and
## its far corner is 367px away; `Stroller.CAMERA_LOOK_AHEAD` can push that to about 410 on the
## trailing side. 420 is the first round number outside it.
##
## Not to be confused with `EVENT_STREAM_RADIUS`, which is deliberately more than twice this: an
## event is put in the world *long* before it can be seen, so that nothing is ever watched into
## existence. This is the other end of the same rule — nothing is watched out of existence either.
const OUT_OF_SIGHT := 420.0

## How far ahead of the player an `AHEAD` event crosses her line, in px. This is a *reaction
## window* stated as a distance: at `WALK_SPEED` it is the two seconds she gets between seeing
## the cat crouch and reaching the place it bolts through.
const AHEAD_LEAD_DISTANCE := 184.0
## Half the visible view along each axis, in px, from her: the camera sits on her at zoom 2 over a
## 1280x720 viewport, so the visible world is 640x360 — 320px sideways, 180px vertically.
##
## **This replaces a flat cap that was sized for one axis and applied to both.** The old
## `SIGHT_AHEAD` (200px) put anything `EventDirector` sited on the horizontal axis 120px inside the
## boundary there — on screen the moment it appeared, whatever the vertical arithmetic said —
## which is exactly *"bikers / unleashed dogs all pop in in front of the player instead of starting
## off screen"* (playtest 33, finding 8). `Offscreen.boundary()` asks the real question
## instead (`Offscreen.boundary()`): how far to the edge of this box *along the heading actually in play*.
const VIEW_HALF_EXTENT := Vector2(320.0, 180.0)

# The page's counter counts encounters (`EncounterWatch`, docs/TELEMETRY.md, "The page counts
# visits"). None of these four changes anything a player can feel: they decide only what is sent.

## The share of what is drawn for an instance that has to be inside the view for it to count as
## seen: a sliver at the edge does not. *(misty-newt: "(fully; or reasonably) visible on screen
## (just a part or too far off the edge doesn't count)".)*
const ENCOUNTER_SEEN_SHARE := 0.8

## The default seconds of notice a row gives from off screen (`EventDef.offscreen_notice`): for a
## row created at once — a patrol sent down the road — the seconds it still has to be off screen
## once it is created, at the speed the gap is actually closing. *(2026-09-07: "events that go
## towards the player (biker / pursuing dog) should at least be 200ms off screen with a warning.")*
## A row warned of before it exists is placed just out of sight instead (`PendingWarning`), and a
## pursuer warned first reads its own notice as its badge alone.
##
## **Per-row rather than universal**, since playtest 34 asked for two rows to move in opposite
## directions on the same day: `charging_dog` needs more of it (finding 2) and `cyclist` needs less
## notice (finding 3), which his own warning time now answers rather than this. This constant stays
## as the default every row gets unless it overrides.
const OFFSCREEN_NOTICE := 0.2

## She has to actually be going somewhere for something to happen in front of her. Below this
## there is no "in front".
const AHEAD_MIN_SPEED := 40.0

## How many of the events handed out on her route after day 6's mark a man shouting's marble is one
## of: the route's bag is rigged (`MarbleBag.rig()`) with a bag of this many marbles, one
## `homeless_yeller` and the rest drawn from the bag she was drawing from, and he is put on her route
## once her walk finds him a site (`EventDirector._place_on_her_route()`). *(olive-koala, statement 2: "after touching
## the mark a marble bag with 1/3 chance of yeller should be put in so the yeller is guaranteed to
## encounter a yeller in the next three events" · inbox #561 in coral-bunny, on the size of a rigged bag: "x
## defines how soon we want to get the guaranteed event", and, told how sparse the route's events
## are: "maybe let's make the other rigged bags smaller, too".)* The second of the next two: at
## `EventDirector.AHEAD_INTERVAL`, within a minute of walking.
const TASK_CONTACT_WITHIN_THE_NEXT := 2

## The same for day 11: once she has read its mark, a second loudspeaker mast's marble is one of
## the next this many events, and the mast is put on her route once her walk finds it a site, beside
## the one near the mark the task points at first. *(inbox #561 in coral-bunny:
## "day 11 is going to be a x=3", then "let's make the other rigged bags smaller".)*
const MAST_WITHIN_THE_NEXT := 2

## The same for day 7: once she has read its mark, a second `delivery_van`'s marble is one of the
## next this many events, and the van is put on her route once her walk finds it a site, besides the
## one near the mark the task points at. *(inbox #586 in olive-hedgehog: "each olive badger rigged
## bag should be 2 or 3. use your own judgement on how soon the events should happen"; inbox #650 in
## mossy-beaver, of which forced cases get one: "I guess that leaves only the van?")* Two is the
## filer's proposal inside the player's "2 or 3", the size day 6's and day 11's rigs have.
const VAN_WITHIN_THE_NEXT := 2

# ------------------------------------------------------ one event per block ---
# The density target is one event per block, so the decision a player makes about an obstacle
# happens several times a day rather than once. The density itself lives in
# `EventScheduler.budget_for()` and the catalogue's `max_per_day`, both **measured** rather than
# derived.
#
# What lives here is what the density needs in order to be legible. Placement is a uniform random
# tile, so a low per-type cap is the only thing keeping two of the same event off one pavement —
# which is a coincidence, not a rule. At this density it has to be a rule.

# --------------------------------------------------------- placement by role ---
# docs/CITY.md, "The words for it" and "Diversions — the design". A day is planned against a
# **corridor** — the ways from the doorstep to the calm areas still worth reaching — and what each
# of these numbers does is pull one kind of thing toward one part of it.
#
# Both are stated as **how many times a tile is offered to the roll**, which is `_ground_for`'s
# existing mechanism rather than a new one: the roll is an index into the candidate array, so
# offering a tile four times over *is* the weight, and every spacing rule downstream keeps working
# unchanged. The precinct weight above is the same shape and is multiplied through, so a corridor
# tile in a precinct is offered sixteen times.
#
# Neither is a filter, and the one filter there is lives in `EventScheduler._copies_of`: **a wall
# never stands on ground a route runs along.** That one can be absolute because the whole
# off-corridor city remains available to it, so it cannot starve a row of ground — which is what a
# weight buys everywhere else here and is why these are weights. It is stated per **sidewalk**, so
# the far side of a route's own street is legal ground for a wall at the weight of ordinary far
# ground; the weights below are still read off the street's depth, so the rim is still where a wall
# is pulled.

## How much likelier a closure is to land in a gap between two adjacent strands than on the rest of
## the rim it is already biased toward.
##
## The other half of *"wall or event"*, and it is the **impassable** half: an event in a gap makes
## switching strands expensive and a closure makes it impossible, which is why having both is
## variety rather than two names for the same thing. A day closes a handful of streets at most
## (`ClosurePlanner.closures_wanted()`: `CLOSURES_PER_ACT`, and from `REGION_WALL_FIRST_DAY` on
## `GATEHOUSE_DAY_CLOSURE_SHARE` of it), so this can be strong without closing many gaps — the quota
## is the limit.
const CLOSURE_GAP_BIAS := 4.0

# ----------------------------------------------------- solid things are solid ---
# The rule is in `EventDef.obstructs_radius`: **anything that stands still is solid at the width it
# is drawn**, derived rather than set per row — a field only ever *reached for* leaves large,
# visibly solid objects with no body at all. What lives here is the one number that rule needs from
# outside itself.

# ------------------------------------------------------ running that matters ---
# Running is the wrong move against everything you route around, so there has to be one kind of
# thing it is the *only* answer to, or the run button is a trap. And the run is **taught** rather
# than merely permitted, on the day it starts to matter: day 1 is arrow keys and nothing else, and
# day 3 is the day something comes after the pram.

## The day running stops being a bad idea and starts being the answer.
##
## Day 3 is act I's last day and already the day it grows teeth — `reversing_lorry` arrives then,
## and `cyclist` on day 2 — so this is the third of three escalations rather than a fourth kind of
## thing. It is also late enough that a player has had two days of the meter to learn that running
## is expensive, which is what makes being *made* to run land as a change of rules rather than as
## the rules finally being explained.
const RUN_TAUGHT_DAY := 3

## How long a pursuer keeps coming once it turns lethal, before it gives up on her: **a long cap,
## not an end she can walk out of**. *(Amendment 8 of M226, the player: "pursuers should never (or a
## long time) stop pursuing if she walks -- that will make it impossible to walk away".)* Walking
## away loses by construction: the pursuer is faster than a walk, and it keeps coming for longer than
## any start it can be given takes to close at the 38px/s walking leaves it (from just off screen to
## her side, about 340px, that is under 9s). Running is what ends a chase, at `PURSUIT_SHAKEN_OFF`'s
## rate, so the sprint is priced by how soon she runs, never by this clock. A long cap rather than
## none, so a pursuer stood against a wall it cannot get round lets go in the end rather than
## charging her from behind it for the rest of the day. Every pursuer holds it: the day-3 dog, the
## resistance's sent robber and guard, the waiting robber and guard, the masked man, and what hunts at
## heat (`tests/test_events_costs.gd`).
const PURSUIT_TIME := 30.0

## And the least a pursuer's speed may differ from either of hers.
##
## The contract in one line: **walking must lose and running must win.** So its speed sits
## strictly between the two, far enough into the band that the difference is worth acting on
## inside `PURSUIT_TIME`. The margin is small at the top end on purpose — a run that only just
## outpaces it is a run she has to actually commit to.
const PURSUIT_MIN_MARGIN := 20.0

## And the least notice one has to give: its telegraph, during which it is visibly coming and
## emitting `EventInstance.TELEGRAPH_INTENSITY_FRACTION`, but cannot yet end the day.
##
## The least warning anything that arrives from off screen is owed, from its screen-edge badge to
## the earliest it can reach her — flat, and not worked out from its field or its speed: a second,
## the player's time to react. *(PLAYTEST-145: "to a human 100ms feels instant, 1s is time needed
## to react to something" · "the 2.9 is not important"; busy-quail, inbox #569: "1s warning should be
## enough -- there is enough screen space to cross".)* `EventDef.minimum_telegraph()` answers it for
## every non-pursuer warned of before it exists (`EventDef.warns_before_it_exists()`: the cyclist,
## the fire engine, day 13's column), whose place follows her until it exists, so the
## walk out of its field that `required_telegraph_time()` prices is not a walk she can take during
## the badge; an ordinary pursuer is owed `PURSUIT_MIN_NOTICE` of visible approach, while a sent
## robber or guard arrives chasing after its badge alone. A row with an in-world telegraph owes
## the minimum its field sets even when it has no coming badge (`EventDef.telegraphs` is false).
const OFFSCREEN_WARNING_MIN := 1.0
## The longest a screen-edge badge is up alone, with nothing in the world, before the thing it warns
## of is placed just out of sight where it points (`PendingWarning`). *(calm-kestrel, inbox #559: "it
## should *always* show the warning for x seconds (never longer than 2s) without placing anything
## then place the object immediately off screen so it will immediately start coming on the screen
## turning off the warning"; busy-quail, inbox #569: "1s warning should be enough -- there is enough
## screen space to cross -- let's apply that to the others as well".)* A ceiling, not a length: a row
## whose own is already shorter keeps it, as the day-3 dog keeps its half second
## (`EventDef.offscreen_notice`). `EventDef.validate()` refuses a row warned of first whose badge
## alone (`EventDef.warned_for()`) is longer.
const WARNING_ALONE_MAX := 1.0

## An ordinary pursuer's telegraph is the **approach**: it exists and visibly closes on her the
## whole time it telegraphs, unlike a row warned of before it exists (the fire engine, sited by a
## screen-edge badge with nothing in the world until its telegraph is spent). A dog that has to bark
## for two seconds before it is allowed to start running is not a dog. So the notice is the sight of
## it closing, and this is how much of that she is owed before it can touch her: the day-3 dog's
## approach. Day 13's guard set on her by the task in her view is the badge's kind instead: he stands
## with his warning up for `WARNING_ALONE_MAX`, a notice the task gives this one instance
## (`EventInstance.notice_her_at()`), which no row's contract states.
##
## **Two other kinds of pursuer are owed something else.** A sent robber or guard has no approach:
## its badge is the notice, and an offscreen run can shake it off. A pursuer that sets off beside her
## (the man a vehicle lets out) is the badge's kind too: it exists only to charge her, and what she
## is owed is the indicator that it is about to, for at least the off-screen charger's
## `OFFSCREEN_WARNING_MIN` (inbox #764 in minty-lemur). A checkpoint's guard owes none of his own: his warning came
## before he was set on her, a hut's guard's raised hand from her crossing for `CheckpointController.CROSSING_WARNING`
## (`PursuitSpec.Start.CHARGES_AT_ONCE`). A pursuer that waited for her warns on its own clock
## inside its one radius (`PursuitSpec.warns_for`), so this floor bounds nothing it does.
const PURSUIT_MIN_NOTICE := 1.5

## How long she has to be **running** before it gives up, in seconds.
##
## The half that makes running **payable**, and the whole of what the chase costs when it is
## answered. Running is `EXCITEMENT_FROM_RUNNING` a second, so a chase priced by its own clock costs
## the same whether she reacted on the first frame or the last — a toll rather than a lesson.
##
## **Stated over the player, not over the gap**, and the two are not the same rule in a real street.
## The same idea as geometry — *the gap has been opening for this long* — is unusable: a run opens
## the gap at 38px/s against the day-3 dog, a fifth of a pixel a frame, so anything that momentarily
## stops her gaining ground resets the timer to zero. A corner, a kerb, a pedestrian, the 0.37s the
## about-turn itself takes. The dog then goes on chasing somebody who is visibly sprinting, which is
## the one outcome that makes the mechanic unteachable.
##
## The contract it used to carry is unaffected, because it never rested here — it rests on the
## speed clauses in `validate_pursuit`. A pursuer is faster than a walk and slower than a run by
## `PURSUIT_MIN_MARGIN` on both sides, so **walking away still cannot end it** (she is never
## running, so this timer never starts) and **running away always can**.
##
## 0.35s is "almost immediately" and is about what the about-turn costs: the dog breaks off as she
## comes up to speed rather than after she has opened thirty pixels of daylight on it. That is most
## of what the whole answer costs her.
const PURSUIT_SHAKEN_OFF := 0.35

## The pursuit fairness contract, and the one place it is stated.
##
## `validate_event`'s escape-distance rule is about walking out of a *field*, and a pursuer has no
## field to walk out of — it follows. So it needs its own contract, and `docs/TODO.md` said what it
## would have to be stated over before there was anything to state it about: `RUN_SPEED`.
##
## The clauses, each of them one of the ways a pursuit can be unfair:
##
## - **Walking must lose.** Faster than `WALK_SPEED` by a real margin, or the mechanic teaches
##   nothing — she strolls away and the run key stays a trap.
## - **Running must win.** Slower than `RUN_SPEED` by the same margin, or it is not a lesson, it
##   is a death sentence with a keypress attached.
## - **It must let go in the end**, within `PURSUIT_TIME` (a long cap, amendment 8 of M226), so a
##   pursuer stuck against a wall does not charge her for the rest of the day. Running ends it long
##   before, at `PURSUIT_SHAKEN_OFF`'s rate, so the cap is never what a runner pays for.
## - **Running has to open more than the radius that ends the day**, over the whole chase. Otherwise
##   running is the correct answer and still not enough.
## - **An ordinary pursuer's notice is the sight of it coming**, at least `PURSUIT_MIN_NOTICE`.
##   A sent pursuer (`PursuitSpec.Start.ARRIVES_CHASING`) has its badge alone, checked by
##   `EventDef.validate()`, and running may shake it off while it is still offscreen. One that
##   sets off beside her (`PursuitSpec.Start.SETS_OFF_BESIDE_HER`) stands with its warning up
##   for its notice and is owed the badge's heads-up, `OFFSCREEN_WARNING_MIN`, rather than an
##   approach she never sees.
## - **A pursuer that waited for her warns inside its one radius for its `PursuitSpec.warns_for`
##   and charges if she is still inside once that has run** (`EventInstance.warns_by_radius()`;
##   inbox #788 in minty-lemur). Leaving the radius first is never charged, and once charged
##   walking loses and running wins by the speed clauses above. `tests/test_events_pursuit.gd`
##   walks it.
## - **It stands off inside its own field.** A pursuer holding a stand-off outside `outer_radius`
##   emits nothing at her for the whole of the phase that is supposed to *be* the warning: no meter,
##   no `!` over her head, and a telemetry entry that cannot say what raised the mark. This one was
##   found by walking a rig rather than by reading it.
## - **It notices her from outside its own stand-off**, or the notice is spent somewhere it was
##   never going to move from and the telegraph is a formality. (`EventDef.notice` only.)
## - **It cannot notice her from outside its own field.** What she is owed before a lethal thing
##   starts making decisions about her is the chance to have felt it: the meter is the only thing
##   that says a stranger in an alley is worth crossing the road for, and it says nothing at all
##   past `outer_radius`. (`EventDef.notice` only.)
##
## **Two clauses that used to be here are gone, and their absence is the design.** The chase used to
## end at a *distance*, so the contract needed "walking cannot reach it inside the chase" and
## "running can" — two inequalities in the same three numbers, pulling opposite ways, which is why
## widening a stand-off silently ate an escape and a robber's trigger once had an eleven-pixel window
## to live in. `PURSUIT_SHAKEN_OFF` ends it at a *rate* instead, and the first two clauses above then
## make both facts true by construction: nothing slower than the pursuer can open the gap at all, and
## nothing faster can fail to.
##
## **What this contract still cannot see**, and it is why the rig exists: every clause is about the
## pursuer, and none is about *her*. She is usually walking into the thing when it lunges, and
## turning round costs ground before the run gains any — so a row can satisfy every line below and
## still leave a two-tenths-of-a-second window. See `PursuitSpec.standoff()`. The rig in
## `tests/test_events.gd` that has to accelerate is what checks the half this cannot.
func validate_pursuit(id: String, speed: float, chase_time: float, inner: float,
		telegraph: float, notice_within := 0.0, outer := 0.0, standoff_from := 0.0,
		arrives_chasing := false, sets_off_beside_her := false) -> bool:
	if speed < WALK_SPEED + PURSUIT_MIN_MARGIN:
		push_error("Unfair pursuit '%s': %.0fpx/s is not enough faster than a walk (%.0f)"
				% [id, speed, WALK_SPEED])
		return false
	if speed > RUN_SPEED - PURSUIT_MIN_MARGIN:
		push_error("Unfair pursuit '%s': %.0fpx/s cannot be outrun (%.0f)"
				% [id, speed, RUN_SPEED])
		return false
	if chase_time <= 0.0 or chase_time > PURSUIT_TIME * 2.0:
		push_error("Unfair pursuit '%s': a %.1fs chase is not something a run can end"
				% [id, chase_time])
		return false
	# And the gap a run opens over the whole chase has to actually clear the lethal radius, or
	# running is correct and still not enough.
	var opened := (RUN_SPEED - speed) * chase_time
	if opened < inner:
		push_error("Unfair pursuit '%s': running opens %.0fpx over %.1fs, less than the %.0fpx "
				% [id, opened, chase_time, inner] + "that ends the day")
		return false
	# A pursuer that sets off beside her is owed the badge's heads-up, not an approach's.
	var least_notice := OFFSCREEN_WARNING_MIN if sets_off_beside_her else PURSUIT_MIN_NOTICE
	if not arrives_chasing and telegraph < least_notice:
		push_error("Unfair pursuit '%s': %.1fs of notice is not enough (%.1fs)"
				% [id, telegraph, least_notice])
		return false
	# Being shaken off has to be reachable inside the chase at all, or the rate rule is decorative
	# and the clock is back to pricing the answer.
	if chase_time <= PURSUIT_SHAKEN_OFF:
		push_error("Unfair pursuit '%s': a %.1fs chase is shorter than the %.1fs of being outrun "
				% [id, chase_time, PURSUIT_SHAKEN_OFF] + "that ends it, so nothing she does matters")
		return false
	# A pursuer that holds its stand-off outside its own forward reach emits nothing at her for the
	# whole of the phase that is supposed to be the warning — no meter, no `!` over her head, and a
	# telemetry entry that cannot say what raised the mark. Stated over `outer · Field.scale(e)`
	# rather than the catalogued `outer` alone, since a pursuer's own approach is the one direction
	# `Field.scale` was built for — the check can only get easier to satisfy as the field grows
	# forward, never harder.
	var forward_reach := outer * Field.scale(Field.eccentricity(speed))
	# `standoff_from` is `EventDef.standoff_reach()`: the lunge is measured from the catch unless a row
	# keeps it somewhere else, and 0 here means the catch.
	var standoff := PursuitSpec.standoff(speed, standoff_from if standoff_from > 0.0 else inner)
	if standoff > forward_reach and outer > 0.0:
		push_error("Unfair pursuit '%s': it stands off at %.0fpx and reaches %.0fpx, so its whole "
				% [id, standoff, forward_reach] + "notice is spent outside its own field")
		return false
	if notice_within <= 0.0:
		return true
	if notice_within <= standoff:
		push_error("Unfair pursuit '%s': it notices her at %.0fpx and stands off at %.0fpx, so its "
				% [id, notice_within, standoff] + "whole notice is spent standing still")
		return false
	if notice_within > forward_reach:
		push_error("Unfair pursuit '%s': it notices her at %.0fpx and reaches %.0fpx, so it decides "
				% [id, notice_within, forward_reach] + "about her before she can feel it at all")
		return false
	return true

## The carriageway, in px — the width the player has to clear when a horn goes.
func carriageway_width() -> float:
	return (STREET_WIDTH - SIDEWALK_WIDTH * 2) * float(TILE_SIZE)

## How long a car takes to get from one junction to the next at a middling cruise. The unit the
## whole signal cycle is built out of; see `SIGNAL_PROGRESSION_BLOCKS`.
func signal_travel_seconds() -> float:
	return (BLOCK_SIZE + STREET_WIDTH) * float(TILE_SIZE) \
			/ ((CAR_SPEED.x + CAR_SPEED.y) * 0.5)

## One full cycle of a signalled junction, both arms and both ambers.
func signal_cycle_seconds() -> float:
	return 2.0 * SIGNAL_PROGRESSION_BLOCKS * signal_travel_seconds()

## What is left of the cycle for the main road, which is most of it — the spine carries five times
## an ordinary street's traffic, so an even split starves it and backs the queue through the
## junction behind.
func signal_main_green_seconds() -> float:
	return signal_cycle_seconds() - SIGNAL_SIDE_GREEN_SECONDS - SIGNAL_AMBER_SECONDS * 2.0

## Shortest horn a lethal car may fairly give. What `tests/test_tuning_fairness.gd` holds `CAR_HORN_TIME` to, and
## what the lethal vehicles' tests hold their warning to.
func required_horn_time() -> float:
	return carriageway_width() * TELEGRAPH_HARD_FAIL_MARGIN / WALK_SPEED

## Shortest reach the crowd's horn watch may fairly have: enough for the fastest car to sound
## the whole of `CAR_HORN_TIME` before it arrives. What `tests/test_tuning_fairness.gd` holds `Crowd.CAR_HORN_SIGHT` to.
func required_horn_sight() -> float:
	return CAR_SPEED.y * CAR_HORN_TIME

## People on the streets in a given act.
func crowd_pedestrians(act: int) -> int:
	return CROWD_PEDESTRIANS_PER_ACT[clampi(act - 1, 0, CROWD_PEDESTRIANS_PER_ACT.size() - 1)]

## Cars on the roads in a given act.
func crowd_cars(act: int) -> int:
	return CROWD_CARS_PER_ACT[clampi(act - 1, 0, CROWD_CARS_PER_ACT.size() - 1)]

# -------------------------------------------------------------------- acts ---

## Day index (1-based, inclusive) at which each act begins.
const ACT_START_DAYS := [1, 4, 8, 12]

## The longest act, in days. What the calm-area floor is stated over.
func longest_act_days() -> int:
	var longest := 0
	for i in ACT_START_DAYS.size():
		var ends: int = ACT_START_DAYS[i + 1] if i + 1 < ACT_START_DAYS.size() \
				else RUN_LENGTH_DAYS + 1
		longest = maxi(longest, ends - ACT_START_DAYS[i])
	return longest

## How many calm areas a city has to have: one per day of the longest act, plus one in reserve.
## See `CityGenerator.MIN_CALM_BLOCKS`, which this is asserted against on boot.
func calm_areas_needed() -> int:
	return longest_act_days() + 1

## Returns the 1-based act number for a given 1-based day.
func act_for_day(day: int) -> int:
	var act := 1
	for i in ACT_START_DAYS.size():
		if day >= ACT_START_DAYS[i]:
			act = i + 1
	return act

## Length of a given day in seconds: an ordinary day (1 to 5) or, once curfew is announced
## (day 6 on), the shorter curfew day.
func day_length(day: int) -> float:
	if day >= 6:
		return CURFEW_DAY_LENGTH_SECONDS
	return DAY_LENGTH_SECONDS

# ------------------------------------------------------------ degradation ---

## The first day the city visibly declines. Day 5 rather than day 4: `ACT_START_DAYS[1]` already
## turns the act over on day 4, and a street that cracks on the same morning the block purposes
## and the crowd both shift reads as one more thing changing at once rather than a decline that
## has been happening. One day later, the ground catches up with what the act already told her.
const DEGRADATION_FIRST_DAY := 5

## The one density every visible sign of decline reads — cracked ground, litter, sacks, shuttered
## fronts — so the city degrades as one thing rather than as several unrelated rolls. Zero before
## `DEGRADATION_FIRST_DAY`, rising the way `EventScheduler.budget_for()` rises, to 1.0 on the run's
## last day. A per-block factor (a `BURNT_OUT` block further gone than a `RESIDENTIAL` one) can
## multiply this later; nothing below reads anything but this one number today.
func degradation_for(day: int) -> float:
	if day < DEGRADATION_FIRST_DAY:
		return 0.0
	# +1 on both ends of the fraction, or `DEGRADATION_FIRST_DAY` itself would answer zero — the
	# day nothing has moved past yet — and the city would first visibly decline on the day after
	# its own name.
	return clampf(float(day - DEGRADATION_FIRST_DAY + 1)
			/ float(RUN_LENGTH_DAYS - DEGRADATION_FIRST_DAY + 1), 0.0, 1.0)

# --------------------------------------------------------------- validation ---

## The fairness contract from docs/EVENTS.md: a player who starts walking away the instant
## an event becomes visible must clear its outer radius before it reaches full intensity.
##
## `warning` is the seconds from that instant to the earliest it can reach her —
## `EventDef.warning_time()`, which for a row in the world while it telegraphs is its telegraph.
## Held against `required_telegraph_time()`. A row warned of before it exists is checked by
## `validate_warning()` instead.
##
## Returns true if the geometry is fair; pushes an error and returns false if it is not.
func validate_event(id: String, warning: float, inner_radius: float,
		outer_radius: float, hard_fail: bool, speed: float = 0.0) -> bool:
	var required := required_telegraph_time(inner_radius, outer_radius, hard_fail, speed)
	if warning + 0.001 < required:
		push_error("Unfair event '%s': warned %.2fs before it can reach her < required %.2fs "
				% [id, warning, required]
				+ "(inner %.0f, outer %.0f, hard_fail %s)"
				% [inner_radius, outer_radius, hard_fail])
		return false
	return true

## The same contract for a row warned of before it exists, whose minimum is not its geometry's:
## `warning` (`EventDef.warning_time()`, from its badge to its reach) against `minimum`
## (`EventDef.minimum_telegraph()`: `OFFSCREEN_WARNING_MIN`). Pushes an error and returns false if it
## is short.
func validate_warning(id: String, warning: float, minimum: float) -> bool:
	if warning + 0.001 < minimum:
		push_error("Unfair event '%s': warned %.2fs before it can reach her < required %.2fs"
				% [id, warning, minimum])
		return false
	return true

## Shortest telegraph an event with this geometry may have and still be fair.
## Kept separate from validate_event() so tests can check the contract without tripping
## the error it raises.
##
## A stationary event only has to be walked out of, so the escape distance is the falloff
## band. An event travelling FASTER than the player sweeps its whole outer radius across
## the street instead — you cannot outwalk it, you can only get off its line — so the
## escape distance is the full radius. An event slower than walking pace (a dog walker)
## can simply be walked away from, so it uses the stationary rule.
##
## **Both distances are stated over the row's own forward reach, `outer_radius · Field.scale(e)`,
## not the catalogued `outer_radius` alone** — a moving field now reaches further ahead of itself
## than it is wide (see `Field.scale()`), and the escape she is owed is the ground she actually has
## to clear, not the number the row was authored with. The band case scales the same way:
## `(outer_radius − inner_radius) · Field.scale(e)` is the band's own width stretched forward, since
## the near edge of an approaching field arrives sooner too. `e` is zero for a stationary row, where
## `Field.scale(0)` is 1.0 and both escapes are exactly what they always were.
func required_telegraph_time(inner_radius: float, outer_radius: float,
		hard_fail: bool, speed: float = 0.0) -> float:
	var margin := TELEGRAPH_HARD_FAIL_MARGIN if hard_fail else 1.0
	var scale := Field.scale(Field.eccentricity(speed))
	var escape := outer_radius * scale if speed > WALK_SPEED \
			else (outer_radius - inner_radius) * scale
	return escape * margin / WALK_SPEED

## Eccentricity of a moving emitter's field kernel, from its own speed — the shape the player asked
## for: *"fields should be ellipses, not circles. the eccentricity should be determined by movement
## speed ... an entity moving towards you has more of an effect than if it moves away or
## orthogonal. the entity itself lives in one of the focus points."* Zero at a standstill, which is
## the plain disc every field always was; rises with speed and is capped at
## `FIELD_ECCENTRICITY_MAX` so nothing ever flattens to a line. Fed to
## `Field.eccentricity()` and `Field.scale()`, the polar conic and its own forward reach
## (`GroundShape.eccentric_distance()` draws it).
##
## **The cap is stated over `Field.scale()`, not over `e` on its own.** A moving field's forward
## reach is `R · Field.scale(e)` (see that function), so the cap has to be read as "how far past its
## own resting radius may a field reach" rather than as a shape of the ellipse in isolation — at
## `FIELD_ECCENTRICITY_MAX` 0.5, `Field.scale` is exactly 2.0, so nothing in the game reaches more
## than twice its catalogued `outer_radius` ahead of itself. Nothing in the catalogue is fast enough
## to reach it — the ceiling is a safety bound for a future row, not a number any current one sits
## against.
##
## **`FIELD_ECCENTRICITY_SPEED` is set against placement, not against taste.** A row's forward
## reach growing past what its telegraph already priced is a fairness question; growing far enough
## to touch an unvisited calm area it used to clear is a different one — `EventScheduler` refuses
## that placement outright (`_calm_to_leave_alone`, `_reaches_any`), so a row whose whole path is
## long enough to brush one can lose its only site and simply not happen that day, however fair its
## telegraph is. The value was set by measuring exactly that on the longest-routed scheduled row
## of the day (`docs/DECISIONS.md`, M114); no scheduled row currently drives a route that long —
## the fire engine is summoned to a route ending at the fire rather than planned — so
## `tests/test_events.gd`'s `_test_a_retried_day_is_the_same_day` is the guard for whichever row
## next does, and a value that makes a one-shot lose its only site fails there first.
##
## A car at `CAR_SPEED.x` (130px/s) sits at e = 0.26 (forward reach 1.35R, rear 0.79R); a walker
## (`PEDESTRIAN_SPEED`, 46-74px/s) at 0.09-0.15; the cyclist (165px/s) at 0.33; the cat (240px/s) at
## 0.48, just under the cap.
const FIELD_ECCENTRICITY_MAX := 0.5
const FIELD_ECCENTRICITY_SPEED := 500.0

# ----------------------------------------------------------------- the finale ---
# The fifteenth and sixteenth walks, which are not an ordinary day: escaping the building, then
# escaping the city, one way through each. Most numbers here are stated against something that
# already exists rather than chosen — the catalogue's own rows and the sealing's own placement —
# so what the finale needs of its own is a length, a density and two reaches. The length is the
# one exception: it is chosen on its own rather than reused from the ordinary day, because the
# escape is asked to stay exactly as hard as it always was while the ordinary day grows around it.

## How long one section of the escape runs, on top of a real `DayController`'s own clock — each
## section is its own day with a brief and a restart checkpoint of its own, and the player's
## answer was *"180s per section"*. Stated on its own rather than reused from the ordinary day's
## length: the player asked that *"the escape shouldn't be easy!"* (`docs/playtests/PLAYTEST-121.md`),
## so the escape does not grow when the ordinary day does. Asked alongside the ordinary day's
## length and not yet answered whether it should grow too — open to overturn.
const FINALE_LENGTH_SECONDS := 180.0

## How many calm blocks each chain runs through between the service exit and its edge — *"a single
## path through the city that crosses three parks"*. The chains are built one street-walk at a
## time between consecutive stops, so this is also how many intermediate stops each chain has.
const FINALE_PARKS_PER_CHAIN := 3

## How close her own centre has to come to the last walkable tile of the spine, at either end of
## the map, for the sequence to be over. One tile and a half — comfortably past her own body
## (`PLAYER_BODY_RADIUS`, 14px) so standing anywhere on that tile is out, and under two tiles so
## the tile before it is not. The same reasoning, and the same figure, as the radius the building's
## own doors hold her with.
const FINALE_EXIT_REACH := TILE_SIZE * 1.5

## How long **every** hallway window holds its lit picture when something goes off outside — *"one
## or two frames"* at 60fps, taken as a span in seconds so it does not depend on the frame rate.
## The same length for the near bang and the far ones, and they light and go dark together:
## *(2026-09-19: "all windows always need to flash together. a single window cannot flash by
## itself.")*
const FINALE_WINDOW_FLASH_SECONDS := 0.12

## The wait between two **distant** flashes in the hallway windows, as a bounded distribution
## rather than a period. *(2026-09-19: "the flashing lights in the window are too rare"; and, on
## how often: "do a biased random distribution between 100ms and 5s between flashes where the mean
## is 1.3s and the rest of the curve is smooth.")*
##
## **Light without noise, and that is the whole of why these exist.** A flash was only ever the
## near bang's own cue, one every `EventCatalogue.FINALE_EXPLOSION_INTERVAL` (22s), which is eight over the
## whole clock — and an explosion is loud: shortening that interval would have made the windows
## flash more often and made the building cost more in the same stroke, which the player did not
## ask for. A distant flash is a picture and nothing else: no instance, no field, nothing on the
## meter. So the night outside reads as a city being shelled, while what she is *charged* for is
## still only the bangs close enough to shake the building.
##
## **A scaled Kumaraswamy draw**, because it is the short-biased smooth curve on a closed interval
## whose inverse CDF is one line — no rejection loop, no table, and a draw that cannot fall outside
## the bounds. With `u` uniform in `[0, 1)` from the section's own seeded stream:
##
##     t = MIN + (MAX − MIN) · sqrt(1 − (1 − u)^(1 / B))
##
## The `sqrt` is the first shape parameter fixed at 2, which is what makes the density zero at both
## ends rather than piling up against them; **`FINALE_DISTANT_FLASH_SHAPE_B` is the only thing that
## sets the mean**, solved numerically so that the mean lands on
## `FINALE_DISTANT_FLASH_MEAN_SECONDS` — so moving the mean means solving `B` again, not editing it
## by feel. At `B = 12.343` the curve measures out at a mean of 1.298s, a median of 1.24s, a mode
## near 1.1s and a 95th percentile of 2.37s: mostly quick double-taps with the occasional long
## dark gap, and no step anywhere in it.
##
## **The interval runs start to start**, so a 0.1s draw against a
## `FINALE_WINDOW_FLASH_SECONDS` (0.12s) flash means two of them overlap. That is wanted — it reads
## as a double flash — and the lit state is a single countdown that the second flash simply
## restarts, so an overlap never blinks dark for a frame and never leaves a window lit.
##
## **How often is the only thing that separates a far flash from a near one.** Both light every
## window in the building together (`InteriorScene.flash_windows()`); what a bang adds is the
## charge on the meter.
const FINALE_DISTANT_FLASH_MIN_SECONDS := 0.1
const FINALE_DISTANT_FLASH_MAX_SECONDS := 5.0
const FINALE_DISTANT_FLASH_MEAN_SECONDS := 1.3
const FINALE_DISTANT_FLASH_SHAPE_B := 12.343

## The basement's steam vents, one entry per vent: how often each one blows, in seconds.
##
## *"Have multiple fixed locations with steam that fully block the path and have them turn off an
## on in different intervals so it becomes a timing puzzle."* **The count is the length of this
## list rather than a second constant**, so a vent without a period of its own is not a thing that
## can be written down.
##
## **Three, and no two periods share a factor with each other**, which is the whole of what makes
## the corridor a puzzle instead of a rhythm: 8, 9 and 11 half-seconds are pairwise coprime, so the
## pattern the three of them make together only repeats after their product — 396s, more than twice
## the whole sequence's own clock — and she never walks the same corridor twice. Three rather than
## more because the basement's corridor is about forty tiles end to end and a vent closes it
## outright: a fourth would make the walk a queue of gates rather than a route with waits in it.
##
## **The floor under all three is what one crossing costs, not taste.** *(2026-09-19: "the steam
## frequencies are too slow.")* A vent stands on a one-tile cell and holds her centre
## `EventCatalogue.STEAM_VENT_BODY` + `PLAYER_BODY_RADIUS` (16 + 14 = 30px) out, so clearing it
## means covering 60px — 0.65s at `WALK_SPEED` (92px/s). A vent's corridor is shut for
## `EventCatalogue.FINALE_STEAM_BLOWS_FOR` and open for the rest of its period, so the shortest period leaves
## `4.0 − 2.0 = 2.0s` of open corridor against that 0.65s: a second and a third of margin, which is
## the "at least a second" a gate owes somebody who started walking a moment too late. Anything
## under 3.7s would stop owing it.
const FINALE_STEAM_PERIODS: Array[float] = [4.0, 4.5, 5.5]

## How many slots each open street of the escape's walk has, each filled by one draw from the
## escape's marble bag below (`DaySpec.slots_per_street`, which the city section's spec takes from
## here; `EventScheduler._fill_the_walk_from_the_bag()` draws them). **One keeps the section the
## climax and every walk out of it walkable**, measured by walking the shortest walk
## from the service exit to each exit through the plan's own events, on two sets of 24 seeds
## (measured by `tests/probes/escape_winnable.gd` at f8172b7ccb7f, whose own stand-in walker and
## meter produced `docs/evidence/winnable-escape-2026-10-19/`; the probe walks with the game's own
## walker, `RouteRig`, and its numbers are not comparable with those):
## at one slot a walk to an exit meets about eight dangers, one every eight seconds of walking, and
## a plain walk gets out on 95 of 96 with the baby woken on 4; at two slots it meets about twelve,
## the baby wakes on about one walk in five, and one walk in sixteen to one in nine ends in crying.
## One slot also stands one roadblock a street at most, so a crossing is one band and one guard on
## her side of it to lure *(inbox #771 in minty-lemur: "Luring away one guard (the challenge) is not
## enough to make the obstacle survivable")*, which the notice spacing
## (`EventScheduler._keeps_its_notice_to_itself()`) would hold at any slot count, since no street is
## long enough for two bands' notices.
const FINALE_SLOTS_PER_STREET := 1
## The escape's marble bag, in the player's order of how many *(inbox #785 in minty-lemur:
## "frequency order is trucks > explosions > vans > barriers > empty")*: army trucks, off-screen
## explosions, unmarked vans, roadblocks (the barriers) and empty marbles, where the slot that draws
## one stands nothing. **The two rows that take her have the fewest marbles the order allows**, vans
## 3 and roadblocks 2 over the one empty marble, and the trucks and explosions, which only wake the
## baby, make up the rest: a van's catch and a guard's end the section, and a van's field is most of
## what the probe's walks that cried had landed. With these a walk to an exit meets about three
## trucks, three explosions, one van and one roadblock; the order's smallest bag, 5, 4, 3, 2 and 1,
## meets a van and a roadblock more often and gets out on 44 walks of 48. A fill is 24 marbles and
## a plan has about 31 open streets, so an escape draws one whole fill and about seven marbles of
## the next. About a third of the streets stand nothing all the same, since a danger the placement
## rules refuse is spent unmet.
const FINALE_BAG_TRUCKS := 10
const FINALE_BAG_EXPLOSIONS := 8
const FINALE_BAG_VANS := 3
const FINALE_BAG_ROADBLOCKS := 2
const FINALE_BAG_EMPTY := 1

# --------------------------------------------------------------------- masts ---
# M180, posters she notices, and loudspeakers that are somewhere: a loudspeaker is a mast on a
# street with a field, not a floor under the whole city. See `MastSites`, `EventScheduler.
# _place_masts()` and `EventManager`'s own broadcast clock.

## How many masts a city carries. The orchestrator's own number, open to overturn: enough that one
## is never far from a route without turning every street into one.
const MAST_COUNT := 6

## Masts go up overnight before this day and stand at the same places for the rest of the run —
## `docs/TODO.md`, M180: "Masts go up overnight before day 5". One day ahead of `_loudspeaker()`'s
## old `scripted_day`, which was the day she could first meet one; the mast itself is older than
## that by a night.
const MAST_FIRST_DAY := 5
