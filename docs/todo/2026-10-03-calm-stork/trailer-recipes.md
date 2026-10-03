# Build the player's scenes and photograph each one

Use the original descriptions in [PLAYTEST-139, trailer action and composition](../../playtests/PLAYTEST-139.md).
Each scene has an individually runnable saved recipe using production components and
the existing explicit creation checks. Do not copy the first attempted trailer's
seeded composition as the storyboard.

[rosy-lark, trailer still feedback](../../playtests/2026-10-03-rosy-lark.md)
requires the choice, blower, dog and title scenes to bustle with people and events.
The trucks scene needs activity appropriate to its day, the mother facing down, and
varied posters on both buildings. [Downy-egret, the numbered scene review](../../playtests/2026-10-03-downy-egret.md)
clarifies that the father's approach is horizontal and the gate itself is vertical.
The chase still must show
a readable running pose; action telemetry alone does not answer its visual feedback.

Show going down the wrong path, turning around and going another way. The player
does not require an obstacle as the reason. No fixed opening position in the final
edit is decided here. Show mostly early dangers through the charging dog with its
real warning and charge. **Proposed, not asked for:** select representative early
encounters for the first preview; identify that selection so it can be changed.

Build the three later-day glimpses with the specified parents: army trucks driving
beside the mother; the father walking toward a gatehouse; the mother visibly running
carrying the baby while guards pursue. Use the actual
[FinaleController](../../../src/finale/finale_controller.gd) for carrying/escape state
and [FinalePlanner](../../../src/finale/finale_planner.gd) for the escape route setup.
Check real gameplay actions, rather than painting substitutes that resemble them.

Build the final zoom from **her doorstep** to the whole bustling city, retaining
the active city. Construct enough extent for that view. PLAYTEST-139 statement 8 says
the other shots are "chosen at random but fixed". Per-shot parent assignments remain
open to M204's editorial choice; recipe preview assignments are proposals, not a
strict alternation rule. The three glimpses keep their mother/father/mother assignments.
Title, fades, one-second glimpse duration,
overall maximum thirty seconds, on-screen text, game resolution and audio remain the
movie editorial requirements in [M204, trailer cut](../2026-09-25-M204/README.md).

When updating the rig, provide an adjustable capture start time after movement begins.
Advance the whole scene during this pre-roll: player movement, vehicles, crowds,
pursuits and any scripted camera track. Everything meant to move is already moving
when capture starts. Keep a configurable zero offset for deliberate resting openings.
Reuse the `in` field in `tools/trailer/shots.json` where it supplies this behavior:
it is seconds into a shot's frames where `tools/trailer.sh` starts the cut. Also
document its units and relationship to the simulation clock. No video render is needed
for this pass.

Assert setup and requested action at named ticks headlessly. Take screenshots of every
created trailer scene at an adjustable intended moment, including those motion scenes;
the player explicitly asks for stills, and stills alone do not prove movement.
Provide commands, resolved setup and provenance. Follow
[verify](../../../.claude/skills/verify/SKILL.md),
[session-captures](../../../.claude/skills/session-captures/SKILL.md) and
[committing](../../../.claude/skills/committing/SKILL.md) for retained runs and
commit-pinned images embedded in the PR. Send useful previews early for composition
feedback. Neither movie assembly nor pixel reproducibility under load gates this work.
