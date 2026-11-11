# mossy-rabbit — The citation check reads every citation inside one pair of parentheses · 2026-11-11

**The ask.** The rules review found that `tools/check_citations.py` read nothing after a comma
inside one pair of parentheses, so a wrong second citation went unflagged where the same citation
alone was caught (amber-ibis's item, moved to this entry when the player answered "split it",
inbox #1348 in grassy-trout). Not the player's request: a defect the review named, filed by the
orchestrator.

## What was built

- **Every citation inside one parenthesis or `;`-part is checked**, after `, `, `, and ` or ` and `:
  `(woolly-finch 35, woolly-finch 36)` checks both.
- **A further piece counts only when it is citation-shaped**: a hyphenated name, an optional number
  or `#N` list, then a separator or the end. Prose with hyphenated words (`a well-known rule and a
  long-standing one`) is not read as a citation, and a number list inside one citation
  (`brisk-heron 1, 13`) stays one citation.
- **`inbox #N in name` lists needed no change**: their own pattern already read each one.
- Two unit cases, each naming the mutation it fails: a wrong second citation after each separator
  is flagged, and resolving second citations with free hyphenated prose pass.

## Choices open to overturn

- `and` is a separator beside the comma and the semicolon, read only when a citation-shaped piece
  follows it (the builder's).

## Verified

The whole-tree run over `CLAUDE.md` and every skill flags nothing under the stricter check, so no
skill changed. `./tools/pycheck.sh` and `./tools/lint.sh` pass.

