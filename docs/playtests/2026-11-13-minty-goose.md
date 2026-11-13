# Playtest minty-goose — Bug fixes have their own lane, which the rules already say

2026-11-13.

## #1445

1. **Context** (the assistant's):

   Said in the orchestrating session of 2026-11-13, answering the question bug-passes-the-fence, which the orchestrator put in chat (the board connector was failing) as:

   > **Still open:**
   > - **Your answer to `bug-passes-the-fence`:** A, bug fixes go ahead of the refactor too, or B, they wait behind it. My pick is A. It decides the last item left in tawny-hedgehog, the bugs-go-first skill change. The board connector is still down, so answering in chat works.

   The question's fuller statement, from an earlier message: "Does a bug fix start ahead of polite-tapir, the refactor you put first, or only ahead of the rest of the queue? A: bug work skips that fence and is started, reviewed and merged ahead of everything; a queue update still merges first. The cost is that a fix in code the refactor is rewriting may have to be redone. B: the `bug` band as it is today: bugs lead the queue but wait behind an entry you put first." It answers "remember those get highest priority" (amber-goose #1442), the item `docs/todo/2026-11-13-tawny-hedgehog/bugs-go-first.md`. "The tool/skill/claude/rule rule" is the orchestrating skill's rule that work on how the project is worked on (a skill, CLAUDE.md, a rule, a hook, a general project script) goes first (inbox #1305 in grassy-trout).

2. **The note.**

   > Your answer to bug-passes-the-fence: bug fixes have their own lane. a bug fix for a tool goes immediate as per the tool/skill/claude/rule rule

3. **Read as:** (the assistant's interpretation, not the player's words)

   Neither A nor B as put. A bug fix is work of its own lane: it is started at once, beside whatever else runs, and is neither held back by the fence of an entry the player has put first nor ordered behind the queue's bands; it does not stop the entry put first either. A bug in a tool, a skill, CLAUDE.md or a rule is work on how the project is worked on, and goes first under that rule, as the inbox.py cite fix did. The orchestrating skill states this lane in place of the bugs-go-first item's proposal that bug work goes ahead of everything.

4. **Context** (the assistant's):

   Answering the orchestrator's next message, which said: "**Do you want me to file #1445 now?** Filing it in the same pull request as the skill change would put this lane into the orchestrating skill and `docs/TODO.md`, with an Opus review. Bug work going ahead of everything was only my proposal, so this replaces it. I file notes only when you ask, so say "file it" and I'll do both in one pull request."

5. **The player's words.**

   > you can file it but is a correction anywhere really necessary? nothing from that was new information

6. **Read as:** (the assistant's interpretation, not the player's words)

   File the note, and change no rule: the bug band's place above now is already the player's (mossy-ferret #710) and a tool's bug already goes first as work on how the project is worked on (inbox #1305 in grassy-trout). The item bugs-go-first, the filer's proposal that bug work goes ahead of everything, is dropped, and with it the entry tawny-hedgehog closes.
