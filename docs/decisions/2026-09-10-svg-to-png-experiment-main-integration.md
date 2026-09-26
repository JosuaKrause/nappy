## SVG-to-PNG experiment: main integration — 2026-09-10

**Verification and capture.** On the merged tree, `./tools/check.sh`, focused
`visuals stroller crowd presentation_mode orientation --illustrated`, `./tools/lint.sh` and
`./tools/pycheck.sh` pass. The agent also runs the focused `events` suite without failures;
the subsequent incoming main changes no event behavior. The visual suite requires every one of
the nine PNGs to load, match its SVG dimensions and alpha, and preserve missing-art fallback
and idempotent resolution. The invalid-size warning path is inspected in code rather than
covered by a malformed-asset fixture. The local suite is partial; full verification belongs to CI.

Two bounded windowed captures at commit `468718d`, clean code/assets, seed 4242, 1280×720,
`--walk 1s3e`, after 2.5 seconds compare the same crossing in ordinary mode and with
`--illustrated`. They are `docs/evidence/archive/session-captures/2026-09-10/`
`svg-transfer-gameplay-svg.png` and `svg-transfer-gameplay-png.png`. The mother and pram
keep their framing, scale, ground contacts and drawing placement; the PNG version adds face,
fabric and wheel detail with no visible checkerboard. The same HUD, shadows and surrounding
SVG world remain visible. These are stills of an eastward walk, not proof of smooth animation
in every direction or player acceptance. Complete telemetry runs are preserved under
`docs/evidence/style-transfer-2026-09-10/runtime/` with their original run names.

The experiment's pre-merge tip was `353030cf56e305de25044527cfe4dfe16d569e9e`, incoming main
was `7f783640a00ff0b18f1f1f7babe31c49d4481399`, and their sole merge base was
`660647a429793939475e9e52b722c088669eb528`. The merge was held with `--no-ff --no-commit`
for semantic review and had no textual conflicts.

Main moves primary sources into `docs/playtests/` and updates hooks, skills, links and the hook
test accordingly. This experiment's separate PLAYTEST-51 is placed in that folder with its
content preserved; main contains PLAYTEST-01 through PLAYTEST-50, so no identity is reused.
Main's M104 (the debug view), M105 (the city degrades), M106 (roofs, fronts and street trees),
M107 (the run clock), M61 rectangle design and expanded M103 drawing queue remain intact.
Those are open gameplay/design work; this experiment changes texture selection and does not
implement or supersede them. Source changes on main are playtest-link comments only, so they
do not conflict with the renderer removal or alter simulation behavior. The texture resolver
keeps existing draw transforms and accepts only matching-size counterparts, preserving the
SVG geometry those new plans reference.

The nine live mother/pram PNGs reproduce byte-for-byte from the saved registration script.
Their native dimensions and alpha bytes match the original SVG rasters. The built-in image
generator painted checkerboards and changed raster dimensions, so its outputs were not used
directly: the existing checkerboard extractor, per-frame bounds registration and original SVG
alpha supply the drop-in contract. Exact prompts, source rasters, raw outputs and measurements
are in `docs/evidence/style-transfer-2026-09-10/`. The first single-pram alpha retry failed and
is retained as a probe, not runtime art or style guidance.

The previous illustrated PNG tree and import sidecars are preserved at
`docs/evidence/archive/rejected-graphics/illustrated-2026-09-10/`; its compositor and review-scene
code remain in the pre-experiment ancestry at `660647a`. The runtime removes those components
and the render-scale experiment, retains the illustrated flags, and draws the existing actors
at their actual origins without comparison offsets. Missing PNGs use their corresponding SVG.
The rest of the graphics catalogue remains SVG pending review of this representative family.

Adopting SVG-first authoring followed by style transfer as the standard pipeline is conditional
on the player's review, as requested in PLAYTEST-51. Automatic approval review rejected replacing
the superseded active documentation and skills, including a variant preserving standalone
copies, as beyond its interpretation of the code-and-assets authorization. The player then
explicitly approved: "Yes, update and archive the documentation". Full standalone snapshots
and the historical text below preserve the superseded instructions; active docs and the skill
now describe texture replacement. The player specified: "don't call it an experiment in the
documentation. if it works it will just be the way it is done". Active documentation calls it
the SVG-to-PNG workflow and keeps visual acceptance in TODO.
