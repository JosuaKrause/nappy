# minty-quail — The map fixtures go through the map's own writers, and the building's front pieces become internal · 2026-11-06


minty-quail's `tests-unseen-reads.md` section 2.3, the five fixtures that wrote a map's tile state
by hand where no game writer could, and `tests-own-class-members.md`'s first owner, the building's
ground-floor pieces, under the player's rules that a test reaches the game only as the game does
(curly-rabbit #1095), that a member only its own class and the tests use becomes internal and is
tested through what the class does outward (curly-rabbit #1098), and that a check whose setup only
a test can make is removed (curly-rabbit #1097).

**Built.** `test_turns.gd`'s junction-box barrier, two-tile plug and lane stubs are bodies stood
through `obstruct_tiles()`, which cars treat as they treat closures (`CarStrategy.cannot_go_on`),
since `close_streets()` closes only a segment between its mouths and never a junction box's tiles.
`test_still_watch.gd` takes the lights' junction from the generated map's own main road (seed
4242). `test_scene_recipe_stretch.gd`'s red-arrow counterexample runs on the real scene's map: task
7's stretch has no hidden shortcut, so the counterexample is a target on hidden cut-off ground that
the walk ranks nearer than the one on the street. The building's front is read off a recording
front drawer by where each picture was put (`tests/front_reads.gd`), in the ground-floor,
city-decay, blackout, home-block and placement suites, and seventeen of its front members took the
underscore; `City.assign_roof_extensions()` lost its only test reader and left the list.

**Removed.** The 16-tile alley in the alley-siting suite, since no generated alley is longer than
8 tiles; the door and fire-escape stream replays, which re-ran the private
rolls; and the read-backs of the extension rows past the end, replaced by a check that each
column's roof is drawn as tall as its extension. Some per-column checks folded into one stronger
"no facade drawn" check over a covered column.

**The power station's yard, after review.** The hand-placed yard fixture went at first on the
claim that no front stands over a yard; the review found one does: a cul-de-sac wall
(`CityGenerator._wall_off_one_end()`) can close the street just north of the station, in about one
city in forty. The ground-floor suite reads it off generated cities: over the yard (seed 823576)
the wall keeps its facade and the station draws no roof there, and over the hall (seed 966118) the
wall is covered and the station's roof is drawn as many rows taller as the wall is high.

**Open to overturn.** Body obstruction stands in for a closure in the turns suite. The shared
helper rather than one reader per suite. The building's window and roof
pieces stay public until a build owns their suites.
