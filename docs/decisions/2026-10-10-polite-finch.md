# polite-finch — One catalogue holds every text the game shows · 2026-10-11


[mossy-beaver](../playtests/2026-10-10-mossy-beaver.md), inbox #650: "yeah we need a text catalogue
instead of spreading it all across the codebase", and, on a text that broke onto three lines where
two were asked for (the [feathery-puffin](2026-10-10-feathery-puffin.md) record): "I can't find the
exact text (we need that catalogue)".

**Built.** `src/ui/texts.gd` (`class_name Texts`) holds every text the game shows as constants,
grouped by screen with a comment per group saying where it is shown: the title and pause screens,
the HUD's lessons, meter labels and task line, the fourteen day briefs, the summary and loss lines,
the resumed-day notes, the endings, the finale and the escape's lines, every chalk mark's brief,
title and header, and the event rows' names. A text with a value in it is a format string there,
filled where it is shown. Callers read `Texts.<NAME>`; the title, pause and day-summary scenes no
longer carry shown text, their scripts set it in `_ready()`. `docs/ARCHITECTURE.md` names it.

**The check** is `tests/test_texts_catalogue.gd`: it fails on a quoted sentence (two words or more)
in any `.gd` under `src/` but the catalogue, skipping comments and the arguments of `print`,
`push_warning`, `push_error`, `printerr`, `assert` and `Telemetry.note` (only those arguments, not
the rest of their line). Its allow-list names each file or single string it exempts with a reason,
folders only where every file in them is a readout or a log, and an entry that no longer shields a
sentence fails, so a stale exemption cannot stay; a new one is caught only in review.

**The form, the check and the file were the filer's proposal** (one GDScript file of constants over a
doc listing where texts live, a resource file, or Godot's translation tables), built as proposed.

*Open to overturn, chosen by the implementer:*

- The event rows' `display_name` is shown nowhere in play; the names moved anyway, so the catalogue
  is the one place a row's name is read from.
- The chalk marks' words lived in `src/resistance/resistance_steps.gd`, outside the brief's list of
  files; they moved, since the entry names "the chalk mark's big message".
- Nothing under `src/interior/` or `src/finale/` is a shown text: the indoor section lines come from
  `main.finale_hint_for()`, which moved.
- A scene's placeholder that is always overwritten before it shows stayed in its scene.
- A single-word text (`Silence.`, `SLEEPINESS`, the arrows' `home` and `task`, the joystick
  buttons' `L` and `R`) is in the catalogue, but the check needs two words, so a new single-word
  text elsewhere passes it.

**Verified** by the named suites the moves touch, a comparison of every string literal in the moved
files on `main` against the catalogue (one difference, the joystick run line, rebuilt from the same
two parts), and before-and-after stills of the title and a day-6 loss screen with its brief
([text-catalogue-2026-10-11](../evidence/text-catalogue-2026-10-11/)), identical in text and layout.
