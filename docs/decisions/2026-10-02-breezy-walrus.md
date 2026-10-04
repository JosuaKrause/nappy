# breezy-walrus — Three modes of nearby ground preparation, all at once by default · built 2026-10-03

*([tawny-stork](../playtests/2026-10-03-tawny-stork.md), statement 1: "let's introduce three options
1) (the default) as many graphics as needed are prepared in one frame 2) at most one graphic is
prepared in one frame 3) graphic creation is smeared out like in the PR"; statement 2: "yes it
should be a flag I can use in mobile under debug"; statement 3: "we should measure option 2 like we
measure option 1 and 3". On 2026-10-03, asked whether mode 1 keeps the old atomic code's 2ms
budget (inbox #497): "if we keep the 2ms budget then it also should apply to the next frame and so
on". Context: [snowy-ibis](../playtests/2026-10-02-snowy-ibis.md),
[sunny-chipmunk](../playtests/2026-10-03-sunny-chipmunk.md), and the
[silky-rabbit record](2026-10-02-silky-rabbit.md), whose stepping is mode 3.)*

**Built (PR #475).** Preparation stays lazy and nearby-only, with the residency's load and unload
boundaries unchanged; only how a needed region's ground is scheduled differs, read once when the
city's ground is created (`src/city/scenery_ground.gd`, `src/city/scenery_residency.gd`):

1. **The default:** every region needed in a frame is prepared whole, as many as the 2ms soft
   budget allows, and what does not fit is prepared in the following frames, each under its own
   2ms — never all at once in the next frame. A run of the queue always does at least one job.
2. **At most one region a frame**, whole; the others wait for following frames, and a guard
   preparation uses up that frame's one.
3. **silky-rabbit's per-region stepping**, unchanged.

In every mode the 96px synchronous guard and a camera relocation finish a region before it can be
seen. The mode is the dev flag `--ground-mode 1|2|3`, or `?groundmode=` on the page; it is one of
the words `?debug=1` opens on the released page (M193), so `?debug=1&groundmode=2` works on the
phone; the command line wins over the page, and any other value warns and uses mode 1.

**Measured** (Apple M2, Godot 4.7.2, the three modes side by side on one build, two clean runs;
`docs/evidence/breezy-walrus-ground-modes-2026-10-03/`). Ordinary south at 60Hz, median ms:
mode 1 1.253–1.299, mode 2 1.268–1.295, mode 3 1.102–1.122; p99 5.170–5.406, 5.173–5.473,
4.717–5.142; worst 8.055, 8.833, 8.058. South at 15Hz, median 1.339–1.373, 1.383–1.396,
1.186–1.198. Diagonal at 15Hz, median 1.514–1.542, 1.637–1.654, 1.394–1.598, with the three modes'
tails overlapping. Settled shoreline: modes 1 and 2 draw 38 calls with 6 water surfaces and release
about 482,500 tracked bytes when the ground is cleared; mode 3 draws 46 with 24 and about 776,700.
No mode needed the guard, and all 48,600 retained frames had complete ground. Mode 2 costs about
what mode 1 does; mode 3 has the lowest medians on the south routes and the most draw calls and
memory. These fixture figures do not establish what a phone feels; that is
[the review item](../review/2026-10-02-breezy-walrus.md). The measured build came before the
"at least one job a run" change, which alters nothing unless a frame's bookkeeping alone takes 2ms.

**The measurement tool** (`tools/measure-ground-frames.sh`) measures the three modes of one
checkout instead of pinned old revisions, rejects a capture that ran a different mode or forced a
draw under a covered window, waits for any other Godot process to end before each capture and
retakes one that another engine disturbed, and records the load average before each launch. Its
kill at the limit is `wait_or_kill`.

**Proposed, not asked for, and open to overturn:** the flag's name and its values 1, 2, 3; a guard
preparation using up mode 2's one region a frame; a run under `?groundmode=` on the released page
kept off the save like the other `?debug=1` words.

**Verified.** `tools/check.sh`, `tools/lint.sh`, `tools/test_cli_help.sh`, and the scenery
residency, presentation mode, atlas ground, ground layers, ground floor, kerb tint, camera start,
main, orientation and finale suites; each new scheduling check was seen to fail with its mode
broken.
