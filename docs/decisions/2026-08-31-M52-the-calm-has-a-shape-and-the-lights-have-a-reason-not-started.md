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
      and one correction travelled with it: `docs/playtests/PLAYTEST-14.md` recorded the request against a
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
