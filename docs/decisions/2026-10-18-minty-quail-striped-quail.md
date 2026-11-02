# minty-quail — The save is a node the Sitting keeps, and the run config is held by main (hidden statics) · 2026-11-02


minty-quail's `hidden-statics.md`: the save's statics and the run configuration's boot copy. The item
stays open for the statics read across the tree.

**Built.**
- `GameSave`, a `RefCounted` of static functions, is a `Node` (`GameSave.NODE_NAME`) that `main` makes
  on the first boot and parks as a child of the `Sitting`, which outlives a scene reload as the web
  flush, its callback and the operation ids must. Its web interface, flush answer, flushes, last
  operation, last tick and configuration are instance fields; the pure parts (`Result`, the
  constants, `file_data()`, `moment_result()`, `Flushes`) stay static. The `Sitting`, on the model
  layer, holds it as an unnamed child, as it holds the save symbol, and `main` finds it by name each
  boot.
- `_path_override` and `set_path_override()` are gone: a save is made at its path
  (`GameSave.new(file_path)`), and a suite builds one at a scratch path and hands it to its boots
  through `main.use_save()`. The runner resets none of the save's fields.
- `RunConfig._at_boot` is gone: `RunConfig.at_boot()` parses the command line and the page query on
  each call, and `main` holds the result for its boot.

**Open to overturn** (the builder's choices where the brief was silent): the save as a node under the
`Sitting` rather than an autoload (the brief took it for one; it was not); `at_boot()` re-parsing the
page query once per scene reload on the web; `main._ready()` taking the sitting before it wires the
save's end-of-run clearing.

**Not measured:** the web flush was checked by reading only; a web export with a save and a held
restart while a flush is pending belongs to the remeasuring step.
