# The field-list tool tells what it cannot answer

`tools/field_answers.py` builds a typing pass's list of other modules' fields
(`typed-everywhere.md`). Its review found three places where it says less than it should, none of
which changes a line it prints on a file in the tree today.

- **A class nested inside an inner class, named through its outer class** (`Outer.Deep.new()`, or a
  cast such as `(x as CountedCrowd.Source)`), is taken for an engine value and gets neither an entry
  nor a "not told" line, though `--help` says such a receiver is told. It gets its "not told" line,
  as a nested class reached any other way does.
- **A number's truthiness reads as a null test**: `return loud if loud else D`, with a non-zero
  constant `D`, is credited as returning `loud`. Such a method is printed behind its guard, as a
  stand-in is, or `--help` names the case among what the tool does not see.
- **Four rules of its guards and views have no case that fails without them**: every part of a
  guard joined by `and` tests the returned chain; a view is looked for only where the class has no
  answer; a private method does not hand a view out; a guarded chain is not looked for where the
  field is answered. Each gets a case.
