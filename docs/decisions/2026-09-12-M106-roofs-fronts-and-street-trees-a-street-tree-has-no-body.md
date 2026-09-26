## M106 — Roofs, fronts and street trees · a street tree has no body, 2026-09-12

*(2026-09-12, playtest 58: "trees shouldn't have a hitbox at all. trees in parks don't why should
the ones in the street be treated differently?")* M106 gave a street tree a 6px collision circle
at its trunk, kept inside one tile so the pavement's other tile stayed a full lane, on the
reasoning that a canopy is walked under and a trunk is not; it went to `REVIEW.md` as *does the
trunk catch her where the pavement is narrow*, and the player's answer is that it should not exist.
**What stands**: no prop has a body. The trunk body, its radius constant and the sentence in
`docs/CITY.md` that called the street tree the one prop with a real body are gone; a street tree
is walked through exactly like a park tree, so a pavement with trees costs the route nothing a bare
one does not. The bounding-box layer walks the physics tree, so it needed no change and draws one
outline fewer. No test asserted the trunk body. Done by the orchestrator in the same round as
playtest 58's other items, since it is a deletion and four sentences.
