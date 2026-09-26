## M171, the ground page per bake mode — built 2026-09-20

Pull request #256, [PLAYTEST-110](../playtests/PLAYTEST-110.md): the player opened the baked
`ground` page and found whole SVG tiles no default build draws and a second grass.

**Built.** A group in `assets/atlases/membership.json` has `members`, baked by both modes, and
the optional `members_png` and `members_svg`, baked by one. The bake rejects any other key in a
group record and a picture listed twice in the mode being baked. Only `ground` changed: twelve
whole tiles the recipe composes nothing for in `members` (`tiles/mountain`, which `CityEdge`
draws, among them), the 31 layers in `members_png`, and the 46 whole tiles of composed sources
in `members_svg`. A default page went from 89 regions at 308×342 to 43 at 172×308, an `--svg`
page to 58 at 206×342. **An `--svg` bake reads no layer** — `_layer_recipe()` answers `{}` for
it and the route-kerb twins tint by the stone's fill colour — so the orchestrator's assumption
held. A mode's bake neither reads nor hashes the other mode's members: touching
`art/tiles/road.svg` leaves a default tree up to date. `tools/audit-pck.sh` counts every
mode's members, since its question is whether an authoring source reached the pack.

**The fallbacks are errors.** `build_tile_set()` branches on the recipe's own `source_bases`
table, and a composed source's picture is its composition or nothing: `Ground source 8
('tiles/sidewalk_kerb_n') cannot be composed: the baked 'ground' page is missing the component
'curbstone'`, with the same shape for a base, a damage pool, a stencil, a grass feature and a
route-kerb twin. The reason travels up through a `missing` out-parameter so one source writes
one line. A recipe that does not load is one error and a null TileSet rather than 46.
`assets/ground_tileset.tres` is unchanged.

**Pixel identity.** A throwaway per-cell SHA-256 before and after, in both modes, with the
import pass between bakes: 173 lines identical in a default bake, 69 in an `--svg` one, the
whole sheets included.

**Tests.** `tests/test_atlas_ground.gd` derives what the mode's page must hold from the recipe
and the `.tres`, compares as a set both ways with both counts asserted, and names the cracked
tiles, `tiles/grass` and `tiles/forest` for a default bake. Moving `art/tiles/road.svg` into
`members` fails three checks by name. **No test provokes the incomplete-recipe error**: an
engine error inside a suite is red whether or not it was expected, so what is checked is the
condition that keeps it unreachable.

**Rejected.** A per-member `"modes"` object, which rewrites every member line to say something
about 46; a `ground` special case in the bake, which puts the knowledge in code rather than in
the file a picture is added to; and an incremental bake — offered to the player, who left it to
the orchestrator: it saves seconds per art change and costs per-group state in the manifest
and `--check`. Worth raising again if a bake grows slow enough to be felt.
