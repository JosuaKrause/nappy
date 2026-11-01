# The architecture questions every code pull request answers

**Every pull request that changes code answers a fixed set of questions about where its pieces
sit, so the architecture the refactor built does not drift once it is done** (plush-egret #892).
The review already finds bugs; what it does not see on its own is a piece put in the wrong layer,
a dependency pointing up, a thing fetched that should be handed, or a copy beside something that
already exists. The author answers, CI checks the answers are there, and the reviewer checks they
are true. This file is the one place the questions are worded; every other text points here, and
`tools/ci_pr_questions.py` reads them from here.

## The questions

1. Which layer does each new or changed piece belong to, and why there?
2. What does it depend on, and is every dependency on its own layer or below?
3. What is it handed, and what does it fetch? A group lookup, an autoload or a static read in a
   simulation layer is named and justified.
4. Does something like it already exist? If so the pull request reuses it or says why not; a mode
   is configured, never copied (minty-lemur #785).
5. Does a fix land in the shared mechanism, or in a branch keyed on one row's id or picture?
6. Can it be tested in isolation? What does a test hand it: can a test build it with fakes and no
   scene tree?
7. Which docs say where it lives (`docs/ARCHITECTURE.md`'s listing), and are they updated?

The layers are **orchestrating**'s "Code is designed by layer"; which folder and file sits in which
is `tools/layer_map.py`. `tools/check_layers.py` answers the second and third questions
mechanically: CI fails a new upward name, and a group lookup, an autoload or a stateful static read
in the world or simulation layers, that its list of standing breaks does not name. An answer to
either names every listed break in a file the pull request touches and every line it adds to or
removes from that list, and says why; a pull request that puts a file in another layer says why the
map was wrong.

*Proposed, open to overturn:* the sixth carries the player's own question first, ahead of the
question it overlaps, rather than standing as an eighth (plush-egret #892; the player offered the
choice, plaid-raven #894), so the two are answered once, together.

## Where they are answered

- **In the pull request's description, under the heading `## Architecture questions`**, one
  numbered answer per question, in order. An answer may restate its question before answering it.
- **In the builder's report**, which is the description (`../../orchestrating/references/agent-contract.md`),
  so a brief asks for the layer and the answers (**orchestrating**, "The task description is the
  contract").
- **A pull request that adds no piece and no dependency** (a fix inside one component) answers in
  one line under the same heading instead:

  `No new piece or dependency: <what the change is and the component it stays inside>`

## Which pull requests

Every pull request that changes a file under `src/`, `tests/` or `tools/`. A docs-only or queue-only
pull request (`tools/ci_classify.py`) changes none of them and answers nothing. A pull request
opened before `tools/ci_pr_questions.py` reached `main` is exempt; the check tells them apart by the
time the pull request was opened.

## What checks them

- **CI** (`tools/ci_pr_questions.py`, in the `gates` job) fails a pull request in scope whose
  description has no `## Architecture questions` heading, or under it neither an answer to every
  question nor the one-line form. It sees that an answer is there, never whether it is true.
- **CI** (`tools/check_layers.py`, in the `gates` job, on every run) fails a new break of the
  layer map and a listed break that is gone. A listed break is matched by file, rule and name, with
  the number of uses the list gives for it (one unless it says more), so a further use of a listed
  name in a listed file fails, and so does one fewer until the count is lowered.
- **The reviewer** checks each answer against the diff and against `tools/check_layers.py --list`
  on the pull request's head; an answer the diff or the check contradicts is a finding
  (**pr-review**, "Then the code").
