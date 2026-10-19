# downy-tapir — The baby is handed her world, the city's after the building · 2026-10-18



downy-tapir's first item, from the player's order "for immediate next step: check the bug and also
make escape winnable with minimal changes (fixing event distribution in some cheap way) then patch
release then full refactor" (minty-lemur #794). The bug is the one the codebase review filed under
minty-quail found by reading: `Baby` looked its world up once, from the `world` group in `_ready()`,
so in an escape started in the building she kept reading the building after `main` reparented her
into the city.

**Confirmed headless (PR #800).** `tests/test_baby_world.gd` boots the real `main.tscn` on the
building at seed 4216201080 (the player's last escape run), walks her out with `exit_requested`, and
asks the baby. Against the old lookup it failed three ways after the handover: her world was the
building's `Interior` node; standing in a live city event's field, the city answered 3.30/s of
excitement and her meter was fed 0.00/s; and on calm ground where the city's sleepiness multiplier is
42x her world answered 1x. So in v0.29.0 the city's trucks, vans, explosions and guards cost the
meter nothing after a building start, and calm ground soothed her at the building's rate. `is_alley`
read the same wrong world. The basement's zero decay reaching city tiles had no case on this seed (no
walkable city tile shares an x with the basement's slot); the fix covers it either way, since every
answer now comes from the city.

**Built.** The world is told, not discovered: `Baby.set_world(ctx)`, called by `main` wherever it
places her (the escape's building, the city after the walk-out on both the reparent path and the
straight-to-city boot, and the ordinary day's city), the way `main` already re-points the danger
edge. The group lookup is gone; a `Baby.new()` with no world still answers neutral, and the tests'
stand-in worlds hand themselves in explicitly. This is the target shape minty-quail's refactor asks
for (a component is handed what it depends on).

**Left open to overturn.** `WorldContext` still adds itself to the `world` group though nothing reads
it now; removing it is left to minty-quail.
