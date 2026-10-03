# Playtest tawny-stork — Three ways to prepare the nearby ground, all at once by default

2026-10-03. Said in conversation. breezy-walrus asked the player to choose how nearby ground is
prepared after the phone test: keep the per-region stepping silky-rabbit built (each region's
preparation spread across frames), restore preparing each region at once while keeping the
findings, or keep stepping off by default behind a dev flag. The assistant had described the second
as "preparing all at once". The player asked:

> "with preparing all at once do you mean still lazy preparation but the entire graphic is prepared in one frame?"

The assistant answered yes: preparation stays lazy and nearby-only, with the wider unloading
boundary; only the scheduling changes, so once a region is needed its whole graphic is built in one
frame, alongside any other region needed in that frame. The player said:

> "let's introduce three options 1) (the default) as many graphics as needed are prepared in one frame 2) at most one graphic is prepared in one frame 3) graphic creation is smeared out like in the PR"

1. **Nearby ground preparation stays lazy, and has three modes.** → breezy-walrus.
   1. **The default: every graphic needed in a frame is prepared, whole, in that frame.**
   2. **At most one graphic is prepared in a frame**, whole.
   3. **One graphic's creation is spread across frames, as silky-rabbit (PR #452) built it.**

The assistant said it read the player's earlier "debug already works on real release builds -- I can
do debug=1&day=7 and start at day 7" as meaning the mode is switched through `?debug=1` on the
released page, and asked if that was meant. The player answered:

> "yes it should be a flag I can use in mobile under debug"

2. **The mode is a flag the player can set on the phone under `?debug=1`.** → breezy-walrus.

> "we should measure option 2 like we measure option 1 and 3"

3. **The second mode is measured the same way as the first and the third**, with silky-rabbit's
   comparison. → breezy-walrus.
