## M133 — The readout on the live page · built 2026-09-13

*(2026-09-13, [PLAYTEST-69](../playtests/PLAYTEST-69.md): "let's add a ?debug=1 flag" — readout
only — "with a note on the screen that this is debug mode -- the note should not be removable";
held that session and started the next at the player's word.)* Two agent commits on
`feature/m133-live-readout`, reviewed on the PR and checked in a browser against a release
export served locally.

**`?debug=1` reaches the readout and nothing else.** `DevFlags.readout_requested()` parses the
page's `?debug=1` and the command line's `--debug` the way `svg_requested()` does, outside
`enabled()`; `main.gd` reads it once into `_readout_requested` and every place that gated the
readout's visibility or its text assembly on `_debug` now reads `_debug or _readout_requested`.
The three geometry layers, the snapshot key, the layer keys and every other dev flag keep
reading `_debug` alone, so on a release page the `4` key is inert: the readout is on and stays
on. It is the third bounded release-safe query flag beside `?svg=1` and `?telemetry=1`; the
2026-09-06 decision that a release carries no modifiers (M76) otherwise stands.

**The note is its own node.** `DebugModeNote` (`src/dev/debug_mode_note.gd`) is a
`CanvasLayer` above the readout's, built by `main.gd` before either boot path only when the flag
holds, drawing "DEBUG MODE ON" top-left in plain outlined text — the cues rule's own carve-out
for a debug overlay — and nothing sets its visibility or frees it: not the `4` key, not the
title screen hiding the readout around it, not a press. A debug build without the flag does not
show it. It is a separate node rather than a line in the HUD on purpose, both because the HUD
hides and shows itself and because the HUD was another milestone's file that day.

**Checked in a browser.** On the served release export, `?debug=1` shows the note on the title
screen and the readout from the first frame of a run, and `4` changes nothing; without the flag
the page shows neither. The readout's last lines name keys (arrows, WASD, shift, esc, r, q),
which the screen rule otherwise forbids; it is developer furniture a visitor opts into and it
stands, but it is now reachable from a public address for the first time.

**Open to overturn.** The wording, the top-left placement mirroring the readout's corner, the
14px outlined text at 0.85 alpha and the command-line spelling `--debug` (kept for symmetry with
`--svg`, though a debug build shows the readout without it) were the agent's choices.
