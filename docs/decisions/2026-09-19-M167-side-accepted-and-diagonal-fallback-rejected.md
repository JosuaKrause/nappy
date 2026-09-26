## M167, side accepted and diagonal fallback rejected — 2026-09-19

[PLAYTEST-98](../playtests/PLAYTEST-98.md) confirms the current left/right artwork is correct and
rejects the restored southeast drawing: "you just reverted back to the bad legs from before
this PR?" and "but SE is just the bad leg from before this PR". Reverting to provisionally
accepted contact positions did not satisfy the separate request to make those legs look natural.
The side pixels and color transformation are protected; remaining drawing work concerns the
diagonal B contact in both pushing and carrying.

The next generation approach put colored hip–knee–shoe chains directly under the father
identity crops. A detached ownership diagram had again failed to control the foreground
thigh. Keeping red on the foreground trailing chain and cyan on the far advancing chain
through generation produced continuous opposite contacts in both complete figures. A
deterministic palette transform then restored gray-blue trousers and dark shoes, before
whole-figure registration and family assembly. The result is new diagonal artwork rather
than another fallback to the old thin legs. Accepted E/W and all other frames remain
byte-identical. Upper-body proportion stability remains a visual-review question; the
new candidate is uninstalled.
Registered inspection found the jacket hem approximately two native pixels higher and the
pushing hand region extending one pixel farther right and down than A/C. These differences
are recorded with the new source and remain visible-review limitations, not claims of exact
upper-body preservation. Fresh preparation and assembly reproduced every saved artifact;
protected-frame hashes, native canvases, alpha-preserving recoloring, PNG scaling and GIF
timing passed. Documentation lint and whitespace checks passed; runtime content is unchanged.
