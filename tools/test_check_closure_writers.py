#!/usr/bin/env python3
"""Unit tests for `tools/check_closure_writers.py`, each against a small src/ tree held in memory:
the allowed sites as the game has them, and one planted line at a time."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_closure_writers

# The smallest tree that has every site of ALLOWED doing what it is allowed to do.
CLEAN = {
    "src/city/city.gd": (
        "class_name City\nextends Node\n\n"
        "func start_recipe_day(state: CityState, day: int,\n\t\tspec: DaySpec = null) -> void:\n"
        "\tvar closures: Array[RoadClosure] = _map.recipe_road_closures().duplicate()\n"
        "\t_map.close_streets(closures)\n\n"
        "func _close_streets(spec: DaySpec, rng: RandomNumberGenerator) -> void:\n"
        "\tvar closures := ClosurePlanner.plan_day(_map, spec, rng, tree)\n"
        "\t_map.close_streets(closures)\n"
    ),
    "src/city/city_map.gd": (
        "class_name CityMap\nextends WorldMap\n\n"
        "## Today's closed ground (`close_streets()` writes it).\n"
        "var _closed_tiles: Dictionary:\n\tget:\n\t\treturn _blocked.todays_closed_tiles()\n"
        "\tset(value):\n\t\t_blocked.replace_closed_tiles(value)\n\n"
        "func closed_tile_set() -> Dictionary:\n\treturn _closed_tiles\n\n"
        "func is_closed(tile: Vector2i) -> bool:\n\treturn _closed_tiles.has(tile)\n\n"
        "func add_recipe_closure(closure: RoadClosure) -> void:\n\t_recipe_closures.append(closure)\n\n"
        "func close_streets(closures: Array[RoadClosure]) -> void:\n"
        "\t_closed_tiles.clear()\n\t_closed_tiles.merge(_fenced_tiles)\n"
        "\tfor tile in tiles:\n\t\t_closed_tiles[tile] = true\n\n"
        "func repaint(state: CityState) -> void:\n\t_closed_tiles.clear()\n\t_shut_the_spent_calm(state)\n\n"
        "func _shut_the_spent_calm(state: CityState) -> void:\n\t_closed_tiles.merge(_fenced_tiles)\n"
    ),
    "src/city/recipe_city_builder.gd": (
        "class_name RecipeCityBuilder\nextends RefCounted\n\n"
        "static func _plan_closures(data: Dictionary, map: CityMap) -> void:\n"
        "\tmap.add_recipe_closure(RoadClosure.new(kind as RoadClosure.Kind, segment))\n"
    ),
    "src/routes/closure_planner.gd": (
        "class_name ClosurePlanner\nextends RefCounted\n\n"
        "static func plan_day(map: CityMap, spec: DaySpec) -> Array[RoadClosure]:\n"
        "\tvar chosen := _close_streets(map, spec)\n"
        "\tfor fence in ParkClosure.fence(map, map.fenced_park_block()):\n\t\tchosen.append(fence)\n"
        "\treturn chosen\n\n"
        "static func _close_streets(map: CityMap, spec: DaySpec) -> Array[RoadClosure]:\n"
        "\tvar chosen: Array[RoadClosure] = []\n\tchosen.append(RoadClosure.new(kind, segment))\n"
        "\treturn chosen\n\n"
        "static func reaches(map: CityMap) -> bool:\n"
        "\tvar blocked := {}\n\tblocked.merge(map.closed_tile_set())\n\treturn blocked.is_empty()\n"
    ),
    "src/routes/road_closure.gd": (
        "class_name RoadClosure\nextends RefCounted\n\nfunc _init(kind: int, segment: Edge) -> void:\n\tpass\n"
    ),
    "src/routes/park_closure.gd": (
        "class_name ParkClosure\nextends RoadClosure\n\n"
        "func _init(block: Vector2i) -> void:\n\tsuper(RoadClosure.Kind.PARK, Edge.new(block))\n\n"
        "static func fence(map: CityMap, block: Vector2i) -> Array[ParkClosure]:\n"
        "\tvar found: Array[ParkClosure] = []\n\tfound.append(ParkClosure.new(block))\n\treturn found\n"
    ),
    "src/world/blocked_layer.gd": (
        "class_name BlockedLayer\nextends RefCounted\n\nvar _closed := {}\n\n"
        "func copy() -> BlockedLayer:\n\tvar twin := BlockedLayer.new()\n"
        "\ttwin._closed = _closed.duplicate()\n\treturn twin\n\n"
        "func todays_closed_tiles() -> Dictionary:\n\treturn _closed\n\n"
        "func replace_closed_tiles(tiles: Dictionary) -> void:\n\t_closed = tiles\n\n"
        "func blocks(tile: Vector2i) -> bool:\n\treturn _closed.has(tile)\n"
    ),
}
EVENT = "src/events/model/event_scheduler.gd"
HEAD = "class_name EventScheduler\nextends RefCounted\n\nfunc plan(map: CityMap, more: Array) -> void:\n"


def tree(changes: dict[str, str | None]) -> dict[str, str]:
    """CLEAN with each path of changes replaced by its text, or taken out when the text is None."""
    files = dict(CLEAN)
    for path, text in changes.items():
        if text is None:
            del files[path]
        else:
            files[path] = text
    return files


def planted(body: str, path: str = EVENT, head: str = HEAD) -> list[str]:
    """The findings on CLEAN plus one file: head, then body as the lines of its function."""
    return check_closure_writers.check(tree({path: head + body}))


class CheckClosureWritersTests(unittest.TestCase):
    def test_the_allowed_sites_pass(self) -> None:
        self.assertEqual(check_closure_writers.check(CLEAN), [])

    def test_a_call_of_close_streets_outside_the_city_fails(self) -> None:
        found = planted("\tmap.close_streets(more)\n")
        self.assertEqual(len(found), 1)
        self.assertTrue(found[0].startswith(f"{EVENT}:5: calls CityMap.close_streets() in plan(): "), found[0])
        self.assertIn("a street closure belongs in ClosurePlanner.plan_day()", found[0])
        self.assertIn('the city skill, "Every day stays winnable"', found[0])

    def test_a_call_in_another_function_of_an_allowed_file_fails(self) -> None:
        city = CLEAN["src/city/city.gd"] + "\nfunc reopen() -> void:\n\t_map.close_streets([])\n"
        found = check_closure_writers.check(tree({"src/city/city.gd": city}))
        self.assertEqual(len(found), 1)
        self.assertIn("src/city/city.gd:14: calls CityMap.close_streets() in reopen()", found[0])

    def test_a_call_by_name_or_through_a_callable_fails(self) -> None:
        for body in (
            '\tmap.call("close_streets", more)\n',
            '\tmap.call_deferred(&"close_streets", more)\n',
            "\tvar closer := map.close_streets\n",
            "\tclose_streets(more)\n",
        ):
            found = planted(body)
            self.assertEqual(len(found), 1, body)
            self.assertIn("close_streets", found[0])

    def test_a_mention_that_is_no_call_passes(self) -> None:
        for body in (
            "\t# map.close_streets(more) is the city's to call\n\tpass\n",
            '\tpush_error("close_streets() takes the planner\'s closures")\n',
            "\t_close_streets(more)\n",
            "\tClosurePlanner._close_streets(map, more)\n",
            '\tvar text := """\n\tmap.close_streets(more)\n\t"""\n',
        ):
            self.assertEqual(planted(body), [], body)
        declared = "class_name Other\nextends RefCounted\n\nfunc close_streets(more: Array) -> void:\n\tpass\n"
        self.assertEqual(check_closure_writers.check(tree({"src/other.gd": declared})), [])

    def test_a_closure_built_outside_the_planner_fails(self) -> None:
        for body, what in (
            ("\tmore.append(RoadClosure.new(0, segment))\n", "RoadClosure.new()"),
            ("\tmore.append(ParkClosure.new(block))\n", "ParkClosure.new()"),
            ("\tvar make := RoadClosure.new\n", "RoadClosure.new()"),
        ):
            found = planted(body)
            self.assertEqual(len(found), 1, body)
            self.assertIn(f"{EVENT}:5: builds a closure ({what}) in plan(): ", found[0])
            self.assertIn("ClosurePlanner.plan_day()", found[0])

    def test_a_class_that_extends_a_closure_is_a_closure(self) -> None:
        bridge = (
            "class_name BridgeClosure extends ParkClosure\n\nstatic func make() -> BridgeClosure:\n\treturn new()\n"
        )
        files = tree({"src/routes/bridge_closure.gd": bridge, EVENT: HEAD + "\tmore.append(BridgeClosure.new())\n"})
        found = check_closure_writers.check(files)
        self.assertEqual(len(found), 2)
        self.assertIn(f"{EVENT}:5: builds a closure (BridgeClosure.new()) in plan()", found[0])
        self.assertIn("src/routes/bridge_closure.gd:4: builds a closure (new() in BridgeClosure's own file)", found[1])
        inner = HEAD + "\tmore.append(Gate.new())\n\nclass Gate extends RoadClosure:\n\tpass\n"
        self.assertEqual(len(planted("", head=inner)), 1)

    def test_a_class_that_is_no_closure_is_built_freely(self) -> None:
        self.assertEqual(planted("\tmore.append(Edge.new(block))\n\tmore.append(RoadClosureView.new())\n"), [])

    def test_a_write_of_the_closed_ground_fails_in_every_form(self) -> None:
        for body in (
            "\tmap.closed_tile_set()[tile] = true\n",
            "\tmap.closed_tile_set().erase(tile)\n",
            "\tmap.closed_tile_set().merge(more)\n",
            "\tmap.closed_tile_set().clear()\n",
            "\tlayer.todays_closed_tiles()[tiles[0]] = true\n",
            "\tlayer.replace_closed_tiles({})\n",
            '\tlayer.call("replace_closed_tiles", {})\n',
            '\tmap.set("_closed_tiles", {})\n',
            "\tvar closed := map.closed_tile_set()\n\tclosed[tile] = true\n",
            "\tvar closed: Dictionary = map.closed_tile_set()\n\tif more:\n\t\tclosed.erase(tile)\n",
            "\tvar closed := {}\n\tclosed = map.closed_tile_set()\n\tclosed.clear()\n",
        ):
            found = planted(body)
            self.assertEqual(len(found), 1, body)
            self.assertIn("the closed ground", found[0])
            self.assertIn("in plan(): a street closure belongs in ClosurePlanner.plan_day()", found[0])

    def test_a_write_in_another_function_of_the_map_fails(self) -> None:
        for body in ("\t_closed_tiles[tile] = true\n", "\t_closed_tiles = {}\n", "\t_closed_tiles.erase(tile)\n"):
            text = CLEAN["src/city/city_map.gd"] + "\nfunc shut(tile: Vector2i) -> void:\n" + body
            found = check_closure_writers.check(tree({"src/city/city_map.gd": text}))
            self.assertEqual(len(found), 1, body)
            line = len(text.splitlines())
            self.assertIn(f"src/city/city_map.gd:{line}: writes the closed ground", found[0])
            self.assertIn("in shut()", found[0])
        layer = CLEAN["src/world/blocked_layer.gd"] + "\nfunc open_all() -> void:\n\t_closed.clear()\n"
        found = check_closure_writers.check(tree({"src/world/blocked_layer.gd": layer}))
        self.assertEqual(len(found), 1)
        self.assertIn("writes the closed ground (_closed.clear()) in open_all()", found[0])

    def test_a_read_of_the_closed_ground_passes(self) -> None:
        for body in (
            "\tif map.closed_tile_set().has(tile):\n\t\tpass\n",
            "\tvar blocked := map.closed_tile_set().duplicate()\n\tblocked[tile] = true\n\tblocked.clear()\n",
            "\tfor tile: Vector2i in map.closed_tile_set():\n\t\tmore.append(tile)\n",
            "\tvar blocked := {}\n\tblocked.merge(map.closed_tile_set())\n",
            "\tif map.closed_tile_set()[tile] == true:\n\t\tpass\n",
            "\tvar closed := map.closed_tile_set()\n\tif closed[tile] != more[0] or closed.size() >= 2:\n\t\tpass\n",
            "\tvar count := 0\n\tcount += map.closed_tile_set().size()\n",
        ):
            self.assertEqual(planted(body), [], body)

    def test_a_name_given_the_record_is_followed_to_the_end_of_its_function_only(self) -> None:
        body = (
            "\tvar closed := map.closed_tile_set()\n\n"
            "func other(closed: Dictionary, tile: Vector2i) -> void:\n\tclosed[tile] = true\n"
        )
        self.assertEqual(planted(body), [])

    def test_a_closure_listed_for_a_recipe_outside_the_builder_fails(self) -> None:
        found = planted("\tmap.add_recipe_closure(more[0])\n")
        self.assertEqual(len(found), 1)
        self.assertIn("lists a closure for a recipe's city (CityMap.add_recipe_closure()) in plan()", found[0])

    def test_a_line_outside_every_function_cannot_be_allowed(self) -> None:
        text = CLEAN["src/routes/closure_planner.gd"] + "\nvar _spare := RoadClosure.new(0, null)\n"
        found = check_closure_writers.check(tree({"src/routes/closure_planner.gd": text}))
        self.assertEqual(len(found), 1)
        self.assertIn("builds a closure (RoadClosure.new()) outside every function", found[0])

    def test_a_function_of_an_inner_class_and_a_lambda_stay_in_their_function(self) -> None:
        inner = (
            "class_name Other\nextends RefCounted\n\nclass Inner:\n"
            "\tfunc run(map: CityMap) -> void:\n\t\tvar later := func() -> void:\n"
            "\t\t\tmap.close_streets([])\n\t\tlater.call()\n\t\tmap.close_streets([])\n"
        )
        found = check_closure_writers.check(tree({"src/other.gd": inner}))
        self.assertEqual(len(found), 2)
        self.assertIn("src/other.gd:7: calls CityMap.close_streets() in run()", found[0])
        self.assertIn("src/other.gd:9: calls CityMap.close_streets() in run()", found[1])

    def test_an_allowed_site_that_is_gone_fails(self) -> None:
        city = CLEAN["src/city/city.gd"]
        renamed = city.replace("func start_recipe_day(", "func start_scene_day(")
        found = check_closure_writers.check(tree({"src/city/city.gd": renamed}))
        self.assertEqual(len(found), 2)
        self.assertIn("src/city/city.gd:1: ALLOWED in tools/check_closure_writers.py lets start_recipe_day", found[0])
        self.assertIn("the file has no start_recipe_day", found[0])
        self.assertIn("calls CityMap.close_streets() in start_scene_day()", found[1])

        emptied = city.replace("\t_map.close_streets(closures)\n\n", "\tpass\n\n")
        found = check_closure_writers.check(tree({"src/city/city.gd": emptied}))
        self.assertEqual(len(found), 1)
        self.assertIn("src/city/city.gd:4: ALLOWED", found[0])
        self.assertIn("start_recipe_day holds no such line", found[0])

        found = check_closure_writers.check(tree({"src/routes/park_closure.gd": None}))
        self.assertEqual(len(found), 1)
        self.assertIn("src/routes/park_closure.gd:1: ALLOWED", found[0])
        self.assertIn("the file is not there", found[0])

    def test_every_allowed_site_is_one_the_clean_tree_needs(self) -> None:
        for site in check_closure_writers.ALLOWED:
            self.assertIn(site.path, CLEAN, site)
            self.assertTrue(check_closure_writers.check(tree({site.path: None})), site)

    def test_the_command_line_reports_and_rejects(self) -> None:
        tool = str(Path(__file__).resolve().parent / "check_closure_writers.py")
        with tempfile.TemporaryDirectory() as raw:
            root = Path(raw)
            for name, text in CLEAN.items():
                (root / name).parent.mkdir(parents=True, exist_ok=True)
                (root / name).write_text(text, encoding="utf-8")
            passed = subprocess.run([sys.executable, tool, "--root", raw], capture_output=True, text=True)
            self.assertEqual(passed.returncode, 0, passed.stdout)
            self.assertTrue(passed.stdout.startswith("OK"))
            (root / EVENT).parent.mkdir(parents=True)
            (root / EVENT).write_text(HEAD + "\tmap.close_streets(more)\n", encoding="utf-8")
            failed = subprocess.run([sys.executable, tool, "--root", raw], capture_output=True, text=True)
            self.assertEqual(failed.returncode, 1)
            lines = failed.stdout.splitlines()
            self.assertTrue(lines[0].startswith(f"{EVENT}:5: calls CityMap.close_streets() in plan()"))
            self.assertTrue(lines[-1].startswith("tools/check_closure_writers.py: 1 "))
            wrong = subprocess.run([sys.executable, tool, "--nope"], capture_output=True, text=True)
            self.assertEqual(wrong.returncode, 2)
            stray = subprocess.run([sys.executable, tool, "src"], capture_output=True, text=True)
            self.assertEqual(stray.returncode, 2)


if __name__ == "__main__":
    unittest.main()
