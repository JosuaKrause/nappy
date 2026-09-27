**An agent captures the player's words into the inbox with a script** (statement 13). When the
player says something in a session that should outlive it — a thought for the queue, a correction
to a task — the agent opens an inbox issue with those words verbatim, in one call, before it goes
on with anything else, so the words are safe even if the session is cleared before a filing PR
exists (statement 2). Which messages to capture is the agent's judgment: there is no hook, and the
conversation is not recorded as a whole ("I don't want my entire conversation recorded. an agent
has better judgement there.").

The script runs under the agent's own GitHub identity (`tools/agent-identity.py run <role> --`,
`claude-coder` or `codex-coder`). Whether those apps may create issues is checked first; if they
lack the issues permission, adding it is the player's to do in GitHub's own settings.

**Proposed, not asked for:** the script's name, `tools/capture.sh`, and that it shares one entry
point with the inbox script of `inbox-skill.md` if that reads simpler.
