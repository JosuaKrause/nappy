# plush-kestrel — Code is designed by layer: the player's principles written into orchestrating and pr-review · 2026-10-18 · not from an entry


The player, after the codebase review was filed as minty-quail: "also make it so the software
principles are going to be mentioned in a code writing / designing rule(?) whereever it makes most
sense" (minty-lemur #796). The principles are the player's: "separation of concerns, composability,
cohesion, coupling, architecture layering" and "use dependency injection to allow for more modular and
testable code" (minty-lemur #785, #794), with "there really should be no separate code for escape" and
"all should be implemented through the regular game engine's means" (minty-lemur #785).

**Built (PR #795).** **orchestrating** gains "Code is designed by layer". That skill is loaded at
every session's start and before every edit under `src/` and `tests/`, so the rule reaches both
designing and writing code; a separate design skill would have needed its own path mapping in the
rules hook and the Codex adapter for the same reach. **pr-review**'s code checks name the rule, the
agent contract every brief points at asks agents to follow it and report the layer, and a brief's
checklist lists the layer.

**What is the player's and what is the filer's.** The five principles, dependency injection, the
direction of dependencies and a mode as configuration rest on the player's words. The six target
layers (minty-quail's), the fix landing in the shared mechanism, new code following the target shape
until minty-quail lands, and the brief naming its layer are the filer's proposal, marked so in the
skill and open to overturn. The one stated exception is a minimal fix the queue orders before the
refactor, as downy-tapir's `winnable-escape.md` is.
