# Visual attempts come back early

Part of the agent contract (`agent-contract.md`, beside this file), read by an agent whose work is
artwork, sound or any result judged by eye or ear, before its first attempt.

The player welcomes repeated feedback and prefers seeing an attempt to waiting through a long
internal revision loop. For artwork, sound or any visual or audible result:

- Come back early with a preview yourself: a prompt preview in the player's requested format,
  naming the visual point that remains uncertain. Keep cheap integrity checks and provenance, but do
  not hold a useful attempt for polish or repeated generation. The player's response steers the next
  pass while independent work continues.
- The player's CLI cannot display images: push the review artifacts first, then embed them in the
  PR description as images with commit-pinned URLs, as **committing** says. A local file link is
  not a delivered visual review.
- **A question the player is to answer by eye gets a picture of its own** (woolly-penguin #758). A
  full sheet is evidence of what was drawn; the decision is shown apart from it, in a picture of the
  options alone, with the question written above it in the PR description, and a choice is never
  asked by row number. The picture holds only the options and the stages either side of them, each
  labelled with a letter the question uses, each option said in words.
- **A delivered review file stays byte-for-byte unchanged.** Render into job-owned scratch, wait
  for the writer to finish, then copy the completed artifact to a new versioned delivery filename
  and record its hash. Once the player has a link, no render or copy overwrites that file: further
  attempts get new filenames. Independent work can continue while the player reviews, but it cannot
  change the artifact being reviewed.
- Label an attempt's actual verification limits: an existing file and plausible stream metadata do
  not prove its audio or picture matches the requested result.
- Showing an attempt does not authorize runtime installation.

## Proposed, not asked for

- **The form of the picture a by-eye question gets** (only the options and the stages either side,
  each lettered, each said in words) is the filer's proposal, open to the player's correction. The
  player asked for a picture of the options apart from the sheet (woolly-penguin #758).
