---
name: svg-art
description: Create, revise and visually review the repository's SVG game graphics, including directional variants, grounding and asset integration. Load before editing SVG assets; raster illustration work uses illustrated-png instead.
---

# SVG artwork

**The rules not to miss:**

- **An SVG is the finished asset: nothing is converted to PNG for now.** A conversion waits until
  the player finds a use for one (inbox #927 in tiny-lark), so no PNG step follows an SVG.
- **Look before designing**: the existing SVG, a rendered image of it, and its binding in
  `docs/GRAPHICS.md`.
- **World position, visible bounds and collision are three things.** Art never repairs physics.
- **A side view and an end view are separate drawings**; rotating one does not make the other.
- **Open and inspect every rendered image.** A command that succeeded only wrote a file.
- **A new picture needs its line in `assets/atlases/membership.json`**, or nothing can draw it.
- **A game SVG has no `.import` sidecar** (the **godot** skill, "Structure").
- **A new file under `docs/evidence/` is committed with `git add --sparse <path>`** in an agent's
  worktree, which leaves that folder out.

SVG is the editable source for game graphics: of subject, geometry, pose and placement, for new
directional and state variants, UI and identity assets as well as standing game entities. Where a
registered PNG derivative of an SVG exists, the SVG is preserved alongside it; the PNGs that exist,
and the one family with no base SVGs, are the **illustrated-png** skill's. Author vectors directly
with patches; use the existing family as the style reference. Read `docs/GRAPHICS.md` for the
asset's actual binding and the owning queue entry under `docs/todo/` before designing. Follow
`playtest-feedback` for player requests and `verify` for runtime checks; this skill adds the visual
work those checks cannot judge.

`references/drawing-and-rendering.md` is read before drawing or revising an SVG and before
rendering one for review: silhouette first, the projections of a vehicle, fixed points across
modular states, one character across every facing, contact shadows, partial motion, the scratch
script that renders with the game's own SVG parser, and validating the XML apart from rendering:
an XML comment cannot contain a double hyphen, and a forgiving Godot import is not XML validation.

## Establish the picture's contract

- Inspect the existing SVG **and a rendered image**, alongside nearby actors, props and ground.
  Read the caller: a single sprite, repeated segment, whole-street scene and TileSet tile have
  different registration and scale contracts. Trace indirect `.tres` and scene references too.
- Record the native canvas, intended world footprint, ground anchor, facing convention and
  state variants. Tiles are sized from `Tuning.TILE_SIZE`; a multi-tile decal uses the requested
  footprint rather than scaling a small actor arbitrarily.
- Keep world position, visible bounds and collision distinct. A circular collision diameter
  does not justify stretching an end-view car to fill a square. If the art reveals a collision
  mismatch, document the gameplay question instead of changing physics as an art repair.

## Integrate and leave the inventory accurate

SVGs under `docs/evidence/` are evidence, not assets: none of this section applies to them;
rejected-graphics governs the archive.

**A game SVG has no `.import` sidecar**: `art/` is behind a `.gdignore` (the **godot** skill,
"Structure", owns that rule and says what the bake does instead). Check both
revisions if GitHub's image-diff viewer fails: malformed XML in the old side can break the
comparison while the new file is valid. Link a current rendered preview rather than repeatedly
altering valid artwork.

Update `docs/GRAPHICS.md` with file paths, registration and actual current use. A prepared asset
stays unbound in the catalogue until code or a resource uses it. In graphics-dependent milestones,
name the files and intended states to reuse without closing outstanding gameplay decisions. The
rejected-graphics skill governs what a draft's disposition keeps or discards, and a human's review
outcome goes in a decision record under `docs/decisions/`; preserve the player's words in the playtest record. PR image
links use a commit containing the image, as `committing` requires.

Run import/boot and XML/doc lint. Add focused tests only for behavior a picture cannot verify,
such as axis selection or grounding. Test the drawing path the runtime actually takes; do not
re-derive repetition arithmetic for a whole-scene renderer that never repeats a texture.

A new picture also needs a line in `assets/atlases/membership.json` naming its group — `members`
if both bakes draw it, `members_png`/`members_svg` if only one does — or nothing can draw it:
`AtlasLibrary.region()` answers null with an error for a name it does not know.

Commit each finished image promptly after visual review and validation. Do not wait for the whole
family. Keep inseparable body/trim layers together so a
commit still contains a reviewable image.
