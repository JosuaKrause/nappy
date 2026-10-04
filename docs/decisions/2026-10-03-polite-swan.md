# polite-swan — A run button beside each joystick focal point · built 2026-10-03

*([minty-hedgehog](../playtests/2026-10-03-minty-hedgehog.md), statement 5, note #434: "for
joystick mode a dedicated run button (one on each side next to the joystick) would make running
much more precise and easier. the button should not trigger when moving the finger over it from
navigation and holding the button and navigating should work correctly. also the double tap should
still work since mouse only navigation would otherwise break.")*

**Built (PR #472).** In joystick mode a run button stands 110px inward of each focal point, toward
the middle of the screen on the focal row: `RUN_CENTRE_LEFT` (350, 480) and `RUN_CENTRE_RIGHT`
(930, 480) in `src/ui/touch_controls.gd`, drawn 34px in radius (`RUN_RADIUS`) and caught within
46px (`RUN_CATCH_RADIUS`), below the 62px that would reach the 48px stop ring. The spot is the
player's: shown four candidates on a layout picture, they chose "Inward" (inbox #477 in [quiet-yak](../playtests/2026-10-03-quiet-yak.md)) and, having
seen it on the phone, "blue is correct" (inbox #478). It takes the "walk toward the middle" press
64–156px out of a ring, about a ±25° wedge, which a press further out or to the side still steers;
it is clear of the screen-edge badge strips, the home and task arrows, the HUD meters and the pause
button. The first build stood the buttons outward, where they took the "walk outward" press and a
held thumb covered the danger badges at the screen's edge. A press that begins on a
button holds `run` until that finger lifts, wherever it lifts, and running lasts while any finger
holds either button, so changing hands does not drop it; and is never also a heading, so the
other hand's drag and the double-tap clock are untouched. A steering finger that slides onto a
button does not press it, because only a press grabs a button. The double press that latches
running stays; the latch and the hold are independent, so lifting the button keeps a latched run
and stopping keeps a held one. A pause, a day ending or switching to tap mode lets go of a held
button. The buttons exist only in joystick mode. The glyph is `art/ui/run.svg` (a disc, a rim, two
chevrons drawn pointing up), in the `ui` atlas group.

**What it collides with, and why nothing is overturned.** PLAYTEST-28 (2026-09-06) removed the held
RUN circle at (1150, 500) when running became a double press ("double press keeps running"). This
brings a button back as a second way to the same action and keeps the double press.

**Proposed, not asked for, and open to overturn:** running lasts while the button is held, rather
than a press latching it as the double press does (the filer's proposal); the 110px offset; the
34px radius and 46px catch; a second finger landing on a button counts as holding it rather than
being read as a heading; the chevrons point up, since chevrons pointing toward the middle would read
as "walk that way"; the glyph has no text. The day-1 hint still says "Tap to walk, double tap to
run" and does not mention the buttons.

**Verified.** `tests/test_touch.gd` covers, through the real input path, the geometry clear of the
rings, a press past the button still steering, a hold until lift, steering and stopping while
holding, changing hands, a steering finger sliding onto a button, the double press as two mouse
clicks, the latch surviving a lift, no button in tap mode and a pause letting go;
`tests/test_orientation.gd` keeps a rotated press west of the left ring walking west. The still and
the layout picture the player chose from are in `docs/evidence/polite-swan-run-buttons-2026-10-03/`.
How the buttons feel under a thumb is the player's to judge:
[the review item](../review/2026-10-03-polite-swan.md).
