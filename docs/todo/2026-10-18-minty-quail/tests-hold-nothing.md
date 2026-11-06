# Tests that hold nothing: the audit's findings, removed by the builds that own their files

**The ask.** Told that a check went because no game path lowers resistance progress (its setup
called a function only that test called), the player: "that was a completely pointless test to
begin with", "good that it's gone", then "can we audit tests for those kind of useless ones and
remove them?", and, quoting back the four kinds the audit looks for, "let's make sure those tests
also won't enter the codebase again" (curly-rabbit #1097). The four kinds, in the orchestrator's
words that the player quoted back: a state only the test can create (input the game does not control, such as a corrupted save
on disk or a browser's answer, does not count, since it can really happen); a design decision read
back, a check that goes red only because a number changed, not because what the number is for
broke; a check that cannot fail, that would pass with the code deleted or checks a value it just
set itself; and a duplicate of the same behavior another suite already tests.

**Read as:** the checks of those four kinds are removed. **The findings below are the audit's, not
the player's:** seven read-only agents of the orchestrator's read every suite on 2026-11-05 and
wrote each line, and the player ruled on the cases the audit could not settle (curly-rabbit #1086, #1100, #1102), and the builds
that own those suites applied each ruling. So a builder checks each
finding against the suite before acting on it, removes it if it holds, tightens it where the line
says so (a sweep guard that cannot fail becomes one that can), and keeps it, saying why in its
record, where it does not hold. Keeping the four kinds out from now on is **verify**'s testing policy and the CI check of
test-only members (record minty-quail-gentle-hare).

**Who removes what.** A suite in a remaining build's file list in `tests-unseen-reads.md`, or in
`tests-own-class-members.md`'s pass, has its findings removed by that build, in the same commit as
its other changes, so no file is rewritten twice. Suites no build lists get removal builds of their
own, split by owner when they are briefed; the save, run, telemetry and screen suites are among
them, since their build is done. A line number is `main`'s at the audit; the builder re-reads it,
and a finding whose check is already gone is skipped.

**Kept on purpose, not findings:** guards that a sweep was not vacuous, orderings between two
constants, checks that pin a bug that shipped, the run log's `Telemetry.begin_memory_log()` setup
(kept with its reason in `tests-unseen-reads.md`), and the atlas library's accounting, which
`tests-unseen-reads.md` says what is left of.

## The findings, by suite

Each line: where | the check | its kind | why | the audit's confidence.

**`test_resistance_arrow.gd`**

- `test_resistance_arrow.gd:217` and `:220` | `_test_the_arrow_moves_at_four_tiles_closer` / `_test_the_arrow_does_not_move_at_three_tiles_closer` | RESTATES | Two probes straddling the hysteresis constant (4 tiles) read back as `moves` true/false; they go red when the threshold is retuned, not when switching breaks. `_test_the_arrow_switches_as_another_target_becomes_closer` (test_resistance_arrow.gd:182) is the behaviour. | medium

**`test_resistance_reach_narrow.gd`**

- test_resistance_reach_narrow.gd:97-98 `_test_the_narrow_targets_are_reachable_on_their_day` | "day %d has a narrow resistance target" (`ResistanceSteps.narrow_target_on(day) != null` for days 9, 12, 14) | restates a design decision | Reads which days have a narrow target out of `ResistanceSteps` and then loops over the same three days; goes red only when the table is edited. The skip-branch `continue` it guards is the only thing it does. Medium-low; kept as a guard if the player prefers. | medium

**`test_resistance_replacement.gd`**

- `test_resistance_replacement.gd:100` | `t.check(true, "skipped: the test city has no two alleys close enough to test this")` | cannot fail | An always-true check on the branch where the setup found nothing, so the whole test silently passes on a seed/city where its precondition does not hold. Should fail (or the setup should pick a city that has the alleys). | high

**`test_route_rig.gd`**

- The rig suite's seed claim, run (record minty-quail-brisk-llama): on seeds 1, 2, 3 and 5 only seed 2 fails, and only two checks, both in `_test_body_clearance_keeps_her_off_the_frontage_beside_a_kerbed_van` ("crosses none of any body's clearance", "no step of the plan past the van..."). Open: why the dev route rig's plan crosses a body's clearance on seed 2, a planner gap in a dev tool or a check that holds by luck.
