# The model table and the label's text say who decides a hand-off and that a build takes the lowest model able

**What changes.** The orchestrating skill's model table (`.claude/skills/orchestrating/SKILL.md`, "The
model table: which model does what"), and every other place that restates what the `fable-only` label
means, are rewritten to the README's reading:

- The `fable-only` row: Fable designs the code and reviews it; the Fable designer decides whether the
  coding is too complex to hand off, writes it itself if so, and otherwise hands it to the lowest
  model that can do it.
- A row, or a sentence above the table, saying that a design is always detailed, the kind a builder
  works from, and takes a stronger model; and that a build, and any task that is neither a design nor
  a review, takes the lowest model that can do it.
- "Build at test parity | Sonnet" and "Build that changes play, or builds a seam from its design |
  Opus" are replaced by that rule; the review rows stay as they are (the player: reviews have their
  own decision points, and some need no strong model). "Investigate an unexplained result | Opus" and
  the two measuring rows are judged against "the lowest model that can do it" when the item is
  built, and the pull request says what it did with each.
- The places that restate the label: `docs/TODO.md` (the `fable-only` line's meaning), the
  playtest-feedback skill's queue-entry paragraph ("writing the code may go to another model") and
  the orchestrating skill's "Proposed, not asked for" bullets on the build rows, which go once those
  rows cite the player.

**Asked first:** whether one Fable agent at a time (inbox #1433 in minty-rabbit) becomes a line of the
table (the README's open point).

**Accepted when** the table, `docs/TODO.md` and the playtest-feedback skill say the same thing, every
new sentence cites inbox #1432 in minty-rabbit, `./tools/lint.sh` passes, and the review (Opus, a change
to what a rule says) finds the text matches the player's words.
