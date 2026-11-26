#!/usr/bin/env python3
"""
Garde-fou automatisé de cohérence scientifique, formelle et d'archivage
pour le compendium unifié CARTOGRAFFECT® (Strate 0 / Strate 1).

Vérifie les 7 groupes d'invariants sans aucune dépendance externe
(bibliothèque standard Python 3.10+ uniquement) :
  1. version_parity               — Parité stricte de VERSION à travers le compendium
  2. strate0_integrity            — SHA-256 de Lexicon176.lean, 11 fichiers Lean (130 th.), 0 trou/axiome sur 6 suites + Strate 1 Lean (36 th.)
  3. zenodo_cff_spdx              — Validité .zenodo.json / manifest.json / CITATION.cff / NOTICE
  4. epistemic_compartmentalization — Chartes Strate 1, CONVERGENCE_MATRIX.md, garde A4-Sanctuaire
  5. zero_leak_zenodo_hygiene     — Zéro fuite locale, 0 .env, 0 brut tiers, <= 20 Mo, 0 filter=lfs
  6. tracked_results_json         — Validité JSON sous extensions/in_silico/results/ et 0 chemin Windows
  7. site_payload_contract        — Exécution et cohérence de scripts/export_site_payload.py --check
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass, field
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
from typing import Any

try:
    import tomllib  # Python 3.11+
except ModuleNotFoundError:  # Python 3.10 fallback
    tomllib = None  # type: ignore[assignment]


SEMVER_RE = re.compile(r"^\d+\.\d+\.\d+$")
ZENODO_SINGLE_LICENSE_RE = re.compile(r"^[A-Za-z0-9.-]+$")
MAX_FILE_BYTES = 20 * 1024 * 1024  # 20 MiB

BINARY_EXTENSIONS = frozenset({
    ".png", ".jpg", ".jpeg", ".gif", ".webp", ".ico", ".bmp", ".tiff",
    ".pdf", ".zip", ".gz", ".tar", ".xz", ".7z",
    ".xlsx", ".xls", ".docx", ".doc", ".pptx",
    ".pyc", ".pyo", ".olean", ".ilean", ".so", ".dll", ".exe", ".bin",
})

WALK_EXCLUDED_DIRS = frozenset({
    ".git", ".lake", ".venv", "venv", "node_modules", "__pycache__", ".pytest_cache",
})

# Patterns de détection construits dynamiquement pour éviter toute auto-occurrence brute.
LEAK_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("user-token", re.compile(r"dr" + r"cab", re.IGNORECASE)),
    ("win-backslash-users", re.compile(r"C:\\" + r"Users\\", re.IGNORECASE)),
    ("win-slash-users", re.compile(r"C:/" + r"Users/", re.IGNORECASE)),
    ("file-uri-users", re.compile(r"file:///" + r"c:/Users/", re.IGNORECASE)),
)

LEAK_SELF_EXEMPT = frozenset({
    "scripts/check_consistency.py",
    "scripts/test_check_consistency.py",
})

FORBIDDEN_INSTITUTIONAL_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("institutional-removed-abbr", re.compile(r"\bop" + r"q\b", re.IGNORECASE)),
    ("institutional-removed-full", re.compile(r"ordre\s+des\s+psycho" + r"logues\s+du\s+qu[eé]bec", re.IGNORECASE)),
)

WIN_ABS_PATH_RE = re.compile(r"(?<![A-Za-z0-9_])[A-Za-z]:[/\\]")
FILE_DRIVE_URI_RE = re.compile(r"file:///+[A-Za-z]:[/\\]", re.IGNORECASE)
UNC_PATH_RE = re.compile(r"\\\\[A-Za-z0-9_.-]+\\[A-Za-z0-9_.-]+")

FORBIDDEN_FORMAL_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("sorry", re.compile(r"\bsorry\b")),
    ("Admitted", re.compile(r"\bAdmitted\b")),
    ("admit", re.compile(r"\badmit\b")),
    ("postulate", re.compile(r"\bpostulate\b")),
    ("{:axiom}", re.compile(r"\{:\s*axiom\b")),
    ("AXIOM", re.compile(r"\bAXIOM\b")),
)

A4_FORBIDDEN_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("PXP / PXP_BIC", re.compile(r"\bPXP(?:_?(?:BIC|WAIC))?\b", re.IGNORECASE)),
    ("LaTeX PXP", re.compile(r"\\text\{\s*PXP\s*\}", re.IGNORECASE)),
    ("PXP_{BIC}", re.compile(r"PXP_?\{?BIC\}?", re.IGNORECASE)),
    ("min r", re.compile(r"(?:\\min\s*r\b|\bmin\s+r\b)", re.IGNORECASE)),
)


@dataclass
class CategoryResult:
    """Résultat d'audit pour un groupe d'invariants."""

    key: str
    title: str
    passed: bool = True
    checks: list[str] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)

    def ok(self, detail: str) -> None:
        self.checks.append(detail)

    def fail(self, detail: str) -> None:
        self.passed = False
        self.errors.append(detail)

    def warn(self, detail: str, strict: bool) -> None:
        self.warnings.append(detail)
        if strict:
            self.passed = False

    def to_dict(self) -> dict[str, Any]:
        return {
            "key": self.key,
            "title": self.title,
            "passed": self.passed,
            "checks_count": len(self.checks),
            "errors": self.errors,
            "warnings": self.warnings,
            "checks": self.checks,
        }


def _configure_stdio() -> None:
    for stream in (sys.stdout, sys.stderr):
        reconfigure = getattr(stream, "reconfigure", None)
        if callable(reconfigure):
            try:
                reconfigure(encoding="utf-8", errors="replace")
            except Exception:
                pass


def _read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _parse_pyproject_version(text: str) -> str | None:
    if tomllib is not None:
        data = tomllib.loads(text)
        project = data.get("project")
        if isinstance(project, dict):
            ver = project.get("version")
            return str(ver) if ver is not None else None
        return None

    in_project = False
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("["):
            in_project = line == "[project]"
            continue
        if in_project:
            match = re.match(r'^version\s*=\s*["\']([^"\']+)["\']', line)
            if match:
                return match.group(1)
    return None


def _extract_cff_versions(cff_text: str) -> tuple[str | None, str | None]:
    top_version: str | None = None
    pref_version: str | None = None
    in_preferred = False

    for line in cff_text.splitlines():
        if re.match(r"^preferred-citation\s*:", line):
            in_preferred = True
            continue
        if in_preferred:
            if line and not line[0].isspace() and not line.lstrip().startswith("#"):
                in_preferred = False
            else:
                m_pref = re.match(r'^\s+version\s*:\s*["\']?([^"\'\s#]+)["\']?', line)
                if m_pref and pref_version is None:
                    pref_version = m_pref.group(1)
                continue

        if not in_preferred:
            m_top = re.match(r'^version\s*:\s*["\']?([^"\'\s#]+)["\']?', line)
            if m_top and top_version is None:
                top_version = m_top.group(1)

    return top_version, pref_version


def _strip_comments_and_strings(text: str, lang: str) -> str:
    """Remplace les commentaires et littéraux de chaîne par des espaces en préservant les sauts de ligne."""
    out: list[str] = []
    n = len(text)
    i = 0

    def emit_blank(chunk: str) -> None:
        for ch in chunk:
            out.append("\n" if ch == "\n" else " ")

    if lang in ("lean", "agda"):
        open_tok, close_tok = ("/-", "-/") if lang == "lean" else ("{-", "-}")
        while i < n:
            if text.startswith(open_tok, i):
                depth = 1
                out.extend((" ", " "))
                i += 2
                while i < n and depth > 0:
                    if text.startswith(open_tok, i):
                        depth += 1
                        out.extend((" ", " "))
                        i += 2
                    elif text.startswith(close_tok, i):
                        depth -= 1
                        out.extend((" ", " "))
                        i += 2
                    else:
                        out.append("\n" if text[i] == "\n" else " ")
                        i += 1
                continue
            if text.startswith("--", i):
                is_comment = True
                if lang == "agda":
                    prev_ok = i == 0 or text[i - 1].isspace()
                    next_ok = i + 2 >= n or text[i + 2].isspace()
                    is_comment = prev_ok and next_ok
                if is_comment:
                    while i < n and text[i] != "\n":
                        out.append(" ")
                        i += 1
                    continue
            if text[i] == '"':
                out.append(" ")
                i += 1
                while i < n:
                    ch = text[i]
                    if ch == "\\" and i + 1 < n:
                        emit_blank(text[i : i + 2])
                        i += 2
                        continue
                    out.append("\n" if ch == "\n" else " ")
                    i += 1
                    if ch == '"':
                        break
                continue
            out.append(text[i])
            i += 1
        return "".join(out)

    if lang == "rocq":
        while i < n:
            if text.startswith("(*", i):
                depth = 1
                out.extend((" ", " "))
                i += 2
                while i < n and depth > 0:
                    if text.startswith("(*", i):
                        depth += 1
                        out.extend((" ", " "))
                        i += 2
                    elif text.startswith("*)", i):
                        depth -= 1
                        out.extend((" ", " "))
                        i += 2
                    else:
                        out.append("\n" if text[i] == "\n" else " ")
                        i += 1
                continue
            if text[i] == '"':
                out.append(" ")
                i += 1
                while i < n:
                    ch = text[i]
                    if ch == '"' and i + 1 < n and text[i + 1] == '"':
                        out.extend((" ", " "))
                        i += 2
                        continue
                    out.append("\n" if ch == "\n" else " ")
                    i += 1
                    if ch == '"':
                        break
                continue
            out.append(text[i])
            i += 1
        return "".join(out)

    if lang == "dafny":
        while i < n:
            if text.startswith("/*", i):
                out.extend((" ", " "))
                i += 2
                while i < n:
                    if text.startswith("*/", i):
                        out.extend((" ", " "))
                        i += 2
                        break
                    out.append("\n" if text[i] == "\n" else " ")
                    i += 1
                continue
            if text.startswith("//", i):
                while i < n and text[i] != "\n":
                    out.append(" ")
                    i += 1
                continue
            if text.startswith('@"', i):
                out.extend((" ", " "))
                i += 2
                while i < n:
                    ch = text[i]
                    if ch == '"' and i + 1 < n and text[i + 1] == '"':
                        out.extend((" ", " "))
                        i += 2
                        continue
                    out.append("\n" if ch == "\n" else " ")
                    i += 1
                    if ch == '"':
                        break
                continue
            if text[i] == '"':
                out.append(" ")
                i += 1
                while i < n:
                    ch = text[i]
                    if ch == "\\" and i + 1 < n:
                        emit_blank(text[i : i + 2])
                        i += 2
                        continue
                    out.append("\n" if ch == "\n" else " ")
                    i += 1
                    if ch == '"':
                        break
                continue
            out.append(text[i])
            i += 1
        return "".join(out)

    if lang == "smt":
        while i < n:
            if text[i] == ";":
                while i < n and text[i] != "\n":
                    out.append(" ")
                    i += 1
                continue
            if text[i] == '"':
                out.append(" ")
                i += 1
                while i < n:
                    ch = text[i]
                    if ch == '"' and i + 1 < n and text[i + 1] == '"':
                        out.extend((" ", " "))
                        i += 2
                        continue
                    out.append("\n" if ch == "\n" else " ")
                    i += 1
                    if ch == '"':
                        break
                continue
            out.append(text[i])
            i += 1
        return "".join(out)

    if lang == "tla":
        while i < n:
            if text.startswith("(*", i):
                depth = 1
                out.extend((" ", " "))
                i += 2
                while i < n and depth > 0:
                    if text.startswith("(*", i):
                        depth += 1
                        out.extend((" ", " "))
                        i += 2
                    elif text.startswith("*)", i):
                        depth -= 1
                        out.extend((" ", " "))
                        i += 2
                    else:
                        out.append("\n" if text[i] == "\n" else " ")
                        i += 1
                continue
            if text.startswith(r"\*", i):
                while i < n and text[i] != "\n":
                    out.append(" ")
                    i += 1
                continue
            if text[i] == '"':
                out.append(" ")
                i += 1
                while i < n:
                    ch = text[i]
                    if ch == "\\" and i + 1 < n:
                        emit_blank(text[i : i + 2])
                        i += 2
                        continue
                    out.append("\n" if ch == "\n" else " ")
                    i += 1
                    if ch == '"':
                        break
                continue
            out.append(text[i])
            i += 1
        return "".join(out)

    return text


def _iter_repo_files(root: Path) -> list[str]:
    results: list[str] = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in WALK_EXCLUDED_DIRS]
        for fname in filenames:
            rel = Path(dirpath, fname).relative_to(root).as_posix()
            results.append(rel)
    return sorted(results)


def _git_ls_files(root: Path) -> tuple[list[str], str | None]:
    proc = subprocess.run(
        ["git", "-C", str(root), "-c", "core.quotepath=false", "ls-files", "-z"],
        capture_output=True,
        check=False,
    )
    if proc.returncode != 0:
        err = proc.stderr.decode("utf-8", errors="replace").strip()
        return [], err or f"git ls-files a retourné le code {proc.returncode}"
    raw_items = proc.stdout.decode("utf-8", errors="surrogateescape").split("\0")
    files = [item for item in raw_items if item]
    return files, None


def _is_raw_third_party_filename(rel: str) -> bool:
    rel_lower = rel.lower()
    name_lower = Path(rel).name.lower()
    if "raw_third_party/" in rel_lower:
        return True
    if "nrc-vad" in name_lower:
        return True
    if "dima_groupe" in name_lower:
        return True
    if name_lower == "cartograffect_55k_nrc_vad_diamant_303.tsv":
        return True
    if name_lower.startswith("fancat") or "fancatdatabase" in name_lower:
        return True
    if "fancat" in name_lower and not name_lower.startswith("cartograffect_"):
        return True
    return False


def _find_windows_paths_in_json(obj: Any, prefix: str = "$") -> list[tuple[str, str]]:
    hits: list[tuple[str, str]] = []
    if isinstance(obj, str):
        if (
            WIN_ABS_PATH_RE.search(obj)
            or FILE_DRIVE_URI_RE.search(obj)
            or UNC_PATH_RE.search(obj)
        ):
            hits.append((prefix, obj))
    elif isinstance(obj, list):
        for idx, val in enumerate(obj):
            hits.extend(_find_windows_paths_in_json(val, f"{prefix}[{idx}]"))
    elif isinstance(obj, dict):
        for key, val in obj.items():
            hits.extend(_find_windows_paths_in_json(val, f"{prefix}.{key}"))
    return hits


def _load_json_dict(path: Path, label: str, cat: CategoryResult) -> dict[str, Any] | None:
    if not path.is_file():
        cat.fail(f"Fichier requis manquant : {label}")
        return None
    try:
        data = json.loads(_read_text(path))
    except json.JSONDecodeError as exc:
        cat.fail(f"JSON invalide dans {label} : {exc}")
        return None
    if not isinstance(data, dict):
        cat.fail(f"{label} doit contenir un objet JSON racine.")
        return None
    return data


def _check_version_parity(
    root: Path,
    zenodo_data: dict[str, Any] | None,
    manifest_data: dict[str, Any] | None,
) -> tuple[CategoryResult, str | None]:
    cat = CategoryResult("version_parity", "1. Parité de version (VERSION)")
    version_path = root / "VERSION"
    if not version_path.is_file():
        cat.fail("Fichier racine VERSION introuvable.")
        return cat, None

    version = _read_text(version_path).strip()
    if not SEMVER_RE.fullmatch(version):
        cat.fail(f"VERSION='{version}' ne respecte pas le format SemVer strict X.Y.Z.")
        return cat, version
    cat.ok(f"VERSION = {version} (SemVer strict)")

    # CITATION.cff
    cff_path = root / "CITATION.cff"
    if not cff_path.is_file():
        cat.fail("CITATION.cff introuvable.")
    else:
        cff_top, cff_pref = _extract_cff_versions(_read_text(cff_path))
        if cff_top != version:
            cat.fail(f"CITATION.cff version='{cff_top}' != VERSION '{version}'.")
        else:
            cat.ok(f"CITATION.cff version = {cff_top}")
        if cff_pref is not None and cff_pref != version:
            cat.fail(f"CITATION.cff preferred-citation.version='{cff_pref}' != '{version}'.")
        elif cff_pref == version:
            cat.ok(f"CITATION.cff preferred-citation.version = {cff_pref}")

    # .zenodo.json
    if zenodo_data is None:
        cat.fail(".zenodo.json indisponible pour le contrôle de version.")
    else:
        z_ver = zenodo_data.get("version")
        if z_ver != version:
            cat.fail(f".zenodo.json version='{z_ver}' != VERSION '{version}'.")
        else:
            cat.ok(f".zenodo.json version = {z_ver}")

    # manifest.json
    if manifest_data is None:
        cat.fail("manifest.json indisponible pour le contrôle de version.")
    else:
        m_ver = manifest_data.get("version")
        if m_ver != version:
            cat.fail(f"manifest.json version='{m_ver}' != VERSION '{version}'.")
        else:
            cat.ok(f"manifest.json version = {m_ver}")

        ms_ver = manifest_data.get("strate_0_core", {}).get("manuscript", {}).get("version")
        if ms_ver != version:
            cat.fail(
                f"manifest.json strate_0_core.manuscript.version='{ms_ver}' != '{version}'."
            )
        else:
            cat.ok(f"manifest.json manuscript.version = {ms_ver}")

    # extensions/in_silico/pyproject.toml
    pyproject_path = root / "extensions/in_silico/pyproject.toml"
    if not pyproject_path.is_file():
        cat.fail("extensions/in_silico/pyproject.toml introuvable.")
    else:
        py_ver = _parse_pyproject_version(_read_text(pyproject_path))
        if py_ver != version:
            cat.fail(
                f"extensions/in_silico/pyproject.toml version='{py_ver}' != '{version}'."
            )
        else:
            cat.ok(f"extensions/in_silico/pyproject.toml version = {py_ver}")

    # CHANGELOG.md
    changelog_path = root / "CHANGELOG.md"
    if not changelog_path.is_file():
        cat.fail("CHANGELOG.md introuvable.")
    else:
        m_chg = re.search(r"^##\s+\[(\d+\.\d+\.\d+)\]", _read_text(changelog_path), re.MULTILINE)
        if not m_chg:
            cat.fail("Aucun en-tête SemVer '## [X.Y.Z]' trouvé dans CHANGELOG.md.")
        elif m_chg.group(1) != version:
            cat.fail(f"CHANGELOG.md dernière version='{m_chg.group(1)}' != '{version}'.")
        else:
            cat.ok(f"CHANGELOG.md en-tête = [{m_chg.group(1)}]")

    # docs/01-Article_Cartograffect.md
    article_path = root / "docs/01-Article_Cartograffect.md"
    if not article_path.is_file():
        cat.fail("docs/01-Article_Cartograffect.md introuvable.")
    else:
        art_matches = re.findall(
            r"\bversion\s+v?(\d+\.\d+\.\d+)\b",
            _read_text(article_path),
            re.IGNORECASE,
        )
        if not art_matches:
            cat.fail("Aucune mention 'version X.Y.Z' détectée dans docs/01-Article_Cartograffect.md.")
        else:
            mismatches = [v for v in art_matches if v != version]
            if mismatches:
                cat.fail(
                    f"docs/01-Article_Cartograffect.md mentionne une version divergente : {mismatches} != '{version}'."
                )
            else:
                cat.ok(f"docs/01-Article_Cartograffect.md mentions de version = {art_matches}")

    return cat, version


def _check_strate0_integrity(
    root: Path,
    manifest_data: dict[str, Any] | None,
    tracked_files: list[str],
    all_repo_files: list[str],
) -> CategoryResult:
    cat = CategoryResult(
        "strate0_integrity",
        "2. Intégrité cryptographique et formelle de la Strate 0",
    )

    lexicon_rel = "Cartograffect/Lexicon176.lean"
    lexicon_path = root / lexicon_rel
    if not lexicon_path.is_file():
        cat.fail(f"{lexicon_rel} introuvable.")
    elif manifest_data is None:
        cat.fail("manifest.json indisponible pour vérifier le SHA-256 de Lexicon176.lean.")
    else:
        actual_sha = hashlib.sha256(lexicon_path.read_bytes()).hexdigest()
        lex_meta = manifest_data.get("strate_0_core", {}).get("lexicon_176", {})
        expected_sha = lex_meta.get("sha256")
        if actual_sha != expected_sha:
            cat.fail(
                f"Rupture SHA-256 pour {lexicon_rel} : calculé={actual_sha}, attendu(manifest)={expected_sha}."
            )
        else:
            cat.ok(f"{lexicon_rel} SHA-256 vérifié ({actual_sha[:16]}...)")

    # 11 fichiers Lean dans manifest.json (incluant EndToEndBridge.lean)
    if manifest_data is not None:
        s0 = manifest_data.get("strate_0_core", {})
        if s0.get("theorems_verified") != 130:
            cat.fail(
                f"manifest.json strate_0_core.theorems_verified doit valoir 130 (trouvé : {s0.get('theorems_verified')})."
            )
        else:
            cat.ok("manifest.json strate_0_core.theorems_verified = 130")

        lean_files = s0.get("lean_files")
        if not isinstance(lean_files, list) or len(lean_files) != 11:
            count = len(lean_files) if isinstance(lean_files, list) else "invalid"
            cat.fail(f"manifest.json strate_0_core.lean_files doit lister 11 fichiers (trouvé : {count}).")
        else:
            missing = [lf for lf in lean_files if not (root / lf).is_file()]
            if missing:
                cat.fail(f"Fichiers Lean manquants sur disque : {missing}")
            elif "Cartograffect/EndToEndBridge.lean" not in lean_files:
                cat.fail("Cartograffect/EndToEndBridge.lean absent de manifest.json strate_0_core.lean_files.")
            else:
                cat.ok("11/11 fichiers Lean du manifest présents sur disque (dont EndToEndBridge.lean)")

    # Unicité de Lexicon176.lean hors Cartograffect/
    dup_lexicons = sorted({
        rel for rel in (set(tracked_files) | set(all_repo_files))
        if Path(rel).name.lower() == "lexicon176.lean" and rel != lexicon_rel
    })
    if dup_lexicons:
        cat.fail(f"Doublon(s) Lexicon176.lean hors {lexicon_rel} : {dup_lexicons}")
    else:
        cat.ok("0 doublon Lexicon176.lean hors Cartograffect/")

    # Scan des 6 suites formelles Strate 0 + extensions Strate 1 Lean hors commentaires et littéraux
    suites: list[tuple[str, str, list[Path]]] = [
        (
            "Lean 4",
            "lean",
            ([root / "Cartograffect.lean"] if (root / "Cartograffect.lean").is_file() else [])
            + sorted((root / "Cartograffect").rglob("*.lean") if (root / "Cartograffect").is_dir() else []),
        ),
        ("Rocq", "rocq", sorted((root / "rocq/theories").rglob("*.v") if (root / "rocq/theories").is_dir() else [])),
        ("Agda", "agda", sorted((root / "agda/src").rglob("*.agda") if (root / "agda/src").is_dir() else [])),
        ("Dafny", "dafny", sorted((root / "dafny/src").rglob("*.dfy") if (root / "dafny/src").is_dir() else [])),
        ("SMT-LIB 2", "smt", sorted((root / "smt/theories").rglob("*.smt2") if (root / "smt/theories").is_dir() else [])),
        (
            "TLA+",
            "tla",
            sorted((root / "tla/specs").rglob("*.tla") if (root / "tla/specs").is_dir() else [])
            + sorted((root / "tla/specs").rglob("*.cfg") if (root / "tla/specs").is_dir() else []),
        ),
    ]

    strate1_lean_paths = sorted(
        (root / "extensions/lexicon/lean").rglob("*.lean")
        if (root / "extensions/lexicon/lean").is_dir()
        else []
    )
    if strate1_lean_paths:
        suites.append(("Lean 4 Strate 1 (extensions/lexicon/lean)", "lean", strate1_lean_paths))

    total_formal_files = 0
    for suite_name, lang, paths in suites:
        if not paths:
            cat.fail(f"Aucun fichier formel trouvé pour la suite {suite_name}.")
            continue
        suite_hits: list[str] = []
        for path in paths:
            total_formal_files += 1
            rel = path.relative_to(root).as_posix()
            stripped = _strip_comments_and_strings(_read_text(path), lang)
            for lineno, line in enumerate(stripped.splitlines(), 1):
                for label, pattern in FORBIDDEN_FORMAL_PATTERNS:
                    if pattern.search(line):
                        suite_hits.append(f"{rel}:{lineno} ({label})")
        if suite_hits:
            cat.fail(f"{suite_name} contient des marqueurs interdits : {suite_hits}")
        else:
            cat.ok(f"{suite_name} ({len(paths)} fichiers) : 0 trou / axiome")

    if total_formal_files > 0 and cat.passed:
        cat.ok(f"Hexa-Prover total : {total_formal_files} fichiers audités hors commentaires")

    return cat


def _check_zenodo_cff_spdx(
    root: Path,
    zenodo_data: dict[str, Any] | None,
    manifest_data: dict[str, Any] | None,
    tracked_files: list[str],
    all_repo_files: list[str],
) -> CategoryResult:
    cat = CategoryResult(
        "zenodo_cff_spdx",
        "3. Conformité Zenodo, CFF et gouvernance SPDX",
    )

    if zenodo_data is None:
        cat.fail(".zenodo.json invalide ou absent.")
    else:
        cat.ok(".zenodo.json JSON valide")
        lic = zenodo_data.get("license")
        if not isinstance(lic, str) or not lic.strip():
            cat.fail(".zenodo.json['license'] manquant ou vide.")
        elif re.search(r"(?:^|\s)(?:AND|OR)(?:\s|$)", lic, re.IGNORECASE) or not ZENODO_SINGLE_LICENSE_RE.fullmatch(lic):
            cat.fail(
                f".zenodo.json['license']='{lic}' doit être un identifiant SPDX unique compatible API Zenodo (sans 'AND')."
            )
        else:
            cat.ok(f".zenodo.json['license'] = '{lic}' (identifiant unique valide)")

        for field_name in ("description", "notes"):
            val = zenodo_data.get(field_name)
            if not isinstance(val, str) or not val.strip():
                cat.fail(f".zenodo.json['{field_name}'] manquant ou vide.")
                continue
            low = val.lower()
            has_agpl = "agpl-3.0-or-later" in low
            has_cc = "cc-by-nc-sa-4.0" in low or "cc by-nc-sa 4.0" in low
            has_cipo = "1233199" in low
            if not (has_agpl and has_cc):
                cat.fail(
                    f".zenodo.json['{field_name}'] doit mentionner explicitement la double licence AGPL-3.0-or-later et CC BY-NC-SA 4.0."
                )
            elif not has_cipo:
                cat.fail(f".zenodo.json['{field_name}'] doit mentionner l'enregistrement CIPO/OPIC 1233199.")
            else:
                cat.ok(f".zenodo.json['{field_name}'] conforme (double licence + 1233199)")

    if manifest_data is None:
        cat.fail("manifest.json invalide ou absent.")
    else:
        cat.ok("manifest.json JSON valide")

    # Unicité et contenu de CITATION.cff
    cff_candidates = sorted({
        rel for rel in (set(tracked_files) | set(all_repo_files))
        if Path(rel).name.lower() == "citation.cff"
    })
    extra_cff = [rel for rel in cff_candidates if rel != "CITATION.cff"]
    cff_path = root / "CITATION.cff"
    if not cff_path.is_file():
        cat.fail("CITATION.cff racine manquant.")
    if extra_cff:
        cat.fail(f"CITATION.cff dupliqué(s) dans les sous-dossiers : {extra_cff}")
    elif cff_path.is_file():
        cat.ok("CITATION.cff unique à la racine")
        cff_text = _read_text(cff_path)
        if not re.search(
            r'^license:\s*["\']?AGPL-3\.0-or-later\s+AND\s+CC-BY-NC-SA-4\.0["\']?\s*$',
            cff_text,
            re.MULTILINE,
        ):
            cat.fail("CITATION.cff doit déclarer license: 'AGPL-3.0-or-later AND CC-BY-NC-SA-4.0'.")
        else:
            cat.ok("CITATION.cff license = AGPL-3.0-or-later AND CC-BY-NC-SA-4.0")

        required_ids = (
            "10.5281/zenodo.23833938",
            "10.5281/zenodo.24022795",
            "https://osf.io/z89sg",
            "1233199",
        )
        missing_ids = [rid for rid in required_ids if rid not in cff_text]
        if missing_ids:
            cat.fail(f"CITATION.cff ne référence pas tous les identifiants requis : {missing_ids}")
        else:
            cat.ok("CITATION.cff contient les 4 identifiants (2 DOIs Zenodo, OSF, CIPO 1233199)")

    # NOTICE
    notice_path = root / "NOTICE"
    if not notice_path.is_file():
        cat.fail("Fichier racine NOTICE manquant.")
    else:
        notice_text = _read_text(notice_path)
        if "SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0" not in notice_text:
            cat.fail("NOTICE ne contient pas la ligne SPDX-License-Identifier attendue.")
        else:
            cat.ok("NOTICE contient la clause SPDX complète")

        if "Hybrid files separation clause" not in notice_text or "CC BY-NC-SA 4.0" not in notice_text:
            cat.fail("NOTICE ne contient pas la clause de séparation des fichiers hybrides.")
        else:
            cat.ok("NOTICE contient la clause de séparation des fichiers hybrides")

        if manifest_data is not None:
            hybrid_files = manifest_data.get("licenses", {}).get("hybrid_files")
            if not isinstance(hybrid_files, list) or not hybrid_files:
                cat.fail("manifest.json licenses.hybrid_files est absent ou vide.")
            else:
                missing_hybrid = [hf for hf in hybrid_files if hf not in notice_text]
                if missing_hybrid:
                    cat.fail(f"NOTICE omet des fichiers hybrides listés dans manifest.json : {missing_hybrid}")
                else:
                    cat.ok(f"NOTICE liste les {len(hybrid_files)} fichiers hybrides du manifest")

    return cat


def _check_epistemic_compartmentalization(root: Path) -> CategoryResult:
    cat = CategoryResult(
        "epistemic_compartmentalization",
        "4. Cloisonnement épistémique Strate 0 / Strate 1",
    )

    required_docs = (
        "extensions/lexicon/EPISTEMIC_STATUS.md",
        "extensions/in_silico/EPISTEMIC_STATUS.md",
        "docs/CONVERGENCE_MATRIX.md",
    )
    for rel in required_docs:
        path = root / rel
        if not path.is_file() or not _read_text(path).strip():
            cat.fail(f"Document épistémique requis manquant ou vide : {rel}")
        else:
            cat.ok(f"Présent : {rel}")

    article_path = root / "docs/01-Article_Cartograffect.md"
    if not article_path.is_file():
        cat.fail("docs/01-Article_Cartograffect.md introuvable pour le contrôle A4-Sanctuaire.")
    else:
        article_text = _read_text(article_path)
        split_match = re.search(r"^##\s+Disponibilité des données", article_text, re.MULTILINE)
        theoretical_body = article_text[: split_match.start()] if split_match else article_text
        hits: list[str] = []
        for lineno, line in enumerate(theoretical_body.splitlines(), 1):
            for label, pattern in A4_FORBIDDEN_PATTERNS:
                if pattern.search(line):
                    hits.append(f"L{lineno} ({label})")
        if hits:
            cat.fail(
                f"Violation A4-Sanctuaire dans le corps théorique de docs/01-Article_Cartograffect.md : {hits}"
            )
        else:
            cat.ok("Garde A4-Sanctuaire : 0 métrique PXP/min r dans le corps théorique")

        # Garde d'intégrité éditoriale & transparence IA dans docs/01-Article_Cartograffect.md
        if re.search(r"(?:49\s*\+|references-v2)", article_text, re.IGNORECASE):
            cat.fail("docs/01-Article_Cartograffect.md contient un marqueur obsolète (49+ / references-v2).")
        else:
            cat.ok("0 marqueur obsolète (49+ / references-v2) dans docs/01-Article_Cartograffect.md")

        art_low = article_text.lower()
        has_art_ai_honesty = (
            "non mathématicien formel" in art_low
            and "traduction" in art_low
            and "ligne par ligne" in art_low
            and "vérification mécanique" in art_low
            and "tests automatisés" in art_low
            and "audit" in art_low
        )
        if not has_art_ai_honesty:
            cat.fail(
                "docs/01-Article_Cartograffect.md doit inclure la déclaration IA explicite "
                "(non mathématicien formel, traduction, ligne par ligne, vérification mécanique, tests automatisés, audit)."
            )
        else:
            cat.ok("Déclaration IA explicite vérifiée dans docs/01-Article_Cartograffect.md")

    readme_path = root / "README.md"
    if not readme_path.is_file():
        cat.fail("README.md introuvable pour le contrôle de transparence IA.")
    else:
        readme_low = _read_text(readme_path).lower()
        has_readme_ai_honesty = (
            "non mathématicien formel" in readme_low
            and "traduction" in readme_low
            and "ligne par ligne" in readme_low
            and "vérification mécanique" in readme_low
            and "tests automatisés" in readme_low
            and "audit" in readme_low
        )
        if not has_readme_ai_honesty:
            cat.fail(
                "README.md doit inclure la déclaration IA explicite "
                "(non mathématicien formel, traduction, ligne par ligne, vérification mécanique, tests automatisés, audit)."
            )
        else:
            cat.ok("Déclaration IA explicite vérifiée dans README.md")

    return cat


def _check_zero_leak_zenodo_hygiene(
    root: Path,
    tracked_files: list[str],
    git_error: str | None,
    strict: bool,
) -> CategoryResult:
    cat = CategoryResult(
        "zero_leak_zenodo_hygiene",
        "5. Scan Zéro-Fuite et hygiène d'archivage Zenodo (git ls-files)",
    )

    if git_error is not None or not tracked_files:
        cat.fail(f"Impossible d'énumérer les fichiers suivis Git : {git_error or 'aucun fichier suivi'}")
        return cat

    cat.ok(f"{len(tracked_files)} fichiers suivis analysés")

    leak_hits: list[str] = []
    institutional_hits: list[str] = []
    env_files: list[str] = []
    raw_third_party: list[str] = []
    oversized: list[str] = []
    missing_tracked: list[str] = []

    for rel in tracked_files:
        name = Path(rel).name
        if name == ".env" or name.startswith(".env."):
            env_files.append(rel)
        if _is_raw_third_party_filename(rel):
            raw_third_party.append(rel)

        path = root / rel
        if not path.is_file():
            missing_tracked.append(rel)
            continue

        size = path.stat().st_size
        if size > MAX_FILE_BYTES:
            oversized.append(f"{rel} ({size / (1024 * 1024):.2f} MiB)")

        if rel in LEAK_SELF_EXEMPT or path.suffix.lower() in BINARY_EXTENSIONS:
            continue

        raw_bytes = path.read_bytes()
        if b"\x00" in raw_bytes[:8192]:
            continue

        text = raw_bytes.decode("utf-8", errors="replace")
        for label, pattern in LEAK_PATTERNS:
            if pattern.search(text):
                for lineno, line in enumerate(text.splitlines(), 1):
                    if pattern.search(line):
                        leak_hits.append(f"{rel}:{lineno} ({label})")
        for label, pattern in FORBIDDEN_INSTITUTIONAL_PATTERNS:
            if pattern.search(text):
                for lineno, line in enumerate(text.splitlines(), 1):
                    if pattern.search(line):
                        institutional_hits.append(f"{rel}:{lineno} ({label})")

    if missing_tracked:
        cat.warn(f"Fichiers suivis absents du répertoire de travail : {missing_tracked}", strict=strict)

    if leak_hits:
        cat.fail(f"Fuites locales détectées dans les fichiers suivis : {leak_hits[:20]}")
    else:
        cat.ok("Zéro-Fuite : 0 chemin utilisateur/local dans les fichiers texte suivis")

    if institutional_hits:
        cat.fail(
            f"Mentions institutionnelles retirées détectées dans les fichiers suivis : {institutional_hits[:20]}"
        )
    else:
        cat.ok("Zéro mention institutionnelle retirée dans les fichiers texte suivis")

    if env_files:
        cat.fail(f"Fichiers .env suivis interdits : {env_files}")
    else:
        cat.ok("0 fichier .env / .env.* suivi")

    if raw_third_party:
        cat.fail(f"Fichiers bruts tiers suivis interdits : {raw_third_party}")
    else:
        cat.ok("0 fichier brut tiers (NRC-VAD, DIMA_GROUPE, FANCat brut, Diamant 55K)")

    if oversized:
        cat.fail(f"Fichiers individuels dépassant 20 MiB : {oversized}")
    else:
        cat.ok("0 fichier individuel > 20 MiB")

    gitattributes_path = root / ".gitattributes"
    if not gitattributes_path.is_file():
        cat.fail(".gitattributes introuvable.")
    else:
        lfs_lines: list[str] = []
        for lineno, line in enumerate(_read_text(gitattributes_path).splitlines(), 1):
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            if "filter=lfs" in stripped.lower():
                lfs_lines.append(f"L{lineno}: {stripped}")
        if lfs_lines:
            cat.fail(f"Règle(s) Git LFS interdite(s) dans .gitattributes : {lfs_lines}")
        else:
            cat.ok("0 règle filter=lfs dans .gitattributes")

    return cat


def _check_tracked_results_json(
    root: Path,
    tracked_files: list[str],
    git_error: str | None,
) -> CategoryResult:
    cat = CategoryResult(
        "tracked_results_json",
        "6. Validité des résultats JSON suivis",
    )

    if git_error is not None:
        cat.fail(f"Impossible de lister les résultats JSON suivis : {git_error}")
        return cat

    json_rels = sorted(
        rel for rel in tracked_files
        if rel.startswith("extensions/in_silico/results/") and rel.endswith(".json")
    )
    if not json_rels:
        cat.fail("Aucun fichier JSON suivi trouvé sous extensions/in_silico/results/.")
        return cat

    for rel in json_rels:
        path = root / rel
        if not path.is_file():
            cat.fail(f"Résultat JSON suivi manquant sur disque : {rel}")
            continue
        try:
            raw_text = _read_text(path)
            parsed = json.loads(raw_text)
        except json.JSONDecodeError as exc:
            cat.fail(f"JSON invalide dans {rel} : {exc}")
            continue

        path_hits = _find_windows_paths_in_json(parsed)
        if path_hits:
            sample = [f"{loc}={val!r}" for loc, val in path_hits[:5]]
            cat.fail(f"Chemin(s) absolu(s) Windows dans {rel} : {sample}")
        else:
            cat.ok(f"{rel} valide et sans chemin Windows")

    return cat


def _check_site_payload_contract(
    root: Path,
    version: str | None,
    manifest_data: dict[str, Any] | None,
) -> CategoryResult:
    cat = CategoryResult(
        "site_payload_contract",
        "7. Contrat d'export web (scripts/export_site_payload.py)",
    )

    exporter = root / "scripts/export_site_payload.py"
    if not exporter.is_file():
        cat.fail("Script requis manquant : scripts/export_site_payload.py")
        return cat
    cat.ok("Présent : scripts/export_site_payload.py")

    check_proc = subprocess.run(
        [sys.executable, str(exporter), "--check", "--root", str(root)],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    if check_proc.returncode != 0:
        detail = (check_proc.stderr or check_proc.stdout).strip()
        cat.fail(f"export_site_payload.py --check a échoué (code {check_proc.returncode}) : {detail}")
        return cat
    cat.ok("export_site_payload.py --check passe (code 0)")

    emit_proc = subprocess.run(
        [sys.executable, str(exporter), "--root", str(root)],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    if emit_proc.returncode != 0:
        detail = (emit_proc.stderr or emit_proc.stdout).strip()
        cat.fail(f"export_site_payload.py a échoué à l'émission JSON : {detail}")
        return cat

    try:
        payload = json.loads(emit_proc.stdout)
    except json.JSONDecodeError as exc:
        cat.fail(f"Sortie JSON invalide depuis export_site_payload.py : {exc}")
        return cat

    if not isinstance(payload, dict):
        cat.fail("export_site_payload.py doit émettre un objet JSON racine.")
        return cat

    if manifest_data is None or version is None:
        cat.fail("VERSION ou manifest.json indisponible pour comparer le payload web.")
        return cat

    rel = payload.get("release", {})
    ids_pay = payload.get("identifiers", {})
    s0_pay = payload.get("strate_0_core", {})
    s0_man = manifest_data.get("strate_0_core", {})
    lic_pay = payload.get("licenses", {})
    lic_man = manifest_data.get("licenses", {})
    ai_pay = payload.get("ai_disclosure", {})
    ai_verif = str(ai_pay.get("verification_and_audit_status", "")).lower()

    checks = [
        (payload.get("schema_version") == "1.0", f"schema_version={payload.get('schema_version')!r} != '1.0'"),
        (
            ids_pay.get("cipo_registration") == "1233199",
            f"identifiers.cipo_registration={ids_pay.get('cipo_registration')!r} != '1233199'",
        ),
        (rel.get("version") == version, f"release.version={rel.get('version')!r} != '{version}'"),
        (rel.get("tag") == f"v{version}", f"release.tag={rel.get('tag')!r} != 'v{version}'"),
        (
            rel.get("date") == manifest_data.get("release_date"),
            f"release.date={rel.get('date')!r} != manifest.release_date={manifest_data.get('release_date')!r}",
        ),
        (
            s0_pay.get("theorems_verified") == s0_man.get("theorems_verified"),
            f"theorems_verified={s0_pay.get('theorems_verified')!r} != {s0_man.get('theorems_verified')!r}",
        ),
        (s0_pay.get("sorry_count") == 0, f"sorry_count={s0_pay.get('sorry_count')!r} != 0"),
        (len(s0_pay.get("provers", [])) == 6, f"provers count={len(s0_pay.get('provers', []))} != 6"),
        (s0_pay.get("lean_modules_count") == 11, f"lean_modules_count={s0_pay.get('lean_modules_count')!r} != 11"),
        (s0_pay.get("states_count") == 176, f"states_count={s0_pay.get('states_count')!r} != 176"),
        (s0_pay.get("predictions_count") == 5, f"predictions_count={s0_pay.get('predictions_count')!r} != 5"),
        (
            s0_pay.get("lexicon176_sha256") == s0_man.get("lexicon_176", {}).get("sha256"),
            "lexicon176_sha256 du payload != manifest.json",
        ),
        (
            lic_pay.get("spdx_expression") == lic_man.get("spdx_expression"),
            f"licenses.spdx_expression={lic_pay.get('spdx_expression')!r} != {lic_man.get('spdx_expression')!r}",
        ),
        (
            bool(ai_pay.get("author_ownership"))
            and bool(ai_pay.get("ai_assistance_scope"))
            and "non mathématicien formel" in ai_verif
            and "ligne par ligne" in ai_verif
            and "tests automatisés" in ai_verif
            and "audit" in ai_verif,
            "Bloc ai_disclosure manquant ou incomplet dans le payload web.",
        ),
    ]
    for ok_cond, err_msg in checks:
        if not ok_cond:
            cat.fail(err_msg)

    if cat.passed:
        cat.ok(
            f"Payload web cohérent avec VERSION={version} et manifest.json "
            f"({s0_pay.get('theorems_verified')} th., {len(s0_pay.get('provers', []))} prouveurs, "
            f"{s0_pay.get('states_count')} états, {s0_pay.get('predictions_count')} prédictions)"
        )

    return cat


def run_checks(root: Path, strict: bool = False) -> dict[str, Any]:
    """Exécute les 7 groupes de contrôles sur `root` et retourne un rapport structuré."""
    t0 = time.perf_counter()
    resolved_root = root.resolve()

    tracked_files, git_error = _git_ls_files(resolved_root)
    all_repo_files = _iter_repo_files(resolved_root)

    # Lecture préalable des JSON structurants (validés aussi dans la catégorie 3)
    scratch = CategoryResult("_pre", "preload")
    zenodo_data = _load_json_dict(resolved_root / ".zenodo.json", ".zenodo.json", scratch)
    manifest_data = _load_json_dict(resolved_root / "manifest.json", "manifest.json", scratch)

    cat1, version = _check_version_parity(resolved_root, zenodo_data, manifest_data)
    cat2 = _check_strate0_integrity(resolved_root, manifest_data, tracked_files, all_repo_files)
    cat3 = _check_zenodo_cff_spdx(
        resolved_root, zenodo_data, manifest_data, tracked_files, all_repo_files
    )
    cat4 = _check_epistemic_compartmentalization(resolved_root)
    cat5 = _check_zero_leak_zenodo_hygiene(resolved_root, tracked_files, git_error, strict=strict)
    cat6 = _check_tracked_results_json(resolved_root, tracked_files, git_error)
    cat7 = _check_site_payload_contract(resolved_root, version, manifest_data)

    categories = [cat1, cat2, cat3, cat4, cat5, cat6, cat7]
    all_passed = all(c.passed for c in categories)
    elapsed_ms = round((time.perf_counter() - t0) * 1000.0, 2)

    return {
        "status": "PASS" if all_passed else "FAIL",
        "strict": strict,
        "root": resolved_root.as_posix(),
        "version": version,
        "elapsed_ms": elapsed_ms,
        "summary": {
            "categories_total": len(categories),
            "categories_passed": sum(1 for c in categories if c.passed),
            "categories_failed": sum(1 for c in categories if not c.passed),
            "total_errors": sum(len(c.errors) for c in categories),
            "total_warnings": sum(len(c.warnings) for c in categories),
        },
        "categories": [c.to_dict() for c in categories],
    }


def _print_human_report(report: dict[str, Any]) -> None:
    print(
        f"CARTOGRAFFECT Consistency Guard — status={report['status']} "
        f"(version={report['version']}, strict={report['strict']}, {report['elapsed_ms']:.1f} ms)"
    )
    print(f"Root: {report['root']}")
    print("-" * 72)
    for cat in report["categories"]:
        badge = "PASS" if cat["passed"] else "FAIL"
        print(f"[{badge}] {cat['title']} ({cat['checks_count']} contrôles OK)")
        for err in cat["errors"]:
            print(f"   ERROR: {err}")
        for warn in cat["warnings"]:
            print(f"   WARN:  {warn}")
    print("-" * 72)
    s = report["summary"]
    print(
        f"Résumé: {s['categories_passed']}/{s['categories_total']} catégories conformes, "
        f"{s['total_errors']} erreur(s), {s['total_warnings']} avertissement(s)."
    )


def main(argv: list[str] | None = None) -> int:
    _configure_stdio()
    parser = argparse.ArgumentParser(
        description="Vérifie les 7 groupes d'invariants du compendium CARTOGRAFFECT®."
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Échoue également sur tout avertissement et exige un index Git valide.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Émet le rapport détaillé au format JSON sur stdout.",
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
        help="Racine du dépôt à auditer (par défaut : racine du compendium).",
    )
    args = parser.parse_args(argv)

    report = run_checks(args.root, strict=args.strict)
    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        _print_human_report(report)

    return 0 if report["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
