priority: now
after: 2026-10-18-minty-quail

# snowy-goose — Explosions in the escape city: off screen, an explosion badge, craters already there, flashes and a shake · filed 2026-10-18


The player, on the escape city: "explosions have to happen off-screen with a warning sign showing the
explosion as mushroom or whatever indicates an explosion -- craters must already be there when the
player walks towards them (right now they appear out of nowhere) -- an explosion is accompanied with a
bright screen flash (matching the flashes from the apartment escape). don't make them too short to not
be dangerous for viewers", and "also have some random screen flashes as well indicating further away
bombs. and for the closeby explosion have the screen shake a little" (minty-lemur #785).

Built after minty-quail (one engine), since the escape city's events then run on the day's code; the
order is the filer's proposal.

**The ask, item by item (one PR, or two if the badge drawing goes first):**
- **Off screen, with a badge.** Every escape explosion goes off out of her view, announced by the
  screen-edge badge pointing at it, drawn as an explosion ("mushroom or whatever indicates an
  explosion"). A new badge picture is SVG, drawn by Opus under **svg-art** and **cues**; its first
  attempt comes back to the player early.
- **Craters already there.** A crater she walks toward is already standing: since an explosion never
  goes off in view, no crater appears in front of her. **Read as:** craters of explosions earlier in
  the walk are placed before she can see them; whether some craters stand from the section's start is
  the builder's proposal.
- **A bright flash** with each explosion, matching the building's flashes (`InteriorScene`'s distant
  flashes, `start_the_night()`, light with no noise behind it).
- **Random distant flashes** for bombs further away, fainter.
- **A small screen shake** for a nearby explosion: short, eased, never hiding a danger or moving the
  controls; if the game has a reduced-motion setting, the shake honours it (say whether it has one).
- **Safe for viewers.** "don't make them too short to not be dangerous for viewers": no flash too
  short or too frequent; the usual photosensitivity guidance is no more than three flashes in any
  one second. Check the building's existing flashes against the same limit and state both.

*Proposed, not asked for:* the flash brightness and shake size are measured on a still and a burst
and shown to the player before they ship.
