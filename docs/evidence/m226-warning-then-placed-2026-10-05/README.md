# M226 — a warning is a badge alone for a second, then the thing is placed just out of sight

**Claim.** On a played day the cyclist's screen-edge badge goes up with nothing in the world, holds
still at the same place on the edge while she walks, and after one second the cyclist is created just
out of sight where it pointed; he is in view at once and the badge goes off.

**Limits.** One warning, one seed, the tap scheme (no covered corners), a forced cyclist rather than
one the day's own bag handed out, the debug readout on. It shows the shape of one warning, not a
measurement: the timings are `tools/test.sh probes/m207_warning_lead.gd`'s.

**Source.** Commit bad3b80d on `feature/warnings-one-second`. Command:

    tools/shot.sh /tmp/warn-first/s.png 9 --no-save --invincible --seed 4242 --day 2 \
        --spawn arterial --walk north --force cyclist 3 --press snapshot_burst 3.5

The burst started on the frame the badge rose (the run log: `edge badge: cyclist at 194px`), so
`elapsed_seconds` in `burst.json` is time since the warning went up. The window was covered, so each
frame was drawn on demand (`AutoScreenshot.drawn_frame()`), which is why the burst ran at about 7fps.

**Retained.** Five of the burst's 21 frames and its `burst.json`:

- `frame-0002.png` (0.18s): the badge alone, top edge, "9 m", nothing on the sidewalk above her.
- `frame-0007.png` (0.87s): the badge at the same place on the edge, still nothing in the world.
- `frame-0008.png` (1.00s): the cyclist created just out of sight at the top edge, already coming
  into view; the readout's nearest is `cyclist active age=1.0/1.0`.
- `frame-0009.png` (1.24s): the cyclist in view, the badge gone, the lethal mark over her.
- `frame-0011.png` (1.53s): the cyclist reaching her, about half a second after he came into view; `--invincible` keeps the day going.
