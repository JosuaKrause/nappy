# The screen-edge badge's pointer and its disc are pictures

The screen-edge badge is the cue that says something lethal or fast is coming from off screen. Its
pointer is drawn in code as a filled polygon with an outline (`DangerEdge._draw_chevron()`,
`src/ui/danger_edge.gd`), and its backing disc and coloured rim as a circle and an arc in the same
file, under a comment that calls it the one place in the game a filled circle is still allowed.

**Build:** the pointer is an image file under `art/`, rotated to where the danger is; the disc and
its rim are a picture too, tinted for the kind of danger, unless the builder shows that a drawn
disc is layout and not a symbol, in which case that is put to the player with both side by side.
