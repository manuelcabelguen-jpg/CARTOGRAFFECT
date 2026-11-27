# DATA_PROVENANCE — Traçabilité des Jeux de Données Tiers (Standard FAIR4RS — v3.0.0)

**Compendium :** CARTOGRAFFECT (`v3.0.0`) · **Licence de ce document :** `CC-BY-4.0` ([`LICENSE-CC-BY-4.0.md`](LICENSE-CC-BY-4.0.md))

Conformément aux principes **FAIR4RS** et au respect strict des licences tierces, **aucun jeu de données brut tiers non redistribuable n'est stocké ni suivi dans ce dépôt Git** (voir `.gitignore` et `scripts/check_consistency.py`). Les scripts exploratoires de [`extensions/lexicon/`](extensions/lexicon/) qui en dépendent adoptent un comportement dégradé propre (**`[SKIP]` explicite** sans crash) lorsque ces fichiers sont absents du disque local.

> [!NOTE]
> **Périmètre épistémique v3.0.0 :** Le cœur normatif Lean 4 (`Cartograffect/`, 8 modules normatifs, 148 théorèmes substantiels / 169 déclarations exportées), l'extension canonique `PredictiveEngineCanonical.lean` (16 + 5 = 21 déclarations) et le moteur Python exact (`python/cartograffect_predictive_engine.py`, 11 tests unitaires) **ne dépendent d'aucun jeu de données tiers externe**. Les trois jeux de données ci-dessous concernent exclusivement les scripts exploratoires historiques de Strate 1 (`extensions/lexicon/`, voir [`extensions/lexicon/ARCHIVE_V2_HYBRID_Y_WARNING.md`](extensions/lexicon/ARCHIVE_V2_HYBRID_Y_WARNING.md)).

---

## 1. Jeux de données tiers non redistribuables

| Fichier local attendu (exclu de Git) | Jeu de données & référence canonique | URL source canonique | Licence d'origine | SHA-256 attendu |
| :--- | :--- | :--- | :--- | :--- |
| `NRC-VAD-Lexicon-v2.1.txt` | **NRC Valence, Arousal, and Dominance (NRC-VAD) Lexicon v2.1** — Mohammad, S. M. (2018), *ACL 2018*, pp. 174–184 | https://saifmohammad.com/WebPages/nrc-vad.html *(publication : https://aclanthology.org/P18-1017/)* | **NRC Research License** (Conseil national de recherches du Canada — recherche académique non commerciale ; redistribution du fichier brut interdite) | Non vérifiable localement — fichier tiers absent |
| `DIMA_GROUPE_1_v35-new.xlsx` | **DIMA — Dictionnaire électronique des Mots d'Affect, Groupe 1 (Catégorie I)** — Le Pesant, D. (2023), MoDyCo (CNRS UMR 7114 / Université Paris Nanterre) | https://modyco.fr/ *(ressource académique distribuée par l'auteur / MoDyCo CNRS UMR 7114 ; ouvrage de référence : Classiques Garnier, 2023)* | **Droits d'auteur réservés / usage recherche académique** *(utilisation équitable aux fins de recherche, art. 29 LDA Canada ; redistribution des fichiers Excel bruts non autorisée)* | Non vérifiable localement — fichier tiers absent |
| `DIMA_GROUPE_2_v35-new.xlsx` | **DIMA — Dictionnaire électronique des Mots d'Affect, Groupe 2 (Catégorie II)** — Le Pesant, D. (2023), MoDyCo (CNRS UMR 7114 / Université Paris Nanterre) | https://modyco.fr/ *(ressource académique distribuée par l'auteur / MoDyCo CNRS UMR 7114 ; ouvrage de référence : Classiques Garnier, 2023)* | **Droits d'auteur réservés / usage recherche académique** *(utilisation équitable aux fins de recherche, art. 29 LDA Canada ; redistribution des fichiers Excel bruts non autorisée)* | Non vérifiable localement — fichier tiers absent |
| `FANCatdatabaseRevisee.xlsx` | **FANCat — French Affective Norms for ten discrete emotion Categories** — Ric, F., Alexopoulos, T., Muller, D., & Aubé, B. (2013), *Behavior Research Methods*, 45(2), 414–421 | https://doi.org/10.3758/s13428-012-0276-z *(matériel supplémentaire de l'article sur SpringerLink / archive des auteurs)* | **Matériel supplémentaire de recherche académique** (*Behavior Research Methods* / Springer ; redistribution directe du fichier `.xlsx` non incluse) | Non vérifiable localement — fichier tiers absent |

---

## 2. Ressources ouvertes et tables de référence publiées utilisées en Strate 1

| Ressource | Référence & URL source canonique | Licence d'origine | Statut dans le dépôt |
| :--- | :--- | :--- | :--- |
| **Roues des émotions (Scherer et al., 2013)** | Scherer, K. R., Shuman, V., Fontaine, J. R. J., & Soriano, C. (2013), in *Components of Emotional Meaning* (OUP, ch. 18, pp. 289–305) — https://doi.org/10.1093/acprof:oso/9780199592746.001.0001 | Extraction des coordonnées publiées de référence (usage scientifique) | Table normalisée [`extensions/lexicon/data/emotion_wheels/scherer2013_wheels.tsv`](extensions/lexicon/data/emotion_wheels/scherer2013_wheels.tsv) |
| **Lexique 3.83** | New, B., Pallier, C., Brysbaert, M., & Ferrand, L. (2004) — http://www.lexique.org | `CC-BY-SA-4.0` | Non redistribué brut (métadonnées dérivées documentées dans [`extensions/lexicon/THIRD_PARTY_NOTICES.md`](extensions/lexicon/THIRD_PARTY_NOTICES.md)) |
| **GLAWI (CLLE-ERSS, CNRS UMR 5263)** | Sajous, F., & Hathout, N. (2015) — http://redac.univ-tlse2.fr/lexicons/glawi.html | `CC-BY-SA-3.0` / `CC-BY-SA-4.0` | Non redistribué brut |
| **Morphalou 3.1 / TLFi (CNRS / ATILF)** | CNRS / ATILF UMR 7118 — https://www.ortolang.fr/market/lexicons/morphalou | Licence Ouverte Etalab / `CC-BY-SA` | Non redistribué brut |

---

## 3. Procédure de vérification locale SHA-256

Après téléchargement autorisé des fichiers tiers dans `extensions/lexicon/` (ou `extensions/lexicon/data/raw_third_party/`, ignoré par Git), calculer localement leur empreinte SHA-256 :

**PowerShell (Windows) :**
```powershell
Get-FileHash -Algorithm SHA256 `
  extensions/lexicon/NRC-VAD-Lexicon-v2.1.txt, `
  extensions/lexicon/DIMA_GROUPE_1_v35-new.xlsx, `
  extensions/lexicon/DIMA_GROUPE_2_v35-new.xlsx, `
  extensions/lexicon/FANCatdatabaseRevisee.xlsx
```

**Linux / macOS :**
```bash
sha256sum \
  extensions/lexicon/NRC-VAD-Lexicon-v2.1.txt \
  extensions/lexicon/DIMA_GROUPE_1_v35-new.xlsx \
  extensions/lexicon/DIMA_GROUPE_2_v35-new.xlsx \
  extensions/lexicon/FANCatdatabaseRevisee.xlsx
```

## 4. Comportement en l'absence des jeux de données tiers (`[SKIP]` explicite)

- `extensions/lexicon/02_prefilter_nrc.py` : en l'absence de `NRC-VAD-Lexicon-v2.1.txt`, affiche un message explicite `[SKIP]` renvoyant vers `DATA_PROVENANCE.md` et termine proprement (code de sortie `0`, sauf si `--require-raw` est explicitement demandé).
- `extensions/lexicon/dima_mapping.py` : `load_dima_tables()` et `load_fancat_table()` journalisent explicitement `[SKIP]` et retournent un `DataFrame` vide lorsque `DIMA_GROUPE_*.xlsx` ou `FANCatdatabaseRevisee.xlsx` sont absents.
- `extensions/lexicon/run_pipeline.py` : saute proprement l'étape 2 si `NRC-VAD-Lexicon-v2.1.txt` est absent et que `nrc_candidates_filtered.tsv` existe déjà ; les tests automatisés vérifient explicitement ce comportement `skip` sans échec.
