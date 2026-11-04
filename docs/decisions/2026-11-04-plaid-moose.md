# plaid-moose — The verify skill says how to design a unit test · 2026-11-04

The player's guidance on designing a unit test, from the board question drawn-art-tests and what
followed it (inbox #1018 in brisk-ferret), done up next as the player asked (inbox #1024 in
brisk-ferret).

**Built.** The **verify** skill's "Testing policy" opens with the guideline, worded as guidance
rather than a hard rule: a test is designed around one isolated component; a component another
suite already tests is not retested; correctness is confirmed by injecting a component's
dependencies through the paths the game uses; and a private read or an escape hatch in a test is a
sign to look again, of testing too much at once, of not injecting as intended, or of testing
internals where outside behaviour matters, those being examples rather than the only reasons.

**Open to overturn:** its place, the head of the testing policy, and its wording; the player named
neither.
