# Code is typed wherever the language can type it, the tests included

**The ask.** Shown that after the typed-access step (`field-reads.md`) a new test suite written the
usual way, `func run(t)` with an untyped `t`, no longer parses, and that most test files are untyped
(of 414 script files under `tests/`, 365 are not fully typed, 330 of them for the runner handed in
untyped), the player: "wait, they weren't typed before???". Told that GDScript makes types
optional and nothing in the project enforced them: "is that a limitation of the type system?". Told
that the tests' case was habit and that the real limits are narrow (a property read on an untyped
value is never warned, collections are typed one level deep, no interfaces or unions so a fake
extends the class it stands in for, a callable carries no signature): "yeah, let's not make that a
habit. we type when we can. with the public seams tests you won't have to keep things untyped to
make it work" (inbox #1280 in olive-ferret).

**Read as:** every declaration and every receiver is typed where GDScript can type it, in `src/`,
`tests/` and `tools/` alike, and a value the language cannot type is read through a typed name. A
test that hands its fake in through a public seam (`tests-public-seams.md`) has a typed place for
it, so no value stays untyped to make a test work. A new file is fully typed from its first line,
tests, rigs, fakes and probes included, which the typed-access step makes the engine enforce
(`field-reads.md`: a file not yet typed carries a first-line opt-out, and a new file may not).

**Build.**

- **The runner is typed in every suite.** One scripted rewrite gives each suite the typed header
  the suite contract names (the runner script preloaded as a constant, `run` taking it as its
  parameter's type), and deletes from each file's opt-out line the warnings it no longer trips, and
  the line where none is left. The script is in the pull request's description, so a branch merging
  `main` reruns it.
- **What is left untyped in a test goes as its suite is converted** to public seams and to one
  module (`tests-public-seams.md`, `tests-one-module.md`): the pull request that converts a suite
  deletes its opt-out line.
- **The files under `src/` lose their lines in the module passes** (`field-reads.md`).

**Proposed, not asked for:** the scripted rewrite of the runner header as a pull request of its
own, right after the typed-access step lands. The plainer alternative is to leave every test file's
opt-out line until its suite is converted. The orchestrator told the player of the plan in the same
conversation ("I plan to do that rather than leave the tests for the late item"), and the player's
answer above followed it.

**Done when** no file under `tests/` or `tools/` carries the opt-out line; `uv run python
tools/check_field_reads.py --summary` counts the files that still do.
