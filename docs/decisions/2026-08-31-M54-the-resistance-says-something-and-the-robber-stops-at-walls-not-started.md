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

Playtest 16's findings 6, 7 and 8, in full in **[docs/playtests/PLAYTEST-16.md](../playtests/PLAYTEST-16.md)**. **This is
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
