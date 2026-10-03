# Playtest sunny-chipmunk — Mobile-ground review corrections and the player's clarifications

2026-10-03.

Context clarification by the assistant: "smeared loading" in snowy-ibis names
silky-rabbit's per-region ground-preparation stepping shipped in v0.21.5. Its
unquoted statements about unspecified device details and routing to M159 are the
assistant's analysis, not additional player observations. The current queue holds
that analysis and the player's clarification below. The earlier primary source
is preserved as requested; the player confirms its title and quoted words.

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

## Mobile-ground review posted by the player

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
