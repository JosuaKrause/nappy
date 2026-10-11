# plush-marten — day 12's park closed by a police cordon

Evidence for the plush-marten entry (the cordon), 2026-10-11.

- `art-first-attempt.png` — a source preview of the three new pictures at scale 3, not a gameplay
  capture: `art/closures/cordon_tape_across.svg` laid edge to edge across the top,
  `art/closures/cordon_tape_along.svg` stacked down the left, `art/closures/cordon_post.svg` at
  every stretch end, and the existing policeman on foot (`art/events/policeman_lunging_side.svg`,
  `art/events/policeman_waiting_front.svg`) for scale, over a flat grass and sidewalk fill. Made by
  a scratch Godot script that loads each SVG with `Image.load_svg_from_string()` at scale 3 and
  blends them onto one image; it shows the pictures' shapes, colours and relative size only, not
  how the game draws or sorts them.
