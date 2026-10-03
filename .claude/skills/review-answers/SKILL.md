---
name: review-answers
description: Generate an editable, self-contained answer worksheet from docs/review. Use when the player wants one local document for answering the review questions; do not use for pull-request review or for processing completed answers.
---

# Review answer worksheet

Create a local Markdown worksheet that the player can understand and answer with only that file open.

## Build the worksheet

Read `docs/REVIEW.md`, then every current `docs/review/*.md` file in filename order. The review
files are authoritative for what must be asked. Read their local references, relevant decision
records, playtests or code only where needed to explain a question; use judgment to summarize the
context rather than copying whole records or applying an automated sentence-stripping scheme.

Write to `build/review-answers.md` in the **main checkout** (`/Users/krause/workspace/nappy-claude/build/`)
by default, never in an agent's worktree: a worktree's `build/` is deleted by `git worktree remove`,
and the player's answers with it. Report the absolute path. The worksheet is local and Git-ignored.
If that path already exists, inspect it for player-written answers and choose a fresh sibling filename instead
of overwriting it. Overwrite an existing worksheet only when the player explicitly asks. Never
lose existing answer text while regenerating a worksheet.

Give each review source, in order:

1. A numbered Markdown heading that identifies the subject.
2. Self-contained prose with every distinct question and every detail needed to answer it:
   scenario, setup, day, seed, command or flags, expected behavior, known measurement and relevant
   tradeoff. Summarize repetition, but do not merge away subquestions.
3. `Source item: <plain filename>` as a tracking label.
4. Exactly one plain lowercase `answer:` line, with a blank line before and after it.

Put context inline in plain Markdown. The player must not need to follow a link or open an image to
understand what is being asked. Describe relevant visual evidence and what still needs judgment;
do not imply that prose reproduces a visual verdict. If a dependency cannot be resolved locally,
say what is missing beside the affected question rather than omitting it or fetching an external
site.

Keep disagreements, outdated premises and uncertain facts visible. Explain which source says what
and what the live repository currently establishes, without silently choosing an answer or erasing
the original concern. Current records or code may clarify context; they do not settle a subjective
question for the player.

## Protect the review state

Generating the worksheet changes only the chosen local file under `build/`. Do not alter review
sources, queue entries, decision records, playtests, game files, commits or pull requests. Turning
filled answers into repository changes is a separate task.

Before reporting completion, compare the worksheet with the live source set and verify:

- every current review filename appears once and removed files contributed no item;
- every actual question and question part remains answerable from the worksheet (a question-mark
  count is not a coverage check);
- each item has exactly one literal `answer:` marker with the required blank lines;
- no context depends on opening a link or image, and unresolved dependencies are named;
- no pre-existing player answer or other text was overwritten.

Read the finished worksheet once as a standalone document, then report its local path.
