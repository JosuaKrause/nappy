# azure-quail — The play time keeps counting across every go-back · 2026-11-01 · not from an entry

The run's play time (`RunHeader.play_ticks`, shown on the ending screens) keeps counting across
every go-back to a checkpoint, checkpoint zero included, and across a retried day. Only a new game
starts it at zero: one from the title, or the held restart, which clears all state including the
timer and boots to the title. The player asked for it (inbox #920).

**This overturns an open choice in [quiet-lynx](2026-10-11-quiet-lynx.md)**, which listed "play time
is part of the checkpoint" under "Open to overturn": the checkpoint no longer holds the time, so
going back no longer takes it back. The checkpoint is otherwise still the exact state of the run at
the dawn. Overturned on 2026-11-01.

**Which paths were wrong before.** Back to checkpoint zero zeroed the time, since the go-back reset
the whole registry. Back to a later checkpoint put the dawn's older time back. A save continued
after either held that wrong time. A lost day's retry already kept it (the header is not spent by
an attempt) and is now pinned by a test. The time is carried by the go-back itself, not by the
reset, so the reset a new game shares with checkpoint zero still zeroes it.

