#!/usr/bin/env python3
"""Bundle repository source files into mastermine.lua."""

from __future__ import annotations

from pathlib import Path
import argparse
import sys


SOURCE_FILES = [
    "LICENSE",
    "README.md",
    "hub.lua",
    "pocket.lua",
    "turtle.lua",
    "fleet_update.lua",
    "turtle_files/actions.lua",
    "turtle_files/basics.lua",
    "turtle_files/config.lua",
    "turtle_files/mastermine.lua",
    "turtle_files/receive.lua",
    "turtle_files/report.lua",
    "turtle_files/startup.lua",
    "turtle_files/state.lua",
    "turtle_files/update",
    "turtle_files/updated",
    "pocket_files/info.lua",
    "pocket_files/report.lua",
    "pocket_files/startup.lua",
    "pocket_files/update",
    "pocket_files/user.lua",
    "pocket_files/updated",
    "hub_files/basics.lua",
    "hub_files/config.lua",
    "hub_files/events.lua",
    "hub_files/monitor.lua",
    "hub_files/report.lua",
    "hub_files/startup.lua",
    "hub_files/state.lua",
    "hub_files/update",
    "hub_files/updated",
    "hub_files/user.lua",
    "hub_files/whosmineisitanyway.lua",
]


def encode_lua_long_string(content: str) -> str:
    eq_count = 0
    while True:
        marker = "]" + ("=" * eq_count) + "]"
        if marker not in content:
            return f"[{'=' * eq_count}[{content}]{'=' * eq_count}]"
        eq_count += 1


def build_bundle(repo_root: Path, output_path: Path) -> None:
    missing_files: list[str] = []
    files: list[tuple[str, str]] = []

    for relative_path in SOURCE_FILES:
        file_path = repo_root / relative_path
        if not file_path.exists():
            missing_files.append(relative_path)
            continue
        files.append((relative_path, file_path.read_text(encoding="utf-8")))

    if missing_files:
        missing = "\n".join(f" - {path}" for path in missing_files)
        raise FileNotFoundError(f"Missing source files:\n{missing}")

    lines: list[str] = [
        "output_dir = ...",
        "if not output_dir then",
        "    output_dir = ''",
        "end",
        "path = shell.resolve(output_dir)",
        "if not fs.isDir(path) then",
        "    error(path .. ' is not a directory')",
        "end",
        "",
        "files = {",
    ]

    for relative_path, content in files:
        encoded = encode_lua_long_string(content)
        lines.append(f'    ["{relative_path}"] = {encoded},')

    lines.extend(
        [
            "}",
            "",
            "for k, v in pairs(files) do",
            "    local file = fs.open(fs.combine(path, k), 'w')",
            "    file.write(v)",
            "    file.close()",
            "end",
            "",
        ]
    )

    output_path.write_text("\n".join(lines), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compile repository files into mastermine.lua"
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Path to repository root (default: current directory)",
    )
    parser.add_argument(
        "--output",
        default="mastermine.lua",
        help="Path to generated output file (default: mastermine.lua)",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = Path(args.repo_root).resolve()
    output_path = Path(args.output).resolve()
    try:
        build_bundle(repo_root, output_path)
    except Exception as exc:  # pragma: no cover - CLI path
        print(f"Build failed: {exc}", file=sys.stderr)
        return 1
    print(f"Wrote bundle: {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
