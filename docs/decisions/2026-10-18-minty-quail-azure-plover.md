# minty-quail — Event pictures draw through a drawer the manager hands in (tests through public seams: W8b) · 2026-11-04

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the event pictures on the
drawer shape of the roof and front drawers (records sandy-raven and crisp-stork), from the player's
answer to drawn-art-tests (inbox #1018 in brisk-ferret).

**Built.**
- `EventDrawer` (`src/events/views/event_drawer.gd`) has one call per kind of picture: a standing
  picture, a picture laid into a rectangle, one slice's band of a wide scene, and the scenery behind
  a crash or a burst main. Every atlas picture the looks drew goes through it, in the same order,
  place, size, mirror and tint; shadows, a dog's lead, muzzle flashes and the caret are not atlas
  pictures and stay the look's own. The manager builds it over its atlas, `EventSpawner.create()`
  hands it to every instance through `EventInstance.drawer`, and an instance nobody handed one makes
  its own the first time its look asks.
- No look places anything by a random draw, so no placement query is added: the picture choices
  stay private and the tests read each answer off a recording drawer
  (`tests/recording_event_drawer.gd`), with a row stood on a street over real frames
  (`tests/drawn_event.gd`).
- `test_events_catalogue.gd`, `test_event_views.gd`, `test_heat.gd`, `test_protest.gd` and
  `test_draw_layers.gd` (private-read lines 7, 5, 2, 2 and 1 to 0; `test_protest.gd`'s `GameState`
  lines 12 to 0; `test_heat.gd`'s hand-called frame 1 to 0). Twenty-one mutation runs. Before and
  after stills of days 9 and 4 (`docs/evidence/event-drawer-2026-11-04/`) show the roadblock, the
  checkpoint, the café, a barricade, both burst mains and the stall unchanged pixel for pixel.

**Open to overturn:** one drawer per event carrying every picture; the manager building it rather
than each instance; an instance's own drawer made when its look first asks, since its slices draw
before it does.

**Not done:** the gait and caret writes in `test_event_redraw.gd`, `test_event_strides.gd` and
`test_drawn_view.gd`: the drawer would answer the strides (a walker stepped for real, drawn with the
recorder) but not the caret, which is drawn outside it and cached by the excitement; `test_acts.gd`'s
flame reads, which the drawer can now answer.
