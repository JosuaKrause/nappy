## M148 — A rolling graph of frame times on the readout · built 2026-09-14

*(2026-09-14, [PLAYTEST-75](../playtests/PLAYTEST-75.md): "I would expect there to be an overlay
that shows the last x frames of frame times in a rolling window" — said of the `--spikes` line,
which is a line in the run log and not what the player meant.)* One agent commit on
`feature/m148-frame-graph`, reviewed on the PR; the still is
`evidence/m148-frame-graph-2026-09-14/readout-graph.png`.

**What it is.** `FrameGraph` (`src/ui/frame_graph.gd`), a `Control` on the readout's own
`CanvasLayer`, built only while `_debug or _readout_requested` holds — absent, not hidden, on
a release page nobody asked `?debug=1` of — and shown and hidden with the readout: one
setter, `_set_readout_visible()`, is now the only place `main.gd` assigns the readout's
visibility, and the boot, the escape boot, the title screen and the `4` key all go through
it, so the two cannot drift apart. It keeps a ring of the last 240 frame deltas fed from
`_process`'s own `delta` (the frame's actual length, not the engine's per-second maximum —
M138, what the readout's lines measure), redraws each frame it is visible, and draws a 240
by 48 design-pixel box: one one-pixel bar per frame, newest at the right, scaled so 33.3 ms
reaches the top; reference lines at 16.7 and 33.3 ms labelled `60` and `30`; the window's
mean as a thin line; a frame past 16.7 ms in `Palette.MARK_COSTLY`, past 33.3 ms in
`Palette.MARK_LETHAL`, the rest the readout's own
text colour at half alpha; a 0.75-alpha black backing so the bars read against the street.
It sits 600 design pixels under the readout block's top, left-aligned with it, which clears
the block's longest shape (thirty lines under `--skip`) and the phone's right focus ring
(centred at y 480 with a 48 px radius, so it ends at 528). `mouse_filter` is `IGNORE` so a
touch through it reaches the joystick. Tests: the ring keeps exactly the last 240 of 300
pushes in order, the mean is the window's, the three classes come out for a known window, a
hidden graph records nothing; and the graph exists under the readout's layer iff the readout
was requested. `docs/TELEMETRY.md`'s debug view and `README.md`'s `--debug` row describe it.

**Corrected the same evening: a bar's class is decided when its frame is pushed.** *(2026-09-14,
the player: "I would assume that the graph adds a row on the right and moves the rest to the
left. but I see things on the left side changing (notably adding yellow lines after the
fact)".)* The first build classified every bar at draw time against the window's current
mean, so as the mean moved, old bars turned amber or back. Now `push()` classifies the frame
against the frames before it — the spike line's own rule, a frame does not raise the bar it
has to clear — and stores the class beside the delta; `_draw()` reads the stored class. A bar
keeps the colour it was born with and only ever scrolls left. **And later the same evening the
rule itself went absolute**: *("picture taking shouldn't hide the amber")* — under a burst's
per-frame readback every frame was 60 to 76 ms, nothing was twice the window's mean, and the
amber vanished. Amber is now a frame past the 16.7 ms line and red one past 33.3 ms, the two
lines the box draws, whatever the neighbours did; the mean line stays as a reading, not a
threshold.

**Choices made where the entry was silent, open to overturn.** Lethal over costly when both
hold; the backing at 0.75 rather than the 0.35 first tried, under which ordinary bars at half
the readout's own alpha vanished against the world; the labels inside the box's left edge; the
fixed offset rather than a per-frame measurement of the block's height; the visibility setter
refactor across the five sites. In the still the bars are tiny — a headless rig draws in a
few milliseconds — and no bar is coloured, since the day-start frame had aged out of the
window by the fourth second; the red was seen on an earlier draft's still.
