# minty-quail — Ending the day, a hold and the warning are parts (row 4b) · 2026-11-21

**What was asked.** Row 4b of minty-quail's `event-interface.md` (a row is written as its parts), designed by Opus;
this is its sixth pull request, "ending the day, a hold and the warning are parts", built as #1622 by three Sonnet
agents in turn.

**What was built.** Three values in `src/events/parts/` (data), each held by the row with `use_<part>()` and
`<part>()` and shared by its copies. `LethalSpec` says whether contact ends her day and the reach it is measured from
(`none()`, `at_its_core()`, `within(reach)`, `catching_within(reach)`); it replaces the row's `hard_fail` and
`catch_reach` and the pursuit's own `catch_reach`, so a hunting copy's catch is stored once, as the hunt's
`LethalSpec` (`HuntSpec.pursuing(chase, catches)`). `HoldSpec` holds a hold, the checkpoint guard's detain and the chatting mother's
conversation alike: how long, how far past its edge, and whether it holds her again; `EventHold` is handed it. `WarningSpec` holds the warning: how long before,
whether the row holds still while warning, whether it is announced, whether it is warned first, and the badge's notice.
`validate()` keeps "a hold on a row that ends the day", which spans two parts; the fairness contract
(`Tuning.validate_event()`) is asked as before. The catalogue's 97 writers are rewritten by
`convert_catalogue_lethal_hold_warning.py`, kept with the design, with seven writes from its `MANUAL` table; docs,
skills and comments name the parts' answers.

**Measured.** The row fingerprint on main and the branch: every removed setting shows the base's value under its part on
all 1649 rows and copies, apart from the heated roadblock's copies, whose row reach reads 28 where the base's row read
0: the 28 was the pursuit's catch reach on the base and is now the row's lethal reach; `ends_the_day()` and
`lethal_reach()` answer the same on both. The excitement, look and placement fingerprints, `placement_rows.gd`,
`escape_density.gd` and `curly_stork_piece_layout.gd` print the same; no cost figure moved.

**Sizing.** Four builders before this step filled their context in under 20 minutes; this one was built one part of the
work per agent turn (the suites, then the checks and comments, then the docs and parity), each pushed before the next.

**Open to overturn:** the design's forks; `is_warned_first()` as the question's name; `HoldSpec.from()` and
`again()` without asserts; `HuntSpec.pursuing()` requiring a catch that ends the day; the default warning, 2.5 s and
announced; tests reading `warned_for()`; "lethal" or "a row that ends the day" in prose for the removed `hard_fail`. The design's `catching_within()`, a catch that is a stop, was built and then deleted in review, since no row has such a catch.
