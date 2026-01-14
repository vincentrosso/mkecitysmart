#!/usr/bin/env python3
"""Simple LCOV coverage gate."""

import argparse
import re
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Verify LCOV coverage threshold.")
    parser.add_argument("--lcov", default="coverage/lcov.info", help="Path to lcov.info")
    parser.add_argument(
        "--threshold",
        type=float,
        default=80.0,
        help="Minimum coverage percent required.",
    )
    parser.add_argument(
        "--include",
        action="append",
        default=[],
        help="Path prefix to include (e.g., lib/services). When omitted, all files are considered.",
    )
    return parser.parse_args()


def compute_coverage(lcov_path: Path, includes: list[str]) -> float:
    if not lcov_path.exists():
        raise SystemExit(f"Coverage file not found: {lcov_path}")

    total_lines = 0
    covered_lines = 0
    includes = [p.strip() for p in includes if p.strip()]
    current_file_included = False

    line_re = re.compile(r"^DA:(\d+),(\d+)")
    sf_re = re.compile(r"^SF:(.+)")
    with lcov_path.open("r", encoding="utf-8") as f:
        for line in f:
            sf_match = sf_re.match(line.strip())
            if sf_match:
                path = sf_match.group(1)
                current_file_included = not includes or any(
                    inc in path for inc in includes
                )
                continue

            if not current_file_included:
                continue

            match = line_re.match(line.strip())
            if not match:
                continue
            total_lines += 1
            hits = int(match.group(2))
            if hits > 0:
                covered_lines += 1

    if total_lines == 0:
        return 0.0
    return (covered_lines / total_lines) * 100.0


def main() -> None:
    args = parse_args()
    percent = compute_coverage(Path(args.lcov), args.include)
    print(f"Coverage: {percent:.2f}% (threshold {args.threshold:.2f}%)")
    if percent < args.threshold:
        raise SystemExit(
            f"Coverage below threshold: {percent:.2f}% < {args.threshold:.2f}%"
        )


if __name__ == "__main__":
    main()
