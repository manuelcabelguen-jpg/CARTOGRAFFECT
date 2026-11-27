#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""
Utilitaire de synchronisation des métadonnées de version, des compteurs v3.0.0
et de l'empreinte SHA-256 de l'annexe exploratoire `Cartograffect/Lexicon176.lean`
pour le compendium CARTOGRAFFECT (bibliothèque standard Python 3.10+ uniquement).

Sources de vérité :
  - `VERSION` (SemVer strict X.Y.Z)
  - `Cartograffect/Lexicon176.lean` (SHA-256 brut de l'annexe exploratoire)
  - Compteurs normatifs v3.0.0 issus de `FORMAL_AUDIT_PACK.md` :
      8 modules normatifs, 148 théorèmes substantiels (169 déclarations exportées,
      21 auxiliaires, 8 piliers), extension PredictiveEngineCanonical (16 + 5 = 21),
      11 tests unitaires Python.

Cibles synchronisées :
  - `CITATION.cff`
  - `.zenodo.json`
  - `manifest.json`
  - `extensions/in_silico/pyproject.toml`

Par défaut (`--check` / `--dry-run`), affiche les diffs unifiés requis sans
modifier aucun fichier (code 0 si déjà synchronisé, 1 sinon). L'option
explicite `--apply` écrit les modifications avec fins de ligne LF.
"""

from __future__ import annotations

import argparse
import difflib
import hashlib
import json
from pathlib import Path
import re
import sys
from typing import Callable


SEMVER_RE = re.compile(r"^\d+\.\d+\.\d+$")

V3_NORMATIVE_MODULES = 8
V3_THEOREMS_SUBSTANTIAL = 148
V3_EXPORTED_DECLARATIONS = 169
V3_AUXILIARY_LEMMAS = 21
V3_PILLAR_THEOREMS = 8
V3_CANONICAL_EXT_OWN = 16
V3_CANONICAL_EXT_AUX = 5
V3_CANONICAL_EXT_TOTAL = 21
V3_PYTHON_UNIT_TESTS = 11


def _configure_stdio() -> None:
    for stream in (sys.stdout, sys.stderr):
        reconfigure = getattr(stream, "reconfigure", None)
        if callable(reconfigure):
            try:
                reconfigure(encoding="utf-8", errors="replace")
            except Exception:
                pass


def _replace_once(pattern: str, repl: str, text: str, label: str, flags: int = 0) -> str:
    new_text, count = re.subn(pattern, repl, text, count=1, flags=flags)
    if count != 1:
        raise ValueError(f"Motif introuvable ou ambigu pour {label} (count={count}).")
    return new_text


def _sync_citation_cff(text: str, version: str) -> str:
    # 1. Champ racine `version: "..."`
    updated = _replace_once(
        r'^(version:\s*)"[^"\r\n]+"',
        rf'\g<1>"{version}"',
        text,
        "CITATION.cff top-level version",
        flags=re.MULTILINE,
    )
    # 2. Mention (vX.Y.Z) dans la description du DOI manuscrit
    updated = _replace_once(
        r'(description:\s*"Zenodo theoretical reference manuscript DOI \(v)\d+\.\d+\.\d+(\)")',
        rf"\g<1>{version}\g<2>",
        updated,
        "CITATION.cff manuscript DOI description",
        flags=re.MULTILINE,
    )
    # 3. Mention CARTOGRAFFECT vX.Y.Z dans l'abstract
    updated = _replace_once(
        r'(abstract:\s*"CARTOGRAFFECT v)\d+\.\d+\.\d+',
        rf"\g<1>{version}",
        updated,
        "CITATION.cff abstract version",
        flags=re.MULTILINE,
    )
    # 3b. Compteurs v3.0.0 dans l'abstract
    updated = _replace_once(
        r'\b\d+(\s+normative modules \(Cartograffect/\) certifying\s+)\d+(\s+substantial theorems\s+\()\d+(\s+exported declarations)',
        rf"{V3_NORMATIVE_MODULES}\g<1>{V3_THEOREMS_SUBSTANTIAL}\g<2>{V3_EXPORTED_DECLARATIONS}\g<3>",
        updated,
        "CITATION.cff abstract normative theorem counts",
        flags=re.MULTILINE,
    )
    # 4. Champ `preferred-citation:` -> `  version: "..."`
    updated = _replace_once(
        r'(^preferred-citation:\s*\n(?:[ \t]+.*\n)*?[ \t]+version:\s*)"[^"\r\n]+"',
        rf'\g<1>"{version}"',
        updated,
        "CITATION.cff preferred-citation.version",
        flags=re.MULTILINE,
    )
    return updated


def _sync_zenodo_json(text: str, version: str) -> str:
    updated = _replace_once(
        r'^(\s*"version":\s*)"[^"\r\n]+"',
        rf'\g<1>"{version}"',
        text,
        ".zenodo.json version",
        flags=re.MULTILINE,
    )
    updated = _replace_once(
        r'("description":\s*"CARTOGRAFFECT v)\d+\.\d+\.\d+',
        rf"\g<1>{version}",
        updated,
        ".zenodo.json description version",
        flags=re.MULTILINE,
    )
    updated = _replace_once(
        r'\b\d+(\s+normative modules \(Cartograffect/\) certifying\s+)\d+(\s+substantial theorems\s+\()\d+(\s+exported declarations)',
        rf"{V3_NORMATIVE_MODULES}\g<1>{V3_THEOREMS_SUBSTANTIAL}\g<2>{V3_EXPORTED_DECLARATIONS}\g<3>",
        updated,
        ".zenodo.json description normative theorem counts",
        flags=re.MULTILINE,
    )
    parsed = json.loads(updated)
    if parsed.get("version") != version:
        raise ValueError(".zenodo.json résultat JSON incohérent après synchronisation.")
    return updated


def _sync_manifest_json(text: str, version: str, lexicon_sha256: str) -> str:
    updated = _replace_once(
        r'^(  "version":\s*)"[^"\r\n]+"',
        rf'\g<1>"{version}"',
        text,
        "manifest.json top-level version",
        flags=re.MULTILINE,
    )
    updated = _replace_once(
        r'("lexicon_176":\s*\{\s*\n(?:[ \t]+.*\n)*?[ \t]+"sha256":\s*)"[0-9a-fA-F]+"',
        rf'\g<1>"{lexicon_sha256}"',
        updated,
        "manifest.json exploratory_annexes.lexicon_176.sha256",
        flags=re.MULTILINE,
    )
    updated = _replace_once(
        r'("manuscript":\s*\{\s*\n(?:[ \t]+.*\n)*?[ \t]+"version":\s*)"[^"\r\n]+"',
        rf'\g<1>"{version}"',
        updated,
        "manifest.json manuscript.version",
        flags=re.MULTILINE,
    )
    parsed = json.loads(updated)
    if parsed.get("version") != version:
        raise ValueError("manifest.json version racine incohérente après synchronisation.")
    if parsed.get("strate_0_core", {}).get("manuscript", {}).get("version") != version:
        raise ValueError("manifest.json manuscript.version incohérente après synchronisation.")
    if parsed.get("exploratory_annexes", {}).get("lexicon_176", {}).get("sha256") != lexicon_sha256:
        raise ValueError("manifest.json exploratory_annexes.lexicon_176.sha256 incohérent après synchronisation.")
    return updated


def _sync_pyproject_toml(text: str, version: str) -> str:
    updated = _replace_once(
        r'(^\[project\]\s*\n(?:(?!\[)[^\n]*\n)*?version\s*=\s*)"[^"\r\n]+"',
        rf'\g<1>"{version}"',
        text,
        "extensions/in_silico/pyproject.toml [project].version",
        flags=re.MULTILINE,
    )
    return updated


def compute_sync_plan(root: Path) -> tuple[str, str, list[tuple[str, str, str]]]:
    """Calcule l'état cible de synchronisation sans écrire sur disque."""
    resolved = root.resolve()
    version_file = resolved / "VERSION"
    lexicon_file = resolved / "Cartograffect/Lexicon176.lean"

    if not version_file.is_file():
        raise FileNotFoundError(f"VERSION introuvable : {version_file}")
    if not lexicon_file.is_file():
        raise FileNotFoundError(f"Lexicon176.lean introuvable : {lexicon_file}")

    version = version_file.read_text(encoding="utf-8").strip()
    if not SEMVER_RE.fullmatch(version):
        raise ValueError(f"VERSION='{version}' invalide (SemVer X.Y.Z requis).")

    lexicon_sha256 = hashlib.sha256(lexicon_file.read_bytes()).hexdigest()

    targets: list[tuple[str, Callable[[str], str]]] = [
        ("CITATION.cff", lambda t: _sync_citation_cff(t, version)),
        (".zenodo.json", lambda t: _sync_zenodo_json(t, version)),
        ("manifest.json", lambda t: _sync_manifest_json(t, version, lexicon_sha256)),
        ("extensions/in_silico/pyproject.toml", lambda t: _sync_pyproject_toml(t, version)),
    ]

    results: list[tuple[str, str, str]] = []
    for rel, transform in targets:
        path = resolved / rel
        if not path.is_file():
            raise FileNotFoundError(f"Cible de synchronisation introuvable : {path}")
        original = path.read_text(encoding="utf-8")
        updated = transform(original)
        results.append((rel, original, updated))

    return version, lexicon_sha256, results


def main(argv: list[str] | None = None) -> int:
    _configure_stdio()
    parser = argparse.ArgumentParser(
        description="Synchronise VERSION, compteurs v3.0.0 et SHA-256 de Lexicon176.lean dans les métadonnées."
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--check",
        action="store_true",
        help="Vérifie sans modifier et affiche le diff si une désynchronisation existe (défaut).",
    )
    mode.add_argument(
        "--dry-run",
        action="store_true",
        help="Alias de --check : simule les mises à jour sans écrire.",
    )
    mode.add_argument(
        "--apply",
        action="store_true",
        help="Écrit effectivement les mises à jour dans les fichiers cibles.",
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
        help="Racine du dépôt (par défaut : racine du compendium).",
    )
    args = parser.parse_args(argv)

    try:
        version, lexicon_sha256, items = compute_sync_plan(args.root)
    except (FileNotFoundError, ValueError, json.JSONDecodeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    changed = [(rel, orig, upd) for rel, orig, upd in items if orig != upd]

    if not changed:
        print(
            f"SYNC OK : 4/4 fichiers synchronisés sur VERSION={version} "
            f"(cœur normatif : {V3_NORMATIVE_MODULES} modules, {V3_THEOREMS_SUBSTANTIAL} th. substantiels / "
            f"{V3_EXPORTED_DECLARATIONS} exportés ; Lexicon176.lean SHA-256={lexicon_sha256})."
        )
        return 0

    if args.apply:
        resolved = args.root.resolve()
        for rel, _orig, upd in changed:
            with open(resolved / rel, "w", encoding="utf-8", newline="\n") as fh:
                fh.write(upd)
            print(f"APPLIED: {rel}")
        print(
            f"Synchronisation appliquée sur {len(changed)} fichier(s) "
            f"(VERSION={version}, SHA-256={lexicon_sha256})."
        )
        return 0

    print(
        f"DESYNC DETECTED : {len(changed)} fichier(s) nécessitent une mise à jour "
        f"(VERSION={version}, SHA-256={lexicon_sha256})."
    )
    for rel, orig, upd in changed:
        diff = difflib.unified_diff(
            orig.splitlines(keepends=True),
            upd.splitlines(keepends=True),
            fromfile=f"a/{rel}",
            tofile=f"b/{rel}",
        )
        sys.stdout.writelines(diff)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
