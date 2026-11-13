# breezy-rabbit — The model table says the Fable designer decides a hand-off, a design is always detailed and takes a stronger model, and a build takes the lowest model able · 2026-11-12


**The ask.** Asked where the rules allow a Fable agent to build, the player explained that the
`fable-only` label's "can hand off coding" is there because Fable may judge the coding too complex,
that otherwise the lowest model that can do it is used, that a build needs no strong model when the
plan is strong, that designs, always detailed, and reviews are where stronger models go, and that
reviews keep their own decision points (inbox #1432 in minty-rabbit).

**What it corrects.** The model table's `fable-only` row said writing the code "may go to another
model" without saying who decides; the brief for polite-tapir's `RowGround` seam (the event
scheduler's breakup) decided for Fable and had a Fable agent write the code. Its build rows defaulted
to Opus for any build that changes play or builds a seam from its design.

## What was built

- **The `fable-only` row**: the Fable designer decides whether the coding is too complex to hand off,
  writes it itself if so, and otherwise hands it to the lowest model that can do it; a brief never
  decides this.
- **Two rows replace "Build at test parity | Sonnet", "Build that changes play, or builds a seam from
  its design | Opus" and "Investigate an unexplained result | Opus"**: a design, always detailed, takes
  a stronger model; a build, and every task that is neither a design nor a review, takes the lowest
  model that can do it. A paragraph under the table says why.
- **`docs/TODO.md` and the playtest-feedback skill** restate the label the same way.
- The review rows, the drawing row and the measuring and capture rows stay.

## Choices open to overturn

- **An investigation of an unexplained result goes under the lowest-model rule**: it is neither a design
  nor a review, and no cited rule kept Opus for it.
- **The measuring and capture rows (Haiku, Sonnet) stay**, read as already the lowest model able.
- **No line about one Fable agent at a time** (inbox #1433 in minty-rabbit): whether it is standing is
  asked on the board (one-fable-standing), and the entry keeps that item.
- **How a hand-off reaches a builder**: the Fable designer says in its report whether it writes the code or hands
  it off, and on a hand-off the orchestrator briefs the lowest model able from the design. The filer's proposal,
  since the player's words do not say how.
- **Drawing keeps Opus**, and the measuring and capture rows name the lowest model for their kind; the catch-all
  covers only a build and the tasks no row names.
