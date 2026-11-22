# velvet-squirrel — How a body stands on its street is one value, derived once · 2026-11-22

**What was asked.** Fable's change to minty-quail row 3a, `body-stance-value.md`, from its review of the row's design
(the record calm-lemur-jolly-dolphin): how a body stands on its street, which the live body and the planned side each
worked out on their own, is one value derived once and handed around. The player, shown Fable's verdicts, asked for each
change to be built as Fable wrote it, reviewed adversarially, then reviewed by Fable against its design (the record
calm-lemur). Built as #1641 by a Sonnet agent.

**What was built.** `BodyStance` is a value made from a map, a row, a place and a facing, or from a plan; it
answers where the body stands, which way it lies, whether a standing vehicle shows its side, and its pieces. The pieces
are laid out afresh on each ask (`pieces()` where it stands, `pieces_at()` round a point); only the layout round the
origin of a body that does not drive is kept, once. The stance holds no tiles: `EventSpawner.footprint_of()` rasterises
its pieces for the record, and `EventBody.tiles()` keeps that answer for the stance it holds. The live event derives one
at setup and again on a move, and hands it to its body and its look; the shadow, the footprint, the record of a new or
moved instance and the planned-side callers read the same value. Two statics stay, for the questions asked with no
stance to hand.

**Differences from the design:** the live body no longer takes the map, since nothing in it reads it once the stance is
handed in; its own tiles are the stance's, worked out once, rather than asked again per position and heading (they
differ only for a solid-bodied pursuer dropped as it runs, which no row reaches: the one pursuing row with a body is the
roadblock, whose body stays through its barrier post); `EventBody.tiles()` asks the spawner's `footprint_of()` rather
than the stance, since which rows the record counts is the spawner's filter; the spawner gains `footprint_of()` and
`record_the_stance()`, taking the stance alone, so a new or moved instance's record comes from the stance it holds and
`record_the_body()` is left for bodies with no instance; `obstructed_footprint()` is gone, and the suites, rigs and
probes that asked it ask `footprint_of()` of a stance; a stance lays its pieces out round a given point and heading
too, for a car that drives on after it is stood; a suite that flipped two private fields moves its event across a street
that turns, so its body and look are handed a stance the other street gives.

**Measured.** On main and the branch: the piece-layout and placement-rows probes identical but their duration lines, the
excitement fingerprint's lines identical, and the look fingerprint's lines identical.
