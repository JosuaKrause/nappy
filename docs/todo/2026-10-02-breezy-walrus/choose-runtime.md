**Nearby ground preparation gets three modes, the first the default**
([tawny-stork](../../playtests/2026-10-03-tawny-stork.md), statement 1: "let's introduce three
options 1) (the default) as many graphics as needed are prepared in one frame 2) at most one graphic
is prepared in one frame 3) graphic creation is smeared out like in the PR"). Preparation stays lazy
and nearby-only, with the residency's load and wider unload boundaries as they are; only how a
needed region's ground graphic is scheduled changes:

1. **The default:** every region needed in a frame is prepared whole, in that frame — the atomic
   preparation silky-rabbit replaced.
2. **At most one region is prepared in a frame**, whole.
3. **One region's preparation is spread across frames** — silky-rabbit's stepping
   ([its record](../../decisions/2026-10-02-silky-rabbit.md)), unchanged.

"Graphic" in the player's words is read as one nearby ground region's graphic, the filer's
reading of the exchange it answered ("the entire graphic is prepared in one frame", said of a
region). So mode 2 is not the "global one-section cap" silky-rabbit measured and rejected (a section
is a quarter of a region; "no consistent timing advantage over per-region"): it prepares one whole
region per frame, and silky-rabbit's matched results do not cover it. **Proposed, not asked for:**
the regions mode 2 does not reach in a frame wait for the following frames.

**Proposed, not asked for:** each mode keeps silky-rabbit's guarantee that no half-built region is drawn: the 96px synchronous
guard and a relocation finishing the destination's ground hold in modes 2 and 3 alike. The
comparisons, the measurement tools and their pinned sources are kept, and each mode is tested
(mode 2 never prepares two regions in one frame outside the guard; mode 3's existing tests stand).
**Mode 2 is measured like modes 1 and 3** (tawny-stork, statement 3: "we should measure option 2
like we measure option 1 and 3"): the same matched native comparison silky-rabbit ran — ordinary
south at 60Hz and 15Hz (median, p95, p99, worst sample) and the settled-shoreline fixture (draw
calls, water surfaces, tracked allocation, steady spans) — with all three modes side by side, the
result filed in the PR's evidence and record.

**The mode is a flag the player sets on the phone under `?debug=1`** (tawny-stork, statement 2:
"yes it should be a flag I can use in mobile under debug"): a dev flag declared in
`src/dev/dev_flags.gd` under the cli-tools rules, and one of the flags `?debug=1` opens on the
released page.
A plain dev flag is read only in a debug build, since `DevFlags.enabled()` is `OS.is_debug_build()`;
M193's `?debug=1` bundle is what reaches a release page, and adding this flag to it widens that
bundle beyond "the flags that choose where a run starts or how it is drawn", by the player's word.
**Proposed, not asked for:** the flag's name and values are the builder's.

The phone report answers the perceptual stutter question for the tested build; it does not
establish the source of the remaining stutter. Finding more to optimize is
[M159's](../2026-09-19-M159/README.md), and "we will have to look in a different direction" means
"we have to think about other ways -- that is orthogonal to when it happens" (the player,
[sunny-chipmunk](../../playtests/2026-10-03-sunny-chipmunk.md)).
