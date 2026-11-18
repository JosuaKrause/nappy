# minty-quail — The sitting's, the run log's and the baby's fields read through their methods · 2026-11-18

**What it is.** A part of minty-quail's `field-reads.md` conversion: the fields of the sitting
(`Sitting`, what one boot of the page keeps across runs, built by `main`), the run session
(`RunSession`), the run log (`TelemetryLog`) and the baby (`Baby`), read from outside their files by
`main.gd`, the still watch and the developer's rigs; seventeen lines of `tools/field_reads.txt`. An
Opus builder designed and built it. It changes nothing in play and moves no balance number.

**What was built.** The sitting is not an autoload (`project.godot` registers only `Tuning` and
`EventBus`): `main` builds it or takes the one the last boot parked at the tree's root, so `main`
reading it is the composition root reading its own part. Its seven fields are private: the run
through `use_run()` and the existing `take_the_run()`; the checkpoint's carry through
`mark_the_run_carried_over()`, `carries_the_run_over()` and `spend_the_carry()`; `controls_word()`
with `keep_controls_word()`; the existing `kept_frame_timing()` and `frame_record_file()`;
`ground_recipe()` and `atlas()`. The run session gains `trace()`; the still watch reads the run log
through the existing `file_path()`. The baby's readers use her getters (`excitement_level()`,
`sleepiness_level()`, `last_frame_incoming()`, `condition()`, `is_asleep()`) and a new
`last_frame_decay()`; the developer's rig and the scene recipe runtime, which wrote her meters
directly, call `seed_meters(sleepiness, excitement)`, which sets the two numbers and says nothing
on her bus, as the writes did. The events skill and its reference `plan-and-excitement.md` say that
nothing outside `Baby` feeds her excitement meter, with `seed_meters()` as the rigs' only door. One
test's check (a tick that never ran cannot pass) reads that the tick took her walking decay. All
seventeen lines are gone from `tools/field_reads.txt`; no field is kept public for tests.

**Proposed, not asked for, open to the player:** the carry as three methods; `seed_meters()` setting
both bars at once; `last_frame_decay()` named to match; `Sitting.use_atlas()` public for one test
(`tests/test_atlas_boot.gd`), which the test-only check does not flag.
