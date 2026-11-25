# The boundary probe writing the runtime's named world

The runtime suite's boundary probe writes the runtime's named world, a state no game path writes,
so the probe stands on the runtime's own fixture rather than on a scene a recipe could build. It
wants a scene recipe actor that needs no city (a recipe actor is added through
`Crowd.add_recipe_actor()`, which only the recipe runtime calls), so that the probe goes through the
runtime's own recipe path and writes nothing by hand.
