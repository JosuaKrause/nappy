`CLAUDE.md` states the rule that it and the skills link the player's words rather than quote them.
Every quote of the player in `CLAUDE.md`, `.claude/skills/**` and their references becomes a short
link to the playtest file (or, where none holds the words, the file that does) that records it; the
sentence around it still says what the rule is and why. Nothing a rule says is lost: a reviewer reads
each changed rule before and after. `./tools/lint.sh` passes on every touched file.
