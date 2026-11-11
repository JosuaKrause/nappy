# mossy-rabbit — The citation check reads every citation inside one pair of parentheses · 2026-11-11

**The ask.** The rules review found that `tools/check_citations.py` read nothing after a comma
inside one pair of parentheses, so a wrong second citation went unflagged where the same citation
alone was caught (amber-ibis's item, moved to this entry when the player answered "split it",
inbox #1348 in grassy-trout). Not the player's request: a defect the review named, filed by the
orchestrator.

## What was built

- **A numbered name is read wherever it stands inside a parenthesis**, after words too: a
  hyphenated name with a number or a `#N` list (`woolly-penguin #759`, `PLAYTEST-16 7`,
  `(the rule is gentle-owl #1255)`). A name needs a letter, so a range or a date is never one.
- **A bare name is read only as a piece of a list**: it starts the part (or follows a leading
  `and`), or follows `, `, `, and `, `, see `, `, also ` or ` and `, and is followed by a comma, the
  part's end, or `and` with another piece. `(woolly-finch 35, woolly-finch 36)` checks both, and a
  misspelt bare name beside a citation is flagged without resolving it.
- **Two bare names joined by `and` are prose and are not read**, judged by what the `and` joins;
  a bare name joined by `and` to a numbered one is read. A number list inside one citation
  (`brisk-heron 1, 13`) stays one citation.
- **`inbox #N in name` lists needed no change**: their own pattern already read each one.
- **Five citations the old check never read are now read**, and the tree passes; the one piece of
  prose newly flagged, a job name in the release reference, is written as code. A hyphenated word
  standing alone after a separator is flagged, and is reworded or marked with a `lint-allow` comment.
- Unit cases, each naming the mutation it fails, and the docstring and the using-tools row say what
  is read and what a writer avoids.

## Choices open to overturn

- `and`, `see` and `also` are separators beside the comma and the semicolon; a bare name after
  `or`, `&` or free text, or followed by words, is not read (the builder's).

## Verified

The whole-tree run over `CLAUDE.md` and every skill passes under the stricter check. `./tools/pycheck.sh` and `./tools/lint.sh` pass.

