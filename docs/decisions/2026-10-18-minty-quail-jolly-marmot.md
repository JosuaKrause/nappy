# minty-quail — The city's run, trace and atlas go private · 2026-11-24

The last pull request of the city scene lane (design `minty-quail-city-scene-pass.md`, C7). After
C6a and C6b (records bouncy-osprey and busy-panda) no suite or probe read `City.run`,
`City.trace` or `City.atlas`, and the scene runtime's three reads were gone with lane D, so the
three vars could go private.

## What was built

- **`City.run`, `trace` and `atlas` are `_run`, `_trace` and `_atlas`**, written only by
  `equip()` and `use_run()`. The game reads none of them from outside `city.gd`, so no method
  answers `run` or `trace`.
- **`City.atlas()` answers the library the city was equipped with**, kept public in
  `tools/test_only_members.txt` as a `[kept]` line: `tests/test_atlas_boot.gd` sweeps every node
  of a booted game for the sitting's library, and `"atlas" in node` no longer finds the city, so
  the sweep asks it through the method and counts it as a holder. Nothing the city draws shows which
  library it was handed, so no other read confirms it.
- **The conversion ran as** `uv run python tools/field_to_method.py --dry-run src/city/city.gd run
  trace atlas`, which refused: `city.gd` names two locals `run` (a barrier's end points and a
  collision strip's rectangle), which a rename by name would have renamed with the field. They are
  renamed by hand to `ends` and `strip`; then the same command without `--dry-run` wrote the
  file (the engine refused 0 uses elsewhere). The one other hand fix is the comment in
  `resistance_director.gd` that named `City.atlas`.
- **The sweep fails when the city is handed another library**: with `atlas()` temporarily returning
  a fresh `AtlasLibrary`, the suite fails with "the day: every one draws from the sitting's library
  (not: City)"; with the real field it passes.

## Search for the old names without parentheses

`rg -P '\b(city|_city)\.(run|trace|atlas)\b(?!\()' src tests tools` comes back empty. Remaining
hits of the bare names elsewhere: `step.get("run")` and `input.run` in the walk plan and the
screenshot rig (a walk step's and an input's own key), `_flushes.trace` in `game_save.gd` (the
save's flush record), `escape.run` in `tests/finale_rig.gd` (the rig's own stand), `texture.atlas`
and `region.atlas` (an engine `AtlasTexture`), and the atlas assignments inside `city.gd` itself
(`_home_door.atlas = _atlas`, `stack.atlas = _atlas`: the home door's and a prop stack's own fields).
