## M216 — The small courtyard building's roofs go around the corner · found 2026-09-26

> "the small courtyard building needs the roofs to go around the corner (like I described with the
> other building types earlier) currently it doesn't read correctly."

[PLAYTEST-143](../../playtests/PLAYTEST-143.md), statement 2. The earlier description is PLAYTEST-138's
"extend the roof from the bottom building above to the roof of the top building", which M203, a
front nobody can stand at has windows on its ground floor (PR #365), builds. A courtyard block is
cut into up to four separate rectangles around its hole (`_cut_courtyards()` and `_subtract()` in
`city_generator.gd`). Each is its own `Building` with its own parapet, so at the courtyard's inner
corners two roofs meet edge to edge instead of turning as one roof. This follows #365, since both
change how one building's roof meets the next.
