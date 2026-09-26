# Codex: match the subagent to the task's difficulty

**Delegation is recommended in Codex too.** Hand specified implementation and routine
investigation to a model suited to that delegated task, keeping design and ambiguous decisions in
the orchestrating session; the review before merge is a separate reviewer's, under **pr-review**. The orchestrator may use any model; choose the
subagent independently by the difficulty of the delegated task. Describe the parent as the
orchestrator in task briefs, without naming or assuming its model. Prefer the least costly
model that can handle the task reliably:

- Use `gpt-5.6-luna` for simple, routine or mechanical bounded work and waits.
- Use `gpt-5.6-terra` for ordinary implementation whose requirements and boundaries are clear.
- Use `gpt-5.6-sol` for involved work that needs stronger investigation, integration or judgment.
- Use `gpt-6-astra` for complex or difficult tasks. Do not make a weaker subagent struggle through
  work whose geometry, architecture, ambiguity or cross-system contracts warrant Astra.

**Route on the reasoning that remains, not the subject's label.** An art, visual or geometry task
is not Astra merely because it contains pictures or spatial placement. Once the geometry and
acceptance contract are settled, binding approved assets through known callers is ordinary
implementation: use Terra when it still has to reconcile placement, draw order, preserved
behavior, tests or runtime evidence; use Luna when it is a direct mechanical substitution with no
interpretive placement or integration choice. Astra is for geometry, architecture, ambiguity or
cross-system contracts that are still genuinely unresolved, not complexity already removed by the
brief.

`.codex/config.toml` sets the default subagent model and reasoning effort: `gpt-5.6-luna` at
medium effort, for routine bounded work. Select Terra, Sol or Astra explicitly when the task's
difficulty warrants it, and choose reasoning effort separately from model tier. Do not keep
retrying an underpowered model. Keep the same scope and verification contracts regardless of
model cost.

If the host does not apply repository subagent defaults, select the model and effort explicitly
when spawning. With the collaboration tool, use a fresh context (`fork_turns="none"`) and a
self-contained brief so the model override takes effect. A full-history fork inherits the
parent model, so use a fresh fork when the delegated task needs a different tier. Do not let
the orchestrator's model determine the subagent choice: route by the delegated task's needs.
