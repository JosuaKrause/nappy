# polite-swan — A run button beside each joystick focal point · built 2026-10-03

*([minty-hedgehog](../playtests/2026-10-03-minty-hedgehog.md), statement 5, note #434: "for
joystick mode a dedicated run button (one on each side next to the joystick) would make running
much more precise and easier. the button should not trigger when moving the finger over it from
navigation and holding the button and navigating should work correctly. also the double tap should
still work since mouse only navigation would otherwise break.")*

**Built (PR #472).** In joystick mode a run button stands 110px outward of each focal point, on
the focal row: `RUN_CENTRE_LEFT` (130, 480) and `RUN_CENTRE_RIGHT` (1150, 480) in
`src/ui/touch_controls.gd`, drawn 34px in radius (`RUN_RADIUS`) and caught within 46px
(`RUN_CATCH_RADIUS`), below the 62px that would reach the 48px stop ring. A press that begins on a
button holds `run` until that finger lifts, wherever it lifts, and is never also a heading, so the
other hand's drag and the double-tap clock are untouched. A steering finger that slides onto a
button does not press it, because only a press grabs a button. The double press that latches
running stays; the latch and the hold are independent, so lifting the button keeps a latched run
and stopping keeps a held one. A pause, a day ending or switching to tap mode lets go of a held
button. The buttons exist only in joystick mode. The glyph is `art/ui/run.svg` (a disc, a rim, two
chevrons), in the `ui` atlas group.

**What it collides with, and why nothing is overturned.** PLAYTEST-28 (2026-09-06) removed the held
RUN circle at (1150, 500) when running became a double press ("double press keeps running"). This
brings a button back as a second way to the same action and keeps the double press.

**Proposed, not asked for, and open to overturn:** running lasts while the button is held, rather
than a press latching it as the double press does (the filer's proposal); the 110px offset; the
34px radius and 46px catch; a second finger landing on a button while another already holds one is
swallowed rather than read as a heading; the glyph is two chevrons with no text.

**Verified.** `tests/test_touch.gd` covers the geometry clear of the rings, a hold until lift,
steering and stopping while holding, a steering finger sliding onto a button, the latch surviving a
lift, no button in tap mode and a pause letting go. The still is
`docs/evidence/run-buttons-2026-10-03/joystick-run-buttons.png`. How the buttons feel under a thumb
is the player's to judge: [the review item](../review/2026-10-03-polite-swan.md).
