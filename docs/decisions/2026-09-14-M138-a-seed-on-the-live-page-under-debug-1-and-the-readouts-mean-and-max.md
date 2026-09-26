## M138 — A seed on the live page under `?debug=1`, and the readout's mean and max · built 2026-09-14

*(2026-09-14, [PLAYTEST-72](../playtests/PLAYTEST-72.md): "setting seed should be possible with
debug=1" — "that would keep the real game clean still"; and, to the readout mean recommended
beside it, "sure, we can print other values, too".)* Three agent commits on
`feature/m138-seed-query`, reviewed on the PR; the still is
`evidence/m138-readout-columns-2026-09-14/readout.png`.

**`?seed=N` is the fourth release-safe query flag, and the second under the note.** It is read
by `DevFlags.seed_override()` only when the command line's `--seed` is absent, through
`_seed_from_query()`, which checks `?debug=1` in the same query string before it looks for
`seed` at all and returns the "not given" sentinel `0` otherwise — so a page without the DEBUG
MODE note never takes a seed, the way it never skips a family. A present value that is not a
positive integer (`0`, a negative number, `abc`, an empty `seed=`) is refused with a warning
naming the value and treated as not given; an absent `seed` parameter says nothing, so an
ordinary `?debug=1` page does not warn on every load. The command line's own `--seed` keeps
`enabled()`'s gate and its unbounded value. The doc comments on `enabled()`,
`readout_requested()` and the class head, which said a seed stays unreachable from the address
bar, now say what is true: the readout's own gate carries the readout, `--skip`/`?skip=` and a
positive-integer seed, and nothing else. The 2026-09-06 rule that a release page carries no
modifiers (M76) stands for a page without the note.

**The gate and the parse sit in one function.** `_skip_from_query()` and
`_validate_skip_words()` are two; `_seed_from_query()` is one, because the gate — `?debug=1`
*in the same query* — is part of what a release-shaped test has to drive, and the suite has no
web runtime to drive the real `readout_requested()`. The agent's choice, noted in the doc
comment; open to overturn if a third flag under the note wants the split.

**The readout's `process` and `physics` lines carry `last`, `mean` and `max` over the last
second.** `FrameCost.sample(now_seconds)` is called once a frame by `main.gd`, only while the
readout is on and right where the readout's own block is gated, with `Time.get_ticks_msec()`
rather than the day clock, so the window keeps moving through a pause, a compressed day and
`--invincible`'s frozen clock: it measures wall-clock stutter, not game time. The window takes
the time from the caller the way `line()` takes `worst_frame_seconds`, so a test drives it with
known times; an empty window falls back to the instantaneous reading rather than a zero that
would read as free. The run log's once-a-second `frame` entry is unchanged — a mean over the
second it already samples at would be no different a number — and `tests/test_performance.gd`
asserts that asymmetry explicitly: the three labels appear on the readout and never in `line()`.

**The lines were clipped, and the fix is 90px and a decimal.** At two decimals the two lines
ran to 51 characters from a label at x 1050 in a 1280-wide viewport whose edge, not the label,
does the clipping — the `max` column, the one the item exists for, would have been off screen
on every device. The label now starts at x 960 (300px rather than 214) and the values print at
one decimal, 48 characters; the still shows both lines whole with margin, and nothing else is
drawn in that strip (the clock is centred, the meters are bottom-left, the home arrow's nearest
approach to that corner was already inside the old bounds). What only a phone can say — whether
the widened block still clears the touch controls in portrait, and whether `?debug=1&seed=N`
answers on the live page — is in `REVIEW.md`.
