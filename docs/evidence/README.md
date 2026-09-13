# Evidence

**Every log, telemetry map or screenshot a doc in this repo refers to lives in this evidence tree.** *(Asked for on
2026-09-01: "when referencing an image or log make sure to copy the files into the repo so the
reference doesn't get lost when cleaning up. make sure all current references are in the repo so I
can clean up the log folder.")*

The rule is in the [feedback skill](../../.claude/skills/feedback/SKILL.md), "Evidence lives in the repo". The
short version: `user://telemetry/` is a scratch directory the player has to be able to empty, and a
finding whose evidence was in it stops being checkable the moment they do. Approved design
references stay at this level; historical runtime captures are organized by date under
[`archive/session-captures/`](archive/session-captures/), and rejected graphics are under the
guarded [`archive/rejected-graphics/`](archive/rejected-graphics/) archive.

Keep the original filename. It carries the run's timestamp, seed and commit, which is most of what
makes the file worth having.

## Graphics recipes

The scripts, retained inputs and regeneration commands for illustrated graphics and reviews are
indexed here. Run Python recipes through the repository's locked `uv` environment. Image generation
can produce different pixels on another call; extraction and assembly use the retained output.

| Graphics or review | Recipe and inputs |
| --- | --- |
| P1's preserved pushing family and stroller artwork | [Comic rig generation and registration](comic-rig-2026-09-12/GENERATION.md) |
| P2's three-pose pushing walk and grounded contact | [Generation, registration and GIF recipe](comic-pushing-strides-2026-09-12/GENERATION.md) |
| Carrying redraws and identity comparison | [Carrying generation and registration](comic-carrying-redraw-2026-09-12/GENERATION.md) |
| Four named carrying versions | [Comparison script](comic-carrying-redraw-2026-09-12/versions/make-comparison.py) and [version inputs](comic-carrying-redraw-2026-09-12/versions/README.md) |
| D's preserved two-frame walking GIF and rollout | [Recipe, timing and source manifest](comic-carrying-redraw-2026-09-12/rollout/README.md) |
| E's three-pose carrying walk and GIF | [Generation, registration and safe rebuild commands](comic-carrying-strides-2026-09-12/GENERATION.md) |
| F's whole-figure carrying correction and GIF | [Source review, generation, registration and rebuild commands](comic-carrying-hip-motion-2026-09-12/GENERATION.md) |
| Stroller contact and grounded scale in PNG and SVG | [Assembly script, placements and regeneration commands](pram-contact-2026-09-12/MEASUREMENTS.md) |
| Trees, bollard and rooftop equipment | [City prop generation and registration](comic-city-props-2026-09-12/GENERATION.md) |
| Garbage and litter | [Comic prop generation and registration](comic-props-2026-09-12/GENERATION.md) |
| Outdoor ground tiles | [Tile generation and registration](style-transfer-tiles-2026-09-12/GENERATION.md) |
| Sidewalk material comparison | [Source pairs, transfer, registration and neighbor panels](sidewalk-continuity-2026-09-12/GENERATION.md) |
| Sidewalk join comparison in generated layouts | [Tile selection, frozen inputs and street assemblies](sidewalk-layout-review-2026-09-12/GENERATION.md) |
| Shared ground bases and transparent details | [Frozen artwork, stencils and component assembly](layered-ground-2026-09-12/GENERATION.md) |
| Muted quiet-square paving | [Generation prompt, raw image and repeat-neighbor registration](quiet-square-2026-09-12/GENERATION.md) |
| Muted plaza paving | [Generation prompt, raw image and repeat-neighbor registration](plaza-paving-2026-09-12/GENERATION.md) |
| Composed streets and varied grass in generated layouts | [In-engine composition and repeatable layout review](layered-ground-layout-2026-09-12/GENERATION.md) |
| Forest and park ground in the actual Main scene | [Runtime texture and cell probe](grass-runtime-2026-09-12/GENERATION.md) |
| Player generation-reference SVG family | [Authoring sources, runtime pairings and frame roles](../graphics-creation/player/README.md) |
| Logo, social card and exported icons | [Identity generation and registration](comic-identity-2026-09-12/GENERATION.md) |

## What is here

| file | what it is | referenced by |
| --- | --- | --- |
| `nappy-svg-mother_carrying_{front,back,side}_{a,b}.png` | Six Godot-rendered mother-carrying-baby frames, enlarged threefold. | [GRAPHICS.md](../GRAPHICS.md), prepared player variant; [DECISIONS.md](../DECISIONS.md), Mother carrying the baby |
| `svg-impact-crater-1x1.png`, `svg-impact-crater-2x2.png`, `svg-impact-crater-3x3.png` | Godot-rendered crater decals enlarged threefold for inspection. | [GRAPHICS.md](../GRAPHICS.md), prepared crater assets; [DECISIONS.md](../DECISIONS.md), Impact-crater artwork |
| `svg-fence-preview-2026-09-09.png` | Current fence tile rendered independently of GitHub's image-diff viewer. | [DECISIONS.md](../DECISIONS.md), Fence image-diff error |
| `svg-seals-before-2026-09-09.png`, `svg-seals-after-2026-09-09.png` | Rendered SVG seal comparisons, fitted per cell for silhouette inspection. | [DECISIONS.md](../DECISIONS.md), SVG artwork and upcoming milestone assets |
| `svg-upcoming-assets-2026-09-09.png` | Reviewed checkpoint, pointing, district and sound assets plus refreshed fence/fire pictures. | [TODO.md](../TODO.md), owning milestone asset notes |
| [Environment source review](svg-environment-2026-09-10/INVENTORY.md) | Native/3× sources, tile repetition, facade overlays and chalk acknowledgement; per-source intended use and work item in `sources.csv`. | [GRAPHICS.md](../GRAPHICS.md), prepared environment kit |
| [Vehicle and animal source review](svg-vehicles-2026-09-10/README.md) | Eight facings, layers, wing phases and per-source consumer/work-item mapping in `facings.csv`. | [TODO.md](../TODO.md), M108, eight-direction entity graphics, and M111, cars follow their turns |
| [People source review](svg-people-2026-09-10/PEOPLE-MATRIX.md) | Individual SVG layers and all eight composed facings, with state, anchor and intended binding for every family. | [GRAPHICS.md](../GRAPHICS.md), prepared people kit |
| [Sideways stair source review](svg-sideways-stairs-2026-09-10/README.md) | Native/3× replacement sources, two opposing hallway stairwells and transparent facade overlays. | [GRAPHICS.md](../GRAPHICS.md), stair placement and landing contract |
| `archive/session-captures/2026-09-09/rig-183151-seed4000-v0.8.2-33-g2b1ee38-dirty/` | Crash gameplay with separate shadows beneath cars and onlookers; whole run and capture. | [DECISIONS.md](../DECISIONS.md), SVG artwork and upcoming milestone assets |
| `archive/session-captures/2026-09-09/rig-183204-seed4000-v0.8.2-33-g2b1ee38-dirty/` | Burnt cars lying perpendicular to the road; whole run and capture. | [DECISIONS.md](../DECISIONS.md), SVG artwork and upcoming milestone assets |
| `shot-2026-09-09-seed4000-d9856f2-seal-ground-before.png` | A vertical crash scene displaced north of its ground point. | [DECISIONS.md](../DECISIONS.md), SVG seal artwork review |
| `shot-2026-09-09-seed4000-9b72a2e-dirty-seal-ground-after.png` | The same scene centred on its street with an aligned shadow; vehicle perspective remains under review. | [DECISIONS.md](../DECISIONS.md), SVG seal artwork review |
| `shot-2026-09-09-seed4242-d29eec6-seal-skip.png` | M64's skip at the kerb, the near half of a soft seal, on seed 4242 day 1. | [DECISIONS.md](../DECISIONS.md), M64 eight seal pictures |
| `shot-2026-09-09-seed4242-d29eec6-seal-burnt-out-car.png` | M64's burnt-out car, four bodies across a street, on seed 4242 day 5. | [DECISIONS.md](../DECISIONS.md), M64 eight seal pictures |
| `shot-2026-09-09-seed4000-1e3995b-seal-car-accident-east-west.png` | M64's car accident on an east–west street, drawn from the rotated asset. | [DECISIONS.md](../DECISIONS.md), M64 eight seal pictures |
| `shot-2026-09-09-seed4242-150985c-seal-car-accident-onlookers.png` | The accident on a north–south street with the game's own person figure as each onlooker. | [PLAYTEST-50.md](../playtests/PLAYTEST-50.md), [DECISIONS.md](../DECISIONS.md), M64 |
| `archive/session-captures/2026-09-09/run-163539-seed2295276695-v0.8.2-27-gc3305c2/` | Playtest 50's whole run: the log, the day-5 maps, two asked-for stills and the game's own capture of the guard robber's chase from inside a building. | [PLAYTEST-50.md](../playtests/PLAYTEST-50.md), `TODO.md` M100 |
| `shot-2026-09-09-seed4242-21d3ba2-signal-head-back-before.png` | A signalled junction on seed 4242 with the north-facing head still drawn face-on, red lamp toward the camera. | [DECISIONS.md](../DECISIONS.md), M95 |
| `shot-2026-09-09-seed4242-21d3ba2-signal-head-back-after.png` | The same junction with the north-facing head drawn as its back, no lamp. | [DECISIONS.md](../DECISIONS.md), M95 |
| `archive/session-captures/2026-08-31/run-2026-08-31T205921-seed8000-7367ab0-dirty-map-day01.png` | Day 1's plan on `feature/the-calm-has-a-shape` at `7367ab0`, seed 8000. | [PLAYTEST-17.md](../playtests/PLAYTEST-17.md), finding 1 |
| `archive/session-captures/2026-09-01/rig-2026-09-01T014558-seed4242-f604488-dirty-map-day01.png` | Day 1 of seed 4242 before M55's gap weighting. | [DECISIONS.md](../DECISIONS.md), M55 |
| `archive/session-captures/2026-09-01/rig-2026-09-01T014420-seed4242-f604488-dirty-map-day01.png` | The same day after M55's gap weighting. | [DECISIONS.md](../DECISIONS.md), M55 |
| `archive/session-captures/2026-09-01/shot-2026-09-01-seed4242-d69631a-corner-nw-before.png` | North-west corner before M55's corner fix. | [DECISIONS.md](../DECISIONS.md), M55 |
| `archive/session-captures/2026-09-01/shot-2026-09-01-seed4242-d69631a-corner-nw-after.png` | North-west corner after M55's corner fix. | [DECISIONS.md](../DECISIONS.md), M55 |
| `archive/session-captures/2026-09-01/shot-2026-09-01-seed4242-d69631a-corner-se-after.png` | South-east corner after M55's corner fix. | [DECISIONS.md](../DECISIONS.md), M55 |
| `shot-2026-09-09-seed4242-69c97bd-arterial-standing-no-caret.png` | The arterial pavement at ordinary crowd density, seed 4242, five seconds standing at `--spawn arterial`: several nearby walkers glow with their own entity halo and none carries a caret. | [tests/test_danger.gd](../../tests/test_danger.gd), `_test_the_arterial_at_ordinary_density_marks_nobody` |
| `shot-2026-09-10-seed4242-m61-shape-before.png` | A `construction` spread on seed 4242 day 2, on `main` before M61: each barrier stands on the old point-ellipse contact shadow, flat and the same shape every point object casts. | M61, "one shape per object" |
| `shot-2026-09-10-seed4242-m61-shape-after.png` | The same spot after M61: each barrier's shadow is now `GroundShape`'s own capsule, swept along the pavement rather than a single oval — a car in the same frame casts the same kind of shadow along its own travel axis. | M61, "one shape per object" |

## Why a lost log stays lost

**A run log cannot be regenerated**, and that is the part worth understanding before anybody tries:
it is a record of what a *player* did, so it is not a function of the seed. Replaying the seed on
the same commit gives a different run.

Three traces from playtests 03, 13 and 14 were already gone when this directory was made — the
scratch folder prunes itself, so evidence that lives only there is one ordinary Tuesday from being
unrecoverable. What those documents quote from them is still the record; the files behind the
numbers are not, and the citations that named them have been removed rather than left dangling.
This directory exists so that stops happening.
