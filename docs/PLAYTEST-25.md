# Playtest 25 — 2026-09-05

A phone session on the mobile build, given as notes across one conversation rather than as a
written-up run — *"I did a test run with the latest mobile updates"*. **Ten findings.** One is a
day that will not end, one is a build that will not start, one is the two control schemes coming
out of their experiment, and seven are about what the city costs to walk through.

**Only the boot failure is diagnosed.** It was reproduced and fixed in the session it was reported
in. Everything else below is the player's own sentence plus, where one was looked for, a statement
of what a reader would have to go and check — and where a cause is offered it is marked as a
hypothesis rather than a finding.

---

## 1. Excitement reaching 100 does not end the day, on the phone only

> "if excitement reaches 100 the game doesn't end! that's a major bug"

And, after the desktop build was checked in the same session:

> "dying works on the local version. it's a mobile only bug"

Asked what actually happened on screen, the player was specific twice. First, that nothing happened
at all and she kept walking — not a screen that flashed past, not a freeze. Then, ruling out the
first thing that was looked at:

> "no I don't misread the number. it stays on 100 and I'm completely invincible"

So the meter **sits** at 100 and the day carries on being unloseable. That is a stuck state rather
than a threshold missed by a fraction, and "invincible" is wider than crying — it says nothing at
all ends the day.

**The day loop is not what is broken, and that was checked rather than assumed.** Two rig runs on
the same city and day, seed 2102613802 day 6, walking blindly south for 25 seconds: the landscape
desktop run loses at 17.6s with `lost_crying`, and the same walk at 720x1280 with `--touch` — which
is a portrait touch device, so the rotated presentation and the touch control layer are both live —
loses at 22.0s with `lost_crying`. So `Baby._update_state()` setting `CRYING` at
`Tuning.METER_MAX` (100), `DayController` turning that into `LOST_CRYING`, and the summary appearing
all work with the touch shape switched on.

**One separate defect was found on the way and it is not this.** `MeterBar._draw()` prints its value
with `"%3.0f" % value`, which rounds to nearest, so **99.5 and everything above it prints `100`** —
verified against the engine rather than inferred. That means a bar can read a flat `100` on a live
day, which is a real thing to fix and was the first explanation reached for. **The player ruled it
out from the chair**, and the "invincible" half rules it out on its own: a meter a fraction under
100 is a meter that goes back down, not one that sits.

**What is left is a stuck state, and it has not been found.** The shape to look for is something
that makes `Baby._physics_process()` stop advancing while the day and the walking carry on —
`Baby` returns from it immediately once `state` is `CRYING`, which pins both meters exactly where
they were — or something that leaves the day unable to end at all. Note that `Baby.reset()` at the
start of every day sets the state back to `AWAKE`, and that the title screen pauses the player
subtree, so the obvious version of "it went `CRYING` while no day was running" is already closed off.

**What could not be checked here:** the Web export itself. The export templates for this Godot build
are not installed on this machine, so nothing in this session ran the bundle a phone actually loads
— the `--touch` runs above are the desktop binary wearing the touch shape, and they lose the day
correctly. **The deployed build the player was on is `v0.2.0`**, the M68 merge, served at
`https://nappy.josuakrause.com/`. Reproducing on that page is the next step and it is the one that
will actually say what this is.

## 2. The local build does not start — fixed

> "the local version doesn't start at all right now"

With `tools/run.sh` printing `Parse Error: Identifier "ControlsMode" not declared in the current
scope` and the same for `TapControls`, from `hud.gd`, `title_screen.gd` and `main.gd`.

**Diagnosed and fixed in the session: a stale `.godot` cache, not a code defect.** `src/ui/
controls_mode.gd` and `src/ui/tap_controls.gd` both declare their `class_name` correctly and both
are committed. What was missing was the entry in `.godot/global_script_class_cache.cfg` that tells
Godot those global classes exist — the checkout's cache predated the merge that added the two files,
and **`tools/run.sh` launches the editor binary straight at the project without an import pass**, so
nothing ever refreshed it. `tools/check.sh` imports first, which is why the boot check was green on
the same tree that would not run. Running `./tools/check.sh` once restored it.

The player's question about it is the finding that outlives the fix:

> "how could so many bugs sneak in just now?"

This one did not sneak in: **it was never in the code, and no gate could have caught it**, because
CI imports from a clean checkout every time and so does `check.sh`. It is only reachable from a
working copy whose cache is older than a new `class_name`, which is every `git pull` that adds one.

## 3. Both control modes are keepers, and the title screen should ask

> "I like both control modes equally let the player choose on the title screen (instead of tap the
> screen to start have two buttons to choose from)"

The verdict on M68's experiment, and it is not the one the experiment was shaped for: tap-to-walk
was built as a switchable alternative to be *chosen between*, resolved from the command line or a
URL flag, on the reading that one of the two would win. Neither did.

So the design the player gave with the verdict: **the title screen stops being "tap to start" and
becomes two buttons**, and picking one is what starts the run. That makes `ControlsMode` a player
choice at the moment of starting rather than a build-time flag — the flags stay, as the way to skip
the question.

## 4. The chatting lady can be walked straight up to

> "the chatting lady has a way too small capture radius in should be much bigger. right now I can
> basically walk up to her without consequence"

`chatting_mother`'s `detain_radius` is **26px**, and it was chosen to be small on purpose: the
catalogue's own note says it sits under the **32px** spacing between the two pavement lanes "so the
far lane of a two-tile pavement can never trigger it". The played consequence of that reasoning is
this finding — 26px from her centre is close enough to brush past, so the one row in the game that
takes the controls away is one the player can ignore.

**This overturns the far-lane rule**, and it is the player's to overturn: the whole point of the row
is that she catches you. What a bigger radius costs is that walking the far lane of the same
pavement no longer avoids her, which is the thing that reasoning was protecting — worth stating in
the change rather than discovering later.

## 5. Alleys are blocked off far too often

> "the probability of blocking off alleys should be way lower"

and, on which part of it:

> "at least for full blockages -- robbers can be frequent"

Two different things wearing the same word, and the player separated them. **The physical blockage**
is `SealPlanner._seal_alley_mouths()`, which walls **both** mouths of **every** through-alley whose
two ends are both off the day's route tree — no roll, no fraction, every qualifying alley, every
day. That is the "full blockage" and it is the one to make rare. **The robber** is `alley_robbery`,
an event rather than a barrier, and the player is explicit that its frequency is fine.

## 6. The dashing cat and the loose dog do not land

> "dashing cat and dog (not pursuing) are basically useless right now -- they need a bigger impact"

Named precisely: the two rows that *come at her and do not chase* — `cat_dash` (intensity 15 over
a 30/120px field, 1.8s, crossing the road at 240px/s) and `loose_dog` (intensity 24 over 30/140px,
running down her pavement at 132px/s, deliberately not lethal). Both are things that happen *to*
her, and the complaint is that meeting one costs nothing worth answering.

Not named, and worth keeping out of it: `charging_dog`, which pursues and is act IV's, is not what
this is about — the player excluded it with *"(not pursuing)"*.

## 7. The cyclist does not connect either

> "biker currently is also basically inconsequential. when hit it should be dayending"

**What was asked for is already the design**, so this is a defect report rather than a change of
mind: `cyclist` carries `hard_fail = true`, and `DayController` already has its sentence written —
*"The bell, and then the bike. She is screaming."* Being hit by it is supposed to end the day.

**The number to look at is 26px**, and it is the same number as finding 4. `cyclist`'s lethal band
is its `inner_radius` of **26px**, and the chatting mother's `detain_radius` — the other thing in
this report that can be walked straight past — is **26px** as well. Two rows whose whole content is
*it catches you*, both set to a radius the player reports never connecting. Whatever is decided for
one is worth deciding for the other in the same pass.

**And it is not finding 1 wearing a disguise.** That was the first worry — `DayController
._on_hard_fail()` returns immediately unless the day is running, exactly as the crying handler
does, so a stuck day loop would swallow the cyclist and the crying alike. The player closed it:

> "cyclist radius should be bigger, then. that observation was from local"

The local desktop build is the one where dying demonstrably works, so a cyclist that goes past
without ending the day there is a **radius that never fires**, not a day that cannot end. The two
26px rows are one finding after all.

## 8. There is no way to calm down

> "currently there is no real way of calming down after an event. even walking on a seemingly empty
> sidewalk segment does not lower excitement and sometimes even increases it more -- I don't think
> this is a necessarily straightforward fix."

And the part that is about legibility rather than arithmetic:

> "while walking the excitement kept going up for semingly no reason"

**"For seemingly no reason" is the whole finding, not a flourish.** The things doing it are café
tables, market stalls and delivery vans — scenery a player reads as *the street*, not as a source —
and each reaches 150–200px, so the ones actually charging her are mostly off screen or behind her.
There is nothing to point at and nothing to walk away from, which means the meter is rising against
a decision the player cannot see and therefore cannot make. That is the opposite of what every
danger cue in this game exists to do.

**The player supplied the run**, and it is copied into
`docs/evidence/run-181812-seed3038142309-v0.2.0-6-gedeed04-dirty/` — a played desktop run on
`v0.2.0-6-gedeed04`, seed 3038142309, with its dawn and dusk maps and the two loss screenshots.

**What the log shows, and it is not subtle.** Day 1 plans **147 `cafe_tables`, 124 `market_stall`
and 84 `delivery_van`** — 355 static bodies, which is M64's sealing placing a barrier on every
street off the day's route. Day 2 adds 98 `construction`. Every one of those rows carries an ambient
field 150–200px wide, and **fields sum**: the log's `in` figure is the total, while the `near` line
names only the closest thing.

The stretch that says it, from day 1, with her stood in a park doubling back trying to settle:

```
  32.2  near  playground at (78,36),  82px, exc 56, in  9.5/s (crowd 0.0, events  9.5), sleep 30
  37.9  near  market_stall at (85,38),184px, exc 54, in 14.2/s (crowd 3.6, events 10.6), sleep 30
  43.2  near  playground at (78,36), 150px, exc 69, in  2.1/s (crowd 2.2, events  0.0), sleep 30
```

The nearest event is a **market stall 184px away — at the very edge of its own 185px radius** — and
events are still delivering 10.6 a second, because several more are inside their radii too and
nobody is nearest. Excitement goes **35 → 69 in fifteen seconds in a calm park**. Walking decay is
a few points a second against that, so there is no ground left that subtracts.

**So this is this finding's mechanism, and finding 9 below is most of its fix.** Take the field off the five
barrier rows and the 355 bodies stop being emitters; what is left emitting is the handful of things
that are meant to be loud. That is the reason the two are one milestone and not two.

**The dusk map the player sent is day 3 of that same run**, and it is the clearest single picture
of the problem: *"this attempt was such a case the excitement kept going up and in the end a cat
killed me"*. Her trail is a stub — she is barely off the doorstep — and the log line for it reads
`lost_crying after 26.7s ... exc 100, in 40.6/s (crowd 0.0, events 40.6) | near: cat_dash 39px`.

And the player's own reading of it, unprompted:

> "the cat was what ultimately did it but without it I would have died a few seconds later"

**So this is a finding about finding 6 as much as this one, and it points the other way.** `cat_dash`
is not a hard fail and carries only intensity 15 — it cannot kill anybody who has headroom. It
killed her because the meter never came back down from everything before it, so the cat was the last
few points of a loss that was already arriving. **The cat is not weak; the baseline is high.** Raising the cat's impact
while the baseline is still pinned would make it an instant loss on contact, which is not what was
asked for. Fix the calm-down problem first, then judge whether the cat still needs anything.

**What it does not explain, and the player flagged it as not straightforward:** whether the falloff
curve and the 150–200px radii are right *at all* once the count drops. A row that reaches 185px was
authored when a street held a few of them. The player's own framing — that a seemingly empty
pavement should give the meter back — is a statement about what calm ground has to be worth, and it
is worth measuring against the same log after the barrier fields go.

## 9. Static blockages should not raise excitement — unless the thing is exciting, and then only up close

> "static blockages in general shouldn't increase excitement"

and, immediately, the exception that makes it a rule rather than a sweep:

> "except for things like ice cream trucks which have inherent excitement"

So the line is **not** *static means no field*. It is: a thing whose whole job is to stand in the
way costs **route and nothing else**, and a thing a baby would actually notice keeps its field
whether or not it also blocks. Being in the way is the entire price of a barrier; being interesting
is priced separately and on its own merits.

**And then the player drew the line again, in a place the first sentence had put on the wrong
side:**

> "restaurants should only increase your excitement when you're actually close"

> "but they should nonetheless"

**That is a third category and it is where most of this finding actually lives.** A café is not
scenery and not a loudspeaker — it is a real source with an unreasonable **reach**. `cafe_tables`
carries 12.0 out to **170px**, which is most of the way across a street, so it charges people who
are nowhere near it and is invisible to them while it does. The fix is a short radius, not silence.

Asked whether a market stall is the same, the player said yes. So the rows sort three ways:

- **Silent — pure obstruction**, their whole price is being in the way: `construction`,
  `delivery_van`, `barricade`.
- **A field, but close only** — real sources whose reach was authored for a street that held a few
  of them, not a hundred: `cafe_tables` (12.0 / 170px) and `market_stall` (14.0 / 185px).
- **A field at range, deliberately**: `ice_cream_van` (13.0 / 240px — the chime carrying three
  streets is the row) and `leaf_blower` (20.0 / 200px — loud is the whole content). **Whether these
  two also want tightening is left to measurement** *(2026-09-05, the player's own call: judge it
  after the rest lands)*, and either answer has to be stated rather than defaulted to.

**Reach, not count, is the thread running through this whole report.** It is what makes finding 8's
*"for semingly no reason"* true: a source you cannot see is one you cannot walk away from.

## 10. A long barrier needs a long field, not a big circle

> "one note is -- horizontal barriers need a combination of rectangular and circular fields"

> "a rounded rectangle if you will"

and the rationale, which is the part that took the thought:

> "since they are not point sources"

**A capsule: the distance to a line segment rather than to a point.** The reasoning is physical
rather than aesthetic, and it generalises past the rows named — **every field in this game is
computed from a single point, and half the things emitting one are not points.** A rectangle along the
barrier's own length with circular caps at its ends — which is what a body that is drawn as a spread
along the pavement actually occupies. Today every field in the game is a disc centred on the
instance, so a six-tile café frontage prices someone standing across the street exactly as it prices
someone standing at the tables, and reaches a long way perpendicular to itself while under-reaching
along its own length.

**This is finding 9 seen from the other side.** Tightening `cafe_tables`' 170px circle makes it stop
charging people who are nowhere near it, and a capsule is the shape that would have made the circle
unnecessary — the reason the radius has to be so large is that it is the wrong shape for the body it
belongs to. Worth knowing when the radius is picked, because the radius is the stopgap and this is
the fix.

**It overturns a sentence already written down, and the player is the one overturning it.** M61's
entry — fields as ellipses whose eccentricity comes from movement speed — states that *"a stationary
thing keeps its circle, by construction: eccentricity from speed means zero speed is a disc"*, and
concludes from that that the change is only about the mobile rows. That is no longer true: a
stationary barrier gets a shape from its **body**, independently of any shape it gets from its
**motion**. Whether the two compose — a capsule that is also eccentric — is an open question, and
the rows it would apply to are stationary, so nothing needs it answered yet.

**The blast radius is M61's, not a small one.** Everything that reasons about "how far" — the
telegraph contract stated over the gap between inner and outer radii, the placement spacing, the
clearance a lethal row keeps, the streaming radius, the denial radius a park spoiler is measured by
— asks a question a circle answers with one number and a capsule answers with two.

What each row carries today — every one of them stationary, every one of them obstructing:

| Row | Field now | Reads as |
|---|---|---|
| `construction` | 11.0 over 46/200px | a hoarding, and the widest body in act I — **silent** |
| `delivery_van` | 8.0 over 40/150px | a van at the kerb — **silent** |
| `barricade` | 6.0 over 40/120px | the act IV hard seal, the one row wide enough to span a street — **silent** |
| `market_stall` | 14.0 over 44/185px, pulsing every 8s | a trestle across the pavement — **field, close only** |
| `cafe_tables` | 12.0 over 40/170px, pulsing every 6s | chairs and tables to squeeze past — **field, close only** |
| `ice_cream_van` | 13.0 over 48/240px, pulsing every 11s | the chime is the point — **field at range; reach open to measurement** |
| `leaf_blower` | 20.0 over 40/200px, pulsing every 4s | a man and a machine; loud is the entire row — **field at range; reach open to measurement** |

`leaf_blower` is the clearest case of what the exception is protecting: nothing about it is worth
meeting if its field goes.

It interacts directly with findings 5 and 8, and with M64's sealing, which places several hundred
barrier bodies a day, and it is worth reading the three together: the seals stop being a meter tax, so the
only thing a wall does is make the player go round.
