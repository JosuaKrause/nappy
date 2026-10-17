priority: bug

# crisp-owl — The escape clock shows what it can update · filed 2026-10-17

[fluffy-kestrel](../../playtests/2026-10-17-fluffy-kestrel.md), #742, "Millisecond precision timer
doesn't update fast enough":

> No point in showing the timer as milliseconds in the escape since the refresh rate is lower than that

**What is wrong.** The escape's clock is formatted `%d:%02d.%03d` by `GameState.format_clock()`, as
the player asked on 2026-09-09
([M102, the finale's brief](../../decisions/2026-09-09-M102-the-finales-brief-and-the-collisions-the-player-answered.md),
point 3: "the only change is that in addition to minutes and seconds the timer also shows
milliseconds. this makes the timer appear faster than just the seconds alone which adds additional
tension."). But the HUD rewrites the label only on `EventBus.day_time_changed`, and
`DayController._process` emits that only when the whole second shown changes (M124's throttle, commit
367f94a3, "the day clock emits only when the second shown actually changes"). The escape's clock is
a `DayController` too, so its label changes once a second and the three digits after the point are
whatever they were when the second flipped: they sit still, then jump.

**Open, asked of the player:** the precision the escape shows. The note can be read two ways —
its title says the timer "doesn't update fast enough", its body that milliseconds are pointless —
and the filer reads it, unconfirmed, as: three digits change faster than a 60 Hz screen can show.
The choices are
hundredths (`2:59.43`, a digit that moves every frame and keeps the faster-looking clock M102
asked for; the filer's pick), tenths (`2:59.4`), or whole seconds (`2:59`, which drops M102's
"appear faster" and would overturn it). The ending screen's run length (M107, "all endings show the
game timer -- with millisecond precision") is a still number, not a ticking one, and the note says
"in the escape"; it stays at milliseconds unless the player says otherwise.

Item: [the-escape-clock-shows-what-it-updates.md](the-escape-clock-shows-what-it-updates.md).
