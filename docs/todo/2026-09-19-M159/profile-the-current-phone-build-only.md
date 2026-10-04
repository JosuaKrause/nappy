**Investigate the phone's stutter once the baked-pages baseline is in.** The player says "we
*cannot* profile on the phone", then qualifies it with "unless you can come up with a way to
profile on a phone", and settles it: "phone profiling would be a nice to have but honestly a
quick eye test is good enough"
([sunny-chipmunk, mobile-ground review clarifications](../../playtests/2026-10-03-sunny-chipmunk.md)).
So no step requires an on-phone measurement, the baseline in
[measure-what-the-baked-pages-cost.md](measure-what-the-baked-pages-cost.md) included. The phone
stays where the player judges perceived stutter; that eye test does not identify the bottleneck.
[M159's README](README.md) holds the band; the baseline comes before attribution.

**What is already measured, and what is left.** The native half is recorded: "M159 — Cheaper crowd
contribution sweeps" moved the pooled day-1 sweep median from 387.813 to 59.375 µs on an Apple M2,
and ends "Phone measurement and remaining-stall attribution stay open". Attributing the remaining
slow intervals is [its sibling item](attribute-the-remaining-slow-intervals-before.md), not this
one. What this item adds is the targets not yet measured: the web build in desktop Chrome, and the
phone by one of the methods below if the player wants it. Native median gains establish neither
phone performance nor uniformly better frame tails (the M159-2 record keeps that limit with this
item).

**Proposed, not asked for:** in desktop Chrome, CPU throttling can show what is sensitive to a
slower CPU, but [Chrome's performance documentation](https://developer.chrome.com/docs/devtools/performance/reference/#throttle-the-cpu-while-recording)
says it does not truly simulate a phone CPU. Label platform and collection method on every number.
Do not use `--invincible`: it skips the baby's source sweep and suppresses the meter being measured.

**Per-system numbers from the phone now come from the frame record**: `?debug=1&framerecord=1` on
the released page keeps every frame's time by system and downloads it as a file
([M159, every frame's time by system](../../decisions/2026-09-19-M159-5.md)); the player's phone
try is the review item [Record a stutter on the phone](../../review/2026-09-19-M159-2.md).

**Two further ways to put numbers on the phone, both optional** (the player: "let's record the
ideas here -- maybe we will do them"):

- **The live page's own readout, read off screenshots** — the player: "add the screenshot way as
  alternative for phone testing but it's not a complete benchmark it's a hack". The released page
  with `?debug=1` shows fps, draw calls and process and physics milliseconds, and `&skip=<word>`
  removes one system (`events`, `crowd`, `shadows`, `motion`; `src/dev/dev_flags.gd` accepts them on
  a release page) so its cost can be subtracted. It is how the phone was measured before: M124's
  phone half and its process-time split by skip word, and M139's phone reading
  (`?debug=1&seed=123` against `&skip=crowd`). It gives per-second totals and differences by
  subtraction, not a benchmark and not per-function attribution.
- **Proposed, not asked for:** Chrome's [remote debugging of an Android tab](https://developer.chrome.com/docs/devtools/remote-debugging/)
  from a computer: with the phone on USB, developer options and USB debugging on and the computer
  authorized, desktop Chrome's `chrome://inspect/#devices` inspects the phone's tab and its
  Performance panel records while the game runs there (screencasting off, since it adds frame
  cost). It needs the player's device setup and has not been tried on their phone, and browser
  traces do not promise named GDScript functions.

**Earlier context:** [PLAYTEST-138, mobile stutter](../../playtests/PLAYTEST-138.md) — the released
page, v0.18.0, on a phone: "it's a bit stuttery"; and
[PLAYTEST-140, steady phone stutter](../../playtests/PLAYTEST-140.md) — Chrome on a Pixel 8 Pro,
stutter that is regular rather than tied to a moment. Do not assume the latest report used that
device. [snowy-ibis, mobile ground-stepping feedback](../../playtests/2026-10-02-snowy-ibis.md)
reports that per-region stepping removed no visible stutter. The next optimization direction is
open; a measurement supports an optimization, it does not replace one.
