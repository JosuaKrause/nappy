# Playtest minty-rabbit — The board's answers on polite-tapir, the test city cache and revealed reads; which model designs, builds and reviews; one Fable at a time

2026-11-12.

## #1427

1. **The note.**

   > yes

2. **Context** (the assistant's):

   On the Nappy board, question fable-polite-tapir: "may polite-tapir's Fable work start, with placement by construction first? (blocks the rest of minty-quail)". My pick was: start polite-tapir with placement by construction.

3. **Read as:** (the assistant's interpretation, not the player's words)

   Polite-tapir's Fable work may start, placement by construction first. The player said to end this session first, so the next orchestrating session starts it.

## #1428

1. **The note.**

   > A

2. **Context** (the assistant's):

   On the Nappy board, question copy-cache: what happens to `CityMap.copy()`, which only the tests' city cache (`tests/city_map_cache.gd`) uses? A: keep it public with a [kept] line giving the tests' city cache as its reason; B: delete it; C: a game reader in main.gd. My pick was A.

3. **Read as:** (the assistant's interpretation, not the player's words)

   `CityMap.copy()` moves from the [no reader] group to a [kept] line whose reason is the tests' per-process city cache.

## #1429

1. **The note.**

   > B but why would it leave the file untyped? it should get picked up eventually if not immediately

2. **Context** (the assistant's):

   On the Nappy board, question revealed-reads: may a typing pass add a line to the field-read list (tools/field_reads.txt) for a read that typing a file reveals, one that was there all along? A: allow it; B: as done so far, the typing pass converts such a read to a method, or leaves the file untyped. My pick was B.

3. **Read as:** (the assistant's interpretation, not the player's words)

   B: the field-read list keeps only shrinking. A file left untyped by a typing pass is not abandoned: it keeps its opt-out line on the list of opt-out files, which only shrinks, and its area's pass, or a later typing pass, types it and converts the read.

## #1432

1. **Context** (the assistant's):

   Said in the orchestrating session of 2026-11-12. The player had told the session to use only one Fable agent at a time, never in parallel. The session had briefed a Fable agent to design and write the code of polite-tapir's RowGround seam (the event scheduler's breakup), and when asked what the rule on Fable is, quoted the orchestrating skill's model table: "A task that needs planning or complex reasoning | Fable is considered"; "A pull request labelled fable-only ... | Fable designs its code and reviews it; writing the code may go to another model"; "The review of anything Fable designed | Fable". The first quote asked where that allows Fable builders. The session answered that no rule asks for a Fable builder: the label's definition in the player's words (inbox #1299 in grassy-trout, statement 15) is "the label means that fable does the design and review (but can hand off coding)", which the session had read as letting Fable write the code. It proposed letting the running RowGround agent finish and, from DawnContext on, a Fable agent designing, an Opus agent building and a fresh Fable agent reviewing. The second quote answered that.

2. **The note.**

   > where does it allow fable builders?

3. **The player's words.**

   > the reason it says "can" is because fable might decide that the coding is too complex

4. **Read as:** (the assistant's interpretation, not the player's words)

   On a fable-only pull request the Fable agent that designs the code decides who writes it: it hands the coding to another model unless it judges the coding too complex to hand off, and then writes it itself. The orchestrator does not make that choice in the brief, either way. The model table's row says only that writing "may go to another model" and not who decides, which let the RowGround brief decide for Fable.

5. **The player's words.**

   > otherwise always use the lowest model that can do it

6. **The player's words.**

   > building doesn't need a strong model if the plan was strong

7. **Read as:** (the assistant's interpretation, not the player's words)

   When the Fable designer hands the coding off, the code goes to the lowest model that can do it, not to a fixed stronger one: a strong plan is what lets a weaker model build it. The orchestrator's proposal that an Opus agent build DawnContext from Fable's design is replaced: the designer judges whether the coding is too complex to hand off, and a handed-off build goes to the lowest model able to do it. The same holds for any build made from a strong plan, the plan being what the build's strength comes from.

8. **The assistant's comment:**

   Does "always use the lowest model that can do it" also reach the choices that are not building: reviews, investigations, measuring?

   - What it answered: the Fable designer of a fable-only pull request decides whether the coding is too complex to hand off; otherwise it is handed off, and "building doesn't need a strong model if the plan was strong".
   - Building is settled by those words: a build from a strong plan goes to the lowest model that can do it, so the table's "Opus for a build that changes play, or builds a seam from its design" stops being the default.
   - If it reaches every choice: the other uncited rows (Opus to investigate an unexplained result, Opus to review a play-changing or design PR) become ceilings, and each brief picks the lowest model that can do the task. The cited rows stay: drawing is Opus's (PLAYTEST-123 8), and a review of anything Fable designed is Fable's.
   - If it reaches building only: reviews and investigations keep the table's models.
   - My pick: every choice, since the words say "always" and the table's own rule is that the model is chosen by judgement (woolly-finch 15). Until you answer, I apply it to building only, which is certain either way.

9. **Context** (the assistant's):

   Said in the session right after the orchestrator asked, on this issue, whether "always use the lowest model that can do it" also reaches the choices that are not building (reviews, investigations, measuring), with its pick "every choice" and building-only until answered.

10. **The player's words.**

    > design (and by that I mean *detailed* designs) and reviews in general are where stronger models should be used

11. **The player's words.**

    > (reviews have their own decision points, though)

12. **The player's words.**

    > (some reviews don't need a strong model)

13. **Read as:** (the assistant's interpretation, not the player's words)

    The answer splits the work by kind. A detailed design, the kind a builder works from and not a sketch, takes a stronger model; building, and everything else that is neither a design nor a review, takes the lowest model that can do it, since a strong detailed design is what lets a weaker model build. Reviews are where stronger models go in general, but which model reviews a given pull request keeps its own decision points: the model table's review rows (a review of anything Fable designed is Fable's; Opus for a play-changing or design pull request, one carrying a drawing, or a change to what a rule says; Sonnet for a queue update, docs, a skill's wording alone or a small delta). So the table's build rows stop defaulting to Opus, and its review rows stand as they are.

14. **Context** (the assistant's):

    Said in reply to the orchestrator's summary of this note in the session, whose first bullet read "Detailed designs (the kind a builder works from) take a stronger model."; the player's words quote that bullet and answer it. The reading appended before this one said the same ("A detailed design, the kind a builder works from and not a sketch, takes a stronger model") and is replaced by the reading below.

15. **The player's words.**

    > Detailed designs (the kind a builder works from) take a stronger model. -- you got that backwards. the designs must be detailed always

16. **Read as:** (the assistant's interpretation, not the player's words)

    Replaces the earlier readings' design clause. A design is always detailed, the kind a builder works from; "detailed" is not a class of design that earns the stronger model while a sketch would not. Designing is work for a stronger model, every time. Building, and everything that is neither a design nor a review, takes the lowest model that can do it, since the detailed design is what lets a weaker model build. On a fable-only pull request the Fable designer decides whether the coding is too complex to hand off. Reviews keep the model table's own review rows, and some need no strong model.

## #1433

1. **Context** (the assistant's):

   The player's opening message of the orchestrating session of 2026-11-12, which continued from the last session's restart note. The next queued work was polite-tapir's (fable-only), and the orchestrating skill's model table puts no limit on how many Fable agents run at once. The session ran one Fable agent (the RowGround builder) and gave every other agent of the session to Sonnet. Whether the limit holds for this session only or as a standing rule for the model table is not said.

2. **The note.**

   > orchestrator, continue. please use only one fable at a time and not in parallel.
