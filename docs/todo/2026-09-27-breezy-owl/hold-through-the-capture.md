**`tools/shot.sh` can hold a direction on the frame it captures.** Today three things stop it:
`AutoScreenshot._tap()` sends a press and its release in the same frame; `--press key:<name>`
builds an `InputEventKey` with `keycode` but no `physical_keycode`, while every move binding in
`project.godot` is `physical_keycode`-only, so `--press key:d` never presses `move_right`; and
`AutoScreenshot._process()` releases every direction it holds (`--walk`, `--flee`) before it
awaits the frame it captures. A test pins a key held through a capture.
