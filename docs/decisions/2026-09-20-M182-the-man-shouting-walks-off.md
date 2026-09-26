## M182 — The man shouting walks off · built 2026-09-20

*(2026-09-20, [PLAYTEST-116](../playtests/PLAYTEST-116.md): "I did the first mark then the yeller
(there should be an indication that I did it correctly)"; [PLAYTEST-117](../playtests/PLAYTEST-117.md):
"yeller should just start walking offscreen -- no onscreen text for acknowledgements like this",
"yes, that I did the yeller correctly".)* One agent, two commits on
`feature/m182-the-man-walks-off`, reviewed here. It is the first item of M182, a finished task is
shown by the world; the other tasks' answers stay open in `TODO.md` with M181.

**What happens.** When the note's step counts, the look-alike she reached — the director's rider
after retargeting, not the one the day seeded — leaves through
`EventInstance.leave_for_a_completed_task()`: the existing departure, so he emits nothing from
that frame, walking at 60px a second (`departs_at` on his row; his beat is 30) away from her.
The others carry on. No text, no marker, and the chalk mark is untouched. The call is scoped to
`homeless_yeller` by id, so the other four tasks are not quietly answered by it.

**Two things the plain departure got wrong for this, both fixed in the wrapper.** A routed mover
leaves "the way it was going", which for a man pacing a folded beat is toward her half the time;
the wrapper turns him away from her. And every departure gives up after six seconds, which
exists for an instance nobody can see: at his shuffle that was 180px and a man vanishing in the
middle of the screen, which the first version's own test accepted and the review sent back. A
task's departure now gives up only once he is beyond `Tuning.OUT_OF_SIGHT` (420px) or there is no
player; an ordinary departure is unchanged and tested as such.

**Known and left:** a departure is a straight line with no pathing, for every row; he is not
solid and costs nothing while leaving. His picture has no quiet pose, so the cue is the shouting
stopping and him going. No burst was captured: `--spawn contact` runs before the director places
a contact (M100, small, real and nobody's), and a one-day rig cannot start with the first mark
already taken. A lost day's retry seeds its own rider and offers the step again.
