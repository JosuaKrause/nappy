# snowy-goose — Explosions in the escape city go off out of sight under their badge, with a flash and a shake · 2026-11-25

Built from the entry's README (minty-lemur #785: explosions off screen under a warning showing the
explosion, craters already there, a bright flash like the apartment escape's, random fainter
flashes, a small shake, nothing dangerous for viewers; inbox #1026 in brisk-ferret: the mushroom
cloud badge is liked).

**Set off by a place, under a badge.** An escape explosion (`finale_explosion`) is not in the
world until she comes within about 890 px of where the escape's bag put it
(`EventCatalogue.FINALE_EXPLOSION_SET_OFF_WITHIN`: its field's 520 px reach,
`FINALE_EXPLOSION_HEARD_WITHIN`, and as far again as she runs in its 1 s badge and 1.2 s bang).
Then its screen-edge badge goes up for 1 s (`Tuning.WARNING_ALONE_MAX`), drawn with the mushroom
cloud of `art/events/explosion.svg` in place of the star burst and showing its distance in meters,
through the one badge path of tawny-wombat; the picture is drawn only in the badge, never on the
street, which the row states as a setting of its look (`LookSpec.drawn_only_in_its_badge()`). It
goes off once the badge has run, and only while it and the crater it leaves are fully out of her
sight. It comes all at once (`EventDef.comes_all_at_once()`: warned first and standing where it
comes), so the badge is the whole of its notice: walking into the range never skips the badge
(`EventDef.may_be_set_off_at_once()`), and the badge goes up only where her running for the whole
of it, with the camera's lead swinging round, cannot bring the place into her sight
(`SetOffWatch`), so it never comes down without its bang (minty-dolphin #852). The bag's counts are
untouched, and so are the building's own explosions (`explosion_outside`).

**Why about 890 px.** Heading straight at one, at a walk or a run, she hears none of its bang, and a
runner is still out of its sight when its badge runs out. The first version set it off at the
field's own reach, 520 px: every bang that went off reached her (the review counted 17 `near`
lines on the branch against main's 6 over the probe's seeds), and a runner met the out-of-sight
check about 352 px from it as the badge ended, so the badge came down with no bang after it. A
second try at 780 px, the view's reach plus a run through the badge and the bang, kept walkers out
of every bang but let five bangs reach a runner against main's four. Holding a badge up past its
second until the place is out of sight was not taken: a badge is up alone for a second at most
(busy-quail #569; calm-kestrel #559).

**What it costs her, measured.** `tests/probes/escape_winnable.gd` on seeds 4242, 1 and 77, both
exits, the bag as built, counting the explosions whose field reached her in each walk's run log
(`near finale_explosion` lines, one explosion per place). At a run the walker was held at a run the
whole way and the meter at 0 (`--invincible`), since a runner from the start loses to crying in 10
to 15 s on both trees and meets almost nothing.

| | main | set off at 780 px | set off at about 890 px (this head) |
| --- | --- | --- | --- |
| Walking: bangs that reached her | 1 (from 194 px, where her walk began) | 0 | 0 |
| Walking: telegraphs alone that reached her (3.6 a second) | 4 | none (no telegraph) | none (no telegraph) |
| Running: bangs that reached her | 4 (first from 105 to 285 px, full strength) | 5 (first from 515 to 520 px, its field's edge) | 0 |
| Running: telegraphs alone that reached her | 7 | none | none |
| Badges, and badges withdrawn with no bang | none | — | 14 walking, 17 running; none withdrawn |

The walk outcomes are main's on every seed (to the tunnel 2 out and 1 lost, to the bridge 1 out and
2 lost). **An explosion now costs her less than on main**: on main the streaming brought one in
900 px out to telegraph 2.5 s, its telegraph emitting a share of its noise, and its bang reached a
runner heading at it at full strength; here nothing of it emits before the bang, and the bang is set
off far enough out that she meets it only coming at it from the side or turning toward it as it
bangs. The lever is `FINALE_EXPLOSION_SET_OFF_WITHIN`; bringing the cost back up to main's is the
player's call.

**Craters already there.** A crater is laid the moment its explosion goes off, not when the bang
ends, and on the very tick its place was found out of her sight (`EventStreaming.set_off()`), not
the tick after, when she may have stepped toward it; so no crater appears in her view and one she
walks toward is standing before she sees it.

**The flash.** Each explosion lifts the city's night light toward the colour the building's hallways
lift to when their windows flash (`BlastLight`), at brightness 0.6; the random distant flashes lift
it to 0.2 and follow the building's own timing (`FlashRhythm`). A flash rises over 0.05 s and fades
over 0.4 s. The HUD, badges and controls are never lit. Measured on a burst (the evidence folder
`snowy-goose-explosion-badge-flash-shake-2026-11-25`): an explosion set off at about 889 px lifts a
frame's mean luminance from 66 to 91 and it is back to base within about 0.5 s; the badge reads
about 42 m; the view is shaken by up to 3 px in the frames after the flash although the bang is
out of the noise's reach.

**The shake.** At most 3 px in world space (6 screen pixels), fading over 0.45 s, scaled by how near
the explosion goes off (`ViewShake.share_at()`): full on top of her, falling in a straight line to
nothing at `EventCatalogue.FINALE_EXPLOSION_FELT_WITHIN`, half as far again as it is set off (about
1335 px), so that a third of the full shake, 1 px, is still felt where an explosion goes off
furthest. **The shake's reach is its own, not the noise's**: scaled by the noise's 520 px it never
fired once explosions went off about 890 px out, since a straight approach never brings her within
520 px of one; now a near explosion out of her sight shakes the view without its noise reaching her,
and a test holds that a bang at the set-off distance shakes it. The burst shows up to 4 px of vertical jitter in
the 0.2 s after the bang. The game has no reduced-motion setting, so the shake has none to honour.

**Safe for viewers: no flash within 0.4 s of the one before, in the city.** The escape city starts no
flash within 0.4 s of the last one's start (`FlashRhythm.LEAST_GAP`), so no second holds more than
three; a test holds it over ten minutes of random bangs. **The building keeps the player's own
timing** (waits of 0.1 s to 5 s, mean 1.3 s, a double flash wanted, PLAYTEST-96 5, plus a bang every
22 s): 20,000 simulated building walks show 6.3% with at least one second holding four flashes,
rarely five. Holding it to the city's limit would narrow the player's own spec, so it is not built
until they answer the question on the Nappy board (building-flash-limit).

**Choices left open to the player** (the review item asks them with the stills):

- The flash brightness (0.6 for an explosion, 0.2 for a distant flash) and the shake (3 px over
  0.45 s). Both are the builder's first values, shown to the player before they ship as the entry
  proposed.
- The set-off distance (about 890 px) and the 1 s badge, and with them that an explosion now costs
  her less than on main (the table above).
- The shake's reach (about 1335 px, a third of the shake at the furthest set-off), the builder's
  first number.
- The building's flash limit waits on the player's answer on the board (building-flash-limit); the
  building's flashes keep their own curve until then.
- No extra craters at the section's start: the escape's seals already stand some there.
- A badge for something that is neither lethal nor faster than a walk: the cues skill keeps its rule
  (lethal or faster than a walk) and names the explosion as the player's explicit ask
  (minty-lemur #785); that the code asks it as a kind of thing (`EventDef.comes_all_at_once()`) is
  listed in that skill as the builder's proposal. `.claude/skills/events/references/warned-first.md`
  covers the explosion, when walking in skips the badge, and that such a badge goes up only where it
  cannot come down without its bang; the **events** skill's exemption from the solid rule reads
  "nothing drawn in the world" rather than "no silhouette".

**Rejected while building.** Drawing the mushroom on the street where it goes off (the picture the
player likes is a badge). Laying the crater when the bang ends (it appeared in her view). A first
version of the finale crater test left a city behind for later suites and made 109 checks fail; the
test was rewritten to clean up.
