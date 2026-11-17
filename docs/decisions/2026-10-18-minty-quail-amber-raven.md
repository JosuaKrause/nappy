# minty-quail — The HUD reads the home arrow and the meter bar through methods · 2026-11-16

**The ask.** "Never read fields directly, always through a method" (inbox #1173 in gray-dolphin), `field-reads.md`'s rule, for
the HUD's reads of the home arrow and the meter bar and of `FrameGraph.text_colour`. This is the pull request #1479.

## What was built

- **`HomeArrow`**: `colour`, `label_when_near` and `rotated` become `_colour`, `_label_when_near` and `_rotated`, handed in by
  `use_look(colour, label_when_near)` and `use_rotated(rotate)`.
- **`MeterBar`**: the exported `label`, `fill_colour`, `full_colour`, `markers` and the `value` property become private fields
  behind `use_look(label, fill, full)`, `use_markers(markers)` and `show_value(value)`, the clamp and the redraw gate moving with
  it. No scene sets the exports (`scenes/ui/hud.tscn` only attaches the scripts).
- **`FrameGraph`**: `text_colour` becomes `_text_colour` behind `use_text_colour(colour)`.
- `tools/field_reads.txt`: the nine lines for these readers and the three emptied group headers are deleted; none is added. The
  readers are the HUD and the debug readout, view-layer callers of the same layer.

## Measured

The search for the old names read without parentheses
(`rg -P '\.(colour|label_when_near|fill_colour|full_colour|markers|text_colour)\b(?!\()' src tests tools -g'*.gd'`) finds no read
of these classes' fields from outside their files; `rotated`, `label` and `value` are too common to grep and are held by the
typed field-read check, which is green. `test_hud.gd` (the real HUD's `_ready()` makes every call) and `test_frame_record.gd`
pass. The look fingerprint was not run: the same colours, word, markers and clamp feed the same `_draw()`.

## Rejected, with the reason

- **A getter named for each field** (designing-classes names a replacing method after the field): these fields are only ever
  written by the HUD and read by nobody outside, so a getter would have no caller. A hand-in setter in the repository's `use_*`
  form (`Stroller.use_atlas()` is the model) is the shape; `rotated`, being yes-or-no, has a replacing name its field did not
  have, as the rule asks.
- **A new test**: the methods hand a drawn control its look and a headless run draws nothing and exposes none of it, so a check
  would read back what the test set, or reach a private field. The reviewer agreed. A preference left standing: `Hud.set_rotated()`
  and `HomeArrow.use_rotated()` forward one flag under two verbs.
