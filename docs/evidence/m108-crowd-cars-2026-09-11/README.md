# M108, eight-direction entity graphics — binding the crowd car to the continuous turn heading

Two `tools/shot.sh` captures, both `--seed 4242`, 1280×720, `--layers 2,3` (shadows and bounding
boxes), at commit `afdf2e0` plus this branch's own work.

- `signal-junction.png` — `--spawn signal --after 6`: a signalled junction on the spine. The car
  in the vertical corridor at the top is the **back** cardinal view (tail lights at the bottom
  edge), its red strike box and cyan shadow capsule both centred on the node and stretched along
  the vertical heading — the picture's own bottom edge (the car's south end) sits
  `Tuning.CAR_STRIKE_HALF_LENGTH` (26px) south of the node, agreeing with the box's own south edge.
  The car at the bottom right is the **side** view along the horizontal street, box and shadow
  both stretched horizontally and needing no anchor correction, as before this milestone item.
- `arterial-lane.png` — `--spawn arterial --after 7`: three cars queued on the arterial, all in
  the **back** cardinal view, each with its own box and shadow agreeing with the picture the same
  way.

Both confirm the live binding: the right texture pair per sector, tint on the body only, trim
untinted above it, and the strike box, the shadow capsule and the picture's own ground contact all
agreeing — the property `tests/test_car_views.gd`'s
`_test_every_sector_picture_agrees_with_the_strike_box` pins analytically for every one of
`EightDirection`'s eight sectors, cardinal and diagonal alike.

**Neither capture catches a car mid-turn**, and that is the six-try budget this item's own
instructions anticipate rather than a gap in the binding: `CrowdAgent`'s own measured turn rate on
this seed is the highest of the three measured for M111 (62 per 90s), but a turn is still a couple
of seconds out of a whole city's traffic, and standing still at a signalled or arterial spot for
long enough to wait one out pushes the excitement meter past the day-ending threshold before one
arrives — confirmed the hard way: an `--after 13` capture at the same signal caught the day-over
screen instead of a car. Six `tools/shot.sh` renders at `--seed 4242` (`--spawn signal` at 3, 6, 9
and 13 seconds; `--spawn arterial` at 6 and 7) found two cardinal views and one side view, all
agreeing with their own box and shadow, and one false alarm — the delivery van event's own single
authored picture, drawn at a fixed three-quarter angle regardless of heading, which is not this
item's binding at all. `tests/test_car_views.gd`'s
`_test_a_turn_sweeps_through_the_diagonal_views` and
`_test_every_sector_picture_agrees_with_the_strike_box` are the actual pin for the diagonal
sectors, the same division of labour `docs/evidence/m108-walkers-2026-09-11/README.md` already
draws for the walker's own diagonal window: the test drives the exact heading state on demand, and
a live screenshot cannot judge the geometry any more reliably than the test already does.
