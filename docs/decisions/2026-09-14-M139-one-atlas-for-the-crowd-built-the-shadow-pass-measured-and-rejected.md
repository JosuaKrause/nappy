## M139 — One atlas for the crowd · built 2026-09-14, the shadow pass measured and rejected

*(2026-09-14, [PLAYTEST-72](../playtests/PLAYTEST-72.md): "I can see lag only if the crowd is
being drawn though" — "yes, let's start with a crowd atlas".)* Two agent commits on
`feature/m139-crowd-atlas`, reviewed on the PR; the stills and whole run folders are
`evidence/m139-crowd-atlas-2026-09-14/`, `before/`, `after/` and `after-shadows/`.

**What it is.** `CrowdAtlas` (`src/crowd/crowd_atlas.gd`) packs the six per-view tables
`CrowdAgent` preloads — the walker's body and trim in both gait frames across five views, the
car's body and trim across five — into one `ImageTexture` on a shelf layout, tallest first, one
pixel of padding, and hands back tables of the same shape whose values are `AtlasTexture`s
with `filter_clip` on. Thirty sprites, the largest 52×46, so the atlas is a small fraction of
the 2048px side it asserts against. It is built lazily on first use, after every source has
gone through `TextureResolver.resolve()`, so a PNG transfer is what gets packed by default and
`--svg` packs the SVG rasters: the atlas only relocates whichever raster the resolver already
chose, and the picture cannot change by a pixel. `_draw_body()` and the entry-clearance read
go through it; the preload tables stay as the source list and as what the view suites pin the
authored views against. `Sprites.draw_standing` and the resolver needed no change — an
`AtlasTexture` reports its region as its size, and the resolver passes anything with an empty
`resource_path` through — and the new suite asserts both, plus every region inside the atlas,
none overlapping, each region's pixels equal to its source's, in both presentation modes.
`pack()` ignores its argument after the first build, the resolver's own read-once shape;
`reset_for_tests()` pairs with the resolver's.

**What it took off, on the desktop.** The desktop table's walk (`tools/shot.sh out.png 20
--seed 3265820891 --day 1 --walk 3s17e`), draws as the mean of the run log's `frame` entries
from two seconds in:

| | draws | primitives | fps |
|---|---|---|---|
| before | 581 | — | — |
| the atlas | 557 | 3903 | 111 |
| the atlas and the shadow pass | 785 | 9825 | 72 |

About 24 calls, 4%, which is one call per visible walker: the crowd field is 1600px square
and the desktop shows about 9% of it, some 21 of the 234 agents at a time, and body and trim
now share a texture, so a walker costs two calls — shadow, then body and trim in one — where
it cost three. **The phone reading is the player's to take on the next release**; the desktop
already said texture switches were not its own cost, and this is the desktop.

**The shadow pass was built, measured and reverted.** The entry gated it on the after-count
settling near two calls per walker, which it did, so the agent built it as written: one
`CrowdShadows` item at `z_index = 1` drawing every agent's shape shadow each frame, and
`_draw_body()` no longer drawing its own. Draws went **up** 41% and primitives 152%, fps down
36%. The cause is culling: each `CrowdAgent` is its own small canvas item and the renderer
skips the ones off screen, so of 234 agents only the visible score cost anything, while one
item whose content spans the whole field always intersects the viewport and draws every
shadow in the population every frame. The tree is back to the atlas alone; the evidence keeps
the regression. A version that keeps the culling — the pass split into field-cell items, or
its loop gated on the camera rect — is possible and is not filed: the atlas is the test the
player asked for, and whether the crowd's drawing is the phone's cost at all is what the next
release measures.

**Open to overturn.** The shelf layout and the read-once `pack()` were the agent's choices.
