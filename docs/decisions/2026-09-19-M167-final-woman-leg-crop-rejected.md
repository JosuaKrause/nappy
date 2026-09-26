## M167, final-woman-leg crop rejected — 2026-09-19

[PLAYTEST-101](../playtests/PLAYTEST-101.md): "the crop in 234 is pretty bad". The final-image
preview in PR #234 was rejected on its crop. Its source images, assembler and sheet remain
under `docs/evidence/male-player-2026-09-19/b-contact/final-woman-legs-2026-09-19/` as evidence.
The implementation fitted the lower donor to an eighteen-pixel region and pasted father
rows 0–30 over it; that rectangular join is visible beneath the jacket. Inspection also
shows that the woman's longer coat hides upper-leg anatomy visible beneath the father's
shorter jacket. These are inspection findings, not a more specific statement from the player.
The player clarified: "it's the wrong part but maybe do the crop in the larger version and
then let the image generation normalize it?". The crop itself is the complaint. Asked for
literal copying without generation in PLAYTEST-93 · overturned to high-resolution cropping
followed by generated normalization in PLAYTEST-101 on 2026-09-19, because the literal-copy
crop was rejected. The corresponding final donors, father identity and protected frames
remain the contract. No replacement art was installed at this point.

The normalization attempt assembled the original high-resolution father upper bodies with
the two final mother B leg crops, using masks along the painted coat contours rather than
discarding every pixel above one horizontal row. The built-in generator normalized this
two-figure assembly before whole-figure native registration. Its jacket-to-trouser transition
was continuous on inspection, but it redrew trouser/shoe detail and the side foreground leg
appeared to advance, leaving the required near-leg-trailing ownership unproven. The attempt
was kept for the early feedback the player requested, not installed or treated as a finished
correction. Exact inputs, prompt, raw result and deterministic derivatives are retained in
`docs/evidence/male-player-2026-09-19/b-contact/normalized-crop-2026-09-19/`.

The player's accompanying request to post baby-carrying animation was answered with native
and 6× eight-direction A/C/B/C GIFs at 190ms per phase, assembled from the installed father
carrying PNGs without changing them. The normalized pushing candidate preserves every other
baseline frame byte-for-byte. Fresh preparation, pushing assembly and carrying assembly
reproduced their saved outputs exactly; source hashes, native canvases and GIF timing were
verified. The boot check, documentation lint and whitespace checks passed. No runtime art,
gameplay code, full local suite or windowed gameplay capture was involved.
