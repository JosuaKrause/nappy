# Comments state the rule, not its history

`event_instance.gd` is 44 percent comment lines (3,210 of 7,342), with citations of inbox numbers,
quotes, playtests, dates or PRs, history phrasing ("PR #781's review 3", "any more",
"the review finding this exists to fix"), 30-50 line doc blocks arguing the history, a sentence
spliced mid-paragraph (`event_instance.gd` near 2542), and a doc contradicted by the code (near 2360,
`chatting_mother` "can never detain a second time"). That is against `CLAUDE.md`'s present-tense rule.

**Build:** in each file a PR touches, state the rule in a sentence or two with one citation, and move
the history to the decision records.
