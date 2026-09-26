## M100 — The home block carries no fire escape · built 2026-09-24

*([PLAYTEST-128](../playtests/PLAYTEST-128.md): "the home building shouldn't have a fire escape (it
has a double staircase inside)".)* `Building._build_front()` still rolls a `RESIDENTIAL` front's
escape on every building, and drops the column when `is_home_building` is set, so no other roll on
the `front:` stream moves on any seed. The `is_home_building` setter now rebuilds the front on a
change, like every other roll-affecting property; in every real path the flag is already set
before the building enters the tree, so this is a safety net rather than a fix.
`tests/test_ground_floor.gd` sweeps 200 fixtures and five generated cities; its older check that
the home flag changes no front roll was rewritten, since keeping the escape was exactly what this
item changes. Seed 73124 had an escape on the home block before;
`evidence/home-no-fire-escape-2026-09-24/home-block.png` shows it without.
