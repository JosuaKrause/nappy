# The 5% button reach and the catches it shrank

**Medium, a question for the player · from the re-review of PR #603 (round-gecko, the unused
joystick becomes Run).** The player asked for "the effective radius of all buttons … 5% over the
visual radius" because buttons were "easy to miss". Applied exactly, it made the existing catches
smaller: pause's `PAUSE_CATCH_RADIUS` went from 46px to 27.3px, about 35% of its old area (the
release that fires pause uses it too, so a thumb has less room before it cancels), and the title,
pause-screen and summary buttons' `ModeButton.contains_design_point()` went from a 122.7px square to
a 48.3px circle, about half the area. The round-gecko record gives only the new numbers.

**Answered by the player** (inbox #648 in [leafy-puffin](../../playtests/2026-10-10-leafy-puffin.md)): "why does the button reach decrease
anything??? the 5% should go over the visible size making the area *larger*!" Read as, open to
correction: every catch is at least 5% beyond its drawn size and never smaller than it was before
round-gecko, so each is the larger of its old catch and 1.05 times its drawn radius, in all three
places (pause, Run, and the round title, pause-screen and summary buttons). Whichever the answer, the phone
review [leafy-marten](../../review/2026-10-10-leafy-marten.md) says the catches changed.
