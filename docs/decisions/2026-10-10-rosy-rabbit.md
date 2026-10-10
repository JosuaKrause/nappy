# rosy-rabbit — The joystick's dead zone is 16px and not drawn · 2026-10-10 · not from an entry

[Pebbly-alpaca](../playtests/2026-10-10-pebbly-alpaca.md), playing v0.26.0: "why is the deadzone so
big now?" · "I asked you to make it smaller". [Leafy-marten](2026-10-10-leafy-marten.md) had taken
the joystick's dead zone (where a press stops her) from the 48px stop circle to 32px for the
player's "decrease the deadzone of the joystick (which makes the player stop) smaller/tighter",
which named no number. The player then named one: "we can try 16px to keep the deadzone
consistent", and, told that tap mode's matching stop circle round her was 16 world px and so 32px
on screen, "but 32 is just wrong".

**Built in PR #661** (`src/ui/touch_controls.gd`):

- **`DEAD_ZONE_RADIUS` is 16 design px**, and never takes the buttons' 5% catch: "also the 5%
  increase doesn't apply to dead zones *only* to buttons".
- **Tap mode's stop circle stays tied to it**, as playtest 34 had it ("the stop circle on the player
  should exactly be the size of the joystick stop circle nothing bigger"): `TAP_STOP_RADIUS` is half
  the dead zone, 8 world px, the same 16px on screen at zoom 2. *Read as, open to correction:* "32
  is just wrong" asks for both circles at 16px on screen. It is now smaller than her 14px body
  radius, so tapping her to stop needs a press near her middle; the pram's side-view centre stays
  outside it. (Asked earlier whether tap mode should follow when the dead zone was to be the dot's
  size, the player chose to keep it at 16px; the later answers set both at 16px on screen.)
- **The dead zone is not drawn**: "also don't draw the dead zone". The ring, the knob at rest and the
  knob while she walks stay.
- **The knob's walking position is its own constant**, `_FOCUS_KNOB_OFFSET`, 36px from the focus,
  where it was before: "the position where the dot it drawn should be independent of the deadzone
  -- those two have no relation". It was derived from the dead zone and would have moved to 24px.
- The stop band at the steering half's edge (`is_in_stop_band()`, 48px either side) is unchanged,
  and a release inside the dead zone still stops her.

`tests/test_touch.gd` holds the 16px dead zone, a press at 1.01 times it steering, tap mode at half
of it, and the running knob inside the ring. The stills of the joystick at rest and while she walks
are in [dead-zone-2026-10-10](../evidence/dead-zone-2026-10-10/). The phone review item
[leafy-marten](../review/2026-10-10-leafy-marten.md) asks about the 16px dead zone.
