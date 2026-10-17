The escape's clock label is rewritten every frame, at the precision the player picks (the README's
open question), while a day's clock keeps M124's once-a-second emission. A test drives the escape's
`DayController` through several frames inside one second and asserts the label differs between
them, and that a day's controller still emits once a second; it fails on today's code. The doc
comments at `DayController`'s throttle, `GameState.format_clock()` and the HUD's clock, and
`docs/MECHANICS.md`'s "The clock reads to the millisecond" paragraph, say what is built.
