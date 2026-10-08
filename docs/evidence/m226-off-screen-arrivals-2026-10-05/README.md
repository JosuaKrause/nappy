# M226 — things from off screen after the review: no pop-in, the dog, a sent guard

**Claim.** On build 8321e965 each thing that arrives from off screen shows its screen-edge badge alone
with nothing in the world, and is then created wholly off screen, so the first frame that shows any
of it shows it at the edge, coming in. Three cases: a cyclist (day 2), the day-3 dog, and the guard
the van's task sends (day 7).

**Limits.** One seed each, the tap scheme, the debug readout on, `--invincible`. The bursts run at
about 5fps because the window was covered and each frame was drawn on demand, so "the first frame
that shows it" is the first captured frame after it was created, not the frame it was created on.
What proves no pop-in is `tests/test_no_pop_in.gd`; these show the shape.

**Commands** (`tools/shot.sh`, commit 8321e965):

    # the cyclist: burst from the badge rising
    tools/shot.sh /tmp/s2.png 9 --no-save --invincible --seed 4242 --day 2 --spawn arterial \
        --walk north --force cyclist 3 --press snapshot_burst 3.5
    # the day-3 dog: burst from the badge rising
    tools/shot.sh /tmp/s4.png 8 --no-save --invincible --seed 4242 --day 3 --spawn arterial \
        --walk north --force charging_dog 3 --press snapshot_burst 3.3
    # the van's guard: two stills of the day-7 package scene, at 9.6s and 9.85s of its playback
    tools/shot.sh /tmp/rob.png 9.6 --no-save --invincible \
        --recipe scene-recipes/task-07-package.json --recipe-mode scripted

**Retained.**

- `cyclist-before.png` (0.84s after the badge rose, `cyclist-burst.json` frame 5): the badge alone
  at the top edge, "10 m", nothing on the sidewalk above her.
- `cyclist-first.png` (1.04s, frame 6, 0.04s after he was created): the first frame showing him, his
  front wheel just inside the top edge, coming in, the badge still up for that frame.
- `dog-badge.png` (0.24s after the badge rose, `dog-burst.json` frame 2): the dog's badge alone.
- `dog-in-view.png` (1.11s, frame 6, the dog 0.2s old): the dog in view at the top, closing on its
  approach, and the run lesson's line.
- `guard-badge.png` (9.6s): the package handed over, the guard's badge alone at the bottom edge.
- `guard-in-view.png` (9.85s): the guard just in at the bottom, already chasing.
