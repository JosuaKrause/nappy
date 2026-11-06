# Comments state the rule, not its history

A comment that carries citations of inbox numbers, quotes, playtests, dates or PRs, history phrasing
("PR #781's review 3", "any more", "the review finding this exists to fix") or a 30-50 line doc
block arguing the history is against `CLAUDE.md`'s present-tense rule. The comments of the three
events files (`event_instance.gd`, `event_catalogue.gd`, `event_def.gd`) state the rule; every other
file a refactor PR touches has its comments brought to the same rule in that PR.

**Build:** in each file a PR touches, state the rule in a sentence or two with one citation, and move
the history to the decision records.
