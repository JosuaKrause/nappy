The escape's clock shows a precision its label actually keeps up with, the one the player picks
(the README's open question), and the label is rewritten as often as that precision changes. A
day's clock keeps M124's once-a-second emission. A test drives the escape's `DayController` through
frames inside one second and asserts the label shows what the picked precision says it should, and
that a day's controller still emits once a second. The doc comments at `DayController`'s throttle,
`GameState.format_clock()` and the HUD's clock, and `docs/MECHANICS.md`'s "The clock reads to the
millisecond" paragraph, say what is built.

*Proposed, not asked for:* hundredths, rewritten every frame (the README's filer's pick).
