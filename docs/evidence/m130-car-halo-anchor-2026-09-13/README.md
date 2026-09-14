# M130 — an eastbound car and its halo read one anchor

Three rig runs on the same seed and the same standing place, so the car, its traced rim, its strike
box and its shadow capsule can be compared frame for frame. Each folder is a whole run: `run.log`,
`maps/` and the `asked/burst-*/` sequence with its own `burst.json` timing record.

```sh
tools/shot.sh out.png 9 --seed 4242 --spawn signal --layers 2,3 --press snapshot_burst 3        # before-signal, after-signal
tools/shot.sh out.png 9 --seed 4242 --spawn signal --layers 2,3 --press snapshot_burst 3 --svg  # after-signal-svg
```

`--spawn signal` stands her on the side street's own pavement at a signalled junction on the spine,
so the near lane is east-west traffic a few metres away — close enough that a passing car clears
`ExcitementHalo.CONTRIBUTION_FLOOR` (1.0 excitement/s at her position) and wears a rim. `--layers
2,3` draws the debug view's shadow capsules in blue and its bodies layer in green, with a moving
car's own strike box (`Tuning.CAR_STRIKE_HALF_LENGTH` × `CAR_STRIKE_HALF_WIDTH`, 26 × 14px from the
node, rotated onto the live heading) in the field layer's lethal red. Both of those are drawn fresh
every frame by `DebugLayers`, which is what makes them the datum a retained car picture can be
compared against.

**`--invincible` cannot be used for this subject and that is not a preference.** `Baby
._update_excitement()` empties its source list entirely under the flag — *"a source that charges the
halo but never reaches the meter is the exact drift this guards against"* — so nothing ever calls
`accumulate_landed()`, every source's `landed()` stays at zero, `ExcitementHalo.select_sources()`
picks nobody and no rim is drawn at all. A capture of a halo is a capture of a real meter.

## What the frames show

- `before-signal/halo-and-body-frame-0020.png` and `after-signal/halo-and-body-frame-0020.png` —
  the same westbound car under a halo, 6× nearest-neighbour crops of frame 20 of each burst. The
  pale rim stands `EntityHalo.HALO_MARGIN` (4px) outside the body on every side, the drawn wheels
  land on the strike box's south edge and the shadow capsule is centred on the node, in both.
- `after-signal-svg/halo-and-body-frame-0020.png` — the same car with `--svg` forcing the authored
  vector textures. It is the same picture at the same registration, because the crowd car family has
  no PNG transfer to force away from: `assets/illustrated/svg-transfer/` carries `props`, `rig` and
  `tiles` and no `crowd`, so `TextureResolver.resolve()` returns the authored SVG in both modes.
- `before-signal/picture-on-the-strike-box-frame-0012.png` — a 6× crop of a westbound car with no
  halo, kept because it is the clearest read of the registration itself: sampling the pixel column
  through its wheel puts the drawn tyre bottom at canvas row 29 of 30 with the canvas's own bottom
  edge on the box's south line, which is `_car_body_anchor()`'s rule met exactly.

**What these frames cannot show, and what does.** The defect only reaches the screen on a car that
has come round an arc, and five bursts across three standing places caught no turn under a halo —
the same budget M121's own record reports spending. The pin is therefore analytic and lives in
`tests/test_car_views.gd`: sweeping a synthetic arc through one sector moves the drawn ground line
2.2px per five degrees while the sector, the mirror and the gait frame are all unchanged, and the
suite asserts the redraw gate asked for a rebuild at every one of those steps. Reverting the gate's
heading term turns those checks red with the measured distances in their messages.
