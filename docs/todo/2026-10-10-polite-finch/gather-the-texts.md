# Every text the game shows lives in one catalogue

The player's ask is a text catalogue in place of texts spread across the codebase: one place that
holds every sentence the game puts on screen, so a text can be found, read beside the others and
changed without hunting for the code that shows it.

What counts is every player-facing string: the title and pause screens, the help lines (button
symbols included as the tokens `HelpText` already uses), the day briefs, the HUD's task line, the
loss and summary lines, the endings and the finale's body, the chalk mark's big message, the event
catalogue's texts, and the indoor lines. A developer readout (`?debug=1`, the dev overlay) and a
log line are not player-facing and stay where they are.

**Proposed, not asked for:**

- **The form: one GDScript file of constants, `src/ui/texts.gd` (`class_name Texts`)**, grouped by
  screen with a comment per group saying where the text is shown, and every caller reading
  `Texts.<NAME>` instead of a literal. A text with a value in it (a clock reading, a day number)
  is a format string there, filled where it is shown. The plainer alternative is a doc listing
  where each text lives, which goes stale the moment a string moves; a resource or JSON file is
  the heavier one, and loses the compile-time check a missing constant gets. Godot's own
  translation tables (`.po`/CSV through `tr()`) would also be one place, but they carry a
  translation workflow nobody asked for.
- **A check that nothing slips back**: a test, or a `tools/lint.sh` rule, that fails on a quoted
  sentence (say, a capital letter, a space and a period inside quotes) in a `src/` file other than
  the catalogue, with an allow-list for the readouts and logs.
- **Names are content, never identifiers** (`CLAUDE.md`): the catalogue holds the mother's and the
  baby's names only inside strings, if any text uses them, never in a constant's name.

`docs/MECHANICS.md`, `docs/NARRATIVE.md` and any other doc that quotes a text keep quoting it; the
catalogue is where the code reads it from. Name the catalogue in `docs/ARCHITECTURE.md`.
