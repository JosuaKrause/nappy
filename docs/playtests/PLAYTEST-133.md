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

Then, on the same fix:

> "the focus fix you are doing will it also prevent godot windows from staying open
> indefinitely?"

> "right now if I click somewhere else they stay open" · "and the agent is waiting forever"

It would not by itself: a window also stays open when its script never reaches its own quit, and
when the agent that launched it is cut off. Proposed: every windowed rig carries a hard wall-clock
limit, kept twice.

## The statements

1. **A rig's window never takes the focus** from what the player is doing.
2. **A rig hears no real input**: no key or pointer press reaches the game during a scripted run.
3. **A rig's window never stays open indefinitely**: the game quits itself on a wall-clock
   limit, and `tools/shot.sh` kills a process still alive past it and says so.
4. It is its own queue item, built after the seal on her building's front (draft PR #351), whose
   agent is taking captures while this is written.

## Then, after the fix landed (#353)

> "are all agents using the non-focus rig now? I still lose focus and even accidentally closed one
> window"

One agent's branch predated the fix, but the other's had it and the player still lost focus: the
window's no-focus flag stops the window taking keys, while macOS still brings the Godot app to the
front when it launches, which the fix's own record left unverified.

6. **A rig is launched in the background**, so macOS never makes it the active app and the
   player's focus stays where it is.
