priority: later

# breezy-moose — The crowd asks the drawn view the same question the events ask · filed 2026-11-22

No player's words name this; it is Fable's follow-up in its recheck of [#1638](https://github.com/JosuaKrause/nappy/pull/1638#issuecomment-7085694378).

**Found.** Whether a reach is on the screen, and what holds when there is no screen, is written twice: once in `DrawnView.shows()` (`src/world/drawn_view.gd`; no screen means everything is shown) and once inline in `CrowdAgent.end_the_frame()` (`src/crowd/crowd_agent.gd`) over `CrowdView.drawn_box()` (an empty box means nothing is shown). A crowd with no screen is handed no view at all to keep that harmless (the cues skill's `references/drawing-and-redraw-gates.md`).

**What the fix must hold.** One `shows`-style read on `CrowdView` that `ScreenCrowdView` forwards to the `DrawnView`, so the question is written once; its own cost reading, since the ask is once per agent per tick; the crowd's fingerprints hold.

*Proposed, not asked for:* the band `later`.
