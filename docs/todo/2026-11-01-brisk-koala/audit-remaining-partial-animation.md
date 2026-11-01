**Separate the remaining partially animated scenery from its stationary pixels.**

The player's general guarantee is that a sprite with only partial motion keeps its stationary
pixels in a static drawing and composites the moving parts separately; city block imagery stays
a still frame. [Sunny lynx](../../playtests/2026-09-26-sunny-lynx.md) records both the guarantee
and agreement to keep this broader audit explicit after the four-case animation checkpoint.

Audit the café row, street musician (the existing `busker` identifiers) and poster crew first,
then check the other partial-motion frame pairs for the same issue. The café's leaning sitters
currently change the owner's drawing key and redraw stationary tables. Separate stationary
tables/scenery from moving sitters while preserving their painter order. Compare the musician's
strum and the crew's paste frames before deciding which pixel spans actually move; do not assume
that a whole figure needs repainting or that its bounding box defines the moving pixels.

Preserve orientation, mirroring, registration, shadows, halos, collision, gameplay, authored
timing and atlas residency. Static layers may legitimately overlap moving layers to provide
background and foreground occlusion; omit duplicate moving pixels, not the underlying artwork.
Use phase-composite comparisons and a runtime burst covering the relevant orientations, and
measure the removed redraw work separately from complete-frame performance. The four completed
cases and their limitations are in the
[scenery contract](../../evidence/m159-scenery-animation-2026-09-26/CONTRACT.md) and its reports.
