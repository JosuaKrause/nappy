## M102 — The finale · the building's doors use the checkpoint's release latch, 2026-09-12

*(2026-09-12, playtest 58, on the checkpoint's "just spawned" flag: "same mechanism can be reused
in the escape scene when going through doors".)* A door in the building had its own guard: a
transition fired only on the frame she newly stepped onto a trigger tile, tracked by the last
tile she stood on, which let the arrival tile and the trigger tile be the same tile but re-fired
the moment she stepped off and back. One agent commit on `feature/building-doors-latch`. **What
stands**: `InteriorScene` holds one `ReleaseLatch`, armed on the arrival door's tile centre with
`_DOOR_RELEASE_RADIUS`, one tile and a half (48px), updated with her position every frame, and no
door fires while it holds; the fade's own `_transitioning` guard stays, since it guards the tween
rather than re-entry. The arrival point is unchanged. **Chosen where the design was silent**: one
latch rather than one per door, since only one door transition is ever recent in this scene and
no door in today's plan stands within another's radius; revisit if a layout ever puts two doors
that close. A test drives the teleport and the per-frame update directly: standing still does not
re-fire, stepping one tile off and back inside the radius does not, 47px holds and 49px clears,
and returning after leaving fires again. The latch primitive itself is proven in the checkpoint
suite.
