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

## The atlas design, asked and answered

Four decisions were put to the player with a recommendation each, after a read-only inventory
of how pictures reach the game. The answer, in full:

> "png vs svg mode now should happen at build time -- so we always get png mode -- if we really
> want svg mode we need to run a custom build command locally (no need to have this in the release
> version). 1. baked on demand. for running locally check the source hashes. 2. move them out but
> make sure every reference gets updated so we don't have stale instructions or comments (code
> will fail but documentation will not) 3. we can do one events page for now 4. no, we bake each
> individual item and the composite at runtime. this is not a bottleneck and it allows for
> variety. if we baked everything either we would need to make the atlas huge or we would lose
> variety."

6. **The presentation mode is chosen by the bake, not by the running game.** A build is PNG mode:
   the illustrated PNG where one exists, the SVG's raster where none does. SVG mode is a custom
   local bake command and is not in the release. *PLAYTEST-105's two separately built resources
   selected before load · overturned by the player on 2026-09-19.*
7. **Atlases are baked on demand and are not committed.** A local run checks the source hashes
   and bakes when they differ.
8. **The authoring sources move out of the folder the engine imports**, and every reference to
   their old paths is updated with them: instructions, skills, docs and comments, since *"code
   will fail but documentation will not"*.
9. **The events are one atlas page "for now".**
10. **The ground is not baked as composites.** *Recommended: grass variants and the route-curb
    tint become bake outputs · refused by the player.* Each individual ground picture is baked
    into the atlas and the compositing stays at runtime, because it *"is not a bottleneck and it
    allows for variety"*, and baking every composite means a huge atlas or lost variety.

Three assumptions were stated alongside the questions and the player did not speak to them: no
desktop export is in scope, since no preset exists; the identity images (logo, icon, social
card) leave the game package; families with no illustrated PNG are served by the same pixels in
either bake.

## What was not spoken to

How atlas groups other than the events are drawn, beyond PLAYTEST-105's *related items together*;
what the custom SVG bake command is called.
