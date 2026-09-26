## M94 — The tunnel and the bridge carry traffic both ways — 2026-09-09

[PLAYTEST-47.md](../playtests/PLAYTEST-47.md), two notes on a freshly pulled `main` at `b4e0fba`. *"no car
ever comes *out* of the tunnel or from the bridge"*, and a boot that failed on the pram texture
`ModularPerson` preloads, taking every script that depends on the player down with it.

**Why no car ever came out.** A recycled agent enters through a band `ENTRY_SPREAD` (420px) deep
outside the edge of the crowd's box that its new direction carries it inward from, and
`CrowdAgent._entry_band_fits()` re-rolled the lane until that band lay within a tile of the map.
The box's own bounds are clamped to the map, so beside the tunnel a southbound spine lane's band
was the 420px beyond the north edge — inside the tunnel, the only place a car coming out could
start — and every roll was refused. The exception the rest of the file makes for a car on the
spine, which may overrun the edge by `Tuning.OUT_OF_SIGHT` (420px) on its way out, had never been
made on the way in. The only inbound cars were the fallback of six missed rolls: measured on seed
4242 at day 1 over forty seconds standing beside each exit, 157 frames of a spine car out of
bounds heading in against 1717 heading out at the tunnel, and 135 against 3823 at the bridge.

**The fix is one line of reasoning**: the entry band may reach as far past the edge as
`_room_beyond_the_map()` grants that agent, which is a tile for everybody and `OUT_OF_SIGHT` for a
car on the spine. Same rig afterwards: 7559 inbound frames against 1715 at the tunnel and 6579
against 3823 at the bridge. Inbound exceeds outbound because beside an edge every southbound spine
recycle lands in the tunnel band, while a northbound car has the whole box to cross first. The
four-edge test that keeps walkers and off-spine cars in bounds is unchanged and still passes, and
a new one in `tests/test_crowd.gd` asserts inbound frames are at least a quarter of outbound at
both ends — a ratio rather than a count, because the population and the re-roll odds both move.

**The boot failure is the gap the godot skill already named**: `tools/run.sh` checked the global
class cache and not the imported textures, and a `.import` sidecar is a repository file whose
`.godot/imported/` copy a pull cannot bring. `run.sh` lists every sidecar's `dest_files` against
what is on disk and runs `check.sh`'s import pass when any is missing, the same repair the stale
class cache path makes, and refuses to launch if the pass does not produce them. Detected by
listing rather than by mtime, so an ordinary edit never triggers a full import. Exercised by
hiding one `.ctex` and reading the function's output: it names exactly that file, and nothing
with everything present.
