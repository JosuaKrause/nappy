## M100 — Small, real, and nobody's · the pram's body sits on her circumference, and the debug view draws every body, 2026-09-12

*(2026-09-11, playtest 57: "I don't like the stroller having a hitbox. it makes navigation clunky,
I cannot get close to walls anymore, and I get constantly stuck."; then "can we keep the stroller
hitbox but move it closer to the player (btw the hitbox right now is not drawn at all for some
reason)"; "place the center of the stroller hitbox at the circumference of the player hitbox";
"and don't make it too big"; "and make sure *all* hitboxes are actually drawn".)* The pram's own
body had been built on 2026-09-10 from an M1 engineering note, never asked for, as a 12px circle
34px ahead of her. Two agent commits on `feature/pram-body-and-keyboard`, reviewed here. **The
body**: `PramCollisionShape2D`'s centre is `Tuning.PLAYER_BODY_RADIUS` (14px) out along her facing,
on the edge of her own circle, at `Stroller.PRAM_BODY_RADIUS`, 8px, pinned and open to overturn.
The drawing, shadow, cue and field keep their 34px offset; `pram_shape` stays 12px for the shadow.
**Chosen where the design was silent**: the body's offset is unsquashed, where the old one applied
the drawing's `OBLIQUE_Y` foreshortening to the physics offset too; every other body in the game
is unsquashed and the debug layer's own doc says physics is. **The debug view** no longer keeps a
list of body kinds to draw: `DebugLayers.collision_nodes_under()` walks the live tree under the
city and the player for every enabled `CollisionShape2D` or `CollisionPolygon2D` under a
`StaticBody2D` or `CharacterBody2D`, and draws each from its own `Shape2D` and global transform,
so the layer cannot omit a body again. **The audit found four kinds it had been omitting**: the
pram's body, a street tree's trunk, a road closure's two barrier bodies, and the four walls around
the map's boundary. A test builds a day with region walls in play, counts enabled shapes by its
own walk and asserts `body_outline_count()` matches. **Left open**: the escape scene's interior
blockers are not wired to the layer at all, since `main` only hands it the city and the player;
and the closure and boundary bodies are found by the walk rather than by a getter on `City`.
**The band's body against its picture**, the tail of the same item, is recorded under the alley
wall below: the wall across a road was already fitted, so the pram's own body was the whole of
that gap.
