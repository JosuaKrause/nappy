## M36 — Playtest 09: the key that did nothing, and the man who did nothing

See **[docs/playtests/PLAYTEST-09.md](../playtests/PLAYTEST-09.md)**. Four things, all done.

- [x] **`Esc` works** — and it had never worked. The guard read `visible` on a `CanvasLayer`, which
      is true from the moment the node is in the tree; the question it meant to ask is `is_showing()`.
      It opens **over** the between-days summary now as well, because `PauseScreen` puts back the
      paused state it found rather than assuming one — the first version refused there on the correct
      grounds that two things fighting over `get_tree().paused` is how a pause stops meaning
      anything, and the answer is to not fight. `tests/test_pause.gd` holds the trap itself as an
      assertion: *a fresh summary is not showing, and its own `visible` is true anyway*
- [x] **`--press <action> <seconds>`, so a rig can press a key** — the actual lesson. Neither the
      suite nor a screenshot could have caught the pause, because nothing in either has ever pressed
      one. Its own first version used `Input.action_press()`, which sets the polled state and nothing
      else: fine for `--walk`, useless for anything answered in `_unhandled_input`, and it produced a
      screenshot of the game carrying on — which looks exactly like the bug it was written to check
- [x] **The man shouting paces** — *"it didn't move and it took a long time to have any effect"*.
      `EventDef.paces`: a **beat** rather than a journey, so it walks its route, turns round at the
      ends, and neither departs nor expires, because it is a fixture that moves. Intensity 10 → 14
      (+17.7 → +31.2 in the cost table) and the body M34 gave him comes off, because anything mobile
      is exempt from "solid things are solid" — M19's `dog_walker` decision, unchanged
- [x] **The robber is a place that becomes a chase** — *"a robber should increase excitement on sight
      and getting close to them should be day ending"*, and *"if you get close they should start
      moving towards you"*. `EventDef.pursues_within`: three states rather than two, with the clock
      starting when it **notices** her and its notice **not** damping what it emits. 16 over 200px,
      lethal inside 30, 130px/s from 140. Standing, walking past and walking *away* all end the day;
      running shakes him off in ~1.5s for 21 points.
      **And a trap found by measuring:** while the chase ended at a *distance*, a trigger at or past
      that distance was a pursuit that lost interest the instant it started — at 170 against 170 the
      rig strolled away from him every time. A break-off stated as a rate cannot reproduce it
- [x] **And a scar could be tidied away by the usable-park rule** — exposed rather than caused by the
      above. `_ensure_one_usable_park` strips the spoilers off the least-disturbed calm block, and a
      burnt-out shell that had been on that corner since day 3 was one of them. Scars are exempt now,
      for the same reason ambient events are: a permanent feature of the map is not today's noise
