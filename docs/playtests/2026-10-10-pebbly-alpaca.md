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
