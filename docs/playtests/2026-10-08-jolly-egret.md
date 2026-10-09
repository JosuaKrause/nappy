# Playtest jolly-egret — An opposite-side tap runs while steering is held

2026-10-08

## #630 — a held steering touch gives the other side to Run

The player said:

> let's fix the run button by making any tap on the opposite side a run if the original side is still holding down the direction

This refines [round-gecko](../decisions/2026-10-07-round-gecko.md), which leaves the opposite
joystick as a small Run disc after a steering tap or drag. Its current rule reserves only a press
that begins on that disc for Run; a press elsewhere on the other half changes the steering side.

**Filed as snowy-wombat, an opposite-side tap runs while steering is held.** While a joystick
pointer remains down and owns a direction from one side, a fresh pointer down anywhere in the
other side's steering area holds Run. Releasing the fresh pointer stops that hold. When the first
pointer has already lifted, the earlier behavior remains: a tap outside the displayed Run disc on
the other side selects that side for steering. The middle stop band and pause button keep their
existing meanings.

2026-10-08.
