Reproduce a car accident's halo covering its cars and restore the outline behind the actual
car pictures. Inspect `EntityHalo`, `EventScenery` and the crash's split drawing before choosing
a fix: both painter order and an offset silhouette can make a halo appear on top, and the
report does not distinguish them. Preserve which influence triggers the halo and the cars'
collision shapes. A before/after picture must show the outline and car surfaces together;
add a focused ordering or placement assertion only if it can establish the diagnosed defect.
