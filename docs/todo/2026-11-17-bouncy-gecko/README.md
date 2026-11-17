priority: later

# bouncy-gecko — A headless test run drops the engine's frame sleep, if it pays · filed 2026-11-17

**Where it comes from.** No words of the player's: the fixer of #1487 (a sent row's route worked out
as it goes) found it on 2026-11-16, and the filer proposes the entry and its band.

**What was found.** A headless Godot engine sleeps about 6900 microseconds on every frame it cannot
draw (its frame sleep, `OS.low_processor_usage_mode_sleep_usec`), which holds every tick
to about 6.9 ms whatever speed-up a suite asks for. `tests/test_sent_rows_keep_to_the_road.gd`
lowers it to 200 microseconds for its walk, which took that suite from 108 s to 40 s.

**Item:** `frame-sleep.md`.
