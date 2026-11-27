#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""
Générateur déterministe du contrat web `site-payload.json` (Strate 0/1 -> Strate 2)
pour le compendium CARTOGRAFFECT v3.0.0 (bibliothèque standard Python 3.10+ uniquement).

Sources lues et recoupées :
  - `VERSION`
  - `manifest.json`
  - `CITATION.cff`
  - `.zenodo.json`
  - `CHANGELOG.md`
  - `FORMAL_AUDIT_PACK.md`
  - `Cartograffect/Lexicon176.lean` (annexe exploratoire)
  - `docs/01-Article_Cartograffect.md`
  - `docs/02-Inventaire_176.md`

Utilisation :
  python scripts/export_site_payload.py --output <chemin/site-payload.json>
  python scripts/export_site_payload.py --check [--output <chemin/site-payload.json>]
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
from typing import Any


SEMVER_RE = re.compile(r"^\d+\.\d+\.\d+$")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
LEAN_ENTRY_RE = re.compile(r'⟨"([^"]+)",\s*⟨(-?\d+),\s*(-?\d+),\s*(\d+)⟩⟩')
MD_LINK_RE = re.compile(r"\[([^\]]+)\]\([^)]+\)")


def _configure_stdio() -> None:
    for stream in (sys.stdout, sys.stderr):
        reconfigure = getattr(stream, "reconfigure", None)
        if callable(reconfigure):
            try:
                reconfigure(encoding="utf-8", errors="replace")
            except Exception:
                pass


def _read_text(path: Path) -> str:
    if not path.is_file():
        raise FileNotFoundError(f"Fichier source requis manquant : {path.as_posix()}")
    return path.read_text(encoding="utf-8")


def _load_json(path: Path, label: str) -> dict[str, Any]:
    raw = _read_text(path)
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ValueError(f"JSON invalide dans {label} : {exc}") from exc
    if not isinstance(data, dict):
        raise ValueError(f"{label} doit contenir un objet JSON racine.")
    return data


def _extract_cff_field(cff_text: str, key: str) -> str | None:
    m = re.search(rf'^{re.escape(key)}:\s*["\']?([^"\'\r\n]+)["\']?\s*$', cff_text, re.MULTILINE)
    return m.group(1).strip() if m else None


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

    single = _extract_cff_field(cff_text, "license")
    return [single] if single else []


def _extract_cff_preferred_version(cff_text: str) -> str | None:
    m = re.search(
        r'^preferred-citation:\s*\n(?:[ \t]+.*\n)*?[ \t]+version:\s*["\']?([^"\'\s#]+)["\']?',
        cff_text,
        re.MULTILINE,
    )
    return m.group(1).strip() if m else None


def _strip_md_links(text: str) -> str:
    return MD_LINK_RE.sub(r"\1", text).strip()


def _parse_changelog_highlights(changelog_text: str, version: str, expected_date: str) -> list[dict[str, str]]:
    header_re = re.compile(r"^##\s+\[(\d+\.\d+\.\d+)\]\s*-\s*(\d{4}-\d{2}-\d{2})\s*$", re.MULTILINE)
    matches = list(header_re.finditer(changelog_text))
    if not matches:
        raise ValueError("Aucun en-tête SemVer '## [X.Y.Z] - YYYY-MM-DD' trouvé dans CHANGELOG.md.")

    target_idx: int | None = None
    for idx, m in enumerate(matches):
        if m.group(1) == version:
            target_idx = idx
            break
    if target_idx is None:
        raise ValueError(f"Section CHANGELOG.md absente pour la version {version}.")

    target_match = matches[target_idx]
    if target_match.group(2) != expected_date:
        raise ValueError(
            f"Date CHANGELOG.md '{target_match.group(2)}' != manifest.release_date '{expected_date}'."
        )

    start = target_match.end()
    end = matches[target_idx + 1].start() if target_idx + 1 < len(matches) else len(changelog_text)
    block = changelog_text[start:end]

    highlights: list[dict[str, str]] = []
    current_section = "General"
    for raw_line in block.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        sec_m = re.match(r"^###\s+(.+)$", line)
        if sec_m:
            current_section = sec_m.group(1).strip()
            continue
        if line.startswith("- "):
            item = line[2:].strip()
            bold_m = re.match(r"^\*\*([^*]+?)\*\*\s*:\s*(.+)$", item)
            if bold_m:
                title = _strip_md_links(bold_m.group(1))
                summary = _strip_md_links(bold_m.group(2))
            else:
                clean = _strip_md_links(item)
                title = clean[:80]
                summary = clean
            highlights.append({
                "section": current_section,
                "title": title,
                "summary": summary,
            })

    if not highlights:
        raise ValueError(f"Aucun point structuré extrait dans CHANGELOG.md pour la version {version}.")
    return highlights


def _extract_author_affiliation(article_text: str) -> str:
    m = re.search(
        r"^Manuel Cabelguen,\s*Ph\.\s*D\.,\s*(.+?)\s*$",
        article_text,
        re.MULTILINE,
    )
    if not m:
        raise ValueError(
            "Ligne d'affiliation canonique introuvable dans docs/01-Article_Cartograffect.md."
        )
    affiliation = m.group(1).strip()
    if "Sainte-Agathe-des-Monts" not in affiliation:
        raise ValueError(
            f"Affiliation inattendue dans docs/01-Article_Cartograffect.md : {affiliation!r}"
        )
    return affiliation


def build_site_payload(root: Path) -> dict[str, Any]:
    """Construit et valide le contrat JSON déterministe `site-payload.json` depuis `root`."""
    resolved = root.resolve()

    version = _read_text(resolved / "VERSION").strip()
    if not SEMVER_RE.fullmatch(version):
        raise ValueError(f"VERSION='{version}' invalide (SemVer X.Y.Z attendu).")

    manifest = _load_json(resolved / "manifest.json", "manifest.json")
    zenodo = _load_json(resolved / ".zenodo.json", ".zenodo.json")
    cff_text = _read_text(resolved / "CITATION.cff")
    changelog_text = _read_text(resolved / "CHANGELOG.md")
    audit_pack_text = _read_text(resolved / "FORMAL_AUDIT_PACK.md")
    lexicon_path = resolved / "Cartograffect/Lexicon176.lean"
    lexicon_text = _read_text(lexicon_path)
    article_text = _read_text(resolved / "docs/01-Article_Cartograffect.md")
    _read_text(resolved / "docs/02-Inventaire_176.md")

    # 1. Validation croisée des dates et versions
    release_date = str(manifest.get("release_date", "")).strip()
    if not DATE_RE.fullmatch(release_date):
        raise ValueError(f"manifest.json release_date='{release_date}' invalide.")
    if manifest.get("version") != version:
        raise ValueError(f"manifest.json version='{manifest.get('version')}' != VERSION '{version}'.")
    if zenodo.get("version") != version:
        raise ValueError(f".zenodo.json version='{zenodo.get('version')}' != VERSION '{version}'.")
    if zenodo.get("publication_date") != release_date:
        raise ValueError(
            f".zenodo.json publication_date='{zenodo.get('publication_date')}' != release_date '{release_date}'."
        )

    cff_ver = _extract_cff_field(cff_text, "version")
    cff_pref_ver = _extract_cff_preferred_version(cff_text)
    cff_date = _extract_cff_field(cff_text, "date-released")
    cff_licenses = _extract_cff_licenses(cff_text)
    if cff_ver != version or (cff_pref_ver is not None and cff_pref_ver != version):
        raise ValueError(
            f"CITATION.cff version='{cff_ver}' / preferred='{cff_pref_ver}' != '{version}'."
        )
    if cff_date != release_date:
        raise ValueError(f"CITATION.cff date-released='{cff_date}' != release_date '{release_date}'.")

    # 2. Extraction des highlights du CHANGELOG
    changelog_highlights = _parse_changelog_highlights(changelog_text, version, release_date)

    # 3. Identifiants permanents recoupés
    ids_manifest = manifest.get("identifiers", {})
    zenodo_code_doi = str(ids_manifest.get("zenodo_code_doi", "")).strip()
    zenodo_article_doi = str(ids_manifest.get("zenodo_article_doi", "")).strip()
    osf_url = str(ids_manifest.get("osf_url", "")).strip()
    cipo_raw = str(ids_manifest.get("cipo_registration", "")).strip()
    github_repo_url = str(ids_manifest.get("repository_url", "")).strip().rstrip("/")

    cipo_m = re.search(r"\b(\d{7})\b", cipo_raw)
    if not cipo_m:
        raise ValueError(f"Numéro OPIC/CIPO invalide dans manifest.json : {cipo_raw!r}")
    cipo_registration = cipo_m.group(1)

    for required_id in (zenodo_code_doi, zenodo_article_doi, osf_url, cipo_registration):
        if not required_id:
            raise ValueError("Identifiant permanent manquant dans manifest.json.")
        if required_id not in cff_text:
            raise ValueError(f"Identifiant '{required_id}' absent de CITATION.cff.")

    related_ids = {
        str(item.get("identifier", "")).strip()
        for item in zenodo.get("related_identifiers", [])
        if isinstance(item, dict)
    }
    if zenodo_article_doi not in related_ids or osf_url not in related_ids:
        raise ValueError(".zenodo.json related_identifiers incomplet vis-à-vis de manifest.json.")

    # 4. Strate 0 Core (Lean 4 unique prouveur de référence v3.0.0)
    s0 = manifest.get("strate_0_core", {})
    normative_modules_count = int(s0.get("normative_modules_count", 0))
    theorems_substantial = int(s0.get("theorems_substantial", 0))
    exported_declarations = int(s0.get("exported_declarations", 0))
    auxiliary_lemmas = int(s0.get("auxiliary_lemmas", 0))
    pillar_theorems_count = int(s0.get("pillar_theorems_count", 0))
    sorry_count = int(s0.get("sorry_count", -1))
    native_decide_count = int(s0.get("native_decide_count", -1))
    custom_axioms_count = int(s0.get("custom_axioms_count", -1))
    normative_lean_modules = list(s0.get("normative_lean_modules", []))
    canonical_ext = s0.get("canonical_extension", {})
    manuscript_meta = s0.get("manuscript", {})
    py_meta = s0.get("python_isomorphic_engine", {})

    if (
        normative_modules_count != 8
        or theorems_substantial != 148
        or exported_declarations != 169
        or auxiliary_lemmas != 21
        or pillar_theorems_count != 8
        or sorry_count != 0
        or native_decide_count != 0
        or custom_axioms_count != 0
    ):
        raise ValueError(
            "Invariants formels Strate 0 v3.0.0 invalides dans manifest.json : "
            f"modules={normative_modules_count}, substantial={theorems_substantial}, "
            f"exported={exported_declarations}, aux={auxiliary_lemmas}, pillars={pillar_theorems_count}, "
            f"sorry={sorry_count}, native_decide={native_decide_count}, axioms={custom_axioms_count}"
        )

    if len(normative_lean_modules) != 8:
        raise ValueError(
            f"manifest.json doit lister exactement 8 modules normatifs Lean 4 (trouvé : {len(normative_lean_modules)})."
        )
    for lf in normative_lean_modules:
        if not (resolved / lf).is_file():
            raise FileNotFoundError(f"Module normatif Lean 4 manquant sur disque : {lf}")

    if "148" not in audit_pack_text or "169" not in audit_pack_text:
        raise ValueError("FORMAL_AUDIT_PACK.md ne recoupe pas les compteurs 148 / 169.")
    if f"{theorems_substantial} substantial theorems" not in cff_text:
        raise ValueError(
            f"Incohérence théorèmes : manifest.json={theorems_substantial} non recoupé dans CITATION.cff."
        )

    ext_own = int(canonical_ext.get("theorems_own", 0))
    ext_aux = int(canonical_ext.get("auxiliary_lemmas", 0))
    ext_total = int(canonical_ext.get("exported_declarations", 0))
    if ext_own != 16 or ext_aux != 5 or ext_total != 21:
        raise ValueError(
            f"Invariants PredictiveEngineCanonical invalides : own={ext_own}, aux={ext_aux}, total={ext_total}."
        )

    python_unit_tests = int(py_meta.get("unit_tests_count", 0))
    if python_unit_tests != 11:
        raise ValueError(f"python_isomorphic_engine.unit_tests_count={python_unit_tests} != 11.")

    predictions_count = int(manuscript_meta.get("predictions_count", 0))
    canonical_states_count = int(manuscript_meta.get("canonical_states_count", 0))
    if predictions_count != 5 or canonical_states_count != 11:
        raise ValueError(
            f"Invariants manuscrit invalides : predictions={predictions_count}, canonical_states={canonical_states_count}."
        )

    # 4b. Annexe exploratoire Lexicon176 (hors cœur normatif)
    annex_lex = manifest.get("exploratory_annexes", {}).get("lexicon_176", {})
    actual_sha256 = hashlib.sha256(lexicon_path.read_bytes()).hexdigest()
    expected_sha256 = str(annex_lex.get("sha256", "")).strip()
    if actual_sha256 != expected_sha256:
        raise ValueError(
            f"SHA-256 Lexicon176.lean ({actual_sha256}) != manifest.json ({expected_sha256})."
        )

    lean_entries = LEAN_ENTRY_RE.findall(lexicon_text)
    annex_states_count = int(annex_lex.get("states_count", 0))
    if len(lean_entries) != annex_states_count or annex_states_count != 176:
        raise ValueError(
            f"Nombre d'entrées Lexicon176.lean ({len(lean_entries)}) != states_count ({annex_states_count})."
        )

    author_affiliation = _extract_author_affiliation(article_text)
    art_low = article_text.lower()
    for marker in ("non mathématicien formel", "ligne par ligne", "vérification mécanique", "tests automatisés", "audit"):
        if marker not in art_low:
            raise ValueError(
                f"Déclaration IA incomplète dans docs/01-Article_Cartograffect.md (marqueur absent : {marker!r})."
            )

    # 5. Strate 1 Extensions (délimitation épistémique stricte)
    s1 = manifest.get("strate_1_extensions", {})
    lex_ext = s1.get("lexicon", {})
    insilico_ext = s1.get("in_silico", {})
    lex_status_file = str(lex_ext.get("epistemic_status_file", "extensions/lexicon/EPISTEMIC_STATUS.md"))
    insilico_status_file = str(
        insilico_ext.get("epistemic_status_file", "extensions/in_silico/EPISTEMIC_STATUS.md")
    )
    archive_warning_file = str(
        lex_ext.get("archive_warning_file", "extensions/lexicon/ARCHIVE_V2_HYBRID_Y_WARNING.md")
    )
    if not (resolved / lex_status_file).is_file():
        raise FileNotFoundError(f"Charte Strate 1 manquante : {lex_status_file}")
    if not (resolved / insilico_status_file).is_file():
        raise FileNotFoundError(f"Charte Strate 1 manquante : {insilico_status_file}")
    if not (resolved / archive_warning_file).is_file():
        raise FileNotFoundError(f"Avertissement archive v2 manquant : {archive_warning_file}")

    predictions_tested = [str(p) for p in insilico_ext.get("predictions_tested", [])]
    experiments = list(insilico_ext.get("experiments", []))
    quarantined_experiments = list(insilico_ext.get("quarantined_synthetic_experiments", []))

    strate_1_extensions = {
        "lexicon": {
            "path": str(lex_ext.get("path", "extensions/lexicon")),
            "status": str(lex_ext.get("status", "exploratory_subordinate")),
            "epistemic_status_file": lex_status_file,
            "archive_warning_file": archive_warning_file,
            "data_provenance_file": str(lex_ext.get("data_provenance_file", "DATA_PROVENANCE.md")),
            "theorems_verified": int(lex_ext.get("theorems_verified", 10)),
            "sorry_count": int(lex_ext.get("sorry_count", 0)),
            "lean_challenges_count": len(lex_ext.get("lean_challenges", [])),
            "summary": (
                "Audit lexical et géométrique exploratoire de Strate 1 "
                "(3 modules actifs dans extensions/lexicon/lean/, 10/10 théorèmes géométriques Lean 4, "
                "0 sorry, 0 constante statistique Python codée en dur ; banc GEW 3.0 / Plutchik sans "
                "surcharges manuelles avec H2 et H4 rapportées comme non corroborées ; tables TSV v2.1.0 "
                "signalées comme archive historique sous ancien axe Y hybride)."
            ),
        },
        "in_silico": {
            "path": str(insilico_ext.get("path", "extensions/in_silico")),
            "status": str(insilico_ext.get("status", "exploratory_subordinate")),
            "epistemic_status_file": insilico_status_file,
            "lockfile": str(insilico_ext.get("lockfile", "extensions/in_silico/uv.lock")),
            "predictions_tested": predictions_tested,
            "active_experiments_count": len(experiments),
            "quarantined_experiments_count": len(quarantined_experiments),
            "a4_sanctuaire_policy": (
                "Respect absolu de l'arbitrage A4-Sanctuaire : aucune métrique quantitative "
                "in silico (PXP, min r) n'est injectée dans le corps théorique de l'article "
                "canonique ; Exp 4-5 DSM-5 / HiTOP isolées en quarantaine dans exploratory_synthetic/ "
                "(SYNTHETIC EXPLORATORY ONLY — V3 = 0)."
            ),
            "summary": (
                "Banc compagnon de simulation Active Inference (Exp 1-3 : test de cohérence numérique "
                "du projecteur budgétaire P1, cohérence générative interne P2-P5 et identifiabilité "
                "bayésienne ; Exp 4-5 DSM-5 / HiTOP en quarantaine exploratory_synthetic/ — "
                "SYNTHETIC EXPLORATORY ONLY, V3 = 0), strictement subordonné à la Strate 0."
            ),
        },
    }

    # 6. Licences (séparation physique OSI / CC-BY-4.0, zéro clause NC)
    lic_manifest = manifest.get("licenses", {})
    code_spdx = str(lic_manifest.get("code_spdx", "")).strip()
    docs_spdx = str(lic_manifest.get("docs_and_data_spdx", "")).strip()
    spdx_expression = str(lic_manifest.get("spdx_expression", "")).strip()
    if code_spdx != "AGPL-3.0-or-later" or docs_spdx != "CC-BY-4.0":
        raise ValueError(
            f"Séparation de licences invalide dans manifest.json : code={code_spdx!r}, docs={docs_spdx!r}"
        )
    if "AGPL-3.0-or-later" not in cff_licenses or "CC-BY-4.0" not in cff_licenses:
        raise ValueError(
            f"CITATION.cff licenses={cff_licenses!r} doit déclarer ['AGPL-3.0-or-later', 'CC-BY-4.0']."
        )
    if any("NC" in item.upper() for item in cff_licenses):
        raise ValueError(f"Clause non commerciale (NC) interdite dans CITATION.cff : {cff_licenses!r}")

    separation_policy = str(lic_manifest.get("physical_separation_policy", "")).strip()
    if not separation_policy:
        raise ValueError("manifest.json licenses.physical_separation_policy manquant.")

    tag = f"v{version}"
    return {
        "schema_version": "2.0",
        "release": {
            "version": version,
            "tag": tag,
            "date": release_date,
            "changelog_highlights": changelog_highlights,
        },
        "identifiers": {
            "zenodo_code_doi": zenodo_code_doi,
            "zenodo_article_doi": zenodo_article_doi,
            "osf_url": osf_url,
            "cipo_registration": cipo_registration,
            "github_repo_url": github_repo_url,
            "github_release_url": f"{github_repo_url}/releases/tag/{tag}",
        },
        "strate_0_core": {
            "reference_prover": "Lean 4",
            "prover_version": str(s0.get("prover_version", "4.35.0")),
            "normative_modules_count": normative_modules_count,
            "normative_lean_modules": normative_lean_modules,
            "theorems_substantial": theorems_substantial,
            "exported_declarations": exported_declarations,
            "auxiliary_lemmas": auxiliary_lemmas,
            "pillar_theorems_count": pillar_theorems_count,
            "sorry_count": sorry_count,
            "native_decide_count": native_decide_count,
            "custom_axioms_count": custom_axioms_count,
            "audit_pack": str(s0.get("audit_pack", "FORMAL_AUDIT_PACK.md")),
            "canonical_extension": {
                "path": str(canonical_ext.get("path")),
                "theorems_own": ext_own,
                "auxiliary_lemmas": ext_aux,
                "exported_declarations": ext_total,
            },
            "python_unit_tests_count": python_unit_tests,
            "manuscript_path": str(manuscript_meta.get("path", "docs/01-Article_Cartograffect.md")),
            "inventory_annex_path": str(manuscript_meta.get("inventory_annex_path", "docs/02-Inventaire_176.md")),
            "continuous_depth_range": str(manuscript_meta.get("continuous_depth_range", "Z in [0, 5]")),
            "canonical_discretization": str(manuscript_meta.get("canonical_discretization", "Z in {0, 1, 2}")),
            "canonical_states_count": canonical_states_count,
            "predictions_count": predictions_count,
            "author_affiliation": author_affiliation,
            "legacy_v2_1_archived_provers": list(s0.get("legacy_v2_1_archived_provers", [])),
        },
        "exploratory_annexes": {
            "lexicon_176": {
                "status": str(annex_lex.get("status", "exploratory_annex_outside_normative_core")),
                "path": str(annex_lex.get("path", "Cartograffect/Lexicon176.lean")),
                "inventory_doc": str(annex_lex.get("inventory_doc", "docs/02-Inventaire_176.md")),
                "states_count": annex_states_count,
                "sha256": actual_sha256,
            }
        },
        "strate_1_extensions": strate_1_extensions,
        "ai_disclosure": {
            "author_ownership": (
                "L'architecture conceptuelle, la psychologie affective, les arbitrages taxonomiques "
                "et l'orientation théorique de CARTOGRAFFECT sont entièrement conçus et assumés par l'auteur."
            ),
            "ai_assistance_scope": (
                "Des outils d'IA générative ont servi d'assistants techniques pour l'aide à la rédaction, "
                "la réalisation du site web vitrine, la traduction et la formalisation sous l'assistant de "
                "preuve de référence Lean 4 (ainsi que pour les annexes exploratoires archivées sur GitHub)."
            ),
            "verification_and_audit_status": (
                "Psychologue clinicien et non mathématicien formel, l'auteur n'a pas vérifié manuellement "
                "ligne par ligne le code mathématique et formel généré ; la validité technique repose sur "
                "la compilation et vérification mécanique par les prouveurs ainsi que sur les tests automatisés. "
                "L'ensemble est publié en accès libre sur GitHub pour inviter l'audit indépendant de "
                "mathématiciens et de spécialistes des méthodes formelles."
            ),
            "summary_en": (
                "The conceptual architecture, affective psychology, taxonomic decisions, and theoretical "
                "orientation of CARTOGRAFFECT are conceived and owned entirely by the author. Generative AI "
                "served as a technical assistant for writing, website engineering, translation, and "
                "formalization in the reference Lean 4 proof assistant (and archived exploratory annexes). "
                "As a clinical psychologist and not a formal mathematician, the author has not manually "
                "verified generated formal code line by line; technical validity relies on mechanical prover "
                "compilation and automated tests, and all artifacts are open-sourced on GitHub to invite "
                "independent specialist audit."
            ),
        },
        "licenses": {
            "code_spdx": code_spdx,
            "docs_and_data_spdx": docs_spdx,
            "spdx_expression": spdx_expression,
            "code_license": "GNU AGPLv3 (AGPL-3.0-or-later)",
            "docs_and_taxonomy_license": "Creative Commons Attribution 4.0 International (CC-BY-4.0)",
            "physical_separation_policy": separation_policy,
            "non_commercial_clauses_in_code": False,
        },
    }


def serialize_payload(payload: dict[str, Any]) -> str:
    return json.dumps(payload, indent=2, ensure_ascii=False) + "\n"


def main(argv: list[str] | None = None) -> int:
    _configure_stdio()
    parser = argparse.ArgumentParser(
        description="Exporte ou vérifie le contrat JSON déterministe site-payload.json (v3.0.0)."
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
        help="Racine du compendium CARTOGRAFFECT (défaut : parent de scripts/).",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Chemin de sortie du fichier site-payload.json.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Valide la cohérence sans écrire (et compare à --output si fourni).",
    )
    args = parser.parse_args(argv)

    try:
        payload = build_site_payload(args.root)
        serialized = serialize_payload(payload)
    except (FileNotFoundError, ValueError, KeyError, TypeError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    if args.check:
        if args.output is not None:
            if not args.output.is_file():
                print(f"ERROR: Fichier cible absent pour --check : {args.output}", file=sys.stderr)
                return 1
            existing = args.output.read_text(encoding="utf-8")
            if existing != serialized:
                print(
                    f"DESYNC: {args.output} diffère du contrat généré par export_site_payload.py.",
                    file=sys.stderr,
                )
                return 1
        rel = payload["release"]
        s0 = payload["strate_0_core"]
        ext = s0["canonical_extension"]
        print(
            f"PAYLOAD CHECK OK : schema={payload['schema_version']}, version={rel['version']}, "
            f"normative_modules={s0['normative_modules_count']}, "
            f"theorems={s0['theorems_substantial']}/{s0['exported_declarations']} (pillars={s0['pillar_theorems_count']}), "
            f"canonical_ext={ext['theorems_own']}+{ext['auxiliary_lemmas']}={ext['exported_declarations']}, "
            f"python_tests={s0['python_unit_tests_count']}, predictions={s0['predictions_count']}."
        )
        return 0

    if args.output is not None:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with open(args.output, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(serialized)
        print(
            f"WROTE {args.output.as_posix()} (version={payload['release']['version']}, "
            f"theorems={payload['strate_0_core']['theorems_substantial']}/{payload['strate_0_core']['exported_declarations']}, "
            f"lexicon_annex_sha256={payload['exploratory_annexes']['lexicon_176']['sha256'][:16]}...)"
        )
        return 0

    sys.stdout.write(serialized)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
