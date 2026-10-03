# Playtest plaid-tapir — The inbox files only a labelled note, and its first filing follows the merge

2026-10-03. Said in conversation while leafy-finch's inbox half (PR #429: the inbox skill, capture
and the write guard) was being wrapped up after a review of every PR merged since v0.21.0.

## Statements

> "the next high priority item to wrap up is the 429 leafy finch wrap up. once this is merged we
> will do the first issue ingestion using its new script."

1. **The inbox PR is the next thing to finish, and the first filing of an inbox note follows its
   merge**, using its script. → leafy-finch.

The assistant had explained that PR #462 makes CI's transcription check fail a filing PR naming an
issue without the `inbox` label, the same rule `tools/inbox.py` holds, and that the other way to
make the two agree was to let any issue the player opened be filed; it had marked the stricter rule
open to overturn. The player answered:

> "if an issue has no inbox label it shouldn't get filed"

2. **An issue without the `inbox` label is never filed**, whoever opened it. → leafy-finch.
