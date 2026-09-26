## M124 — The two fixes built · 2026-09-13

The build half of the desktop measurement below (M124, where a frame goes). Four agent commits
on `feature/m124-frame-fixes`, reviewed here; the evidence, with twelve walks, the pixel
comparison and two bursts, is `docs/evidence/m124-frame-fixes-2026-09-13/`.

**Events redraw only when their picture changes.** `EventInstance._process()`'s three
unconditional `queue_redraw()` calls are now `_redraw_if_the_picture_changed()`, the gate
`CrowdAgent` has always had. `_picture_key()` is a `Vector4i`: a bit field of every yes/no thing
the drawing asks — finished, suppressed by a checkpoint hold, leaving, mid-stride, facing west,
telegraphing, waiting, chatting, guard inside, taking a victim, the victim's stride, the idle
timer, the boom raised, the gate's axis, the caret's flash — plus the eight-view sector the
next draw would land on, the caret's strength, the protest pose, and the bob and the caret's
swell quantised to an eighth of a pixel and a tenth. Four looks are never gated — the flock, the
burning building, the firefight and an abduction mid-take — because each is a continuous
function of the clock that no key could name. **One defect the gate exposed**: the caret's
strength was cached against the event's age alone, and the gate became the first thing to ask
each tick, before the manager and the halo had written where she is, so the lethal cyclist's
caret doubled; the cache is now keyed on her position too, with the regression in
`tests/test_event_redraw.gd`.

**The building shadows are drawn per chunk.** One `Node2D` per 16-tile-square patch that holds
any shadow, so the renderer's own rect culling drops the off-screen ones; `compute()` is
untouched and `split()` is pulled out so `tests/test_building_shadows.gd` can hold that it is a
partition. **Rejected: one mesh.** A mesh is one draw call but still one item, so all of its
triangles are submitted every frame and the primitive count does not move, and this frame is
submission-bound; chunking also keeps the drawing literally unchanged where a mesh would have
re-expressed M122's diagonal corner cut.

**Measured on the measurement's own walk** — `tools/shot.sh out.png 20 --seed 3265820891 --day 1
--walk 3s17e` — with `--disable-vsync` added, because this session's display is 60Hz and with
vsync on every state pins at 60 and the table reads nothing; the four states were run
interleaved, three rounds, on a machine three other agents were using. The baseline is a floor:
in two of three rounds it sits on the display's own pace, so every gap is a lower bound.

| state | fps | draws | objects | primitives | process ms |
|---|---|---|---|---|---|
| baseline | 64 | 708 | 3506 | 7345 | 17.90 |
| events gated | 72 | 715 | 3515 | 7364 | 17.44 |
| shadows chunked | 74 | 583 | 1648 | 3767 | 16.88 |
| both | **90** | 581 | 1642 | 3758 | 15.68 |

About +40% together against the 30% the measurement's (f) row projected. The gate's counters
are unchanged, which is the (e2) shape: the same commands, no rebuild. Chunking leaves about
sixty shadow objects on screen where the whole-city list submitted 1,918.

**Pixel identity: zero of 921,600.** A plain before-and-after cannot answer this, since two runs
of the same build differ by about sixteen thousand pixels of crowd and traffic; `--fixed-fps 60`
makes the capture frame-exact, and base against tip then differs by 1,661 pixels, every one
inside the debug readout's own digits. The method was validated against a control with the
shadows drawing nothing, which differs by 77,040.

**Motion evidence is two bursts**: the dog walker's stride and the café sitters' lean, the
animation a distance-driven key would have silenced. No busker burst, because `--spawn
event:busker` on seed 4242 day 1 lands beside a scaffolding; the café's lean is the same idle
mechanism. There is no leaving fade to key on — *nothing vanishes while you are looking at it*
is a departure, not a fade.
