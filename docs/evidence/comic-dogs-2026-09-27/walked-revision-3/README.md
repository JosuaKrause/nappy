# Walked-dog fixed-joint study

These single-view image-generation edits use the frozen first-pass A bodies as their edit
targets. No runtime artwork changes. The side candidate has a continuous opposite stride;
the first diagonal candidates still need visible haunch-to-thigh continuity. Identical inferred
internal pivots in a diagnostic trace do not establish that continuity by themselves.

[PROMPTS.md](PROMPTS.md) records the exact first three prompts.
[DIAGONAL-REFINEMENT.md](DIAGONAL-REFINEMENT.md) records the targeted diagonal correction prompts.
The `raw/` outputs and [input-manifest.json](input-manifest.json) preserve the frozen inputs.
The original review and revision-2 files remain intact. The accepted pursuing family is frozen.

`assemble.py build` verifies frozen input hashes before writing the registered crops and
diagnostics. Registration scales the complete edited canvas uniformly back into its A crop's
coordinate plane. It never fits to the changing paw silhouette. The internal hip and shoulder
points in the diagnostics are inferred anatomical positions; visible distal chains trace each
leg's ownership. These assembled images are not runtime captures.
