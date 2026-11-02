# minty-quail — What outlives a scene reload is held by one Sitting the game parks across it (hidden statics) · 2026-11-02


minty-quail's `hidden-statics.md`, the state that has to outlive `reload_current_scene()` (a held
restart, the day-14 hand-over to the escape, a checkpoint carry, a recipe section retried). The item
stays open for the statics read across the tree.

**Built.**
- `Sitting` (`src/autoload/sitting.gd`, a plain `Node` on the model layer, not an autoload) holds
  `controls_word` (from `ControlsMode._remembered*`: the title's answer kept as the `--controls` word,
  read back through `ControlsMode.from_word()` and `side_from_word()`), `restarted_at_msec` and
  `note_restart_requested()` (from `TitleScreen`), `frame_record_path` (from
  `FrameRecorder._native_path`: one desktop file per sitting, across a restart too) and
  `carry_the_run_over` (from `Main`), and is the home the save symbol is carried in
  (`SaveIndicator._home_override` and `use_home()` are gone; `outlive_the_scene(home)` and
  `carried(home)` take it). `FrameRecorder._save_callback` is an instance field.
- `main` takes the `Sitting` handed through `use_sitting()`, else the one parked in its home
  (`use_sitting_home(node)`, the tree's root by default), else builds one; `_reload_the_scene()`,
  which every reload goes through, parks it there first, before a test's own reload too. `main`
  hands it to the title, the recorder and the symbol; nothing below `main` fetches it.
- A test of a lone title, recorder or symbol hands in a fresh `Sitting`; the held-restart, day-14 hand-over and checkpoint tests boot
  the next `main` with only the home, checking it took the parked one (with the park or the lookup
  removed, 15 and 8 checks fail). The runner resets none of these fields.

**Open to overturn** (the builder's choices where the brief was silent): a node `main` parks rather
than a new autoload (an autoload is fetchable from anywhere) or `GameState` (a held restart throws
the run away, and these facts outlive it); the file under `src/autoload/` though it is not an
autoload; the controls kept as a word, so the model-layer owner names nothing in the view. Finding
the parked `Sitting` by name in its home is the composition root's one lookup per boot, judged
acceptable in review; `change_scene_to_node()`, which would let `main` build its successor and hand
it the sitting, is the alternative not taken, as a larger change to the reload path.

**Not measured:** the web save button's callback (now held by the recorder that registers it) was
checked by reading only; a real browser run of the frame record's save button belongs to the
remeasuring step.
