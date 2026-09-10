# Playtest 47 — A stale import and a one-way tunnel · 2026-09-09

Two notes from the player after pulling `main` at `b4e0fba` and starting `./tools/run.sh`.

## 1. The game does not boot on a pulled checkout

> ```
> ERROR: Unable to open file: res://.godot/imported/pram-layered-v3-draft-transparent.png-85e7ca641939dbb97a440d2158284260.ctex.
> SCRIPT ERROR: Parse Error: Could not preload resource file "res://assets/illustrated/modular/pram-layered-v3-draft-transparent.png".
>           at: GDScript::reload (res://src/visuals/modular_person.gd:10)
> SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
>           at: GDScript::reload (res://src/player/stroller.gd:0)
> ```
>
> (and the same compile error for the crowd, the city, the event manager, the halos, the scheduler
> and the telemetry autoload)

The pram texture that `ModularPerson` preloads is committed with its `.import` sidecar, but the
imported `.ctex` it points at lives in the gitignored `.godot/imported/` folder, which a pull never
touches. `tools/run.sh` only checks the global class cache before launching, so a checkout whose
scripts all resolve but whose textures were never imported boots straight into a parse error that
takes every script depending on the player down with it.

## 2. No car ever comes out of the tunnel or off the bridge

> "also, no car ever comes *out* of the tunnel or from the bridge."

Cars leave by the tunnel and the bridge, and only ever leave. The two exits are meant to say
*the city goes on past here*, and traffic that only ever runs one way through them says the
opposite: a road that drains and never fills.
