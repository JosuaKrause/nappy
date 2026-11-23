priority: now
after: 2026-10-18-minty-quail

# tawny-wombat — The army truck and the stairwell masked man are placed after their badge · filed 2026-10-31


**The ask.** Told which dangers get a screen-edge badge while already in the world, the player:
"Army convoy should definitely placed for her not at dawn. Otherwise it might have driven away by
then", "Stairwell guard could as well be placed when it should appear instead of when entering", and
"Anyway a badge shouldn't disappear before the entity is visible" (minty-dolphin #852). Then, about
the badge handler keeping the rule that badges a danger already in the world: "Don't let legacy
implementations prevent you from establishing a clean design" (minty-dolphin #852).

**Read as:** every badge comes from one path, a warning put up before its danger is placed, pointing
at where it will come from. The two dangers still badged while already in the world are moved onto
that path, and the handler's measuring of dangers in the world goes. The army truck is the
`military_convoy` row (`EventDef.Look.ARMY_TRUCK`, from day 13, planned at dawn today); the stairwell
masked man is the escape building's guard placed at the foot of the stairwell when she enters, who
runs at her once she is within 426px. The badge handler, `BadgeModel` (`src/ui/badge_model.gd`), says
in its own comment that `_measure_dangers_in_the_world()` "goes, as a deletion, in the follow-up that
places those two after their badge" (minty-quail-15, PR #854).

**Items:** `army-truck-after-its-badge.md`, `stairwell-man-after-his-badge.md`, and the deletion
of the measuring, in whichever of the two lands second.

*Proposed, not asked for:* one entry with two items rather than the "two queue entries after the
refactor" the orchestrator named when it settled the board question badge-before-placing; the band
`now`, after minty-quail, since the refactor reshapes the events and badges it touches. Open to the
player's correction.
