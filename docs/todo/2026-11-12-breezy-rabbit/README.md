priority: now

# breezy-rabbit — The model table says the Fable designer decides a hand-off, every build takes the lowest model that can do it, and one Fable runs at a time · filed 2026-11-12

**The ask.** Asked where the rules allow a Fable agent to build, the player explained the `fable-only`
label's "can hand off coding": "the reason it says "can" is because fable might decide that the
coding is too complex", then "otherwise always use the lowest model that can do it" and "building
doesn't need a strong model if the plan was strong". Asked whether that reaches more than building:
"design (and by that I mean *detailed* designs) and reviews in general are where stronger models
should be used", "(reviews have their own decision points, though)", "(some reviews don't need a
strong model)". Corrected on a summary that had detailed designs as one kind of design: "you got that
backwards. the designs must be detailed always" (inbox #1432 in minty-rabbit). And at the start of the
same session: "please use only one fable at a time and not in parallel" (inbox #1433 in minty-rabbit).

**Read as:**

- **On a `fable-only` pull request the Fable agent that designs the code decides who writes it**:
  it hands the coding off unless it judges the coding too complex to hand off, and then writes it
  itself. A brief does not make that choice for it.
- **A design is always detailed, the kind a builder works from, and designing takes a stronger
  model.**
- **Building, and every other task that is neither a design nor a review, takes the lowest model
  that can do it**, since the detailed design is what lets a weaker model build. The model table's
  build rows stop defaulting to Opus.
- **A review's model keeps the table's own review rows**: stronger models in general, but some
  reviews need none.

**Why it is work on how the project is worked on:** the orchestrating skill's model table is what
every brief picks its model from, so it goes first (the orchestrating skill's "Work on how the project
is worked on goes first").

**Open:** whether "one fable at a time and not in parallel" (inbox #1433 in minty-rabbit) is a standing
rule for the model table or held for that session only (`one-fable-line.md`, asked on the board).

*Not asked for:* the band `now` is the filer's proposal.
