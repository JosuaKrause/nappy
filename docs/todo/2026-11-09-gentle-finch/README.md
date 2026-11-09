priority: later
after: 2026-10-18-minty-quail

# gentle-finch — The caret, the home arrow and the edge badge's pointer become picture files · filed 2026-11-09

**The ask.** The player's rule is that a picture is an image file, never assembled from draw calls
(PLAYTEST-29 3). A review of the rule files found three symbols that are drawn in code all the
same, and the danger-cue skill calling one of them an exemption. Asked on the board whether the
three stay drawn in code or become picture files like every other symbol, the player: "yes we
would want to move to pictures only eventually. That will allow us to experiment with variations.
So make todos for them but not part of the refactor" (inbox #1278).

**Read as:** each of the three becomes an image file under `art/`, drawn as every other symbol is,
so a variation is a new picture and not a change to drawing code. It waits for the refactor
(minty-quail, one engine: the codebase refactored by layer) and is no part of it.

*Proposed, not asked for* (the filer's): the band `later`, from "eventually"; one item per symbol,
so each can be tried and judged alone; and the edge badge's backing disc and coloured rim, which
are drawn in code beside its pointer, going with the pointer's item.

**What each picture has to keep.** The three are drawn in code today because something about them
changes while they are on screen: the caret's width breathes with what the entity is costing her
and its colour says amber or red; the arrows turn to point at their target; the badge's pointer
turns to where the danger is. Each item says how a picture carries that (a tint, a rotation, a
scale, or a small set of pictures), and the danger-cue skill's rules hold for the result (**cues**).

**Items:** `caret.md`, `home-and-task-arrow.md`, `edge-badge-pointer.md`.
