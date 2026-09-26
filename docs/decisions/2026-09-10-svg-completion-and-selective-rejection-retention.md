## SVG completion and selective rejection retention — 2026-09-10

M103, the drawings the queue owes, has its prepared sources: the environment set adds 81 SVGs
and revises the vent's first rotor phase; the vehicle/animal set supplies the mouse and riot-van
end view. Native and 3× review sheets, tile repetition, frontage overlays and chalk comparison
are preserved in `docs/evidence/svg-environment-2026-09-10/`, with precise source registration in
`sources.csv`. The separate vehicle/animal inventory is in
`docs/evidence/svg-vehicles-2026-09-10/`. All assets have XML validation and import sidecars.
The work changes no runtime binding. The queue keeps integration with each gameplay owner and
the detailed M108/M111 directional-binding and car-turning items; the source list is archived below.

Review choices open to overturn: the vent's symmetric rotor advances an eighth-turn so the phase
is visibly different; a quarter-turn would repeat the same cross. The water tank uses a 32×48
canvas to preserve its open supports. Litter alpha fits within ten native pixels. The alley
alternative, acknowledgement tick and optional explosion burst are prepared review candidates.

### M103 — Original source-art specification

[PLAYTEST-53](../playtests/PLAYTEST-53.md) authorizes completing the missing SVG artwork now;
PNG conversion remains in M109, convert the SVG catalogue to PNG.

> "create a comprehensive list of graphics that need to be generated for *all* open items. create a
> new todo item with the list so it can be picked up independently and the graphics will be ready
> before implementation of any of the functionalities start"

**One list, every open item, so a picture is never the thing an implementation waits on.** Each
entry names the owning milestone, the file it becomes, the family it joins and the contract the
code will hold it to — canvas, anchor, projection — so it can be drawn cold, reviewed with the
**svg-art** skill, and filed in `GRAPHICS.md` as *prepared* until its milestone binds it. Drawn as
SVG first: every PNG needs an authored SVG source, and M108, eight-direction entity graphics,
and M109, convert the SVG catalogue to PNG, cover direction and transfer work. **A prepared picture is not a
binding**: nothing here changes what the game does, and the milestone that owns each one still
decides placement, timing and rules. **Anything that repeats along a street comes in a few
variations** *(2026-09-10: "we need a few variations for some of these items (like store
fronts)")*: the entry says how many, and a family is named by a glob only when the glob names
every member.

The families and their contracts are in `GRAPHICS.md`: standing things are bottom-centre anchored
through `Sprites.draw_standing()` and mirror about that point; a vehicle that travels has a side
view (east, mirrored for west) and an end view (north or south, one picture, authored proportions);
a seal or scene that follows a street has an east–west picture and a `_vertical` sibling rather
than a rotation; ground tiles are 32×32 in `assets/tiles/` and reach the game through
`assets/ground_tileset.tres`; the checkpoint kit keeps its own off-centre anchors in SVG comments.

**To draw** — nothing in this list exists yet:

- [ ] **M56 — `assets/events/riot_van_end.svg`.** The night raid's van seen end-on, for the frames
      it hunts north or south. Matches `riot_van.svg` (54×38, side view) the way
      `unmarked_van_end.svg` (32×48) matches `unmarked_van.svg` (50×32): narrower than the side
      view, taller, authored proportions, not mirrored. Bound by M56's riot-van item through
      `EventInstance._draw_vehicle`, which selects side or end from the heading
- [ ] **M100 — `assets/tiles/alley.svg`, revised so an alley does not read as a roof.** Playtest
      50 read the two-tile alley behind a building as its roof (*"the robber is stuck inside the
      roof"*). Conditional on that reading persisting in the next played session — the item is
      filed under M100's open design questions — but the picture can be drafted now: same 32×32
      tile contract, distinct at a glance from `roof.svg` and from the pavement, and it must still
      tile seamlessly with its own neighbours. Draft it, put it beside the current tile in the
      review render, and let the played verdict choose
- [ ] **M100 — the chalk mark, made unmistakable, as one option among four.** Playtest 50 could not
      tell a mark had been touched (*"how do I know I stepped on the chalk"*). Today the touch is a
      colour change from `Palette.CHALK` to `CHALK_DONE`, both code-drawn. If the player's answer to
      that open question is *the mark's colour made unmistakable*, that is a palette pair rather
      than an SVG; if it is a touched-mark picture, it is a ground decal in the crater family
      (centre-anchored, one tile). PLAYTEST-53 authorizes preparing a distinct touched-mark SVG
      for review now: `assets/props/chalk_mark_touched.svg`, 32×32, centre anchor (16, 16).
      Preserve the existing mark and add her acknowledgement: "the narrative can be that she
      adds something to the mark to indicate that she has seen it". Compare it with the current
      mark; binding stays with M100, small, real, and nobody's
**The interior, for M102** — the apartment section is a second small map drawn with the ground
`TileMapLayer` and the same oblique view as the city: floors are 32×32 tiles chosen by type and
exposed edge, walls stand along a room's north edge in elevation the way a building's front does,
and props are bottom-centre anchored on the floor. The room list is the player's, 2026-09-10:

- [ ] **M102 — the hallway.** *("we need a hallway with windows that can flash (from the implied
      bombs) we need a hallway floor … doors to the stairway (only visible from inside the stairway
      -- in the hallway the doors are at the bottom and can be implied by the edge of the
      flooring.")* `assets/interior/hallway_floor.svg`, edge-aware like the street tiles;
      `hallway_wall.svg` and `hallway_wall_window.svg` for its north wall, plus
      `hallway_wall_window_flash.svg`, the same window lit white for the one or two frames an
      off-screen explosion throws light through it — the flash is the explosion row's cue indoors,
      where no crater can be seen; and `hallway_floor_edge_s.svg`, the hallway's south edge with
      the apartment doors' thresholds drawn into the floor's edge, since the doors themselves are
      below the view and never drawn
- [ ] **M102 — the stairwell.** *("we need a staircase, a mechanical looking floor for the
      staircase shaft.")* `stair_down.svg`, a flight one tile wide that reads as *down* at a glance
      — going onto it is going to the next floor's map; `stairwell_floor.svg`, checker plate or
      grating, so the shaft reads as the building's machinery rather than another corridor; and
      `stairwell_door.svg`, the door back onto a floor's hallway, in the stairwell's north wall and
      seen only from inside the stairwell, which is the player's rule
- [ ] **M102 — the entrance, blocked.** *("we need a main entrance door and thrown together
      furniture that blocks it.")* `entrance_door.svg`, a double door wider than `door.svg`, and
      `entrance_barricade.svg`, the furniture heaped against it — a wardrobe, chairs, a mattress —
      drawn so it reads as *thrown together* rather than built, and as *not this way* from across
      the hallway. Two pictures rather than one, so the door can be seen behind the pile
- [ ] **M102 — `assets/interior/chandelier.svg`.** *("maybe chandeliers for lightning inside the
      building.")* A hanging fixture drawn over the hallway with a pool of light on the floor
      beneath it, the interior's one light source; whether it swings under the explosions is the
      milestone's call, and a second frame is cheap if it does
- [ ] **M102 — the basement.** *("a gloomy floor for the basement and raw brick walls. a puddle
      tile.")* `basement_floor.svg`, dark and stained, edge-aware; `basement_wall_brick.svg` for
      its north walls, raw brick where the hallway is plaster; and `puddle.svg`, a floor overlay
      tile the corridor is dotted with, which the steam row stands beside
- [ ] **M102 — `assets/interior/emergency_exit_door.svg`.** *("an emergency exit door (the service
      entrance).")* The push-bar door at the end of the basement corridor, the finale's way out
      onto the city; plainer and narrower than the home door so the two are never confused
- [ ] **M102 — `assets/interior/lift_door_dead.svg`.** The non-functioning lift on the hallway: a
      closed door pair, dark, with whatever says *dead* at a glance — no lamp, or a hand-written
      notice
- [ ] **M102 and M100 — `assets/events/mouse.svg`.** The apartment's own small event, and an
      alley's *("btw we can reuse the mouse for alleyways as well", 2026-09-10 — the row is
      M100's)*: a moving picture in the `cat_running.svg` family, tiny, side view mirrored for
      west. One picture is enough; a mouse that startles is a short pulse and does not need a
      second pose, and one drawing serves both rows
- [ ] **M102 — `assets/events/steam.svg`.** A stationary field in a basement corridor: a vent or a
      burst pipe with a plume, bottom-centre anchored, drawn so the pulse animation can scale the
      plume the way `flame.svg` is scaled by the fire animation. The plume is the field's picture
      and must not be mistaken for the sound-pulse arcs
- [ ] **M102 — an explosion picture, only if wanted.** The brief's explosions are off screen: their
      sound is `sound_pulse.svg`'s arcs once M100's sound lines bind them, and their mark is one of
      the three prepared craters. A flash or a smoke column at the screen's edge is optional and the
      milestone decides; listed so that decision is taken with the option drawn rather than
      imagined

**The city degrading, for M105** — *(2026-09-10: "we need cracked street/sidewalk tiles to be able
to deteriorate the city. we need loose garbage (eg eaten apple, newspaper, etc) that can be spread
around throughout the city to show basic services failing towards the later acts … we need garbage
sacks that can be placed in alleyways at first and at the side of buildings later on as the city
degrades.")*

- [ ] **M105 — cracked ground, in `assets/tiles/`, at several levels.** *(2026-09-10: "floor tiles
      of the city need different levels of cracks … so we can add variety and gradient.")* Levels
      are the gradient and patterns within a level are the variety. For the road tile, the pavement tile, and
      the alley if it reads differently: a ladder of three variants — hairline, cracked, broken
      (a chunk missing, weeds through it) — each a drop-in for its base tile in
      `assets/ground_tileset.tres`, same 32×32 and same edge behaviour, so `GroundTiles` can swap
      one for the other per tile without a new type, and so the level a tile shows can rise with
      the day. Two patterns per level so a run of them does not repeat visibly
- [ ] **M106 — street trees.** *(2026-09-10: "we could also add trees that can be placed in the
      street. right now the fallen tree doesn't make that much sense.")* `assets/props/tree_pit.svg`,
      a square grate or bare-earth pit one tile wide, centre-anchored on the pavement, with the
      existing `tree_a.svg` / `tree_b.svg` standing in it — the canopy is reused, so the new
      drawing is only the ground it grows from. Whether a street tree wants a slimmer canopy than a
      park's is the review's call
- [ ] **M105 — loose litter, in `assets/props/`.** A family of small ground decals, centre-anchored
      like the craters: `litter_apple.svg`, `litter_newspaper.svg`, `litter_cup.svg`,
      `litter_bag.svg`, `litter_can.svg` — five or six, each under a third of a tile, drawn flat
      on the ground so they never stand up or cast a shadow
- [ ] **M105 — garbage sacks, in `assets/props/`.** `garbage_sack.svg`, one tied black sack,
      bottom-centre anchored, and `garbage_sacks_pile.svg`, three or four heaped, the alley's
      version; both stand against a wall the way `door.svg` does and both get a shape under M61

**Roofs and fronts, for M106** — *(2026-09-10: "we need stuff on top of roofs -- we have an air
duct already -- it needs to be animated. but we need other things on roofs as well (there are
reference photos to draw ideas from). we need more varied building fronts. storefronts, fire
escapes.")* The reference photos are in `docs/reference/`: `rooftop-hvac-units-01.jpg`,
`rooftop-duct-run-01.jpg`, `rooftop-skylights-01.jpg`, `rooftop-vents-fire-escape-01.jpg`,
`rooftop-flat-brick-01.jpg`, the two `rooftop-parapet-*` pictures and `rooftop-hvac-ducts-01.mp4`
for the roofs; `storefront-row-awnings-01.jpg`, `storefront-row-souvenirs-01.jpg`, the three
`storefront-row-taco-bell-*.jpg` and `street-fire-escape-yellow-cab-01.jpg` for the fronts.

- [ ] **M106 — the vent, animated.** `assets/props/industrial_vent.svg` (32×32 roof unit) becomes
      frame `a` of a pair, and `industrial_vent_b.svg` is the same unit with the fan a quarter turn
      on, so alternating them at a walk's cadence reads as turning
- [ ] **M106 — roof furniture, in `assets/props/`, each a 32×32 or 64×32 roof unit like the
      vent.** `roof_hvac_unit.svg` (a boxed condenser with a grille), `roof_duct_straight.svg` and
      `roof_duct_corner.svg` (a run that can be laid along a roof), `roof_skylight.svg` (a raised
      glazed pitch), `roof_vent_stack.svg` (a short pipe with a cowl), and `roof_water_tank.svg` (a
      tank on legs, the tallest of them, which sets whether a roof unit may cast a shadow onto the
      roof at all). Seen from the same oblique angle as the roof tiles, so a unit's south face
      shows and its north does not. The HVAC unit and the skylight come in two variations each,
      since they are the ones a roof repeats
- [ ] **M106 — fronts, in `assets/buildings/`, in variations.** Ground-floor facade tiles that
      stand where `wall_base.svg` does, **four storefronts** — `storefront_{a,b,c,d}.svg`, a
      grocer, a café, a pharmacy, a shop with a sign — each in three states: plain, under an
      awning (`storefront_a_awning.svg`, which overhangs the pavement by a few pixels and is the
      one front that is not flush), and shuttered (`storefront_a_shuttered.svg`, behind a rolled
      steel shutter, for M105's later acts) — twelve tiles that share one door position so a
      street of them lines up. **Two fire escapes**, `fire_escape_{a,b}.svg`, overlays the height
      of two wall cells with a ladder to the ground, drawn over `wall.svg` cells rather than
      replacing them, so a facade keeps its windows behind it. And **two more window pairs** in
      the `window_{dark,lit}.svg` family — a taller sash and a shuttered one — so a residential
      facade is not one window repeated

**Already drawn — nothing to do, listed so the list is complete.** M56's roadblock guards use
the prepared `assets/checkpoints/guard_standing.svg` and `guard_lunging.svg` pair. M65's eight
`protester_point_*.svg` poses. M100's `industrial_vent.svg`, `civic_portico.svg`, `sound_pulse.svg`,
and `tree_{a,b}.svg`. M101's `flame.svg`, `rubble.svg`, `fire_engine.svg` and `fire_engine_end.svg`.
M102's six carrying frames, three craters, and every truck, van, seal, guard and flame it reuses
from the live tables; the baby-state cue over the bundle is the existing `baby_{zzz,fuss,cry}.svg`.

**Needs no picture.** M61's shadows and the field's visibility are code-drawn from the shape, and
there is no shadow SVG to draw. M96 to M99 own no drawing;
M99's building type that closes four streets composes from the existing wall and roof tiles unless
its milestone decides it should read differently from a big building, which is a question for
then. M100's accessibility, controller, save and audio items own none. M79 is tabled and its facade
art is not owed until it is picked up.

---

### Source-art scope and retention decisions

The completed SVG-only pass adds 242 source assets: 81 environment/interior sources, 78 vehicle,
animal and rider sources, and 83 directional people sources. The existing unbound industrial vent
receives its first visible rotor phase. The people inventory is
`docs/evidence/svg-people-2026-09-10/PEOPLE-MATRIX.md`; the vehicle/animal `facings.csv` specifies
all eight headings, layer order and permitted mirrors. Native/3× source and composite sheets
cover every authored direction and state. Existing canonical event sources remain live, and
the added directional sources remain unbound pending M108, eight-direction entity graphics.

The people review uses authored body planes, limb placement and prop occlusion rather than
head-only changes. The tan chatting prams reuse the matching player-pram geometry with the
event palette; west mirrors also mirror held props. The guard's lunging anchor remains (17,44)
within its 36×44 canvas. Existing protester pointing directions are arm directions while their
body faces the viewer; they remain separate from the new movement-facing protester sources.
These symmetry and composition choices are recorded for human review, open to overturn.

M108's source checklist was: audit every entity drawing and caller with a complete facing/state
matrix; complete crowd layers and people, including carrying/talking/attack poses; complete
animals and riders, including wing phases; complete crowd and event vehicles with real front,
rear and diagonal projections. Each group preserves native scale, anchors and event identity.
That source checklist is fulfilled by the three inventories. Runtime use remains open in the
expanded binding tasks, including the player's requested M111, cars follow their turns.

Final integrated source verification: all 242 new SVG paths are covered by the intended-use
inventories and family mappings, every new source parses as XML and has its import sidecar,
and import/boot plus documentation lint pass in the main checkout. No `.import` files remain
below its `.gdignore` folders. Runtime sources, tests and the ground TileSet match the merged
main tip; the focused merge tests above remain the behavior check. Native/3× rendered review
evidence establishes source geometry, not runtime integration. The PR proposes these candidates
for human review and does not include illustrated PNG conversion.

PLAYTEST-53 requests all missing graphics, limited to SVG authoring for this pass. The work
covers M103, the drawings the queue owes, and the source-art portion of M108, eight-direction
entity graphics. Runtime integration remains a separate M108 item; M109, convert the SVG
catalogue to PNG, retains the later transfer work. Prepared environment assets do not implement
their owning gameplay milestones.

The player says: "don't store every rejected attempt in the repo only the ones you suggest
for human review". The SVG, illustrated-PNG and rejected-graphics skills now preserve rejected
art only when it was suggested for human review. Internal drafts stay outside the repository.
This narrows the previous blanket preservation instruction for future attempts; existing
historical review records are retained.

The chalk-mark question was asked during authoring. The player requested a distinct touched-mark
SVG for review, then supplied its meaning: "the narrative can be that she adds something to the
mark to indicate that she has seen it". The prepared picture preserves the original circle and
crossing strokes and adds her acknowledgement. M100, small, real, and nobody's, owns the eventual
feedback binding; this does not introduce a quest marker before the first encounter.

The player also requested cleanup of the previous PNG run and asked whether `docs/.gdignore`
landed. It is tracked; the 20 `.import` files found beneath `docs/` were copied into the rejected
illustrated archive with former runtime textures. They were removed because documentation
evidence is excluded from Godot import and those sidecars point to obsolete runtime paths.
The follow-up broadens cleanup to every folder excluded by `.gdignore`. A filesystem scan
finds `docs/`, `tools/` and the generated `.godot/` cache excluded; no `.import` files remain
under any of them. Active game-asset import settings remain tracked.

The three rejected diagonal draft sets from the preceding PNG run were removed from the current
tree: `diagonal-svg-2026-09-10-v1`, `-v2` and `-v3`, including 40 preview PNGs and the third set's
source manifest. The player confirmed this scope by naming the `-v2` folder. They remain
recoverable from Git history. Accepted runtime textures and their generation and comparison
evidence remain available.

The player clarifies retention: "also keep if a human has rejected them. only if you reject
them don't store them". A human rejection is preserved whether or not an assistant recommended
the candidate first. Only drafts rejected internally by the assistant before human review are
discarded. The graphics skills state this distinction explicitly.

The player asks to "commit whenever you have a new image done". Completed SVGs are committed
after visual review and validation, with their import sidecars; inseparable body/trim layers
form one image. This replaces batch commits for the image authoring work.
