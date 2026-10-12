# Playtest minty-marmot — GoatCounter counts by release

2026-10-11.
Said in a session as one note the assistant captured into the inbox on GitHub Issues, #706, and
answered there. The note is recorded as it holds: first what its words answered, then the words
themselves, whole, and the later words after what they answer. The questions and context are the
assistant's; only the quoted lines are the player's.

## #706

1. **What the note answered** (the assistant):

   Said mid-session while the agent filed velvet-marten (PR #702) and two M159/bouncy-swan fixes ran. `tools/goatcounter.sh` is the only way the repository reads GoatCounter: it prints the `nappy-` event counts as a per-day funnel, or per event type with `--encounters`. The events the page sends (`VisitCounter`, `src/autoload/visit_counter.gd`) carry no build version, so a release can only be matched to the counts by date today.

2. **The note.**

   > when analyzing goatcounter stats can we build tooling to correlate it with releases?

3. **The assistant asked:**

   Asked: (A) `tools/goatcounter.sh --by-release` reads the release tags' dates from git and groups the daily counts into one window per release, marking a day with two releases as mixed rather than splitting it; tooling only, nothing changes in the game; exact for single-release days, blurred on the others (recommended first). Or (B) the page reports its version with each event (or once per visit) so counts split exactly; it changes what the page sends to GoatCounter and the telemetry docs, and only counts from releases after the change can be split.

4. **The player's words, answering it:**

   > A is the right choice. mixing releases is fine. in the future we will have slower release cadence

## Filed as

- **#706**: [spotted-badger](../todo/2026-10-11-spotted-badger/README.md), GoatCounter counts grouped
  by release.
