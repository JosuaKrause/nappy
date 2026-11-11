# The citation check reads a second citation after a comma

`tools/check_citations.py` checks the citations of the player's words in `CLAUDE.md` and the
skills. Inside one pair of parentheses it reads nothing after a comma: in a pair holding two
citations separated by a comma, a wrong second number is not flagged, where the same citation
alone in parentheses is.

**Build:** every citation inside one pair of parentheses is checked, whatever separates them, with
a test case for a wrong second citation.
