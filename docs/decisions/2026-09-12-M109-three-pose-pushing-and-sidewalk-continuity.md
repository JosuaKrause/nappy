## M109 — Three-pose pushing and sidewalk continuity — 2026-09-12

PLAYTEST-65 accepted the grounded stroller scale and requested the same three-pose walking
structure for pushing. P1 — Two-pose push is preserved as the original family; P2 — Three-pose
push supplies fifteen SVG-first full-figure PNGs. A and B are opposite contacts, with C between
them and selected whenever the mother stops. Both carrying and pushing share the distance-driven
A/C/B/C selector. The existing walk-clock rate, pram drawing scale and offsets, collision geometry,
controls and touch radii remain unchanged.

The first pushing generation repeated leading legs. Targeted full-figure edits corrected the
front contact, then profile and northeast hip-to-shoe ownership. The standing row was generated
separately to retain adult proportions. Horizontal registration uses the original upper-body
centroid so changing foot spread cannot shift her grip. The final selection combines whole
figures from the recorded batches without anatomical splicing. Source sheets, displayed review
passes, raw inputs, exact prompts, extraction scripts, native/enlarged GIFs and grounded contact
sheets are retained in `docs/evidence/comic-pushing-strides-2026-09-12/`.

The same playtest found that the sidewalk did not continue the accepted road-edge paving.
Source review showed the SVGs already shared their slab layout, fill and joints; the mismatch was
in the generated PNG materials. The seven sidewalk surfaces now share paving edited from the
accepted north curb, with damage variants edited from that same base. All eight curb textures
and the road controls remain byte-identical. The accepted east curb retains its brighter material
variation. Tile size, full opacity and placement remain fixed, and no city behavior changes.

`docs/evidence/sidewalk-continuity-2026-09-12/` preserves before/source/after neighbor panels,
repeated and isolated damaged cells, raw edits, prompts, source hashes and fixed-cell registration.
New-directory rebuilds compare the saved tile and panel bytes and reject changed source, raw,
reference and dependency inputs. The source/before comparison uses its pinned source revision,
so installing the new sidewalk does not silently change what the before panel depicts.

Focused runtime checks cover both state selectors, all facings, together idle and PNG/SVG
resolution. Native assemblies cover the art and ground contact; live turns and state transitions
remain human visual-review questions in `docs/REVIEW.md`. The full test suite runs in PR CI.
