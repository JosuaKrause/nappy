# round-gecko — The unused joystick becomes Run · 2026-10-07

The player asked in [dotted-sparrow](../playtests/2026-10-07-dotted-sparrow.md), issue #602,
for the unused joystick to become Run at the joystick's size, and every button's effective
radius to extend 5% beyond its visible radius, except the joystick dead zone. They clarified
that using the joystick chooses the side, that the choice is not permanent, and explicitly
selected "Keep Run visible until the player steers from the other side": "steering can also
be done by tapping so we shouldn't immediately reset".

**Built in PR #603.** A tap or drag in joystick mode selects its steering focus and replaces
the opposite ring with the existing Run glyph. Release retains both the heading and that side
choice. A steering press outside the Run disc on the other half, or a drag that crosses the
middle stop band and resumes there, swaps the roles. Run takes only a pointer whose press begins
on its displayed disc; a run pointer remains a run pointer through a side swap, and a steering
drag cannot acquire a run hold by crossing the disc. Held Run and a double-tap run latch remain
independent. Pausing, hiding controls, and changing schemes release held input.

`ButtonGeometry` supplies the shared 1.05 radius multiplier. The joystick's dead zone remains
48px; its 2px ring stroke reaches 49px, which is Run's painted radius. The Run catch is 51.45px.
Pause's painted radius is 26px and its catch 27.3px. The SVG drawing compensates for its
transparent margins. Title, pause, and summary buttons use radial catches and matching hover
instead of enlarged rectangles, with their local transforms and presentation rotation respected.
Restart holds and background continue actions keep their existing behavior. The two covered
corners used by `VisibleView` end at the focal discs, without the removed inward buttons' space.

**Replaced decisions.** [Polite-swan](2026-10-03-polite-swan.md) recorded two separate buttons,
110px inward of the focal rings, drawn at 34px with a 46px catch. Its placement came from the
player's "Inward" choice. The player's new "instead" request replaces that layout and its
phone review. [Leafy-lemur](2026-09-27-leafy-lemur.md) displayed the heading on both rings;
the ring displaying Run now gives that space to the requested button. The remaining steering
ring still reads the actual movement input, including keyboard input and detention.

**Small implementation choices, open to correction:** both joysticks show before the first
pointer selection, and keyboard input picks no side. A press in an available ring's dead zone
selects that side too, so a drag may begin there; a middle-band-only press does not select a side.
The Run disc reserves its own presses for running, so a new steering press on that half lands
outside it. Selection survives pause/resume, clears on a scheme change or a reconstructed day's
controls, and is never stored as a handedness setting.

**Verified.** `./tools/check.sh` and `./tools/lint.sh` passed. The combined focused run
`./tools/test.sh touch orientation pause encounters held_restart` passed 544 checks; a final
touch run passed 206 checks after adding two tap-and-run side-swap assertions. Three orientation
test fixtures were changed to free their controls immediately, preventing a queued old fixture
from supplying the next suite's control mode. No full local suite was run; full game and browser
verification is CI's. The two inspected [gameplay stills](../evidence/round-gecko-controls-2026-10-07/README.md)
show both layouts after synthetic tap release, with provenance and limits. Evidence is three files,
434,699 bytes. Its phone review is now [leafy-marten](../review/2026-10-10-leafy-marten.md)'s, which keeps the button-rim check.
