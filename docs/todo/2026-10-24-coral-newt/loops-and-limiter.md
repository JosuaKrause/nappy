# Seamless loops and a final limiter

From chirp's render (`chirp/src/core/project.ts`, the seamless-loop block; the limiter in
`chirp/src/core/fx.ts`).

**Build:** a loop is rendered longer than its length and the tail folded back onto its start, so a
release or a reverb rings across the seam instead of dipping; a peak limiter runs last. It serves
the per-act ambience beds (M100's audio), so it is built with the first bed, not before.
