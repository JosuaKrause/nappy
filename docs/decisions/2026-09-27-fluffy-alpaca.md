# fluffy-alpaca — The task line goes when the task is done · built 2026-09-27

*([olive-koala](../playtests/2026-09-27-olive-koala.md), statement 5: "the bottom left text with
the current task should disappear when the task is complete")*

**Built (PR #414).** The HUD's task line (`Hud._resistance_label`) kept naming a finished task,
because `_on_resistance_step_completed()` never reset `_contact_step`. It resets it, so the line
goes the moment the task is done. A test for a mark and for a task.
