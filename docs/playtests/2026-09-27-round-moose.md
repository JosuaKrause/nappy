# Playtest round-moose — The game over screen says how far you got

2026-09-27. Said in conversation after release v0.20.0 went out, while the queue was being
reviewed together and three tooling PRs were open.

## Statements

1. **Release notes, from the next tag on.** Asked whether GitHub has a native way to show release
   notes:

   > "If so let's create a script that automatically creates a bullet point list of things that
   > landed in the release (from CI during release including everything that is contained in the
   > same version level minor until last minor, patch until last patch, created from existing
   > files -- not agentic)"

   Told that no GitHub Release exists yet for the existing tags:

   > "For the next tag is enough, let's do that now so it's ready for the next release."

2. **The queue's `now` band.** After the whole queue was read out:

   > "also move M210 M217 M213 M221 M222 M215 M218 M206 M205 M175 M185 to now those are major
   > bugs and important items. No need to pick up everything this session but it should be
   > categorized correctly."

3. **The identity wrapper in an isolated worktree.** Asked whether committing should document the
   `.venv/bin/python` form of `tools/agent-identity.py run` that got through where the `uv run`
   form was refused, or whether the permission rule should change instead:

   > "Yes document the fallback"

4. **The game over screen.**

   > "Oh bad ending game over screen should show the day that you made it to"

   Today the `BAD` ending (nerves ran out) shows the heading "GAME OVER", the title "You stop
   going out.", two lines of body text and "Time played" to the millisecond, and nothing says
   which day the run reached. Filed as
   [striped-lemur](../todo/2026-09-27-striped-lemur/README.md).

5. **Its band.**

   > "File that for now too"

6. **Which day.** Asked whether "the day that you made it to" is the day the run ended on or the
   last day completed:

   > "Yes the last day played. Not the last day completed. So if you die on the first day it says
   > 1 and not 0"
