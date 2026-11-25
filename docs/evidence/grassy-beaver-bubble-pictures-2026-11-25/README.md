# The thought bubbles' pictures: the review sheet (grassy-beaver)

**What it shows.** Every picture the thought bubbles draw, as the source SVGs render through the
engine's own SVG parser: the frame (`art/ui/thought_bubble.svg`) holding each of the eight hint
icons (`art/ui/hint_*.svg`), with the pointing arrow (`art/ui/hint_arrow.svg`) beside the four
hints that point. Each bubble stands over the mother and the pram at the game's camera zoom (one
world pixel is two screen pixels) on the sidewalk, the asphalt and the grass, with a 4x
enlargement beside the three, and a strip at the foot shows every bubble at native size beside
the exclamation mark (`art/props/alert.svg`), the one mark already drawn over her head.

**What it does not show.** Nothing draws these pictures in the game yet: the mechanics that show
them are a later item of the entry, so this is a source preview, not a gameplay capture. Three
things on the sheet are the sheet's own layout and not the game's: the bubble's foot stands 52px
over her ground point (the exclamation mark's is 54px, `Stroller.ALERT_HEIGHT`), each arrow is
turned to an example direction (the runtime turns it toward the way to go), and the arrow sits
in the bubble's right half beside the icon, which is the place the frame's own comment proposes.

**Source revision.** The sheet was rendered from the tree of the commit that last changed it
(`git log -1 -- docs/evidence/grassy-beaver-bubble-pictures-2026-11-25/review-sheet.png`). After
the pull request is squashed, `git fetch origin refs/pull/1764/head` makes the commit reachable.

**How to make it again.** Godot 4.7.2 and Pillow. From a checkout, with a fresh scratch
directory and any Godot project to run the script under (it uses no autoload):

```sh
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
"$GODOT" --headless --path <any project> \
    --script docs/evidence/grassy-beaver-bubble-pictures-2026-11-25/render-sources.gd \
    -- --checkout "$PWD" --output-dir <fresh scratch>/renders
uv run python docs/evidence/grassy-beaver-bubble-pictures-2026-11-25/compose-sheet.py \
    <fresh scratch>/renders <fresh scratch>/review-sheet.png
```

**Files kept.** `review-sheet.png`, the sheet the pull request embeds and the player's question
asks about; `render-sources.gd`, which renders the sources at 1x, 2x, 4x and 8x;
`compose-sheet.py`, which lays the sheet out from those renders. The intermediate renders stay
in scratch space, since the two scripts make them again.
