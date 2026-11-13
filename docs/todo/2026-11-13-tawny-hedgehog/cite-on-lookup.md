# `tools/inbox.py cite` doubles a citation wrapped across a line, and writes when run to look one up

**What goes wrong, twice over.**

- **A citation wrapped across a line is cited twice**, in two shapes, since `cite_line()` reads one line at a time:
  - **The run breaks after "and"**, as in the records minty-quail-quiet-swan and minty-quail-tall-lynx ("(inbox #1159
    and" ending line 4, "#1156 in gray-dolphin)." opening line 5): the first line's "inbox #1159" looks unnamed, so it
    becomes "inbox #1159 in gray-dolphin and" and the run names the playtest twice. `cite --dry-run 1159` on `main`
    shows the doubled edit in both records and lists the same sentence in minty-quail-curly-hawk and -fluffy-newt for
    a hand fix.
  - **The line breaks after the citation's own "in"**, the name opening the next line ("inbox #1432 in" /
    "minty-rabbit", in `.claude/skills/orchestrating/SKILL.md`): `ALREADY_IN`, which looks for ` in <name>` after
    the citation on the same line, finds no name, so a second ` in minty-rabbit` goes in ("in minty-rabbit in").
    `cite --dry-run 1432` on `main` shows it.
- **An agent that wants to know where a note was filed runs `cite N` and edits the tree.** Two sessions did:
  `cite 1159` edited the two records above in the main checkout, and `cite 1432` edited
  `.claude/skills/orchestrating/SKILL.md` in a review checkout. The reviewer undid the second; the first stood
  uncommitted in the main checkout until the player reset it.

**What is fixed.**

- A citation wrapped across a line is read as one run, in both shapes above: a run continued on the next line (the
  line ends inside `inbox #N, #M and`, the next line starts with `#K`) gets no ` in <name>` when its end already
  names the playtest, and one ` in <name>`, after its last number, when it names none; and a citation whose ` in`
  ends the line, with the name opening the next, counts as already cited. Each shape is a fixture in
  `tools/test_inbox.py` (the 1159 records and the 1432 sentence), and a second run over the fixed text changes
  nothing.
- **Proposed, not asked for:** `cite` writes only with `--write`; without it, it prints what `--dry-run` prints today
  (the diff and the hand-fix list), so a lookup can no longer edit. `--dry-run` stays, as the same as no flag.
  `.claude/skills/inbox/references/filing-a-batch.md` and the tool's `--help` say `--write` where they say to edit.
  Plainer alternative: keep `cite` as it is and add a warning to the inbox skill, which leaves the trap armed.
