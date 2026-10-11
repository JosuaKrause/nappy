**An input held through a hold's release keeps steering her; only one lifted during the hold
resets her to standing still.** A finger kept down on the screen keeps updating her heading as it
moves, from the frame the hold lets her out ("basically keep updating navigation"), and a key kept
down keeps her walking that way ("Keyboard holding is the same as finger holding"). A finger or key
lifted at any point during the hold leaves her standing still when it lets her out, as downy-lark
built. It holds for every `redetains` hold, the street doors' gatehouses and the alley guard's,
since they are one mechanism.

*Open, for whoever picks it up:* what a tap that locked a heading before the hold does when no
finger is down at the release. The note speaks of a finger still on the screen; a tap's locked
heading with the finger already up reads as "lifted" and resets, which is the filer's reading.

Update `tests/test_checkpoints.gd`'s `_test_she_stands_still_when_a_hold_lets_her_out` into its two
halves (held through: she moves the first frame after the release, in the held direction, for a key,
a held finger and a joystick drag; lifted during the hold: she stands still), and the hold paragraph
in `docs/MECHANICS.md`.
