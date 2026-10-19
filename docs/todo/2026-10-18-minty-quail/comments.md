# Comments state the rule, not its history

44 to 60 percent of the events files are comment lines (`event_instance.gd` 3,210 of 7,342,
`event_catalogue.gd` 1,867 of 3,112, `event_def.gd` 1,193 of 1,854), with about 270 citations of
inbox numbers, quotes, playtests, dates or PRs, history phrasing ("PR #781's review 3", "any more",
"the review finding this exists to fix"), 30-50 line doc blocks arguing the history, a sentence
spliced mid-paragraph (`event_instance.gd` near 2542), and a doc contradicted by the code (near 2360,
`chatting_mother` "can never detain a second time"). That is against `CLAUDE.md`'s present-tense rule.

**Build:** in each file a PR touches, state the rule in a sentence or two with one citation, and move
the history to the decision records.
