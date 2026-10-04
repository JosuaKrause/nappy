**Record what each frame spends, by system, on the phone.** The player, having found ground mode 2
the smoothest on a phone ([quiet-yak](../../playtests/2026-10-03-quiet-yak.md), #510):

> let's focus on recording what cause spillover in the regular 2ms and we can probably investigate
> further here. it seems that stuttering happens with a lot of objects on screen so influence
> calculation, pathing, drawing, etc. can all be the culprit

and, after: "my hypothesis is that mode 2 allows more expensive things to take up time as it limits
itself to a very short time budget."

**What is recorded.** The scenery queue works under a 2ms budget a frame; the stutter is a frame
whose whole work runs past what one frame has, and most of that work runs outside the budget. Asked
which frames to break down, the player chose "Every frame, slow ones marked": for a few minutes of
play, every frame keeps its time per system, and a frame past the display's budget is flagged. The
systems are at least the ones the player named and the scenery queue itself:

- the scenery queue: its time, how far it went past its 2ms, and which jobs it ran (ground region,
  building, shadow, decal), guard preparations apart;
- the crowd's movement and pathing;
- the baby's influence sweep (the meter's sources);
- event updates, and the danger cues and their prediction;
- the CPU side of drawing: the `_draw()` calls that ran that frame and the render submit.

The breakdown has to add up against the frame: what the named systems do not account for is
recorded as its own remainder, never dropped. GPU time cannot be measured in a phone's browser;
the record says so rather than leaving it out silently. The player's hypothesis is a question the
record should be able to answer: in mode 2, are the slow frames ones where the scenery queue was
short and another system was long.

**How it gets off the phone.** The player chose "Download plus readout line": under `?debug=1` on
the released page, a button saves the recording as a file through the browser's own download, which
the player sends over; and the debug readout gets a line with the last slow frame's three largest
costs, so they can see live that a stutter was caught. The `?debug=1` words reach the released page
the way M193 says (`tools/decisions.sh M193`), and a run recording this way stays off the save like
the other words.

**What exists to build on.** `--frame-trace` (`src/telemetry/frame_trace.gd`,
[TELEMETRY.md](../../TELEMETRY.md#raw-frame-traces)) keeps raw callback intervals with world
counters in preallocated storage and writes a JSON file under `user://` on a native exit; it has no
per-system times and no way off a phone. The readout's `process` and `physics` lines are the
engine's previous-second maxima, not per-frame costs (M143). The crowded-scene attribution
(`tools/decisions.sh crowded-scene`) measured per-callback costs natively with the Godot profiler,
which a phone does not have. The timing itself must stay cheap enough that it does not become the
stutter: preallocated, no per-frame allocation or printing, and its own cost measured with it on and
off.

**Not part of this item:** the optimization the recording points at, which is
[the attribution item](attribute-the-remaining-slow-intervals-before.md) and M159's deliverable.
