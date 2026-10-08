# Dappled-swan — A dog enters the covered corner with its badge

An inspected production-game burst shows a warned dog entering the whole camera beneath the
joystick mode's lower-left covered rectangle, keeping its badge there, then showing its body
beyond the rectangle with the badge gone. This is the camera's ordinary game drawing and actual badge consumer;
no warning, picture or control is injected or drawn by the measurement probe.

Source: `0364aa435b402859067e59a0fc5a193cd589969e`, Godot 4.7.2 native Compatibility renderer,
macOS Apple M2, seed 4242, day 3, joystick mode with touch controls, invincible, no save.
The starting point is the signal junction. Existing developer flags make the director hand
out a charging dog every three walking seconds while input walks at 245 degrees from north.

## Selected frames

All files remain under the original run folder
`rig-220954-seed4242-v0.25.4-26-g0364aa43`. Times below are `burst.json`'s recorded elapsed
wall-clock seconds from the burst request, not assumed 12fps or exact simulation times.

| Frame | Burst elapsed | What it shows |
|---|---:|---|
| [0003](rig-220954-seed4242-v0.25.4-26-g0364aa43/frame-0003.png) | 0.175390 | The dog's badge points southwest; the incoming dog is not drawn in the camera yet. |
| [0011](rig-220954-seed4242-v0.25.4-26-g0364aa43/frame-0011.png) | 1.450861 | The actual dog is on the lower-left road, within the covered rectangle, and its separate dog badge remains beside it. |
| [0015](rig-220954-seed4242-v0.25.4-26-g0364aa43/frame-0015.png) | 2.195829 | The dog has crossed the rectangle's right boundary; its body and danger caret are visible and its edge badge is gone. |
| [0008](rig-220954-seed4242-v0.25.4-26-g0364aa43/frame-0008.png) | 0.744730 | A black capture frame, retained as a capture failure. It supports no claim about the game drawing or the arrival. |

The covered rectangle extends from the left edge to design-space x=289 and from y=431 downward,
using the actual 49px focal disc. It includes ground below the disc as well as ground directly
behind it. In frame 0011 the dog is left of that boundary and below the disc's top. In frame
0015 it is to the right of the boundary. This demonstrates the rectangle's visibility rule,
not that an opaque control completely hides the dog from a person's eyes.

The burst contains 19 frames over 3.088798 seconds. Its early images are 1280×720 and later
images 2048×1152; both have the same 16:9 design box. The black frame and changing native size
make this unsuitable for judging smoothness or exact animation speed. The three usable states
and headless consumer observation establish the intended covered-corner behavior. No image
is edited, resized or annotated. The selected PNGs and full timing sidecar are retained;
the remaining frames and the final automatic screenshot are redundant scratch.

## Reproduction and independent observation

The single windowed call is:

```sh
tools/shot.sh /private/tmp/nappy597-corner.png 8 --no-save --invincible --seed 4242 --day 3 \
  --spawn signal --controls joystick --touch --walk '8@245@' --force charging_dog 3 \
  --press snapshot_burst 3.1
```

The [headless observer](../../../tests/probes/m226_corner_runtime.gd) instantiates the real main
scene and reads its player, event manager, controls-derived visible view and actual badge list.
It changes no gameplay state. Its log separately records “in whole camera”, “in visible area”
and “badge up”; [preflight.txt](preflight.txt) records the result on the same source. It uses
the arrival collector's active-frame geometry, independently of placement bounds.

The preflight also preserves a boundary approximation: at 4.698 seconds the badge is already
gone while the selected drawing still counts as covered; at 4.704 seconds the drawing counts
as visible. The badge asks its nominal `drawn_box()`, while this observer measures the active
frame's drawing. This evidence does not claim pixel-exact agreement at that boundary.

```sh
godot --headless --path . res://tests/probes/m226_corner_runtime.tscn -- \
  --no-save --invincible --seed 4242 --day 3 --spawn signal --controls joystick --touch \
  --walk '8@245@' --force charging_dog 3 --frame-trace --after 8
```

The initial square spawn was unsuitable: it lay against the west map edge and the southwest
walk could not produce the needed arrival. A half-second forced interval at the signal did
produce covered arrivals, but overlapped multiple dogs; the three-second interval above
separates the first dog's covered entry and emergence from the next warning. These are
capture setup choices, with no change to ordinary warning or pursuit tuning.
