# Playtest quiet-wombat — Fix trailer startup camera before further editing

2026-10-07.

## #608 — Fix the startup camera before improving trailer 580

The player directs the next work on the open trailer PR #580:

> regrding 580. we need to fix the camera bug at start before we can keep improving the trailer

The assistant says it will make the camera bug the first task and inspect the existing branch.
The player clarifies the symptom and the intended recording boundary:

> by camera bug I mean that the camera starts at 0x0 and races towards the player instead of starting at the player. if it started at the player we could start recording each scene a little bit earlier (still not at 0 since we want to see movement)

Captured in [issue #608](https://github.com/JosuaKrause/nappy/issues/608). This is a correction
within M204, the trailer from saved scenes, in PR #580. It precedes further editorial changes.
