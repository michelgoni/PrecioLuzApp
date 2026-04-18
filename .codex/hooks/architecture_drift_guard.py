#!/usr/bin/env python3
"""Architectural anti-drift guard for PrecioLuzApp.

This hook inspects the working tree after Bash commands and again at turn end.
It warns when changes appear to violate the documented repo boundaries:
Features / Domain / Clients / Persistence / UIShared.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


@dataclass(frozen=True)
class Violation:
    path: str
    rule: str
    detail: str
    severity: str = "error"


INFRA_PATTERNS = [
    (re.compile(r"\bURLSession\b"), "URLSession"),
    (re.compile(r"\bJSONDecoder\b|\bJSONEncoder\b"), "JSONDecoder/JSONEncoder"),
    (re.compile(r"\bURLRequest\b|\bURLComponents\b"), "URLRequest/URLComponents"),
    (re.compile(r"\bUNUserNotificationCenter\b"), "UNUserNotificationCenter"),
    (re.compile(r"\bUserDefaults\.standard\b"), "UserDefaults.standard"),
    (re.compile(r"\bFileManager\b"), "FileManager"),
    (re.compile(r"import\s+SQLiteData"), "SQLiteData import"),
    (re.compile(r"\bsqlite\b", re.IGNORECASE), "sqlite reference"),
]

UI_IMPORT_PATTERNS = [
    (re.compile(r"import\s+SwiftUI"), "SwiftUI"),
    (re.compile(r"import\s+Charts"), "Charts"),
    (re.compile(r"import\s+UIKit"), "UIKit"),
]

TCA_PATTERN = re.compile(r"import\s+ComposableArchitecture")
VIEWMODEL_PATTERN = re.compile(r"\bObservableObject\b|\bViewModel\b|\b@ObservedObject\b")

ROOT_BOUNDARIES = {
    "Sources/Domain/": "Domain",
    "Sources/Clients/": "Clients",
    "Sources/Persistence/": "Persistence",
    "Sources/UIShared/": "UIShared",
    "Sources/Features/": "Features",
}


def main() -> int:
    payload = read_payload()
    repo_root = resolve_repo_root(payload)
    changed_files = gather_changed_files(repo_root)
    violations = inspect_files(repo_root, changed_files)

    event_name = payload.get("hook_event_name", "")
    if event_name == "PostToolUse":
        emit_post_tool_use(violations)
        return 0

    if event_name == "Stop":
        emit_stop(violations)
        return 0

    return 0


def read_payload() -> dict:
    raw = sys.stdin.read().strip()
    if not raw:
        return {}
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {}


def resolve_repo_root(payload: dict) -> Path:
    cwd = payload.get("cwd") or os.getcwd()
    try:
        output = run(["git", "rev-parse", "--show-toplevel"], cwd=cwd)
        return Path(output.strip())
    except Exception:
        return Path(cwd)


def gather_changed_files(repo_root: Path) -> list[Path]:
    candidates: set[str] = set()

    commands = [
        ["git", "diff", "--name-only", "--diff-filter=ACMR", "HEAD"],
        ["git", "diff", "--cached", "--name-only", "--diff-filter=ACMR"],
        ["git", "ls-files", "--others", "--exclude-standard"],
    ]

    for command in commands:
        try:
            output = run(command, cwd=repo_root)
        except Exception:
            continue
        for line in output.splitlines():
            line = line.strip()
            if line:
                candidates.add(line)

    result: list[Path] = []
    for relative in sorted(candidates):
        path = repo_root / relative
        if path.is_file() and should_inspect(path, repo_root):
            result.append(path)
    return result


def should_inspect(path: Path, repo_root: Path) -> bool:
    rel = path.relative_to(repo_root).as_posix()
    return rel.endswith(".swift") and rel.startswith("Sources/")


def inspect_files(repo_root: Path, files: Iterable[Path]) -> list[Violation]:
    violations: list[Violation] = []
    for path in files:
        rel = path.relative_to(repo_root).as_posix()
        text = safe_read(path)
        if not text:
            continue
        violations.extend(check_domain(rel, text))
        violations.extend(check_clients(rel, text))
        violations.extend(check_persistence(rel, text))
        violations.extend(check_features(rel, text))
        violations.extend(check_views(rel, text))
    return dedupe(violations)


def check_domain(rel: str, text: str) -> list[Violation]:
    if not rel.startswith("Sources/Domain/"):
        return []
    violations: list[Violation] = []
    for pattern, label in UI_IMPORT_PATTERNS:
        if pattern.search(text):
            violations.append(Violation(rel, "Domain must stay UI-free", f"Found {label} in Domain."))
    if TCA_PATTERN.search(text):
        violations.append(Violation(rel, "Domain must stay framework-light", "Found ComposableArchitecture import in Domain."))
    return violations


def check_clients(rel: str, text: str) -> list[Violation]:
    if not rel.startswith("Sources/Clients/"):
        return []
    violations: list[Violation] = []
    for pattern, label in UI_IMPORT_PATTERNS:
        if pattern.search(text):
            violations.append(Violation(rel, "Clients should not depend on UI frameworks", f"Found {label} in Clients."))
    return violations


def check_persistence(rel: str, text: str) -> list[Violation]:
    if not rel.startswith("Sources/Persistence/"):
        return []
    violations: list[Violation] = []
    for pattern, label in UI_IMPORT_PATTERNS:
        if pattern.search(text):
            violations.append(Violation(rel, "Persistence should not depend on UI frameworks", f"Found {label} in Persistence."))
    return violations


def check_features(rel: str, text: str) -> list[Violation]:
    if not rel.startswith("Sources/Features/"):
        return []
    violations: list[Violation] = []

    if VIEWMODEL_PATTERN.search(text):
        violations.append(Violation(rel, "Features should stay TCA-first", "Found ObservableObject/ViewModel pattern inside Features."))

    for pattern, label in INFRA_PATTERNS:
        if pattern.search(text):
            violations.append(Violation(rel, "Features should use injected clients, not direct infrastructure", f"Found {label} inside Features."))

    if re.search(r"import\s+UIKit", text):
        violations.append(Violation(rel, "Prefer SwiftUI-first features", "Found UIKit import inside Features."))

    return violations


def check_views(rel: str, text: str) -> list[Violation]:
    if not rel.endswith("View.swift"):
        return []
    violations: list[Violation] = []
    for pattern, label in INFRA_PATTERNS:
        if pattern.search(text):
            violations.append(Violation(rel, "Views should not talk to infrastructure directly", f"Found {label} inside a View."))
    return violations


def dedupe(violations: Iterable[Violation]) -> list[Violation]:
    seen: set[tuple[str, str, str]] = set()
    result: list[Violation] = []
    for item in violations:
        key = (item.path, item.rule, item.detail)
        if key not in seen:
            seen.add(key)
            result.append(item)
    return result


def emit_post_tool_use(violations: list[Violation]) -> None:
    if not violations:
        return
    summary = render_summary(violations, max_items=4)
    payload = {
        "systemMessage": (
            "Architectural drift guard detected suspicious layer mixing. "
            "Review the modified files before continuing.\n" + summary
        )
    }
    print(json.dumps(payload))


def emit_stop(violations: list[Violation]) -> None:
    if not violations:
        return
    summary = render_summary(violations, max_items=8)
    payload = {
        "decision": "block",
        "reason": "Architectural drift guard found violations.",
        "systemMessage": (
            "Architectural drift guard blocked turn completion until the architectural issues are reviewed.\n" + summary
        )
    }
    print(json.dumps(payload))


def render_summary(violations: list[Violation], max_items: int) -> str:
    lines = []
    for item in violations[:max_items]:
        lines.append(f"- {item.path}: {item.rule} {item.detail}")
    if len(violations) > max_items:
        lines.append(f"- ... and {len(violations) - max_items} more")
    return "\n".join(lines)


def safe_read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return ""


def run(command: list[str], cwd: str | Path) -> str:
    completed = subprocess.run(
        command,
        cwd=str(cwd),
        check=True,
        capture_output=True,
        text=True,
    )
    return completed.stdout


if __name__ == "__main__":
    raise SystemExit(main())
