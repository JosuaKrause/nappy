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

**Still open, and it is the reason this will be reported a fourth time if it is not taken
seriously:** answering **0.2s** after the lunge is still caught. The stand-off is bought with
`PURSUIT_REACTION` against the dog's own speed, and at the lunge she is walking *into* it, so the
gap closes at `pursue_speed + WALK_SPEED` and the notice is worth about a third of what it was
priced at. `Tuning.pursuit_standoff` has said so since M35 and nothing has been done about it.
A player who reads the telegraph is fine; a player who reacts to the lunge is dead.

## 2. The border is just black

> "Did you do the border yet? It's just black."

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
