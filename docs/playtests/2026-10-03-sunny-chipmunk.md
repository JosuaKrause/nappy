# Playtest sunny-chipmunk — Mobile-ground review corrections and the player's clarifications

2026-10-03.

Context clarification by the assistant: "smeared loading" in snowy-ibis names
silky-rabbit's per-region ground-preparation stepping shipped in v0.21.5. Its
unquoted statements about unspecified device details and routing to M159 are the
assistant's analysis, not additional player observations. The player confirms
the earlier primary source's title and quoted words.

## Mobile-ground review posted by the player

Source: [PR #455 comment](https://github.com/JosuaKrause/nappy/pull/455#issuecomment-5964676726). The player posts the following review and answers;
quoted reviewer analysis is identified by its own headings, rather than attributed to the
player as firsthand gameplay observations.

> ## Review of PR #455 — Record mobile ground-loading feedback and the pending runtime choice
>
> Claude:
>
> **Verdict: not ready** at head a0f45926d61952f07ba2787f0c81192f3507d4d0. 2 blocking, 4 should-fix, 2 nits.
>
> (A nappy-codex-reviewer[bot] APPROVE already exists on this head and misses findings 1 and 2.)
>
> ### Blocking
>
> **1. A merged decision record is rewritten by a second PR**
> `docs/decisions/2026-10-02-silky-rabbit.md:123-126`, `:153-168`
>
> - docs/DECISIONS.md says each record is its own file "so … two pull requests never edit the same record", and "A record says what was true when it was written".
> - Narrowed text: the merged record said "Browser/phone perception and the full game's competing-work performance remain a human review item". It now says "remaining correctness checks", to match this PR's rewrite of the review item.
> - Added status paragraph: "The player has not selected an option. The runtime stays unchanged, and breezy-walrus … holds that decision." This turns false once breezy-walrus closes.
>
> Fix: revert both hunks. The snowy-ibis playtest and the breezy-walrus entry already carry this. The outcome goes in breezy-walrus's own record when it closes.
>
> **2. The player's way forward is handed to a `later`-band entry, with no link back**
> `docs/todo/2026-10-02-breezy-walrus/README.md:3-9, 20-22`; `choose-runtime.md:14-17`; record `:168`
>
> The player said "we will have to look in a different direction". The entry hands that to M159, "a slow frame names the frame that was slow". But:
>
> - `tools/queue.sh` prints `later 2026-09-19-M159`.
> - M159's phone item, "Profile the current phone build only after that baseline", waits behind the baked-pages measurement.
> - M159 is not edited to cite snowy-ibis.
> - The README paraphrases the report and never quotes that sentence.
>
> A playtest note is filed `now` unless the player names another band. As filed, the report's only forward instruction sits in `later` without the player being asked.
>
> Fix:
> - Quote the sentence in full in the README.
> - Add a snowy-ibis pointer to M159's phone-profiling item.
> - Ask the player whether M159, or that one item, moves to `now`. Until then, write "M159 covers it" only with the band it sits in.
>
> ### Should-fix
>
> **3. "make it optional and set the toggle to off" is ambiguous and was not read back**
> README `:16-22`, `choose-runtime.md:3-4`, record `:163-165`, playtest `:23`
>
> - The filing calls it a "default-off toggle", a "shipped default-off toggle" and a "default-off runtime fork", then argues against it as "two shipped paths to maintain".
> - The player's words fit three readings, each with a different maintenance cost: a setting players see, a `?debug=1` dev flag, or a `Tuning` constant.
> - playtest-feedback says an answer that can be read two ways is read back before filing.
>
> Fix: add "I read the toggle as X, not Y" and confirm it with the player.
>
> **4. The recommendation quotes only the smallest benefit**
> README `:16-19`, `choose-runtime.md:7-9`, record `:161-163`, playtest `:21-23`
>
> It cites "about 0.13ms", the 60Hz median. The tails are what stutter is made of. For ordinary south at 60Hz, the record's own table shows:
>
> | Measure | Before | After |
> |---|---|---|
> | p95 | 3.519–4.021ms | 2.849–3.073ms |
> | p99 | 4.627–5.274ms | 4.292–4.441ms |
> | worst sample | 8.710ms | 7.414ms |
>
> The record also says the 15Hz tails are mixed. The player chooses from this text, so it should show both what the change costs and what it buys.
>
> Fix: give the tail figures next to the median wherever 0.13ms is quoted.
>
> **5. The playtest file contains the filer's own analysis and routing**
> `docs/playtests/2026-10-02-snowy-ibis.md:16-18, 25-27`, title line 1
>
> Playtest files are primary sources and are never rewritten. Two passages read as the narrator's conclusions, not as anything said:
> - "This report does not identify a device … It does not claim that ground is uninvolved …"
> - "The runtime stays unchanged pending the player's choice. Further attribution belongs to the existing M159 … work."
>
> Fix:
> - Write them as "The assistant states …" if they were said in the conversation. Otherwise move them to the entry.
> - Define the player's labels where they are quoted: "smeared loading" is silky-rabbit's per-region stepping, shipped in v0.21.5; for "the toggle", see finding 3.
> - The title "does not visibly remove stutter" is stronger than the player's hedged "I can't say that the stuttering really went away". The commit's own word, "inconclusive", is closer.
>
> **6. The review-item rewrite narrows the item and overlaps M159's**
> `docs/review/2026-10-02-silky-rabbit.md:3-8, 14-15`
>
> - **Narrowed:** "in the browser **and** on the phone" becomes "browser **or** phone". Desktop-browser perception and the "complete-game judgment" are dropped. The player tested only "on mobile", and the PR description does not mention the drop.
> - **May be moot:** it asks for a playtest run on code that the open breezy-walrus entry may revert. Fix: say the item lapses if breezy-walrus restores atomic preparation, or hold it until the choice is made.
> - **Overlaps M159:** `docs/review/2026-09-19-M159.md` asks for nearly the same run: blank ground, water seams, a hitch as scenery comes into view, day transition, orientation, and whether these "feel smooth on these devices". This PR doesn't touch it. Fix: record snowy-ibis's partial answer there, and merge the two items or cross-reference them.
>
> ### Nits
>
> **7. Phone context is left out**
> README `:3-9`
>
> - PLAYTEST-140 records the player's phone as Chrome on a Pixel 8 Pro.
> - Its statement 3 says the stutter is steady: "it's pretty regular nothing stands out". A steady stutter isn't the burst on approach that stepping targets, which supports "look in a different direction".
>
> Cite it as context, without claiming it was this test's device.
>
> **8. Verbatim quote unconfirmed**
> The playtest wording reads like the player's, but it can't be checked against the source conversation. It doesn't appear in the PR #446/#452 threads.
>
> ### Checked and clean
>
> - **Three options:** they match the player's three questions (keep the findings and revert, keep the code, make it optional with the toggle off). The recommendation is under "Proposed, not asked for:". No runtime change is authorized.
> - **Nothing invented:**
>   - consistent with gray-stork and freckled-beaver;
>   - tag v0.21.5 points at 6006fa6, silky-rabbit's merge, published 2026-10-02;
>   - no device, browser, route or A/B comparison is claimed.
> - **Queue:** breezy-walrus is in `now`, with no `after:` lines, a heading in the sibling format, and it sits at the top of `now` in `tools/queue.sh`.
> - **Lint:** `./tools/lint.sh` passes at the head. Present tense holds, with no quest-log shapes.
> - **Classifier:** `tools/ci_classify.py` gives queue_only=false, docs_only=true. That is correct, because the record edit makes this a full review.
> - **CI:** test, gates, cost-table and classify are green. Shards and game are skipped, as expected for docs-only.
> - **Playtests:** no existing playtest file is modified.
> - **Current main:** merges cleanly with origin/main (b5dbf6c), with no overlap.
> - **Decision records:** `tools/decisions.sh` (stutter, ground preparation, toggle, smear, revert) finds no unnamed collision. The M159-4 nearby-residency record is correctly left out of the revert.
> - **Names:** American English throughout, and no character names in identifiers.
>
> Me: The quotes came from me in conversation and should be recorded properly

## The player's answers to the mobile-ground review

Source: [PR #455 comment](https://github.com/JosuaKrause/nappy/pull/455#issuecomment-5964967556). The player posts the following review and answers;
quoted reviewer analysis is identified by its own headings, rather than attributed to the
player as firsthand gameplay observations.

> ## PR #455 — review update (head a0f4592), the player's answers
>
> **Title confirmed:** "does not visibly remove stutter". The player: "I can confirm that statement even if it wasn't exactly what I said". It stays. Finding 5 no longer covers the title.
>
> **Nit 8 withdrawn:** the player confirms the snowy-ibis quote is verbatim.
>
> **Finding 2 resolved, and the entry's reading corrected.**
>
> The player on M159 and "a different direction":
>
> > "M159 we need to find more things to optimize so yeah it should go to now. but "we will have to look in a different direction" means we have to think about other ways -- that is orthogonal to when it happens."
>
> So:
> - M159 moves to `priority: now` in this PR, citing the player's words above.
> - "Look in a different direction" means "think about other ways to optimize". It is not a routing of the work to M159. The breezy-walrus README quotes the original sentence and this clarification, and no longer presents M159 as the answer to it. M159 is where the search for more optimizations happens; the new direction is still open.
>
> **Finding 3 resolved: the toggle is a dev flag.**
>
> The player:
>
> > "that is an option where we can still keep the code around and turn it on and off (eg via debug dev flag)"
>
> So:
> - The third option is "keep the stepped-loading code, off by default, switchable through a debug dev flag". It is not a player-facing setting.
> - The argument against it, "two shipped paths to maintain", is restated for a dev flag. Under **cli-tools**, the flag is declared in `src/dev/dev_flags.gd`, the one place the dev flags are declared, and documented there.
>
> **Recording:** the player's answers (title, M159, direction, toggle) go into a new playtest file, verbatim, dated 2026-10-03. snowy-ibis is not rewritten.
>
> Still open: finding 1 (blocking — revert the edits to the merged silky-rabbit record), findings 4, 5 (without the title), 6 and 7.
>
> **Verdict: not ready** at a0f4592.

## Further review and phone-profiling constraint

Source: [PR #455 comment](https://github.com/JosuaKrause/nappy/pull/455#issuecomment-5965391649).

Context: the review asks whether M159 can require CPU measurements on the phone.
It records the player's answer, "we *cannot* profile on the phone", within the full
review below. This is the available question context; no unrecorded question text is
invented.

> ## Review of PR 455 — Record mobile ground-loading feedback and the pending runtime choice
> Head: 8cb9d7b167e78e474417055d3e6828d89724518c · reviewed as a queue update (CI and
> tools/ci_classify.py call it queue-only: all 8 files are under docs/todo/, docs/review/ or
> docs/playtests/)
>
> Summary
> The earlier blocking finding is fixed: the merged silky-rabbit decision record ("nearby ground
> regions prepare across frames") is untouched; `git diff origin/main 8cb9d7b -- docs/decisions`
> is empty. Most of the player's two PR comments are carried faithfully:
>   - M159 is in `now`.
>   - "a different direction" is no longer routed to M159.
>   - The third option is a debug dev flag.
>   - The tail figures are given.
>   - Both comments are copied word for word.
> One problem blocks the merge. M159's phone item, which this PR moves to `now`, still asks for
> profiling on the phone, which the player says cannot be done. The PR also adds a sentence that
> reorders the item against its own heading. A few smaller faithfulness gaps remain.
>
> ── BLOCKING ─────────────────────────────────────────────────────────────
>
> 1. The M159 phone item asks for profiling on the phone, which the player says cannot be done
>    docs/todo/2026-09-19-M159/profile-the-current-phone-build-only.md:1-11, 16-17
>
>    - The player, 2026-10-03, in reply to this review: "we *cannot* profile on the phone".
>    - The item, already like this on main, asks for exactly that:
>        - heading (:1): "Profile the current phone build only after that baseline."
>        - body: "Divide CPU time between the baby's every-physics-tick crowd contribution
>          sweep, the halo's rendered-frame contribution sweep, event streaming/director work…"
>        - body: "Measure the conservative contribution rejection on that device", i.e. the
>          Pixel 8 Pro running Chrome (PLAYTEST-140).
>    - This PR moves M159 to `now` and leaves those instructions in place, so an agent briefed
>      from this file would set out to profile on a phone it cannot profile on.
>    - The PR adds at :16-17: "The baseline remains a comparison prerequisite, not a reason to
>      defer identifying candidate costs."
>        - That contradicts the heading's "only after that baseline".
>        - The player never reordered the items inside M159. Their answer moved only the entry's
>          band: "M159 we need to find more things to optimize so yeah it should go to now."
>        - The sentence is not marked as the filer's proposal.
>
>    Fix:
>    - File the player's sentence verbatim in sunny-chipmunk, the new playtest holding the
>      player's comments on this PR, after the question it answered.
>    - Rewrite the item so nothing asks for on-phone measurement. The phone stays the device
>      where the player judges stutter by eye. CPU attribution is done where it can be measured,
>      which the item names under "Proposed, not asked for:" (for example the web build profiled
>      in desktop Chrome with CPU throttling, and/or the native profile M159 already uses),
>      unless the player names the method.
>    - Delete the reordering sentence at :16-17, or mark it as a proposal.
>
> ── NON-BLOCKING ─────────────────────────────────────────────────────────
>
> 2. M159's README paraphrases the player's instruction instead of quoting it, and loses
>    "orthogonal to when it happens"
>    docs/todo/2026-09-19-M159/README.md:5-9
>
>    - The README says: "The player asks to put M159 in `now` to find more things to optimize,
>      while 'look in a different direction' means considering other approaches rather than
>      choosing one here."
>    - "Rather than choosing one here" is the filer's wording.
>    - The player's words were: "M159 we need to find more things to optimize so yeah it should
>      go to now. but 'we will have to look in a different direction' means we have to think
>      about other ways -- that is orthogonal to when it happens."
>    - breezy-walrus (choose ground preparation after the mobile test) already quotes this
>      verbatim at README.md:11-14.
>
>    Fix: quote the player's sentence verbatim in M159's README.
>
> 3. The silky-rabbit review item has no case for the dev-flag option, and it drops the
>    atomic-vs-stepped comparison
>    docs/review/2026-10-02-silky-rabbit.md:3-8
>
>    - The item branches two ways: "It lapses if that choice restores atomic preparation" and
>      "If stepping is retained, …".
>    - The player's third option ("keep the code around and turn it on and off (eg via debug dev
>      flag)") restores atomic preparation by default and also keeps stepping. It matches both
>      branches, so whether the item lapses is unclear.
>    - The rewrite deletes main's line 14: "A useful comparison uses the same route and settings
>      in the atomic and stepped builds". That is the comparison a dev flag makes cheap, and
>      snowy-ibis (mobile ground stepping does not visibly remove stutter) notes there was no
>      "controlled atomic versus stepped comparison".
>    - The PR description does not mention dropping it.
>
>    Fix: say what happens to the item under the dev-flag option, and restore the comparison
>    sentence for the branches where stepping survives.
>
> 4. The recommendation gives the benefits as figures but the costs only as words
>    docs/todo/2026-10-02-breezy-walrus/README.md:27-38
>
>    - The benefits carry median, p95, p99 and worst-sample ranges.
>    - The costs say only "the added drawing/allocation costs and pending-job lifecycle".
>    - The silky-rabbit record (docs/decisions/2026-10-02-silky-rabbit.md:92-95) has the cost
>      figures:
>        - draw calls 38 → 46
>        - water surfaces 6 → 24
>        - about 61% more allocation
>        - steady median 0.792–0.814 ms → 0.818–0.842 ms
>    - The recommendation (revert) rests on those costs, and the player chooses from this text.
>
>    Fix: put the four cost figures next to the benefits.
>
> ── NITS ─────────────────────────────────────────────────────────────────
>
> 5. docs/playtests/2026-10-03-sunny-chipmunk.md:8-9
>    "The current queue holds that analysis and the player's clarification below" is already
>    partly false: the player corrected the routing to M159, and the queue no longer holds it.
>    It is also a status sentence in a primary source, which is never rewritten after merge.
>    Fix: drop it, or say only that the analysis is the assistant's, not the player's.
>
> 6. Small dropped specifics and wording
>    - docs/todo/2026-10-02-breezy-walrus/README.md:5-7 drops the player's own assessment of the
>      keep-the-code option, "(it does improve a little bit on paper)". It belongs next to that
>      option.
>    - sunny-chipmunk.md:12 and :130 share the heading "Mobile-ground review posted by the
>      player". The second section is the player's answers, and should say so.
>
> ── CHECKED AND CLEAN ────────────────────────────────────────────────────
>
> - No decision record changed: the silky-rabbit record is byte-identical to main, snowy-ibis is
>   unchanged since a0f4592, and no existing playtest was modified.
> - Both player comments (5964676726, 5964967556) match sunny-chipmunk's blockquotes byte for
>   byte, nested quotes included.
> - The player's answers are applied:
>     - M159 is in `now`.
>     - breezy-walrus quotes the "different direction" clarification in full.
>     - Option 3 is off by default behind a debug dev flag declared in src/dev/dev_flags.gd, the
>       one place dev flags are declared.
>     - PLAYTEST-140 (Chrome on a Pixel 8 Pro, steady stutter) is cited as context only.
> - The benefit figures match the record's table (lines 61-64, and "15Hz tails are mixed" at 66).
> - Restoring atomic preparation is marked "Proposed, not asked for:". No runtime choice is
>   inferred: "They have not selected one of those options."
> - Bands (tools/queue.sh): breezy-walrus is at the top of `now` and M159 is in `now`; `--check`
>   passes.
> - tools/decisions.sh (atomic, dev flag, different direction, smeared) finds only silky-rabbit
>   and M159-4 (nearby scenery residency); neither is overturned.
> - Lint and whitespace: ./tools/lint.sh passes and `git diff --check` is clean.
> - CI on 8cb9d7b: test, gates, classify and cost-table are green; game and shards are skipped
>   (docs only); the queue-update gates ran and passed.
> - Existing reviews:
>     - nappy-codex-reviewer's APPROVE at 8cb9d7b rests on its full review at 095f902, which
>       missed finding 1 (its reordering sentence was already in that diff) and findings 2-4.
>     - The player's CHANGES_REQUESTED at a0f4592 is outdated.
>     - The one inline thread (whitespace) is resolved.
>
> Verdict: NOT READY — 8cb9d7b167e78e474417055d3e6828d89724518c
> Finding 1 must be fixed before merge; findings 2-4 should go in the same push.

## Qualification about finding a phone-profiling method

Source: [PR #455 comment](https://github.com/JosuaKrause/nappy/pull/455#issuecomment-5965393255).

After the review identifies phone profiling as unavailable, the player adds:

> unless you can come up with a way to profile on a phone

## Phone profiling is optional

Said in conversation, 2026-10-03, not in a PR comment. The proposal it answers: keep USB
remote debugging of the phone's Chrome tab from a computer as an optional way to profile on
the phone; and a review finding that the baked-pages baseline item still required phone
timings. The player says:

> phone profiling would be a nice to have but honestly a quick eye test is good enough. although it doesn't actually tell us how we could improve things and what the exact bottlenecks are -- let's record the ideas here -- maybe we will do them

## The live readout as a phone method, and the dev flag on a release page

Said in conversation, 2026-10-03, while the orchestrating session fixed this PR against the
player's review. It had asked whether the released page's own readout (`?debug=1` for fps, draw
calls and process and physics milliseconds; `&skip=<word>` to subtract one system), with which M124
and M139 measured the phone, should join the recorded phone methods. The player says:

> add the screenshot way as alternative for phone testing but it's not a complete benchmark it's a hack

It had also said that a dev flag cannot be switched on the phone's released page, and asked
whether the stepping flag should say it works in debug builds only or join what `?debug=1` opens
on a release page. The player says:

> no debug already works on real release builds -- I can do debug=1&day=7 and start at day 7
