## Café sitters face their own tables; barriers follow the actual mouth — 2026-09-12

PLAYTEST-64 reported a wrong-facing right sitter and sideways sitters in the vertical café.
`EventInstance._cafe_seat_heading` derives a bearing from each alternating chair's offset
toward its table. Horizontal seats use east/west views and vertical seats use south/north;
the fixed screen-depth lift does not enter the facing calculation. Focused event-view tests
cover each seat and its mirror. The available gameplay stills are partly occluded and do
not establish every facing by eye, so that visual check remains in REVIEW.

The same playtest showed horizontal boards stacked along vertical roadworks and barriers
on the wrong axis in horizontal alleys. A new narrow `barrier_segment_vertical.svg` is the
vertical roadworks panel; `barrier_end.svg` is an end post, not that panel's end-on drawing.
Closure panels span their allocated repeat interval instead of stacking native-height boards.
Alley rectangles now determine the spread axis before street-lattice inference: a horizontal
alley gets a vertical obstruction across its short mouth, and vice versa. That shared axis
also drives shadows and the collision capsule, so the picture and obstruction agree. Tests
cover both alley axes, the texture selection and its aspect. Human appearance review remains
open; no balance or obstruction-radius values change.
