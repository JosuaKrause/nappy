# Investigate phone stutter after the existing baseline

The player says "we *cannot* profile on the phone", then qualifies that with
"unless you can come up with a way to profile on a phone";
[sunny-chipmunk, mobile-ground review clarifications](../../playtests/2026-10-03-sunny-chipmunk.md)
records both statements and their context. Do not require on-phone measurements.
The phone remains where the player judges perceived stutter. The entry moves to
`now`; that band change does not reorder its existing baseline work.

**Proposed, not asked for:** after that baseline, attribute costs using the native
profiling and raw-frame traces already available, plus the web build in desktop
Chrome where useful. Chrome CPU throttling can expose sensitivity, but
[Chrome's performance documentation](https://developer.chrome.com/docs/devtools/performance/reference/#throttle-the-cpu-while-recording)
says it does not truly simulate a phone CPU. Label platform and collection method;
neither native improvement nor desktop throttling establishes phone performance.

Separate the baby's per-physics-tick contribution sweep, the halo's rendered-frame
sweep, event streaming/director work, crowd/traffic and debug presentation where
instrumented spans permit. Do not use `--invincible`: it skips the baby's source
sweep and suppresses the meter behavior being measured. Measure the conservative
contribution rejection on the accessible target, including both callers, before
considering caching or lower tick rates. Retain median and tail distributions and
verify unchanged gameplay.

**Proposed optional phone method, not an available measurement claim:** Chrome
supports [remote debugging an Android tab from a computer](https://developer.chrome.com/docs/devtools/remote-debugging/).
With a USB-connected Android phone, developer options/USB debugging enabled and
the phone's authorization accepted, desktop Chrome's `chrome://inspect/#devices`
can inspect the phone tab. Its Performance panel can record while the game runs
on the phone; turn off screencasting because it adds frame cost. This requires
the player's device setup and has not been verified on their phone. Browser
traces alone do not promise named GDScript-function attribution. Treat this as
an option to establish with the player, not a prerequisite or a task to perform
against an unavailable device.

[PLAYTEST-138, mobile stutter](../../playtests/PLAYTEST-138.md) and
[PLAYTEST-140, steady phone stutter](../../playtests/PLAYTEST-140.md) give earlier
context: Chrome on a Pixel 8 Pro, with stutter that is regular rather than tied
to a particular moment. Do not infer that the latest report uses that device.
[snowy-ibis, mobile ground-stepping feedback](../../playtests/2026-10-02-snowy-ibis.md)
reports no visible removal of stutter by per-region stepping. The next optimization
direction remains open; measurement supports an optimization rather than replacing it.
