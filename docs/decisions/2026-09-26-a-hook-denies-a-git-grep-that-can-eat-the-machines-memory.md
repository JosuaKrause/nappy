## A hook denies a `git grep` that can eat the machine's memory · built 2026-09-26

*(2026-09-26, after the player's machine kernel-panicked: "let's create a hook for git grep.")*

**The incident.** At 06:22 EDT on 2026-09-26 the player's 16 GB Mac panicked on a watchdog timeout
with its memory compressor full. A read-only search sub-agent had run `git grep -n -i
"…wrap.*corner…" <branch> -- docs/`, in a loop over six branches. The kernel log shows it killing
`git` at about 80 GB six times, once per branch, before it found nothing left to kill. Nine
implementation agents died with the machine.

**What the measurement showed** (every probe capped at 1–2s): the cause is a missing `-I`, not the
regex, the tree or the number of trees. Without `-I`, `git grep` runs its pattern over every blob,
the evidence images included: over `docs/` it passed 2.7 GB in 2s and kept growing. With `-I` the
same search finished at about 850 MB, and with a text-only pathspec (`-- 'docs/*.md'`) at 16 MB.
BSD `grep -r` stays flat at a few MB and needs no guard. The full table is in PR #377.

**What is built.** `.claude/hooks/git-grep-guard.sh`, a `PreToolUse` hook on `Bash` and `Monitor`
(which runs a shell command too) in `.claude/settings.json` and, through `tools/codex-hooks.py`, on
Codex's shell calls, which reach its hooks as `Bash` with the command in `command` (measured with a
live Codex CLI 0.157.1 run; the adapter also reads a `cmd` field as a fail-safe no payload has
been seen to carry). It denies a `git grep` (including `git -C <dir> grep`, `git --no-pager grep`, a full path to
git, in a loop, after `&&`, `;` or `|`, or in `$(…)`) that has neither an effective `-I` nor a
pathspec restricted to a known list of text extensions. `-I` is read the way git reads it: the last
of `-I` and `-a`/`--text`/`--no-text` wins, and an `-e`/`-f` argument is never a flag. An exclusion
pathspec, in any magic spelling (`:!`, `:^`, `:/!`, `:(exclude)`), is never text-only. The reason
tells the model the rewrite.

It reads the raw command text three ways and denies if any reading matches: quotes deleted, quotes
replaced by spaces, and quotes honoured. So a wrapper (`timeout`, `sudo`, `find | xargs`), a heredoc
fed to an interpreter, quoted code run by one (`bash -c`, `python3 -c`, an f-string) and a mention
all deny. What still passes is a `grep` that is not its own word after `git`: `git log --grep=…`,
`git log -S grep`, `git … | grep`, the bare word `git-grep`, and "git, grep" in prose. All three
readings are linear in the text's length, and a command over 32 KB holding both words is denied
before they run, which keeps the densest text at about 1.2s against the hook's 10s timeout, the
same as the other hooks'. Claude Code's hooks documentation says settings hooks
fire for a sub-agent's tool calls too, which is what ran the command. A hook added to
`settings.json` runs only once the player has approved it through `/hooks`.

**A mention denies, against the brief.** The orchestrator's brief said not to deny a command that
only mentions the words (`echo "git grep"`, a commit message, `rg "git grep"`). The build denies
them, because every reading that let a mention through also let through a real call hidden in
quoted code or a heredoc, and a missed call costs a machine while a false deny costs a rewrite.
Open to overturn; the player keeps it for now, a mention written as one hyphenated word
*(2026-09-26, [2026-09-26-curly-quail](../playtests/2026-09-26-curly-quail.md), statement 5)*.

**Tried and rejected on the way**, each found by a review: a tokenizer with a closed list of
boundary words (a newline or an unknown wrapper ended a command early); a quote-opaque parse that
skipped heredoc bodies (the call inside `bash <<EOF` passed); a single quote-deleting reading (it
glued the character before a quote onto the next word, so `f"git grep …"` and `cmd="git grep …"`
passed); a bash tokenizer, which ran past the 5s timeout at about 20 KB; and a quote-honouring
reading that appended to an array in its state, quadratic in the number of words, so dense
short-word text ran past the 10s timeout at 128 KB.

**Accepted holes**, each needing a deliberate step; the hook's header holds the full list. Among
them: a shell or git alias, a `git` or `grep` assembled by an expansion (`$(echo gi)t grep`), an
encoded command, a command kept in a file the command runs (`bash x.sh`), and an attributes file or
`--attr-source` that marks binaries as text.

**Choices open to overturn**: a revision-less `git grep` gets no exemption, since the working tree
without `-I` grew fastest of all; several trees on one line get no rule of their own, since the
branches share blobs; the extension list is explicit, so `-- '*.png'` is denied; any long pathspec
magic (`:(glob)*.md`) and a text pathspec that also carries an exclusion are false denies.

**A review found `Monitor` unguarded**, and a second guess that Codex sent its commands as
`exec_command` with a `cmd` field was disproved only by running Codex. That is why a change to a
hook now checks whether Codex's side is affected (a new tool name, payload field or hook event)
and updates the adapter, `.codex/hooks.json` and their tests in the same PR when it is *(2026-09-26:
"okay, yes this is important to keep up to date")*; the rule is in `CLAUDE.md` and python-tooling.
