## M173 — The standalone bake names a stale import cache · built 2026-09-20

Pull request #253. Found the same day: the player pulled a change that added six pictures, ran
`tools/bake-atlases.sh` by hand, and got a bake that succeeded followed by dozens of `ERROR:`
and `SCRIPT ERROR` lines and an exit of zero.

**The cause.** The engine loads `project.godot`'s autoloads before it runs any `--script`,
whatever the script references, and their dependency chain reaches `event_instance.gd`'s
`preload`s. With an import cache that has not seen a picture, those fail and every script that
depends on them fails to compile; with no `.godot/` at all — every fresh clone and worktree —
no `class_name` resolves and every autoload fails. The bake reads its sources itself, so its
pages are right either way.

**Built.** The wrapper captures the engine's output, prints all of it, and takes its existing
failure paths first — a non-zero exit from the bake, or outputs still stale afterwards — so the
explanation is never printed over a real failure. When the bake succeeded and the output
carries `SCRIPT ERROR`, `Parse Error` or `ERROR:`, it says after the engine's lines that the
pages are correct, what the errors are, and that `tools/check.sh` repairs it. It exits zero,
because `check.sh`, `test.sh` and `export-web.sh` call it before their own import pass and
treat non-zero as a failed bake, on exactly the tree they most need to work on; `run.sh` and
`shot.sh` call `--check`, which never starts the engine.

**Rejected.** Telling an import-cache cascade from any other engine error: the two reproduced
cascades share no stable wording, and matching the engine's diagnostics line by line is a
parser of somebody else's prose. Running the bake without the autoloads: this engine version
has no flag for it, and rewriting `project.godot` around the bake is more than the defect is
worth. M164's gate does not see this output, since nothing greps the bake's.

**It ends by itself** when M171's last item removes the last `preload` of a source picture.

**It did not.** The last picture `preload` went with the events (#255) and the cascade is
unchanged on a tree with no `.godot/`: a forced bake still prints a parse cascade from
`game_state.gd` and `Failed to instantiate an autoload`, because without the class-name cache
no `class_name` resolves — the second cause above. The diagnostic stays, and the wrapper names
that cause (#257).
