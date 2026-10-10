# The fields layer cut where a wall stops the field

**Claim.** With the debug view's fields layer on, an outline is drawn only where the emitter's
field reaches past every wall: the market stall's outer field, which runs up into the building
behind it, stops a tile inside the building on both sides and is not drawn across it.

**Limits.** One still of one moment. It shows the cut on a thick building in the city; the
interior's walls and one-tile walls are held by `tests/test_wall_shield.gd`, not by a picture. The
facade is drawn rising above the building's footprint, so the cut's two ends sit in the brick
drawing about a tile above the sidewalk's edge rather than at a line drawn on the ground.

**Source.** Commit `7407a21fc666adc528483b2b3568d629607cef8d` on
`feature/calm-pelican-interior-walls`, Godot 4.7.2, macOS desktop, the window covered (the frame was
drawn on demand).

```sh
tools/shot.sh out.png 5 --seed 4242 --spawn arterial --layers 1 --invincible --walk 2s3e
```

**Retained.** `arterial-fields.png`, the still as written; `arterial-fields-stall.png`, the same
still cropped to the stall (x 440 to 900, y 90 to 420) so the cut can be seen at full size.
