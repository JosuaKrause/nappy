# Playtest pebbly-alpaca — The joystick's dead zone is the size of the dot

2026-10-10.

Said in a session on the day v0.26.0 was released, playing it:

> why is the deadzone so big now?

> I asked you to make it smaller

The session found the dead zone (`TouchControls.DEAD_ZONE_RADIUS`) at 32px, down from v0.25.0's
48px stop circle by the player's earlier "decrease the deadzone of the joystick (which makes the
player stop) smaller/tighter", where no number was named; the player:

> make it the size of the dot

The dot read as the knob drawn at the steering focus while she stands (`_FOCUS_KNOB_RADIUS`, a
third of `PAUSE_RADIUS`, about 8.7px). Asked whether tap mode's stop circle round her, tied by
playtest 34 to "exactly the size of the joystick stop circle nothing bigger" (16 world px today,
about 4.3 if it followed), should shrink with it, offered "Keep tap at 16px (Recommended)" and
"Shrink tap with it", the player chose:

> Keep tap at 16px (Recommended)

Then, while it was being built:

> also the 5% increase doesn't apply to dead zones *only* to buttons

> we can try 16px to keep the deadzone consistent

Told that tap mode's 16 world px is 32px on screen at zoom 2:

> but 32 is just wrong

Read as both stop circles being 16px on screen, the joystick's 16 design px and tap mode's 8 world
px, open to correction. And:

> also don't draw the dead zone

Told that the knob's walking position was derived from the dead zone and would move from 36px to
24px:

> no, the position where the dot it drawn should be independent of the deadzone -- those two have no relation

**Filed as:** [rosy-rabbit](../decisions/2026-10-10-rosy-rabbit.md), built in PR #661.
