**Two reads the guard now refuses or asks about are settled** (#448's review, findings 4 and 5;
[busy-ibis](../../playtests/2026-10-03-busy-ibis.md), statement 6: "let's discuss the findings
further").

- `git -C $(git rev-parse --show-toplevel) log --oneline | grep merge` was allowed before #448 and is
  denied after it, only because `merge` appears later as a grep pattern. Once #429 (a quoted
  argument of a text-only command is not a command) and #453 are on `main`, check it again: if it
  is still denied, count only write words in command position, or add it to the frosty-pelican
  record's accepted false denies as an example.
- With the switch on, `git push --dry-run`, `git commit --dry-run` and `git rebase
  --show-current-patch` are asked about though they write nothing (on a machine with identities
  they were already denied). Either let them through as reads, or list them with the accepted
  false denies.

**Proposed, not asked for:** both choices are the builder's, said in the PR.
