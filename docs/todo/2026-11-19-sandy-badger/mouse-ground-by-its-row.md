# The mouse's ground is the row's answer, not a branch on its id

`RuledLocationGround` asks whether a row is the mouse (`_MOUSE_ID`) to decide something about its ground. That
decision becomes a question the row answers (a method on `EventDef`, declared by the mouse's row in the catalogue),
so the location ground asks the row and names no row's id. The builder reads the two branches first and says what
the question is; nothing a player sees changes, and the mouse's placement tests hold it. `ruled_location_ground.gd`
is also a file of row 3a's first pull request (minty-quail's `event-interface.md`), so this starts after that merges.
