# Playtest pebbly-bison — Scene review context and bounded extent

2026-10-03.

The player asks: "have a look at the last comment of 456 even though it got merged".
The following review supplies the context. Its confirmation of the player's words
"scenes are not complete cities" applies to bounded scenes' unbuilt surroundings.

Source: https://github.com/JosuaKrause/nappy/pull/456#issuecomment-5965449418

> ## Review of PR 456 — Specify saved scene recipes for exact tests and trailer shots
> Head: 9417f28aab0cf426e94b6751caeced63ff8452bd · queue update (all 14 files under docs/todo/ or
> docs/playtests/; ci_classify calls it queue-only)
>
> Summary
> The player's 2026-10-03 review, quoted in gentle-marten, is addressed:
>   - Three chained entries:
>       - round-ferret: the recipe builder, the power-station join, headless checks
>       - calm-stork: the PLAYTEST-139 trailer scenes, as screenshots
>       - velvet-hare: ordinary controls and bounded ground for every recipe
>   - All six scenes are there in the player's terms: wrong-way turnaround, early dangers through
>     the charging dog, trucks beside the mother, the father walking toward the gatehouse, the
>     mother running with the baby from guards, the zoom out from her doorstep.
>   - Screenshots, not video, with an adjustable capture time.
>   - The validity rule matches the player's. Existing creation checks on what a scene builds need
>     an explicit allow to fail (for example a courtyard placed inside the power plant), and a
>     bounded scene's unbuilt surroundings are exempt (recipe-construction.md:18-19,
>     free-play-and-extent.md:30-32). The player confirmed this reading on 2026-10-03: "scenes are
>     not complete cities".
>   - Proposed mechanisms are labelled, M120 (the map edge) is named, and the original quotes are
>     unchanged.
> Nothing blocks the merge. The items below are worth one follow-up push, ideally before
> gentle-marten and mossy-swan become immutable.
>
> ── NON-BLOCKING ─────────────────────────────────────────────────────────
>
> 1. gentle-marten files the player's 2026-10-03 answers without the questions they answered
>    docs/playtests/2026-10-03-gentle-marten.md:84-86, 97, 105
>
>    - The answers:
>        - "it really depends -- …"
>        - "yes, it's still the roof and facade case"
>        - "like with the normal game it should be possible to use scripted movements or just load
>          in and control like the normal game"
>        - "why would it only apply to trailer scenes?"
>    - They appear only nested inside the quoted review, framed by the reviewer's paraphrase.
>    - playtest-feedback wants words said in conversation "recorded with what they answered", and
>      round-ferret and velvet-hare cite these answers.
>
>    Fix: a short section, "The answers of 2026-10-03", with each answer after the question or
>    proposal it answered; where the question was not kept, say so.
>
> 2. calm-stork needs a still of the escape, and the screenshot hang that blocks it has no owner
>    calm-stork/trailer-recipes.md:14-18, :36-38 · calm-stork/README.md:20-23
>
>    - M204's cut-under-30s.md:18-20: "tools/shot.sh --screenshot seems to hang on --start-escape
>      together with --walk or --after … not investigated."
>    - calm-stork asks for exactly that still: "the mother visibly running carrying the baby while
>      guards pursue", with movement already under way.
>    - calm-stork leaves to M204 only "missing-truck, nonrunning-mother and loaded-render bugs",
>      so nobody owns the hang.
>
>    Fix: calm-stork takes it over (marked as a proposal), or names the capture path its escape
>    still uses instead.
>
> 3. M204 (the trailer cut) does not point to calm-stork
>    M204 is unchanged by this PR
>
>    - calm-stork builds the trucks, gatehouse and chase shots M204's cut needs.
>    - M204 still describes the missing truck as a `--spawn arterial` non-determinism to fix in
>      tools/trailer/shots.json.
>
>    Fix: one line in M204's README, marked "Proposed, not asked for:", saying its shots can come
>    from calm-stork's recipes once they are built.
>
> 4. mossy-swan's framing claims more than the quote
>    docs/playtests/2026-10-02-mossy-swan.md:5-8
>
>    The framing says the player "introduces … a planned extent". The player said "the extend that
>    was planned for", which refers to an extent already planned.
>
>    Fix: drop "introduces", or say what had been planned.
>
> 5. calm-stork reads "randomly alternate" one specific way without marking it
>    calm-stork/trailer-recipes.md:22-24
>
>    - The player: "shots should randomly alternate between man/woman"; statement 8 records it as
>      "chosen at random but fixed".
>    - The entry writes "alternate parents with a randomized initial choice", which is strict
>      alternation from a random start rather than a random but fixed choice per shot.
>
>    Fix: quote statement 8 and leave the per-shot assignment to M204, or mark the reading as the
>    filer's.
>
> ── NITS ─────────────────────────────────────────────────────────────────
>
> - calm-stork/trailer-recipes.md:32 says "the existing per-shot trim/start control". Name it: the
>   `in` field in tools/trailer/shots.json, the number of seconds into a shot's frames where
>   tools/trailer.sh starts the cut.
> - round-ferret/runtime-and-replay.md:13 says "existing optional walking/input and camera rigs".
>   Name the flags: --walk, --press, --zoom-out.
> - round-ferret/README.md:22-23, :29-30 and calm-stork/README.md:18 ("following the review's
>   requested split") are status lines that go stale once PR 457 merges. Drop them, or link
>   gentle-marten.
> - round-ferret/examples-and-verification.md:8 is labelled "Proposed coverage:". The required
>   label is "Proposed, not asked for:".
> - velvet-hare/free-play-and-extent.md:13-14, :20-23 ask for "no invisible wall" but name only
>   M120's camera clamp. City._spawn_boundary() also builds walls just outside the map. Name it.
>
> ── CHECKED ──────────────────────────────────────────────────────────────
>
> - Player quotes:
>     - All six playtests and PLAYTEST-139 read in full.
>     - Quotes are unchanged across all six commits; only the assistant's framing changed.
>     - gentle-marten's quoted review matches GitHub comment 5964971807 byte for byte.
> - The six scenes, "her doorstep", screenshots not video, and the capture-time wording are
>   carried.
> - M203 (roofs covering adjoining facades): both quotes are exact, and the yard caveat is
>   carried.
> - Code claims: M120's City.camera_bounds() claim holds, and FinaleController and FinalePlanner
>   exist.
> - Bands (tools/queue.sh): all three entries are in `next`, chained by `after:`, and marked as
>   proposals.
> - Mechanical: tools/lint.sh, tools/ci_classify.py and tools/ci_queue_update.py --pr 456 pass.
> - CI at 9417f28 is green.
> - The base is current main, so there are no conflicts.
>
> Verdict: READY — 9417f28aab0cf426e94b6751caeced63ff8452bd
> (Findings 1 and 4 touch playtest files, which are fixed after merge. Do them first if wanted.)

## The answers of 2026-10-03

The original questions for these four answers are not retained in the available
conversation. The proposal contexts below come from the quoted review, not recovered
verbatim questions.

On a proposed requirement that normal recipes prove realizability:

> it really depends -- if there is an easy check -- refuse and require an explicit allow (for eg tests and edge cases) -- if there is not an easy way to check it doesn't matter -- the rule is more for things that already are explicitly verified during city creation

On whether the power-station example concerns M203's roof/facade handling:

> yes, it's still the roof and facade case

On the scene's control modes:

> like with the normal game it should be possible to use scripted movements or just load in and control like the normal game

On a proposed restriction of these modes to trailer scenes:

> why would it only apply to trailer scenes?

## Source framing

The merged mossy-swan framing says the player introduces a planned extent. Their
actual quote refers to "the extend that was planned for"; the earlier plan's exact
context is not retained here. It permits that extent rather than introducing one.

PLAYTEST-139 statement 8 says:

> **The other shots alternate between the mother and the father**, chosen at random but fixed,

That source does not require strict alternation from a randomized initial parent.
The specific later-day glimpses retain their explicit mother/father/mother assignments.
