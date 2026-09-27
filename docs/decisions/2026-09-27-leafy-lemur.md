# leafy-lemur — The on-screen controls show her heading at both focal points · built 2026-09-27

*([olive-koala](../playtests/2026-09-27-olive-koala.md), statement 6: "the onscreen controls should
show the selected direction on both sides always. when using hands and when using the keyboard")*

**Built (PR #412).** `TouchControls.current_heading()` reads the four move actions the way the
stroller does for her velocity, and both of `Mode.JOYSTICK`'s focal rings draw that heading, so a
press through either ring and a key both show on both. The rings redraw every frame of a running
day, since a key's release never passes through the controls. `Mode.TAP` has one aiming origin,
her, and is unchanged. `tests/test_touch.gd` checks a press through either focus and a key against
`current_heading()`. The keyboard case has no still: the capture rig cannot hold a key through a
capture (breezy-owl), and the player chose to check it in game ("no need for proof there" · "I
will see it in game").
