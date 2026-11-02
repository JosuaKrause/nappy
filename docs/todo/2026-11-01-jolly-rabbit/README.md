priority: later
after: 2026-10-18-minty-quail

# jolly-rabbit — Name the refactor's build records instead of numbering them · filed 2026-11-01

[plaid-penguin](../../playtests/2026-11-01-plaid-penguin.md), #937: "the whole point of the name system was to not use numbers. if it's only for the refactor let's wrap up with what we have but in general a numbering system is bad and you know why".

**Context.** `tools/new-name.sh decision --entry <entry>` draws a build record named `<entry>-2`, `-3` and on when the entry's record exists. Two PRs built in parallel drew the same next number four times in one day (#919, #921, #925, #929) and one had to renumber each time. The player's answer on the board declined a number-aware fix to the script.

**Read as:** the refactor (minty-quail) wraps up with the numbered records it has. After it is done, the numbered build records that `tools/new-name.sh decision --entry <entry>` draws (`<entry>-2`, `-3`, and on) are named instead, so no record name is a number drawn on two branches at once. The band is the filer's proposal, since the player named none and the note is not from playing; it waits on the refactor because the player asked for the refactor to be wrapped up with what it has.

**Proposed, not asked for:** a build record named `<entry>-<adjective>-<animal>`, drawn like any other name. The plainer alternative is to leave `--entry` as it is and only stop numbering new kinds of thing.
