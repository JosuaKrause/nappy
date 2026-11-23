# minty-quail — Location.section and EventPlan.ends go private (tests-own-class-members) · 2026-11-23

**What was asked.** `tests-own-class-members.md`: a member only its own class and the tests use becomes internal, its
tests checking what the class does from outside (curly-rabbit #1098). Built as #1662 by a Sonnet agent, for a location's
section and a plan's ends.

**What was built.** The location's `section()` is deleted, since it only returned its field, and its tests ask whether
two locations share a section; the plan's `ends()` is private, asked only by its own gap measure, and the spacing
suite's oracle builds the same bounds from the plan's walk and its body. The spacing suite compares no two routes, so it
does not ask the private ends at all, as it did not before.

**Measured.** Check counts unchanged; each rewritten check was shown failing with the rule it holds broken.
