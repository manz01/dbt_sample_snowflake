#!/usr/bin/env python3
import json
import os
import re
import sys
from pathlib import Path

MANIFEST = Path("target/manifest.json")
SOURCES_DIR = Path(os.getenv("SOURCES_DIR", "models/01_raw")).as_posix().rstrip("/")
FILE_PREFIX = os.getenv("FILE_PREFIX", "SRC_")  # must be lowercase 'src_' per requirement
ALLOWED_EXTS = {".yml", ".yaml"}

# Suffix (after 'src_') must be UPPERCASE letters/digits/underscores
SUFFIX_RE = re.compile(r"^[A-Z0-9_]+$")

def _under_sources_dir(p: Path) -> bool:
    posix = p.as_posix()
    return posix == SOURCES_DIR or posix.startswith(f"{SOURCES_DIR}/")

def main() -> int:
    if not MANIFEST.exists():
        print("ERROR: target/manifest.json not found. Run `dbt parse` first.", file=sys.stderr)
        return 2

    data = json.loads(MANIFEST.read_text())
    sources = data.get("sources", {})

    violations = []
    for src in sources.values():
        path = src.get("original_file_path") or src.get("patch_path") or ""
        if not path or path.startswith("dbt_packages/"):
            continue

        pkg = src.get("package_name")
        p = Path(path)

        # 1) must live under SOURCES_DIR
        if not _under_sources_dir(p):
            violations.append(("wrong_location", pkg, path, f"must live under `{SOURCES_DIR}/`"))

        # 2) extension must be .yml or .yaml
        if p.suffix not in ALLOWED_EXTS:
            violations.append(("bad_extension", pkg, path, "extension must be .yml or .yaml"))

        # 3) filename rules:
        #    - must start with 'src_' (lowercase)
        #    - remainder (after 'src_') must be UPPERCASE letters/digits/underscores
        base = p.stem  # filename without extension
        if not base.startswith(FILE_PREFIX):
            violations.append((
                "bad_filename_prefix", pkg, path,
                f"filename must start with `{FILE_PREFIX}` (lowercase)."
            ))
        else:
            suffix = base[len(FILE_PREFIX):]
            if not suffix:
                violations.append((
                    "bad_filename_suffix", pkg, path,
                    f"filename must include a name after `{FILE_PREFIX}` (e.g., `src_ACCOUNTS.yml`)."
                ))
            elif not SUFFIX_RE.fullmatch(suffix):
                violations.append((
                    "bad_filename_case", pkg, path,
                    (f"portion after `{FILE_PREFIX}` must be UPPERCASE letters/digits/underscores "
                     f"(e.g., `src_ACCOUNT_EVENTS.yaml`).")
                ))

        # 4) source_name: no restriction (can be anything) — intentionally not checked

    if violations:
        print("❌ dbt `sources` layout/name checks failed:\n")
        for kind, pkg, path, msg in violations:
            print(f"- [{kind}] package={pkg} file={path}: {msg}")
        print(f"\nExpected directory: {SOURCES_DIR}/")
        print(f"Filename pattern : {FILE_PREFIX}<UPPERCASE_AND_UNDERSCORES>.yml|yaml\n")
        return 1

    print(
        f"✅ All source YAMLs are under `{SOURCES_DIR}/`, filenames start with `{FILE_PREFIX}` "
        f"and the remainder is UPPERCASE letters/digits/underscores. Source names in YAML are unrestricted."
    )
    return 0

if __name__ == "__main__":
    sys.exit(main())
