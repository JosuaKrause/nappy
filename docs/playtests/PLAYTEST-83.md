# Playtest 83 — The corrected stairs are accepted

**Date:** 2026-09-19

## What was checked

The corrected M158 staircase was walked from
`./tools/run.sh --start-escape stairwell:left`. Its live layout follows the literal grammar in
[PLAYTEST-81](PLAYTEST-81.md): the two diagonal flight directions, their solid side pieces and
the corridor doors all come from the same parsed map.

## What the player said

> "the stairs look good. I need a sprite sheet to confirm that the legs are now okay. and I'm
> not sure what's going on with the performance branch"

The first sentence accepts M158, the staircase follows the corrected tile grammar. The other two
sentences are requests for visible review evidence and a plain account of work already in flight:
the father's corrected opposite-contact legs belong to M160 on PR #221, and the frame-stutter
investigation belongs to M159 on PR #216. They do not reopen or change the staircase geometry.
