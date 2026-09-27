# Authored leg geometry preview

The side proposal gathers the four legs beneath the frozen A body using the authored SVG B
as pose authority. Its [clean A/B pair](review/dog-body-pair.png) and
[color-free leg silhouettes](review/dog-leg-silhouette-pair.png) expose the actual contour
movement. The [overlay](review/dog-leg-silhouette-overlay.png) uses cyan for A-only alpha,
magenta for B-only alpha and black for overlap; it contains no coat-color information.
Diagonal corrections are pending. This is evidence only; visual acceptance remains open.

The exact generation prompt and input roles are in [PROMPTS.md](PROMPTS.md). Built-in
`image_gen` supplies the artwork. Registration applies one uniform scale from the generated
canvas into A's original crop plane, then the frozen A native transform; it does not paint,
warp, composite limbs or apply SVG alpha. Body and paw differences remain visible in the pair.

Run `uv run python docs/evidence/comic-dogs-2026-09-27/walked-revision-4/assemble.py build`
to reproduce the derivatives, or replace `build` with `verify` to check them. The frozen
input manifest is pinned by the recipe before any output write. The prior family images,
walked A/cardinal frames and accepted pursuing family remain untouched.
