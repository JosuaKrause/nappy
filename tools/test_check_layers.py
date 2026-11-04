#!/usr/bin/env python3
"""Unit tests for `tools/check_layers.py`, against small trees written here and a throwaway repository.

The map the real tree is held to is `tools/layer_map.py`'s; every case here patches in a map of its
own, so a change to the game's code or to the real map never turns these red, and CI's own step
(`uv run python tools/check_layers.py`) is what holds the real tree.
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
import unittest
from collections.abc import Iterator
from contextlib import contextmanager
from pathlib import Path
from typing import ClassVar
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_layers
import layer_map
from layer_map import Exception_

FOLDERS = {"src/data": "data", "src/model": "model", "src/world": "world", "src/sim": "simulation", "src/ui": "view"}
PROJECT = (
    '[application]\n\n[autoload]\n\nBus="*res://src/model/bus.gd"\nTuning="*res://src/data/tuning.gd"\n\n[display]\n'
)


@contextmanager
def the_map(
    exceptions: tuple[Exception_, ...] = (),
    files: dict[str, str] | None = None,
    caches: dict[str, str] | None = None,
) -> Iterator[None]:
    with (
        mock.patch.object(layer_map, "FOLDERS", FOLDERS),
        mock.patch.object(layer_map, "FILES", files or {}),
        mock.patch.object(layer_map, "STATIC_CACHES", caches or {}),
        mock.patch.object(layer_map, "CONSTANT_AUTOLOADS", {"Tuning": "constants"}),
        mock.patch.object(layer_map, "EXCEPTIONS", exceptions),
    ):
        yield


def tree(**files: str) -> check_layers.Tree:
    """A tree of `src/<folder>/<name>.gd` files, keyed `folder__name`, with the fixture's autoloads."""
    texts = {f"src/{key.replace('__', '/')}.gd": text for key, text in files.items()}
    return check_layers.Tree(files=texts, autoloads=check_layers.autoloads_of(PROJECT))


def rules(found: list[check_layers.Finding]) -> set[tuple[str, str, str]]:
    return {finding.key for finding in found}


BASE = {
    "data__catalogue": "class_name Catalogue\nconst ROWS := 3\n",
    "model__bus": "extends Node\nsignal happened\n",
    "model__map": "class_name Map\nextends RefCounted\n",
    "world__navigator": "class_name Navigator\nextends RefCounted\nvar map: Map\n",
    "sim__walker": "class_name Walker\nextends Node2D\nvar nav: Navigator\n",
    "ui__hud": "class_name Hud\nextends Control\nvar walker: Walker\n",
}


class StripTests(unittest.TestCase):
    def test_comments_and_strings_are_blanked_and_line_breaks_kept(self) -> None:
        text = 'var a := Walker.new() # Hud here\nvar b := "Hud"\n## Hud in a doc\nvar c := """Hud\nHud"""\nvar d\n'
        code = check_layers.blank(text)
        self.assertEqual(code.bare.count("\n"), text.count("\n"))
        self.assertIn("Walker", code.bare)
        self.assertNotIn("Hud", code.bare)
        self.assertEqual([literal.text for literal in code.literals], ["Hud", "Hud\nHud"])

    def test_a_hash_inside_a_string_is_not_a_comment(self) -> None:
        code = check_layers.blank('var a := "#ff0000"; var b := Hud.new()\n')
        self.assertIn("Hud", code.bare)

    def test_an_escaped_quote_does_not_end_the_string(self) -> None:
        code = check_layers.blank('var a := "say \\"Hud\\" now" + Walker.X\n')
        self.assertNotIn("Hud", code.bare)
        self.assertIn("Walker", code.bare)


class NamesTests(unittest.TestCase):
    def test_a_clean_tree_has_no_findings(self) -> None:
        with the_map():
            self.assertEqual(check_layers.check(tree(**BASE)), ([], []))

    def test_naming_a_higher_layer_is_found_with_its_line(self) -> None:
        files = dict(BASE, world__navigator="class_name Navigator\n\nfunc f(w: Walker) -> void:\n\tpass\n")
        with the_map():
            failures, found = check_layers.check(tree(**files))
        self.assertEqual(rules(found), {("src/world/navigator.gd", "names", "Walker")})
        self.assertEqual(found[0].line, 3)
        self.assertIn("src/world/navigator.gd:3: names Walker (world names simulation)", failures[0])

    def test_a_name_in_a_comment_a_string_or_after_a_dot_is_not_a_dependency(self) -> None:
        text = 'class_name Navigator\n# Walker\nvar s := "Walker"\nvar x = thing.Walker\nvar n := $Walker\n'
        with the_map():
            self.assertEqual(check_layers.check(tree(**dict(BASE, world__navigator=text))), ([], []))

    def test_extends_and_a_preload_path_count(self) -> None:
        files = dict(
            BASE,
            model__map='class_name Map\nextends Navigator\nconst H := preload("res://src/ui/hud.gd")\n',
        )
        with the_map():
            _, found = check_layers.check(tree(**files))
        self.assertEqual(
            rules(found), {("src/model/map.gd", "names", "Navigator"), ("src/model/map.gd", "names", "src/ui/hud.gd")}
        )

    def test_a_sibling_layer_is_a_reference_that_fails_in_both_directions(self) -> None:
        folders = {**FOLDERS, "src/obs": "observers"}
        files = dict(
            BASE,
            obs__log="class_name Log\nextends Node\nvar h: Hud\n",
            ui__hud="class_name Hud\nextends Control\nvar l: Log\n",
        )
        with the_map(), mock.patch.object(layer_map, "FOLDERS", folders):
            _, found = check_layers.check(tree(**files))
        self.assertEqual(rules(found), {("src/obs/log.gd", "names", "Hud"), ("src/ui/hud.gd", "names", "Log")})
        self.assertTrue(all("(a sibling)" in finding.detail for finding in found))
        # Without the sibling relation the view may name the observers, as a higher layer does.
        with the_map(), mock.patch.object(layer_map, "FOLDERS", folders), mock.patch.object(layer_map, "SIBLINGS", ()):
            _, found = check_layers.check(tree(**files))
        self.assertEqual(rules(found), {("src/obs/log.gd", "names", "Hud")})

    def test_an_autoload_is_named_at_its_files_layer(self) -> None:
        files = dict(BASE, data__catalogue="class_name Catalogue\nfunc f() -> void:\n\tBus.happened.emit()\n")
        with the_map():
            _, found = check_layers.check(tree(**files))
        self.assertEqual(rules(found), {("src/data/catalogue.gd", "names", "Bus")})

    def test_a_file_entry_overrides_its_folder(self) -> None:
        with the_map(files={"src/ui/hud.gd": "data"}):
            _, found = check_layers.check(tree(**BASE))
        self.assertEqual(rules(found), {("src/ui/hud.gd", "names", "Walker")})


class FetchTests(unittest.TestCase):
    def test_a_group_lookup_in_the_world_or_simulation_is_a_fetch_named_by_its_group(self) -> None:
        walker = (
            "class_name Walker\nfunc f() -> void:\n"
            '\tvar p = get_tree().get_first_node_in_group("player")\n'
            '\tget_tree().call_group(Hud.GROUP, &"stop")\n'
        )
        with the_map():
            _, found = check_layers.check(tree(**dict(BASE, sim__walker=walker)))
        self.assertIn(("src/sim/walker.gd", "group", "player"), rules(found))
        self.assertIn(("src/sim/walker.gd", "group", "Hud.GROUP"), rules(found))

    def test_is_in_group_is_not_a_lookup_and_the_view_may_look_up(self) -> None:
        walker = 'class_name Walker\nfunc f(n: Node) -> bool:\n\treturn n.is_in_group("player")\n'
        hud = 'class_name Hud\nvar w: Walker\nfunc f() -> void:\n\tget_tree().get_nodes_in_group("player")\n'
        with the_map():
            self.assertEqual(check_layers.check(tree(**dict(BASE, sim__walker=walker, ui__hud=hud))), ([], []))

    def test_an_autoload_is_a_fetch_unless_it_is_read_as_constants(self) -> None:
        walker = "class_name Walker\nfunc f() -> void:\n\tBus.happened.emit(Tuning.SPEED)\n"
        files = dict(BASE, sim__walker=walker, data__tuning="extends Node\nconst SPEED := 1\n")
        with the_map():
            _, found = check_layers.check(tree(**files))
        self.assertEqual(rules(found), {("src/sim/walker.gd", "autoload", "Bus")})

    def test_a_static_func_that_reaches_state_is_a_fetch_however_indirectly(self) -> None:
        model = (
            "class_name Map\n"
            "static var _graph := []\n"
            "static func size() -> int:\n\treturn 3\n"
            "static func by_key(k: int) -> int:\n\treturn _lookup(k)\n"
            "static func _lookup(k: int) -> int:\n\treturn _graph[k]\n"
        )
        clean = "class_name Walker\nfunc f() -> int:\n\treturn Map.size()\n"
        fetching = "class_name Walker\nfunc f() -> int:\n\treturn Map.by_key(1)\n"
        with the_map():
            self.assertEqual(check_layers.check(tree(**dict(BASE, model__map=model, sim__walker=clean))), ([], []))
            _, found = check_layers.check(tree(**dict(BASE, model__map=model, sim__walker=fetching)))
        self.assertEqual(rules(found), {("src/sim/walker.gd", "static", "Map")})
        self.assertEqual(found[0].detail, "Map.by_key")

    def test_a_listed_cache_is_not_state(self) -> None:
        model = "class_name Map\nstatic var _lut := []\nstatic func at(i: int) -> int:\n\treturn _lut[i]\n"
        walker = "class_name Walker\nfunc f() -> int:\n\treturn Map.at(1)\n"
        with the_map(caches={"Map._lut": "a table"}):
            self.assertEqual(check_layers.check(tree(**dict(BASE, model__map=model, sim__walker=walker))), ([], []))

    def test_a_world_file_holding_state_in_a_static_is_found(self) -> None:
        navigator = "class_name Navigator\nvar map: Map\n\nstatic var _last := 0\n"
        with the_map():
            _, found = check_layers.check(tree(**dict(BASE, world__navigator=navigator)))
        self.assertEqual(rules(found), {("src/world/navigator.gd", "static", "Navigator")})
        self.assertEqual(found[0].line, 4)

    def test_a_node_fetched_by_absolute_path_or_from_the_root_is_a_fetch(self) -> None:
        planted = {
            "get_node": 'get_node("/root/Main/Hud")',
            "get_node_or_null": 'get_node_or_null("/root/Main/Hud")',
            "dollar": 'var h = $"/root/Main/Hud"',
            "root": 'get_tree().root.find_child("Hud", true, false)',
            "get_root": "get_tree().get_root()",
            "current_scene": "get_tree().current_scene",
            "main_loop": "Engine.get_main_loop()",
        }
        for label, line in planted.items():
            walker = f"class_name Walker\nfunc f() -> void:\n\t{line}\n"
            for folder in ("sim", "world"):
                with self.subTest(label=label, folder=folder), the_map():
                    files = dict(BASE, **{f"{folder}__walker": walker})
                    _, found = check_layers.check(tree(**files))
                    self.assertEqual({finding.rule for finding in found}, {"node"})
                    self.assertEqual(found[0].line, 3)

    def test_a_nodes_own_children_and_the_views_root_reads_are_not_fetches(self) -> None:
        walker = (
            'class_name Walker\nfunc f() -> void:\n\tvar a = $Entities\n\tvar b = get_node_or_null("Baby")\n'
            '\tvar c = get_node("Entities/Layer")\n\tvar d = $"Entities/Layer"\n'
        )
        hud = "class_name Hud\nvar w: Walker\nfunc f() -> void:\n\tget_tree().current_scene\n"
        with the_map():
            self.assertEqual(check_layers.check(tree(**dict(BASE, sim__walker=walker, ui__hud=hud))), ([], []))

    def test_a_string_with_an_escape_or_triple_quotes_does_not_blind_later_fetches(self) -> None:
        walker = (
            "class_name Walker\n"
            'var _s := "x \\"/root/z\\" y"\n'
            'var _t := """a\n/root/b"""\n'
            "func f() -> void:\n"
            '\tget_node("/root/Main/Hud")\n'
            '\tget_node_or_null("/root/Main/Hud2")\n'
            '\tvar c = $"/root/Main/Hud3"\n'
            '\tget_tree().call_group("sirens", "go")\n'
        )
        with the_map():
            _, found = check_layers.check(tree(**dict(BASE, sim__walker=walker)))
        got = {(f.rule, f.name): f.line for f in found}
        self.assertEqual(
            got,
            {
                ("node", "/root/Main/Hud"): 6,
                ("node", "/root/Main/Hud2"): 7,
                ("node", "/root/Main/Hud3"): 8,
                ("group", "sirens"): 9,
            },
        )

    def test_a_uid_path_names_the_class_it_loads_like_a_res_path(self) -> None:
        walker = 'class_name Walker\nfunc f() -> void:\n\tvar h = preload("uid://hud123")\n'
        hud_file = check_layers.Tree(
            files=tree(**dict(BASE, sim__walker=walker)).files,
            autoloads=check_layers.autoloads_of(PROJECT),
            uids=check_layers.uids_of({"src/ui/hud.gd": "uid://hud123\n"}),
        )
        with the_map():
            _, found = check_layers.check(hud_file)
        self.assertEqual(rules(found), {("src/sim/walker.gd", "names", "src/ui/hud.gd")})
        self.assertEqual(found[0].detail, "simulation loads view")

    def test_fetches_outside_the_world_and_simulation_are_not_checked(self) -> None:
        model = 'class_name Map\nfunc f() -> void:\n\tget_tree().get_first_node_in_group("player")\n\tBus.x()\n'
        with the_map():
            self.assertEqual(check_layers.check(tree(**dict(BASE, model__map=model))), ([], []))


class ExceptionTests(unittest.TestCase):
    FILES: ClassVar[dict[str, str]] = dict(BASE, world__navigator="class_name Navigator\nvar w: Walker\n")

    def test_a_listed_finding_passes(self) -> None:
        listed = (Exception_("names", "Walker", "why", ("src/world/navigator.gd",)),)
        with the_map(exceptions=listed):
            failures, found = check_layers.check(tree(**self.FILES))
        self.assertEqual(failures, [])
        self.assertEqual(len(found), 1)

    def test_a_listed_finding_that_is_gone_fails_until_its_line_is_deleted(self) -> None:
        listed = (Exception_("names", "Walker", "why", ("src/world/navigator.gd",)),)
        with the_map(exceptions=listed):
            failures, _ = check_layers.check(tree(**BASE))
        self.assertEqual(len(failures), 1)
        self.assertIn("src/world/navigator.gd: tools/layer_map.py lists names Walker", failures[0])
        self.assertIn("it is gone", failures[0])

    def test_an_exception_for_another_file_or_rule_does_not_cover_it(self) -> None:
        for listed in (
            Exception_("names", "Walker", "why", ("src/ui/hud.gd",)),
            Exception_("static", "Walker", "why", ("src/world/navigator.gd",)),
        ):
            with self.subTest(listed=listed), the_map(exceptions=(listed,)):
                failures, _ = check_layers.check(tree(**self.FILES))
                self.assertEqual(len(failures), 2)

    def test_a_second_use_of_a_listed_name_in_a_listed_file_fails(self) -> None:
        listed = (Exception_("names", "Walker", "why", ("src/world/navigator.gd",)),)
        twice = dict(self.FILES, world__navigator="class_name Navigator\nvar w: Walker\nvar v: Walker\n")
        with the_map(exceptions=listed):
            failures, found = check_layers.check(tree(**twice))
        self.assertEqual(len(found), 2)
        self.assertEqual(len(failures), 1)
        self.assertIn("src/world/navigator.gd:3: names Walker (2 uses, 1 listed)", failures[0])

    def test_a_listed_count_covers_exactly_that_many_uses(self) -> None:
        listed = (
            Exception_("names", "Walker", "why", ("src/world/navigator.gd",), more=(("src/world/navigator.gd", 2),)),
        )
        twice = dict(self.FILES, world__navigator="class_name Navigator\nvar w: Walker\nvar v: Walker\n")
        with the_map(exceptions=listed):
            self.assertEqual(check_layers.check(tree(**twice))[0], [])
            failures, _ = check_layers.check(tree(**self.FILES))
        self.assertEqual(len(failures), 1)
        self.assertIn("lists 2 uses of names Walker, and 1 stand; lower its count", failures[0])

    def test_a_count_for_a_file_not_listed_is_an_error(self) -> None:
        listed = (Exception_("names", "Walker", "why", ("src/world/navigator.gd",), more=(("src/ui/hud.gd", 2),)),)
        with the_map(exceptions=listed), self.assertRaises(check_layers.LayerError):
            check_layers.check(tree(**self.FILES))

    def test_a_file_listed_twice_for_one_finding_is_an_error(self) -> None:
        listed = (
            Exception_("names", "Walker", "a", ("src/world/navigator.gd",)),
            Exception_("names", "Walker", "b", ("src/world/navigator.gd",)),
        )
        with the_map(exceptions=listed), self.assertRaises(check_layers.LayerError):
            check_layers.check(tree(**self.FILES))


class MapTests(unittest.TestCase):
    def test_a_file_in_no_layer_fails(self) -> None:
        with the_map():
            failures, _ = check_layers.check(tree(**dict(BASE, newfolder__thing="class_name Thing\n")))
        self.assertEqual(
            failures, ["src/newfolder/thing.gd: in no layer; place it, or its folder, in tools/layer_map.py"]
        )

    def test_a_file_entry_for_a_file_that_is_gone_or_an_unknown_layer_fails(self) -> None:
        with the_map(files={"src/model/gone.gd": "model", "src/ui/hud.gd": "screen"}):
            failures, _ = check_layers.check(tree(**BASE))
        self.assertTrue(any("src/model/gone.gd, which does not exist" in failure for failure in failures))
        self.assertTrue(any("'screen', which is no layer" in failure for failure in failures))

    def test_the_real_map_places_its_files_in_real_layers(self) -> None:
        for where, layer in [*layer_map.FOLDERS.items(), *layer_map.FILES.items()]:
            with self.subTest(where=where):
                self.assertIn(layer, layer_map.LAYERS)
        self.assertEqual(set(layer_map.LAYER_TEXT), set(layer_map.LAYERS))
        for exception in layer_map.EXCEPTIONS:
            with self.subTest(exception=exception.name):
                self.assertIn(exception.rule, ("names", "group", "autoload", "static"))
                self.assertNotIn("\n", exception.reason)
                self.assertEqual(list(exception.files), sorted(exception.files))


class ReadTests(unittest.TestCase):
    def test_a_revision_is_read_from_git_whatever_is_checked_out(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            repo = Path(temporary)

            def git(*args: str) -> None:
                subprocess.run(
                    ["git", "-c", "user.name=t", "-c", "user.email=t@example.com", *args],
                    cwd=repo,
                    check=True,
                    capture_output=True,
                )

            git("init", "-q", "-b", "main")
            (repo / "project.godot").write_text(PROJECT)
            (repo / "src" / "world").mkdir(parents=True)
            (repo / "src" / "world" / "navigator.gd").write_text("class_name Navigator\nvar w: Walker\n")
            (repo / "src" / "world" / "notes.txt").write_text("not code\n")
            git("add", ".")
            git("commit", "-q", "-m", "one")
            (repo / "src" / "world" / "navigator.gd").write_text("class_name Navigator\n")
            read = check_layers.read_rev("HEAD", cwd=repo)
            self.assertEqual(read.files, {"src/world/navigator.gd": "class_name Navigator\nvar w: Walker\n"})
            self.assertEqual(read.autoloads, {"Bus": "src/model/bus.gd", "Tuning": "src/data/tuning.gd"})
            self.assertEqual(check_layers.read_checkout(repo).files["src/world/navigator.gd"], "class_name Navigator\n")


if __name__ == "__main__":
    unittest.main()
