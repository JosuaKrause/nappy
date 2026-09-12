# Escape interior graphics review

`source-sheet-1x.png` and `source-sheet-3x.png` render every changed SVG with Godot's
`Image.load_svg_from_string()` at native size and three times native size. Each individual source
PNG is beside the sheets.

`stair-assembly-e-w-1x.png` and `stair-assembly-e-w-3x.png` are fitted source composites of one
east-descending half-flight joining its west-descending return. The floor-landing strip occupies
the door, landing and joining-corner cells; the turn platform occupies its direction-specific
cleared two-by-three-cell box. They review source registration and rail joins, not runtime motion.
