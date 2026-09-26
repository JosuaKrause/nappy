## M106 — Roofs, fronts and street trees · built 2026-09-11

*(2026-09-10: "we need stuff on top of roofs -- we have an air duckt already -- it needs to be
animated … we need more varied building fronts. storefronts, fire escapes." and "we could also add
trees that can be placed in the street. right now the fallen tree doesn't make that much
sense".)* Four agent commits on `feature/roofs-fronts-trees`, reviewed here. **Roof furniture**:
`Building` keeps its block's district and seeds a pick per building — vents, HVAC boxes and a
straight-and-corner duct run on industrial, skylights on civic, water tanks with the odd vent
elsewhere — on interior roof cells only, drawn above the roof tiles in the buildings layer so
nothing is y-sorted against the street; the vent alternates its two frames on a 1.4s per-building
timer and nothing else on a roof moves. **Fronts**: every commercial ground-floor column is one
of four storefronts, an awning on 35% of them, as a plain base-tile substitution whose opaque art
covers the window underneath; civic gets its portico at the facade's centre; residential facades
tall enough take a fire escape on 30%, over the bottom two rows — the portico and the fire escape
are overlays, the two composition changes the item allowed, and the tint rules stand. The
shuttered storefront and window variants stay unbound for M105. **Street trees**: a pure function
of the map, `StreetTrees`, plants pits at the kerb-side tile of ordinary residential and
commercial streets at 96px minimum spacing and a 55% chance per slot, one tile clear of every
segment's mouth — which covers crossings, doors and checkpoints at once, since the region wall
stands at that same mouth — and clear of the home's door. A street tree is the one prop with a
real body: a 6px trunk kept inside one tile, so the pavement's other tile keeps a full lane of
her clearance; the crowd never collided with props, so only she needed it. `ClosurePlanner`
weights `fallen_tree` six times on a segment that has standing trees, from the same function the
city plants from; the fallen picture's canopy and trunk fills are byte-identical to the standing
pictures', so no art moved.

**The district comparison, judged here from the four rig pictures** in
`docs/evidence/m106-districts-2026-09-11/`: commercial reads at a glance (a run of storefronts
under awnings) and so does residential (a fire escape, a water tank); industrial and civic are
told apart by their roofs alone — an HVAC box and a duct, three skylights — which are small at
play scale, and the civic portico was out of frame. Whether those two read as places is the
`REVIEW.md` question. Taking the pictures cost more than the four shots allowed: two long walks
ended the day, one on the meter and one under a car, and the civic block on the first seed was a
hundred tiles from the doorstep, so a nearer seed was used; there is no `--spawn <district>`
flag, and main.gd was another agent's file. **Chosen where the design was silent**: the shares,
the spacing, the plant chance, the trunk radius and the closure weight above, none of them in
`Tuning` since none is a route decision.
