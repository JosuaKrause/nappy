# mossy-rabbit — A tool's help says what its catalogue row had to keep · 2026-11-11

**The ask.** The tool catalogue (the using-tools skill) says what each entry point is for and leaves
flags, numbers and refusals to the tool's `--help`; for about two dozen tools the help lacked a
sentence the old row said, so the row kept it, and six tools that write pictures or video printed no
pointer to the skill that governs their output (`tool-help-gaps.md`, mossy-rabbit's last item). Not
the player's request: a defect the rules review found, filed by the orchestrator, split ahead of the
refactor as tooling when the player answered "split it" (inbox #1348 in grassy-trout).

## What was built

- **Each sentence a catalogue row kept that the tool's help lacked moved into the help**, and the row
  says only what the tool is for: the GoatCounter reader (where its key comes from, the linked
  worktree's `.env`, the host, a saved read compared with the previous file by hand), the layer,
  override, test-only-member, field-read and citation checks, the inbox tool, the CI checks, the
  ground-frames measure, the trailer's selected modes, the queue's `--check` errors, the lint pass's
  name clash, the name drawer's heading, the browser check, the sound synthesizer and the Reddit
  reader's credentials. Two rows whose help already held the rest are shortened to their purpose.
- **The six picture and video writers** (`remove-checkerboard.py`, `split-scenes.py`,
  `bake-atlases.sh`, `record.sh`, `clip.sh`, `trailer.sh`) print, after success and on stderr, the
  one-line pointer to their skill that `shot.sh`, `reference.sh` and `synthesize-sfx.py` print. No
  other behaviour changes.

## Choices open to overturn

- **Which skill each writer names**: session-captures for the recording, the clip and the trailer,
  illustrated-png for the checkerboard remover and the atlas bake, svg-art for the scene splitter
  (the builder's).
- **The Codex adapter's guard budget stays in its row**, since Codex support is frozen and its files
  stay as they are (the builder's).

## Left, each with its reason

- **`tools/field_answers.py` and `tools/sweep-agent-leftovers.py` and their rows** are untouched:
  other pull requests held them while this one was built.

## Verified

`./tools/pycheck.sh`, `tools/test_cli_help.py`, `./tools/lint.sh` and the citation check pass;
`tools/test_cli_help.sh` passes all but the trailer's `--selected-remix` case, which needs an import
cache a sparse worktree lacks and CI has.
