## M73 — The meter tells the truth, and the local build starts · built 2026-09-06

Playtest 25's first two findings, both about a reader being told something that is not so — one on
screen, one at the command line — plus the two items that fell out of them.

**The invincibility bug was one untyped array literal.** *"if excitement reaches 100 the game
doesn't end! that's a major bug … it stays on 100 and I'm completely invincible"*. In
`_on_day_finished()`, `_observer.trail() if _observer else []` assigned an **untyped** `Array` to an
`Array[Vector3]`, which throws at runtime. With telemetry off the `else` ran, the handler aborted
six lines before the summary was shown, and `DayController._end()` had already set the phase to
`OVER` — so the clock stopped, no summary appeared, she kept walking, and every later ending was
swallowed, because the crying handler, the hard-fail handler and `DayController._process()` all
return unless the day is running.

**Nothing about it was mobile, and that is why it survived every gate.** `Telemetry` disables itself
on a web export, so the observer is null there and never null on an ordinary desktop run — the
desktop and every rig died correctly. **A cast on the literal was rejected in favour of a typed
local assigned in an `if`**: the ternary would have invited the same edit back, and the tree was
grepped for the same shape — a typed collection initialised from a ternary with a bare `[]` or `{}`
on one side — in the same commit.

**Every environment gate became a flag with an override.** *(2026-09-05: "in general don't tie
features directly to an environment — tie it to a feature flag which might be informed by the
environment but lets you override … that way you can get telemetry when you need it".)* The rule
itself went into the **godot** skill so it arrives before the next edit that would break it. The
gates it condemned were `Telemetry`'s web check — which is what hid the bug above, by making the web
build's day-ending path unreachable from every test and every desktop session — plus
`QuitOption.available()`, `DevFlags.enabled()` and `AutoScreenshot`. The platform default is kept in
each case and the reasoning with it: `user://` on a web export is a stranger's browser storage that
nobody collects or clears. **The measure of done was the reach rather than the flags** — for each
gate, how a person enters the branch the platform does not pick for them — and the override has to
work in a *release* build, since the deployed page is exactly where `DevFlags` cannot reach.
`ControlsMode`'s `?controls=` URL flag was the precedent. `TouchInput.available()` already had the
shape and needed nothing.

**A meter bar may not read `100` while the day is still alive.** `MeterBar._draw()` printed with
`"%3.0f"`, which rounds to nearest, so 99.5 and above printed `100` while the day ends at exactly
`Tuning.METER_MAX`. The player met it on a phone and read it as the crying rule being broken — it is
the same sentence that opened the bug above, and the two were genuinely different faults. Both bars
now floor rather than round, since the sleepiness bar told the same lie at the other end of the day.

**`tools/run.sh` refuses a stale class cache instead of booting into it.** The player's local build
would not start: `Parse Error: Identifier "ControlsMode" not declared in the current scope`, and the
same for `TapControls`. Neither file was missing; what was missing was their entry in
`.godot/global_script_class_cache.cfg`, because `run.sh` exec'd the Godot binary straight at the
project with no import pass and the checkout's cache predated the merge that added them. **No gate
could have caught it and none was at fault** — CI and `tools/check.sh` both import from clean, which
is why `check.sh` was green on a tree that would not run. It is reachable from any `git pull` that
adds a `class_name`. The constraint on the fix was that `run.sh` must not become slow to start, so
the import pass is a no-op on an up-to-date cache.
