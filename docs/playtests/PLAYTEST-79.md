# Playtest 79 — The father's B-frame contact

**Date:** 2026-09-19

## What was checked

The new male protagonist family from M157 was reviewed in its comparison graphics.

## What the player said

> "male graphics looks good."

On looking at the directional pushing cycle more closely:

> "actually now that I look again the B frames going north, east, south east, south, south west,
> and west show the wrong leg in front. the other two directions are correct"

The correction belongs on its own pull request because the original male-player work has already
merged:

> "you will need a new PR for this"

## What this settles

The father's identity, blue overshirt and illustration style are accepted. The B contact is not:
north, east, southeast, south, southwest and west put the wrong leg forward. Northeast and
northwest are the correct reference. Those six runtime directions come from four authored pushing
sources: back, side (also mirrored), front diagonal (also mirrored) and front. The authored back
diagonal B source used by northeast and northwest remains unchanged.

