# Playtest 133 — A rig's window takes no focus and hears no stray key

2026-09-25. Said in conversation, after a drawing agent's day 11 capture on seed 4242 showed her
eight tiles off her stoop, where every day starts her.

## What the player said

> "since those are godot apps that launch in my view it could be that accidentally pressed a
> button maybe? since it takes the focus away from what I'm doing every time"

## What was proposed

1. A rig's window opens without taking focus (Godot's no-focus window flag), so typing stays in
   whatever the player is working in.
2. A scripted rig ignores real keyboard and pointer input, since it drives her from its own
   script, so a stray key can never move her in a capture.

> "that would be good"

## The statements

1. **A rig's window never takes the focus** from what the player is doing.
2. **A rig hears no real input**: no key or pointer press reaches the game during a scripted run.
3. It is its own queue item, built after the seal on her building's front (draft PR #351), whose
   agent is taking captures while this is written.
