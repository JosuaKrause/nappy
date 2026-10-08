priority: now

# sunny-finch — The police car has a clear collision rule · filed 2026-10-07

[azure-koala](../../playtests/2026-10-07-azure-koala.md), finding 8, files inbox #601 in the
player's `now` band:

> police cars don't have a hitbox

[M61, one shape per object](../../decisions/2026-09-10-M61-one-shape-per-object-the-shape-the-shadow-and-the-body.md)
lists `police_patrol` among "the rows that obstruct nothing"; its shape there supplies a shadow,
not a solid collision body. The note calls that experience out but does not choose a lethal hit
or the solid-body policy. The work is [settle-and-build-the-hitbox.md](settle-and-build-the-hitbox.md).
