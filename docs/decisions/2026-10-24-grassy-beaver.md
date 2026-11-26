# grassy-beaver — The thought bubbles' pictures: a cloud frame, a pointing arrow and eight hint icons · 2026-11-25

The pictures half of the thought-bubbles item of grassy-beaver (a day one that teaches): the
SVGs each hint shows and a review sheet of them, drawn before anything shows them, so the player
can turn the look down before it is built everywhere (the item's own proposal; the player's ask
is a bubble over the mother holding an icon and no words, curly-moose #819). The mechanics that
show the bubbles are the item's other half and stay in
`docs/todo/2026-10-24-grassy-beaver/thought-bubbles.md`.

**What is drawn.** Under `art/ui/`, all on the `ui` atlas page beside the marks that ride over
her head, and catalogued as prepared in `docs/GRAPHICS.md`:

- `thought_bubble.svg`, the frame (56x46, bottom-centre anchor (28,46), the foot of the lower
  trailing dot, which sits on the canvas's centre line so the trail ends over her head): a cloud
  on two trailing dots, paper-white (`#f7f3e8`) in the vocabulary's near-black outline
  (`#221f28`). Its outline is the union of the cloud's circles, each drawn fat in the outline
  colour and again in the fill on top, so no seam shows inside. Two lobes on its left give the
  icon box room when an arrow sits beside the icon, so every icon stays on the paper.
- `hint_arrow.svg`, the way a hint points (14x14, centre anchor), drawn pointing east and turned
  at runtime, which is layout and not a picture.
- Eight icons, 24x20 with a centre anchor: the way to the park (`hint_park.svg`, trees on a
  mound of grass), back to the tutorial route (`hint_back_to_route.svg`, the route's sidewalk
  edged in the straw yellow of its tinted curbstones, `Palette.ROUTE_KERB_TINT`, and the pram
  standing off it), use the crosswalk (`hint_crosswalk.svg`, a street from above with a
  crosswalk over it, its broad beige bars as the game's crosswalk tile draws them), cross the
  street (`hint_cross_street.svg`, the near sidewalk shut by a barrier and a crosswalk further
  up, where the way over is), turn back (`hint_turn_back.svg`, a street barrier and a U-turn
  arrow), walk wide of the noise (`hint_noise.svg`, a loudspeaker and an arrow bent wide round
  it), the chalk mark (`hint_chalk.svg`, an alley between brick walls with the mark on its
  floor, faint as `chalk_mark.svg` draws it, and a blue arrow walking in up the alley to it) and
  walk through the hut (`hint_hut.svg`, the checkpoint hut with an arrow going in at one side
  and out at the other).

**The choices, each the builder's and open to the player's correction.** They need no run of the
game to judge, so they go to the player as one question on the Nappy board's main tab, which the
pull request's description words with what each answer costs:

- **The frame is unlike the exclamation mark in shape and colour**, as the item proposed: a
  round cloud where the mark is a square-cornered bar, paper-white where the mark is amber or
  red, and no flashing of its own. It keeps the vocabulary's outline so it reads over every
  ground. It is the largest thing over her head, about twice her width, so its icon reads at the
  game's zoom; the cost is that, standing 52px over her ground point, it covers about 1.75 by
  1.4 tiles of the street straight ahead of her whenever she walks up the screen, for as long as
  it shows.
- **Blue means where to walk**, one blue (`#3d78b8`) for every arrow in every bubble. It is
  neither the caret's amber nor the danger red, and deeper than the home arrow's pale blue
  (`Palette.HOME_ARROW`) so it holds on the paper-white.
- **One arrow picture, turned at runtime, for the four hints that point** (the park, back to the
  route, the crosswalk and cross the street: the hints whose trigger names a place, the way
  along the route, the nearest route tile and, for the last two, the nearest crosswalk), drawn
  in the bubble's right half beside the icon; those four icons carry no arrow of their own, so a
  bubble never holds two arrows. The other four carry their own arrow: turn back, walk wide, the
  hut, and the chalk mark, whose arrow walks into the alley, since the player asked the bubble
  to hint at going in to get the mark (minty-dolphin #868). The arrow's place in the bubble is
  the frame comment's proposal for the mechanics, which own the layout.
- **The noise is a loudspeaker**, a sign for noise rather than any one row's picture, since the
  hint fires for whichever noise source would raise the amber caret over itself for her.
- **The way back to the route borrows the route's curbstone tint**, the faint straw yellow the
  city blends into the curbstones of the day's route; whether the tutorial route carries that
  tint on day 1 is the route's, and the icon loses its one tie to the ground if it does not.
- **Cross the street draws the way over on a crosswalk**, never mid-road, since the crosswalk
  bubble exists to stop a crossing away from one (minty-dolphin #867, curly-moose #832), and its
  arrow points at the nearest crosswalk. Its barrier on the near sidewalk sets it apart from the
  crosswalk icon.
- **Both crosswalk icons draw a north-south street**, so the bars stand upright side by side as
  the game's `crossing_v.svg` draws them; the east-west tile's bars, stacked in a framed box,
  read as a list glyph at the game's zoom.

**Rejected while drawing.** An arrow inside each pointing icon as well as the turned one, two
arrows in one bubble pointing different ways; the arrow on the bubble's rim outside it, like a
compass needle, which collides with the trailing dots and her head whenever the way is down the
screen; the cloud's outline as one hand-drawn path, which leaves the bumps uneven where the
union of circles keeps them round; a line of steps straight over the open carriageway for cross
the street, which taught the crossing the crosswalk bubble exists to stop, and read as a centre
line; the east-west crosswalk with three thin bars, which read as a menu glyph; the chalk mark
alone in its alley, whose crossed circle read as a no-entry sign until an arrow walked in to it.

**Evidence.** The review sheet, its renderer and its composer are
`docs/evidence/grassy-beaver-bubble-pictures-2026-11-25/`; its README says what the sheet's own
layout adds. Checked: every SVG parses (`xmllint`), the `ui` page bakes with the ten new members
(`tools/check.sh`), and the atlas suites hold (`test_atlas_library.gd`,
`test_atlas_stroller_crowd.gd`, `test_player_presentation.gd`).
