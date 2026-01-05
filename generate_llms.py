#!/usr/bin/env python3

"""
Generate llms.txt + llms-full.txt + per-page llms/*.txt exports

from a MkDocs-style docs/ folder.

Assumes GitHub Pages base:
  https://tmdc-io.github.io/vulcan-docs/
"""

from __future__ import annotations

import os
from pathlib import Path

SITE_BASE = "https://tmdc-io.github.io/vulcan-book"
DOCS_DIR = Path("docs")
OUT_DIR = DOCS_DIR / "llms"

EXCLUDE_DIRS = {".git", "assets", "stylesheets", "javascripts", "overrides", "__draft", "writing-guide", "readme"}
EXCLUDE_FILES = {"llms.txt", "llms-full.txt", "FILE_REFERENCES.md"}


def first_h1(md_text: str, fallback: str) -> str:
    for line in md_text.splitlines():
        line = line.strip()
        if line.startswith("# "):
            return line[2:].strip()
    return fallback


def is_excluded(path: Path) -> bool:
    if path.name in EXCLUDE_FILES:
        return True
    parts = set(path.parts)
    return any(d in parts for d in EXCLUDE_DIRS)


def md_files() -> list[Path]:
    files = []
    for p in DOCS_DIR.rglob("*.md"):
        if is_excluded(p):
            continue
        files.append(p)
    return sorted(files)


def slug_from_md(md_path: Path) -> str:
    rel = md_path.relative_to(DOCS_DIR)
    # remove .md
    rel_no_ext = rel.with_suffix("")
    # MkDocs "index.md" usually maps to the folder URL
    if rel_no_ext.name == "index":
        rel_no_ext = rel_no_ext.parent
    # turn path into url-ish slug
    slug = "/".join(rel_no_ext.parts).strip("/")
    return slug or ""  # root index


def llms_txt_url(slug: str) -> str:
    # We host text exports under /llms/<slug>.txt
    if not slug:
        return f"{SITE_BASE}/llms/index.txt"
    return f"{SITE_BASE}/llms/{slug}.txt"


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    pages = []
    full_parts = []

    for md in md_files():
        raw = md.read_text(encoding="utf-8")
        title = first_h1(raw, md.stem)

        slug = slug_from_md(md)
        out_path = OUT_DIR / (("index" if slug == "" else slug) + ".txt")
        out_path.parent.mkdir(parents=True, exist_ok=True)

        # Minimal "clean" export: title + source + raw markdown
        source_page = f"{SITE_BASE}/" + (slug + "/" if slug else "")
        export = f"# {title}\n\nSource: {source_page}\n\n---\n\n{raw}\n"
        out_path.write_text(export, encoding="utf-8")

        pages.append((title, llms_txt_url(slug), source_page))
        full_parts.append(export)

    # llms.txt (index)
    llms_index = [
        "# Vulcan Book",
        "",
        "> AI-friendly index of Vulcan documentation text exports (for retrieval + RAG).",
        "",
        "## Full documentation",
        f"- [llms-full.txt]({SITE_BASE}/llms-full.txt)",
        "",
        "## All pages",
    ]
    for title, url, source_page in pages:
        llms_index.append(f"- [{title}]({url}) (source: {source_page})")

    (DOCS_DIR / "llms.txt").write_text("\n".join(llms_index) + "\n", encoding="utf-8")

    # llms-full.txt (flattened)
    (DOCS_DIR / "llms-full.txt").write_text("\n\n".join(full_parts), encoding="utf-8")

    print(f"Generated:\n- {DOCS_DIR / 'llms.txt'}\n- {DOCS_DIR / 'llms-full.txt'}\n- {OUT_DIR}/...")
    print(f"\nTotal pages: {len(pages)}")


if __name__ == "__main__":
    main()

