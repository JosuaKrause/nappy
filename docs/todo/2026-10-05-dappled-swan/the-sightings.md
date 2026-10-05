**The sightings ask the visible area.** Three tests read `EventManager._is_on_screen()` or the same
`Tuning.VIEW_HALF_EXTENT` box, a point around her:

- **The fire's sighting.** `EventManager._summon_what_has_been_sighted()` sends the counter's
  `nappy-day-3-seen-fire` and summons the fire truck (`spawns_on_sight`) the first frame the burning
  building is on screen.
- **The pelican's sighting.** `EventManager._report_the_pelicans_in_view()` sends
  `nappy-day-N-pelican-seen` the first frame a pelican is on screen.
- **The poster crews' pasting** (`PosterWalls._work_the_crews()`), a sheet every `PASTE_EVERY`
  seconds while the crew is inside her view; that it is a visibility test is the filer's reading,
  in the README's **Proposed, not asked for**.

With the visible area, none of these happens while the thing is only under a covered corner in the
joystick mode. Whether the fire and the pelican keep a point test or measure a share of their drawn
box as the counter's seen does (`VisibleView.visible_share()`, 80% for seen) is open for whoever
picks the entry up; the point against the visible area is the smaller change.
`docs/TELEMETRY.md`'s lines for `seen-fire` and `pelican-seen` change with it.
