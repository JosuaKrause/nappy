# A trailer recipe's settled camera must be a boolean

**Low · from the re-review of PR #580 (the trailer reimagined, its camera starting at the
player).** `playback.settled_camera` accepts any value (`"false"` is truthy) in
`src/dev/scene_recipe_runtime.gd`; require a bool as `camera.fixed` does, with a schema test.
