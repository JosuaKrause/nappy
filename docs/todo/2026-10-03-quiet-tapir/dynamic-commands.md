# Refuse hidden write verbs and input-provided release refspecs

Reproduce the three distinct gaps from the source review using hook JSON. Classify
unreadable or publishing writes as denied under both opt-in and default refusal,
preserving recognized reads, command boundaries, coder exemptions and reviewer
restrictions. Include Codex adapter checks only if its payload/tool/event contract
changes. Record the accepted parser limits and verify all tested payloads are data.
