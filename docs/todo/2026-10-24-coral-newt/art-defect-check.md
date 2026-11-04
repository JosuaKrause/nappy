# A check that names an art defect where it is

From pxl's critic (`pxl/src/core/lint.ts`).

**Build:** a small check over a rendered SVG or PNG that reports a named defect at its coordinates
with an overlay: stray single pixels, colours outside the family's palette, near-duplicate colours,
things **svg-art** warns about in prose today. A rule a tool checks beats a rule that has to be
remembered.
