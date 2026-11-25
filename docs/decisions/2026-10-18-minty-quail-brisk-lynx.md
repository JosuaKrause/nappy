# minty-quail — The run's configuration answers through its methods, its readers outside main.gd first · 2026-11-18

**What it is.** The first of two pull requests for the run's configuration (`RunConfig`, what the
command line and the page's address asked for this run: the developer's flags, overrides and rig
switches) in minty-quail's `field-reads.md` conversion: its 51 fields were read 60 times from
outside its file. This one settles the shape for the whole class and converts the 21 reads outside
`main.gd` (the auto screenshot, the debug readout, the rig lock, the scene recipe runtime, the day
director, the run log's session). An Opus builder designed and built it. It changes nothing in play;
every flag does what it did.

**The shape, and what was weighed.** One method per field, the configuration handed whole, which is
how its other readers (the run log, the save, GoatCounter, touch, quit, the web display) already
work. A part per reader was weighed and rejected: the readers' needs overlap (the screenshot's path,
whether a movie is recording, `--spikes`), so any cut repeats a fact in two parts or hands a reader
several. Plain values at construction were weighed and rejected: several answers combine flags
(`day_length_for(day)`, `rig_quit_seconds()`, `screenshot_rig()`), which a reader handed values
would work out again.

**What was built.** Twelve fields are private: value fields keep their names (`screenshot_path()`,
`skip_words()`, `layers_override()`, `spawn_target()`, `meters_override()`, `rig_after()`,
`recipe_manifest_path()`, `recipe_draft_path()`), yes-or-no fields take new ones
(`refuses_telemetry()`, `asks_for_spikes()`, `validates_the_recipe()`), and `readout_requested`
reads through the existing `asks_for_the_readout()`. Six fields `main.gd` still reads stay public;
the six readers here use their methods (`dev_flag_words()`, `is_debug_build()`, `runs_as_a_rig()`,
`records_a_movie()`, `asks_for_the_player_view()`, `plays_the_recipe_scripted()`). `main` builds
and hands on what it did. `tools/field_reads.txt` lost 21 lines and gained none.

**Left:** `main.gd`'s 39 lines, the second pull request, as minty-quail's `field-reads.md` says.

**Proposed, not asked for, open to the player:** one method per field over the two other shapes; the
method names; a method beside each still-public field, so those facts read two ways until the second
pull request.
