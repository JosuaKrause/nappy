priority: now

# tall-osprey — The robber's capture zone is smaller · filed 2026-09-27

> "the robber's capture zone is too big."

[olive-koala](../../playtests/2026-09-27-olive-koala.md), statement 1. The `alley_robbery` row (`EventCatalogue._alley_robbery()`) has three radii: his 200px field
(`outer_radius`, where the meter starts to feel him), the 140px at which he notices her and gives
chase (`pursues_within`), and his 30px catch (`inner_radius`, a `hard_fail`). The chalk mark's
guard uses the same row, and `ResistanceDirector` places him between his catch plus a contact's
reach and his `pursues_within` plus that reach from the mark. "Capture zone" is the catch (the
player's answer, 2026-09-27).
