# The steering side is chosen on the title

Four stills. The title, in landscape and in the rotated portrait presentation, shows two
joystick buttons centred on the two focal points the rings occupy in play, and the tap button
midway between them. The two gameplay stills show each choice in play: with the left side
steering, the left focal point carries the steering ring (its dead zone drawn as a fainter
inner circle, the knob at the heading) and the right one the Run disc; with the right side
steering, the mirror. Each gameplay still follows one synthetic tap above the steering focus,
so the knob points north.

Captured from clean source revision `1d8cb7ab`, with Godot 4.7.2 on macOS / Apple M2, native
Compatibility rendering. Every frame was drawn on demand because its window was occluded. The
capture owner is the leafy-marten implementation agent.

Rerun from a fresh clone using a new scratch directory:

```sh
git fetch origin feature/leafy-marten-title-side   # or refs/pull/<PR>/head once merged
git checkout --detach 1d8cb7ab
./tools/check.sh
capture_dir="$(mktemp -d)"
./tools/shot.sh "$capture_dir/leafy-marten-title.png" 3 --title --touch --seed 4242 --no-save
RESOLUTION=720x1280 ./tools/shot.sh "$capture_dir/leafy-marten-title-portrait.png" 3 --title --touch --no-save
./tools/shot.sh "$capture_dir/leafy-marten-left-steering.png" 4 --controls joystick --touch --tap 240 380 --invincible --seed 4242 --press key:4 0.5
./tools/shot.sh "$capture_dir/leafy-marten-right-steering.png" 4 --controls joystick-right --touch --tap 1040 380 --invincible --seed 4242 --press key:4 0.5
```

`key:4` hides the developer readout so the right-hand control is not under it. `GODOT` may
point at another installed engine executable. The dev flags disable saves. The collector is
`tools/shot.sh` with `AutoScreenshot` at the same revision. Only the four requested stills are
retained.

These stills establish the rendered layouts. They do not establish phone feel, the reach of the
steering half, the dead zone's size under a thumb, swipe handling or multi-touch ownership; the
geometry and input behaviour are covered by the touch, orientation, pause, main and
visible-view suites. Invincibility makes no claim about costs or danger. Crowd positions vary
between repeat captures.
