**The sightings ask the visible area.** Two tests read a point around her against the
`Tuning.VIEW_HALF_EXTENT` box:

- **The fire's sighting.** `EventManager._summon_what_has_been_sighted()` sends the counter's
  `nappy-day-3-seen-fire` and summons the fire truck (`spawns_on_sight`) the first frame the burning
  building is on screen, through `EventManager._is_on_screen()`, its only caller once PR #578 has
  moved the pelican's `pelican-seen` onto `VisibleView`.
- **The poster crews' pasting** (`PosterWalls._work_the_crews()`), a sheet every `PASTE_EVERY`
  seconds while the crew is inside her view; that it is a visibility test is the filer's reading,
  in the README's **Proposed, not asked for**.

With the visible area, neither happens while the thing is only under a covered corner in the
joystick mode. Whether the fire keeps a point test or measures a share of its drawn box, as the
counter's seen and `pelican-seen` do (`Tuning.ENCOUNTER_SEEN_SHARE`, 80%), is open for whoever picks
the entry up; the point against the visible area is the smaller change. `docs/TELEMETRY.md`'s line
for `seen-fire` changes with it.
