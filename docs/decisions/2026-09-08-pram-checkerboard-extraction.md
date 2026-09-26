## Pram checkerboard extraction — 2026-09-08

PLAYTEST-44 records the player's approval: "I find the pram layered pictures look good" and
request to "write a script to turn the checkerboard pattern into real transparency". The blanket
rejection of these two pram drawings was overturned by that approval for background extraction.
Their original opaque PNGs remain unchanged in the archive; this approval is specific to these
drawings and does not revive other rejected graphics.

The chosen approach is a reproducible Pillow script, preserving source geometry and saving
separate RGBA copies. Regeneration is unnecessary for the requested background cleanup. Review
uses solid dark and blue backdrops to expose residual checkerboard, fringe and holes in artwork.
Removing the background does not establish shared layer pivots, eliminate the duplicated basket,
or verify assembled animation; those remain in the actor registration queue.

Both transparent outputs retain the originals' 1448×1086 dimensions and exact RGB samples;
the script changes only alpha. Direct checks confirmed fully transparent background and enclosed
handle gaps. A synthetic sample checked preservation of warm pale art, an enclosed white highlight,
existing partial alpha and refusal to overwrite an output. The reviewed dark/blue contact sheet is
[pram-transparency-review.png](../evidence/pram-transparency-review.png). The extraction is a
threshold-based matte with a one-pixel neutral fringe pass, not recovery of original soft alpha;
similarly colored artwork on other inputs needs separate review.
