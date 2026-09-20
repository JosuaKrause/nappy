# Playtest 105 — Build atlases ahead of time and load each texture only once

2026-09-19. Design discussion following the father's artwork review.

> "are sprite atlases generated at build time or load time?"

The current implementation packs atlases at runtime. Most sprite groups pack on a worker
thread with main-thread image reads and texture creation. The crowd waits for its first pack;
ground packing is synchronous during TileSet construction and day repaint. The original
preloaded source textures remain resident alongside the packed texture.

> "make a todo that atlases must be created at build time. so they can be cheaply loaded at runtime. this enforces that related items must be put in the same atlas so the atlas does not get wasted. all textures that are loaded in an atlas must not be loaded individually (otherwise we require double the gpu ram)"

Create a separate implementation TODO. Generate atlases during the build, group related assets
by shared use and loading lifetime, and load the resulting atlas resources cheaply at runtime.
Every atlas-backed image must be accessed through its region of that shared texture; loading
the original individual textures as well violates the memory requirement. Retain editable
source assets for authoring without loading those originals into GPU memory in the game.
This extends the grouped-atlas requirements in PLAYTEST-75 and PLAYTEST-76; it does not ask
for immediate implementation or change the approved father artwork.

The player strengthens the build and memory boundary:

> "must not also be loaded individually into GPU memory. -- or any memory. they should cease existing in the build once they get baked into an atlas"

Exclude individual baked textures and their imported resource copies from the shipped build
entirely. Runtime must not load them into CPU or GPU memory. Original SVGs and PNGs remain
repository authoring inputs only; runtime packages contain the atlases and region metadata.
