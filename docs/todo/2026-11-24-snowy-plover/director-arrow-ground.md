# The director's own use of the arrow ground

`ResistanceDirector._ground_for_the_arrow()` chooses the ground the resistance's red arrow points
across. Only the day suites reach it, as part of a whole day; no suite reaches it from a task scene
of several targets on a stretch, where its choice among the targets is the whole behavior, so a
change to how it chooses passes every suite. The test wants a task scene of several targets on a
stretch, built in the suite, and asks which ground the arrow takes.
