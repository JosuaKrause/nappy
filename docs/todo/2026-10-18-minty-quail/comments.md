# Comments state the rule, not its history

`event_catalogue.gd` and `event_def.gd` are more than half comment lines, with citations of inbox
numbers, quotes, playtests, dates or PRs, history phrasing ("PR #781's review 3", "any more", "the
review finding this exists to fix") and 30-50 line doc blocks arguing the history. That is against
`CLAUDE.md`'s present-tense rule.

**Build:** in each file a PR touches, state the rule in a sentence or two with one citation, and move
the history to the decision records.
