## Gotchas learned in M22

- **A threshold that sounds defensible can be the old mistake in a new shape.** "Mark anything
  louder than the walking decay" marked `poster_crew`, `barricade` and `burnt_shell` — the three
  rows the cost table already calls scenery, and a set the rings would have marked too. The rule
  that works is not about magnitude: mark danger that **changes over time**.
- **Deleting a thing does not delete the habit.** `tests/test_danger.gd` asserts `EventAuraLayer`
  cannot come back and that the whole catalogue is never marked at once, because the failure this
  standing decision exists to stop is somebody reaching for a ring the *next* time something
  needs signalling, and a comment in a deleted file cannot stop that.
- **An additive `warn()` beats a setter, and the reason is ordering.** The crowd and the events
  both look at the ground she is standing on in the same frame. With a setter, whichever ran
  second cleared what the first said — silently downgrading a lethal event to nothing because no
  car happened to be coming. `Stroller.warn()` raises the level and never lowers it.
- **Force a cue's condition on, look at it, and put it back.** The screen-edge badge needs
  something lethal off-screen and closing, which a six-second screenshot cannot be asked for.
  Forcing it found three defects no test could see: it collided with the excitement meter, the
  icon was squashed by a square box, and some badges had no silhouette at all. That last one is
  the point of the badge — an arrow that can only say "something" is an anxiety, not a warning.
- **`tools/shot.sh` was silently eating its own flags.** Every dev flag passed to it was dropped,
  so a screenshot taken to look at one specific event was of the doorstep, and nothing said so.
  It forwards them now and has `--walk`, which holds a direction down for the whole run —
  necessary since M27, because a screenshot of a standing player is a screenshot of almost
  nothing.
- **The suite count went down, and that is correct.** 15890 → **15744**: the aura-layer checks
  went with the layer. A drop in check count after a deletion is fine; a drop after anything else
  is a suite that stopped running.
