# striped-lemur — The game over screen shows the day you made it to · built 2026-09-27

*([round-moose](../playtests/2026-09-27-round-moose.md), statements 4 to 6: "Oh bad ending game over
screen should show the day that you made it to" · "Yes the last day played. Not the last day
completed. So if you die on the first day it says 1 and not 0")*

**Built (PR #410).** `DaySummary.show_ending()` takes the day, and on the `BAD` ending only it adds
"You made it to day N." under "Time played". Every caller passes `GameState.day`, which never moves
past the day a run ends on, so the ending and the day brief read the same number. The wording was
the filer's proposal and was built as proposed.
