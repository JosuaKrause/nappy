class_name TelemetryScreen
extends RefCounted
## What the run log photographs: whether there is a drawn frame to read at all, the wait for the
## next one, and the picture it holds. `Telemetry` builds the one it photographs (the game's own
## viewport) and hands it to its `BurstRecorder`, so the recorder never asks the display server or
## the tree anything itself, and a test hands it a screen of its own.
##
## **This base is a screen with nothing on it**, which is what a headless process has: it cannot
## draw, so nothing waits on it or reads it.

## Whether a frame can be drawn and read back. False headless, where the null display server
## draws nothing.
func can_draw() -> bool:
	return false

## Returns once a frame has been drawn since the call. A coroutine: callers `await` it.
func drawn() -> void:
	await Engine.get_main_loop().process_frame

## The frame just drawn, or null when there is nothing left to read it from.
func picture() -> Image:
	return null
