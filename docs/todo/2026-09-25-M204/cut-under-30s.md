**The cut, under 30s**: the choice in action; early dangers up to the charging dog; the
title; three 1s segments through black — army trucks beside the mother, the father walking
to a gatehouse, the mother running with the baby in her arms from pursuing guards; the
zoom out. Nothing a player never sees. The player renders the final video.

In the first render the trucks shot shows no truck (`--spawn arterial` on day 13 rendered
differently each time) and in the chase shot she does not visibly run. The title shot shows
the father straight after the danger shot's father, where statement 8 asks the shots to
alternate. The captions and the title card are drafts that wait on the player's notes, which
come next.

A render is not yet reproducible under load: `tools/trailer.sh --check all`, run while two
other Godot processes were busy, found the choice, danger and title shots rendering different
frames on the second pass, and all three matched when run again on a quieter machine.
Statement 1 asks for "the same output every time", so the cut needs a render that holds
under load.

`tools/shot.sh --screenshot` seems to hang on `--start-escape` together with `--walk` or
`--after`; the movie-writer path the trailer uses does not. Found on the chase shot, not
investigated.
