**Nothing off screen is redrawn or animated**, judged against a bounding box a little larger than
the view so nothing visibly starts or stops at the edge
([velvet-marten](../../playtests/2026-10-11-velvet-marten.md), #700: "Skipping redraws for of
screen elements. Also we don't really change things with animation if it's of screen. If we have a
bounding box that extends a little bit into of screen then it won't be noticable.").

It is about drawing only: what a thing does, where it is and its timing in the game carry on off
screen exactly as now. An animation's frame clock may stand still off screen and resume on entry,
since nobody sees which frame it is on.

Places the investigation found redrawing with no need (each to be measured before it is built):

- `CrowdAgent` redraws with no on-screen check, a marked car every frame, and a car's bob is drawn
  inside its picture rather than moved by its transform, so the bob alone forces a redraw.
- `EventInstance._picture_key()` runs the warning caret's projection every frame for every live
  event, and most live events are off screen; the crowd cars' redraw check does the same for
  `_caret_strength()`.
- `home_arrow.gd` redraws on every frame's `hide_arrow()`, `danger_edge.gd` with no badges to draw,
  and `meter_bar.gd` on any change of a float.

**What it must keep.** The cues rules: a caret or a badge that is owed is drawn on the frame its
event comes into view or into the badge band, never a frame late, so each skip carries a test that
the cue appears on its first visible frame. The [scenery animation contract](../../evidence/m159-scenery-animation-2026-09-26/CONTRACT.md)
for partially animated scenery is untouched.
