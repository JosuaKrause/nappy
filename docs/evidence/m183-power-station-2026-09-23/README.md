# M183, the power station and the blackout — the first drawing of the station

Captures on `feature/power-station`, seed 4242, day 1, 1280×720, with `--invincible`.

- `door-seed4242-day1.png` — `tools/shot.sh … 4 --seed 4242 --spawn power_station --invincible`:
  the hall's south facade with the steel double door, its canopy, caged lamp and high-voltage
  plate, and the corner of the fenced transformer yard at the right edge. The stacks stand on the
  hall's roof, north of this frame, which the gameplay camera does not reach from the door.
- `overview-crop-4x-seed4242-day1.png` — a crop of `--overview` on the same seed, enlarged four
  times with nearest-neighbour scaling: the whole station, hall and door to the west, the two
  striped stacks rising over the street north of it, and the yard with its three transformers to
  the east. Enlarged, so it says what is drawn where, not how it reads at gameplay scale.

`tests/test_power_station.gd` is the verification of where the station stands and that its door
can be reached; these captures only show what it looks like.
