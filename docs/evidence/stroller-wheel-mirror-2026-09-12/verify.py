#!/usr/bin/env python3
"""Verify the installed five-texture stroller family and the wheel candidate."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path


EXPECTED = {
    "pram_side.png": "c869c90248de26b9d9563b9365d026fcd2961e9b490395e762e7ce76b53be9af",
    "pram_front.png": "d2020ba1d2bf0407d50106bc81b441a79efec9b567c27ecd662acb0427419bb2",
    "pram_back.png": "c2e711adf9942321ac903168f696795219e6f6f02a93cdc9be307b841fdfb440",
    "pram_back_diagonal.png": "11f278b6c7e584d7d4250365ad808c9142e9a65f576ef68ebad7115a50ad5699",
}
EXPECTED_CANDIDATE = "adb38bc65fd1b3850ec7e45847e0224a9bf26700b4afa899531b362378db322d"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime-dir", type=Path, required=True)
    parser.add_argument("--assignment-dir", type=Path, required=True)
    parser.add_argument("--candidate", type=Path, required=True)
    args = parser.parse_args()
    for name, expected in EXPECTED.items():
        runtime = args.runtime_dir / name
        assignment = args.assignment_dir / name
        if digest(runtime) != expected or digest(assignment) != expected:
            raise SystemExit(f"upstream mismatch: {name}")
        print(f"OK upstream {name}")
    if digest(args.candidate) != EXPECTED_CANDIDATE:
        raise SystemExit("candidate hash changed")
    print("OK candidate pram_front_diagonal.png")


if __name__ == "__main__":
    main()
