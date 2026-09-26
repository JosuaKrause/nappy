# Playtest 145 — Measure the work in a crowded scene

2026-09-26. Reported in conversation about the current mobile build.

## What the player said

> "can you investigate what the bottleneck is when a lot of entities are on screen? I think that is what makes the current mobile version stutter"

Asked which phone/browser and location reproduce it:

> "just find a crowded place with lots of entities / cars / people. it doesn't need to also stutter on the desktop. just measure what the contributions are each frame"

## Scope

This continues M159, a slow frame names the frame that was slow: measure subsystem time in a
crowded scene on the available desktop. Desktop stutter reproduction and phone access are not
prerequisites. The suspected link to current mobile stutter remains a hypothesis.

## Follow-up instructions

> "hold off on measurements right now"

> "can you write the plan down for now so you can continue later?"
