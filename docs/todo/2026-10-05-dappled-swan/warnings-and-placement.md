**The off-screen warnings and the placing just off screen ask the visible area.** Today
`DangerEdge` raises a screen-edge badge for something closing on her that is not
`is_on_screen(at, margin)` (a margin of `SCREEN_MARGIN`, 130 screen px, once the thing has been in
view, so it does not flicker) and drops it once the thing is on screen. A warning with nothing in
the world yet, and a pursuer the director sites, is placed `Tuning.offscreen_lead()` out:
`offscreen_boundary(heading)`, a ray to the edge of the `VIEW_HALF_EXTENT` box along her heading,
plus a short notice at its closing speed. The resistance's own pursuers are started past `ResistanceDirector.badge_line()`, which adds the camera's lead, the badge margin and
the badge's rise to that half extent. `ResistanceDirector._box_shows()` refuses to place a chalk
mark, a waiting robber or a task's target where any corner of its box is in sight.

With the visible area, in the joystick mode a thing in a covered corner counts as off screen: its
badge stays up there, and the boundaries and the refusal measure to the area's edge rather than the
view's. M226 rewrites these warnings and their placing, so this is built on what M226 leaves, and
`EventDef.validate()`'s worst case (`Tuning.min_offscreen_boundary()`, 180 world px) is checked
against the area.
