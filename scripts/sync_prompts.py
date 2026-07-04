#!/usr/bin/env python3
"""Sync the canonical prompt source (prompts/) into each package.

`prompts/` at the repo root is the single source of truth for LLM prompt
content shared by the R and Python packages. Edit files there, then run this
script to regenerate the copies each package actually ships:

    python3 scripts/sync_prompts.py

Run with --check (used in CI) to verify the generated copies are up to date
without modifying anything; it exits non-zero if they've drifted from the
canonical source.
"""

from __future__ import annotations

import argparse
import filecmp
import shutil
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SOURCE = REPO_ROOT / "prompts"
TARGETS = [
    REPO_ROOT / "r" / "inst" / "prompts",
    REPO_ROOT / "python" / "src" / "statlingo" / "prompts",
]


def _tree_matches(a: Path, b: Path) -> bool:
    """Recursively compare two directory trees for identical content."""
    cmp = filecmp.dircmp(a, b)
    if cmp.left_only or cmp.right_only or cmp.diff_files or cmp.funny_files:
        return False
    return all(
        _tree_matches(a / sub, b / sub) for sub in cmp.common_dirs
    )


def sync(check: bool) -> int:
    if not SOURCE.is_dir():
        print(f"error: canonical prompt source not found at {SOURCE}", file=sys.stderr)
        return 1

    exit_code = 0
    for target in TARGETS:
        if check:
            if not target.is_dir() or not _tree_matches(SOURCE, target):
                print(f"drift detected: {target} is out of sync with {SOURCE}")
                exit_code = 1
            else:
                print(f"up to date: {target}")
            continue

        if target.exists():
            shutil.rmtree(target)
        shutil.copytree(SOURCE, target)
        print(f"synced: {SOURCE} -> {target}")

    return exit_code


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify generated copies are up to date without modifying them",
    )
    args = parser.parse_args()
    sys.exit(sync(check=args.check))


if __name__ == "__main__":
    main()
