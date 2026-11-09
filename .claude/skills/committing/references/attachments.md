# Attachments in a pull request

The alternative to committed media that **committing**'s "A PR description never links a file by
branch name" names. Read it before relying on an upload in place of a committed picture.

GitHub-hosted attachments are an alternative to committed media: dragging an image or video into
the PR text box uploads it and supplies its URL. GitHub also documents `--attach` for PR creation,
editing and comments in [Attaching files with GitHub CLI](https://docs.github.com/en/github-cli/github-cli/attaching-files-with-github-cli).
Check that the installed CLI and the required agent identity support that route before using it.
The [CLI upload token allowlist](https://github.com/cli/cli/blob/2c7ec97fddb8da331803e18e8c33395a3b6537ee/internal/attachments/client.go#L65-L79)
excludes, at that pinned commit, the GitHub App installation tokens this repository's bots use,
so changing the apps' permissions does not enable that CLI route; check the current allowlist
before relying on it either way. The player can upload through the browser. Attachment uploads
follow the same identity and publication authorization rules as other PR writes, and issue writes
still use `tools/inbox.py`.
