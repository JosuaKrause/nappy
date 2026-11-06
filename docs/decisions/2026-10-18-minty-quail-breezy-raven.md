# minty-quail — The HUD's, the run's and the smaller owners' members only their own class used become internal · 2026-11-06


minty-quail's `tests-own-class-members.md`, the underscore pass, for the HUD pieces (the danger
edge, the entity halo, the badge model, the screen orientation, the pause screen), the sprites, the
run (the summary model, the run-state registry, the calendar, the day director), the loss cause, the
run config, the build info, the web display, the baby, the tuning and the ground recipe: a public
member only its own class and the tests use becomes internal and its tests move to what the class
does outward (curly-rabbit #1098), and one with no reader left is deleted (curly-rabbit #1095).

**Built.** Internal: `BuildInfo.commit_text`, `RunConfig.day_length_override` (read through
`day_length_for`), `RunCalendar.is_checkpoint_day`, the registry's `state_data` and `rider_data`
(the save suite reads `run_data()["state"]`), the summary model's `clock_line` and
`resistance_tally` (read through `day_over()`), the loss cause's suffixes (read through
`LossCause.of()`), `DayDirector.loss_cause` (read through `finish_day()`), `EntityHalo.has_settled`
(the suites read the alpha the rim's shader is handed), the badge model's `announces` and
`approach_speed`, `PauseScreen.body_for` (the suites read the body shown under each control
scheme) and `ScreenOrientation.rotation_transform` (`Boot.carries_the_rotation` in
`tests/booted_main.gd`). Deleted: `DangerEdge.arrows_drawn` (its check counts the pictures the
control asks its atlas for in one draw), `Baby.set_stroller` (the placement suite parents the
stroller and the baby as the scene does) and `GroundRecipe.reads` with its counter. Removed as
holding nothing or repeated (curly-rabbit #1097): the checkpoint calendar's table read-back and
its every-act loop, for one day-12 check; two direct approach-speed checks the measured walk
repeats, with the announce checks moved to the badge model's suite as one stepped check; the
overflow check that repeated "does not end the day".

**Kept public**, each with its reason beside its line in the list: `Sprites.mirrored_transform`,
`base_transform_of` and `EntityHalo.trace_offsets`, which only feed a draw pass no recorder
reaches; `WebDisplay.dpr_cap`, a hand-in; `Baby.overflow_mass`, which a measurement probe sweeps;
`Tuning.FINALE_DISTANT_FLASH_MEAN_SECONDS`, a constant the interior suite holds a sampled mean
against; `DangerEdge.subject_for_def`, which a warning-lead probe run by the pursuit suite steps a
badge model with. Open to overturn, the last most of all; and the ground layers' two read-count
checks became one identity check, weaker than the count.
