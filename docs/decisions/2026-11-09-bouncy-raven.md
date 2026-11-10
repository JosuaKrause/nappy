# bouncy-raven — The process skills after the rules review: one owner per rule, the board read on a heads-up, detail in reference files · 2026-11-09 · not from an entry

**The ask.** The player had a review made of every rule file ("have another fable agent review all
skills/claude/rule files", inbox #1267 in olive-ferret), read its summary, and said "let's do all the suggested
changes for the hooks/skills/claudes etc", "four PRs is fine with me -- can we parallelize?" and
"for the rule/skill/claude changes I want fable to do it directly" (inbox #1267 in olive-ferret). The work was split
by files into four pull requests. This record is the one for the twelve skills about how the work is
done: pr-review, inbox, session-cleanup, board, merging-main, playtest-feedback, verify,
writing-tests, designing-classes, python-tooling, cli-tools and review-answers.

## What the review found in these skills

- **The board was read "on every turn"**, citing a note in which that phrase is the assistant's own
  description; the player's words there are that a heads-up to check the doc means it need not be
  polled (inbox #830 in minty-dolphin).
- **The same rule in several skills:** which GitHub identity writes what was restated in pr-review,
  inbox and session-cleanup beside its owner, committing; what the test-only-members check does was
  restated in writing-tests and pr-review beside the tool's own help.
- **Two answers to which model reviews:** pr-review sent a change to the rules to a stronger
  model, where the orchestrating skill's model table sends a skill's wording to Sonnet.
- **Nothing sanctioned removed a review checkout or a brief:** a review's detached checkout has no
  branch, so `tools/prune-merged.sh`, the script that retires a merged branch and its worktree,
  never takes it, and a released brief was never deleted.
- **Sentences no longer true:** a "Python 3.9+" line of `CLAUDE.md` that does not exist; pointers
  to `docs/DECISIONS.md` for a record, where records are files fetched with `tools/decisions.sh`;
  rules for merging a branch still on the single-file queue, a case no open pull request can still
  be; "ten milestones" as an interval, where entries are no longer numbered.
- **Examples that broke another rule:** the inbox skill captured the player's words through fixed
  file names under `/tmp`, where a stale file can be posted as their words.
- **Rules a cold session could not follow:** "ask first, in the session" beside the board's rule
  that no question is a dialog in the chat; "show the user" in a skill a builder reads with no user;
  a conclusion "written down in the turn it is reached" in a queue file that only a reviewed pull
  request changes.
- **History in the rule files**, and proposals marked inline until a reader could not tell the
  player's rules from the filer's.

## What was built

- **Each skill opens with its must-see rules**, one line each, inside its first two kilobytes.
- **The board** is read at session start, when the player says "doc" or "check the doc", and
  before the first write to it in a turn, with no read between the session's own consecutive
  writes; it is not polled on other turns.
- **One owner per rule:** the identity rule is committing's, and each of the three skills keeps
  only what is its own (the reviewer identity alone approves; the two roles whose captures count).
  The mechanics of the test-only-members list are the tool's; writing-tests keeps what a builder
  does about a failure, and three points the tool's help does not say.
- **Which model reviews** is the orchestrating skill's model table to decide; pr-review fixes one
  case itself, a queue update's review, which is Sonnet's (bouncy-heron 8).
- **A review checkout and a released brief each have a way out, said once each:** pr-review says a
  review checkout is removed with `tools/agent-setup.sh --remove <name>` once the review is posted,
  and session-cleanup, with its storage reference, that `tools/prune-merged.sh` deletes a released
  brief as it retires the brief's branch. The flag and the deletion are the hooks pull request's.
- **The false sentences are corrected or gone**, the old-queue passages among them.
- **The inbox skill's examples** write through a file in a fresh directory, in three calls.
- **The unfollowable rules say what to do:** ask on the board, and a session that does not write
  the board reports the fork to the orchestrating one; a merge's excerpts go in the report and the
  pull request's conversation; a conclusion goes on the inbox note in that turn, in the queue item
  at the next queue update, and in the restart prompt's plan until then.
- **designing-classes lists the layers in order**, as the layer map (`tools/layer_map.py`) has
  them, each with what it holds.
- **Detail moved to reference files** the skill names with when to read it: verify's windowed
  capture, experiment evidence, dev flags and runner internals; the filing of an inbox batch;
  session-cleanup's storage steps; the reviewer's procedure for a changed checker.
- **The proposals are listed once at the end of each file that has any**, each with the player's
  word it extends or the record that proposes it, or saying that the player's words name nothing
  on the point.

The twelve skills are smaller by less than the review's table projected: the moves are made, and
the same review adds an opening list to every file, a closing list to six, the layer list and the
three-call sequence.

## Where the review was wrong

- It gave the test-only-members check's help as holding everything the skills said about the
  list. Three points are only in the tool's header comment (a moved file must be tracked first for
  its lines to pair; a renamed member is not carried; a member reached only through a string is a
  false failure), so writing-tests keeps one sentence each until the help says them.

## Choices made in the rewrite, open to the player's overturn

- **Thirty days without a commit to an item's file** is the interval after which session-cleanup
  reassesses a long-open item, in place of "ten milestones". Listed in the skill as a proposal.
- **The restart prompt stays under 10 KB.** Listed in the skill as a proposal.
- merging-main keeps the general half of the old-queue passage: a record that takes a new name
  keeps its content, its provenance and the player's words.
- playtest-feedback keeps its two spent-park sentences as present-tense examples.
- designing-classes' closing list has an entry for which layers there are, since the set of layers
  is the filer's apart from the two points the player decided (inbox #904 in freckled-moose).

## History taken out of the skills

Kept here word for word, each with the rule it stood beside.

**verify, "Headless unless a window is the only way":**

> **Why, beyond tidiness — a windowed run used to be able to hang forever, and working beside one is still not free** (woolly-finch 1). A rig's own window now carries three defences against exactly that (docs/DECISIONS.md, M195, "a rig's window takes no focus, hears no stray key, and always closes"): it never takes the OS focus in the first place (`DisplayServer.WINDOW_FLAG_NO_FOCUS`), its main loop runs at full speed while covered or unfocused rather than throttling to about once a second the way an ordinary window's does on macOS (`--disable-vsync`, both scripts' own launch; running is not drawing, see "a hidden window is not drawn" below), and it always closes — the game's own wall-clock timer, backstopped by `tools/shot.sh`'s (and a rig-flagged `tools/run.sh`'s) outside kill. None of that makes a windowed run *free*, only bounded: it is still slower than a headless check by however long Godot takes to boot a window and draw a frame, and a run left to its outside kill still costs the whole of that wait before it says so.

Smaller phrases from the same skill: "but have not been photographed that way"; "the one case not
yet photographed"; "and now never hears a real key or pointer press at all while it drives a run";
"can no longer reach the rig either way, on top of that"; "see that file's own header and M172, a
suite that fails to parse fails the test run, in `docs/DECISIONS.md`"; "a runner that hangs on a
broken suite again".

**writing-tests, "a test module `test_<x>` tests only `<x>`":**

> *Asked for as guidance rather than a hard rule (inbox #1018 in brisk-ferret) · made a hard rule with exceptions only for good reasons on 2026-11-06, because as guidance it did not work (inbox #1159 in gray-dolphin).*

Only statement 8 of inbox #1018 in brisk-ferret, that the rule is guidance and not a hard rule, is
overturned. Its statements 5 and 10 are still rules in writing-tests, which cites the note for
them: components tested apart, correctness confirmed by dependency injection, a private read or an
escape hatch as a sign of one of three things, and the three as examples.

**writing-tests, "A test never asserts what a setting is":**

> *Asked for as a judgment call, a test that only doubles the work of a change deleted (PLAYTEST-67) · overturned to absolute on 2026-11-06, because a test must never test configuration settings (inbox #1159 in gray-dolphin).*

**writing-tests, "The kept relationship tests stay":**

> *Kept for fairness guarantees only (inbox #1159 in gray-dolphin) · widened on 2026-11-07 to any guarantee between settings (inbox #1173 in gray-dolphin).*

**designing-classes, "Code is designed by layer":**

> *Two departures from minty-quail's filed layering, decided by the player* (inbox #904 in freckled-moose): the view (the HUD, the screens, the badges, the controls) and the observers are **siblings at one level**, neither above the other and neither naming the other, where minty-quail's README puts the UI inside the observers; and the map lookup (`WorldMap` and its records) stays **with the city maps in the domain model**, a correction to minty-quail's item 3, which puts one map interface in the world.

and, from the proposal before it:

> the target layers are minty-quail's (data and configuration; the domain model; the world; simulation; run flow; observers);

**merging-main, "Preserve the identity of records before merging":**

> **One case still collides: a branch from before the queue was files** that filed a new entry `M<n>` or a new `PLAYTEST-NN.md` the old way, when `main` has a different record under the same number. Keep `main`'s record and number intact; give the branch's record a name from `tools/new-name.sh` instead of the next number, preserve its content, provenance and the player's words, and update every reference that means the branch's record — never a global replacement of the shared number, which also rewrites references to `main`'s record. A playtest's identity changes only in its identifying label; its text is a primary source. Ambiguous references need historical inspection; do not guess which session they mean. A persisted or externally consumed identifier needs its consumers checked, not only a textual rename.

**merging-main, "Show every conflict in three ways":**

> **A branch still on the old single-file queue** — its `docs/DECISIONS.md`, `docs/TODO.md` or `docs/REVIEW.md` edited where `main` has them as files — is converted, never hand-merged: `tools/convert-queue-edits.py`, run mid-merge, reads what the branch did to the three old files since the merge base and applies it as file operations on `main`'s side (a record added becomes a decision file, a closed entry or item deletes its folder or file, a review bullet becomes a review file, an edit inside an entry becomes the same edit to its file), stages them, and resolves the three files to `main`'s text. It refuses, naming every path, and changes nothing on an edit it cannot map; show that path three ways as below. Converting does not exempt the merge from the semantic review below.

Also from that skill: "or the branch turns out to edit the old single-file queue"; "the conversion's
plan"; and its description's clause "and the conversion of a branch still on the old single-file
queue".

**pr-review, "Briefing a review agent":**

> Sonnet is enough for a small or mechanical PR; a PR that carries a design decision, a drawing, or a change to the rules is reviewed by a stronger model.

**pr-review, the procedure for a changed checker:**

> (for `Main.use_sitting` in the PR that added the per-class reading, the test's call is on a `TitleScreen`)

**pr-review, the queue update's six questions:**

> The first five are the reviewer's reading of faithfulness (bouncy-heron 4), proposed at filing (leafy-finch), and the sixth came from the player's note (inbox #767 in minty-lemur); all are open to the player's correction.

**pr-review, "Is every defect already found in this change fixed inside it?":** "(`docs/decisions/`,
M90, the controls do what the hand does, where PLAYTEST-35's findings on the open branch went in)".

**session-cleanup, the restart prompt's layout:** "The player asked for a better layout, old entries
removed routinely and a systematic way of reading it (frosty-owl #1065); the layout below is the
filer's proposal, not asked for and open to the player's correction:".

**playtest-feedback**, two sentences whose tense changed: "as a park fenced with a street closure's
barriers (PLAYTEST-140 8) was" and "as when the spent park's ask, which was about routing, was
filed as a park she cannot enter".
