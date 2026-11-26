# grassy-beaver — The thought bubbles' simple icons: each hint just its thing, kept beside the first set · 2026-11-25

A second set of hint icons for the thought bubbles of grassy-beaver (a day one that teaches), drawn
beside the first set rather than over it. The player asked whether the chalk-mark bubble could show
just the mark instead of an arrow into the alley (inbox #1771 in spry-wombat), then the same for
the other bubbles (inbox #1772 in spry-wombat), then to keep both versions for comparison
(inbox #1773 in spry-wombat). The mechanics that show the bubbles stay the open half of
`docs/todo/2026-10-24-grassy-beaver/thought-bubbles.md`.

**What is drawn.** Eight icons under `art/ui/`, `hint_<hint>_simple.svg`, each on the same 24x20
canvas with the same centre anchor as its first-set icon, so either drops into the frame's icon box
unchanged, and all eight on the `ui` atlas page beside the first set. Each shows just the thing its
hint is about, drawn the way the game draws it, with no scene and no arrow inside:

- **The way to the park** (`hint_park_simple.svg`): one park tree, `tree_a.svg`'s crown and trunk
  in its own greens and brown, with no mound of grass and no second tree.
- **Back to the route** (`hint_back_to_route_simple.svg`): a piece of sidewalk edged in the straw
  yellow the city blends into the route's curbstones (`Palette.ROUTE_KERB_TINT`), with no pram.
- **Use the crosswalk** (`hint_crosswalk_simple.svg`): the crosswalk alone, a patch of asphalt
  with the broad beige bars as `crossing_v.svg` draws them, with no sidewalks. It has three bars
  where the tile has two, since two upright bars on a dark square read as a pause sign.
- **Cross the street** (`hint_cross_street_simple.svg`): the street alone, a carriageway from
  above with its pale curbs and its centre dashes in the road line's colour, with no barrier on
  the near sidewalk and no crosswalk up the street.
- **Turn back** (`hint_turn_back_simple.svg`): the barrier alone, two panels of the road closure
  barrier as `barrier_across.svg` draws them, with no U-turn arrow.
- **Walk wide of the noise** (`hint_noise_simple.svg`): the loudspeaker alone, giving off its
  sound, with no arrow bent round it.
- **The chalk mark** (`hint_chalk_simple.svg`): the mark alone, the crossed circle in chalk at
  `chalk_mark.svg`'s colour and opacity, on a patch of the alley's dark floor with its paving
  joints so the faint chalk shows on the bubble's paper; no alley walls and no arrow.
- **Walk through the hut** (`hint_hut_simple.svg`): the checkpoint hut as `hut_south.svg` draws
  it, door to the front, with no arrow through it.

The four hints that point at a place (the park, back to the route, the crosswalk, cross the street)
keep the one arrow beside the picture, `hint_arrow.svg` turned toward the way to go, in both sets:
that arrow is the bubble's layout, not the picture (the first record of the pictures,
`docs/decisions/2026-10-24-grassy-beaver.md`). The frame and the arrow are shared by both sets.

**What each simple icon costs.** Where one thing alone cannot say its hint, the hint rests on when
the bubble shows rather than on the picture:

- **The chalk mark** alone is a crossed circle on a dark square, which can read as a no-entry sign
  or a cancel button; the first set's alley and arrow were drawn because the mark alone read that
  way. It also no longer shows going into the alley, which the player asked the bubble to hint at
  (minty-dolphin #868); the bubble shows when a mark first comes into view (gentle-owl #1234), so it
  names what she is looking at rather than what to do about it.
- **The hut** alone says a checkpoint hut is there, not that it can be walked through, which is
  the lesson the player named for it (curly-moose #819); it can read as "keep away from the
  checkpoint".
- **Turn back** alone is a closure barrier, which says the way is shut but not to turn round, and
  is close to what a closed street already shows on the ground.
- **The noise** alone says something loud is near, not to walk wide of it.
- **Cross the street** alone is a street, and with its arrow at the nearest crosswalk it says much
  what the crosswalk bubble says; the two now differ only in their picture.
- **Back to the route** alone hangs on the straw-yellow curbstones, so it loses its tie to the
  ground if the tutorial route carries no tint on day 1.

**Which set the mechanics draw is the player's**, asked on the Nappy board's main tab with the
comparison sheet; both are prepared and neither is drawn by the game yet. The builder's pick is the
simple set except for the hut and turn back, which keep their first icons, since in those two the
arrow is the whole message.

**Evidence.** The comparison sheet, its renderer and its composer are
`docs/evidence/grassy-beaver-simpler-bubbles-2026-11-25/`: each hint in both sets side by side over
the mother at the game's zoom on two grounds, both at 4x, and each set at native size. Its README
says what the sheet's own layout adds. Checked: every new SVG parses (`xmllint`), the `ui` page
bakes with the eight new members (`tools/check.sh`), and the atlas suites hold.
