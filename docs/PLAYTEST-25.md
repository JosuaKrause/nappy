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

## The cause, found and reproduced

**One line, `src/main.gd:464`, inside `_on_day_finished()`:**

```gdscript
var trail: Array[Vector3] = _observer.trail() if _observer else []
```

The `else []` branch produces an **untyped** `Array`, and assigning that to an `Array[Vector3]`
throws at runtime — `Trying to assign an array of type "Array" to a variable of type
"Array[Vector3]"`. `_observer` is in the tree only while a run is being traced, so on a build with
telemetry off the `else` runs and `_on_day_finished()` **aborts at that line**, six lines before it
would have called `_summary.show_day(...)`.

**And `DayController._end()` has already set the phase to `OVER` by then.** So the day is over and
nothing says so: the clock stops, no summary appears, the tree is never paused, she keeps walking,
and every later ending is swallowed — `_on_baby_state_changed()`, `_on_hard_fail()` and
`DayController._process()` all return immediately unless the day is running. That is the whole of
*"it stays on 100 and I'm completely invincible"*, and it is the same hole the cyclist and the dusk
timeout fall into.

**Why it is mobile-only and not a mobile bug at all.** `Telemetry` disables itself on a web export
(`OS.has_feature("web")` — browser storage is a stranger's disk, and nobody would ever collect or
clear it), so `_observer` is null there and is never null on an ordinary desktop run. Nothing about
touch, rotation or the phone is involved. The two rig runs earlier in this entry die correctly
because they had telemetry on.

**Reproduced twice**: in a real Web export served locally, with the GDScript backtrace read out of
the browser console; and on the desktop with `--no-telemetry`, which puts a desktop build in the
same condition by a different route —

```sh
./tools/shot.sh /tmp/x.png 25 --no-telemetry --seed 2102613802 --day 6 \
    --spawn arterial --meters 0 99 --walk 25s
```

**That second command opens a window on whoever runs it**, which is worth saying because it was
called headless here first and it is not: `shot.sh` renders, so it needs a window even though it
exits on its own. The condition it creates — no `TelemetryObserver` in the tree while the day ends
— is the thing worth keeping, and the place it belongs is a rig in `tests/`, which is headless and
is where the regression test for this goes.

**Why nothing caught it.** It is a runtime type error on a path no test walks: `tests/
test_day_loop.gd` asserts that crying loses the day, and every rig that has ever run the day-ending
path had telemetry on. CI could not have caught it, and neither could a hundred desktop playtests.
It is exactly the silent-type-drop trap the **godot** skill exists for, in the one place the type
was written down and the literal was not.

**And the player drew the rule out of it, which is worth more than the fix:**

> "in general don't tie features directly to an environment -- tie it to a feature flag which might
> be informed by the environment but let's you override"

> "that way you can get telemetry when you need it"

**The gate did not cause the bug; it made the bug unfindable.** `Telemetry` returns early on
`OS.has_feature("web")` and there is no way to say *yes, this run, log it* — so the branch where
`_observer` is absent could not be entered by any test or any desktop session, and nothing about
that looked like a gap. The platform is allowed to pick the **default**; it may not **be** the
decision, because a branch only the deploy target can enter is a branch nobody has ever watched.

`TouchInput.available()` is the shape the project already has right — the platform fact
(`DisplayServer.is_touchscreen_available()`) and the policy built on it are separate, so `--touch`
renders a touch-only screen on a machine with no touchscreen and a rig can photograph it. The rule
is now in the **godot** skill under "Capabilities", so it arrives before the next edit that would
break it, and the gates that currently violate it are queued under M70.

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

**And the player named where the 170 came from**, which is the thing that makes it a design fault
rather than a badly chosen number:

> "that number was so big because it was a point source before"

A field computed from a single point has to be wide enough to stand in for a thing that is not a
point. The radius was doing the body's job. Once the field is the body's own shape — finding 10 —
that job goes away and the number should come **down**, not be carried across.

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

and then the general rule the two sentences above are an instance of:

> "basically for every base shape the minkowsky sum of a circle and the shape should be the
> influence field"

**That is the whole thing in one line, and it is a better statement than the capsule.** The
influence field of a body is the set of points within a given distance *of the body* — so the
falloff is a function of **distance to the body**, not distance to a point, and every shape falls
out of the same rule rather than needing its own case:

| Base shape | Field |
|---|---|
| a point | a circle — every field in the game today, unchanged |
| a line segment | a capsule — the "rounded rectangle" |
| a rectangle | that rectangle with rounded corners |
| any polygon | the polygon offset outward, corners rounded |

The reasoning is physical rather than aesthetic — **every field in this game is computed from a
single point, and half the things emitting one are not points.**

And then the other operand, which is what makes this one rule for the whole game rather than one
rule for barriers:

> "that's for static objects. for moving objects one side of the sum is an oval"

**So the field is always `body ⊕ kernel`, and only the kernel changes**: a **disc** when the thing
is standing still, an **ellipse** when it is moving, with the eccentricity coming from speed — which
is M61's original instruction, *"fields should be ellipses, not circles. the excentricity should be
determined by movement speed"*, arriving as the second half of the same sum rather than as a
separate system.

**That answers a question this file was about to leave open.** Whether a capsule could also be
eccentric had no answer; now it does, and it is composition rather than a special case. A stationary
café is its frontage ⊕ a disc. A van driving at her is its body ⊕ an ellipse.

**And the player scoped the implementation in the same breath:**

> "but most moving objects are small enough to be a point"

**Which means nobody has to compute a general Minkowski sum of two convex shapes.** In practice the
two cases are disjoint and each collapses to something ordinary: a **static body ⊕ a disc** is a
capsule or a rounded rectangle, and a **moving point ⊕ an ellipse** is just the ellipse. The cat,
the loose dog, the cyclist, the flock and the pursuers are all points. The only rows that would need
the general case are things that are both large and moving — the vehicles — and whether any of them
is worth the general form is a question to settle then, not an argument for building it now.

**One detail worth carrying over from M61 rather than rediscovering.** Its instruction says *"the
entity itself lives in one of the focus points"*, not at the centre. That matters, because a kernel
ellipse **centred** on the body is symmetric front to back and would deliver none of M61's own
rationale — *"an entity moving towards you has more of an effect than if it moves away or
orthogonal"*. The offset is what buys the asymmetry; the eccentricity alone does not. A rectangle along the
barrier's own length with circular caps at its ends — which is what a body that is drawn as a spread
along the pavement actually occupies. Today every field in the game is a disc centred on the
instance, so a café frontage prices someone standing across the street exactly as it prices someone
standing at the tables, and reaches a long way perpendicular to itself while under-reaching along
its own length.

**The bodies, so nobody sizes this off a guess.** A spread is drawn `obstructs_radius` either side
of its centre (`EventInstance._draw_spread` and `_draw_cafe` both take `half = max(11, obstructs_
radius)`), so the frontages are **48px** for `cafe_tables` (24px each way, against a 170px field),
**56px** for `market_stall` (28, against 185), **64px** for `construction` (`SIDEWALK_SPREAD_MAX`,
against 200), **44px** for `delivery_van` (`VEHICLE_BODY` 22, against 150) and **124px** for
`barricade` (62, against 120). Only the barricade is long against its own reach; the rest are short
bodies wearing wide circles.

**This is finding 9 seen from the other side.** Tightening `cafe_tables`' 170px circle makes it stop
charging people who are nowhere near it, and a capsule is the shape that would have made the circle
unnecessary — the reason the radius has to be so large is that it is the wrong shape for the body it
belongs to. Worth knowing when the radius is picked, because the radius is the stopgap and this is
the fix.

**It overturns a sentence already written down, and the player is the one overturning it.** M61's
entry states that *"a stationary thing keeps its circle, by construction: eccentricity from speed
means zero speed is a disc"*, and concludes that the change is only about the mobile rows. That is
no longer true: a stationary barrier gets its shape from its **body**, and zero speed only collapses
the **kernel**. The rule survives the correction — a still thing does get a disc for a kernel — but
the conclusion drawn from it does not, and the blast radius is the whole catalogue rather than the
movers.

**The blast radius is M61's, not a small one.** Everything that reasons about "how far" — the
telegraph contract stated over the gap between inner and outer radii, the placement spacing, the
clearance a lethal row keeps, the streaming radius, the denial radius a park spoiler is measured by
— asks a question a circle answers with one number and a capsule answers with two.

**And there is a trap in it that has to be named before anybody writes the code.** Under the
Minkowski rule, `inner_radius` and `outer_radius` stop meaning *distance from the centre* and start
meaning *distance from the body*. For a point body those are the same number and nothing moves. For
a spread they are not: read naively, a 170px outer radius becomes 170px **beyond** the body, which
is a **larger** field than today's, not a smaller one — the exact opposite of what findings 8 and 9
are asking for.

**The player's own reading points the other way and is the one to build to**: *"that number was so
big because it was a point source before"*. The radius was standing in for a body the maths could
not see, so once the shape carries the body the radius should come down by roughly what the body was
worth — for `cafe_tables`, on the order of the 24px half-frontage, and much more than that if the
reach was never justified at 170px in the first place. Either way the numbers get **derived**, not
carried across, and the change is not a refactor even where it looks like one.

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
