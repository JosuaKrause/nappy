# polite-swan: run buttons beside the joystick focal points

## joystick-run-buttons.png

**Claim.** In joystick mode the touch layout draws a run button beside each focal ring, the chevrons pointing up on both, at (350,480) and (930,480) (the "Inward" spot the player chose, inbox #477), and nothing else of the layout moved. **Limits.** The idle state only: the dev flags cannot hold a finger down (`--tap` sends a press and a release), so the held look (the `Palette.BUTTON_PRESSED` disc behind both glyphs) is not pictured; the hold itself is covered by `tests/test_touch.gd`. One frame, one seed, 1280x720 unrotated; says nothing about a real phone's thumb reach. layout.png shows the four candidate spots the player chose between.

- Source revision: `14848bec` (clean tree).
- Command: `tools/shot.sh docs/evidence/polite-swan-run-buttons-2026-10-03/joystick-run-buttons.png 4 --seed 4242 --day 1 --controls joystick --touch --press key:4 1.5` (`--press key:4` toggles the developer readout off).
- Seed 4242, day 1, 4.0s wait. Nothing else retained from the run.

## layout.png

**Claim.** The 1280x720 touch layout with the screen-edge badge track, arrow strips, pause button, touch HUD meters, day-hint label, stop band and both rings, and four candidate run-button spots per side with what each takes away; B (inward) is the one the player chose. **Limits.** A diagram, not a capture: positions come from the constants named in `layout.py`'s docstring, copied by hand, and go stale if those change. Regenerate with `python3 layout.py layout.png` (Pillow, headless).
