# Playtest 110 — What is on the ground page, and what the bake leaves behind

2026-09-20. Said in conversation while the last two consumer moves of M171, build-time atlases
replace individual textures — the ground and the events — were merging, after the player opened
the baked pages in `assets/atlases/baked/` and looked at them. No run attached.

## What the player said

On a summary that said the compositor "builds the ground from regions of the baked ground page
and uploads one composed sheet":

> "didn't we say we do the compositing of ground features live and not in the atlas?"

It does: the sheet is the runtime result of the compositing, rebuilt on every repaint, and
nothing composed is on the page. The sentence was ambiguous, not the build.

On the ground pull request's note that a source whose region the bake does not carry "now
draws nothing instead of falling back to its SVG":

> "why not bake the svg instead?" · "let's make it loud at least"

On the `ground` page itself:

> "why are the svg ground + crack textures in the atlas? and what is the purpose of the second
> grass texture?"

On the answer — that the page carries every whole authored tile `assets/ground_tileset.tres`
names as well as every layer the compositor stacks, that a default bake composes 46 of the 58
sources from layers and reads those 46 whole tiles only as a fallback for an incomplete recipe,
that the 18 whole cracked tiles have no illustrated PNG and so are baked as SVG rasters, and
that `tiles/grass` and `tiles/forest` are two more such fallbacks beside the flat
`tiles/layers/grass_base` the eight grass variants are composed on:

> "well they should not exist anymore since we composite on the fly now. I certainly don't want
> to see those svgs in the game. we can keep the prebake for svg mode only. then we don't need
> those fallbacks. baking should empty the folder before I guess?"

And, a moment later, on emptying the folder:

> "since we don't want to regenerate things that haven't changed -- just deleting doesn't cut
> it though"

As built, the bake is all or nothing: `tools/bake-atlases.sh` compares one manifest of source
hashes, and when anything differs `tools/bake_atlases.gd` writes every page again, which hands
the engine every page to import again.

Told that, and that emptying the folder is therefore free for as long as the bake stays all or
nothing, and only an incremental bake would rule it out:

> "so emptying the folder beforehand is possible"

Offered the two: keep the bake all or nothing, or keep hashes per group and rewrite only the
changed groups' pages, with the recommendation to stay all or nothing, since a changed
picture costs a few seconds of re-bake and an unchanged tree costs nothing:

> "whichever you think works best here"

On `assets/atlases/baked/head_indicators.png`, a page left on disk from before the
`head_indicators` group was folded into `ui`:

> "why does head indicators exist if ui contains them now?"

On whether the minor release may go out before the milestone's last item, "close the contract":

> "yes close the contract is needed"

## What the page held, which is what the notes are about

A default (PNG) bake of the `ground` group, 89 regions:

- 31 layers under `tiles/layers/` — four bases, the markings, 18 damage stencils and three
  grass features. All are composed from.
- 58 whole tiles. Twelve are drawn as they are, because the recipe composes nothing for their
  source: `bulkhead`, `courtyard`, `fence`, `mountain`, `plaza`, `precinct`, `quiet_square`,
  `sand`, `scree`, `spoiled`, `stoop`, `water`. **The other 46 are never drawn in a default
  bake**: `alley`, `road`, `road_main`, `sidewalk`, `grass`, `forest`, the eight road lines,
  the six crossings, the eight kerbs and the 18 `*_cracked_*` tiles, the last of which are SVG
  rasters since no illustrated PNG exists for them.

An `--svg` bake is the reverse: it draws the whole tiles, composes nothing, and finds the
route-kerb tint by matching the curbstone's fill colour on the whole kerb tiles.

## What is asked for, as statements

1. **A default bake carries no whole tile of a source the compositor composes.** Those 46
   pictures are on the page of an `--svg` bake only. No SVG raster of a ground tile is in the
   game.
2. **The fallback from an incomplete recipe to the whole authored tile is removed.** A recipe
   that cannot be composed is loud, as the missing region already is (`push_error`, which the
   test gate is red for).
3. **The bake does not leave a page behind.** The bake stays all or nothing — *left to the
   orchestrator, "whichever you think works best here"* — so every bake ends with exactly the
   pages the membership names in `assets/atlases/baked/`, and a tree holding any other page is
   stale. An incremental bake, which rewrites only the groups whose inputs changed, was
   offered and not taken: it saves a few seconds per art change and adds per-group state to
   the manifest and to `--check`. It is worth raising again if a bake grows slow enough to
   be felt.
4. **The minor release waits for "close the contract"**, as PLAYTEST-109 already said.

**Not spoken to, and the orchestrator's assumption:** an `--svg` bake drops the 31 layers in
return, since it composes nothing; `tools/bake-atlases.sh --check` calls a tree with a page no
group names stale, so the tools that re-bake on a stale tree clear it; and the package audit
fails the export on a baked page the packed region table names no group for.
