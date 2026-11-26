# Thought bubbles over the mother: four hints still to build

The player: "thought bubbles -- I really like that idea for immediate feedback especially since it
doesn't need reading", then "we should make it so it only shows a few times for each new lesson"
(curly-moose #819). The mechanics are `HintWatch`, which asks a `HintWatcher` per hint, `ThoughtBubble`,
which draws the picture over her, and `HintLedger`, which counts the shows; `SimulationBuilder` lists
the watchers (`docs/EVENTS.md`, "The visual vocabulary").

**Still to build**, each a watcher handed what its question reads, with its picture already in the
`ui` atlas page (`hint_cross_street`, `hint_turn_back`, `hint_chalk`, `hint_hut`, and the arrow
`hint_arrow`) and a place to be given in `HintKind`:

- **Cross the street**: a body closes her sidewalk ahead and the far one is open; points at the nearest
  zebra crossing.
- **Turn back**: she nears a seal or closure that leaves no sidewalk on along her heading (day 2's
  dead end).
- **The chalk mark**: it first comes into her view (`VisibleView`), shown a few times in all; "also a
  thought bubble should hint on going into the alley to get the mark" (minty-dolphin #868); "when the
  mark becomes visible to the player for the first time it causes a thought bubble" (gentle-owl #1234).
- **Walk through the hut**: a checkpoint hut she may walk through first comes into her view
  (curly-moose #819).

The order they win in: cross the street and turn back come before walk wide of the noise; the chalk
mark and the hut come after the way to the park.
