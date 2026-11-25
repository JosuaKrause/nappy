# minty-quail — A run's parts reached through methods, each part's fields behind methods · 2026-11-17

**What it is.** One bullet of minty-quail's `field-reads.md`, "A run's parts": the run's state
(`RunState`) handed out its parts as fields, and a read through one was two field reads. The
design and the conversion were an Opus builder's; a Sonnet builder verified it and opened it. It
changes nothing in play: saves load as before (a save written by main still loads), the run-log
lines are byte for byte, and `to_data()` and `restore()` are untouched.

**What was built.** Every part of the run is private behind an accessor that keeps its old name
(`header()`, `calendar()`, `resistance()`, `attempt_spend()`, `facts()`, `posters()`,
`pelican()`, `run_parts()`), and each part's fields are private behind methods: a value's getter
keeps the field's name, a yes-or-no question takes a new one (`parent_is_father()`,
`in_hard_mode()`, `sabotage_went_through()`, `is_carrying_package()`, `has_completed()`), and a
change is told by a method each with a game caller (`count_a_play_tick()`, `record_the_sabotage()`,
`pick_up_package()`, `block_on()`, `count_a_draw()`, `mark_pasted_through()` and the rest).
`tools/field_reads.txt` lost every line of the run's parts and gained none. The run's state no
longer names the resistance's happenings for the neighbor's raid day, a standing layer break
polite-tapir gave to this work: the day (10) is the resistance's steps' (`ResistanceSteps.NEIGHBOR_DAY`),
a data class, and the break's entry in `tools/layer_map.py` is gone. Tests set a part's
list or count through `tests/given_run.gd`, which edits one part through its own `to_data()` and
`restore()`, the path a loaded save takes, so the game gains no setter only tests call.

**Proposed, not asked for, open to the player:** the attempt spend, the pelican and the posters
converted with the five classes the bullet names, since they are parts of the run the same way; a
list getter answering the live list rather than a copy, since the events append to the one-shot
list they are handed; `settled` with no accessor, since only the calendar reads it; most readers
still handed the whole run rather than the part they need.
