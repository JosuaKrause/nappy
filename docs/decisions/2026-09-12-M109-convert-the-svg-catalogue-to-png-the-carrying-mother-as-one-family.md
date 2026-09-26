## M109 — Convert the SVG catalogue to PNG · the carrying mother as one family, 2026-09-12

[PLAYTEST-62](../playtests/PLAYTEST-62.md) asks for consistency across directions, animation frames
and state variants, explicitly the same mother carrying the baby and pushing the stroller. It
suggests a shared grid and leaves the method to visual results. The ten carrying SVGs were
already authored and bound; this increment adds their PNG derivatives without changing sources,
runtime drawing, animation, mirroring, offsets or gameplay. The catalogue-wide conversion remains
open in M109, convert the SVG catalogue to PNG.

The generation evidence is
`docs/evidence/style-transfer-player-family-2026-09-12/`: source SVG hashes and native/8× Godot
rasters, a five-column/two-row source grid, a matching existing-PNG pushing-family reference,
both raw generator outputs, exact prompts, extraction and registration code, and native/3×
comparisons across eight directions and both gait frames. The columns are front, back, side,
front diagonal and back diagonal; rows are frames a and b. Runtime mirroring supplies west views.
The source SVG remains authoritative for the carrying pose and head turns. Existing pushing PNGs
supply recognizable identity and rendering, and remain unchanged; the urban and cardinal images
supply style only. This avoids regenerating an established family merely to extend its states.

The first built-in imagegen output painted checkerboard and pale ghost outlines in its margins.
The approved neutral-background extractor left residue that expanded the measured cell bounds,
shrinking the actual character inside an exact source alpha mask. That result was rejected
internally and its failed registered derivatives were kept outside the repository. A background-only
imagegen edit produced a plain white background; the same extractor then removed it cleanly.
The original raw image remains because it is an input to the accepted edit. This is why the
illustrated-PNG skill now checks extracted bounds and interior placement as well as exact alpha.

The shared grid and existing-family reference produced recognizable short brown hair, red coat,
blue jeans, dark shoes and matching baby/blanket materials across the retained variants. A grid
alone did not guarantee identical generated details between gait frames; comparison at native
size and enlarged remains required. The carrying diagonals retain their SVG head turn rather
than copying the more frontal rendering in the existing pushing PNG. Both art skills now require
reviewing direction, frame and state families together; grid batching is a technique, not a
mandatory output format. Human appearance and motion review remains in `REVIEW.md`.

Integration verification: `./tools/check.sh`, focused `visuals stroller presentation_mode orientation`
suites, `visuals --svg`, doc lint, the evidence converter's Ruff check and `git diff --check`
passed. The visual suite checks every rig PNG against its native SVG size and alpha, including
all ten carrying derivatives. Both modified skills passed the skill-creator frontmatter validator.
Re-running registration from the corrected raw atlas reproduced all ten runtime PNGs byte for byte.
