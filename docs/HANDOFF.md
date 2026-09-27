# Handoff

Read `CLAUDE.md`, inspect the working tree and open pull requests, fetch the current remote state,
then run `tools/queue.sh`. Queue order comes from each entry's priority band; `docs/TODO.md`
explains the format. Historical decisions live under `docs/decisions/` and are found with
`tools/decisions.sh`.

## Pick up the animation review

[PR #385, separate scenery animation](https://github.com/JosuaKrause/nappy/pull/385) carries roof
vent, south-water, broken-pipe spray and crash-smoke separation, runtime GIFs and controlled
native measurements. Read its current checks and review comments before acting. The player's
instruction is to push the current progress and latest findings and mark the PR ready for review.
No merge or release is authorized.

The [capture report](evidence/m159-scenery-animation-2026-09-26/README.md),
[native comparison](evidence/m159-scenery-animation-2026-09-26/native/README.md) and
[retained contract](evidence/m159-scenery-animation-2026-09-26/CONTRACT.md) distinguish eliminated
static redraw work from mixed whole-frame results. They establish no general FPS, phone or GPU
improvement. The [visual review item](review/2026-09-19-M159.md) asks about the separated parts
and proposed water ripple. The player's words are in
[Sunny lynx](playtests/2026-09-26-sunny-lynx.md).

[M159, a slow frame names the frame that was slow](todo/2026-09-19-M159/README.md), retains the
wider attribution, atlas and phone work. Its separate exploratory items cover event-shape
classification caching, identical danger-prediction reuse, and reuse/lazy preparation of static
visuals before they enter view. Their mechanisms are proposals to measure. No further optimization
pass is selected for implementation at this checkpoint.

## Other pickup threads

Run the queue for current priority; its immediate entries are M227, Codex as a Claude Code
sub-agent; M226, pursuing-dog timing and the other warnings; and M223, the queue/review overhaul.
Other sessions' open work stays separate from this animation checkpoint.

PR #362, the trap comes to her, needs its decision identity reconciled with M137's queue
identity and its record checked against the event doc's trap variants. PR #365, courtyard roofs
and furniture, needs its M216 queue closure and visual evidence reviewed; the map-edge front
case still needs a design answer. PR #379, the man shouting, carries the proposed standing
handover and the unresolved report of zero charge. Inspect each live PR and its own brief before
resuming any of them.

The spent-park follow-up remains a plan with an unrun regression start; its queue item is
M129, a spent park is closed. The post-release counter readback belongs to
[the counter review item](review/2026-09-26-after-the-next-release-read-the.md):
a path beginning `/nappy` counts site access and a name beginning `nappy-` counts a game metric.

## Work safely across sessions

Inspect `tools/agent-status.sh` and the current briefs under `.claude/briefs/` before touching
an existing worktree. Start a fresh bounded agent when a previous agent is cold; never overwrite
uncommitted or separately pushed work. Other sessions' worktrees are outside this task.

The main checkout is the player's test bed. Check out the intended build there before inviting
a local playtest. Every game launch uses dev flags or `--no-save`; only one measured game runs
at a time. Visual evidence of motion is a timed burst, and GIFs in a PR are linked by commit.

Run `tools/check.sh`, the affected suites and `tools/lint.sh` for changes; Python tooling also
uses `tools/pycheck.sh`. Full-suite validation is CI's. A merge needs an independent review of
the current head and explicit current-session permission; marking a PR ready for review supplies
neither merge nor release permission.
