#!/usr/bin/env python3
"""Unit tests for `tools/check_closure_writers.py`, each against a small tree of `.gd` files in a temp folder."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_closure_writers

CLOSURE = "class_name RoadClosure\nextends RefCounted\n"
MAP = (
    "class_name CityMap\nextends RefCounted\n\n"
    "var _closed_tiles: Dictionary = {}\n\n"
    "func close_streets(closures: Array[RoadClosure]) -> void:\n"
    "\t_closed_tiles.clear()\n"
    "\tfor closure in closures:\n"
    "\t\t_closed_tiles[closure] = true\n\n"
    "func closed_tile_set() -> Dictionary:\n"
    "\treturn _closed_tiles\n"
)
PLANNER = (
    "class_name ClosurePlanner\nextends RefCounted\n\n"
    "static func plan(map: CityMap) -> void:\n"
    "\tvar shut: Array[RoadClosure] = [RoadClosure.new()]\n"
    "\tmap.close_streets(shut)\n"
)
ALLOWED = {
    ("src/city_map.gd", "close_streets", "ground"): "the map's writer",
    ("src/closure_planner.gd", "plan", "build"): "the planner builds",
    ("src/closure_planner.gd", "plan", "close"): "the planner closes",
}


def hits(allowed: dict[tuple[str, str, str], str] | None = None, **files: str) -> list[str]:
    """The check's findings on a tree of `src/<name>.gd` files, written to a temp folder."""
    with tempfile.TemporaryDirectory() as raw:
        root = Path(raw)
        (root / "src").mkdir()
        tree = {"road_closure": CLOSURE, "city_map": MAP, "closure_planner": PLANNER}
        tree.update(files)
        for name, text in tree.items():
            (root / "src" / f"{name}.gd").write_text(text, encoding="utf-8")
        return check_closure_writers.scan(root, ALLOWED if allowed is None else allowed)


def other(body: str) -> str:
    """A class under src/ that the planner does not reach, with `body` in one function."""
    return "class_name EventScheduler\nextends RefCounted\n\nfunc _sneak(map: CityMap) -> void:\n" + body


class CheckClosureWritersTests(unittest.TestCase):
    def test_the_allowed_sites_pass(self) -> None:
        # The map's own `func close_streets(` is a definition, not a call, and needs no line.
        self.assertEqual(hits(), [])

    def test_a_call_of_close_streets_elsewhere_fails(self) -> None:
        found = hits(event_scheduler=other("\tmap.close_streets([])\n"))
        self.assertEqual(len(found), 1)
        self.assertIn("src/event_scheduler.gd:5:", found[0])
        self.assertIn("close_streets()", found[0])
        self.assertIn("_sneak", found[0])

    def test_a_closure_built_elsewhere_fails(self) -> None:
        found = hits(event_scheduler=other("\tvar c := RoadClosure.new()\n"))
        self.assertEqual(len(found), 1)
        self.assertIn("a RoadClosure built", found[0])

    def test_a_class_extending_a_closure_at_any_depth_is_a_closure(self) -> None:
        park = "class_name ParkClosure\nextends RoadClosure\n"
        gate = "class_name GateClosure\nextends ParkClosure\n"
        found = hits(park_closure=park, gate_closure=gate, event_scheduler=other("\tvar c := GateClosure.new()\n"))
        self.assertEqual(len(found), 1)
        self.assertIn("a RoadClosure built", found[0])

    def test_an_inner_class_extending_a_closure_is_a_closure(self) -> None:
        body = "\tvar c := Sneaky.new()\n\nclass Sneaky extends RoadClosure:\n\tpass\n"
        found = hits(event_scheduler=other(body))
        self.assertEqual(len(found), 1)
        self.assertIn("a RoadClosure built", found[0])

    def test_a_recipe_closure_listed_elsewhere_fails(self) -> None:
        found = hits(event_scheduler=other("\tmap.add_recipe_closure(null)\n"))
        self.assertEqual(len(found), 1)
        self.assertIn("a recipe closure listed", found[0])

    def test_the_closed_ground_written_elsewhere_fails(self) -> None:
        for body in (
            "\tmap.closed_tile_set()[Vector2i.ZERO] = true\n",
            "\tmap.closed_tile_set().merge({})\n",
            "\tlayer.replace_closed_tiles({})\n",
            "\tlayer.todays_closed_tiles().clear()\n",
        ):
            with self.subTest(body=body):
                found = hits(event_scheduler=other(body))
                self.assertEqual(len(found), 1, found)
                self.assertIn("the closed ground written", found[0])

    def test_reading_the_closed_ground_passes(self) -> None:
        body = (
            "\tvar shut := map.closed_tile_set().duplicate()\n"
            "\tif map.closed_tile_set()[Vector2i.ZERO] == true:\n\t\tpass\n"
        )
        self.assertEqual(hits(event_scheduler=other(body)), [])

    def test_the_closed_ground_written_in_the_map_outside_its_sites_fails(self) -> None:
        found = hits(city_map=MAP + "\nfunc _sneak() -> void:\n\t_closed_tiles = {}\n")
        self.assertEqual(len(found), 1)
        self.assertIn("src/city_map.gd:15:", found[0])

    def test_comments_and_strings_are_not_read(self) -> None:
        body = '\t# map.close_streets([]) is the planner\'s\n\tprint("close_streets( RoadClosure.new(")\n'
        self.assertEqual(hits(event_scheduler=other(body)), [])

    def test_an_allowed_site_that_is_gone_fails(self) -> None:
        planner = "class_name ClosurePlanner\nextends RefCounted\n\nstatic func plan(map: CityMap) -> void:\n\tpass\n"
        found = hits(closure_planner=planner)
        self.assertEqual(len(found), 2)
        self.assertTrue(all("holds no" in line for line in found), found)

    def test_the_real_tree_passes(self) -> None:
        self.assertEqual(check_closure_writers.scan(check_closure_writers.ROOT), [])


if __name__ == "__main__":
    unittest.main()
