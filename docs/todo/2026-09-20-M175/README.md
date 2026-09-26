## M175 — A row states what it costs, and the cost table is checked in · asked for 2026-09-20

> "is there a better way than having four numbers to control what actually happens? we adjust
> one thing but then forget to adjust other things in lockstep the balance is off."

> "we can do option 1 and take the radius into account as well. meaning we compute numbers
> close by and at various distances. those numbers gets automatically computed/updated but
> also checked in so we can see in the diff where the balance changed"

[PLAYTEST-114](../../playtests/PLAYTEST-114.md) has the conversation and both options. What the
player feels near a source is its `intensity`, averaged over its pulse, scaled by
`Tuning.SLEEPING_SENSITIVITY` (0.55) when the baby sleeps, shaped by `inner_radius`,
`outer_radius` and `falloff_power`, less `Tuning.EXCITEMENT_DECAY_WALKING` — several numbers
nothing ties together, so moving one silently re-prices every row. `docs/COSTS.md` is the
generated table that shows such a move in a diff (`tools/cost-table.sh` writes it and CI checks
it); what is open is the half that stops the move from happening.
