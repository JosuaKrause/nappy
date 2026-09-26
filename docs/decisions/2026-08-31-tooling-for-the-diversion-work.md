## Tooling for the diversion work · `feature/a-map-that-shows-the-plan`

Asked for alongside the diversion design, and it goes **first** for the reason the playtest-13
tooling did: the thing being built is a *placement*, and a placement is exactly what a trace in
words cannot show. Without this the only way to check that a corridor points anywhere is to play
the day and form an impression.

- [x] **Draw the corridor on the telemetry map.** `TelemetryMap` already writes a
      `<stem>-map-day<NN>.png` per day with the home, the calm areas, the spine, the precincts and
      the closures. Add the day's **corridor** — the routes from the doorstep to the calm areas
      that are still worth reaching — as a drawn path over the grid. This is the picture that
      answers *"is anything guiding her"*, which is the open question the whole milestone exists
      for, and it cannot be answered from a log line. **Built**: violet, junction centre to junction
      centre so it reads as a path. And it immediately earned itself — the first picture shows the
      trunk wandering west, north and back east before it arrives anywhere, which is the
      13.2-against-4.4 measurement above as something a person can look at
- [x] **And then it was read by the player, which changed three things about it.** *(2026-08-31,
      the first time anybody looked at one.)* Two were about the picture and the third was about the
      city; all three are in `docs/TELEMETRY.md` and the code, and the shape they share is worth the
      line: **a debug picture that decorates is a debug picture that lies.**
      - *"Marks disappearing is a problem"* — the corridor was drawn under four other marks and
        over one, so a stroke could simply not be there. It is **mixed into the ground** now rather
        than laid over it, which is also what *"keep the violet lines transparent"* asks for.
      - *"Don't draw the bundles white — don't make a distinction between path and bundle."* Gone.
        What goes with it is a diagnostic — a picture with no sharing in it is a star — and it is
        asserted in `tests/test_route_tree.gd` instead of being visible.
      - *"Why blue? Why not just take the sidewalk colour"* — the precinct mark is **deleted**. A
        precinct is laid `SIDEWALK` from frontage to frontage, so the ground pass already draws it
        as the one corridor with no asphalt stripe down it, and the blue line was an overlay
        repeating a fact the picture had
- [x] **Mark every placed event with its categorisation.** Not just *where* — **what kind**, in the
      vocabulary in `docs/CITY.md`, "The words for it": its **effect** (lethal / impassable /
      costly) and its **role** (wall / friction / set piece). A wall drawn on the corridor instead
      of beside it is the central defect this milestone can have, and it is one glance to see and
      invisible in every other tool. Distinguish placed-and-live from placed-and-never-reached, and
      keep it legible at 640px

      **Built: colour is the role, shape is the effect, a white pip is whether she reached it.** No
      row carries an effect the vocabulary did not already have — `EventDef.effect()` and
      `Planned.role` both existed by the end of step 2 — so this is a legend rather than a model,
      and `tests/test_telemetry.gd` asserts the legend *is* the drawing. Three things came out of
      building it, and two of them were found only by opening the PNG:

      - **"Distinguish placed-and-live from placed-and-never-reached" needs a second picture, and
        the second picture is the more useful half.** At dawn nothing has been reached, so the flag
        can only mean something at dusk — `-map-day<NN>-dusk.png`, written from `_on_day_finished`
        before `end_day()`. What the pair says that neither says alone: the dawn map shows a wall in
        the wrong place, and only the dusk one shows **a corridor with nothing on it ever met**.
      - **The first version faded what she never reached, and that is the picture whispering the
        thing it exists to shout.** A wall in the far corner of a map she never walked into is
        still a wall in the wrong place, and it is exactly the placement no trace can report. Drawn
        as a pip instead, every mark stays at full strength — and the pips turn out to be a **trail
        of where she actually went**, laid over the corridor the day planned for her, which is a
        second question answered for nothing.
      - **A faint mark can still be the loudest thing in a picture if it is the wrong shape.** A
        routed event draws a band along the ground it covers; at the mark's own strength, on a day
        with 175 placements, those bands read as *corridor* — thin coloured lines down the middle of
        streets, which is what the violet is. Dropping them was wrong too (a van that sweeps a whole
        street would be drawn as a point). 0.18 makes it a shadow you find when you look for it. The
        shape to carry: **a mark that can be mistaken for the one thing it has to be compared
        against is worse than no mark.**

Both obey the telemetry invariant — no RNG, nothing that changes a placement, no cost when
telemetry is off — and both are dev tooling under the same eventual debug-build gate.
