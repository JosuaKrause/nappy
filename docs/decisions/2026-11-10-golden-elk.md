# golden-elk — A scratch script that reloads in-memory GDScript source crashes the engine · 2026-11-10 · not from an entry



**What happened.** On 2026-11-10, on Godot 4.7.2 (macOS, arm64), a review agent asked the engine a
question with a scratch script: `Godot --headless -d --path . --script <a file under /tmp>`. The
script extended `SceneTree`, set the three warnings `debug/gdscript/warnings/untyped_declaration`,
`unsafe_property_access` and `unsafe_method_access` through `ProjectSettings.set_setting()` at run
time, then set a `GDScript`'s `source_code` from a string and called `reload()`. The engine stopped
at a debugger break and died 0.3 s after launch with "handle_crash: Program crashed with signal
11". macOS wrote a crash report (EXC_BAD_ACCESS at 0xe8, then SIGABRT), which the player saw as a
crash dialog.

**What is known, and what is not.** Reloading a GDScript from in-memory source at run time, under
`-d`, after changing those warning settings at run time, crashed the engine. Which of the three
ingredients is necessary was not isolated: the reload alone, the debug flag, or the run-time
setting of the warnings may each be enough or each be irrelevant.

**Not attributed.** Two earlier crashes the same day, at 16:23 and 16:26 EST, each with a `python3`
parent process, are not attributed to this cause or to any other.

**The rule.** The **godot** skill, "Structure", says an engine question is asked with a script
saved to a file, through the repository's own runners, and never by reloading a GDScript from
in-memory source or by changing `debug/gdscript/warnings/*` at run time. Every crash puts a crash
dialog in front of the player, so the safe way is the only way, whether or not the cause is ever
isolated.
