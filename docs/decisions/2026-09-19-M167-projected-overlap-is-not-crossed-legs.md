## M167, projected overlap is not crossed legs — 2026-09-19

[PLAYTEST-99](../playtests/PLAYTEST-99.md) rejects the generated diagonal: "the legs are now
crossed". The source diagram forced the screen-right hip into the screen-left trailing shoe,
creating an X-shaped stance. Proving that a generator obeyed that diagram did not establish a
natural stride. The correction keeps each leg on its own side of the projected pelvis, with
separate lateral walking tracks and forward/backward depth along the southeast travel axis.
The illustrated-leg guidance now explicitly distinguishes foreground overlap from crossing
the legs. Accepted E/W and every unaffected frame remain protected; the crossed candidate
is retained as rejected evidence and never installed.

Inspection of the original father diagonal A showed the foreground thigh originates at the
screen-left hip, not the screen-right assignment imposed by the X guide. Editing the crossed
figure directly merely reversed its crossing and was rejected internally. A replacement
colored guide kept screen-left hip, knee and trailing shoe on the left track and screen-right
hip, knee and advancing shoe on the right track. The generated pushing and carrying figures
retained that uncrossed stride. Deterministic recoloring restored gray-blue trousers and dark
shoes; whole-figure registration kept the native canvases and protected every other frame.
The new candidate is preserved under `uncrossed-southeast-2026-09-19/`, with PNG sheets and
GIFs for both states. Its diagonal angle and upper-body proportion consistency remain visual
judgments; it does not replace runtime art before acceptance.
The registered candidate retains a somewhat frontal pelvis and a jacket hem roughly two to
three native pixels higher than A/C. The pushing hand sample starts one row higher. The
recipe records those limits. Fresh preparation and assembly reproduce the saved artifacts;
only the two authored diagonal B PNGs change. Independent byte comparisons preserve all
other frames, including the accepted side hashes. Lint and whitespace checks pass.
