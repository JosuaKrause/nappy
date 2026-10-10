# calm-pelican — The city camera at the city's edge

Two stills of what a player standing at the city's edge sees now that the city camera has no limits
and the land past the edge is painted for any view (#580's `clear_camera_limits()`, asked for in
#587: "the camera during normal gameplay shouldn't stop"). In both the camera is centred on her, and
the half of the screen past the edge shows the painted land beyond it rather than stopping at the
boundary street.

- `edge-east.png` — `--spawn edge:e`: her pavement beside the arterial where it runs out at the east
  edge, with the grass and fence past the edge filling the right half of the screen.
- `edge-south-bridge.png` — `--spawn edge:s`: the spine's last junction at the south edge, with the
  water and the bridge deck past the edge filling the lower half; cars on the deck are the spine's
  own traffic.

Both were taken at `aa4291ad84b15e885f416285c2424b36cc7341f7` (the game's build line reads
`v0.25.6-15-gaa4291ad`) with Godot 4.7.2 on an Apple M2, seed 4242, day 1, standing still for three
seconds under `--invincible` so nothing ends the day before the capture. The developer readout and
the first-day controls hint are drawn over both, as they are in every rig still. The east still's
window was covered, so its frame was drawn on demand (`[AutoScreenshot] wrote ... (window not
visible, so this frame was drawn on demand)`). Only the two stills are kept; the runs' logs say
nothing about the camera.

```sh
tools/shot.sh edge-east.png 3 --seed 4242 --spawn edge:e --invincible
tools/shot.sh edge-south-bridge.png 3 --seed 4242 --spawn edge:s --invincible
```

They show a standing player only: what the view does while she walks along the edge, or with the
look-ahead pushing it further past, is not captured here.
