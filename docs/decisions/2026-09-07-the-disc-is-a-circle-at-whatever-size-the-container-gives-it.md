## The disc is a circle at whatever size the container gives it · built 2026-09-07

*(Playtest 35 finding 7: "the hover highlight showed a bug that the button is currently a square
and not the circle -- although nothing we need to fix right now".)* Parked by the player on sight;
it turned out to be a two-line fix and was built the same day, in `src/ui/mode_button.gd`.

**The constant was the bug and the hover was the light that found it.** `_disc_style()` set every
`corner_radius_*` to `_RADIUS` (46), which rounds a rect into a circle only while that rect is
exactly 92x92 — and `custom_minimum_size` is a *minimum*, so any container that hands the button
more room leaves a rounded rectangle. The resting and hover browns sat close enough to the panel
behind them that the corners never read; the near-white pressed and hover fills showed the
silhouette outright. So it was an old defect exposed rather than a regression, and reverting the
hover would only have hidden it again.

**Fixed by deriving the radius rather than by pinning the size**, and that is the choice worth
keeping: every scene already sets shrink-centre on all six `ModeButton` instances, so which
container was doing the stretching could not be reproduced from the scene files alone. Pinning the
size would have fixed the case nobody could see and left the next container free to break it
again; `_drawn_radius()` reads half the rect's own shorter side, which is correct at every size,
falling back to `_RADIUS` before the first layout when `size` is still zero. The styleboxes are
re-applied on `NOTIFICATION_RESIZED` — a stylebox is stored data, not something re-derived per
frame — and the look is refreshed afterward so a resize cannot silently un-press a held button.
**The hold sweep had the same latent bug** — its centre and radius were `_RADIUS` too — and reads
the rect's own middle and `_drawn_radius()` now.
