## M102 — The finale · the escape has what a day has around it, 2026-09-20

*(2026-09-20, [PLAYTEST-114](../playtests/PLAYTEST-114.md): "Pause etc should exist the same way it
does in the main game"; [PLAYTEST-115](../playtests/PLAYTEST-115.md): "The escape shouldn't behave any
different than the rest of the game. If I load into the game and I'm at escape I see the title
screen, then the brief (where I can play the escape or restart for a new game)", and of the hint
line, "it always should show in the beginning even for a normal playthrough".)* One agent commit
on `feature/m102-escape-pause`, reviewed here.

**Two readings were overturned by the player on the way.** The orchestrator had written the
pause's held restart as a return to the section's brief; *"the same way it does in the main
game"* makes it what it is in a day, a new run. And the record below this one chose a resume
straight onto the section's brief; the player's sentence puts the title screen first.

**The pause** is the day's own `PauseScreen`, built in the escape's boot and wired through a
`_connect_pause_signals()` both boots call. `Esc`, the pause button and losing focus open it; it
never opens over a section's brief or the epilogue; `FinaleController`, the interior scene and
the finale's city all stop with the tree, asked of `Node.can_process()`.

**A resume is told from a handover by where `escape_section` came from.** Both reach the
escape's boot with the section set and a save read; only a resume got the value *from* the file,
so it is compared before and after `GameSave.try_resume()`. A resume opens the title with the
tree paused, and the title's start shows the section's brief over the world already built.

**Found on the way: a game closed in the city reopened in the building.** The boot chose its
section from the `--start-escape` word alone, which a real run never carries; it now reads the
saved section for a run's own escape.

**The hint line shows every time a section's clock starts**, a retry and a resume included.
That "always" covers a retry is the orchestrator's reading and open to overturn.

**The audit of a day's boot against the escape's**, and what was left: touch controls,
orientation and the debug readout already matched. The home arrow has no home to point at. The
save indicator stays built only for a run's escape, since a flagged boot writes nothing. The
screen-edge badge, the halo and the debug layers exist for the city section only, and neither
section has a telemetry observer; both need an adapter rather than wiring and are open in
`TODO.md`. Kept different because the player asked: no Nerve cost, the millisecond clock, the
two titles, a clock per section.

**Not covered by a test:** the escape's boot is a coroutine nothing in the suite can drive, so
every new test assembles what it builds by hand; `Esc`'s successful open is proven through focus
loss, which reaches the same `_pause.open()` behind the same guards. Evidence:
`docs/evidence/m102-escape-pause-2026-09-20/`.
