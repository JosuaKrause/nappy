# Pram transparency extraction

The two approved PLAYTEST-37 layered pram sheets are preserved in the rejected-art archive;
these versioned siblings retain their original 1448×1086 pixel geometry and are RGBA PNGs.

The reproducible command is:

```sh
uv run python tools/remove-checkerboard.py \
  docs/evidence/archive/rejected-graphics/pram-registration-2026-09-08/pram-layered-v3-draft.png \
  assets/illustrated/modular/pram-layered-v3-draft-transparent.png
```

Run the same command with `pram-layered-v3-alpha-attempt.png` and
`pram-layered-v3-alpha-attempt-transparent.png` for the second sibling.

The extractor makes bright, near-neutral connected regions of at least 12 pixels transparent,
then clears one neighboring pixel of bright neutral fringe. RGB samples and existing alpha on
retained pixels remain unchanged. This removes the checkerboard, including enclosed handle and
wheel gaps, while retaining chromatic pale blankets and dark outlines. The matte uses hard alpha
on these opaque inputs; it does not reconstruct the original antialiased edge coverage.
It is a bounded neutral background heuristic; it does not claim mathematically lossless removal
of an arbitrary checkerboard, and its outputs require visual review before runtime use.

The script refuses to overwrite an existing destination; choose a fresh output path when rerunning.
The dark/blue review sheet is `docs/evidence/pram-transparency-review.png`. The runtime pram
manifest consumes the approved transparent v3 draft; the alpha-attempt sibling remains review
material.
