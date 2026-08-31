# Playtest 14

Played on `main` at M46, immediately after the crowd milestone merged. Reported in three bursts
while playing, so the wording below is the player's, in the order it arrived.

The through-line is different from playtest 13's. Nothing here is about balance: five of the six
are about **the city not saying what it is** — a black edge, a junction that lies about where the
streets go, a landmark that never moves, a calm area that is the same shape every time — and the
sixth is a mechanic that was answering a question nobody asked.

---

## 1. The pursuing dog does not stop

> "The pursuing dog *still* doesn't stop. It's a *very simple rule*! When I run the dog backs down
> almost immediately — that's the only thing that needs to be tweaked. Nothing else!!!"
>
> "How does the distance matter in any way? The rule is WHEN I RUN THE DOG BACKS AWAY ALMOST
> IMMEDIATELY."
>
> "Or make running less costly."

**Third report of the same encounter** — playtest 10's finding 13, playtest 13's, and now this.
M35 and M39 both fixed something real and neither fixed this.

The rule the player states is the rule the design intends, and the code was stating it about the
**geometry** instead: `PURSUIT_SHAKEN_OFF` counted seconds of *the gap actually opening*. Against
the day-3 dog a run opens the gap at 38px/s — a fifth of a pixel a frame — so anything that
momentarily stopped her gaining ground reset the timer to zero: a corner, a kerb, a pedestrian in
the way, or the 0.37s the about-turn itself takes. The dog went on chasing somebody who was
visibly sprinting.

Confirmed off a trace before touching anything: `run  ran 1.3s, exc 57 -> 98`. She escaped and lost
the day doing it, which is the second remark exactly.

**Fixed** — the break-off is a fact about her now, and the price fell with it: 0.35s of running for
5 points, against 1.2s for 17. "Make running less costly" is answered by the chase being shorter
rather than by moving `EXCITEMENT_FROM_RUNNING`, which has to stay where it is because it is the
whole of why running is wrong against everything that does *not* follow her.

**Closed by the player, and played — which is the part to keep.**

> "BTW the pursuing dog is perfect now! When I walk away I die, if I run a bit I get rid of the
> dog. Perfect balance."

**That is the first human verdict this mechanic has ever had**, and it is a verdict on the exact
sentence it was designed around: walking and running give *opposite outcomes* rather than the same
outcome at two prices. Three playtests reported it broken; the thing that was wrong was never the
speeds, the stand-off, the telegraph or the chase clock — all of which were tuned repeatedly — but
that the break-off was stated about the geometry instead of about the player. `docs/TODO.md` and
`CLAUDE.md` both listed the day-3 dog under known-shaky ground on the grounds that no person had
played it since M35; that entry is now spent.

> "The pursuing dog is fixed now — the additional change you suggested is *not* needed."

The measured gap is still there: answering **0.2s** after the lunge is still caught, because she is
walking *into* the thing when it fires and `pursuit_standoff` is priced against the dog's own speed
alone. It was offered and declined, and that is the right call to leave standing — a player who
reads the telegraph has two and a half seconds and the lunge is the worst case rather than the
expected one. **Do not reopen it without a player asking.** `Tuning.pursuit_standoff` keeps the
note; what it does not keep any more is a claim that somebody wants it fixed.

## 2. The border is just black — and here is what should be there

> "Did you do the border yet? It's just black."

And then, after the first attempt at it, the brief that should have been asked for before a line
was written:

> "For the borders you actually need to create specific border tiles — in the south there needs to
> be a bulkhead first then water — no buildings — in the east and west there needs to be a fence,
> then grass and forest — in the north there needs to be a mountainside. The only exception is the
> tunnel (which needs the street to continue with a slight darkening of the tiles each step) and
> the bridge in the south."

> "The fence is rotated the wrong way."

**Recorded in full because the first pass lost it.** The complaint was written down as *"the border
is just black"* and answered by continuing the pavement outward, which cured the black and kept
the wrong answer: more city, receding into a camera limit, on every side. The design in the brief —
four sides that each say something different about *why* the city ends — was never on disk. See
the rule this produced in `CLAUDE.md`, "Write the feedback down with all of its detail".

The order out from the last kerb, which is what the tiles have to encode:

| side | step 1 | beyond |
|---|---|---|
| south | bulkhead | water — **no buildings** |
| east / west | fence | grass, then forest |
| north | scree | mountainside |

The two exceptions are the spine's own carriageway: the **tunnel** north, where the street carries
on and darkens a step per tile until it is gone, and the **bridge** south. The east-west road exits
that M41 built are deleted by this — *"the only exception is the tunnel and the bridge"* — and they
were never on a main road anyway.

The fence runs **north-south**, the axis it is used on. The first one was drawn as a horizontal
rail, so it appeared side-on to the border it was fencing.

M41 built a ring of frontages outside the map and opened the camera onto it. Neither of them put
anything on the **floor** out there — the tilemap has only ever been painted over `map.size` — so
the frontages stood on the clear colour.

**Fixed.** Each outside tile clamps to the nearest tile in the map and takes its picture, so the
edge continues outward: pavement behind a frontage, carriageway where a corridor runs off the map.
The spine's four exits get their road for free. A crossing is the one substitution — zebra stripes
repeated into the distance are a ladder lying in the road.

## 3. Junctions are four-way where an arm dead-ends

> "The intersections are four way when one side is a dead end."

**Not reproduced, and two candidates were checked and are correct.** Recorded so the next attempt
does not re-check them:

- **Absorbed streets.** A calm zone swallows the corridor between its blocks, and the junctions at
  each end are already T-junctions in the tile map: measured on two seeds, every junction at the
  end of an absent segment has **no crossing on the missing arm** and the full two tiles on the
  other three.
- **The map boundary.** Every junction on a boundary corridor keeps all four crossings, and that
  is right rather than wrong: the crossing on the outward side is how somebody walking the
  boundary street's outer pavement gets over the road she is meeting. It reads as a dead end only
  because there was nothing beyond it — which is finding 2, and finding 2 is fixed.

Since both remarks arrived in the same sentence, the black edge is the likely cause and this may
already be answered. **Needs a location from the player**, or a third candidate nobody has thought
of.

## 4. The main road is always in the same place

> "I have the feeling the main road is now always left to home. It should move around more."

Correct, and worse than the wording: it was `CrowdLanes.arterial_index` — the middle corridor — on
**every seed ever generated**. The largest thing a player navigates by stood in the same place
relative to the home in every run anybody has played.

**Fixed.** Rolled from the city's own street stream, three corridors clear of either boundary so
that both halves of the city are worth being in. Four places were still deriving it from the
constant, which is exactly the defect M46 found in `CrowdLanes.busyness` — *a fact about a city
answered from an axis length*.

Two tests were pinned to seed 4242's old fixture rather than to a rule and had to be fixed with it.
One of them opened its day with **no crowd focus**, so it found cars on the spine only for as long
as the spine was the middle corridor: M46's floor-test defect, in the test next door to it.

## 5. Courtyards are still one block

> "Also the courtyards are still one block."

Known and planned — the M47 entry *"The 2×2 inner courtyard — an apartment complex"*, asked for
"a long time ago" and still not built. What exists is `COURTYARD_SIZE_TILES`, a four-tile court cut
inside **one** residential block. What is wanted is four blocks of buildings with a shared court in
the middle, built on M21's mechanism — absorb the streets between four blocks — with frontages
around the outside instead of open ground, so it is a calm area you have to find a way *into*.

**Not started.** It is the largest remaining piece of M47 and the one the player has now asked for
twice.

## 7. Calm areas must not be diagonal from each other either

> "Calm zones shouldn't be possible diagonal from each other — we said they should not be next to
> each other, this includes the entire surrounding."

`_has_open_calm_neighbour` walked the four edges of a footprint and skipped the four corners, so
two calm areas could meet at a **crossroads** — not across a street from each other but across a
junction, which from the pavement is the same sight and is exactly what the rule exists to stop.

M47 had it as an open question — *"probably right — they are a junction apart rather than a street
apart — but it is currently an accident of the loop bounds rather than a decision"*. **This is the
decision.** Fixed: the ring is `footprint.grow(1)`, corners included.

### Re-reported on 2026-08-31, off a telemetry map, and it was half fixed

> "I see two diagonally adjacent parks -- that bug is still not fixed?"

Sent with a `-map-day` picture showing two green lot outlines meeting at a corner. **The report is
right and the M49 fix was not wrong** — it was narrower than the sentence it came from, in a way
nothing could have caught:

- `_has_open_calm_neighbour` asks whether anything **open calm** is in the ring — park, forest,
  quiet square — and a **courtyard** is none of those. So the rule was never about calm areas, it
  was about three of the four kinds of them.
- `CityGenerator.validate()` could not catch it either, and for two independent reasons: it skipped
  every non-open-calm lot, *and* it only stepped `RIGHT` and `DOWN`, so it had never checked a
  diagonal at all. The generator's placement rule was fixed in M49 and the guarantee that is
  supposed to hold it was left checking the old thing.

Measured over 40 seeds before the fix: **10 of 40 cities have at least one pair**, 12 side by side
and 8 diagonal, and **every single one is courtyard-to-courtyard**. No park was ever next to
anything — that half has worked since M49.

The shape to carry, because this project has now paid for it twice in two milestones: **an
identity standing in for the property.** `_OPEN_CALM` is the list of purposes that are *laid as
open ground*, and it was being read as "the calm ones" because for a long time those were the same
set. `docs/CITY.md` states the guarantee over **calm areas**, and `map.calm_blocks` — which is what
the picture draws and what the player is looking at — has always included courtyards.

## 8. A calm area she had never been to was already spoiled

> "I just came to a calm zone that already had events play out (a musician) but I have never been
> to it before — this should not be possible otherwise the contract of 'I should be able to find
> calm zones easily and should not be able to return to previous ones' is broken — this calm zone
> would make the game hard stop since no calm zone would be available one day early."

**The most serious finding in this playtest**, because it is an unwinnable-day bug rather than a
feel one, and the arithmetic in the player's sentence is the whole of it.

`MIN_CALM_BLOCKS` is derived as *an act's worth of days plus one* precisely so that an act can burn
one area per day and still have a spare. What burns them is meant to be
`_spoil_the_parks_she_used`, which spoils only the ones she **settled in this act** — that is the
mechanism that stops her returning, and it is deliberate.

But `_ensure_one_usable_park` guarantees exactly **one** clean area, and nothing stops ordinary
event placement landing a busker, a market stall or a café in any of the others. So an area she has
never visited can be spoiled by chance, the pool of usable areas falls below what the derivation
assumed, and the act runs out a day early — through no decision she made and with nothing telling
her it happened.

**The fix is to make the guarantee match the derivation:** every calm area she has **not** used
this act stays clean, so the only thing that ever spoils one is having gone there. Spoiling remains
the answer to *returning*, and the count of places left is then exactly what
`Tuning.calm_areas_needed()` says it is.

## 9. Nothing guides her toward the calm

> "I still don't feel the game guiding me to calm zones via obstacles — also tell me you have a
> note about hard and soft diversions — otherwise what's the point of me giving feedback if you
> never implement it."

**There was no note about hard and soft diversions anywhere in the repo** — not in `CLAUDE.md`, not
in `docs/`, not in `docs/TODO.md`. It was asked for, never written down, and therefore never built.
That is the second time in this playtest, and it is what produced the `CLAUDE.md` rule.

The current logic is now written out in `docs/CITY.md`, "Guiding her to the calm — what the game
actually does", because it had never been stated in a design doc either. The short version: the
city **permits** routes to calm and **protects** them from becoming impossible, and never suggests
one. Closures are drawn at random from the candidates that keep the two-routes invariant, so a
closure is as likely to be behind her as across her route; there is no cue of any kind toward calm;
and the main road as a soft block is planned and unbuilt.

**The design for hard and soft diversions has to be captured from the player** before anything is
built, and this file is where it goes. Guessing at it is how finding 2 went wrong.

## 10. Traffic lights stand against the building, not the kerb

> "The traffic lights go to the side of the road *not* the building — they always stay close to
> the road."

A signal head belongs at the **kerb**, on the carriageway side of the footway, and it should stay
there whatever the pavement around it is doing. `City._spawn_signal_heads` currently puts them
somewhere that reads as the frontage side.

The reason it matters is the one the heads were built on in M41: *where it stands is what says
which road it is talking about*. A head against a shopfront is a head that has stopped pointing
at anything, and it is also simply wrong — nobody puts a light where a driver cannot see it.

## 11. Calm ground is worth more, and a small calm area worth more still

> "x1.5 the sleepiness effect of calm zones and double it for 1x1 calm zones."

`Tuning.SLEEPINESS_CALM_ZONE_MULTIPLIER` is 12 (M38 took it 10 → 12).

**Two readings and the ambiguity is worth resolving before building it**, because they differ for
the multi-block case:

- **A**: every calm area ×1.5, and a 1×1 area ×2 — so 18 for a zone and 24 for a single block.
- **B**: every calm area ×1.5, and a 1×1 area double *that* — 18 and 36.

A is the reading taken here unless corrected. The design behind it is clear either way and is a
good one: a four-block zone is more than one lap wide and a single block is not, so the small ones
have always been the weaker choice for reasons that had nothing to do with what they are *for*.
Paying by area makes *which* calm area to head for a real question again — which is exactly the
sentence `docs/CITY.md` uses about keeping single-block calm in the mix.

Check afterwards: `docs/MECHANICS.md` states the "a calm area is more than one lap" margin, and
M38's entry warns that this constant is the one that decides whether a day is winnable once the
park is reached.

## 12. The fence is drawn in elevation and then turned on its side

> "The fence still doesn't look like a fence — it just looks like a fence from the front but
> rotated sideways, which doesn't make sense."

Both fence tiles so far have been a **side elevation**: palings with a rail across them, as you
would see a fence standing in front of you. The game is drawn from directly above. From there a
fence is a thin line with post-heads on it and a shadow, not a row of vertical boards — turning the
elevation ninety degrees does not make it a top-down drawing, it just makes it a picture lying on
the ground.

This is the "one picture per row" rule applied to ground: the tile has to be drawn *from the
camera's angle*, not drawn flat and rotated.

## 13. The eastern border, in one screenshot

`run-2026-08-30T233248-seed3225216943-834423d-dirty-069s-asked.png` — seed 3225216943, day 2,
tile (152,103), east edge. Four separate faults, listed as the player numbered them:

- **a) A calm area is directly against the border.** M47's *"calm ground is never at the edge"* was
  committed and this seed has it anyway, so either the rule does not cover this case or it is not
  being applied to whatever kind of calm this is. Needs checking against `_zone_fits` and the
  single-block calm placement separately — they are different code paths.
- **b) A road runs into the border instead of ending in a T-junction.** The lattice is supposed to
  end in a boundary corridor that every interior street tees into. Here a carriageway reaches the
  edge and simply stops in the grass.
- **c) People walk into the border as if it were pavement, and disappear.**

  > "Nobody should be walking there since it is not a walkable area — they need to turn like the
  > cars on a t-junction."

  **The player's diagnosis is right and the first one written here was wrong.** It was recorded as
  agents *ranging too far* — that M46 grew the crowd's box near the boundary, so they now travel
  further outside the map before recycling, and the new grass made it visible. That explains how
  far they get. It does not explain why they are out there at all, and the answer is one line.

  Every agent, walker and car alike, already runs the T-junction rule: `_process` calls
  `_blocked_ahead(_vertical, _direction, LOOKAHEAD)` and diverts. `_blocked_ahead` reads:

  ```gdscript
  if _map.is_closed(tile):
      return true
  if not _map.in_bounds(tile):
      return false          # <- the boundary is the one wall it says is clear
  ```

  **Out of bounds is reported as not blocked.** So the machinery that turns a car off a closed
  street, off a precinct and out of a park is in place, applies to walkers, and is told that the
  edge of the world is open road. Nothing about the crowd's population or its box is implicated;
  they walk off the map because the only thing that would stop them says they may.

  Two things follow and both are worth having before this is built. The fix is likely to be
  *"out of bounds is blocked"* and then the existing divert does the rest — which would also make
  fault **b)** disappear, since a car reaching the edge would turn instead of running into the
  grass. And it wants checking against the **spine exits**, which are the one place an agent is
  supposed to leave the map: the tunnel and the bridge are lethal on purpose and a car has to be
  able to drive into them.
- **d) The fence again** — finding 12.

## 14. The same faults on the other borders

> "Same issue with other borders."

North and south have the same shape of problem: what the streets do when they reach the edge, and
what the crowd does out there. The south's bulkhead and the north's mountainside are the same
question in different art. Whatever fixes the east has to be stated over *a border* rather than
over one side of the map — the first border pass was four sides written four times, and that is
already one bug per side waiting to happen.

---

## What this playtest says about the process

Two of the six were **already written down** and not done (3's boundary half is arguable, 5 is
explicit in `docs/TODO.md`), and one had been reported twice before (1). The pattern is not that
the findings are hard; it is that a finding which is planned rather than fixed comes back in the
player's own words, and the second telling is angrier than the first.

And one shape recurs from M46 and is now three-for-three: **a fact about a city answered from a
constant.** `CrowdLanes.busyness` did it with the arterial, the spine did it with its position, and
two tests did it with a fixture that only existed on one seed. When something asks *which* street,
*which* corridor, *which* precinct — it has to ask the map.
