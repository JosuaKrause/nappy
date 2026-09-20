# Playtest 108 — The atlas structure is the next work, and the order around it

2026-09-19. Said in conversation while the open pull requests were being merged and the queue
was read back. No run attached.

## What the player said

On what to work on next:

> "I think we should focus on fixing the structure of texture/sprite atlases. the implementation
> we currently have is not great"

> "there are a ton of things from the last few sessions that we rather should focus on"

On the order, and on the rasterizing itself:

> "is it beneficial to render SVGs to pngs at build time as well? M159 comes after M171 (which we
> do next). M163 we can do before that I guess? what is it exactly? M164 is a bug? also important."

## What is asked for, as statements

1. **M171, build-time atlases replace individual textures, is the next milestone.** The contract
   is [PLAYTEST-105](PLAYTEST-105.md)'s; this session adds the judgement that the runtime packing
   in place is "not great" and that its structure is what gets fixed.
2. **M159, a slow frame names the frame that was slow, comes after M171.**
3. **M163, the ground atlas test builds the same reference it compares, may go before M171.**
4. **M164, engine errors make the test gate red, is a bug and is "also important".**
5. **Work the last few sessions left open comes before older queue items.** The teaching day's
   remaining measurement (M96) was offered as a decision and the player asked why it was being
   talked about again; it stays where the queue has it.

## The question about SVGs

The player asked whether rendering SVGs to PNGs at build time is beneficial as well. The answer
given: the engine's import pass already rasterizes every SVG into a texture of its own before the
game runs, so nothing parses an SVG at runtime; under PLAYTEST-105's rule that a baked picture
ceases to exist in the build, the atlas bake has to do that rasterizing itself, straight into the
atlas page, and the per-picture imported copies go away. The risk named was pixel parity if a
rasterizer other than the engine's own were used.

## What was not spoken to

Whether baked atlases are committed or built on demand; whether authoring sources may move out of
`assets/`; how events are grouped; whether the ground's grass variants and route-curb tint become
build outputs.
