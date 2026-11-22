#!/usr/bin/env python3
"""
Générateur déterministe du contrat web `site-payload.json` (Strate 0/1 -> Strate 2)
pour le compendium unifié CARTOGRAFFECT® (bibliothèque standard Python 3.10+ uniquement).

Sources lues et recoupées :
  - `VERSION`
  - `manifest.json`
  - `CITATION.cff`
  - `.zenodo.json`
  - `CHANGELOG.md`
  - `Cartograffect/Lexicon176.lean`
  - `docs/01-Article_Cartograffect.md`

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
    lexicon_path = resolved / "Cartograffect/Lexicon176.lean"
    lexicon_text = _read_text(lexicon_path)
    article_text = _read_text(resolved / "docs/01-Article_Cartograffect.md")

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
    cff_license = _extract_cff_field(cff_text, "license")
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

    # 4. Strate 0 Core + Lexicon176 SHA-256 + comptage
    s0 = manifest.get("strate_0_core", {})
    theorems_verified = int(s0.get("theorems_verified", 0))
    sorry_count = int(s0.get("sorry_count", -1))
    custom_axioms_count = int(s0.get("custom_axioms_count", -1))
    provers_raw = s0.get("provers", [])
    lean_files = s0.get("lean_files", [])
    lex_meta = s0.get("lexicon_176", {})
    manuscript_meta = s0.get("manuscript", {})

    if theorems_verified <= 0 or sorry_count != 0 or custom_axioms_count != 0:
        raise ValueError(
            f"Invariants formels Strate 0 invalides dans manifest.json : "
            f"theorems={theorems_verified}, sorry={sorry_count}, axioms={custom_axioms_count}"
        )
    if f"{theorems_verified}/{theorems_verified} verified theorems" not in cff_text:
        raise ValueError(
            f"Incohérence théorèmes : manifest.json={theorems_verified} non recoupé dans CITATION.cff."
        )
    if not isinstance(provers_raw, list) or len(provers_raw) != 6:
        raise ValueError(f"manifest.json doit déclarer exactement 6 prouveurs (trouvé : {len(provers_raw)}).")
    if not isinstance(lean_files, list) or len(lean_files) != 10:
        raise ValueError(f"manifest.json doit lister exactement 10 fichiers Lean (trouvé : {len(lean_files)}).")
    for lf in lean_files:
        if not (resolved / lf).is_file():
            raise FileNotFoundError(f"Module Lean listé dans manifest.json introuvable : {lf}")

    provers = [
        {
            "name": str(p["name"]),
            "version": str(p["version"]),
            "entrypoint": str(p["entrypoint"]),
            "directory": str(p["directory"]),
        }
        for p in provers_raw
    ]

    actual_sha256 = hashlib.sha256(lexicon_path.read_bytes()).hexdigest()
    expected_sha256 = str(lex_meta.get("sha256", "")).strip()
    if actual_sha256 != expected_sha256:
        raise ValueError(
            f"SHA-256 Lexicon176.lean ({actual_sha256}) != manifest.json ({expected_sha256})."
        )

    lean_entries = LEAN_ENTRY_RE.findall(lexicon_text)
    states_count = int(lex_meta.get("states_count", 0))
    if len(lean_entries) != states_count or states_count != 176:
        raise ValueError(
            f"Nombre d'entrées Lexicon176.lean ({len(lean_entries)}) != states_count ({states_count})."
        )

    predictions_count = int(manuscript_meta.get("predictions_count", 0))
    if predictions_count != 5:
        raise ValueError(f"manifest.json predictions_count={predictions_count} != 5.")

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
    if not (resolved / lex_status_file).is_file():
        raise FileNotFoundError(f"Charte Strate 1 manquante : {lex_status_file}")
    if not (resolved / insilico_status_file).is_file():
        raise FileNotFoundError(f"Charte Strate 1 manquante : {insilico_status_file}")

    predictions_tested = [str(p) for p in insilico_ext.get("predictions_tested", [])]
    experiments = list(insilico_ext.get("experiments", []))

    strate_1_extensions = {
        "lexicon": {
            "path": str(lex_ext.get("path", "extensions/lexicon")),
            "status": str(lex_ext.get("status", "exploratory_subordinate")),
            "epistemic_status_file": lex_status_file,
            "summary": (
                "Triangulation psychométrique préliminaire sur les 24 ancres Scherer GRID / CPM "
                "et réfutation formelle des roues émotionnelles 2D à rayon fixe "
                "(EmotionWheelsChallenge.lean) ; statut exploratoire subordonné à la Strate 0 ; "
                "extension axiologique Z- (« Diamant 303 ») strictement cloisonnée hors de "
                "l'axiomatique Z in {0..7}."
            ),
        },
        "in_silico": {
            "path": str(insilico_ext.get("path", "extensions/in_silico")),
            "status": str(insilico_ext.get("status", "exploratory_subordinate")),
            "epistemic_status_file": insilico_status_file,
            "predictions_tested": predictions_tested,
            "experiments_count": len(experiments),
            "a4_sanctuaire_policy": (
                "Respect absolu de l'arbitrage A4-Sanctuaire : aucune métrique quantitative "
                "in silico (PXP, min r) n'est injectée dans le corps théorique de l'article "
                "canonique ; banc compagnon Exp 1–5 réservé à un second article dédié."
            ),
            "summary": (
                "Banc compagnon de simulation Active Inference (Exp 1–5 : faisabilité générative "
                "P1–P5, phénotypes cliniques, identifiabilité bayésienne et explorations "
                "nosologiques DSM-5 / HiTOP), strictement subordonné à la Strate 0 et réservé "
                "à un second article méthodologique dédié dans le respect absolu de A4-Sanctuaire."
            ),
        },
    }

    # 6. Licences
    lic_manifest = manifest.get("licenses", {})
    spdx_expression = str(lic_manifest.get("spdx_expression", "")).strip()
    if spdx_expression != "AGPL-3.0-or-later AND CC-BY-NC-SA-4.0":
        raise ValueError(f"Expression SPDX inattendue dans manifest.json : {spdx_expression!r}")
    if cff_license != spdx_expression:
        raise ValueError(f"CITATION.cff license='{cff_license}' != '{spdx_expression}'.")

    hybrid_clause_summary = str(lic_manifest.get("hybrid_separation_clause", "")).strip()
    if not hybrid_clause_summary:
        raise ValueError("manifest.json licenses.hybrid_separation_clause manquant.")

    tag = f"v{version}"
    return {
        "schema_version": "1.0",
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
            "theorems_verified": theorems_verified,
            "sorry_count": sorry_count,
            "custom_axioms_count": custom_axioms_count,
            "provers": provers,
            "lean_modules_count": len(lean_files),
            "lean_modules": [str(lf) for lf in lean_files],
            "states_count": states_count,
            "predictions_count": predictions_count,
            "lexicon176_sha256": actual_sha256,
            "author_affiliation": author_affiliation,
        },
        "strate_1_extensions": strate_1_extensions,
        "ai_disclosure": {
            "author_ownership": (
                "L’architecture conceptuelle, la psychologie affective, la taxonomie des 176 états "
                "et l’orientation théorique de CARTOGRAFFECT® sont entièrement conçues et assumées par l’auteur."
            ),
            "ai_assistance_scope": (
                "Des outils d’IA générative ont servi d’assistants techniques pour la rédaction, le site web, "
                "la traduction et la transposition exploratoire de propriétés du modèle vers des assistants de preuve "
                "formelle (Lean 4, Rocq, Agda, Dafny, Z3, TLA+) et des scripts sur GitHub."
            ),
            "verification_and_audit_status": (
                "Psychologue clinicien et non mathématicien formel, l’auteur n’a pas vérifié manuellement ligne par ligne "
                "le code mathématique/formel généré ; la validité technique repose sur la compilation mécanique des prouveurs "
                "et les tests automatisés. Ce matériel est publié en accès libre sur GitHub pour inviter l’audit indépendant "
                "de mathématiciens et de spécialistes des méthodes formelles."
            ),
            "summary_en": (
                "The conceptual architecture, affective psychology, taxonomy, and theoretical orientation of CARTOGRAFFECT® "
                "are conceived and owned entirely by the author. Generative AI served as a technical assistant for writing, "
                "website engineering, translation, and exploratory formal-method transposition (Lean 4, Rocq, Agda, Dafny, "
                "Z3, TLA+) and GitHub scripts. As a clinical psychologist and not a formal mathematician, the author has not "
                "manually verified generated formal code line by line; technical validity relies on mechanical prover compilation "
                "and automated tests, and the code is open-sourced on GitHub to invite independent specialist audit."
            ),
        },
        "licenses": {
            "spdx_expression": spdx_expression,
            "code_license": "GNU AGPLv3",
            "theory_license": "CC BY-NC-SA 4.0",
            "hybrid_clause_summary": hybrid_clause_summary,
        },
    }


def serialize_payload(payload: dict[str, Any]) -> str:
    return json.dumps(payload, indent=2, ensure_ascii=False) + "\n"


def main(argv: list[str] | None = None) -> int:
    _configure_stdio()
    parser = argparse.ArgumentParser(
        description="Exporte ou vérifie le contrat JSON déterministe site-payload.json."
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
        print(
            f"PAYLOAD CHECK OK : schema={payload['schema_version']}, version={rel['version']}, "
            f"theorems={s0['theorems_verified']}, provers={len(s0['provers'])}, "
            f"lean_modules={s0['lean_modules_count']}, states={s0['states_count']}, "
            f"predictions={s0['predictions_count']}."
        )
        return 0

    if args.output is not None:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with open(args.output, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(serialized)
        print(
            f"WROTE {args.output.as_posix()} (version={payload['release']['version']}, "
            f"theorems={payload['strate_0_core']['theorems_verified']}, "
            f"sha256={payload['strate_0_core']['lexicon176_sha256'][:16]}...)"
        )
        return 0

    sys.stdout.write(serialized)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
