# The trailer's walks turn smoothly

Once the smooth option exists, turn it on for every scene recipe the trailer's shot list
(`tools/trailer/shots.json`) uses, and check that each scene's validation still passes with
`tools/trailer.sh --validate`; a scene whose timed event or capture moment depended on the
abrupt path's timing is retimed and named in the PR. Render the selected cut again
(`tools/trailer.sh --selected` into a fresh output directory, as the README's trailer paragraph
says), and put a short burst or the new movie's link in the PR description so the player can
compare the turns. Uploading the new cut to YouTube is the player's.
