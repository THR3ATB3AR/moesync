#!/usr/bin/env python3
"""Create categorized Markdown release notes from conventional commit subjects."""

import argparse
import re
import subprocess
from pathlib import Path


VERSION_TAG_PATTERN = re.compile(r"^v\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$")
CONVENTIONAL_COMMIT_PATTERN = re.compile(
    r"^(?P<type>[a-z]+)(?:\([^)]*\))?(?P<breaking>!)?:\s*(?P<subject>.+)$"
)
SECTIONS = (
    ("Features", "✨ New features"),
    ("Fixes", "🐛 Fixes and improvements"),
    ("Other", "🔧 Other changes"),
)


def git(*args: str) -> str:
    return subprocess.run(
        ["git", *args],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tag", required=True)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    git("rev-parse", "--verify", f"{args.tag}^{{commit}}")
    tags = git("tag", "--merged", args.tag, "--sort=-version:refname").splitlines()
    previous_tags = [
        tag
        for tag in tags
        if tag != args.tag and VERSION_TAG_PATTERN.fullmatch(tag)
    ]
    previous_tag = previous_tags[0] if previous_tags else None
    revision_range = (
        f"{previous_tag}..{args.tag}" if previous_tag else args.tag
    )

    commits = git(
        "log",
        "--no-merges",
        "--format=%H%x09%s",
        revision_range,
    ).splitlines()
    categorized: dict[str, list[tuple[str, str, bool]]] = {
        category: [] for category, _ in SECTIONS
    }

    for commit in commits:
        commit_hash, separator, subject = commit.partition("\t")
        if not separator:
            continue
        match = CONVENTIONAL_COMMIT_PATTERN.match(subject)
        if match:
            commit_type = match.group("type")
            title = match.group("subject")
            is_breaking = bool(match.group("breaking"))
        else:
            commit_type = "other"
            title = subject
            is_breaking = False

        category = (
            "Features"
            if commit_type == "feat"
            else "Fixes"
            if commit_type in {"fix", "perf"}
            else "Other"
        )
        title = title[:1].upper() + title[1:]
        categorized[category].append((commit_hash, title, is_breaking))

    base_url = f"https://github.com/{args.repository}"
    lines = ["## What's changed", ""]
    if previous_tag:
        compare_url = f"{base_url}/compare/{previous_tag}...{args.tag}"

    for category, heading in SECTIONS:
        entries = categorized[category]
        if not entries:
            continue
        lines.extend([f"### {heading}", ""])
        for commit_hash, title, is_breaking in entries:
            safe_title = title.replace("[", r"\[").replace("]", r"\]")
            commit_url = f"{base_url}/commit/{commit_hash}"
            breaking_label = "**Breaking:** " if is_breaking else ""
            lines.append(
                f"- {breaking_label}[{safe_title}]({commit_url}) "
                f"(`{commit_hash[:7]}`)"
            )
        lines.append("")

    if not commits:
        lines.extend(["No changes were recorded since the previous release.", ""])

    lines.extend(
        [
            "## Downloads",
            "",
            "Choose the Android universal APK for most devices, or select an "
            "architecture-specific APK. Linux and Windows builds are also "
            "available in the assets below.",
            "",
            "See [all MoeSync releases](https://github.com/"
            f"{args.repository}/releases) for previous versions.",
        ]
    )
    if previous_tag:
        lines.insert(2, f"[Full changelog]({compare_url})")
        lines.insert(3, "")

    args.output.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
