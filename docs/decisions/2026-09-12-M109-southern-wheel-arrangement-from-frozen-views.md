## M109 — Southern wheel arrangement from frozen views — 2026-09-12

PLAYTEST-65 asks to use the displayed SE wheels for SW “and vice versa”, then explicitly
requests wording that cannot cause a second application. The final arrangement is defined
relative to a frozen source: SE takes that source's displayed SW wheel assembly, and SW takes
its displayed SE assembly. Each body, canopy, handle and grounded height stays fixed. The
player says “the rest looks good”, accepting the northern contact adjustment and stoop face.

The recipe reflects the complete wheel footprint about the canvas center using simultaneous
RGBA replacement over the union of original and reflected attachment masks. The runtime's
ordinary SW reflection supplies the reciprocal result. Frozen-source hash validation rejects
using the output as a new input, and fresh builds reproduce identical pixels. Documentation
identifies this final stage explicitly instead of instructing a future session to swap installed
textures. The upstream direction assignment and donor extraction remain reproducible stages.

The player's visual confirmation defines the final cues: SW has its leftmost wheel in shadow
and red axles on the right of the other two wheels; SE has its rightmost wheel in shadow and
red axles on the left of the other two. The final paired comparison matches these cues.
The player then confirms the main checkout looks correct, accepting this wheel arrangement.
