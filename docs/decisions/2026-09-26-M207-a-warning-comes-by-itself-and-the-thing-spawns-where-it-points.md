## M207 — A warning comes by itself, and the thing spawns where it points · built 2026-09-26

*([PLAYTEST-140](../playtests/PLAYTEST-140.md): "12.9s is a *long* warning to the point where nothing
really happens anymore. I feel the same with the biker. it gets warned too early so most of the
time you're already gone when anything happens." · its first build turned down in
[PLAYTEST-145](../playtests/PLAYTEST-145.md): "I don't like that the warning is tied to the size of
the field or the speed.")*

**What was tried.** A `hard_fail` row that travels toward her is sited so its telegraph is over
before it arrives, since `EventInstance.is_lethal_at()` refuses the whole telegraph, and the
shortest telegraph the fairness contract allows (`Tuning.required_telegraph_time()`) is the time
to walk across its field's forward reach, doubled. So the cyclist's warning was shortened by
shrinking his field: `outer_radius` 90px to 60px and `telegraph_time` 2.97s to 2.1s, a floor of
1.95s. Measured from the screen-edge badge, walking into him, she was warned 2.03s ahead. The
smaller field made him cheaper to pass, 16.0 to 12.1 over a full pass, which the player refused
([PLAYTEST-144](../playtests/PLAYTEST-144.md), statement 16: the cyclist must not become cheaper), so
his `intensity` went from 18.0 to 21.5 to restore the 16.0. That reshaped his cost with distance:
dearer close in (0 to 25px awake, 12.0 to 15.5; a close pass while she sleeps went from about free
to 0.7 to 1.2) and free past about 60px, where it had cost 2.2 at 75px.

**Why it was turned down.** The player does not want a warning tied to the size of a thing's field
or to its speed. The warning is to go up by itself, and the thing is to spawn where it points when
its time comes, the waiting place following her on the thing's own ground, which is what is built.

**What is built instead** ([PLAYTEST-145](../playtests/PLAYTEST-145.md): "the warning appears by
itself with a reasonable position and when the time is right the object is spawned in at that
location just offscreen" · "the spawn point follows her but must keep making sense" · "all
offscreen events should work like that" · "2.9s is a fair time to react and *think* about what to
do. so I'd file mark that as the minimum"). A `PendingWarning` (`src/events/pending_warning.gd`)
holds a place and a clock and nothing in the world; the screen-edge badge is up for it the whole
time. Each frame the place follows her on the thing's own ground, and once `telegraph_time` is
over and the place is on that ground and off screen by `Tuning.offscreen_lead()`, the thing is
created there with its telegraph already spent, so a `hard_fail` row is lethal from the moment it
exists. It covers `cyclist` and `loose_dog` (on a sidewalk, down her line), `fire_truck` (on its
street's road, level with her or up the road, never past the fire) and the day-13 column (in its
lane). The siting no longer derives from the telegraph: `Tuning.outlasting_telegraph_lead()` and
`EventDef.toward_player_lead()` are gone, and the cyclist is back to his 90px field and `intensity`
18.0, 16.0 over a full pass. **That is not the cost he had before M207**: created with his
telegraph spent, he meets her at his full intensity rather than damped through an approach, so a
pass at 0px beside her costs 5.5 awake where it cost 3.4, and about 1.1 asleep where it was about
free (`docs/COSTS.md`); `loose_dog`'s moved the other way, 24.2 to 23.8.

**The fire engine and the day-13 column are created with their field already on her.** Just off
screen on its road the engine is about 250px from her, and its 548px of forward reach is longer
than the view is from her (180px up or down, 320px across); the column's front truck is about
220px up its lane with 395px of reach. What she is owed is the warning before either exists, and
the tests check that on the game's own siting. Neither is `hard_fail`, and a lethal row's field is
refused if it would reach her where it is created.

**The minimum warning for every row warned first is `Tuning.OFFSCREEN_WARNING_MIN`, 2.9s**,
measured from the badge to the earliest moment the thing can reach her (`EventDef.warning_time()`),
never a figure worked out from its field or speed; the engine carries `EventDef.warned_first`, and
the column's convoy is warned through a flagged copy (`EventManager.as_warned()`), so the ordinary
map-placed convoy keeps its field's minimum. The cyclist's `telegraph_time` is 2.13s, 2.92s from
badge to reach walking into him; the engine clears the 2.9s by 3.40s and the column by 1.55s.
`required_telegraph_time()` still sets the minimum for every row not warned first. Two bugs
the measuring found in the waiting place were fixed with it: the fire truck's place was the point of
the road nearest the fire, which put it behind her once she walked a screen up the road, and the
cyclist's place held still at a cross street while she walked into it, which brought it on screen.

**Choices made by the implementer where the design was silent, open to overturn**: a place with no
sensible ground moves sideways up to a street's width, then further along her line up to two
streets, never nearer; if nothing is found it stays where it was and the thing waits past its time
until its place is on its ground and off screen again. The direction a cyclist or loose dog comes
from is fixed when the warning goes up; if she turns, it does not swing round with her. A fire
truck whose fire she has walked past arrives a tile up from the fire and parks unseen. Her entering
a building or a park has no special handling. `loose_dog` is held to its field's minimum
(2.07s; it warns 2.40s) rather than the 2.9s, through an exemption list an earlier build added
before the player named the dog. The player's words on it are that its warning may be short ("the
loose dog can stay as short as it wants since it is not lethal and relatively low impact") and that
it "might not need a warning at all", not an exemption from a minimum (PLAYTEST-145, statements 11,
17 and 18); whether it keeps a warning is M226's. The player's "the dog timer is
good" was the pursuing dog's, and warning `charging_dog` first while keeping its day-3 timing is
M226; M226 also fits every other offscreen warning to that dog's timing on day 3, its warning
time and its on-screen chase, in place of the flat 2.9s ("the 2.9 is not important"). A warning
whose place is on screen (held because no ground was found, or the column clamped at the map's
end) keeps its badge up, pointing at an empty spot in view, past its time until she walks on; the
implementer's proposal, not built, is no badge and a clock held at the full `telegraph_time` while
the place is in view.

**What telegraphs at all is M226's.** The last question M207 left, whether patrols and planned
convoys are warned first, is answered by the player's rule that a thing telegraphs only if it goes
fast, can end the day and comes toward her (PLAYTEST-145, statements 19–24): none of them can end
the day, so none needs to telegraph, and that is not an exemption; in this build they telegraph as
they did before, and M226 changes that. The fire engine and the day-13 column,
which this build warns first, stop telegraphing under the same rule; M226 builds that, with the
pursuing dog's gold timing.

**The table of every warned row's lead**, `tests/probes/m207_warning_lead.gd`
(`tools/test.sh probes/m207_warning_lead.gd`; the runner does not discover it). Its first printing
was measured under the siting that was turned down. For each row it measures the seconds from the first warning she can
see, the badge or the thing in view, to the earliest moment it can reach her, walking toward it,
standing, and walking away, against `EventDef.minimum_telegraph()`. Its first printing, over the
floor in seconds walking toward / standing / walking away: `door_guard` +2.35 / +0.50 / +2.35;
`military_convoy` −0.21 / −0.21 / +11.24; `charging_dog` on day 3 −0.33 / +0.48 / +5.18;
`loose_dog` +0.10 / +1.62 / never; the cyclist at 60px +0.09 / +1.20 / never. The rest of that
printing is not kept; the probe run at da950c20, the turned-down build, prints it again (after the
squash that commit is reachable only as `git fetch origin pull/372/head`). Several rows measured under their own floor that way: `cat_dash` across her
line (to no warning at all horizontally), `charging_dog` from day 4, `alley_robbery`,
`masked_pursuer` and `pigeon_flock` walking toward it, `military_convoy` and `police_patrol`'s
return leg by a fraction of a second. Whether each is a contract breach or the probe standing her in
the wrong place is M224, a warning shorter than its own floor.
Printed again under warning first, from the badge to the earliest reach, walking toward / standing /
walking away, against the floor: `loose_dog` vertically 2.43 / 2.53 / 3.13 and horizontally 3.05 /
3.60 / 6.63 against 2.07; the cyclist vertically 2.92 / 3.35 / 4.87 and horizontally 3.47 / 4.20 /
never against 2.90; `fire_truck` 6.30 each way and the day-13 column 4.45 each way, both against
2.90. The rows not warned first measure as in the first printing.
