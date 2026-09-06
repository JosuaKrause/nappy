# Luna graphics handoff

## Read first

Read `CLAUDE.md`, `docs/HANDOFF.md`, `docs/TODO.md`'s Visual overhaul section, then
`docs/PLAYTEST-27.md` and `docs/VISUALS.md`. The playtest preserves the player's full words;
the visuals document states the current target. Read the relevant skills before editing.
The orchestration and committing rules still apply. Implementation uses Luna.

The tracking pull request is [graphics overhaul PR #19](https://github.com/JosuaKrause/nappy/pull/19).
Keep it draft. A prototype, source sheet or code scaffold is not a completed overhaul. Do not
release or merge the overhaul until the entire requested presentation is implemented and reviewed.

## Current decisions

- **No diagonal grid for now.** The player briefly chose it, then explicitly tabled it again.
  Keep the current cardinal presentation and controls. Match the illustrated diagonal references'
  art style, not their projection. M79 contains the investigation and additional review notes.
- **New artwork is PNG, not SVG or pictures drawn in code.** Existing SVG assets remain until
  replaced. Their separately requested small polish PR is not the full overhaul.
- **Illustrated apartment city, not detached houses or primitive low-poly people.** Detailed ink
  contours, painted materials, substantial facades, shops, clothing folds and recognizable people
  are the target. The 3D prototype was not accepted as final art.
- **Eight directions:** N, NE, E, SE, S, SW, W, NW. Prepare unused directions too. Explicitly record
  genuine symmetry; never silently substitute an unrelated or mirrored view.
- **Modular characters:** interchangeable head/hair, torso/clothing, arms/hands, legs and shoes,
  shared pivots and registration, per-direction layer order. Start with a few variations, not a
  giant catalogue. Keep authored events visually distinct from the generic crowd.
- **Mother:** high brown bun, green coat, patterned scarf, jeans and dark practical shoes, as in
  the dedicated reference. Detailed dark pram and warmly bundled baby. Portrait HUD is not requested.
- **Grounded walking:** stance feet stay fixed on the ground while the body travels; swing feet
  lift and land, with knees solved from joints. A bob or speed-controlled sine wave is insufficient.
  Actual displacement drives travel, including collision, stops, acceleration and turns.
- **Camera-specific cheats are permitted:** shorten hidden north-side building depth, exaggerate
  facades or split a foreground front. Geometry need only read correctly in gameplay; logical
  collision and streets do not change with the drawing.
- **Occlusion:** stable local dotted/stippled reveal or a foreground cutaway, not glassy roofs.
  Preserve the player/pram, approaching threats and useful street information. Do not introduce
  warning flicker or hide the visible evidence of a real wall.
- **Everything remains in scope:** title, controls, pause, summaries, endings, HUD/touch; all
  environmental, crowd and event art; animations; late-game litter, wear and flying paper; actual
  excitement-source attribution; improved objective guidance. No new action-bar verbs or minimap.

## References and source art

All paths are relative to the repository root and are committed assets, not Downloads dependencies.

| File | Use |
| --- | --- |
| `docs/evidence/graphics-reference-urban-01.jpeg` | Main illustrated urban style reference |
| `docs/evidence/graphics-reference-urban-02.jpeg` | Additional street, vehicle, shop and crowd detail |
| `docs/evidence/graphics-reference-cardinal.jpeg` | Floor for the available cardinal perspective; not the illustrated style or detail target |
| `docs/evidence/graphics-reference-mother.jpeg` | Mother, clothing, face, pram and baby reference |
| `assets/illustrated/source/mother-turnaround-v1.png` | Generated eight-view source draft; **not runtime-ready** |
| `assets/illustrated/source/README.md` | Exact built-in generation prompt, inspection and remaining defects |
| `assets/illustrated/modular/` | Registered, transparent mother/pram part sheets, articulated mother revision, contact reviews, manifests and generation records; **not runtime-wired** |

The original mother draft is materially closer in style, but has a **baked checkerboard and no
alpha**. Its observed order is **S, SE, E, NE / N, NW, W, SW**, not the requested N-first ordering.
It remains a style reference only. The registered replacement in `assets/illustrated/modular/`
provides real-alpha mother and pram part sheets in `N, NE, E, SE, S, SW, W, NW` order, with
manifests for cells, pivots, foot/wheel anchors and draw order. `mother-parts-v3.png` separates
the mother’s leg segments and shoe cutouts so the compositor can show a planted foot and a lifted
swing foot. The art and compositor are not live gameplay binding. The player explicitly offers to
perform style transfer on usable draft sheets if generation does not achieve the target.

Use the imagegen skill for generation/editing. Built-in mode does not require an API key. Do not
silently switch to a paid CLI workflow or use SVG/code primitives as substitute artwork. Preserve
prompts and rejected alternatives in the same overhaul history. Verify actual alpha values; an
image of a checkerboard is not transparency.

## Implementation checkpoint

The playable game still uses the existing renderer. No illustrated replacement is wired into it.
The `src/visual3d/` street and actor files are isolated experiments. Additional 3D animal,
projection and screen attempts are preserved in ancestry, indexed in `docs/DECISIONS.md` under
Illustrated assets and experiment preservation. Do not revive their design by mistake.

The modular sprite work is a standalone, tested presentation component, not live gameplay:

- `src/visuals/directional_parts.gd` registers eight-direction regions and per-direction pivots.
- `src/visuals/planted_gait.gd` uses world-pixel stance/swing state and solved knees.
- `src/visuals/modular_person.gd` consumes actual applied displacement without changing a logical
  body, collision or gameplay RNG.
- `assets/illustrated/modular/` supplies registered mother and pram bundles, including articulated
  lower-body parts. `tests/test_visuals.gd` exercises their regions and a walk/stop/turn sequence.
- `Stroller` owns a zero-offset live `ModularPerson` child. It supplies only displacement that
  survived collision and shove resolution, then resets the gait with every logical player reset.
  Legacy mother/pram SVG drawing is absent while shadows, baby cues and alert cues remain.
- Crowd binding and on-screen inspection remain to be built and verified.

The standalone `scenes/dev/illustrated_street_review.tscn` consumes the layered PNG assets under
`assets/illustrated/street/`: ground, continuous apartment frontage, roof depth and props. Its
camera-specific shortened north depth and stable dotted roof reveal are a player-review gate, not a
live renderer or a substitute for movement review. `GENERATION_RECORD.md` retains the built-in
generation prompts; facade, roof and props have verified alpha, while the ground plate is opaque.
Its generated street layers need a reference-conditioned improvement pass against the authoritative
urban images before their style is extended elsewhere.

Review coordinate units before integration: the gait draft's configurable limb lengths are not
proof of logical-pixel sizing. Test foot anchors in world space and apply drawing height only
when projecting the pose. Validate zero displacement, collision, reverse/turn, teleports/resets,
direction-boundary hysteresis and switching compatible parts. No animation code may move a logical
body, alter collision or advance gameplay RNG.

Current main's control work must be preserved: title buttons and input-mode selection, device/input
resolution, forced debug overrides, summary/pause behavior and portrait transforms. The archived
screen experiment predates some of this and must not simply replace current title scripts.

## Next work order

1. Bind the approved presentation to the live crowd and expand by event family. Every
   catalogue look needs its own identity and state-appropriate animation; a generic placeholder
   must be recorded as unfinished, never quietly substituted.
2. Add seeded deterioration, truthful contribution cues and objective guidance. The baby already
   receives event/crowd contributions: consume those facts instead of inventing nearest-source
   attribution or copying meter arithmetic. Silent barriers remain silent.
3. Rebuild all screens while preserving the current main behavior, then verify busy scenes,
   portrait/touch, pauses/transitions and the browser. Keep the full TODO scope visible throughout.

The separate SVG polish is an independent small PR. Review its existing asset-only diff and finish
its visual/CI gate; do not expand it into the PNG overhaul or change gameplay to accommodate it.

## Git and verification

Commit and push frequently, **especially before changing direction**. Rejected ideas belong in
the overhaul branch's history, not dangling feature branches. An ancestry-only merge preserves
an experiment without adopting its files; `git show <commit>:<path>` retrieves it using the archive
index. Do not force-delete an unmerged branch. Active isolated worktrees are temporary and are
removed after their work is preserved. Inspect `git status`, `git worktree list` and remote PRs
before assuming anything about checkout state.

Use `./tools/check.sh`, `./tools/lint.sh` and focused test filters. Full-suite verification belongs
to PR CI. Read the actual result; a partial suite or headless boot proves neither visual quality
nor successful complete gameplay. No completed-test claim applies to an untested scaffold.

Godot windowed runs affect the player's screen and can stall on focus loss. Headless first;
use a small number of purposeful captures with an **external timeout**. A prior macOS launch
aborted before the game started; subsequent bounded escalated captures exited normally. Do not
blindly repeat sandboxed window launches. `tools/shot.sh` accepts seed/day/walk/touch flags and
`RESOLUTION`; choose the complete capture case before opening the window.

`tools/serve-web.sh` exports debug and serves the local web build without deployment. Browser
performance and real-touch behavior still need verification. Keep capability overrides usable.
After import/export, inspect `git status` and `git diff project.godot`; editor rewrites can remove
settings/comments or alter documentation whitespace. Keep source references and import sidecars
committed; never commit `.godot/`.

Before stopping, update this handoff, the main handoff and the open queue; archive history in
DECISIONS, run lint, commit and push. Tell the player what remains incomplete rather than presenting
a source-art draft as a finished game overhaul.
