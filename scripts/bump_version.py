#!/usr/bin/env python3
"""
Simple semantic version bumper for pubspec.yaml.

Increments the patch component and the build number (after '+').
Example: 1.0.0+1 -> 1.0.1+2
"""
from __future__ import annotations

import pathlib
import re
import sys

PUBSPEC = pathlib.Path("pubspec.yaml")


def main() -> int:
  if not PUBSPEC.exists():
    print("pubspec.yaml not found", file=sys.stderr)
    return 1

  content = PUBSPEC.read_text(encoding="utf-8")
  match = re.search(
      r"^version:\s*([0-9]+)\.([0-9]+)\.([0-9]+)(?:\+([0-9]+))?",
      content,
      flags=re.MULTILINE,
  )
  if not match:
    print("version line not found in pubspec.yaml", file=sys.stderr)
    return 1

  major, minor, patch = [int(match.group(i)) for i in range(1, 4)]
  build = int(match.group(4) or 0)

  patch += 1
  build = build + 1 if build > 0 else patch
  new_version = f"{major}.{minor}.{patch}+{build}"

  updated = re.sub(
      r"^version:\s.*$",
      f"version: {new_version}",
      content,
      count=1,
      flags=re.MULTILINE,
  )
  PUBSPEC.write_text(updated, encoding="utf-8")
  print(new_version)
  return 0


if __name__ == "__main__":
  raise SystemExit(main())
