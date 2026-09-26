## Eight-direction style transfer — 2026-09-10

Final integrated verification on 2026-09-10: import/boot passed; focused stroller, visuals,
presentation and orientation suites passed 191 checks in default mode, and stroller/visuals
passed 145 checks with `--svg`. All six new PNGs reproduced byte-for-byte from the saved atlas.
Two windowed gameplay captures used clean `afda953`, seed 4242, 1280×720, `--walk 1s3@135@`,
after 2.5 seconds, once default PNG and once `--svg`. Both show the same southeast-facing rig,
placement, framing and HUD; transferred detail is visible without checkerboard artifacts. The
telemetry confirms leaving the doorstep and crossing the road; the capture shows speed 92.
These stills verify the southeast gameplay binding, not smooth motion in every direction.

Captures: `docs/evidence/archive/session-captures/2026-09-10/eight-directions-gameplay-png.png`
and `eight-directions-gameplay-svg.png`. Complete telemetry runs are preserved under
`docs/evidence/style-transfer-eight-directions-2026-09-10/runtime/`, retaining their original
`rig-083929-seed4242-v0.8.2-114-gafda953` and `rig-083950-seed4242-v0.8.2-114-gafda953` names.

The mother/pram part of M108, eight-direction entity graphics, is implemented in SVG and PNG.
Sources were committed before generation in `7b5f871` and refined in `09a4ee9`; the source manifest
records their hashes. Four 26×46 mother gait frames and two 36×30 pram views add genuine diagonal
projections, with explicit west mirroring and unchanged 34px spacing. The drawing now selects
eight views with a 5° hold beyond each 22.5° sector boundary; resetting selects the nearest view
directly. The same texture/mirror helpers used by drawing are checked across all directions and
both mother frames, including wrapped boundaries and reset cases near boundaries.

The built-in generator produced the saved diagonal atlas from those SVGs and the approved style
references. Checkerboard extraction and registration produce six native-size PNGs with exact
SVG alpha; raw output, source rasters, source hashes, measurements and exact prompt are preserved
under `docs/evidence/style-transfer-eight-directions-2026-09-10/`. Its comparison sheets show
SVG left and PNG right. The eight-view sheet assembles textures with runtime offsets at 3×;
it is a source comparison, not a gameplay capture or a smooth-animation measurement.

Three SVG drafts were reviewed internally before PNG generation: the first kept cardinal
silhouettes and changed facial features between gait frames; the second still changed faces
and barely changed the legs. A third draft made frames consistent before the front/back art
distinction was completed with the visible baby and a rear three-quarter cheek/arm/coat plane.
Their preview files were removed during PLAYTEST-53's selective-retention cleanup and remain
recoverable from Git history rather than occupying the current rejected-art archive.
The correction requires consistent upper bodies across gait frames, distinct leg/shoe geometry,
true three-quarter pram planes and a reset that selects the nearest view without inherited
hysteresis. These are source-art/runtime defects, not things a style transfer should conceal.

The user also requests PNGs by default with an SVG override, and authorizes merging PR #75
after the current work. The resolver now prefers matching PNGs and `--svg` / `?svg=1` forces
SVGs in debug or release. City TileSet replacement uses the same resolver. The old illustrated
flag API is removed; unknown old flags have no effect. The visual suite checks every rig PNG
against its native SVG alpha and dimensions, plus both selection modes and missing-file fallback.

The player emphasized: "every png asset needs a corresponding svg asset -- the svg asset always
comes first". This is the permanent authoring rule in both graphics skills and VISUALS, and
M109, convert the SVG catalogue to PNG, includes the pairing/provenance audit and check.

The player subsequently approved the workflow and requested two broader work items: eight-direction
movement graphics for all entities, then conversion of all SVGs to PNG through this workflow.
These are M108, eight-direction entity graphics, and M109, convert the SVG catalogue to PNG.
Their scope includes prepared artwork and an exhaustive inventory rather than only currently
moving actors. Adding the queue does not implement the remaining families or change the default
presentation. The current mother/pram implementation remains the first directional family.

PLAYTEST-51 accepts the conversion examples and requests eight directions, with SVG artwork first.
The player accepts the hand-to-pram gap if it predates the transfer. Comparing `660647a` with
the transferred version confirms the same 34px PRAM_DISTANCE, projected Y offset and source
SVG silhouettes. The gap is inherited and spacing is preserved. New diagonal views use the
same explicit east/west mirror symmetry as the cardinal side views; art direction stays upright.
