# round-ferret — Saved recipe construction and power-station joins · 2026-10-03

The player's saved-recipe request and valid power-station edge case are recorded in
gray-otter, minty-wombat and frosty-finch. The clarification and source-context addendum
are [pebbly-bison](../playtests/2026-10-03-pebbly-bison.md). The builder implements
versioned JSON pins through the production construction stages, never by searching
city seeds or repairing a finished map. Unsupported pins fail explicitly.

`city.context_seed` supplies one deterministic construction witness; explicit streets,
lots, layouts, station footprint/door and closures enter before derived geometry.
The witness supports existing checks; it is not a claim that the authored bounded
scene is a complete city or that a natural seed realizes the exact arrangement.
The bounded exterior does not contribute route guarantees. Normal recipes waive no
checks. Proposed named fixture diagnostics allow only declared generator guarantee
failures; malformed data, broken references and invalid placements remain errors.

Both hall and yard recipes pass existing checks without fixture allowances. The hall
covers the adjoining facade only where a real roof extension covers it; the yard
retains the facade. This supplies a concrete checked yard case without asserting that
M203's unsuccessful seed sampling proved impossibility. The [join stills](../evidence/calm-stork-scene-stills-2026-10-03/README.md)
show composition, with capture source identified separately from the extracted slice.

The minimal real-Main runtime provides scripted input, setup, initial/final manifests,
save isolation and simulation-clock screenshots. It reuses the walking syntax behind
`--walk`; the consolidated runtime also implements a recipe camera `zoom_out` track.
Recipe launches reject independent `--press` input, and playback has no press field.
Conflicting independent input/camera flags are rejected. JSON, anchors, explicit
context seed, named fixture diagnostics, quiet background and synchronous scripted
scenery preparation are implementation choices open to overturn.

Trailer events/actors and screenshots are recorded in
[calm-stork](2026-10-03-calm-stork.md). Ordinary controls, escape retry and interactive
extent checks for every recipe are recorded in [velvet-hare](2026-10-03-velvet-hare.md).
The shared bounded presentation already omits context scenery and map boundaries.

Verification: focused recipe/generator/real-Main launch suites passed 72,908 checks;
CLI checks passed 276. The suite covers malformed input, conflicting pins, existing
checks and fixture exceptions, roof coverage, actual startup/movement/completion and
save isolation. Check and lint passed on the implementation; full game testing is CI's.

Merge reconciliation: builder b4a77e0d and main 746e7b3f shared base b5dbf6cb.
Main added the same 14 design/source files already present through the stacked branch;
the no-commit merge changed no tree content. Code, docs and evidence remained intact,
and the queue closure below was applied after reconciliation to avoid resurrecting work.

The player clarified that the three-way split is queue entries, not PRs. The complete
implementation is consolidated into #457. Reconciling integrated head 8a6fdb4c with
main 746e7b3f (base b5dbf6cb) exposed seven add/add documentation conflicts: three source
framings and four builder item files. The merged source text and narrower existing-check
contract were retained; later framing corrections remain in pebbly-bison. Duplicate
trailer/free-play files in the former combined entry were removed in favor of the
three linked entries. Code was unchanged by this merge; lint, whitespace and boot passed.
The check counts above describe the extracted builder verification; the consolidated
runtime's lifecycle and scene checks are recorded with their respective entries.
