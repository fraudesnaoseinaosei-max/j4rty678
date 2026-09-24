#!/usr/bin/env python3
"""
tests/verify_syntax.py
Validates syntax and AST integrity of all Lua scripts in the DreezHub repository.
Preprocesses Luau-specific keywords (such as `continue`) into standard Lua 5.1 AST-compatible equivalents
before parsing with luaparser.
"""

import sys
import os
import re
from pathlib import Path
from luaparser import ast

REPO_ROOT = Path(__file__).resolve().parent.parent

def preprocess_luau(code: str) -> str:
    """
    Transforms Luau-specific syntax into Lua 5.1-compatible syntax for AST validation.
    Replaces standalone 'continue' statements with 'do end' (a valid no-op statement),
    preserving line counts and block boundaries.
    """
    # Replace continue keyword when used as a standalone statement
    clean_code = re.sub(r'(?<![a-zA-Z0-9_\.:])continue(?![a-zA-Z0-9_])', 'do end', code)
    return clean_code

def verify_file(file_path: Path) -> tuple[bool, str]:
    """
    Reads and validates a single Lua file.
    Returns (success: bool, message: str).
    """
    try:
        content = file_path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        try:
            content = file_path.read_text(encoding="latin-1")
        except Exception as e:
            return False, f"Failed to read file: {e}"

    clean_content = preprocess_luau(content)
    try:
        ast.parse(clean_content)
        lines = len(content.splitlines())
        return True, f"OK ({lines} lines)"
    except Exception as e:
        return False, f"Syntax Error: {e}"

def scan_and_verify(target_paths=None) -> bool:
    """
    Scans repository for .lua files and validates them.
    Returns True if all files pass, False otherwise.
    """
    if target_paths:
        files = [Path(p).resolve() for p in target_paths]
    else:
        files = []
        for root, dirs, filenames in os.walk(REPO_ROOT):
            # Ignore .git and .agents directories
            dirs[:] = [d for d in dirs if d not in {".git", ".agents", "__pycache__"}]
            for fname in filenames:
                if fname.endswith(".lua"):
                    files.append(Path(root) / fname)

    files.sort()
    if not files:
        print("[!] No .lua files found to verify.")
        return True

    print(f"=== DreezHub Lua Syntax Verification ({len(files)} files) ===")
    all_passed = True
    passed_count = 0
    failed_count = 0

    for file_path in files:
        rel_path = file_path.relative_to(REPO_ROOT) if file_path.is_relative_to(REPO_ROOT) else file_path
        success, message = verify_file(file_path)
        if success:
            print(f"  [PASS] {rel_path} -> {message}")
            passed_count += 1
        else:
            print(f"  [FAIL] {rel_path} -> {message}")
            all_passed = False
            failed_count += 1

    print("--------------------------------------------------")
    print(f"Results: {passed_count} passed, {failed_count} failed out of {len(files)} total files.")
    return all_passed

if __name__ == "__main__":
    paths = sys.argv[1:] if len(sys.argv) > 1 else None
    success = scan_and_verify(paths)
    sys.exit(0 if success else 1)
