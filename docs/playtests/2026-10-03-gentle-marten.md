# Playtest gentle-marten — Scene-builder review clarifications and screenshot scope

2026-10-03.

## Implementation and capture instructions in conversation

After the design PR and discussion of saved recipes, the player authorizes implementation:

> start implementing in a new PR built on top of 456

They add concurrent review work:

> in parallel address comments on 453 455 456

For the trailer-scene deliverables, the player specifies:

> take screenshots of the scenes that you create for the trailer -- not videos

> I only care about the scenes for now -- not making them into a video

> and create the scenes how I described them -- not what was actually used in the first attempt

After the assistant asks for the missing original findings on #456, the player replies:

> I forgot to post it earlier -- I created a clean version without references now

The clean review is quoted below. The player subsequently adds capture timing requirements:

> if you update the trailer rig make it so the recording can start some time after the movement starts

> very rarely do we want to make a video that starts from a rest position

> everything should already be in movement when the video starts

The assistant proposes independently configurable capture start after the whole scene
begins moving. The player confirms adjustability:

> yeah, it should be a time that can be set

> so it can be adjusted

## Scene-builder review posted by the player

Source: [PR #456 comment](https://github.com/JosuaKrause/nappy/pull/456#issuecomment-5964971807). The player posts the following review and answers;
quoted reviewer analysis is identified by its own headings, rather than attributed to the
player as firsthand gameplay observations.

> ## Review of PR #456 — Specify saved scene recipes for exact tests and trailer shots
>
> **Verdict: not ready** at head 410ef017cdfc76bc3fb4e8253446522ab47418b4. 0 blocking, 8 should-fix, 7 nits.
>
> The five playtest files quote the player verbatim (confirmed by the player). Paths are under `docs/todo/2026-10-02-round-ferret/` unless given in full.
>
> ### Should-fix
>
> **1. Takes over M204's open trailer fixes without saying so**
> `trailer-recipes.md:29-30`, `examples-and-verification.md:53-55`, `README.md:66-67`
>
> - Three passages make these fixes round-ferret's work:
>   - the missing truck;
>   - the mother who doesn't visibly run;
>   - the render that isn't reproducible under load.
> - M204's `cut-under-30s.md` already owns all three. M204 is untouched (`later`, no `after:`).
> - round-ferret's completion becomes gated on M204's open determinism bugs:
>   - `--spawn arterial` non-determinism is "not root-caused";
>   - the `--start-escape` + `--walk` hang is "not investigated".
> - The player's only words on the first render: "the trailer needs some work. I will give more details later" (PLAYTEST-139, statement 12).
>
> Fix: either leave the fixes in M204, or edit M204 to say what moved, add an `after:` line, and mark the move as the filer's proposal. Either way, load reproducibility is not a completion criterion here.
>
> **2. Too large for one branch and one PR**
>
> - The entry is about 3,557 words across 6 files. The next largest open entries, M100 and leafy-finch, are about 1,700.
> - The player's first ask, the building next to the power plant, can't ship on its own: the README needs all five items done.
>
> Fix: split into entries chained with `after:`:
> - (a) recipe builder + power-plant join + headless test;
> - (b) the trailer recipes + recording;
> - (c) free play and extent.
>
> **3. The validity rule is broader than the player's**
> `README.md:19-21`, `recipe-construction.md:32-42`, `examples-and-verification.md:26-29`
>
> The entry requires every normal recipe to establish that its arrangement "could actually occur under the game's generation and placement rules". The player's rule (2026-10-03) is narrower:
>
> > "it really depends -- if there is an easy check -- refuse and require an explicit allow (for eg tests and edge cases) -- if there is not an easy way to check it doesn't matter -- the rule is more for things that already are explicitly verified during city creation"
>
> Fix:
> - A recipe is refused only when it breaks a check that city creation already runs explicitly. The refusal is overridden by an explicit allow, for tests and edge cases.
> - Where no easy check exists, nothing is required.
> - Reusing the generator's existing checks remains the means.
> - The fixture contract (named expected violations; trailer tools refuse fixtures) becomes this explicit allow. It stays under "Proposed, not asked for:" where it goes beyond it.
>
> **4. The fenced-yard variant may not be producible**
> `README.md:36-39`, `examples-and-verification.md:26-29`
>
> - The player confirms the case is M203's roof and facade handling: "yes, it's still the roof and facade case".
> - M203 says the yard guard "has no picture because no seed tried has a column it applies to".
>
> Fix: the yard variant passes if it breaks no check that city creation runs (finding 3). Otherwise it carries an explicit allow. Say which, and cite M203's note.
>
> **5. Free play is framed as the filer's, not the player's**
> `free-play-and-extent.md:3-7, 12-15`, `examples-and-verification.md:41`
>
> - The player's words (2026-10-03): "like with the normal game it should be possible to use scripted movements or just load in and control like the normal game". It applies to every recipe: "why would it only apply to trailer scenes?"
> - The entry already scopes it to every recipe; keep that.
> - Its framing as "select free play or scripted playback when launching it", with restarting restoring the setup, is the filer's.
>
> Fix: quote the player's sentence. Describe the modes as the normal game's: scripted movement, or load in and take the controls. Mark launch selection and restart behavior as proposals, or drop them.
>
> **6. Other mechanisms not marked as proposals**
> `recipe-construction.md:20-30`, `runtime-and-replay.md:19-25`
>
> The PR description says named anchors are marked, but they sit outside both "Proposed, not asked for:" paragraphs. Also unmarked:
> - independent deterministic seed streams;
> - the list of what a recipe controls (progression, meter state, ambient population with a deterministic default).
>
> Fix: mark them, or add them to the proposal list at `README.md:41`.
>
> **7. mossy-swan doesn't say what the player was answering**
> `docs/playtests/2026-10-02-mossy-swan.md:5-8`
>
> The file doesn't record what the assistant had proposed as "scripted movements" or as the "planned" extent. Playtest files can't be edited after merge.
>
> Fix: before merge, add the assistant's proposal before the quote.
>
> **8. Trailer specifics changed or dropped**
> `trailer-recipes.md:14-20, 32`, README
>
> - **Zoom:** PLAYTEST-139 says "a zoom out from her doorstep"; the entry says "the parent's doorstep". Fix: say "her doorstep".
> - **Route choice:** "the obstacle and alternative must be legible", but the player said "going down the wrong path then turning around and going another", and no obstacle appears. Fix: use the player's wording.
> - **Opening shot:** "The opening shows a route choice" follows M204's shot order, not PLAYTEST-139. Fix: cite M204.
> - **Encounters:** "construct the desired encounters directly" leaves "desired" undefined. The player only said "mostly focus on early dangers, up to say the charging dog". Fix: leave the choice open, or ask.
>
> ### Recording
>
> The player's answers of 2026-10-03 go into a new playtest file, verbatim; the existing five files are not rewritten. They are:
> - the roof and facade confirmation;
> - the validity rule;
> - free play, and its scope over every recipe.
>
> ### Nits
>
> 9. The optional crossing example (`examples-and-verification.md:15-16`) brings back something the player steered away from. The assistant proposed crossing, pursuit and truck examples; the player answered "in addition to the power plant test create scenes as described for the trailer". Drop it or ask.
> 10. "Saved recipes first" leaves a visual editor open for later. Say so in one line.
> 11. Free play beyond the extent (`free-play-and-extent.md:17-31`) collides with M120, the map edge, which clamps `City.camera_bounds()` to the painted band. Name M120 and say recipes need a different camera bound.
> 12. References the reader can't follow:
>     - "the existing escape logic and recorded scene contracts" (`runtime-and-replay.md:30-31`);
>     - "the project's established review format", "the existing repeated-render machinery", and "existing rules for retained capture evidence…" (`examples-and-verification.md`);
>     - PLAYTEST-139 linked without a title.
> 13. "Power plant", "power station" and "power-station" are mixed. Pick one.
> 14. Narration inside playtest files:
>     - minty-wombat:5-7, "This is an assistant-added proposal…";
>     - brisk-ibis:5-9, "asks for" overstates "create scenes as described for the trailer".
>     Drop it or label it as the assistant's.
> 15. `README.md:13-14`, "…is the test use to build first": "first" was the assistant's ordering, not the player's.
>
> ### Checked and clean
>
> **Playtest files**
> - All five are dated 2026-10-02, with the player's quotes marked.
> - gray-otter's option labels are recorded ("Saved recipes first" / "Visual editor first" / "Both together").
> - No band or routing is presented as source.
>
> **Quotes from earlier files** (match origin/main)
> - The PLAYTEST-139 "pre determined seeds with fixed events" quote is exact.
> - The M203 quote is exact.
> - The frosty-finch quote is exact.
> - PLAYTEST-139 statements 2-8 are carried faithfully apart from finding 8: 1s segments, at most 30s, mother/father/mother, fades to black, later-day spoilers only, on-screen text, resolution and audio.
>
> **Code claims hold at head**
> - `CityGenerator.generate()` loops `_attempt(seed_value + attempt)`.
> - `--spawn power_station` finds an existing power station rather than requiring one.
> - `City._assign_roof_extensions` skips the yard via `_hall_cols()`.
>
> **Mechanics**
> - `./tools/lint.sh` passes.
> - `tools/ci_classify.py` reports queue_only.
> - `tools/ci_queue_update.py` reports all mechanical checks passed.
> - `tools/queue.sh` lists round-ferret in `next`, matching the PR description. The band is the filer's choice and is marked as a proposal.
> - CI status on the head was not checked from the review checkout.
>
> **Style**
> - Present tense throughout, and no quest log.
> - No character names in identifiers.
> - No British spellings in new names.
>
> **Collisions:** `tools/decisions.sh` finds none beyond M120 (nit 11) and M204 (finding 1).
>
> Fix findings 1-8, and the mossy-swan file in particular, before merge, since playtest files are fixed once merged.
