# polite-tapir — The world layer no longer names her class · 2026-11-16

**The ask.** Every listed layer break is fixed, moved or declared permanent (`standing-layer-breaks.md`, the layer-break
item of the polite-tapir entry). This is the pull request #1484, the design's pull request 3 of who builds the event manager and the crowd, merged before the builder (the design's pull
request 2, #1486); the builder is the record `polite-tapir-snowy-toad`, which
names this pull request and holds none of what it built. The design's pull request 1, merged after this one, is the record `polite-tapir-snowy-sparrow`; its pull request 4, the bus, is open. Behaviour is
unchanged: the camera frames the same and the view is the same rectangle. Nothing here is visible in play and no words of the
player's are cited or changed.

## What was built

- **`City.camera_bounds(look_ahead: float)`** takes the reach a glance costs (the camera's look-ahead) as a value. `main` (the
  overview camera and the trailer's zoom-out, the only two callers) passes `Stroller.CAMERA_LOOK_AHEAD` (46px, the number the
  body read before).
- **`VisibleView.look_from(centre: Vector2)`** replaces `look_through(player: Node2D)` and its cast to `Stroller`. Its callers,
  `EventManager` and `DangerEdge`, pass `Stroller.view_centre_of(player)`, a new static holding the one rule they would
  otherwise repeat: her current camera's drawn centre, or a plain body's own position for a rig.
- **`Stroller.camera_screen_center()` becomes private** (`_camera_screen_center()`): with `view_centre_of()` the one reader
  outside tests is gone, and `check_test_only_members.py` fails a public member only tests read. The tests ask
  `view_centre_of()`; the patrol suite's stand-in her keeps her camera disabled instead of overriding the private method.
- `tools/layer_map.py` loses the two `Stroller` lines (`city.gd`, `visible_view.gd`); `standing-layer-breaks.md` lists only
  `interior_scene.gd` for her class's type tests; `docs/MECHANICS.md` names `Stroller._camera_screen_center()` as what the
  camera ease reads.

## Measured

`uv run python tools/check_layers.py --list` printed 86 findings before and 84 after; the two removed are `city.gd` and
`visible_view.gd` naming `Stroller`, and none is new (the new `Stroller` names in `event_manager.gd`, simulation, and
`danger_edge.gd`, view, point down). The reviewer confirmed it, with line numbers stripped, and that `look_through(`, the public
`camera_screen_center(` and an argument-less `City.camera_bounds()` are left nowhere under `src/`, `tests/`, `tools/`, the
top-level docs or the skills. Tests, each by mutation on the head: `test_city_world` (the framing at look-ahead 0 and 46 differs
by exactly the look-ahead on each edge; fails if the argument is ignored), `test_visible_view` (the view is laid about the centre
handed in; fails with the centre ignored) and `test_stroller` (a plain body is viewed from its own position, and a rig whose
camera is current, limited to a 4000px rectangle and standing in its corner, from the camera's centre, not from her; fails with
the body changed to `return player.global_position`).

## Rejected, with the reason

- **Moving the break rather than removing it**: `Stroller.view_centre_of()` is a pure function of the body it is handed, called
  from her own layer (`EventManager`, which already casts its player to `Stroller` in five other places) and from a layer above
  (`DangerEdge`); what stays is one type test on a `Node2D`, now in her own file. Two inline cast copies in the callers would have
  derived the rule twice.
- **Keeping `camera_screen_center()` public**: forced out, since once `view_centre_of()` lives in `stroller.gd` its only readers
  are its own file and tests, the case the tests skill makes internal.

## Review

One review, changes requested on the head `1bd14d1779`, asking six fixes, all made in `d062180b4` and approved by the delta
review: the missing check on her camera's half of `view_centre_of()` (a mutation answering the body's position for her too
failed nothing; a rig whose camera is current and limited now holds it); `docs/MECHANICS.md` naming `view_centre_of()` where
the ease reads `_camera_screen_center()`; two queue sentences in `standing-layer-breaks.md`; the patrol suite's stand-in
overriding the private method; a stale closing paragraph in the description; and a test named for a camera it did not test.
Of its two preferences, `DangerEdge`'s first use of her class was left as it is and "are gone" in the queue entry was taken.

## What stays open

The bus through the event manager's parts and the resistance, and the city's own eight fields (`snowy-toad`'s "What stays open").
The world layer's other reads of the `player` group stay as `standing-layer-breaks.md` says.
