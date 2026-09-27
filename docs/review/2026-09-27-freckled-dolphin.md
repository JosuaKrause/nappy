# freckled-dolphin — Create the three agent apps and post as each · 2026-09-27 · not from an entry

**Create the three agent apps, on your own machine, and post one comment as each.** This is a job
for your local Claude or Codex with you at the browser; a cloud session cannot do it, since its
proxy blocks the API calls and it has no browser. In the checkout, with `uv` installed and your
browser logged in to GitHub, run `uv run python tools/agent-identity.py create claude-coder
claude-reviewer codex-coder`. For each app a browser tab opens on GitHub's "Create GitHub App" page
with the name and permissions filled in: click **Create GitHub App**, and on the page that opens
next install it on **only** the `nappy` repository. The keys land in `~/.config/nappy-agents/`,
outside the repository. Then `uv run python tools/agent-identity.py status` should report all three
usable, and `uv run python tools/agent-identity.py run <role> -- gh issue comment <n> --body
"<role> says hello"` on a throwaway issue, once per role, should show three different bot authors.
**Do the apps get created and installed with nothing edited by hand, and does each comment show as
its own bot with its own avatar?** The GitHub calls were tested only against mocked responses
(`DECISIONS.md`, tall-egret, each agent posts on GitHub as an app of its own), so a failure here is
a bug: bring back the terminal output.
