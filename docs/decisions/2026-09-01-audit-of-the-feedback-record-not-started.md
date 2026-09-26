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
      to clear the area fast."* It is recorded correctly in `docs/playtests/PLAYTEST-02.md`; only the status
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
      `docs/playtests/PLAYTEST-14.md` carries the same stale reading, and `CLAUDE.md`'s known-shaky-ground
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
