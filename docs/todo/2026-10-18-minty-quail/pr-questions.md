# Questions every pull request answers, so the architecture does not drift after the refactor

**The ask.** Asked whether reviews should split into roles (security, adversarial, correctness,
intentionality, architecture, style, extensibility), the player: "I think the current process works
well with finding potential bugs. what I'm worried about is that the architecture starts to drift again
once the refactor is complete", then "I guess it could be framed as series of questions a PR needs to
answer", adding "also \"can this be tested in isolation\" although there is some overlap to Q6", and to
the first cut below "yeah I like this"; then "can we build this in parallel?" (plush-egret #892).

**Read as:** the review stays one adversarial reviewer; what is added is a fixed set of architecture
questions every code pull request answers, which the author answers and the review verifies, built now,
beside the refactor's remaining steps, not saved for its closing pull request.

**The questions** (the orchestrating session's first cut, which the player accepted, with the player's
eighth):
1. Which layer does each new or changed piece belong to, and why there?
2. What does it depend on, and is every dependency on its own layer or below?
3. What is it handed, and what does it fetch? A group lookup, an autoload or a static read in a
   simulation layer is named and justified.
4. Does something like it already exist? If so the pull request reuses it or says why not; a mode is
   configured, never copied (minty-lemur #785).
5. Does a fix land in the shared mechanism, or in a branch keyed on one row's id or picture?
6. What does a test hand it: can a test build it with fakes and no scene tree?
7. Which docs say where it lives (`docs/ARCHITECTURE.md`'s listing), and are they updated?
8. Can it be tested in isolation? It overlaps the sixth, as the player said; how the two are worded
   together is the builder's to propose.

**Proposed, not asked for** (the orchestrating session's, open to overturn):
- The author answers them in the brief and in the pull request's description, under one heading; a
  pull request that adds no piece and no dependency (a fix inside one component) answers in a line.
- CI checks that a code pull request's description carries the answers, the way
  `tools/ci_code_pr_queue.py` checks for a queue item.
- A layer-check script answers the second and third mechanically: the layer map held as data (the
  target layers in **orchestrating**'s "Code is designed by layer": data and configuration, the domain
  model, the world, simulation, run flow, observers, with the view and UI above), failing a pull request
  where a file names a class of a higher layer, or a simulation-layer file fetches through a group, an
  autoload or a static; every exception standing today listed by name, so the list only shrinks as the
  refactor's remaining items land.
- The review verifies each answer against the diff (**pr-review** gains the questions);
  **orchestrating**'s brief template asks for the layer and the answers.
- Tested before it is relied on: the layer check run on `main` as it stood before the refactor flags
  what the refactor fixed (`VisibleView` reading the touch controls, the crowd reading the frame
  record's statics, the crowd finding her through the `player` group), and on today's `main` only the
  listed exceptions; the questions answered for PRs #888 to #891 surface what their reviews found about
  layering.
- Left for later, not in this item: a file-size and near-copy watch in CI, and a periodic drift audit
  that files what it finds into the queue.
