# polite-marten — The handoff leaves the repository · 2026-09-26 · not from an entry

*(2026-09-26: "why is the handoff checked in anyway?" — then, shown what it held: "we don't need
session handover across agents. each have their own threads to work on. let's remove the handoff
file from github". Earlier the same evening, on a line recording a session's merge permission:
"remove that bit altogether -- this is not something that should go into a checked in handoff".)*

**What was done.** `docs/HANDOFF.md` is deleted. Nothing checked in says where a session stopped:
the pick-up state is read live from `gh pr list`, `tools/agent-status.sh`, `tools/queue.sh` and the
items under `docs/review/`, and a session's end writes only the git-ignored
`.claude/restart-prompt.md` (**session-cleanup**, step 7 and 8). The restart prompt never records a
merge or release permission, since permission is per session.

**What the file held, and where each part went.** Read paragraph by paragraph before deletion, it
was roughly five things:

- **Durable how-to guidance, a little under half of it.** Most was already where it belongs and
  was only repeated: the tools catalogue in **using-tools**, the probes and `PARTIAL RUN` and the
  unloadable suite in **verify**, the B and P captures in `README.md` and `docs/TELEMETRY.md`,
  `tools/reference.sh`'s privacy guarantee in **reference-photos**, `--walk` and the debug view in
  **verify** and `docs/TELEMETRY.md`. What lived only in the handoff moved: how CI, the rulesets,
  the deploy and `tools/release.sh` behave, the batch-merge trade-off, and that publishing needs
  its own go-ahead went to **committing** ("Merging", "Releasing"); the engine-error rule of
  `tools/test.sh` and `check.sh`'s revert of the files its import pass rewrites went to **verify**;
  why `tools/serve-web.sh` exports debug went to its **using-tools** row; the one-speed rule's own
  words and reason, and why a press is never a destination, went to `docs/MECHANICS.md`.
- **Design state, about a third.** The control schemes, the walled city, the junctions, the
  reachability grid, the graphics workflow: already stated in `docs/MECHANICS.md`,
  `docs/ARCHITECTURE.md`, `docs/CITY.md`, `docs/VISUALS.md` and `docs/GRAPHICS.md`, with the
  history in the records (M53, M69, M76, M80, M82, M83, M88, M110, M111, M118).
- **Queue and review pointers.** "Built and unwalked" paragraphs for playtests 22 and 25 and the
  new controls, M56's remaining measurement, M109 and M100: each already an item under
  `docs/review/` or an entry under `docs/todo/`.
- **Where the last session stopped**, a tenth: open pull requests, a branch without a PR, the
  briefs, a merge permission. Dropped; it is local state.
- **Two closing rules** — the first tool call of a design task is a search, and the plan is the
  orchestrator's while the implementation is an agent's — already in **playtest-feedback** and
  **orchestrating**.

**Why it went.** Each agent and each host works its own threads, and a session only ever needs the
state of the threads it picks up, which the live commands give exactly. A checked-in handoff
conflicted across pull requests: M223's count found it the third most conflicted file in the
month before, and on the day it went, a merge of `main` into PR #385's branch replaced the
365-line handoff `main` had just written with the branch's own 61 lines. A review noticed, and the
player then chose #385's version on purpose ("I prefer codex's version of the handoff"); but
whichever side of such a merge wins, the other side's session state goes unless somebody notices.
It went stale by design — it was true only at the moment the last session ended and false after
the next merge — and it put session state (which PRs were open, who had permission to merge) into
`main`'s history, where it reads as a standing fact. **The session-cleanup rule that only the
session's end writes it** (M223, "handoff only at the end of a session") answered the conflicts
and not the staleness, and still wrote session state into git.

**Rejected: keeping a trimmed handoff of the durable part.** Every durable paragraph already had,
or now has, an owner that loads when it is needed — a skill by its trigger, a design doc by its
subject — and a second copy in a general entry point is the "three files, three answers" drift
session-cleanup exists to prevent. A handoff with no session state in it is an index of those
owners, which `CLAUDE.md` already is.
