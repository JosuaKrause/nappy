# minty-quail — The page counter is handed whether it may send, and the prediction reference keeps its own reach (minty-quail, T1) · 2026-11-24

minty-quail's `tests-public-seams.md` and `tests-unseen-reads.md` closed their two refactor
bullets that touch the game's code before the end remeasure: the recording counter's override of
`VisitCounter._send_event()` and the prediction reference's call to a crowd source's private
`_projection_reach()`.

**The counter's platform is handed in.** `VisitCounter._send_event()` asked the engine itself
whether this is the web (`OS.get_name() == "Web"`) and whether `window.goatcounter.count` is
there (`_goatcounter_present()`), so a headless run could never take the send path and both
counter suites overrode `_send_event()` to record names. A new `GoatCounterPlatform`
(`src/telemetry/goatcounter_platform.gd`) holds the three answers about the machine (the web, a
debug build, the page's `count.js`, the last as a Callable asked afresh each time since `count.js`
loads asynchronously). `VisitCounter.send_through(outbox, platform)` takes it beside the outbox,
`main` hands `GoatCounterPlatform.of_the_engine()` (the engine's own answers, and the probe moved
there from the counter unchanged), and the gate composes `may_ever_send()` over the platform's web
and debug-build answers and the configuration's `?debug=1`. GoatCounter's names and counts are
unchanged: the committed baseline `tests/fixtures/observed_run_log.txt` and the `sent` lists of
the observers suite hold the same names in the same order.

**Why the platform answers the debug build too.** The booted observers suite hands the boot a
debug-build configuration (command-line flags need one), which the counter's gate would refuse for
good. The debug build is a fact about the machine as the web is, and `RunConfig.at_boot()` reads it
from the engine, so the counter asks the platform for it and the configuration only for the page's
`?debug=1`. Rejected: giving the counter a Callable that answers the whole gate (the gate's
composition is what the tests must drive, not stand in for); handing the answers to
`GoatCounterOutbox` (its one-argument constructor serves the suites that test the queue alone).

**The suites drive the real path.** `tests/recording_page.gd` records the scripts an outbox is asked
to evaluate and the platform of a released web page; both suites' `RecordingCounter` drop the
override and read the names off the page. `test_visit_counter.gd`'s gate test now hands the real
counter all sixteen combinations of web, debug build, `?debug=1` and `count.js` and counts what
reaches the page, where it composed the gate by hand. Under a break that ignores the platform's
debug build, and one that ignores whether `count.js` is present, the suite fails; the never-queues
case hands a platform whose page has no `count.js`, so a refused event that slipped through would
sit in the queue and show.

**The reference keeps its own reach.** `tests/fixtures/prediction_reference.gd` worked out a crowd
body's reach by calling the source's private `_projection_reach()`, so a wrong reach was wrong the
same way in both and the parity check could not show it. The reference now works it out from the
tuning (the kind's outer radius, `Field.scale()` at the top of its speed range) and what the body
answers publicly (`lane().kind()`, `is_startled()`, `jolt_radii()`). The suite's parity sweep did not
catch a source whose reach was halved: its positions all lie inside the closing distance. A new
case puts her where only the end of the horizon brings her into the body's field (four fifths of its
outer radius past the closing distance), for a walker and a car; halving the source's reach fails
it on both kinds.

**`test_prediction_reuse.gd` states its exception** in its header: it writes private members of the
source's event and body one input at a time, and overrides `_sample_expected_landed()`, since no
game path changes one input alone and that is what the cache's key has to notice.

**The count commands see the fixtures.** The two commands of `tests-public-seams.md` globbed
`tests/*.gd`, which skips `tests/fixtures/`; they now read `tests -g '*.gd' -g '!tests/probes/**'`
and print only `tests/shared_state.gd` and `tests/test_prediction_reuse.gd`.

**The twenty kept reasons are re-pointed** in `tools/test_only_members.txt`: sixteen hand-ins,
three steps by hand and `RouteTree.grow` name writing-tests' section "A test reaches the game the
way the game does" instead of the two items.

Open: that section is written by the pull request that closes the two items; until then a reader
finds the rule in the items.
