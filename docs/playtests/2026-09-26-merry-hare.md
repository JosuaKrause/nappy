# Playtest merry-hare — The icons above the player are cut off at their edges

2026-09-26.

> btw separate topic. the icons above the player seem to be cut off at the edge -- maybe we should increase the bounding box?

The report concerns the player indicators. Whether the clipping follows the icons' own edges or
the screen edge is being clarified. Increasing image bounds is the player's proposed remedy;
the cause needs to be established before choosing the smallest correction.

> at the very least the triple ~ symbol in ui.png has its bottom cut off

> that's a new PR btw

The clarification identifies clipping inside the UI atlas, specifically the triple-wave baby
indicator. The fix belongs to a new PR, separate from scenery animation.
