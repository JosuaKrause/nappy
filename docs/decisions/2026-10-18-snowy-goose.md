# snowy-goose — Explosions in the escape city go off out of sight under their badge, with a flash and a shake · 2026-11-25

Built from the entry's README (minty-lemur #785: explosions off screen under a warning showing the
explosion, craters already there, a bright flash like the apartment escape's, random fainter
flashes, a small shake, nothing dangerous for viewers; inbox #1026 in brisk-ferret: the mushroom
cloud badge is liked).

**Set off by a place, under a badge.** An escape explosion (`finale_explosion`) is not in the
world until she comes within 520 px of where the escape's bag put it
(`EventCatalogue.FINALE_EXPLOSION_HEARD_WITHIN`, the same as how far it is heard). Then its
screen-edge badge goes up for 1 s (`Tuning.WARNING_ALONE_MAX`), drawn with the mushroom cloud of
`art/events/explosion.svg` in place of the star burst and showing its distance in meters, through
the one badge path of tawny-wombat; the picture is drawn only in the badge, never on the street. It
goes off once the badge has run, and only while it and the crater it leaves are fully out of her
sight. Walking into the range never skips the badge (`EventDef.may_be_set_off_at_once()`). The
bag's counts are untouched, and so are the building's own explosions (`explosion_outside`).

**Craters already there.** A crater is laid the moment its explosion goes off, not when the bang
ends, so no crater appears in her view and one she walks toward is standing before she sees it.

**The flash.** Each explosion lifts the city's night light toward the colour the building's hallways
lift to when their windows flash (`BlastLight`), at brightness 0.6; the random distant flashes lift
it to 0.2 and follow the building's own timing (`FlashRhythm`). A flash rises over 0.05 s and fades
over 0.4 s. The HUD, badges and controls are never lit. Measured on a burst (the evidence folder
`snowy-goose-explosion-badge-flash-shake-2026-11-25`): the explosions lift a frame's mean luminance
from about 64 to 86-89, the distant flashes to 70-79.

**The shake.** At most 3 px in world space (6 screen pixels), fading over 0.45 s, scaled by how loud
the explosion is where she stands (`ViewShake`). The burst shows up to 4 px of vertical jitter in
the 0.2 s after the bang. The game has no reduced-motion setting, so the shake has none to honour.

**Safe for viewers: both limits, stated.** The escape city starts no flash within 0.4 s of the last
one, so no second holds more than three; a test holds it over ten minutes of random bangs. The
building keeps its own timing, which the player specified (waits of 0.1 s to 5 s, mean 1.3 s, plus a
bang every 22 s): 20,000 simulated building walks show 6.3% with at least one second holding four
flashes, rarely five. It is left unchanged.

**Choices left open to the player** (the review item asks them with the stills):

- The flash brightness (0.6 for an explosion, 0.2 for a distant flash) and the shake (3 px over
  0.45 s). Both are the builder's first values, shown to the player before they ship as the entry
  proposed.
- The 520 px set-off distance and the 1 s badge.
- Whether the building gets the same flash limit as the escape city (its 6.3% of walks with a second
  of four flashes).
- No extra craters at the section's start: the escape's seals already stand some there.
- A badge for something that is neither lethal nor faster than a walk. The cues skill said a badge
  is only for those; it now adds things that stand where they come and so are on her all at once,
  and `.claude/skills/events/references/warned-first.md` covers the explosion and when walking in
  skips the badge.

**Rejected while building.** Drawing the mushroom on the street where it goes off (the picture the
player likes is a badge). Laying the crater when the bang ends (it appeared in her view). A first
version of the finale crater test left a city behind for later suites and made 109 checks fail; the
test was rewritten to clean up.
