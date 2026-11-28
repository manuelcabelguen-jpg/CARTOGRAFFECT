# SPDX-License-Identifier: AGPL-3.0-or-later
"""
01_ingest_normalize.py — Micro-Passes 1 & 1b : Ingestion, Gouvernance lexicale & Routage bi-hémisphérique (CARTOGRAFFECT v3.0.0)

Périmètre strict :
- Lecture seule sur data/raw/ (4 sources tierces non redistribuables).
- Aucune modification dans Cartograffect/ (noyau Lean 4 intouché).
- Calcul SHA-256 et mise à jour idempotente de DATA_PROVENANCE.md.
- Chargement et audit de DIMA 1 (Émotions) et DIMA 2 (Sentiments), avec journalisation
  exacte des cellules non nulles dans Unnamed: 26, Unnamed: 29 et Unnamed: 30 avant retrait.
- Fusion DIMA 1 + 2 sur la clé (lemme_norm, part_disc, classe, categ) avec tri prioritaire
  (Z_PLUS_ACTIVE > Z_PLUS_SATELLITE > Z_MINUS_RESERVE > NON_LEXICAL_DISCARD, puis tier/type),
  attribution du tier et routage bi-hémisphérique sans perte (hemisphere_route, pruning_bucket,
  z_minus_value_candidate).
- Chargement et normalisation de FANCatdatabaseRevisee.xlsx (onglet FANCat All, 27 colonnes
  renommées, saut de la ligne secondaire Mean/SD) et NRC-VAD-Lexicon-v2.1.txt (TSV).
- Export :
  - data/processed/dima_normalized.parquet (local, ignoré Git)
  - data/processed/dima_z_minus_reserve.parquet (local, ignoré Git — vue réserve -Z)
  - data/processed/fancat_clean.parquet (local, ignoré Git)
  - data/processed/dima_classes_summary.csv
  - reports/lexicon_v3/mp1_ingestion_audit.md
"""

from __future__ import annotations

import hashlib
import re
import unicodedata
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import pandas as pd

REPO_ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = REPO_ROOT / "data" / "raw"
PROCESSED_DIR = REPO_ROOT / "data" / "processed"
REPORTS_DIR = REPO_ROOT / "reports" / "lexicon_v3"
PROVENANCE_PATH = REPO_ROOT / "DATA_PROVENANCE.md"

RAW_SOURCES_META: list[dict[str, str]] = [
    {
        "filename": "NRC-VAD-Lexicon-v2.1.txt",
        "rel_path": "data/raw/NRC-VAD-Lexicon-v2.1.txt",
        "dataset": (
            "**NRC Valence, Arousal, and Dominance (NRC-VAD) Lexicon v2.1** (54 801 termes anglais, "
            "échelle `[-1, +1]`) — Mohammad, S. M. (2018), *Proceedings of ACL 2018*, pp. 174–184 ; "
            "Mohammad, S. M. (2025), *NRC VAD Lexicon v2: Norms for Valence, Arousal, and Dominance "
            "for over 55k English Terms*, `arXiv:2503.23547`"
        ),
        "url": (
            "https://saifmohammad.com/WebPages/nrc-vad.html *(ACL 2018 : "
            "https://aclanthology.org/P18-1017/ ; v2 : https://arxiv.org/abs/2503.23547)*"
        ),
        "license": (
            "**NRC Research License** (Conseil national de recherches du Canada — recherche "
            "académique non commerciale uniquement ; redistribution du fichier brut interdite)"
        ),
    },
    {
        "filename": "DIMA_GROUPE_1_v35-new.xlsx",
        "rel_path": "data/raw/DIMA_GROUPE_1_v35-new.xlsx",
        "dataset": (
            "**DIMA — Dictionnaire Informatisé des Mots d'Affect, Groupe 1 (Catégorie I : Émotions, "
            "v35)** — Le Pesant, D. (2023), *L'Expression des émotions et des sentiments en français* "
            "(coll. *Domaines linguistiques*, vol. 14), Paris : Classiques Garnier "
            "(ISBN 978-2-406-14592-9) ; MoDyCo (CNRS UMR 7114 / Université Paris Nanterre)"
        ),
        "url": (
            "https://modyco.fr/ *(ressource académique distribuée par l'auteur / MoDyCo CNRS UMR 7114 ; "
            "ouvrage de référence : Classiques Garnier, 2023)*"
        ),
        "license": (
            "**Droits d'auteur réservés / usage recherche académique** *(utilisation équitable aux "
            "fins de recherche, art. 29 LDA Canada ; redistribution des fichiers Excel bruts non autorisée)*"
        ),
    },
    {
        "filename": "DIMA_GROUPE_2_v35-new.xlsx",
        "rel_path": "data/raw/DIMA_GROUPE_2_v35-new.xlsx",
        "dataset": (
            "**DIMA — Dictionnaire Informatisé des Mots d'Affect, Groupe 2 (Catégorie II : Sentiments, "
            "v35)** — Le Pesant, D. (2023), *L'Expression des émotions et des sentiments en français* "
            "(coll. *Domaines linguistiques*, vol. 14), Paris : Classiques Garnier "
            "(ISBN 978-2-406-14592-9) ; MoDyCo (CNRS UMR 7114 / Université Paris Nanterre)"
        ),
        "url": (
            "https://modyco.fr/ *(ressource académique distribuée par l'auteur / MoDyCo CNRS UMR 7114 ; "
            "ouvrage de référence : Classiques Garnier, 2023)*"
        ),
        "license": (
            "**Droits d'auteur réservés / usage recherche académique** *(utilisation équitable aux "
            "fins de recherche, art. 29 LDA Canada ; redistribution des fichiers Excel bruts non autorisée)*"
        ),
    },
    {
        "filename": "FANCatdatabaseRevisee.xlsx",
        "rel_path": "data/raw/FANCatdatabaseRevisee.xlsx",
        "dataset": (
            "**FAN / FANCat — French Affective Norms & French Affective Norms for ten emotional "
            "Categories** (1 031 mots français) — **FAN :** Monnier, C., & Syssau, A. (2014), "
            "*Behavior Research Methods*, 46(4), 1128–1137 ; **FANCat :** Syssau, A., Yakhloufi, A., "
            "Giudicelli, E., Monnier, C., & Anders, R. (2021), *Behavior Research Methods*, 53(1), "
            "447–465 *(consignes adaptées de Ric, F., Alexopoulos, T., Muller, D., & Aubé, B., 2013, "
            "BRM, 45(2), 414–421)*"
        ),
        "url": (
            "https://doi.org/10.3758/s13428-020-01450-z *(FAN : "
            "https://doi.org/10.3758/s13428-013-0431-1 ; protocole Ric et al. : "
            "https://doi.org/10.3758/s13428-012-0276-z)*"
        ),
        "license": (
            "**Matériel supplémentaire de recherche académique** (*Behavior Research Methods* / "
            "Springer Nature ; usage scientifique avec citation obligatoire ; redistribution directe du "
            "fichier `.xlsx` exclue du dépôt)"
        ),
    },
]

FANCAT_COLUMNS: list[str] = [
    "word_fr",
    "word_en",
    "valence_fan_mean",
    "valence_fan_sd",
    "arousal_fan_mean",
    "arousal_fan_sd",
    "fancat_n_ratings",
    "awe_mean",
    "awe_sd",
    "contentment_mean",
    "contentment_sd",
    "amusement_mean",
    "amusement_sd",
    "serenity_mean",
    "serenity_sd",
    "excitement_mean",
    "excitement_sd",
    "fear_mean",
    "fear_sd",
    "anger_mean",
    "anger_sd",
    "disgust_mean",
    "disgust_sd",
    "sadness_mean",
    "sadness_sd",
    "anxiety_mean",
    "anxiety_sd",
]

FANCAT_DISCRETE_EMOTIONS: list[str] = [
    "awe",
    "contentment",
    "amusement",
    "serenity",
    "excitement",
    "fear",
    "anger",
    "disgust",
    "sadness",
    "anxiety",
]

DIMA_SNAKE_RENAME: dict[str, str] = {
    "LEMME": "lemme_raw",
    "PART DISC": "part_disc_raw",
    "TYPE": "type_raw",
    "EMPLOI": "emploi",
    "SYNTAXE": "syntaxe",
    "DIATHESES": "diatheses",
    "N0": "n0",
    "N1": "n1",
    "N2": "n2",
    "AJOUT": "ajout",
    "VSUP-1": "vsup_1",
    "VSUP-2": "vsup_2",
    "VSUP-3": "vsup_3",
    "VSUPCONV-1": "vsupconv_1",
    "VSUPCONV-2 ou AuxFactConv": "vsupconv_2_ou_auxfactconv",
    "AUXFACT": "auxfact",
    "REGISTRE": "registre",
    "SEM": "sem",
    "CLASSE": "classe_raw",
    "SOUS-CLASSE": "sous_classe_raw",
    "Entrées antonymes": "entrees_antonymes",
    "ANTONYMIE": "antonymie_raw",
    "CATEG": "categ_raw",
    "LOCUTIONS": "locutions",
}

TIER_RANK: dict[str, int] = {
    "TIER1_STATE": 0,
    "TIER2_VERB_BEHAVIOR": 1,
    "EXCLUDED_CONTEXT": 2,
}

TYPE_RANK: dict[str, int] = {
    "ExpAffect": 0,
    "HumAffect": 1,
    "CaractAffect": 2,
    "ComportAffect": 3,
    "CausAffect": 4,
    "ObjAffect": 5,
    "ParoleAffect": 6,
}

STATE_TYPES = {"ExpAffect", "HumAffect", "CaractAffect"}

HEMISPHERE_ROUTE_RANK: dict[str, int] = {
    "Z_PLUS_ACTIVE": 0,
    "Z_PLUS_SATELLITE": 1,
    "Z_MINUS_RESERVE": 2,
    "NON_LEXICAL_DISCARD": 3,
}

# 12 classes frontières axiologiques/épistémiques (après normalisation des sauts de ligne)
Z_MINUS_VALUE_CANDIDATE_CLASSES: frozenset[str] = frozenset(
    {
        "Bonne conscience",
        "Mauvaise conscience",
        "Mauvaise conscience scrupule",
        "Gratitude",
        "Pudeur",
        "Estime respect",
        "Croyance",
        "Croyance relig",
        "Incrédulité",
        "Incrédulité relig",
        "Défiance_Non fiabilité",
        "Orgueil surestimation de soi",
    }
)


@dataclass(frozen=True)
class RawFileAudit:
    filename: str
    rel_path: str
    size_bytes: int
    sha256: str
    dataset: str
    url: str
    license: str


@dataclass(frozen=True)
class UnnamedCellAudit:
    column: str
    row_index: int
    excel_row: int
    value_repr: str
    value_str: str
    lemme: str
    part_disc: str
    type_val: str
    classe: str
    categ: str


def clean_text(val: Any) -> str:
    """Normalise une chaîne en NFC, remplace les séquences d'espaces/retours ligne par un espace et strip."""
    if val is None or pd.isna(val):
        return ""
    text = unicodedata.normalize("NFC", str(val))
    return re.sub(r"\s+", " ", text).strip()


def clean_optional_text(val: Any) -> str | None:
    """Variante de clean_text retournant None si la chaîne normalisée est vide."""
    cleaned = clean_text(val)
    return cleaned if cleaned else None


def normalize_antonymie(val: Any) -> str | None:
    """Normalise ANTONYMIE en remplaçant les sauts de ligne par ' / ' puis en compactant les espaces."""
    if val is None or pd.isna(val):
        return None
    text = unicodedata.normalize("NFC", str(val))
    text = re.sub(r"\s*[\r\n]+\s*", " / ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text if text else None


def sha256_file(path: Path) -> str:
    """Calcule le digest SHA-256 hexadécimal d'un fichier par blocs."""
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def compute_raw_hashes() -> list[RawFileAudit]:
    """Vérifie la présence des 4 fichiers dans data/raw/ et calcule leurs empreintes SHA-256."""
    audits: list[RawFileAudit] = []
    for meta in RAW_SOURCES_META:
        file_path = RAW_DIR / meta["filename"]
        if not file_path.is_file():
            raise FileNotFoundError(f"Fichier brut manquant : {meta['rel_path']}")
        audits.append(
            RawFileAudit(
                filename=meta["filename"],
                rel_path=meta["rel_path"],
                size_bytes=file_path.stat().st_size,
                sha256=sha256_file(file_path),
                dataset=meta["dataset"],
                url=meta["url"],
                license=meta["license"],
            )
        )
    return audits


def update_data_provenance(audits: list[RawFileAudit]) -> None:
    """Met à jour de façon idempotente les sections 1 et 3 de DATA_PROVENANCE.md."""
    if not PROVENANCE_PATH.is_file():
        raise FileNotFoundError("DATA_PROVENANCE.md introuvable à la racine du dépôt.")

    content = PROVENANCE_PATH.read_text(encoding="utf-8")

    table_lines = [
        "<!-- BEGIN:MP1_SOURCES_TABLE -->",
        "| Fichier local attendu (exclu de Git) | Jeu de données & référence canonique | URL source canonique | Licence d'origine | SHA-256 vérifié (local) |",
        "| :--- | :--- | :--- | :--- | :--- |",
    ]
    for item in audits:
        table_lines.append(
            f"| `{item.rel_path}` (`{item.size_bytes:,}` octets) | {item.dataset} | {item.url} | "
            f"{item.license} | `{item.sha256}` |"
        )
    table_lines.append("<!-- END:MP1_SOURCES_TABLE -->")
    table_block = "\n".join(table_lines)

    sec1_pattern = re.compile(
        r"(## 1\. Jeux de données tiers non redistribuables\r?\n\r?\n)(.*?)(\r?\n---\r?\n\r?\n## 2\.)",
        flags=re.DOTALL,
    )
    if not sec1_pattern.search(content):
        raise ValueError("Structure attendue de DATA_PROVENANCE.md introuvable (Section 1 -> Section 2).")
    content = sec1_pattern.sub(lambda m: f"{m.group(1)}{table_block}{m.group(3)}", content, count=1)

    sha_cmd_block = "\n".join(
        [
            "<!-- BEGIN:MP1_SHA_COMMANDS -->",
            "Après téléchargement autorisé des fichiers tiers dans `data/raw/` (exclu du suivi Git via `.gitignore` / contrôle FAIR4RS), calculer localement leur empreinte SHA-256 :",
            "",
            "**PowerShell (Windows) :**",
            "```powershell",
            "Get-FileHash -Algorithm SHA256 `",
            "  data/raw/NRC-VAD-Lexicon-v2.1.txt, `",
            "  data/raw/DIMA_GROUPE_1_v35-new.xlsx, `",
            "  data/raw/DIMA_GROUPE_2_v35-new.xlsx, `",
            "  data/raw/FANCatdatabaseRevisee.xlsx",
            "```",
            "",
            "**Linux / macOS :**",
            "```bash",
            "sha256sum \\",
            "  data/raw/NRC-VAD-Lexicon-v2.1.txt \\",
            "  data/raw/DIMA_GROUPE_1_v35-new.xlsx \\",
            "  data/raw/DIMA_GROUPE_2_v35-new.xlsx \\",
            "  data/raw/FANCatdatabaseRevisee.xlsx",
            "```",
            "<!-- END:MP1_SHA_COMMANDS -->",
        ]
    )
    sec3_pattern = re.compile(
        r"(## 3\. Procédure de vérification locale SHA-256\r?\n\r?\n)(.*?)(\r?\n## 4\.)",
        flags=re.DOTALL,
    )
    if sec3_pattern.search(content):
        content = sec3_pattern.sub(lambda m: f"{m.group(1)}{sha_cmd_block}\n{m.group(3)}", content, count=1)

    PROVENANCE_PATH.write_text(content, encoding="utf-8")


def load_dima() -> tuple[pd.DataFrame, list[UnnamedCellAudit], dict[str, int]]:
    """Charge DIMA 1 (Émotions) et DIMA 2 (Sentiments), audite et écarte les colonnes Unnamed:*."""
    p1 = RAW_DIR / "DIMA_GROUPE_1_v35-new.xlsx"
    p2 = RAW_DIR / "DIMA_GROUPE_2_v35-new.xlsx"

    df1 = pd.read_excel(p1, sheet_name="Émotions")
    df2 = pd.read_excel(p2, sheet_name="Sentiments")

    unnamed_1 = [c for c in df1.columns if str(c).startswith("Unnamed:")]
    if unnamed_1:
        raise AssertionError(f"Colonnes Unnamed inattendues dans DIMA 1 : {unnamed_1}")

    unnamed_2 = [c for c in df2.columns if str(c).startswith("Unnamed:")]
    unnamed_non_null_counts: dict[str, int] = {}
    cell_audits: list[UnnamedCellAudit] = []

    print("[MP1][DIMA 2] Inspection des colonnes Unnamed:* :")
    for col in unnamed_2:
        nn = df2[col].dropna()
        unnamed_non_null_counts[str(col)] = int(len(nn))
        print(f"  - {col} : {len(nn)} cellule(s) non nulle(s)")
        for idx, val in nn.items():
            row_idx = int(idx)
            excel_row = row_idx + 2
            audit = UnnamedCellAudit(
                column=str(col),
                row_index=row_idx,
                excel_row=excel_row,
                value_repr=repr(val),
                value_str=str(val),
                lemme=clean_text(df2.at[idx, "LEMME"]),
                part_disc=clean_text(df2.at[idx, "PART DISC"]),
                type_val=clean_text(df2.at[idx, "TYPE"]),
                classe=clean_text(df2.at[idx, "CLASSE"]),
                categ=clean_text(df2.at[idx, "CATEG"]),
            )
            cell_audits.append(audit)
            print(
                f"      [CELLULE] col={audit.column} | df_idx={audit.row_index} | "
                f"excel_row={audit.excel_row} | val={audit.value_repr} | "
                f"context=(LEMME={audit.lemme!r}, PART_DISC={audit.part_disc!r}, "
                f"TYPE={audit.type_val!r}, CLASSE={audit.classe!r}, CATEG={audit.categ!r})"
            )

    if len(cell_audits) != 3:
        raise AssertionError(f"Nombre inattendu de cellules non nulles dans Unnamed:* : {len(cell_audits)} (attendu 3).")

    df2_clean = df2.drop(columns=unnamed_2).copy()
    if list(df1.columns) != list(df2_clean.columns):
        raise AssertionError("Les 24 colonnes de DIMA 1 et DIMA 2 nettoyé ne correspondent pas.")

    df1 = df1.copy()
    df1["dima_groupe"] = 1
    df1["source_file"] = p1.name
    df1["excel_row"] = df1.index.astype("int64") + 2

    df2_clean["dima_groupe"] = 2
    df2_clean["source_file"] = p2.name
    df2_clean["excel_row"] = df2_clean.index.astype("int64") + 2

    df_raw = pd.concat([df1, df2_clean], ignore_index=True)
    df_raw["raw_row_order"] = df_raw.index.astype("int64")
    return df_raw, cell_audits, unnamed_non_null_counts


def classify_tier(part_disc: str, type_val: str, is_classifier: bool) -> tuple[str, str]:
    """Assigne le tier lexical v3.0.0 et la raison explicite pour une ligne DIMA."""
    if is_classifier:
        return "EXCLUDED_CONTEXT", "classifier_class"
    if part_disc in {"NOM", "ADJ"} and type_val in STATE_TYPES:
        return "TIER1_STATE", f"{part_disc}+{type_val}"
    if (part_disc == "VERB" and type_val in STATE_TYPES) or (type_val == "ComportAffect"):
        return "TIER2_VERB_BEHAVIOR", f"{part_disc}+{type_val}"
    reason = type_val if type_val in {"CausAffect", "ObjAffect", "ParoleAffect"} else f"non_state_pos:{part_disc}"
    return "EXCLUDED_CONTEXT", reason


def classify_hemisphere_route(part_disc: str, type_val: str, is_classifier: bool) -> tuple[str, str]:
    """Assigne la route bi-hémisphérique (Z+ actif vs réserve -Z) et le bucket d'élagage réversible."""
    if is_classifier:
        return "NON_LEXICAL_DISCARD", "META_CLASSIFIER"
    if part_disc in {"NOM", "ADJ"} and type_val == "ExpAffect":
        return "Z_PLUS_ACTIVE", "Z_PLUS_EXPAFFECT"
    if part_disc in {"NOM", "ADJ"} and type_val == "HumAffect":
        return "Z_PLUS_ACTIVE", "Z_PLUS_HUMAFFECT"
    if part_disc == "VERB" and type_val in {"ExpAffect", "HumAffect"}:
        return "Z_PLUS_SATELLITE", "Z_PLUS_VERB_EXP"
    if type_val == "CaractAffect":
        return "Z_MINUS_RESERVE", "Z_MINUS_TRAIT_CARACT"
    if type_val in {"ComportAffect", "ParoleAffect"}:
        return "Z_MINUS_RESERVE", "Z_MINUS_BEHAVIOR_SPEECH"
    if type_val == "ObjAffect":
        return "Z_MINUS_RESERVE", "Z_MINUS_OBJAFFECT"
    if type_val == "CausAffect":
        return "Z_MINUS_RESERVE", "Z_MINUS_CAUSAFFECT"
    return "NON_LEXICAL_DISCARD", "GRAMMATICAL_ADV_PREP"


def normalize_and_merge_dima(df_raw: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    """Normalise DIMA 1+2, assigne `tier` et le routage Z+/Z-, et fusionne sur (lemme_norm, part_disc, classe, categ)."""
    df = df_raw.copy()

    df["lemme_norm"] = df["LEMME"].map(clean_text).str.lower()
    df["part_disc"] = df["PART DISC"].map(clean_text)
    df["type"] = df["TYPE"].map(clean_text)
    df["classe"] = df["CLASSE"].map(clean_text)
    df["categ"] = df["CATEG"].map(clean_text)
    df["sous_classe"] = df["SOUS-CLASSE"].map(clean_optional_text)
    df["antonymie"] = df["ANTONYMIE"].map(normalize_antonymie)
    df["is_locution"] = df["LOCUTIONS"].map(clean_text).ne("")
    df["is_classifier"] = df["classe"].str.lower().str.contains("classifieur", regex=False)

    tiers = [
        classify_tier(pd_val, tp_val, bool(clf))
        for pd_val, tp_val, clf in zip(df["part_disc"], df["type"], df["is_classifier"])
    ]
    df["tier"] = [t[0] for t in tiers]
    df["tier_reason"] = [t[1] for t in tiers]

    routes = [
        classify_hemisphere_route(pd_val, tp_val, bool(clf))
        for pd_val, tp_val, clf in zip(df["part_disc"], df["type"], df["is_classifier"])
    ]
    df["hemisphere_route"] = [r[0] for r in routes]
    df["pruning_bucket"] = [r[1] for r in routes]

    df["_route_rank"] = df["hemisphere_route"].map(HEMISPHERE_ROUTE_RANK).fillna(99).astype("int64")
    df["_tier_rank"] = df["tier"].map(TIER_RANK).fillna(99).astype("int64")
    df["_type_rank"] = df["type"].map(TYPE_RANK).fillna(99).astype("int64")
    df["_emploi_num"] = pd.to_numeric(df["EMPLOI"], errors="coerce").fillna(999.0)

    key_cols = ["lemme_norm", "part_disc", "classe", "categ"]

    # Traçabilité des clés dupliquées avant fusion (priorité Z_PLUS_ACTIVE > Z_PLUS_SATELLITE > Z_MINUS_RESERVE > NON_LEXICAL_DISCARD)
    dup_mask = df.duplicated(subset=key_cols, keep=False)
    df_dups = df[dup_mask].sort_values(key_cols + ["raw_row_order"], kind="mergesort")
    merged_key_audits: list[dict[str, Any]] = []
    for key_vals, grp in df_dups.groupby(key_cols, sort=False):
        grp_sorted = grp.sort_values(
            ["_route_rank", "_tier_rank", "_type_rank", "_emploi_num", "raw_row_order"], kind="mergesort"
        )
        naive_first = grp.iloc[0]
        chosen = grp_sorted.iloc[0]
        merged_key_audits.append(
            {
                "lemme_norm": key_vals[0],
                "part_disc": key_vals[1],
                "classe": key_vals[2],
                "categ": key_vals[3],
                "n_rows": int(len(grp)),
                "raw_types_order": " | ".join(grp["type"].tolist()),
                "raw_tiers_order": " | ".join(grp["tier"].tolist()),
                "raw_routes_order": " | ".join(grp["hemisphere_route"].tolist()),
                "chosen_type": chosen["type"],
                "chosen_tier": chosen["tier"],
                "chosen_route": chosen["hemisphere_route"],
                "naive_first_type": naive_first["type"],
                "naive_first_tier": naive_first["tier"],
                "naive_first_route": naive_first["hemisphere_route"],
                "saved_by_priority_sort": bool(
                    chosen["hemisphere_route"] != naive_first["hemisphere_route"]
                    or chosen["tier"] != naive_first["tier"]
                    or chosen["type"] != naive_first["type"]
                ),
            }
        )
    df_dup_audit = pd.DataFrame(merged_key_audits)

    # Agrégation prioritaire par clé
    df_sorted = df.sort_values(
        key_cols + ["_route_rank", "_tier_rank", "_type_rank", "_emploi_num", "raw_row_order"],
        kind="mergesort",
    )

    def _join_unique(series: pd.Series) -> str | None:
        seen: list[str] = []
        for item in series:
            if item is None or pd.isna(item):
                continue
            s = str(item).strip()
            if s and s not in seen:
                seen.append(s)
        return "|".join(seen) if seen else None

    def _join_emplois(series: pd.Series) -> str | None:
        seen: list[str] = []
        for item in series:
            if item is None or pd.isna(item):
                continue
            val_str = str(int(item)) if float(item).is_integer() else str(item)
            if val_str not in seen:
                seen.append(val_str)
        return "|".join(seen) if seen else None

    grouped_meta = (
        df_sorted.groupby(key_cols, sort=False, as_index=False)
        .agg(
            n_emplois_merged=("raw_row_order", "size"),
            types_all=("type", _join_unique),
            tiers_all=("tier", _join_unique),
            routes_all=("hemisphere_route", _join_unique),
            emplois_all=("EMPLOI", _join_emplois),
            sous_classes_all=("sous_classe", _join_unique),
        )
    )

    df_primary = df_sorted.drop_duplicates(subset=key_cols, keep="first").copy()
    df_merged = df_primary.merge(grouped_meta, on=key_cols, how="left", validate="one_to_one")
    df_merged = df_merged.drop(columns=["_route_rank", "_tier_rank", "_type_rank", "_emploi_num"])
    df_merged = df_merged.rename(columns=DIMA_SNAKE_RENAME)

    df_merged["z_minus_value_candidate"] = (
        (df_merged["hemisphere_route"] == "Z_PLUS_ACTIVE")
        & (df_merged["classe"].isin(Z_MINUS_VALUE_CANDIDATE_CLASSES))
    ).astype(bool)

    # Normalisation explicite des types pour Parquet sans avertissement
    df_merged["emploi"] = pd.to_numeric(df_merged["emploi"], errors="coerce").astype("float64")
    string_cols = [
        "lemme_norm",
        "part_disc",
        "classe",
        "categ",
        "type",
        "tier",
        "tier_reason",
        "hemisphere_route",
        "pruning_bucket",
        "sous_classe",
        "antonymie",
        "source_file",
        "types_all",
        "tiers_all",
        "routes_all",
        "emplois_all",
        "sous_classes_all",
        *DIMA_SNAKE_RENAME.values(),
    ]
    for col in string_cols:
        if col == "emploi":
            continue
        df_merged[col] = df_merged[col].map(lambda x: None if pd.isna(x) else str(x)).astype("string")

    ordered_cols = [
        "lemme_norm",
        "part_disc",
        "classe",
        "categ",
        "type",
        "tier",
        "tier_reason",
        "hemisphere_route",
        "pruning_bucket",
        "z_minus_value_candidate",
        "sous_classe",
        "antonymie",
        "is_locution",
        "is_classifier",
        "dima_groupe",
        "source_file",
        "excel_row",
        "raw_row_order",
        "n_emplois_merged",
        "types_all",
        "tiers_all",
        "routes_all",
        "emplois_all",
        "sous_classes_all",
        "lemme_raw",
        "part_disc_raw",
        "type_raw",
        "emploi",
        "syntaxe",
        "diatheses",
        "n0",
        "n1",
        "n2",
        "ajout",
        "vsup_1",
        "vsup_2",
        "vsup_3",
        "vsupconv_1",
        "vsupconv_2_ou_auxfactconv",
        "auxfact",
        "registre",
        "sem",
        "classe_raw",
        "sous_classe_raw",
        "entrees_antonymes",
        "antonymie_raw",
        "categ_raw",
        "locutions",
    ]
    df_merged = df_merged[ordered_cols].sort_values(["categ", "classe", "lemme_norm", "part_disc"], kind="mergesort").reset_index(drop=True)

    # Contrôles stricts
    assert len(df_raw) == 3373, f"Nombre de lignes brutes DIMA inattendu : {len(df_raw)}"
    assert len(df_merged) == 3342, f"Nombre d'entrées fusionnées DIMA inattendu : {len(df_merged)}"
    assert df_merged.duplicated(subset=key_cols).sum() == 0, "Clés dupliquées résiduelles après fusion."
    assert df_merged["classe"].nunique() == 109, f"Nombre de classes DIMA inattendu : {df_merged['classe'].nunique()}"
    assert Z_MINUS_VALUE_CANDIDATE_CLASSES.issubset(set(df_merged["classe"].unique())), "Classes frontières -Z manquantes."
    for req_col in ("lemme_norm", "part_disc", "classe", "categ", "tier", "hemisphere_route", "pruning_bucket"):
        assert df_merged[req_col].isna().sum() == 0, f"Valeurs nulles interdites dans {req_col}"

    route_counts = df_merged["hemisphere_route"].value_counts().to_dict()
    assert route_counts == {
        "Z_MINUS_RESERVE": 1229,
        "Z_PLUS_ACTIVE": 966,
        "Z_PLUS_SATELLITE": 670,
        "NON_LEXICAL_DISCARD": 477,
    }, f"Comptages hemisphere_route inattendus : {route_counts}"
    assert int(df_merged["z_minus_value_candidate"].sum()) == 46, (
        f"Nombre inattendu de candidats z_minus_value_candidate : {int(df_merged['z_minus_value_candidate'].sum())}"
    )

    return df, df_merged, df_dup_audit


def build_dima_classes_summary(df_raw_norm: pd.DataFrame, df_merged: pd.DataFrame) -> pd.DataFrame:
    """Construit la table synthétique des 109 classes DIMA (effectifs, tiers, routes Z+/Z- et familles ANTONYMIE)."""
    raw_counts = (
        df_raw_norm.groupby(["categ", "classe"], as_index=False)
        .agg(n_raw_rows=("raw_row_order", "size"))
    )

    records: list[dict[str, Any]] = []
    for (categ, classe), grp in df_merged.groupby(["categ", "classe"], sort=True):
        ant_vals = sorted({str(a) for a in grp["antonymie"].dropna() if str(a).strip()})
        ant_family = " || ".join(ant_vals) if ant_vals else ""
        t_counts = grp["tier"].value_counts().to_dict()
        r_counts = grp["hemisphere_route"].value_counts().to_dict()
        tp_counts = grp["type"].value_counts().to_dict()
        pos_counts = grp["part_disc"].value_counts().to_dict()

        n_nom = int(pos_counts.get("NOM", 0))
        n_adj = int(pos_counts.get("ADJ", 0))
        n_verb = int(pos_counts.get("VERB", 0))
        n_other_pos = int(len(grp) - (n_nom + n_adj + n_verb))

        records.append(
            {
                "categ": str(categ),
                "classe": str(classe),
                "antonymie_family": ant_family,
                "is_classifier": bool(grp["is_classifier"].any()),
                "n_entries": int(len(grp)),
                "n_unique_lemmes": int(grp["lemme_norm"].nunique()),
                "n_tier1_state": int(t_counts.get("TIER1_STATE", 0)),
                "n_tier2_verb_behavior": int(t_counts.get("TIER2_VERB_BEHAVIOR", 0)),
                "n_excluded_context": int(t_counts.get("EXCLUDED_CONTEXT", 0)),
                "n_z_plus_active": int(r_counts.get("Z_PLUS_ACTIVE", 0)),
                "n_z_plus_satellite": int(r_counts.get("Z_PLUS_SATELLITE", 0)),
                "n_z_minus_reserve": int(r_counts.get("Z_MINUS_RESERVE", 0)),
                "n_non_lexical_discard": int(r_counts.get("NON_LEXICAL_DISCARD", 0)),
                "n_z_minus_value_candidate": int(grp["z_minus_value_candidate"].sum()),
                "n_exp_affect": int(tp_counts.get("ExpAffect", 0)),
                "n_hum_affect": int(tp_counts.get("HumAffect", 0)),
                "n_caract_affect": int(tp_counts.get("CaractAffect", 0)),
                "n_comport_affect": int(tp_counts.get("ComportAffect", 0)),
                "n_caus_affect": int(tp_counts.get("CausAffect", 0)),
                "n_obj_affect": int(tp_counts.get("ObjAffect", 0)),
                "n_parole_affect": int(tp_counts.get("ParoleAffect", 0)),
                "n_nom": n_nom,
                "n_adj": n_adj,
                "n_verb": n_verb,
                "n_other_pos": n_other_pos,
            }
        )

    summary = pd.DataFrame(records).merge(raw_counts, on=["categ", "classe"], how="left", validate="one_to_one")
    col_order = [
        "categ",
        "classe",
        "antonymie_family",
        "is_classifier",
        "n_raw_rows",
        "n_entries",
        "n_unique_lemmes",
        "n_tier1_state",
        "n_tier2_verb_behavior",
        "n_excluded_context",
        "n_z_plus_active",
        "n_z_plus_satellite",
        "n_z_minus_reserve",
        "n_non_lexical_discard",
        "n_z_minus_value_candidate",
        "n_exp_affect",
        "n_hum_affect",
        "n_caract_affect",
        "n_comport_affect",
        "n_caus_affect",
        "n_obj_affect",
        "n_parole_affect",
        "n_nom",
        "n_adj",
        "n_verb",
        "n_other_pos",
    ]
    summary = summary[col_order].sort_values(["categ", "classe"], kind="mergesort").reset_index(drop=True)

    assert len(summary) == 109, f"Nombre de classes dans le résumé inattendu : {len(summary)}"
    assert int(summary["n_entries"].sum()) == 3342
    assert int(summary["n_raw_rows"].sum()) == 3373
    assert int(summary["n_z_plus_active"].sum()) == 966
    assert int(summary["n_z_plus_satellite"].sum()) == 670
    assert int(summary["n_z_minus_reserve"].sum()) == 1229
    assert int(summary["n_non_lexical_discard"].sum()) == 477
    assert int(summary["n_z_minus_value_candidate"].sum()) == 46
    assert (
        summary["n_z_plus_active"]
        + summary["n_z_plus_satellite"]
        + summary["n_z_minus_reserve"]
        + summary["n_non_lexical_discard"]
        == summary["n_entries"]
    ).all()
    return summary


def load_fancat() -> tuple[pd.DataFrame, dict[str, int]]:
    """Charge FANCatdatabaseRevisee.xlsx (FANCat All), saute la ligne Mean/SD et renomme les 27 colonnes."""
    fancat_path = RAW_DIR / "FANCatdatabaseRevisee.xlsx"
    headers = pd.read_excel(fancat_path, sheet_name="FANCat All", header=None, nrows=2)
    assert headers.shape == (2, 27), f"En-tête FANCat inattendu : {headers.shape}"
    assert clean_text(headers.iloc[0, 0]) == "French"
    assert clean_text(headers.iloc[0, 1]) == "English"
    assert clean_text(headers.iloc[0, 2]) == "Valence FAN"
    assert clean_text(headers.iloc[0, 4]) == "Arousal FAN"
    assert clean_text(headers.iloc[0, 6]) == "FANCat"
    assert clean_text(headers.iloc[0, 7]) == "Awe"
    assert clean_text(headers.iloc[0, 25]) == "Anxiety"
    assert clean_text(headers.iloc[1, 0]) == "Words"
    assert clean_text(headers.iloc[1, 1]) == "Translation"
    assert clean_text(headers.iloc[1, 2]) == "Mean"
    assert clean_text(headers.iloc[1, 3]) == "SD"
    assert clean_text(headers.iloc[1, 6]) == "N of ratings"

    df = pd.read_excel(fancat_path, sheet_name="FANCat All", skiprows=2, header=None)
    assert df.shape[1] == 27, f"Nombre de colonnes FANCat inattendu : {df.shape[1]}"
    df.columns = FANCAT_COLUMNS

    fr_raw = df["word_fr"].astype(str)
    en_raw = df["word_en"].astype(str)
    stats = {
        "n_fr_whitespace_trimmed": int((fr_raw != fr_raw.str.strip()).sum()),
        "n_en_whitespace_trimmed": int((en_raw != en_raw.str.strip()).sum()),
        "n_fr_upper_normalized": int((fr_raw.str.strip() != fr_raw.str.strip().str.lower()).sum()),
    }

    df["word_fr"] = df["word_fr"].map(clean_text).astype("string")
    df["word_en"] = df["word_en"].map(clean_text).astype("string")
    df["word_fr_norm"] = df["word_fr"].str.lower().astype("string")
    df["word_en_norm"] = df["word_en"].str.lower().astype("string")

    df["fancat_n_ratings"] = pd.to_numeric(df["fancat_n_ratings"], errors="raise").astype("int64")
    float_cols = [c for c in FANCAT_COLUMNS if c not in ("word_fr", "word_en", "fancat_n_ratings")]
    for col in float_cols:
        df[col] = pd.to_numeric(df[col], errors="raise").astype("float64")

    ordered = ["word_fr", "word_fr_norm", "word_en", "word_en_norm", *FANCAT_COLUMNS[2:]]
    df = df[ordered].reset_index(drop=True)

    assert len(df) == 1031, f"Nombre de lignes FANCat inattendu : {len(df)}"
    assert int(df.isna().sum().sum()) == 0, "Valeurs nulles détectées dans FANCat."
    assert df["word_fr_norm"].duplicated().sum() == 0, "Doublons sur word_fr_norm dans FANCat."
    assert df["valence_fan_mean"].between(1.0, 9.0).all()
    assert df["arousal_fan_mean"].between(1.0, 9.0).all()
    for emo in FANCAT_DISCRETE_EMOTIONS:
        assert df[f"{emo}_mean"].between(1.0, 5.0).all(), f"Hors bornes [1, 5] pour {emo}_mean"

    return df, stats


def load_nrc_vad() -> pd.DataFrame:
    """Charge et audite NRC-VAD-Lexicon-v2.1.txt (TSV) sans convertir 'null'/'nan' en NaN."""
    nrc_path = RAW_DIR / "NRC-VAD-Lexicon-v2.1.txt"
    df = pd.read_csv(
        nrc_path,
        sep="\t",
        encoding="utf-8",
        keep_default_na=False,
        dtype={
            "term": "string",
            "valence": "float64",
            "arousal": "float64",
            "dominance": "float64",
        },
    )
    assert list(df.columns) == ["term", "valence", "arousal", "dominance"], f"Colonnes NRC inattendues : {list(df.columns)}"
    df["term_norm"] = df["term"].map(clean_text).str.lower().astype("string")
    df["is_mwe"] = df["term_norm"].str.contains(" ", regex=False)

    assert len(df) == 54801, f"Nombre de termes NRC-VAD inattendu : {len(df)}"
    assert int(df.isna().sum().sum()) == 0, "Valeurs nulles détectées dans NRC-VAD."
    assert (df["term_norm"] == "").sum() == 0, "Termes vides dans NRC-VAD."
    assert df["term_norm"].duplicated().sum() == 0, "Doublons sur term_norm dans NRC-VAD."
    for axis in ("valence", "arousal", "dominance"):
        assert df[axis].between(-1.0, 1.0).all(), f"Score {axis} hors [-1, 1]"
    return df


def build_audit_report(
    raw_audits: list[RawFileAudit],
    unnamed_non_null_counts: dict[str, int],
    unnamed_cells: list[UnnamedCellAudit],
    df_dima_raw_norm: pd.DataFrame,
    df_dima_merged: pd.DataFrame,
    df_dup_audit: pd.DataFrame,
    df_classes_summary: pd.DataFrame,
    df_fancat: pd.DataFrame,
    fancat_stats: dict[str, int],
    df_nrc: pd.DataFrame,
    processed_artifacts: list[tuple[str, int, str]],
) -> str:
    """Génère le rapport markdown d'audit de la Micro-Passe 1 (sans chemin absolu local)."""
    now_utc = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

    lines: list[str] = [
        "# Rapport d'Audit — Micro-Passe 1 : Ingestion & Gouvernance lexicale (CARTOGRAFFECT v3.0.0)",
        "",
        f"- **Date d'exécution :** `{now_utc}`",
        "- **Script :** [`python/lexicon_pipeline/01_ingest_normalize.py`](../../python/lexicon_pipeline/01_ingest_normalize.py)",
        "- **Périmètre Lean 4 :** `Cartograffect/` strictement en lecture seule (0 fichier modifié)",
        "- **Gouvernance FAIR4RS :** [`DATA_PROVENANCE.md`](../../DATA_PROVENANCE.md) mis à jour de façon idempotente ; `data/raw/` et les dérivés FANCat restent exclus du suivi Git.",
        "",
        "---",
        "",
        "## 1. Sources brutes vérifiées (SHA-256)",
        "",
        "| Fichier (`data/raw/`) | Taille (octets) | SHA-256 |",
        "| :--- | ---: | :--- |",
    ]
    for item in raw_audits:
        lines.append(f"| `{item.rel_path}` | {item.size_bytes:,} | `{item.sha256}` |")

    lines.extend(
        [
            "",
            "---",
            "",
            "## 2. Audit des colonnes `Unnamed:*` dans `DIMA_GROUPE_2_v35-new.xlsx` (onglet `Sentiments`)",
            "",
            "Les 7 colonnes excédentaires (`Unnamed: 24` à `Unnamed: 30`) présentes dans `DIMA_GROUPE_2_v35-new.xlsx` ont été inspectées avant suppression :",
            "",
            "| Colonne | Cellules non nulles | Statut |",
            "| :--- | ---: | :--- |",
        ]
    )
    for col_name, count in unnamed_non_null_counts.items():
        status = "Journalisée puis écartée" if count > 0 else "Vide — écartée"
        lines.append(f"| `{col_name}` | {count} | {status} |")

    lines.extend(
        [
            "",
            "### Contenu exact des 3 cellules non nulles journalisées",
            "",
            "| Colonne | Index DataFrame | Ligne Excel | Valeur exacte (`repr`) | Contexte DIMA (`LEMME`, `PART DISC`, `TYPE`, `CLASSE`, `CATEG`) |",
            "| :--- | ---: | ---: | :--- | :--- |",
        ]
    )
    for cell in unnamed_cells:
        lines.append(
            f"| `{cell.column}` | {cell.row_index} | {cell.excel_row} | `{cell.value_repr}` | "
            f"`({cell.lemme}, {cell.part_disc}, {cell.type_val}, {cell.classe}, {cell.categ})` |"
        )

    # Bilan fusion DIMA
    tier_counts = df_dima_merged["tier"].value_counts().to_dict()
    total_merged = len(df_dima_merged)
    n_saved = int(df_dup_audit["saved_by_priority_sort"].sum()) if len(df_dup_audit) else 0

    lines.extend(
        [
            "",
            "---",
            "",
            "## 3. Normalisation et fusion DIMA 1 + DIMA 2",
            "",
            f"- **Lignes brutes chargées :** `{len(df_dima_raw_norm)}` (`1 401` DIMA 1 Catégorie I + `1 972` DIMA 2 Catégorie II)",
            f"- **Entrées uniques après fusion sur `(lemme_norm, part_disc, classe, categ)` :** `{total_merged}`",
            f"- **Clés dupliquées consolidées :** `{len(df_dup_audit)}` clés distinctes ({int(df_dup_audit['n_rows'].sum())} lignes brutes fusionnées en {len(df_dup_audit)} entrées ; **0 doublon inter-groupes** I/II)",
            f"- **Clés protégées par le tri prioritaire :** `{n_saved}` / `{len(df_dup_audit)}` clés où la ligne brute apparaissant en premier avait un emploi moins central (ex. `CausAffect`/`ObjAffect`) que la ligne `ExpAffect` retenue.",
            "",
            "### Répartition par `tier` (sur les 3 342 entrées fusionnées)",
            "",
            "| Tier | Effectif | Part (%) |",
            "| :--- | ---: | ---: |",
        ]
    )
    for tier_name in ("TIER1_STATE", "TIER2_VERB_BEHAVIOR", "EXCLUDED_CONTEXT"):
        cnt = int(tier_counts.get(tier_name, 0))
        pct = 100.0 * cnt / total_merged
        lines.append(f"| `{tier_name}` | {cnt} | {pct:.2f}% |")

    lines.extend(
        [
            "",
            "### Tableau croisé `part_disc × type → tier` (3 342 entrées fusionnées)",
            "",
            "| `part_disc` | `type` | `tier` | `tier_reason` | Effectif |",
            "| :--- | :--- | :--- | :--- | ---: |",
        ]
    )
    ct_df = (
        df_dima_merged.groupby(["part_disc", "type", "tier", "tier_reason"], as_index=False)
        .size()
        .sort_values(["tier", "size", "part_disc", "type"], ascending=[True, False, True, True], kind="mergesort")
    )
    for _, r in ct_df.iterrows():
        lines.append(f"| `{r['part_disc']}` | `{r['type']}` | `{r['tier']}` | `{r['tier_reason']}` | {int(r['size'])} |")

    # Cas frontières pour validation humaine
    n_clf = int(df_dima_merged["is_classifier"].sum())
    n_adv_comp = int(((df_dima_merged["part_disc"] == "ADVERB") & (df_dima_merged["type"] == "ComportAffect")).sum())
    n_parole = int((df_dima_merged["type"] == "ParoleAffect").sum())
    n_adjrelat = int((df_dima_merged["part_disc"] == "ADJRELAT").sum())

    lines.extend(
        [
            "",
            "### Cas frontières signalés pour validation humaine",
            "",
            f"- **Classifieurs exclus (`EXCLUDED_CONTEXT`, `classifier_class`) :** `{n_clf}` entrées (`Z Classifieurs` : 12, `Sentiment classifieur` : 3) — écartées explicitement conformément au cahier des charges.",
            f"- **`ADVERB + ComportAffect` en `TIER2_VERB_BEHAVIOR` :** `{n_adv_comp}` entrées (ex. *comme un fauve en cage*, *avec rancune* / *acrimonieusement*) — incluses via la clause `OU TYPE == 'ComportAffect'`.",
            f"- **`ParoleAffect` en `EXCLUDED_CONTEXT` :** `{n_parole}` entrées (ex. *gueuler*, *pester*, *vitupérer*) — exclues car ne relevant pas de `ExpAffect/HumAffect/CaractAffect/ComportAffect`.",
            f"- **`ADJRELAT` en `EXCLUDED_CONTEXT` :** `{n_adjrelat}` entrées (adjectifs relationnels *affectif*, *émotionnel*, *amoureux*, *phobique*, etc.) — exclues car `PART DISC == 'ADJRELAT'` hors `{{NOM, ADJ}}`.",
            "",
            "### Détail des 30 clés multi-emplois consolidées",
            "",
            "| `lemme_norm` | `part_disc` | `classe` | `categ` | Lignes | Types bruts (ordre fichier) | Retenu (`tier` / `type`) | Sauvé par tri prioritaire |",
            "| :--- | :--- | :--- | :--- | ---: | :--- | :--- | :---: |",
        ]
    )
    for _, r in df_dup_audit.iterrows():
        saved_flag = "OUI" if r["saved_by_priority_sort"] else "non"
        lines.append(
            f"| `{r['lemme_norm']}` | `{r['part_disc']}` | `{r['classe']}` | `{r['categ']}` | "
            f"{int(r['n_rows'])} | `{r['raw_types_order']}` | `{r['chosen_tier']}` / `{r['chosen_type']}` | {saved_flag} |"
        )

    # Routage bi-hémisphérique Z+ / Réserve -Z (Micro-Passe 1b)
    route_counts = df_dima_merged["hemisphere_route"].value_counts().to_dict()
    bucket_counts = (
        df_dima_merged.groupby(["hemisphere_route", "pruning_bucket"], as_index=False)
        .size()
        .sort_values(["hemisphere_route", "size", "pruning_bucket"], ascending=[True, False, True], kind="mergesort")
    )
    cand_df = df_dima_merged[df_dima_merged["z_minus_value_candidate"]]
    cand_summary = (
        cand_df.groupby(["classe", "pruning_bucket"], as_index=False)
        .agg(
            effectif=("lemme_norm", "size"),
            exemples=("lemme_norm", lambda s: ", ".join(sorted(set(s))[:5])),
        )
        .sort_values(["classe", "pruning_bucket"], kind="mergesort")
    )
    route_changed = df_dup_audit[df_dup_audit["chosen_route"] != df_dup_audit["naive_first_route"]]

    lines.extend(
        [
            "",
            "---",
            "",
            "## 4. Routage bi-hémisphérique $Z_+$ / Réserve $-Z$ (Micro-Passe 1b)",
            "",
            "L'élagage réversible sans perte partitionne les `3 342` entrées DIMA en 4 routes et 9 buckets (`Z_PLUS_ACTIVE > Z_PLUS_SATELLITE > Z_MINUS_RESERVE > NON_LEXICAL_DISCARD`) :",
            "",
            "### Répartition par `hemisphere_route`",
            "",
            "| Route (`hemisphere_route`) | Effectif | Part (%) | Rôle architectural |",
            "| :--- | ---: | ---: | :--- |",
        ]
    )
    route_roles = {
        "Z_PLUS_ACTIVE": "Cœur actif $Z_+$ (`NOM`/`ADJ` en `ExpAffect` ou `HumAffect`)",
        "Z_PLUS_SATELLITE": "Satellites verbaux $Z_+$ (`VERB` en `ExpAffect` ou `HumAffect`)",
        "Z_MINUS_RESERVE": "Réserve structurée $-Z$ (exportée localement dans `data/processed/dima_z_minus_reserve.parquet`)",
        "NON_LEXICAL_DISCARD": "Écartés non lexicaux (`META_CLASSIFIER` + adverbes/prépositions/conjonctions/`ADJRELAT`)",
    }
    for r_name in ("Z_PLUS_ACTIVE", "Z_PLUS_SATELLITE", "Z_MINUS_RESERVE", "NON_LEXICAL_DISCARD"):
        cnt = int(route_counts.get(r_name, 0))
        pct = 100.0 * cnt / total_merged
        lines.append(f"| `{r_name}` | {cnt} | {pct:.2f}% | {route_roles[r_name]} |")
    lines.append(f"| **Total** | **{total_merged}** | **100.00%** | Partition complète sans perte |")

    lines.extend(
        [
            "",
            "### Détail des 9 `pruning_bucket`",
            "",
            "| `hemisphere_route` | `pruning_bucket` | Effectif | Part (%) |",
            "| :--- | :--- | ---: | ---: |",
        ]
    )
    for _, r in bucket_counts.iterrows():
        cnt = int(r["size"])
        lines.append(f"| `{r['hemisphere_route']}` | `{r['pruning_bucket']}` | {cnt} | {100.0 * cnt / total_merged:.2f}% |")

    lines.extend(
        [
            "",
            f"### Effet de la priorité de routage sur les clés multi-emplois (`{len(route_changed)}` cas)",
            "",
            "Par rapport au tri initial MP1, la priorité `Z_PLUS_ACTIVE > Z_PLUS_SATELLITE > Z_MINUS_RESERVE > NON_LEXICAL_DISCARD` promeut 3 adverbes multi-emplois vers `Z_MINUS_RESERVE` (`Z_MINUS_CAUSAFFECT`) plutôt que `NON_LEXICAL_DISCARD` (`ExpAffect`), tout en conservant `types_all` et `routes_all` :",
            "",
        ]
    )
    for _, r in route_changed.iterrows():
        lines.append(
            f"- `{r['lemme_norm']}` (`{r['part_disc']}`, `{r['classe']}`) : `{r['naive_first_route']}` (`{r['naive_first_type']}`) → `{r['chosen_route']}` (`{r['chosen_type']}`)"
        )

    lines.extend(
        [
            "",
            f"### Candidats frontières axiologiques/épistémiques (`z_minus_value_candidate = True` : `{len(cand_df)}` entrées en `Z_PLUS_ACTIVE` sur 12 classes)",
            "",
            "Ces entrées sont marquées pour arbitrage humain explicite en MP3 (maintien en $Z_+$ vs bascule vers la réserve $-Z$) :",
            "",
            "| Classe DIMA (`classe`) | `pruning_bucket` | Effectif | Exemples de lemmes |",
            "| :--- | :--- | ---: | :--- |",
        ]
    )
    for _, r in cand_summary.iterrows():
        lines.append(f"| `{r['classe']}` | `{r['pruning_bucket']}` | {int(r['effectif'])} | `{r['exemples']}` |")

    # Résumé des 109 classes & ANTONYMIE
    n_no_ant = int((df_classes_summary["antonymie_family"] == "").sum())
    ant_families = sorted({a for a in df_classes_summary["antonymie_family"] if a})
    lines.extend(
        [
            "",
            "---",
            "",
            "## 5. Synthèse des 109 classes DIMA et familles `ANTONYMIE`",
            "",
            f"- **Nombre total de classes :** `{len(df_classes_summary)}` (`{int((df_classes_summary['categ'] == 'I').sum())}` en Catégorie I, `{int((df_classes_summary['categ'] == 'II').sum())}` en Catégorie II)",
            f"- **Libellés distincts de familles `ANTONYMIE` (non vides) :** `{len(ant_families)}` (dont 2 libellés proches dans `Nostalgie` : `Nostalgie de qqc / Regretter qq || Nostalgie de qqc / Regretter qqc ou qq`)",
            f"- **Classes sans famille `ANTONYMIE` renseignée :** `{n_no_ant}` (`Compassion`, `Jalousie envie`, `Jalousie sexuelle`, `Peur`, `Peur panique`, `Peur phobie`, `Sentiment`, `Sentiment classifieur`, `Z Classifieurs`).",
            "",
            "---",
            "",
            "## 6. Ingestion FANCat & NRC-VAD v2.1",
            "",
            "### FANCat (`FANCatdatabaseRevisee.xlsx`, onglet `FANCat All`)",
            f"- **Lignes ingérées :** `{len(df_fancat)}` mots français uniques (après saut de la ligne d'en-tête secondaire `Mean/SD`)",
            f"- **Colonnes :** `{len(df_fancat.columns)}` (`27` colonnes canoniques renommées + `word_fr_norm`, `word_en_norm`)",
            f"- **Nettoyage appliqué :** `{fancat_stats['n_fr_whitespace_trimmed']}` espaces de fin supprimés sur `word_fr`, `{fancat_stats['n_en_whitespace_trimmed']}` sur `word_en`, `{fancat_stats['n_fr_upper_normalized']}` normalisation de casse (`père-Noël` -> `père-noël`) ; `0` valeur manquante.",
            f"- **Plages observées :** `valence_fan_mean` ∈ `[{df_fancat['valence_fan_mean'].min():.2f}, {df_fancat['valence_fan_mean'].max():.2f}]`, `arousal_fan_mean` ∈ `[{df_fancat['arousal_fan_mean'].min():.2f}, {df_fancat['arousal_fan_mean'].max():.2f}]`, `fancat_n_ratings` ∈ `[{int(df_fancat['fancat_n_ratings'].min())}, {int(df_fancat['fancat_n_ratings'].max())}]`.",
            "",
            "### NRC-VAD v2.1 (`NRC-VAD-Lexicon-v2.1.txt`)",
            f"- **Termes ingérés :** `{len(df_nrc)}` (`{int((~df_nrc['is_mwe']).sum())}` unigrammes, `{int(df_nrc['is_mwe'].sum())}` expressions multi-mots ; lecture `keep_default_na=False`)",
            f"- **Plages observées :** `valence` ∈ `[{df_nrc['valence'].min():.3f}, {df_nrc['valence'].max():.3f}]`, `arousal` ∈ `[{df_nrc['arousal'].min():.3f}, {df_nrc['arousal'].max():.3f}]`, `dominance` ∈ `[{df_nrc['dominance'].min():.3f}, {df_nrc['dominance'].max():.3f}]`.",
            "",
        ]
    )

    # Pré-diagnostic recouvrement pour MP2
    dima_lemmes = set(df_dima_merged["lemme_norm"])
    fan_fr = set(df_fancat["word_fr_norm"])
    fan_en = set(df_fancat["word_en_norm"])
    nrc_terms = set(df_nrc["term_norm"])

    ov_t1 = len(set(df_dima_merged.loc[df_dima_merged["tier"] == "TIER1_STATE", "lemme_norm"]) & fan_fr)
    ov_t2 = len(set(df_dima_merged.loc[df_dima_merged["tier"] == "TIER2_VERB_BEHAVIOR", "lemme_norm"]) & fan_fr)
    ov_ex = len(set(df_dima_merged.loc[df_dima_merged["tier"] == "EXCLUDED_CONTEXT", "lemme_norm"]) & fan_fr)

    lines.extend(
        [
            "---",
            "",
            "## 7. Pré-diagnostic de recouvrement inter-bases (préparation Micro-Passe 2)",
            "",
            f"- **DIMA ∩ FANCat (`lemme_norm == word_fr_norm`) :** `{len(dima_lemmes & fan_fr)}` lemmes distincts (sur `{len(dima_lemmes)}` lemmes uniques DIMA et `{len(fan_fr)}` mots FANCat) — dont `{ov_t1}` en `TIER1_STATE`, `{ov_t2}` en `TIER2_VERB_BEHAVIOR`, `{ov_ex}` en `EXCLUDED_CONTEXT`.",
            f"- **FANCat (glose anglaise) ∩ NRC-VAD (`word_en_norm == term_norm`) :** `{len(fan_en & nrc_terms)}` mots FANCat sur `{len(df_fancat)}` (`{100.0 * len(fan_en & nrc_terms) / len(df_fancat):.1f}%` ; attention : correspondance exacte brute avant lemmatisation / désambiguïsation des gloses).",
            "",
            "---",
            "",
            "## 8. Artefacts exportés (`data/processed/`)",
            "",
            "| Fichier | Taille (octets) | SHA-256 | Statut Git |",
            "| :--- | ---: | :--- | :--- |",
        ]
    )
    for rel_p, sz, digest in processed_artifacts:
        git_stat = "Local uniquement (ignoré par `.gitignore`)" if rel_p.endswith(".parquet") else "Suivi dans Git"
        lines.append(f"| `{rel_p}` | {sz:,} | `{digest}` | {git_stat} |")
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    print("[MP1] Démarrage de l'ingestion, gouvernance lexicale & routage Z+/Z- (CARTOGRAFFECT v3.0.0)...")
    raw_audits = compute_raw_hashes()
    for item in raw_audits:
        print(f"  [SHA-256] {item.rel_path} ({item.size_bytes} B) -> {item.sha256}")

    update_data_provenance(raw_audits)
    print("[MP1] DATA_PROVENANCE.md mis à jour (idempotent).")

    df_dima_raw, unnamed_cells, unnamed_counts = load_dima()
    df_dima_raw_norm, df_dima_merged, df_dup_audit = normalize_and_merge_dima(df_dima_raw)
    print(
        f"[MP1][DIMA] {len(df_dima_raw_norm)} lignes brutes -> {len(df_dima_merged)} entrées uniques | "
        f"tiers={df_dima_merged['tier'].value_counts().to_dict()} | "
        f"routes={df_dima_merged['hemisphere_route'].value_counts().to_dict()} | "
        f"z_minus_value_candidate={int(df_dima_merged['z_minus_value_candidate'].sum())}"
    )

    df_z_minus = (
        df_dima_merged[df_dima_merged["hemisphere_route"] == "Z_MINUS_RESERVE"]
        .copy()
        .reset_index(drop=True)
    )
    assert len(df_z_minus) == 1229, f"Effectif inattendu pour dima_z_minus_reserve : {len(df_z_minus)}"

    df_classes_summary = build_dima_classes_summary(df_dima_raw_norm, df_dima_merged)
    print(f"[MP1][DIMA CLASSES] {len(df_classes_summary)} classes résumées.")

    df_fancat, fancat_stats = load_fancat()
    print(
        f"[MP1][FANCat] {len(df_fancat)} mots chargés ({len(df_fancat.columns)} colonnes) | "
        f"espaces nettoyés={fancat_stats['n_fr_whitespace_trimmed']}"
    )

    df_nrc = load_nrc_vad()
    print(f"[MP1][NRC-VAD] {len(df_nrc)} termes chargés.")

    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)

    dima_out = PROCESSED_DIR / "dima_normalized.parquet"
    z_minus_out = PROCESSED_DIR / "dima_z_minus_reserve.parquet"
    fancat_out = PROCESSED_DIR / "fancat_clean.parquet"
    classes_out = PROCESSED_DIR / "dima_classes_summary.csv"
    audit_out = REPORTS_DIR / "mp1_ingestion_audit.md"

    df_dima_merged.to_parquet(dima_out, engine="pyarrow", index=False)
    df_z_minus.to_parquet(z_minus_out, engine="pyarrow", index=False)
    df_fancat.to_parquet(fancat_out, engine="pyarrow", index=False)
    df_classes_summary.to_csv(classes_out, index=False, encoding="utf-8")

    processed_artifacts = [
        ("data/processed/dima_normalized.parquet", dima_out.stat().st_size, sha256_file(dima_out)),
        ("data/processed/dima_z_minus_reserve.parquet", z_minus_out.stat().st_size, sha256_file(z_minus_out)),
        ("data/processed/fancat_clean.parquet", fancat_out.stat().st_size, sha256_file(fancat_out)),
        ("data/processed/dima_classes_summary.csv", classes_out.stat().st_size, sha256_file(classes_out)),
    ]

    report_md = build_audit_report(
        raw_audits=raw_audits,
        unnamed_non_null_counts=unnamed_counts,
        unnamed_cells=unnamed_cells,
        df_dima_raw_norm=df_dima_raw_norm,
        df_dima_merged=df_dima_merged,
        df_dup_audit=df_dup_audit,
        df_classes_summary=df_classes_summary,
        df_fancat=df_fancat,
        fancat_stats=fancat_stats,
        df_nrc=df_nrc,
        processed_artifacts=processed_artifacts,
    )
    audit_out.write_text(report_md, encoding="utf-8")
    print(
        "[MP1] Exports terminés : data/processed/{dima_normalized.parquet,"
        "dima_z_minus_reserve.parquet,fancat_clean.parquet,dima_classes_summary.csv} "
        "et reports/lexicon_v3/mp1_ingestion_audit.md"
    )


if __name__ == "__main__":
    main()
