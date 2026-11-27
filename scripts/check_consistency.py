#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""
Garde-fou automatisé de cohérence scientifique, formelle, juridique (OSI/FAIR4RS)
et d'archivage pour le compendium CARTOGRAFFECT v3.0.0 (Strate 0 / Strate 1).

Vérifie les 7 groupes d'invariants sans aucune dépendance externe
(bibliothèque standard Python 3.10+ uniquement) :
  1. version_parity               — Parité stricte de VERSION (3.0.0) à travers le compendium
  2. strate0_integrity            — Compteurs v3.0.0 (8 modules normatifs, 148 th. substantiels / 169 exportés,
                                    8 piliers, PredictiveEngineCanonical 16+5=21, 11 tests Python),
                                    0 sorry / 0 native_decide / 0 computeActivation, isolation de Lexicon176.lean,
                                    et contrôle lecture seule 0 trou des suites archivées v2.1
  3. zenodo_cff_spdx              — Séparation physique OSI (AGPL-3.0-or-later code) / CC-BY-4.0 (docs & tables),
                                    0 clause non commerciale (NC) dans le code source, FAIR4RS pins + lockfile + DATA_PROVENANCE.md
  4. epistemic_compartmentalization — Chartes Strate 1, ARCHIVE_V2_HYBRID_Y_WARNING.md, CONVERGENCE_MATRIX.md,
                                    garde A4-Sanctuaire, transparence IA & lien FORMAL_AUDIT_PACK.md
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

FORBIDDEN_LEAN_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("sorry", re.compile(r"\bsorry\b")),
    ("admit", re.compile(r"\badmit\b")),
    ("native_decide", re.compile(r"\bnative_decide\b")),
    ("axiom", re.compile(r"\baxiom\b")),
    ("unsafe", re.compile(r"\bunsafe\b")),
    ("noncomputable", re.compile(r"\bnoncomputable\b")),
    ("computeActivation", re.compile(r"\bcomputeActivation\b")),
)

FORBIDDEN_ARCHIVE_FORMAL_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
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

# Motifs construits dynamiquement afin d'éviter toute auto-détection dans ce fichier Python.
LEGACY_NC_LICENSE_FILE = "LICENSE-" + "CC-BY-" + "NC-SA-4.0.md"
NC_LICENSE_PATTERN = re.compile(r"CC[- ]BY[- ]N" + r"C[- ]SA", re.IGNORECASE)

V3_OBSOLETE_DOC_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("invalid-llm-id", re.compile(r"gemini-3\." + r"8-flash", re.IGNORECASE)),
    ("obsolete-constructive-epithet", re.compile(r"th[eé]or[eè]mes\s+(?:purement\s+)?con" + r"structifs", re.IGNORECASE)),
    ("removed-activation-fn", re.compile(r"\bcompute" + r"Activation\b")),
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


def _parse_pyproject_data(text: str) -> dict[str, Any] | None:
    if tomllib is not None:
        return tomllib.loads(text)
    return None


def _parse_pyproject_version(text: str) -> str | None:
    data = _parse_pyproject_data(text)
    if data is not None:
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


def _extract_cff_licenses(cff_text: str) -> list[str]:
    inline = re.search(r'^license:\s*\[([^\]]+)\]\s*$', cff_text, re.MULTILINE)
    if inline:
        return [item.strip().strip("\"'") for item in inline.group(1).split(",") if item.strip()]
    block = re.search(r'^license:\s*\n((?:[ \t]+-\s+[^\r\n]+\n?)+)', cff_text, re.MULTILINE)
    if block:
        return [
            re.sub(r'^[ \t]+-\s+', '', ln).strip().strip("\"'")
            for ln in block.group(1).splitlines()
            if ln.strip()
        ]
    m = re.search(r'^license:\s*["\']?([^"\'\r\n]+)["\']?\s*$', cff_text, re.MULTILINE)
    return [m.group(1).strip()] if m else []


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

    if zenodo_data is None:
        cat.fail(".zenodo.json indisponible pour le contrôle de version.")
    else:
        z_ver = zenodo_data.get("version")
        if z_ver != version:
            cat.fail(f".zenodo.json version='{z_ver}' != VERSION '{version}'.")
        else:
            cat.ok(f".zenodo.json version = {z_ver}")

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
            cat.fail(f"manifest.json strate_0_core.manuscript.version='{ms_ver}' != '{version}'.")
        else:
            cat.ok(f"manifest.json manuscript.version = {ms_ver}")

    pyproject_path = root / "extensions/in_silico/pyproject.toml"
    if not pyproject_path.is_file():
        cat.fail("extensions/in_silico/pyproject.toml introuvable.")
    else:
        py_ver = _parse_pyproject_version(_read_text(pyproject_path))
        if py_ver != version:
            cat.fail(f"extensions/in_silico/pyproject.toml version='{py_ver}' != '{version}'.")
        else:
            cat.ok(f"extensions/in_silico/pyproject.toml version = {py_ver}")

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
        "2. Intégrité cryptographique et formelle v3.0.0 (Lean 4 référence unique)",
    )

    audit_pack = root / "FORMAL_AUDIT_PACK.md"
    if not audit_pack.is_file():
        cat.fail("FORMAL_AUDIT_PACK.md introuvable.")
    else:
        ap_text = _read_text(audit_pack)
        if "148" in ap_text and "169" in ap_text and "Top 8" in ap_text:
            cat.ok("FORMAL_AUDIT_PACK.md présent et cohérent (148 substantiels / 169 exportés / Top 8 piliers)")
        else:
            cat.fail("FORMAL_AUDIT_PACK.md incomplet vis-à-vis des compteurs v3.0.0 (148 / 169 / Top 8).")

    lexicon_rel = "Cartograffect/Lexicon176.lean"
    lexicon_path = root / lexicon_rel
    if not lexicon_path.is_file():
        cat.fail(f"{lexicon_rel} introuvable.")
    elif manifest_data is None:
        cat.fail("manifest.json indisponible pour vérifier le SHA-256 de Lexicon176.lean.")
    else:
        actual_sha = hashlib.sha256(lexicon_path.read_bytes()).hexdigest()
        lex_meta = manifest_data.get("exploratory_annexes", {}).get("lexicon_176", {})
        expected_sha = lex_meta.get("sha256")
        if actual_sha != expected_sha:
            cat.fail(
                f"Rupture SHA-256 pour {lexicon_rel} : calculé={actual_sha}, attendu(manifest)={expected_sha}."
            )
        else:
            cat.ok(f"{lexicon_rel} (annexe exploratoire) SHA-256 vérifié ({actual_sha[:16]}...)")

    normative_modules: list[str] = []
    if manifest_data is not None:
        s0 = manifest_data.get("strate_0_core", {})
        expected_counts = [
            ("normative_modules_count", 8),
            ("theorems_substantial", 148),
            ("exported_declarations", 169),
            ("auxiliary_lemmas", 21),
            ("pillar_theorems_count", 8),
            ("sorry_count", 0),
            ("native_decide_count", 0),
            ("custom_axioms_count", 0),
        ]
        for key, exp in expected_counts:
            got = s0.get(key)
            if got != exp:
                cat.fail(f"manifest.json strate_0_core.{key}={got!r} != {exp}.")
            else:
                cat.ok(f"manifest.json strate_0_core.{key} = {exp}")

        ext = s0.get("canonical_extension", {})
        if (
            ext.get("theorems_own") != 16
            or ext.get("auxiliary_lemmas") != 5
            or ext.get("exported_declarations") != 21
        ):
            cat.fail(f"manifest.json canonical_extension compteurs invalides : {ext!r}")
        else:
            cat.ok("manifest.json PredictiveEngineCanonical = 16 propres + 5 auxiliaires = 21")

        py_tests = s0.get("python_isomorphic_engine", {}).get("unit_tests_count")
        if py_tests != 11:
            cat.fail(f"manifest.json python_isomorphic_engine.unit_tests_count={py_tests!r} != 11.")
        else:
            cat.ok("manifest.json python_isomorphic_engine.unit_tests_count = 11")

        normative_modules = list(s0.get("normative_lean_modules", []))
        if len(normative_modules) != 8:
            cat.fail(f"manifest.json normative_lean_modules doit lister 8 fichiers (trouvé : {len(normative_modules)}).")
        else:
            missing = [lf for lf in normative_modules if not (root / lf).is_file()]
            if missing:
                cat.fail(f"Modules normatifs Lean 4 manquants sur disque : {missing}")
            elif lexicon_rel in normative_modules:
                cat.fail("Cartograffect/Lexicon176.lean ne doit pas figurer dans normative_lean_modules.")
            else:
                cat.ok("8/8 modules normatifs Lean 4 présents sur disque (Lexicon176 isolé en annexe)")

    isolation_targets = [root / lf for lf in normative_modules if (root / lf).is_file()]
    canon_ext_path = root / "extensions/predictive_engine/PredictiveEngineCanonical.lean"
    if canon_ext_path.is_file():
        isolation_targets.append(canon_ext_path)
    else:
        cat.fail("extensions/predictive_engine/PredictiveEngineCanonical.lean introuvable.")

    lex_import_hits: list[str] = []
    for path in isolation_targets:
        stripped = _strip_comments_and_strings(_read_text(path), "lean")
        if re.search(r"^\s*import\s+Cartograffect\.Lexicon176\b", stripped, re.MULTILINE):
            lex_import_hits.append(path.relative_to(root).as_posix())
    if lex_import_hits:
        cat.fail(f"Import interdit de Lexicon176 dans le cœur normatif / extension : {lex_import_hits}")
    else:
        cat.ok("Isolation stricte : 0 import de Lexicon176 dans les 8 modules normatifs et PredictiveEngineCanonical")

    dup_lexicons = sorted({
        rel for rel in (set(tracked_files) | set(all_repo_files))
        if Path(rel).name.lower() == "lexicon176.lean" and rel != lexicon_rel
    })
    if dup_lexicons:
        cat.fail(f"Doublon(s) Lexicon176.lean hors {lexicon_rel} : {dup_lexicons}")
    else:
        cat.ok("0 doublon Lexicon176.lean hors Cartograffect/")

    for retired in (
        "extensions/lexicon/lean/SchererGRID.lean",
        "extensions/lexicon/src/grid_cpm_integration.py",
    ):
        if (root / retired).is_file():
            cat.fail(f"Artefact synthétique retiré encore présent hors archive/ : {retired}")
    cat.ok("0 artefact synthétique retiré (SchererGRID.lean / grid_cpm_integration.py) hors archive/")

    # Audit statique Lean 4 actif hors commentaires et littéraux
    lean_suites: list[tuple[str, list[Path]]] = [
        (
            "Lean 4 cœur & annexe (Cartograffect/)",
            ([root / "Cartograffect.lean"] if (root / "Cartograffect.lean").is_file() else [])
            + sorted((root / "Cartograffect").rglob("*.lean") if (root / "Cartograffect").is_dir() else []),
        ),
        (
            "Lean 4 extension canonique (PredictiveEngineCanonical)",
            [canon_ext_path] if canon_ext_path.is_file() else [],
        ),
    ]
    strate1_lean_paths = sorted(
        (root / "extensions/lexicon/lean").rglob("*.lean")
        if (root / "extensions/lexicon/lean").is_dir()
        else []
    )
    if strate1_lean_paths:
        lean_suites.append(("Lean 4 Strate 1 (extensions/lexicon/lean)", strate1_lean_paths))

    for suite_name, paths in lean_suites:
        if not paths:
            cat.fail(f"Aucun fichier Lean trouvé pour {suite_name}.")
            continue
        hits: list[str] = []
        for path in paths:
            rel = path.relative_to(root).as_posix()
            stripped = _strip_comments_and_strings(_read_text(path), "lean")
            for lineno, line in enumerate(stripped.splitlines(), 1):
                for label, pattern in FORBIDDEN_LEAN_PATTERNS:
                    if pattern.search(line):
                        hits.append(f"{rel}:{lineno} ({label})")
        if hits:
            cat.fail(f"{suite_name} contient des marqueurs interdits : {hits}")
        else:
            cat.ok(f"{suite_name} ({len(paths)} fichiers) : 0 sorry / native_decide / axiom / computeActivation")

    # Contrôle statique lecture seule des 5 suites archivées v2.1 (aucun affaiblissement des gardes historiques)
    archived_suites: list[tuple[str, str, list[Path]]] = [
        ("Rocq (archive figée v2.1)", "rocq", sorted((root / "rocq/theories").rglob("*.v") if (root / "rocq/theories").is_dir() else [])),
        ("Agda (archive figée v2.1)", "agda", sorted((root / "agda/src").rglob("*.agda") if (root / "agda/src").is_dir() else [])),
        ("Dafny (archive figée v2.1)", "dafny", sorted((root / "dafny/src").rglob("*.dfy") if (root / "dafny/src").is_dir() else [])),
        ("SMT-LIB 2 (archive figée v2.1)", "smt", sorted((root / "smt/theories").rglob("*.smt2") if (root / "smt/theories").is_dir() else [])),
        (
            "TLA+ (archive figée v2.1)",
            "tla",
            sorted((root / "tla/specs").rglob("*.tla") if (root / "tla/specs").is_dir() else [])
            + sorted((root / "tla/specs").rglob("*.cfg") if (root / "tla/specs").is_dir() else []),
        ),
    ]
    for suite_name, lang, paths in archived_suites:
        if not paths:
            cat.fail(f"Aucun fichier formel trouvé pour {suite_name}.")
            continue
        hits = []
        for path in paths:
            rel = path.relative_to(root).as_posix()
            stripped = _strip_comments_and_strings(_read_text(path), lang)
            for lineno, line in enumerate(stripped.splitlines(), 1):
                for label, pattern in FORBIDDEN_ARCHIVE_FORMAL_PATTERNS:
                    if pattern.search(line):
                        hits.append(f"{rel}:{lineno} ({label})")
        if hits:
            cat.fail(f"{suite_name} contient des marqueurs interdits : {hits}")
        else:
            cat.ok(f"{suite_name} ({len(paths)} fichiers) : 0 trou / axiome")

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
        "3. Licences OSI / CC-BY-4.0, Zenodo, CFF et reproductibilité FAIR4RS",
    )

    if not (root / "LICENSE").is_file():
        cat.fail("Fichier racine LICENSE (AGPL-3.0-or-later) manquant.")
    else:
        cat.ok("LICENSE présent (GNU AGPLv3)")
    if not (root / "LICENSE-CC-BY-4.0.md").is_file():
        cat.fail("Fichier racine LICENSE-CC-BY-4.0.md manquant.")
    else:
        cat.ok("LICENSE-CC-BY-4.0.md présent (CC-BY-4.0)")
    if (root / LEGACY_NC_LICENSE_FILE).is_file():
        cat.fail(f"Fichier obsolète {LEGACY_NC_LICENSE_FILE} encore présent à la racine.")
    else:
        cat.ok("Ancien fichier de licence NC retiré de la racine")

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
        elif lic.lower() != "agpl-3.0-or-later":
            cat.fail(f".zenodo.json['license']='{lic}' attendu 'agpl-3.0-or-later'.")
        else:
            cat.ok(f".zenodo.json['license'] = '{lic}' (OSI unique valide)")

        if "®" in json.dumps(zenodo_data, ensure_ascii=False):
            cat.fail(".zenodo.json contient encore le symbole '®'.")
        else:
            cat.ok(".zenodo.json exempt du symbole '®'")

        for field_name in ("description", "notes"):
            val = zenodo_data.get(field_name)
            if not isinstance(val, str) or not val.strip():
                cat.fail(f".zenodo.json['{field_name}'] manquant ou vide.")
                continue
            low = val.lower()
            has_agpl = "agpl-3.0-or-later" in low
            has_ccby = "cc-by-4.0" in low or "cc by 4.0" in low
            has_nc = bool(NC_LICENSE_PATTERN.search(val))
            has_cipo = "1233199" in low
            if has_nc:
                cat.fail(f".zenodo.json['{field_name}'] contient encore une clause non commerciale (NC) interdite.")
            elif not (has_agpl and has_ccby):
                cat.fail(
                    f".zenodo.json['{field_name}'] doit mentionner AGPL-3.0-or-later (code) et CC-BY-4.0 (docs/tables)."
                )
            elif not has_cipo:
                cat.fail(f".zenodo.json['{field_name}'] doit mentionner l'enregistrement CIPO/OPIC 1233199.")
            else:
                cat.ok(f".zenodo.json['{field_name}'] conforme (AGPL-3.0-or-later + CC-BY-4.0 + 1233199, 0 NC)")

    if manifest_data is None:
        cat.fail("manifest.json invalide ou absent.")
    else:
        cat.ok("manifest.json JSON valide")
        m_lic = manifest_data.get("licenses", {})
        if m_lic.get("code_spdx") != "AGPL-3.0-or-later" or m_lic.get("docs_and_data_spdx") != "CC-BY-4.0":
            cat.fail(f"manifest.json licenses invalides : {m_lic!r}")
        elif NC_LICENSE_PATTERN.search(json.dumps(manifest_data)):
            cat.fail("manifest.json contient encore une référence de licence NC interdite.")
        else:
            cat.ok("manifest.json licenses = AGPL-3.0-or-later (code) / CC-BY-4.0 (docs & tables)")

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
        cff_licenses = _extract_cff_licenses(cff_text)
        if NC_LICENSE_PATTERN.search(cff_text):
            cat.fail("CITATION.cff contient encore une clause de licence NC interdite.")
        elif set(cff_licenses) != {"AGPL-3.0-or-later", "CC-BY-4.0"}:
            cat.fail(f"CITATION.cff license={cff_licenses!r} doit être ['AGPL-3.0-or-later', 'CC-BY-4.0'].")
        else:
            cat.ok("CITATION.cff license = [AGPL-3.0-or-later, CC-BY-4.0]")

        if "®" in cff_text:
            cat.fail("CITATION.cff contient encore le symbole '®'.")
        else:
            cat.ok("CITATION.cff exempt du symbole '®'")

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

    notice_path = root / "NOTICE"
    if not notice_path.is_file():
        cat.fail("Fichier racine NOTICE manquant.")
    else:
        notice_text = _read_text(notice_path)
        if NC_LICENSE_PATTERN.search(notice_text):
            cat.fail("NOTICE contient encore une clause de licence NC interdite.")
        elif "®" in notice_text and "no ® trademark symbol" not in notice_text:
            cat.fail("NOTICE contient encore le symbole '®' non justifié.")
        elif "AGPL-3.0-or-later" not in notice_text or "CC-BY-4.0" not in notice_text:
            cat.fail("NOTICE doit documenter la séparation physique AGPL-3.0-or-later / CC-BY-4.0.")
        elif "LICENSE-CC-BY-4.0.md" not in notice_text:
            cat.fail("NOTICE doit référencer LICENSE-CC-BY-4.0.md.")
        else:
            cat.ok("NOTICE conforme (séparation physique AGPL-3.0-or-later / CC-BY-4.0, 0 NC)")

    # Propreté juridique OSI : 0 clause non commerciale (NC) dans TOUS les fichiers de code source actifs
    code_roots = (
        root / "Cartograffect.lean",
        root / "Cartograffect",
        root / "python",
        root / "scripts",
        root / "extensions/predictive_engine",
        root / "extensions/in_silico/pyproject.toml",
        root / "extensions/in_silico/src",
        root / "extensions/in_silico/experiments",
        root / "extensions/in_silico/tests",
        root / "extensions/lexicon/lean",
        root / "extensions/lexicon/src",
        root / "extensions/lexicon/scripts",
    )
    code_suffixes = frozenset({".lean", ".py", ".js", ".toml"})
    code_nc_hits: list[str] = []
    scanned_code = 0
    for item in code_roots:
        if item.is_file():
            files = [item]
        elif item.is_dir():
            files = sorted(p for p in item.rglob("*") if p.is_file() and p.suffix in code_suffixes)
        else:
            files = []
        for path in files:
            rel = path.relative_to(root).as_posix()
            scanned_code += 1
            if NC_LICENSE_PATTERN.search(_read_text(path)):
                code_nc_hits.append(rel)
    lex_dir = root / "extensions/lexicon"
    if lex_dir.is_dir():
        for path in sorted(lex_dir.glob("*.py")):
            scanned_code += 1
            rel = path.relative_to(root).as_posix()
            if NC_LICENSE_PATTERN.search(_read_text(path)):
                code_nc_hits.append(rel)

    if code_nc_hits:
        cat.fail(f"Clause non commerciale (NC) interdite dans fichier(s) de code source : {code_nc_hits}")
    else:
        cat.ok(f"Propreté OSI : 0 clause non commerciale (NC) dans {scanned_code} fichiers de code source")

    pyproject_path = root / "extensions/in_silico/pyproject.toml"
    if pyproject_path.is_file():
        py_data = _parse_pyproject_data(_read_text(pyproject_path))
        if py_data is not None:
            deps = py_data.get("project", {}).get("dependencies", [])
            unpinned = [d for d in deps if "==" not in str(d)]
            if not deps or unpinned:
                cat.fail(f"FAIR4RS : dépendances non épinglées (==) dans extensions/in_silico/pyproject.toml : {unpinned}")
            else:
                cat.ok(f"FAIR4RS : {len(deps)} dépendances exactement épinglées (==) dans pyproject.toml")
    lock_uv = root / "extensions/in_silico/uv.lock"
    lock_req = root / "extensions/in_silico/requirements.lock"
    if not (lock_uv.is_file() or lock_req.is_file()):
        cat.fail("FAIR4RS : aucun lockfile (uv.lock ou requirements.lock) dans extensions/in_silico/.")
    else:
        lock_name = "uv.lock" if lock_uv.is_file() else "requirements.lock"
        cat.ok(f"FAIR4RS : lockfile reproductible présent (extensions/in_silico/{lock_name})")

    prov_path = root / "DATA_PROVENANCE.md"
    if not prov_path.is_file():
        cat.fail("FAIR4RS : DATA_PROVENANCE.md manquant à la racine.")
    else:
        prov_text = _read_text(prov_path)
        missing_ds = [
            ds for ds in ("NRC-VAD-Lexicon-v2.1.txt", "DIMA_GROUPE_", "FANCatdatabaseRevisee.xlsx")
            if ds not in prov_text
        ]
        if missing_ds:
            cat.fail(f"DATA_PROVENANCE.md ne couvre pas tous les jeux de données tiers : {missing_ds}")
        else:
            cat.ok("FAIR4RS : DATA_PROVENANCE.md couvre NRC-VAD, DIMA et FANCat")

    return cat


def _check_epistemic_compartmentalization(root: Path) -> CategoryResult:
    cat = CategoryResult(
        "epistemic_compartmentalization",
        "4. Cloisonnement épistémique Strate 0 / Strate 1 & transparence IA",
    )

    required_docs = (
        "DECISIONS_V3.md",
        "FORMAL_AUDIT_PACK.md",
        "DATA_PROVENANCE.md",
        "extensions/lexicon/EPISTEMIC_STATUS.md",
        "extensions/lexicon/ARCHIVE_V2_HYBRID_Y_WARNING.md",
        "extensions/in_silico/EPISTEMIC_STATUS.md",
        "extensions/predictive_engine/EPISTEMIC_STATUS.md",
        "docs/CONVERGENCE_MATRIX.md",
        "docs/01-Article_Cartograffect.md",
        "docs/02-Inventaire_176.md",
    )
    for rel in required_docs:
        path = root / rel
        if not path.is_file() or not _read_text(path).strip():
            cat.fail(f"Document épistémique requis manquant ou vide : {rel}")
        else:
            cat.ok(f"Présent : {rel}")

    article_path = root / "docs/01-Article_Cartograffect.md"
    if article_path.is_file():
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

        if re.search(r"(?:49\s*\+|references-v2)", article_text, re.IGNORECASE):
            cat.fail("docs/01-Article_Cartograffect.md contient un marqueur obsolète (49+ / references-v2).")
        else:
            cat.ok("0 marqueur obsolète (49+ / references-v2) dans docs/01-Article_Cartograffect.md")

    ai_markers = ("non mathématicien formel", "traduction", "ligne par ligne", "vérification mécanique", "tests automatisés", "audit")
    for doc_rel in ("docs/01-Article_Cartograffect.md", "README.md", "VALIDATION.md"):
        doc_path = root / doc_rel
        if not doc_path.is_file():
            cat.fail(f"{doc_rel} introuvable pour le contrôle de transparence IA.")
            continue
        low = _read_text(doc_path).lower()
        missing_ai = [m for m in ai_markers if m not in low]
        if missing_ai:
            cat.fail(f"{doc_rel} déclaration IA incomplète (manquant : {missing_ai}).")
        else:
            cat.ok(f"Déclaration IA explicite vérifiée dans {doc_rel}")

    for doc_rel in ("README.md", "VALIDATION.md"):
        doc_path = root / doc_rel
        if doc_path.is_file():
            txt = _read_text(doc_path)
            if "FORMAL_AUDIT_PACK.md" not in txt:
                cat.fail(f"{doc_rel} doit contenir un lien direct vers FORMAL_AUDIT_PACK.md.")
            else:
                cat.ok(f"Lien direct vers FORMAL_AUDIT_PACK.md présent dans {doc_rel}")

    audit_docs = (
        "README.md",
        "VALIDATION.md",
        "docs/CONVERGENCE_MATRIX.md",
        "docs/01-Article_Cartograffect.md",
        "docs/02-Inventaire_176.md",
        "extensions/lexicon/EPISTEMIC_STATUS.md",
        "extensions/in_silico/EPISTEMIC_STATUS.md",
        "extensions/predictive_engine/EPISTEMIC_STATUS.md",
    )
    obsolete_hits: list[str] = []
    for doc_rel in audit_docs:
        doc_path = root / doc_rel
        if not doc_path.is_file():
            continue
        txt = _read_text(doc_path)
        for label, pattern in V3_OBSOLETE_DOC_PATTERNS:
            if pattern.search(txt):
                obsolete_hits.append(f"{doc_rel} ({label})")
    if obsolete_hits:
        cat.fail(f"Motifs obsolètes détectés dans la documentation v3.0.0 : {obsolete_hits}")
    else:
        cat.ok("0 motif obsolète (modèle LLM invalide / épithète constructif / fonction retirée) dans les docs v3.0.0")

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
    annex_pay = payload.get("exploratory_annexes", {}).get("lexicon_176", {})
    annex_man = manifest_data.get("exploratory_annexes", {}).get("lexicon_176", {})
    lic_pay = payload.get("licenses", {})
    lic_man = manifest_data.get("licenses", {})
    ai_pay = payload.get("ai_disclosure", {})
    ai_verif = str(ai_pay.get("verification_and_audit_status", "")).lower()

    checks = [
        (payload.get("schema_version") == "2.0", f"schema_version={payload.get('schema_version')!r} != '2.0'"),
        (ids_pay.get("cipo_registration") == "1233199", f"cipo_registration={ids_pay.get('cipo_registration')!r} != '1233199'"),
        (rel.get("version") == version, f"release.version={rel.get('version')!r} != '{version}'"),
        (rel.get("tag") == f"v{version}", f"release.tag={rel.get('tag')!r} != 'v{version}'"),
        (rel.get("date") == manifest_data.get("release_date"), f"release.date={rel.get('date')!r} != manifest.release_date"),
        (s0_pay.get("normative_modules_count") == 8, f"normative_modules_count={s0_pay.get('normative_modules_count')!r} != 8"),
        (s0_pay.get("theorems_substantial") == s0_man.get("theorems_substantial"), "theorems_substantial mismatch"),
        (s0_pay.get("exported_declarations") == s0_man.get("exported_declarations"), "exported_declarations mismatch"),
        (s0_pay.get("pillar_theorems_count") == 8, "pillar_theorems_count != 8"),
        (s0_pay.get("sorry_count") == 0, "sorry_count != 0"),
        (s0_pay.get("native_decide_count") == 0, "native_decide_count != 0"),
        (s0_pay.get("python_unit_tests_count") == 11, "python_unit_tests_count != 11"),
        (s0_pay.get("predictions_count") == 5, "predictions_count != 5"),
        (annex_pay.get("sha256") == annex_man.get("sha256"), "exploratory_annexes.lexicon_176.sha256 mismatch"),
        (lic_pay.get("code_spdx") == lic_man.get("code_spdx") == "AGPL-3.0-or-later", "licenses.code_spdx mismatch"),
        (lic_pay.get("docs_and_data_spdx") == lic_man.get("docs_and_data_spdx") == "CC-BY-4.0", "licenses.docs_and_data_spdx mismatch"),
        (lic_pay.get("non_commercial_clauses_in_code") is False, "non_commercial_clauses_in_code must be False"),
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
            f"({s0_pay.get('normative_modules_count')} modules, {s0_pay.get('theorems_substantial')}/{s0_pay.get('exported_declarations')} th., "
            f"{s0_pay.get('python_unit_tests_count')} tests Python, {s0_pay.get('predictions_count')} prédictions)"
        )

    return cat


def run_checks(root: Path, strict: bool = False) -> dict[str, Any]:
    """Exécute les 7 groupes de contrôles sur `root` et retourne un rapport structuré."""
    t0 = time.perf_counter()
    resolved_root = root.resolve()

    tracked_files, git_error = _git_ls_files(resolved_root)
    all_repo_files = _iter_repo_files(resolved_root)

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
        description="Vérifie les 7 groupes d'invariants du compendium CARTOGRAFFECT v3.0.0."
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
