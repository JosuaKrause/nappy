# minty-quail — The row has no public field (row 4b) · 2026-11-22

**What was asked.** Row 4b of minty-quail's `event-interface.md` (a row is written as its parts), designed by Opus; this
is its tenth pull request, "the row has no public field", built as #1630 by Sonnet agents one part per turn (the
rewrite, the suites and docs), with a measuring agent for the parity.

**What was built.** The 29 settings the row still held as public fields are private, each written only by the draft. The
556 reads of them outside the row's file, in 110 files of `src/`, `tests/` and `tools/cost_table.gd`, were rewritten by
row 4a's scripts with a table for the row (kept with the design), to the row's existing questions where one answers
(`is_ambient()`, `is_a_one_shot()`, `is_a_mast()`, `pursues()`, `waits_for_her()`, `drives()` and the rest) and to new
ones only where the game asks: `id()`, `lasts_for()`, `is_of_kind(kind)` (the catalogue's sort by kind),
`ambient_source()` (the dawn's ambient), `charges_counted_as()` (the live event), `pursuit()` and `notice()` (the
behaviours and the live event, none when the row has neither), which stay inside the events folder: the suites that ask
them test a module of that folder, and a suite of a module outside asks the row's or the live event's own questions, but
for four reads of the radius at which the masked man starts his run up the stairwell (his notice settings' run, not his
notice radius, which `notice_within()` answers), in the visit counter's suite and the shared walk of the two interior
masked-man suites, which no question answers and no game caller asks. No `is_scripted()` or `is_recurring()`: only tests
would ask them. `EventCatalogue.by_role()`, read only by `mast()`, is gone; `mast()` asks `is_a_mast()`.
`tools/field_reads.txt` lost every `[EventDef]` line and gained none.

**The act is a scripted row's alone.** Every row wrote an act, but only a scripted row's is read (its own first day).
`EventDraft.scripted_on(day, act)` writes a scripted row's act with its day, and `from_day(first)` writes only the first
day. No `act()` question was added, since only `test_acts.gd` would ask it; the suite asks what the game asks.

**Measured.** On main and the branch, by script over every line of the row fingerprint (every row, every copy, the
planners' 239 plans, their full lines printed for the comparison): every line of main is on the branch unchanged or
renamed private with the same value; every new line is one of the new questions and equals the field it replaces; the
only value changed is the act of eight non-scripted rows (the police patrol, the poster crews, the roadblock, the
abduction, the alley robbery, the military convoy, the protest) and two copies of them, which nothing reads, their first
days unchanged. The look, excitement and placement fingerprints, `placement_rows.gd`, `escape_density.gd` and
`curly_stork_piece_layout.gd` print the same but timings; no cost figure moved.

**Open to overturn:** the act a scripted row's alone; `is_of_kind(kind)` where the design named a question per kind;
`pursuit()` and `notice()` handed out beside the row's own questions about them; the four test reads of the radius at
which the masked man starts his run, left reading his notice settings; `test_heat`'s comparison of a row's kind written
as a loop over every kind; `docs/EVENTS.md`'s settings table naming the settings a draft writes.
