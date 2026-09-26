## Gotchas learned in M33

- **A falloff shape is a design decision wearing an implementation's clothes.** Thirty rows of
  hand-tuned radii and intensities, and the thing making three quarters of every radius free was
  one exponent nobody had looked at since M2. When a whole class of content "does not land", check
  the curve before checking the constants.
- **One shape change moves every consumer of it, including the ones that did not want it.** The
  crowd sums the same `falloff` the events do, and doubling what a body is worth at mid-range put
  the arterial floor at 18.4/s against a 3.5 decay — a main road that fills the meter in six
  seconds. It pays the shape back in **radius**, so the close pass is untouched and only the wide
  cheap middle went.
- **A measured fact written only in a document breaks silently.** *"Running is the wrong move
  against every event"* had been in `CLAUDE.md` since M19 and was false in four rows the moment
  the falloff moved. It is a test now. Anything the docs state as measured and load-bearing should
  be.
- **A ratio the design rests on can decay out from under it with nobody touching the numbers.**
  M19 measured eleven contacts down a lane centre against one on the midline and M27 re-measured
  it; by M33 it was thirteen against fifteen on `main`, because a midline is 16px from two lane
  centres, `BUMP_RADIUS` is 14, and every milestone since has given walkers more reason to be off
  their exact centre. Two pixels of clearance was never a mechanic. Re-measure the ratios a design
  claims, not just the numbers it sets.
- **A hysteresis that is one number wide is not a hysteresis.** The bump resolved to exactly
  `BUMP_RADIUS`, which is the value that releases the contact, so a resolved pair sat on its own
  threshold and re-fired. Resolve *past* the release, always.
- **Positional separation can be undone by steering.** The invariant says separation is positional
  and never a force, and it is — but a walker steers back to its lane centre at 90px/s, so the
  separation was being un-made every frame. The fix is not more separation, it is giving the other
  body somewhere else to want to be.
- **The obvious avoidance test is the wrong one for anything crossing your path.** "Is it within a
  lane's width of my line right now" is right for somebody sharing the pavement and useless for
  somebody crossing it — at 60px/s they enter that window a third of a second before the contact.
  Predict the **closest approach**. A probe said nine of every twelve contacts were exactly that
  walker, which is how the first version got caught doing nothing.
- **Measure the thing you are changing, not the thing next to it.** The probe first counted "is
  anybody touching", which chains one contact into the next on a busy pavement and reported a 3.8s
  contact that was really nine. Per-agent, or the number is a different number.
- **A rig that drives the player must turn the player's own `_physics_process` off.** The
  pursuit probe moved her twice a frame — once by the rig and once by `Stroller` — so she fled at
  157px/s instead of 92 and the chase looked unfair in the player's favour. `CLAUDE.md` already
  says a probe that disagrees with the game is wrong about the game; this is the cheapest way to
  make one disagree.
- **A rig cannot hold a reference to an event past the frame it finishes.** `EventManager` frees
  a finished instance, and `if not _dog: return` then silently swallows the whole measurement.
  Twelve minutes of a probe printing nothing.
- **A new catalogue row reshuffles every day's rolls.** Adding `charging_dog` changed which tile
  every later event landed on, which surfaced a latent bug in `_along_street_path`: a route
  truncated by a closure can *finish* jammed against the city wall even though the length check
  keeps a margin from it. That check had been passing by luck since M5.
- **The first cue rule you write about "changes over time" will mark everything again.** M22
  learned it with "louder than the walking decay"; M33 learned the same lesson with
  `pulse_period > 0`, which is six of the ten rows available on day 1. The question is never
  *does it change* — it is **can the player play against the change**.
