# A smooth option for movement scripts

Add an opt-in smooth mode to the movement script, available to both `--walk` and a scene
recipe's playback. With it on, a change of direction between two steps turns her heading
gradually rather than at once, and **after each turn, and at the end of the script, she is at
exactly the position the abrupt script puts her** — the player's own test case is `west 1s,
north 1s`: heading 270 turning gradually to 0, finishing where the abrupt version finishes, in
both coordinates. Smooth off is today's behaviour, unchanged.

**Why it needs more than rotating the heading.** Turning at full speed through a window around
the corner cuts the corner and lands somewhere else: with a heading rotating linearly through an
angle Δ over a window of 2τ seconds centred on the step boundary, the displacement over the
window points the same way as the abrupt path's but is longer by a factor of
`sin(Δ/2) / ((Δ/2)·cos(Δ/2))` (about 1.27 for a right angle). **Proposed, not asked for:** walk
the window at that factor's inverse, `(Δ/2) / tan(Δ/2)` of full speed (about 0.785 for a right
angle, zero for a reversal, which becomes stop-and-turn), so both coordinates match exactly;
that needs the input path to carry a magnitude below one through to her speed. **This collides
with [M82, one way to say where she goes](../../decisions/2026-09-06-M82-one-way-to-say-where-she-goes.md)**:
`src/dev/auto_screenshot.gd` keeps a scripted step's vector at unit length because "a step that
pressed a shorter vector would reintroduce the slow walk M82 deleted". The slowdown is offered as a
scripted-only exception, never reachable by a player's input; if it cannot be kept scripted-only,
choose another construction that keeps the end position and the total time at full speed, or
report the fork, and say which in the PR.

**Proposed, not asked for:** smooth is off by default; the turn window's length is the
implementer's choice, clamped so it never reaches past half of either neighbouring step; and a
stand, or a change between walking and running, is not smoothed.

**Proposed, not asked for:** the switch is a flag of the recipe's playback (`"smooth": true`)
and of the dev flags (`--smooth-walk`), with the walk string's syntax left alone; **cli-tools**
governs the flag's help and rejection.

Verify with a headless test that runs the `west 1s north 1s` script smooth and abrupt from one
spot and compares the end positions (equal within a pixel, physics-tick rounding aside, with the
tolerance stated), a test for an oblique bearing turn, and one for a reversal.
