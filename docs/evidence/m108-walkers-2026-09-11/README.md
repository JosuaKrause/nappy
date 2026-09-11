# M108, eight-direction entity graphics — binding crowd walkers first

Two `tools/shot.sh` captures, both `--seed 4242`, 1280×720, at commit `34289a6`.

- `junction-signal.png` — `--spawn signal --after 5`: a signalled junction on the spine. Shows
  walkers in the front and back cardinal views (the two vertical-corridor sectors), correctly
  tinted per walker with their trim drawn above, alongside the mother/pram rig and live traffic.
- `corner-nw.png` — `--spawn corner:nw --after 6`: a horizontal street at the map's own corner.
  Shows the side cardinal view along the horizontal corridor, including one walker mid-excitement
  with its halo rim tracing the same silhouette `_draw_body()` draws — confirming the halo still
  follows the walker's own body through the new view lookup rather than a separate presentation.

Both confirm the live binding renders correctly: the right texture pair, tint on the body only,
trim untinted above it, shadow, gait bob and the halo all intact through the sector-based drawing
path this milestone item replaced the three-frame one with.

**Neither capture happens to catch a walker in a diagonal sector**, and that is expected rather
than a gap in the binding: a walker only shows one while it is actively closing a cross-lane gap
at `CrowdAgent.STEER_SPEED` (90px/s), which for the small corrections most turns need is a window
of a few tenths of a second, in a crowd of 234 spread across the whole visible field. Catching one
on demand would mean forcing the steering rather than photographing the game as it runs, which is
exactly the shape of thing `docs/evidence/m108-walkers-2026-09-11/` exists to avoid manufacturing.
`tests/test_walker_views.gd` is the actual verification for every sector, both diagonal pairs, the
boundary hold, the wrap, rest-retention and the fresh-placement/recycle reset — a live screenshot
cannot judge any of those any more reliably than a human eye could, and a rig that drives the exact
heading state it wants to see is the "focused rig" `docs/TODO.md`'s own item asks for beside the
rendered evidence.
