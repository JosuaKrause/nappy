# grassy-beaver — The thought bubbles' pictures: a cloud frame, a pointing arrow and eight hint icons · 2026-11-25

The pictures half of the thought-bubbles item of grassy-beaver (a day one that teaches): the
SVGs each hint shows and a review sheet of them, drawn before anything shows them, so the player
can turn the look down before it is built everywhere (the item's own proposal; the player's ask
is a bubble over the mother holding an icon and no words, curly-moose #819). The mechanics that
show the bubbles are the item's other half and stay in
`docs/todo/2026-10-24-grassy-beaver/thought-bubbles.md`.

**What is drawn.** Under `art/ui/`, all on the `ui` atlas page beside the marks that ride over
her head, and catalogued as prepared in `docs/GRAPHICS.md`:

- `thought_bubble.svg`, the frame (56x46, bottom-centre anchor on the lower trailing dot's foot):
  a cloud on two trailing dots, paper-white (`#f7f3e8`) in the vocabulary's near-black outline
  (`#221f28`). Its outline is the union of the cloud's circles, each drawn fat in the outline
  colour and again in the fill on top, so no seam shows inside.
- `hint_arrow.svg`, the way a hint points (14x14, centre anchor), drawn pointing east and turned
  at runtime, which is layout and not a picture (the design's words).
- Eight icons, 24x20 with a centre anchor: the way to the park (`hint_park.svg`, trees on a mound
  of grass), back to the tutorial route (`hint_back_to_route.svg`, the route's sidewalk edged in
  the straw yellow of its tinted curbstones, `Palette.ROUTE_KERB_TINT`, and the pram standing off
  it), use the zebra (`hint_zebra.svg`, a street from above with a zebra crossing), cross the
  street (`hint_cross_street.svg`, the near sidewalk shut by a barrier and a line of steps over to
  the far one), turn back (`hint_turn_back.svg`, a street barrier and a U-turn arrow), walk wide
  of the noise (`hint_noise.svg`, a loudspeaker and an arrow bent wide round it), the chalk mark
  (`hint_chalk.svg`, an alley between brick walls with the mark on its floor, drawn as
  `chalk_mark.svg` draws it) and walk through the hut (`hint_hut.svg`, the checkpoint hut with an
  arrow going in at one side and out at the other).

**The choices, each the builder's and open to the player's correction on the review item**
(`docs/review/2026-10-24-grassy-beaver.md`):

- **The frame is unlike the exclamation mark in shape and colour**, as the item proposed: a round
  cloud where the mark is a square-cornered bar, paper-white where the mark is amber or red, and
  no flashing of its own. It keeps the vocabulary's outline so it reads over every ground. It is
  the largest thing over her head, about twice her width, so its icon reads at the game's zoom;
  the sheet shows it beside the mark at native size.
- **Blue means where to walk**, one blue (`#3d78b8`) for every arrow in every bubble. It is
  neither the caret's amber nor the danger red, and deeper than the home arrow's pale blue
  (`Palette.HOME_ARROW`) so it holds on the paper-white.
- **One arrow picture, turned at runtime, for the four hints that point** (the park, back to the
  route, the zebra and cross the street, which the design's table says point somewhere), drawn in
  the bubble's right half beside the icon; those four icons carry no arrow of their own, so a
  bubble never holds two arrows. The other four carry their own arrow (turn back, walk wide, the
  hut) or none (the chalk mark). The arrow's place in the bubble is the frame comment's proposal
  for the mechanics, which own the layout.
- **The noise is a loudspeaker**, a sign for noise rather than any one row's picture, since the
  hint fires for whichever noise source would raise the amber caret over itself for her.
- **The way back to the route borrows the route's curbstone tint**, the faint straw yellow the
  city blends into the curbstones of the day's route; whether the tutorial route carries that tint on
  day 1 is the route's, and the icon loses its one tie to the ground if it does not.
- **Cross the street draws steps, not an arrow**, since its arrow points at the nearest zebra.

**Rejected while drawing.** An arrow inside each pointing icon as well as the turned one, two
arrows in one bubble pointing different ways; the arrow on the bubble's rim outside it, like a
compass needle, which collides with the trailing dots and her head whenever the way is down the
screen; the cloud's outline as one hand-drawn path, which leaves the bumps uneven where the union
of circles keeps them round.

**Evidence.** The review sheet, its renderer and its composer are
`docs/evidence/grassy-beaver-bubble-pictures-2026-11-25/`; its README says what the sheet's own
layout adds. Checked: every SVG parses (`xmllint`), the `ui` page bakes with the ten new members
(`tools/check.sh`), and the atlas suites hold (`test_atlas_library.gd`,
`test_atlas_stroller_crowd.gd`, `test_player_presentation.gd`).
