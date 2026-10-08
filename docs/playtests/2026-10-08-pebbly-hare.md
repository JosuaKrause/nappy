# Playtest pebbly-hare — Scene recipes stay out of production and trailer frames are labeled

2026-10-08.

## #622 — Scene recipe packaging and trailer frame labels

The player is reviewing PR #580's apartment-window trailer and PR #592's authored scene
recipes. The trailer's full-resolution source PNGs are labeled A, B and C; the current cut
uses A and B after the request to omit C.

> do scene recipes have a godot ignore file? are they ignored in the prod build? also where can I find the graphics you used for the player in the scene? I need to get the A B C labeling right

The assistant's audit of the published v0.25.5 package finds 22 `scene-recipes/*.json` files.
There is no `scene-recipes/.gdignore`. `tools/.gdignore` covers the trailer's full-resolution
artwork. The assistant supplies byte-identical copies of the actual inputs in the main
checkout's `build/trailer/player-frames/mother-carrying-front-{a,b,c}.png` so the player can
identify them. It proposes excluding development recipes from production in PR #592 while
preserving local recipe use; the packaging mechanism is the assistant's proposal.
