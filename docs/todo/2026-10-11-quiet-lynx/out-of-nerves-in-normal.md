# What the last nerve does in normal mode

**Normal mode never reaches the GAME OVER ending** (statement 7: *"No game over in normal
(Recommended)"*). Losing the last nerve sends the run to its latest checkpoint with 5 nerves (see
[checkpoints.md](checkpoints.md)).

The lost-day screen says where she goes back to, for example "Back to day 8", with the nerves drawn
as five stars through `NerveDisplay.stars()` (the one function every screen that shows nerves reads
them through, as `docs/MECHANICS.md` "Nerves" says). It keeps the ordinary continue button, which
now really continues: into the checkpoint's day.

**The GAME OVER screen, still with no continue button, is hard mode's only.** This keeps PLAYTEST-28
finding 4 as written (*"the game over screen cannot have a continue button"*,
[PLAYTEST-28](../../playtests/PLAYTEST-28.md)): the screen with no continue button is the screen a
run ends on, and a normal run does not end there.

A resumed save whose day was under way costs a nerve, as it does today (`docs/MECHANICS.md` "Saving
and resuming"). If that spends the last nerve in normal mode, the run goes to the checkpoint the same
way, on the same screen.

The pause screen's held restart still starts from scratch in both modes, never from a checkpoint:
*"restart button restarts the game from scratch -- not sure why that was ever a question?"*
([PLAYTEST-143](../../playtests/PLAYTEST-143.md)). It goes back to the title, where the Hard Mode
checkbox shows again.

**Proposed, not asked for:** the exact wording of the lost-day screen's line. The player's own
example was "Back to day 8".
