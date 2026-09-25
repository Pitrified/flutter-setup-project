#!/usr/bin/env python3
"""Query and check the plan folders under `plans/`.

Reads the frontmatter the `tracked-development` skill describes and answers the
questions nobody wants to answer by opening twenty folders: what is in progress,
what is next by priority, what a phase range contains.

    python3 scripts/plans.py list
    python3 scripts/plans.py list --status "in progress"
    python3 scripts/plans.py list --index 15
    python3 scripts/plans.py list --out /tmp/roadmap.md

Every path is an argument with a default, because this file is meant to be
callable from anywhere: `--root` is the plans directory, and without it the root
comes from `git rev-parse --show-toplevel`, never from this file's own location.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass, field
from html import escape
from pathlib import Path

STATUSES = ("draft", "planned", "in progress", "done", "superseded", "discarded")

# A phase file is NN_name.md; NN.M_name.md is a side-document of phase NN, which
# carries no status of its own (plans/21_plans_query_skill/00_start.md Q9).
PHASE = re.compile(r"^(\d\d)_([a-z0-9_.]+)\.md$")
SIDE = re.compile(r"^(\d\d)\.(\d+)_([a-z0-9_.]+)\.md$")
FOLDER = re.compile(r"^(\d\d)_([a-z0-9_]+)$")


class PlansError(Exception):
    """Something about the plans tree stops the tool from doing its job."""


class FrontmatterError(PlansError):
    """A `---` block exists but does not parse."""


@dataclass
class Phase:
    """One `NN_name.md` sub-plan."""

    path: Path
    number: str
    status: str | None


@dataclass
class Folder:
    """One `plans/NN_name/` feature folder."""

    path: Path
    number: str
    name: str
    start: Path | None
    front: dict[str, str] = field(default_factory=dict)
    phases: list[Phase] = field(default_factory=list)
    sides: list[Path] = field(default_factory=list)
    tracking: Path | None = None

    @property
    def status(self) -> str | None:
        return self.front.get("status")

    @property
    def priority(self) -> str | None:
        return self.front.get("priority")

    @property
    def summary(self) -> str:
        """First line of `description`, which is what a listing has room for."""
        text = self.front.get("description", "")
        return text.strip().splitlines()[0] if text.strip() else ""


def parse_frontmatter(text: str, where: Path) -> dict[str, str]:
    """The `---` block as a dict, supporting `key: value` and `key: |` blocks.

    Hand-rolled rather than PyYAML: six keys do not justify a dependency, and
    this box runs the gates on the standard library only.
    """
    if not text.startswith("---\n"):
        return {}
    end = text.find("\n---", 3)
    if end == -1:
        raise FrontmatterError(f"{where}: frontmatter opens with --- and never closes")
    lines = text[4:end].splitlines()
    front: dict[str, str] = {}
    key: str | None = None
    block: list[str] = []
    for line in lines:
        if key is not None and (line.startswith("  ") or not line.strip()):
            block.append(line[2:] if line.startswith("  ") else "")
            continue
        if key is not None:
            front[key] = "\n".join(block).strip()
            key, block = None, []
        if not line.strip():
            continue
        if ":" not in line:
            raise FrontmatterError(f"{where}: cannot read frontmatter line {line!r}")
        name, _, value = line.partition(":")
        value = value.strip()
        if value in ("|", ">", "|-", ">-"):
            key = name.strip()
        else:
            front[name.strip()] = value
    if key is not None:
        front[key] = "\n".join(block).strip()
    return front


def read_status(md: Path) -> str | None:
    return parse_frontmatter(md.read_text(encoding="utf-8"), md).get("status")


def load(root: Path, skipped: list[str] | None = None) -> list[Folder]:
    """Every numbered folder under `root`, in number order.

    A folder with no start file is not a feature (a reference dump such as
    `00_drafts` or `99_notes`) and is skipped; its name is appended to `skipped`
    so a caller can say so rather than leaving a folder silently absent.
    """
    if not root.is_dir():
        raise PlansError(f"{root}: not a directory")
    folders: list[Folder] = []
    for path in sorted(p for p in root.iterdir() if p.is_dir()):
        match = FOLDER.match(path.name)
        if not match:
            continue
        start = path / "00_start.md"
        if not start.exists():
            if skipped is not None:
                skipped.append(path.name)
            continue
        folder = Folder(
            path=path,
            number=match.group(1),
            name=match.group(2),
            start=start,
            front=parse_frontmatter(start.read_text(encoding="utf-8"), start),
            tracking=(path / "tracking.md") if (path / "tracking.md").exists() else None,
        )
        for md in sorted(path.glob("*.md")):
            if md.name in ("00_start.md", "tracking.md"):
                continue
            if SIDE.match(md.name):
                folder.sides.append(md)
            elif phase := PHASE.match(md.name):
                folder.phases.append(Phase(md, phase.group(1), read_status(md)))
        folders.append(folder)
    return folders


def default_root() -> Path:
    """`<repo>/plans`, from git rather than from this file's location."""
    try:
        top = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=True,
        ).stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError) as exc:
        raise PlansError(
            "not in a git repository, so --root is required to say where plans/ is"
        ) from exc
    return Path(top) / "plans"


def in_range(number: str, spec: str) -> bool:
    """`15` matches 15; `09-12` matches 9 through 12 inclusive."""
    low, _, high = spec.partition("-")
    try:
        first = int(low)
        last = int(high) if high else first
    except ValueError as exc:
        raise PlansError(f"--index wants NN or NN-MM, not {spec!r}") from exc
    return first <= int(number) <= last


def rows(folders: list[Folder]) -> list[tuple[str, ...]]:
    """One row per folder, sorted by priority descending then number."""

    def sort_key(folder: Folder) -> tuple[int, int]:
        try:
            priority = int(folder.priority or 0)
        except ValueError:
            priority = 0
        return (-priority, int(folder.number))

    out = []
    for folder in sorted(folders, key=sort_key):
        done = sum(1 for p in folder.phases if p.status == "done")
        phases = f"{done}/{len(folder.phases)}" if folder.phases else "-"
        out.append(
            (
                folder.number,
                folder.name,
                folder.status or "-",
                folder.priority or "-",
                phases,
                folder.summary or "-",
            )
        )
    return out


HEADERS = ("NN", "folder", "status", "pri", "phases", "description")


def print_table(table: list[tuple[str, ...]], width: int = 66) -> None:
    body = [r[:-1] + (r[-1][:width],) for r in table]
    widths = [max(len(h), *(len(r[i]) for r in body)) if body else len(h)
              for i, h in enumerate(HEADERS)]
    line = "  ".join(h.ljust(w) for h, w in zip(HEADERS, widths))
    print(line)
    print("  ".join("-" * w for w in widths))
    for row in body:
        print("  ".join(cell.ljust(w) for cell, w in zip(row, widths)))


def write_out(table: list[tuple[str, ...]], out: Path) -> None:
    """Markdown or HTML by extension, untracked: a message, not a tracked file."""
    if out.suffix == ".html":
        cells = "\n".join(
            "<tr>" + "".join(f"<td>{escape(c)}</td>" for c in row) + "</tr>"
            for row in table
        )
        head = "".join(f"<th>{h}</th>" for h in HEADERS)
        out.write_text(
            "<!doctype html><meta charset=utf-8><title>plans</title>"
            "<style>body{font:14px system-ui;margin:2rem}"
            "td,th{padding:.2rem .6rem;text-align:left;border-bottom:1px solid #ddd}</style>"
            f"<table><tr>{head}</tr>\n{cells}</table>\n",
            encoding="utf-8",
        )
    else:
        md = ["| " + " | ".join(HEADERS) + " |", "| " + " | ".join("---" for _ in HEADERS) + " |"]
        md += ["| " + " | ".join(c.replace("|", r"\|") for c in row) + " |" for row in table]
        out.write_text("\n".join(md) + "\n", encoding="utf-8")
    print(f"wrote {out}")


def cmd_list(args: argparse.Namespace) -> int:
    skipped: list[str] = []
    folders = load(args.root, skipped)
    if args.index:
        folders = [f for f in folders if in_range(f.number, args.index)]
    if args.status:
        folders = [
            f
            for f in folders
            if f.status == args.status or any(p.status == args.status for p in f.phases)
        ]
    if not folders:
        print("no folder matches")
        return 0
    table = rows(folders)
    if args.out:
        write_out(table, args.out)
    else:
        print_table(table)
    if args.index:
        skipped = [s for s in skipped if in_range(s[:2], args.index)]
    if skipped and not args.out:
        print(f"\nno 00_start.md, so not listed: {', '.join(skipped)}")
    if args.index or args.status:
        for folder in sorted(folders, key=lambda f: f.number):
            if not folder.phases and not folder.sides:
                continue
            print(f"\n{folder.number}_{folder.name}")
            for phase in folder.phases:
                print(f"  {phase.path.name:<46} {phase.status or '-'}")
            for side in folder.sides:
                print(f"  {side.name:<46} (side-document)")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--root",
        type=Path,
        help="the plans directory (default: <repo>/plans, via git rev-parse)",
    )
    sub = parser.add_subparsers(dest="command")
    listing = sub.add_parser("list", help="one line per folder, by priority")
    listing.add_argument("--status", choices=STATUSES, help="only this status")
    listing.add_argument("--index", help="NN or NN-MM")
    listing.add_argument("--out", type=Path, help="write .md or .html instead of printing")
    listing.set_defaults(func=cmd_list)

    args = parser.parse_args(argv)
    if not getattr(args, "func", None):
        args = parser.parse_args((argv or []) + ["list"])
    try:
        args.root = args.root or default_root()
        return args.func(args)
    except PlansError as exc:
        print(f"plans: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
