priority: now

# calm-stork — Construct the described trailer scenes and screenshots · filed 2026-10-03

The player asks "in addition to the power plant test create scenes as described for the
trailer" in [brisk-ibis, required trailer scenes](../../playtests/2026-10-02-brisk-ibis.md).
[PLAYTEST-139, trailer action and composition](../../playtests/PLAYTEST-139.md)
is the source, not the first attempted trailer's shot list. Later instructions request
screenshots of every scene and no videos for this pass, and configurable time before
recording starts so everything is already moving; [gentle-marten, review and capture scope](../../playtests/2026-10-03-gentle-marten.md)
records them.

Use [round-ferret, the shared recipe builder](../../decisions/2026-10-02-round-ferret.md)
to deliver [the described scenes](trailer-recipes.md). Follow with
[velvet-hare, ordinary controls and bounded ground](../2026-10-03-velvet-hare/README.md)
for experimentation in every recipe. The entry includes the
[scene composition corrections](scene-composition.md) from
[downy-egret, the numbered scene review](../../playtests/2026-10-03-downy-egret.md).
The urgent band follows the playtest-feedback rule. The separate queue entries preserve
the builder, scenes and free-play requirements within the same implementation PR.

[M204, the trailer cut](../2026-09-25-M204/README.md) retains movie assembly, final
ordering/captions/fades, the thirty-second limit, resolution/audio output, and its
existing missing-truck, nonrunning-mother and loaded-render bugs in the first attempt.
The scenes here must themselves show the requested truck/run actions. Fixing or
reproducing that earlier movie is not this slice's acceptance test.

The chase still uses the recipe capture path (`--recipe scene-recipes/trailer-chase.json
--recipe-mode scripted`), with recipe movement and capture on the same physics clock.
M204 retains investigation of its older standalone `--start-escape` with `--walk` or
`--after` screenshot hang; that path is not required for this still.
