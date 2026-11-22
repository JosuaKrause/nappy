# velvet-squirrel — How a body stands on its street is one value, derived once · 2026-11-22

**What was asked.** Fable's change to minty-quail row 3a, `body-stance-value.md`, from its review of the row's design
(the record calm-lemur-jolly-dolphin): how a body stands on its street, which the live body and the planned side each
worked out on their own, is one value derived once and handed around. The player, shown Fable's verdicts, asked for each
change to be built as Fable wrote it, reviewed adversarially, then reviewed by Fable against its design (the record
calm-lemur). Built as #1641 by a Sonnet agent.

**What was built.** `BodyStance` is a value made from a map, a row, a place and a facing, or from a plan; it answers where
the body stands, which way it lies, whether a standing vehicle shows its side, and its pieces and tiles, each worked out
once. The live event derives one at setup and again on a move, and hands it to its body and its look; the shadow, the
footprint and the planned-side callers read the same value. Two statics stay, for the questions asked with no stance to
hand.

**Differences from the design:** the live body no longer takes the map, since nothing in it reads it once the stance is
handed in; a stance's tiles are worked out once rather than asked per heading; the spawner gains two members so a live
body's tiles and a move's record come from the live stance; `obstructed_footprint` stays public, kept in the test-only
list because the parity probes ask it by name on both trees; a suite that flipped two private fields hands the body a
stance with the answers flipped.

**Measured.** On main and the branch: the piece-layout and placement-rows probes identical but their duration lines, the
excitement fingerprint's lines identical, and the look fingerprint's lines identical.
