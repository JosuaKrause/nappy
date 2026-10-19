priority: now

# downy-tapir — The escape playable again, and a patch release · filed 2026-10-18


The first work of the next session, before the refactor (minty-quail, one engine), in the player's
order: "for immediate next step: check the bug and also make escape winnable with minimal changes
(fixing event distribution in some cheap way) then patch release then full refactor"
(minty-lemur #794). One PR each, in that order: `winnable-escape.md`, then `patch-release.md`.

**Read as:** "the bug" is the one the codebase review (minty-quail) found by reading and flagged as
possibly live in v0.29.0, the baby reading the building's world in the escape city; "minimal
changes" means no restructuring, which minty-quail does properly afterwards.
