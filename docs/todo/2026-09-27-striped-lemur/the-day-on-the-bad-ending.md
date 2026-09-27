The `BAD` ending screen carries a line naming the day the run made it to: the last day played,
not the last day completed *(2026-09-27: "Yes the last day played. Not the last day completed. So
if you die on the first day it says 1 and not 0")*. It is the day she was walking when the last
nerve went, the same number the HUD and that day's brief showed for it: 1 if the nerves ran out
on day 1, 9 if on day 9. It sits beside "Time played" under the body text, and only the `BAD`
ending gets it; the neutral and good endings are reached by finishing day 14 or the escape, where
the day says nothing.

**Proposed, not asked for:** the wording, "You made it to day %d.", in the plain voice of the
other lines.

A run that ends on a load that spends the last nerve (`docs/MECHANICS.md`, "the day brief never
shows at all — the ending does") names the day that load was for. A test in the day summary's
suite shows the line with the day on a `BAD` ending and its absence on the other two. The
evidence is one still of the screen, taken with a dev flag that ends the run on a chosen day.
