## Graphics redesign — 2026-09-05

The player requested a whole-game overhaul and explicitly rejected the first implementation's
SVG outline and polish approach: "a full overhaul of the graphics as if nothing had existed
before". The correction includes animation, every screen, projecting roof depth with stylized
occlusion reveal, actual excitement-source feedback, late-game deterioration and reconsidered
objective guidance. Full wording is in `PLAYTEST-30.md`; `PLAYTEST-25.md` is reserved for the
separate mobile playtest on the other development branch.

The player approved the standalone cardinal apartment-street review with "looks good continue".
The accepted gate is the illustrated PNG ground, continuous apartment frontage, roof depth and
stable dotted occlusion; binding it to the live player is the next implementation slice. Approval
does not turn the review scene into a completed overhaul or approve the still-open presentation
families.

The initial SVG polish is preserved in a local stash and isolated worktrees, not adopted as the
new art direction. The prior keep-every-roof-inside-its-lot restriction and SVG-only assumption are
open to replacement under the player's explicit instruction to rethink graphics and challenge
earlier guidelines. Collision and route guarantees still describe gameplay and are not repealed
by an artistic roof projection.

`VISUALS.md` specifies the redesign from the player's supplied urban, cardinal-layout and mother
references. The first implementation experiment uses native orthographic 3D and articulated models
with Godot's Compatibility renderer. Native 3D must pass a rendered movement and browser-cost
review before it defines the production pipeline; rendered PNG animation atlases from the same
models are the fallback worth measuring. Blender is absent on this machine and is not installed by
the experiment.

The requested main update brought in the release-tag pinning fix. The separate branches for the
mobile playtest and event costs also contain relevant title/control and field instructions, so
the new presentation must coordinate with them rather than overwrite them.

**This file is the history. Nothing in it describes the game as it is now.**

Every other document in this repo states the current state and only the current state. When one of
them needs to say *why* something is the way it is, or *what was tried and rejected*, or *what a
number used to be*, the answer lives here and is fetched on demand. That split is the whole point:
a reader of `CLAUDE.md` or `docs/CITY.md` should never have to work out which sentences are still
true.

**How to use it.** Search for the symbol, the constant or the noun — `PURSUIT_SHAKEN_OFF`,
`absent_segments`, "flock", "corridor". Every fact lifted out of a docstring during the timeless
restyle is findable here by the name it was attached to. If it is not, that is a bug in this file.

**What belongs here**, and each entry is dated and names the milestone and the playtest that
produced it:

- **Decisions taken** — with the options that were rejected, and why. A rejected option with its
  reasoning attached is a decision somebody can overturn; a deleted one is not.
- **Ideas rejected outright** — the same thing for proposals that never became a decision.
- **Changes that happened** — with the measurement that justified them, so a later session can tell
  whether the measurement still holds.

**What does not belong here.** Anything that is currently true. If a sentence in this file describes
how the game works today, it is in the wrong file and belongs in the design doc it is about.

**The playtest files are not absorbed into this one.** `docs/playtests/PLAYTEST-NN.md` are primary sources — a
player's own words on a date — and this file cites them rather than restating them.
