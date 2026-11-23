# polite-tapir — The button tokens are the texts' · 2026-11-23

**The ask.** Every listed layer break is fixed, moved in the map, or declared permanent with its reason (the design review's reading, which the player approved, inbox #1268 in olive-ferret). This is pull request 2 of Fable's design `polite-tapir-standing-rest`: the break where `Texts` (data, every sentence the screen says) built a line from a constant of `HelpText` (view, the label that draws a button's picture in the middle of a line).

**What was built.** The two tokens, `{pause}` and `{run}`, are part of the sentence, so they are written where the sentences are: `Texts.PAUSE_TOKEN` and `Texts.RUN_TOKEN`, at the head of the lessons section. `Texts.RUN_JOYSTICK` reads `RUN_TOKEN`. `HelpText` reads them from below: its icon table is keyed by them and `measurable()` replaces them. `HelpText` keeps no alias under the old names. The readers moved with them: `hud.gd`, `test_sentence_lines.gd`, `test_hud.gd`, `test_pause.gd`. The `HelpText` entry of `tools/layer_map.py` is deleted, and the two clauses of the item file that named the `HelpText` token are settled. No sentence changed, so no picture is owed.

**Rejected.** Handing `HelpText.joystick_in_force()` its group lookup's answer is not done: it is not a listed break, and the view is not a layer that is handed what it reads. `Texts.PAUSE_LESSON`'s `%s` form stays.
