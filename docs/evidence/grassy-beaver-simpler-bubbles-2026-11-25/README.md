# The thought bubbles in two sets: the comparison sheet (grassy-beaver)

**What it shows.** Each of the eight hints in both of the sets the thought bubbles can draw, side by
side, as the source SVGs render through the engine's own SVG parser: the first icons
(`art/ui/hint_<hint>.svg`, each a small scene with an arrow of its own for four of them) and the
simple icons beside them (`art/ui/hint_<hint>_simple.svg`, each just the thing the hint is about,
drawn the way the game draws it, with no scene and no arrow inside). Both sit in the frame
(`art/ui/thought_bubble.svg`), with the pointing arrow (`art/ui/hint_arrow.svg`) beside the four
hints that point. Each row stands the two over the mother and the pram at the game's camera zoom
(one world pixel is two screen pixels) on the sidewalk and on the asphalt, with both at a 4x
enlargement beside them, and two strips at the foot show each set at native size beside the
exclamation mark (`art/props/alert.svg`), the one mark already drawn over her head.

**What it does not show.** Nothing draws either set in the game yet: the mechanics that show the
bubbles are a later item of the entry, so this is a source preview, not a gameplay capture. Three
things on the sheet are the sheet's own layout and not the game's: the bubble's foot stands 52px
over her ground point (the exclamation mark's is 54px, `Stroller.ALERT_HEIGHT`), each arrow is
turned to an example direction (the runtime turns it toward the way to go), and the arrow sits in
the bubble's right half beside the icon, which is the place the frame's own comment proposes.

**Source revision.** The sheet was rendered from the tree of the commit that last changed it
(`git log -1 -- docs/evidence/grassy-beaver-simpler-bubbles-2026-11-25/comparison-sheet.png`).
After the pull request is squashed, `git fetch origin refs/pull/<its number>/head` makes the
commit reachable; the pull request is the one that added this folder
(`git log --diff-filter=A -- docs/evidence/grassy-beaver-simpler-bubbles-2026-11-25/`).

**How to make it again.** Godot 4.7.2 and Pillow. From a checkout, with a fresh scratch
directory and any Godot project to run the script under (it uses no autoload; a directory holding
only a `project.godot` with the line `config_version=5` will do):

```sh
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
"$GODOT" --headless --path <any project> \
    --script docs/evidence/grassy-beaver-simpler-bubbles-2026-11-25/render-sources.gd \
    -- --checkout "$PWD" --output-dir <fresh scratch>/renders
uv run python docs/evidence/grassy-beaver-simpler-bubbles-2026-11-25/compose-sheet.py \
    <fresh scratch>/renders <fresh scratch>/comparison-sheet.png
```

**Files kept.** `comparison-sheet.png`, the sheet the pull request embeds and the player's
question asks about; `render-sources.gd`, which renders both sets of sources at 1x, 2x, 4x and 8x;
`compose-sheet.py`, which lays the sheet out from those renders. The intermediate renders stay
in scratch space, since the two scripts make them again. The first set alone is on the earlier
sheet, `docs/evidence/grassy-beaver-bubble-pictures-2026-11-25/`.
