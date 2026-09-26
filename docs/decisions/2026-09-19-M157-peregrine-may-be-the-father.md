## M157 — Peregrine may be the father · built 2026-09-19

*(2026-09-19: "we need to create a second set of player graphics for a male protagonist ... he
should have a blue shirt to easily distinguish him from his wife. the style etc should match. at
the beginning of a run the gender gets chosen randomly (50/50) and it stays throughout the run.")*
Three agent commits on `feature/m157-male-protagonist`, reviewed in the source matrices and one
normal-scale run still.

**The name stays Peregrine.** The two playable presentations are the same protagonist, so the
story still spends only two proper nouns: Peregrine and Wren. `NARRATIVE.md` now states the premise
with a parent and uses singular they where either presentation can stand in the sentence. The
historical alternative removed from that present-tense document is preserved here: **Hal** was
considered for the halcyon and its fourteen days of calm — a run is fourteen days and the bird's
whole job is to make the world quiet enough to nest in — then rejected because the name read male
on sight and cost the mother-only premise more than that arithmetic bought. M157 keeps the existing
gender-neutral name rather than making the random presentation choose a different identity.

**One complete second family.** `assets/rig/father_*` adds five authored views by three gait poses
for pushing and carrying; the runtime mirrors the east-authored side and diagonals to supply all
eight directions. The corresponding 30 native PNGs under `assets/illustrated/svg-transfer/rig/`
keep the current 24×46 cardinal and 26×46 side/diagonal canvases, bottom-center ground anchors and
45px visible stature. Short brown hair, a clean-shaven face, cream undershirt, blue overshirt,
blue-gray trousers and dark shoes establish one identity across both states. The female family,
the shared stroller and event NPCs are unchanged.

The generation record is `evidence/male-player-2026-09-19/`: SVG sources and exact source renders,
the player's supplied male scene as identity reference, two retained 15-figure generator outputs,
prompts, fixed cell boundaries, alpha-preserving extraction, registration hashes, native and 3×
matrices, female/male comparisons and stroller-contact sheets. Carrying uses the generated pushing
sheet as its identity reference. Uniform whole-figure scaling and upper-body-centroid placement
preserve stature and hand position without splicing fixed anatomy across moving legs. A normal
gameplay still and its entire run folder are under
`evidence/archive/session-captures/2026-09-19/rig-074419-seed3-v0.11.1-3-gaa5a6b38-dirty/`;
it proves appearance only. `REVIEW.md` asks for the human verdict on identity, gait and handle
contact in motion for both presentations and both carrying states.

**One choice owns the run.** `GameState.start_run()` makes an inclusive two-way draw from a new
independent `player-presentation` stream derived from the run seed. Keeping it off the city and day
streams means an existing seed's layout and events do not move. `Main._make_player()` copies the
stored choice before each of the ordinary, escape-interior and finale-city player instances enters
the tree; days, retries, pause/continue, carrying and texture resolution only read it. Seed 3 is a
male example and seed 1 a female example. `Stroller.family_sources()` warms both complete families
and the shared stroller into one atlas, while `--svg` selects the corresponding SVG source for
every pose rather than changing the family choice.

**Checks.** The focused presentation test reproduces the seeded draw, crosses wins, retries and new
days without a reroll, walks both presentations through every facing, pose and carrying state, and
requires the warmed PNG and forced-SVG paths to cover both families in one atlas without a late
load. Existing player and orientation rigs explicitly select the physics camera callback their
scenes already use, removing the engine's override warning rather than changing their assertion.
The boot check, governed-doc lint, SVG XML checks, reproducible registration/pair checks and focused
player, lifecycle, texture, orientation and performance suites pass. The unfiltered suite remains
CI's merge-result gate.
