# Walking-frame correction toolbox

These are reusable strategies for revising an existing illustrated family. Choose the operation
that addresses the visible defect and review its result; none guarantees acceptance. Preserve
source provenance, frozen raster inputs, prompts, masks, transforms and reproducible
assembly recipes. The attempts and player verdicts are recorded under M160, the father's opposite
contact, and M167, the father's natural legs, in `docs/DECISIONS.md`.

## Select a donor by anatomy and projection

Trace each leg from its own hip through knee to shoe. Identify the leading and trailing leg
along the travel direction separately from which thigh overlaps in front. Inspect the actual
image: an A/B label or a front-diagonal filename cannot establish its contact or projection.
Check western mirrors too. A same-clothing donor can supply useful leg artwork across character
or carrying states, but its view, proportions and ownership must fit the target.

Prefer the original large artwork for cropping and generated normalization. Mask along the
garment contour rather than assuming a horizontal row separates coat and legs. A longer coat
can hide anatomy the target's shorter jacket exposes; that region needs a coherent transition.
Supply approved upper-body crops for identity, excluding the wrong legs from that reference.
Give each saved generation input an explicit role: identity, pose, material or style.

## Guide an uncrossed contact

Colored hip–knee–shoe chains placed in the target figure can guide generated leg ownership.
Establish the projected hips from the accepted torso first. Keep separate lateral walking
tracks: foreground overlap does not require an X between opposite hips and shoes. The near
leg can trail while the far leg advances. Inspect the generated anatomy afresh; obeying a
mistaken guide produces a mistaken pose. Remove guide colors with a saved material transform,
then review native-size and enlarged results before adopting the frame.

## Match materials independently

Once geometry is accepted, use deterministic color transforms instead of another generation.
Sample corresponding materials from adjacent accepted A/C frames. Separate trousers, jacket,
skin, shoes and baby/blanket; opposite brightness errors need opposite corrections. A whole
figure darkening cannot fix dark trousers and a bright jacket together. Preserve alpha and
unaffected pixels, record masks and parameters, and inspect the complete animation for flicker.

## Reuse a stable body and move the new hem

When the adjacent accepted frame has the correct body pose and registration, its native upper
body can restore consistent texture, hands, face and carried-baby proportions. Copy the complete
carrying upper at its original scale rather than resizing the baby separately. Keep the approved
new legs and the new frame's hem contour. Select only the actual garment edge, move that contour
to the neighboring frames' hem height, and fill behind it with the matching jacket texture.
Exclude trouser pixels and preserve alpha outside the authorized body/hem region.

This is a constrained composite, not permission to paste an arbitrary rectangular upper over
moving hips. It works only when the body pose, garment transition and leg articulation remain
continuous. Check for a hard horizontal seam, doubled outline, abrupt leg-width change and lost
hand contact. Use generation for unresolved anatomy; retain accepted pixels for a local material
or edge correction. The reproducible accepted example is
`docs/evidence/male-player-2026-09-19/b-contact/whole-figure-color-2026-09-19/assemble.py`.

## Freeze and review the complete family

Freeze each accepted direction and state with hashes before the next edit. Verify untouched
frames byte-for-byte, native canvas and anchors, protected lower-body alpha, and restored upper
pixels outside the moved edge. Rebuild from frozen inputs to check reproducibility. Review both
pushing and carrying as clean eight-direction A/C/B/C PNG sheets and GIFs: an unchanged carrying
preview cannot demonstrate a carrying correction. Use nearest-neighbor enlargement and recorded
phase timing; include both native and enlarged views. Keep diagnostic overlays separate.

Install only the accepted family. Keep original generation records immutable and use explicit
manifest overrides for accepted derivatives; verify runtime bytes against those derivatives,
rebake, and check the region in `assets/atlases/baked/regions.json`. Static
sheets establish poses; a runtime burst establishes the moving assembly.
