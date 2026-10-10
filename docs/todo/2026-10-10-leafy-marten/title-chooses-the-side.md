# The title chooses the steering side

The title screen (`src/ui/title_screen.gd`) shows two `ModeButton`s today, "On-screen Controls"
(`Symbol.JOYSTICK`, the joystick scheme) and "Tap to Go" (`Symbol.TAP`), side by side across the
bottom. Build the player's layout instead: **two joystick buttons, one drawn where each joystick
focal point is in play** (`TouchControls.FOCUS_LEFT`, 240,480, and `FOCUS_RIGHT`, 1040,480, in
design space), **and the tap button in the centre between them.** Pressing the left joystick
button begins the run in the joystick scheme with the left side steering and the right side Run;
the right one is the mirror. The tap button begins the tap scheme as it does now.

**In play the sides never swap.** No steering press, tap or drag on the Run side selects steering
there; the only way to change sides is the title. Remove round-gecko's side selection and swap
logic from `TouchControls` rather than leaving it unreachable, which is the simplification the
player named ("this all makes the logic to define how each button works easier"). Both rings no
longer show "before the first pointer selection": from the first frame of play, one ring steers
and the other is Run.

**Read as, open to correction:** "permanently for the sitting" is read as until the title is
shown again. The title opens again after a run ends (`TitleScreen.open(again)`), and its buttons
ask again there; the side is never saved as a setting. A resumed run's title asks the same way.

**Proposed, not asked for:** both joystick buttons keep the existing `ModeButton` drawing with
the joystick symbol and the caption "On-screen Controls", and the tap button keeps "Tap to Go";
no new wording is added to say which side steers, since the button's own position says it.
The key player's path (`start_requested`'s `by_key`, a walk key on the title) keeps its current
scheme, and keyboard input picks no side. Both choices go in the PR description.

Verify with the title and touch suites (`./tools/test.sh touch orientation pause`), a test that a
press on Run's half after the start never steers, and stills of the title in landscape and
rotated portrait presentation, embedded in the PR description.
