# Rendered canvas-shader warmup

This complete capture run exercises both real `Main` boot branches in one bounded windowed Godot
process. The ordinary and escape records each observe `HaloWarm` and `WaterWarm` before the frame
and again at `RenderingServer.frame_post_draw`, then retain the first completed game frame after
the warmup. The ordinary frame shows the opening day at the doorstep; the escape frame shows the
opening building-section brief. The existing [waterfront burst](../waterfront.gif) records the
approved ripple at the first south-shore approach.

`capture.json` records Godot 4.7.2, the `gl_compatibility` rendering method, the `opengl3` driver,
the Apple M2 adapter and the no-save/no-telemetry arguments. The command forces Compatibility
explicitly and starts both paths under seed 4242:

```sh
SCENERY_CAPTURE_OUTPUT=/absolute/path/to/new-output \
  Godot --path . --rendering-method gl_compatibility \
  res://tests/probes/scenery_shader_warmup_runtime.tscn -- \
  --no-save --no-telemetry --seed 4242 --spawn edge:s --no-title \
  --start-escape=city --invincible
```

An earlier `tools/shot.sh` launch reaches the ordinary day but its requested burst cancels with
zero frames, so it establishes no rendered result and is not retained as evidence. This successful
run establishes visible boot completion and a rendered frame while the two warmup nodes are live;
it is not a hitch, frame-time or phone-performance measurement.
