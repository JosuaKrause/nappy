# M183, the power station and the blackout — the station's drawing

Captures on `feature/power-station`, seed 4242, day 1, 1280×720, with `--invincible`. The door view
is `tools/shot.sh … 4 --seed 4242 --spawn power_station --invincible`; the full view is the same
with `--zoom 0.35`, the ordinary gameplay view zoomed out until the whole station fits.

**The redrawn street front**, after the player found the first facade read as an apartment block
from the door:

- `door-redraw-seed4242-day1.png` — the hall's facade as it stands now: ribbed steel cladding, a
  clerestory band of tall, narrow, unlit wired-glass windows under the roof edge, a hazard-striped
  band along the base, and the front door as a heavy braced steel service door with a personnel
  door set in it, hazard-striped guard posts, a caged work lamp and a high-voltage plate. The
  transformer yard's fence is at the right edge.
- `zoomed-out-redraw-seed4242-day1.png` — the whole station: the hall with its door, the two
  striped stacks over the street north of it, and the fenced yard with its three transformers to
  the east.

**The first attempt**, kept for comparison:

- `door-seed4242-day1.png` — the first facade from the door: ordinary wall tiles with tall lit
  windows, which read as a block of flats, and a canopied double door.
- `zoomed-out-seed4242-day1.png` — the first attempt's whole station, from the zoomed-out gameplay
  view.
- `overview-crop-4x-seed4242-day1.png` — a crop of `--overview`, enlarged four times with
  nearest-neighbour scaling. Enlarged, so it says what is drawn where, not how it reads at gameplay
  scale; the zoomed-out stills are the ones that do.

`tests/test_power_station.gd` is the verification of where the station stands and that its door
can be reached; these captures only show what it looks like.
