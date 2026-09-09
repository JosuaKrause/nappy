# Luna graphics handoff

## Read first

Read `CLAUDE.md`, `docs/HANDOFF.md`, `docs/TODO.md`'s Visual overhaul section, then
`docs/PLAYTEST-30.md` and `docs/VISUALS.md`. The playtest preserves the player's full words;
the visuals document states the current target. Read the relevant skills before editing.
The orchestration and committing rules still apply. Implementation uses Luna.

The actor repair review is [PR #49](https://github.com/JosuaKrause/nappy/pull/49).
Keep it draft. Read `ILLUSTRATED-GAMEPLAY-FIXES.md` and `PLAYTEST-43.md` for the attachment and
legacy-scale repair gate. A prototype, source sheet or code scaffold is not a completed overhaul. Do not
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
| `assets/illustrated/modular/` | Measured mother parts and the selected transparent v3 pram, registered by the opt-in compositor |

The original mother draft is materially closer in style, but has a **baked checkerboard and no
alpha**. Its observed order is **S, SE, E, NE / N, NW, W, SW**, not the requested N-first ordering.
It is a source draft, not visual authority. `mother-parts-v3.png` supplies independently packed
parts with measured per-facing crops, anatomical axes and sole contacts. A textured torso core
excludes the sleeves so separate arms can meet the pram handles. Some views explicitly reuse a
single same-facing arm drawing; newly authored isolated anatomy remains an art requirement.
PLAYTEST-44 selects `pram-layered-v3-draft-transparent.png`; its manifest registers eight views
of chassis, seat, canopy and baby against one pram frame. The mother and pram map source columns
independently. Both families are bound to the opt-in live player. The player explicitly offers to
perform style transfer on usable draft sheets if generation does not achieve the target.

Use the imagegen skill for generation/editing. Built-in mode does not require an API key. Do not
silently switch to a paid CLI workflow or use SVG/code primitives as substitute artwork. Preserve
prompts and rejected alternatives in the same overhaul history. Verify actual alpha values; an
image of a checkerboard is not transparency.

## Implementation checkpoint

The playable game uses the existing renderer by default. `--illustrated` or a web
`?illustrated=1` query opts into the initial illustrated character runtime for review; neither
argument changes simulation. A missing argument remains legacy, so this is not an approval or a
release switch.
The 3D street and actor experiments are preserved in ancestry, indexed in `docs/DECISIONS.md`
under Illustrated assets and experiment preservation, and are not in the tree. Do not revive their
design by mistake.

The modular sprite components also have opt-in live gameplay bindings:

- `src/visuals/directional_parts.gd` validates eight-direction regions, pivots and source axes,
  then maps painted segment endpoints to actor-local joints without scaling length twice.
- `src/visuals/planted_gait.gd` uses world-pixel stance/swing state, lifted ankles and solved knees.
  Zero displacement freezes an unfinished step; renewed travel resumes it within bounded reach.
- `src/visuals/modular_person.gd` consumes actual applied displacement without changing a logical
  body, collision or gameplay RNG.
- `assets/illustrated/modular/` supplies mother and pram source bundles, including articulated
  lower-body parts. The focused visual and attachment suites exercise registration, transformed
  joints and displacement sequences; passing those checks does not establish visual acceptance.
- Under the illustrated opt-in, `Stroller` owns a zero-offset live `ModularPerson` child. It
  receives only displacement that survived collision and shove resolution, then resets the gait
  with every logical player reset. The legacy mother/pram SVG drawing remains the default, with
  shadows, baby cues and alert cues in both presentations.
- Under the illustrated opt-in, walkers bind to `ModularWalker`; cars retain their existing
  presentation. Walker scale includes both the painted upper body and the separately drawn legs.
  Profile legs explicitly reuse one same-facing source set, and diagonal crops share edge pixels.

The standalone `scenes/dev/illustrated_street_review.tscn` consumes the layered PNG assets under
`assets/illustrated/street/`: ground, continuous apartment frontage, roof depth and props. Its
camera-specific shortened north depth and stable dotted roof reveal are a player-review gate, not a
live renderer or a substitute for movement review. `GENERATION_RECORD.md` retains the built-in
generation prompts; facade, roof and props have verified alpha, while the ground plate is opaque.
The street study is rejected and needs rebuilding from the authoritative urban images. It is
not an approved direction or a basis for extending the asset family; see `HANDOFF.md` and the
M84 record in `DECISIONS.md`.

Review rendered coordinates as well as solver targets. Test planted soles in world space after
the source-to-actor transform. Validate zero displacement, collision, reverse/turn, teleports/resets,
direction-boundary hysteresis and switching compatible parts. No animation code may move a logical
body, alter collision or advance gameplay RNG.

Current main's control work must be preserved: title buttons and input-mode selection, device/input
resolution, forced debug overrides, summary/pause behavior and portrait transforms. The archived
screen experiment predates some of this and must not simply replace current title scripts.

## Next work order

1. Review registered actors against the legacy SVGs in all eight directions, then review movement
   and live overlap. The calibration scene keeps the original drawing at a fixed horizontal
   comparison offset. Resolve the documented source-part limitations before expanding variants;
   follow `ILLUSTRATED-GAMEPLAY-FIXES.md`.
2. After the actor gate, rebuild a representative live illustrated street and expand by family. Every
   catalogue look needs its own identity and state-appropriate animation; a generic placeholder
   must be recorded as unfinished, never quietly substituted.
3. Add seeded deterioration, truthful contribution cues and objective guidance. The baby already
   receives event/crowd contributions: consume those facts instead of inventing nearest-source
   attribution or copying meter arithmetic. Silent barriers remain silent.
4. Rebuild all screens while preserving the current main behavior, then verify busy scenes,
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
