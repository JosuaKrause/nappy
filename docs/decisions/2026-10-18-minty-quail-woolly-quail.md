# minty-quail — Which other classes' fields a set of files reads, and which method answers each, is a tool · 2026-11-11

**The ask.** Every typing pass of the tests layer owes, in its record and description, the list of
other modules' fields its files read or write, each with the method the game calls that answers it
or "no method" (the scoping rule of the rethink on #1342). Built by hand, that list came back
*not ready* on most passes: inner classes missed, getters missed, an inherited getter missed, and a
method credited that returns a derived value. A manual sequence done a second time becomes a script
(woolly-finch 23).

## What was built

- **`tools/field_answers.py`** takes `.gd` files, or a brief whose "Your files" paragraph names
  them, and prints one Markdown line per class under `src/`, inner classes as `Outer.Inner`: each
  field the files read or write through a receiver of that class, read or written, the files and
  lines, and the answer. `--json` gives the structured form, `--counts` the short one, `--rev` reads
  a commit without a checkout. Its `--help` says what it sees and what it does not.
- **One rule decides an answer**: a public method's body and a read are each brought down to the
  value they stand for (a field, a chain of fields, a call handed on, or an expression), and equal
  values answer each other. A null-guarded return, a chain (`plan.def.id` and `row_id()`), a
  read-through, a handed-on call and a property whose getter equals a method all answer; a derived
  value does not.
- **An inherited field** is listed under the class that declares it, names the receiver's class, and
  is answered from the receiver's class and all its bases (the map's `size` through `CityMap`,
  answered by `WorldMap.size_in_tiles()`).
- **A write** lists every public method that assigns the field, with the statement, for the builder
  to judge. **A call count** is by the receiver's class, game calls under `src/` outside the
  declaring file. **A receiver whose class it cannot tell** gets a line of its own, never a guess.
- **The field-read check's reader is reused**, by import and a subclass, through two override points
  added to `tools/check_field_reads.py` whose behaviour and list are unchanged.

## Choices open to overturn

- **A yes-or-no method on the field alone** (`is_in_the_world()` for `live != null`) is printed
  apart from the answers, never as one (the builder's).
- **Private methods are never answers**, and tests' calls are never counted (the builder's).
- **A chain's read is listed once**, under the class whose method answers it (the builder's).

## Left, each with its reason

- **The field-read check's own reader keeps the blind spots this tool fills** (scripts with no
  class name behind a preload, another file's inner class, a dot that opens a continuation line):
  moving them into the check would grow `tools/field_reads.txt`, a decision of its own.
- **The typing briefs and `typed-everywhere.md` name the tool** in the next queue update.

## Verified

Run on six typing passes' files at their reviewed heads, the tool reproduced every review finding
and missed no read a review found; the comparison is in pull request #1366's description.
`./tools/pycheck.sh`, `./tools/lint.sh` and `./tools/check.sh` pass, and `tools/field_reads.txt`
is reproduced byte for byte.
