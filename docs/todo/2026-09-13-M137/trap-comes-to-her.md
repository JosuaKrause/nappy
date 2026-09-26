**The trap comes to her.** On a perform step, no robber is seeded at dawn. At the moment
the note is handed over, `spawn_extra` puts a robber on walkable ground outside the view
rect (`set_sight`'s own callable, or the stream radius M131 measured, says what off screen
is) already awake and pursuing, so he runs at her from off screen. **He is his own
catalogue row, not an `alley_robbery` woken by hand.** *(2026-09-13: "we need a version of
the robber that is not frozen when spawned.")* `alley_robbery` is `is_waiting()` from the
frame it spawns — `pursues_within > 0` and no notice yet — and the new row is never
waiting: awake from its first frame, telegraph included, the same body, speed, lethal
reach and picture as the alley robber, `hard_fail` like him, and spawned only by the
director — never placed, budgeted or streamed by the scheduler, so `EventDef.validate()`
and the catalogue's placement pool are told so. He obeys the row's own numbers — spawn
distance is a new number the **balance** rule owns — and the telegraph contract: the
screen-edge badge and the caret answer him the way they answer any pursuer, so the player
has the reaction time the contract promises. A chalk mark's guard is unchanged: this entry
is about the perform step's contact, which is what the player named; say so in the record
if a chalk mark's trap should follow.

**What an agent's reading of the code found before it was stopped, unverified by any
rig.** The stream-in path's `EventInstance.resume(age, travelled, noticed_at)` would take
an alley robber out of waiting, which is the by-hand wake the player refused; the new row
says it in the definition instead. Once noticed, `_chase()` moves him at
`pursue_speed` (130 px/s) from the first frame — the row does not set
`still_while_telegraphing` — holding at the standoff until his 1.8 s telegraph ends, so
`DangerEdge` already arrows any `hard_fail` row and announces him on the first closing
frame: no cue code changes. A candidate spawn distance, to be scrutinised: 400 px clears
the view from any bearing (the viewport's half-diagonal at zoom 2 is about 367 px, the
argument `NOTICE_RADIUS`'s own doc makes), plus `pursue_speed × Tuning.PURSUIT_MIN_NOTICE`
(130 × 1.5 = 195) so at least the minimum notice passes while only the badge speaks for
him — about 600 px. The trigger belongs in the contact-completed path, gated on
`task_event_id` being set and on `TRAP_FIRST_DAY`, with a guard on `_maybe_set_a_trap`'s
dawn call for a perform step; `_draw_guard_position`'s rejection loop (walkable, not
closed, not held, not the home block) is the bearing draw to reuse.
