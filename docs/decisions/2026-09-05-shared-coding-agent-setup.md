## Shared coding-agent setup — 2026-09-05

The request was to support both Claude Code and Codex, including hooks and discoverable skills,
with the same behavior "in spirit". The integration kept `.claude/skills/` as the canonical
content and exposed it through `.agents/skills`, rather than copying skills that could drift.
`AGENTS.md` supplied Codex's entry point and tool adaptations. A Codex hook adapter reused the
Claude rule mapping and lint scripts, translating multi-file patches and lifecycle payloads.
Shell edits retained explicit rule loading because script-generated paths cannot be inferred
reliably; loading every skill on the first shell read was rejected to preserve selective context.
The user also questioned whether Claude's delegation rule saved usage in Codex. The shared
orchestration skill separated Claude's Sonnet default from Codex's decision to delegate for
parallelism, context isolation or independent review; inheriting the parent model offered no
automatic cheaper-model saving.

The user clarified that this had been a question to investigate, not a decision to discourage
delegation: cheaper Codex models made delegation recommended. The correction restored that
recommendation and selected Luna at medium effort as the repository's subagent default, with
explicit stronger-model overrides when needed. The parent retained design and verification.
