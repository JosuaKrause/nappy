# mossy-rabbit — The citation check reads every citation inside one pair of parentheses · 2026-11-11

**The ask.** The rules review found that `tools/check_citations.py` read nothing after a comma
inside one pair of parentheses, so a wrong second citation went unflagged where the same citation
alone was caught (amber-ibis's item, moved to this entry when the player answered "split it",
inbox #1348 in grassy-trout). Not the player's request: a defect the review named, filed by the
orchestrator.

## What was built

- **Every citation-shaped piece inside one parenthesis or `;`-part is checked**: a hyphenated name
  with an optional number or `#N` list, at the part's start, after a leading `and`, or after `, `,
  `, and `, `, see `, `, also ` or ` and `. `(woolly-finch 35, woolly-finch 36)` checks both.
- **Prose is not read as a citation**: two bare names joined by `and`, neither with a number
  (`a well-known and long-standing one`), are prose, and a number list inside one citation
  (`brisk-heron 1, 13`) stays one citation. A bare name beside a citation is still checked, so a
  misspelt name is flagged without resolving it.
- **`inbox #N in name` lists needed no change**: their own pattern already read each one.
- **Four citations the old check never read are now read**, and the tree passes; the one piece of
  prose newly flagged, a job name in the release reference, is written as code.
- Unit cases, each naming the mutation it fails, and the docstring and the using-tools row say what
  is read and what a writer avoids.

## Choices open to overturn

- `and`, `see` and `also` are separators beside the comma and the semicolon; `or`, `&` and free
  text before a name are not, so a piece after them is unread (the builder's).

## Verified

The whole-tree run over `CLAUDE.md` and every skill passes under the stricter check. `./tools/pycheck.sh` and `./tools/lint.sh` pass.

