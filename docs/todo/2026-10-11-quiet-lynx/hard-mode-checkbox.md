# The Hard Mode checkbox and the mode carried in the save

The title screen shows a **Hard Mode** checkbox, and only when the title is beginning a new game,
meaning no resumable save is behind it (statement 1: *"a "Hard Mode" checkbox on the title screen
(if new game)"*). It decides whether checkpoints exist: checked, the run has none.

The mode is fixed for the run and carried in the save, so a resumed run is in the mode it began in.
A save with no mode key reads as normal.

The title's class doc in `src/ui/title_screen.gd` says *"What it is not is a main menu. There are no
options, no seed box and no load game"*. The checkbox is the one option, so that sentence changes in
the same pull request, to say there is exactly one and what it is. The player asked for the
checkbox, which is why the doc is allowed to change.

**Proposed, not asked for:**

- The box starts unchecked on every new game and is not remembered between sittings. The plainer
  alternative, remembering the last choice, would put a setting outside the save and make a returning
  player's mode depend on something the run does not hold.
- Nothing during play shows the mode: no HUD mark, no line on the day brief. The mode changes only
  what happens after the last nerve.
- A tap on the box never starts the game. Only the title's three controls buttons start it, as now,
  so the box can be set and changed freely before choosing a control scheme.
