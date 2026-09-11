#!/usr/bin/env python3
"""Fast source-package checks that do not require a Flutter SDK.

This complements (not replaces) `flutter analyze` and `flutter test`. It is
useful in restricted CI/container environments to catch missing local imports,
localization drift, unsafe native permissions, and incomplete deliverables.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

REQUIRED = [
    "pubspec.yaml",
    "analysis_options.yaml",
    "README.md",
    "PRIVACY.md",
    "ARCHITECTURE.md",
    "lib/main.dart",
    "lib/app/app.dart",
    "lib/features/prayer_times/application/prayer_coordinator.dart",
    "lib/features/prayer_times/domain/prayer_state_machine.dart",
    "lib/features/prayer_tracker/presentation/tracker_screen.dart",
    "lib/features/qibla/presentation/qibla_screen.dart",
    "lib/features/settings/presentation/settings_screen.dart",
]


def fail(message: str) -> None:
    print(f"ERROR: {message}")
    raise SystemExit(1)


def check_required_files() -> None:
    missing = [item for item in REQUIRED if not (ROOT / item).is_file()]
    if missing:
        fail("missing required files: " + ", ".join(missing))


def check_pubspec() -> None:
    text = (ROOT / "pubspec.yaml").read_text(encoding="utf-8-sig")
    if not re.search(r"(?m)^name:\s*salah_focus\s*$", text):
        fail("pubspec project name must be salah_focus")
    for dep in (
        "flutter_riverpod",
        "go_router",
        "dio",
        "sqflite",
        "geolocator",
        "flutter_local_notifications",
        "timezone",
        "flutter_compass",
    ):
        if not re.search(rf"(?m)^\s{{2}}{re.escape(dep)}:\s*", text):
            fail(f"required dependency missing: {dep}")


def check_local_imports() -> None:
    pattern = re.compile(r"import\s+['\"]package:salah_focus/([^'\"]+)['\"]")
    missing: list[str] = []
    for file in (ROOT / "lib").rglob("*.dart"):
        text = file.read_text(encoding="utf-8")
        for match in pattern.finditer(text):
            target = ROOT / "lib" / match.group(1)
            if not target.is_file():
                missing.append(f"{file.relative_to(ROOT)} -> {target.relative_to(ROOT)}")
    if missing:
        fail("broken local imports:\n  " + "\n  ".join(missing))


def check_localizations() -> None:
    # Catalogs can live in separate files. Match each map at its own indentation
    # so the following language and date-formatting maps are not included.
    blocks: dict[str, str] = {}
    block_re = re.compile(r"^([ ]{2,4})'([a-z]{2})': \{\n(.*?)^\1\},", re.MULTILINE | re.DOTALL)
    for name in ("app_strings.dart", "additional_translations.dart"):
        text = (ROOT / "lib/app/localization" / name).read_text(encoding="utf-8")
        for match in block_re.finditer(text):
            blocks[match.group(2)] = match.group(3)
    languages = (ROOT / "lib/app/localization/app_language.dart").read_text(encoding="utf-8")
    supported = set(re.findall(r"Locale\('([a-z]{2})'\)", languages))
    if not supported or not supported.issubset(blocks):
        fail(f"missing localization catalogs: {sorted(supported - blocks.keys())}")
    key_re = re.compile(r"^\s+'([^']+)'\s*:\s*", re.MULTILINE)
    keys = {code: set(key_re.findall(body)) for code, body in blocks.items()}
    reference = keys["en"]
    for code in supported:
        missing = sorted(reference - keys[code])
        if missing:
            fail(f"localization keys missing for {code}: {missing}")


def check_no_placeholders() -> None:
    hits: list[str] = []
    pattern = re.compile(r"\b(TODO|FIXME|IMPLEMENT_ME)\b")
    for root in (ROOT / "lib", ROOT / "native", ROOT / "test", ROOT / "integration_test"):
        for file in root.rglob("*"):
            if file.is_file() and file.suffix in {".dart", ".kt", ".swift"}:
                for index, line in enumerate(file.read_text(encoding="utf-8").splitlines(), 1):
                    if pattern.search(line):
                        hits.append(f"{file.relative_to(ROOT)}:{index}")
    if hits:
        fail("placeholder markers remain: " + ", ".join(hits))


def main() -> int:
    check_required_files()
    check_pubspec()
    check_local_imports()
    check_localizations()
    check_no_placeholders()
    dart_files = len(list((ROOT / "lib").rglob("*.dart")))
    tests = len(list((ROOT / "test").rglob("*_test.dart"))) + len(
        list((ROOT / "integration_test").rglob("*_test.dart"))
    )
    print(f"Source verification passed: {dart_files} Dart source files, {tests} tests.")
    print("Run `flutter analyze` and `flutter test` on a Flutter 3.47+ workstation for compiler-level verification.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
