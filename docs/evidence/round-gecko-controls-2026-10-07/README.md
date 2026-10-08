# The unused joystick becomes Run

These two gameplay stills show Run occupying the unused focal point, at the same painted
radius as the steering ring, after a synthetic tap has pressed and released. The left-steering
capture has Run on the right; the right-steering capture has Run on the left. The separate
inward discs are absent.

Captured from clean source revision `5d99f3012ca9773c8e5c2b6f10d44a29bc9324a3`, in that
order, with Godot 4.7.2 on macOS / Apple M2, native Compatibility rendering, 1280×720.
Both runs use seed 4242, day 1, a three-second wait, invincibility, the touch interface and
joystick mode. The left frame is drawn on demand because its window is occluded; the right
frame uses the regular render loop. The capture owner is the round-gecko implementation agent.

Rerun from a fresh clone using a new scratch directory:

```sh
git fetch origin refs/pull/603/head
git checkout --detach 5d99f3012ca9773c8e5c2b6f10d44a29bc9324a3
./tools/check.sh
capture_dir="$(mktemp -d)"
./tools/shot.sh "$capture_dir/round-gecko-left.png" 3 --seed 4242 --controls joystick --touch --tap 240 580 --invincible --player-view
./tools/shot.sh "$capture_dir/round-gecko-right.png" 3 --seed 4242 --controls joystick --touch --tap 1040 580 --invincible --player-view
```

`GODOT` may point at another installed engine executable for each command. The dev flags
disable saves. The collector is `tools/shot.sh` with `AutoScreenshot` at the same revision.
Only the two requested stills are retained; automatic captures and routine run logs are
unrelated to the layout claim.

These stills establish the two rendered layouts and retention after a released synthetic tap.
They do not establish phone feel, multi-touch ownership, precise hit boundaries, or movement
quality. Input behavior is covered by the focused touch, orientation, pause and held-restart
suites; visibility-mask behavior is covered by encounters. Invincibility makes no claim about
normal costs or danger. Crowd positions can vary between repeat captures.
