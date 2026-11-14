import os, pathlib, sys

ROOT = pathlib.Path(r"D:\VSCODE\Github\xiaotang-daozai")
SKIP_DIRS = {".git", "target", "vendor", "dist", ".rebrand-tmp"}
SKIP_FILES = {"LICENSE", "THIRD_PARTY_NOTICES.txt"}
TEXT_EXT = {".rs", ".toml", ".rc", ".nsi", ".ps1", ".cmd", ".md", ".yml", ".yaml",
            ".json", ".txt", ".svg", ".lock", ".ico.md"}

MAP = [("岛仔", "岛主"), ("DAOZAI", "DAOZHU"), ("Daozai", "Daozhu"), ("daozai", "daozhu")]

changed = []
for dirpath, dirnames, filenames in os.walk(ROOT):
    dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
    for name in filenames:
        if name in SKIP_FILES:
            continue
        path = pathlib.Path(dirpath) / name
        if path.suffix.lower() not in TEXT_EXT:
            continue
        try:
            raw = path.read_bytes()
        except OSError:
            continue
        bom = raw.startswith(b"\xef\xbb\xbf")
        try:
            text = raw.decode("utf-8-sig")
        except UnicodeDecodeError:
            continue
        new = text
        for a, b in MAP:
            new = new.replace(a, b)
        if new == text:
            continue
        data = new.encode("utf-8")
        if bom:
            data = b"\xef\xbb\xbf" + data
        path.write_bytes(data)
        changed.append(str(path.relative_to(ROOT)))

print(f"changed files: {len(changed)}")
for c in changed:
    print("  ", c)
