# DATA_PROVENANCE — Traçabilité des Jeux de Données Tiers (Standard FAIR4RS — v3.0.0)

**Compendium :** CARTOGRAFFECT (`v3.0.0`) · **Licence de ce document :** `CC-BY-4.0` ([`LICENSE-CC-BY-4.0.md`](LICENSE-CC-BY-4.0.md))

Conformément aux principes **FAIR4RS** et au respect strict des licences tierces, **aucun jeu de données brut tiers non redistribuable n'est stocké ni suivi dans ce dépôt Git** (voir `.gitignore` et `scripts/check_consistency.py`). Les scripts exploratoires de [`extensions/lexicon/`](extensions/lexicon/) qui en dépendent adoptent un comportement dégradé propre (**`[SKIP]` explicite** sans crash) lorsque ces fichiers sont absents du disque local.

> [!NOTE]
> **Périmètre épistémique v3.0.0 :** Le cœur normatif Lean 4 (`Cartograffect/`, 8 modules normatifs, 148 théorèmes substantiels / 169 déclarations exportées), l'extension canonique `PredictiveEngineCanonical.lean` (16 + 5 = 21 déclarations) et le moteur Python exact (`python/cartograffect_predictive_engine.py`, 11 tests unitaires) **ne dépendent d'aucun jeu de données tiers externe**. Les trois jeux de données ci-dessous concernent exclusivement les scripts exploratoires historiques de Strate 1 (`extensions/lexicon/`, voir [`extensions/lexicon/ARCHIVE_V2_HYBRID_Y_WARNING.md`](extensions/lexicon/ARCHIVE_V2_HYBRID_Y_WARNING.md)).

---

## 1. Jeux de données tiers non redistribuables

<!-- BEGIN:MP1_SOURCES_TABLE -->
| Fichier local attendu (exclu de Git) | Jeu de données & référence canonique | URL source canonique | Licence d'origine | SHA-256 vérifié (local) |
| :--- | :--- | :--- | :--- | :--- |
| `data/raw/NRC-VAD-Lexicon-v2.1.txt` (`1,612,583` octets) | **NRC Valence, Arousal, and Dominance (NRC-VAD) Lexicon v2.1** (54 801 termes anglais, échelle `[-1, +1]`) — Mohammad, S. M. (2018), *Proceedings of ACL 2018*, pp. 174–184 ; Mohammad, S. M. (2025), *NRC VAD Lexicon v2: Norms for Valence, Arousal, and Dominance for over 55k English Terms*, `arXiv:2503.23547` | https://saifmohammad.com/WebPages/nrc-vad.html *(ACL 2018 : https://aclanthology.org/P18-1017/ ; v2 : https://arxiv.org/abs/2503.23547)* | **NRC Research License** (Conseil national de recherches du Canada — recherche académique non commerciale uniquement ; redistribution du fichier brut interdite) | `42c718817fc91d5c133581b24b0bb31d2b14a0b16edb19bc6ce6ab70343e5a45` |
| `data/raw/DIMA_GROUPE_1_v35-new.xlsx` (`147,198` octets) | **DIMA — Dictionnaire Informatisé des Mots d'Affect, Groupe 1 (Catégorie I : Émotions, v35)** — Le Pesant, D. (2023), *L'Expression des émotions et des sentiments en français* (coll. *Domaines linguistiques*, vol. 14), Paris : Classiques Garnier (ISBN 978-2-406-14592-9) ; MoDyCo (CNRS UMR 7114 / Université Paris Nanterre) | https://modyco.fr/ *(ressource académique distribuée par l'auteur / MoDyCo CNRS UMR 7114 ; ouvrage de référence : Classiques Garnier, 2023)* | **Droits d'auteur réservés / usage recherche académique** *(utilisation équitable aux fins de recherche, art. 29 LDA Canada ; redistribution des fichiers Excel bruts non autorisée)* | `4a8094961dcacc3f7c17d8a2ce99bbf883088bafc2a33dfaa907488a9e2510d0` |
| `data/raw/DIMA_GROUPE_2_v35-new.xlsx` (`207,614` octets) | **DIMA — Dictionnaire Informatisé des Mots d'Affect, Groupe 2 (Catégorie II : Sentiments, v35)** — Le Pesant, D. (2023), *L'Expression des émotions et des sentiments en français* (coll. *Domaines linguistiques*, vol. 14), Paris : Classiques Garnier (ISBN 978-2-406-14592-9) ; MoDyCo (CNRS UMR 7114 / Université Paris Nanterre) | https://modyco.fr/ *(ressource académique distribuée par l'auteur / MoDyCo CNRS UMR 7114 ; ouvrage de référence : Classiques Garnier, 2023)* | **Droits d'auteur réservés / usage recherche académique** *(utilisation équitable aux fins de recherche, art. 29 LDA Canada ; redistribution des fichiers Excel bruts non autorisée)* | `bb40b8374bb6ee29d73e2878a6436f4a54d280a4c8e76586309c532e66f265c3` |
| `data/raw/FANCatdatabaseRevisee.xlsx` (`545,252` octets) | **FAN / FANCat — French Affective Norms & French Affective Norms for ten emotional Categories** (1 031 mots français) — **FAN :** Monnier, C., & Syssau, A. (2014), *Behavior Research Methods*, 46(4), 1128–1137 ; **FANCat :** Syssau, A., Yakhloufi, A., Giudicelli, E., Monnier, C., & Anders, R. (2021), *Behavior Research Methods*, 53(1), 447–465 *(consignes adaptées de Ric, F., Alexopoulos, T., Muller, D., & Aubé, B., 2013, BRM, 45(2), 414–421)* | https://doi.org/10.3758/s13428-020-01450-z *(FAN : https://doi.org/10.3758/s13428-013-0431-1 ; protocole Ric et al. : https://doi.org/10.3758/s13428-012-0276-z)* | **Matériel supplémentaire de recherche académique** (*Behavior Research Methods* / Springer Nature ; usage scientifique avec citation obligatoire ; redistribution directe du fichier `.xlsx` exclue du dépôt) | `e73b150c64385e7daece6f299b945fd1f37dd6bccd8f6356e02244d71df6b7a6` |
<!-- END:MP1_SOURCES_TABLE -->
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

<!-- BEGIN:MP1_SHA_COMMANDS -->
Après téléchargement autorisé des fichiers tiers dans `data/raw/` (exclu du suivi Git via `.gitignore` / contrôle FAIR4RS), calculer localement leur empreinte SHA-256 :

**PowerShell (Windows) :**
```powershell
Get-FileHash -Algorithm SHA256 `
  data/raw/NRC-VAD-Lexicon-v2.1.txt, `
  data/raw/DIMA_GROUPE_1_v35-new.xlsx, `
  data/raw/DIMA_GROUPE_2_v35-new.xlsx, `
  data/raw/FANCatdatabaseRevisee.xlsx
```

**Linux / macOS :**
```bash
sha256sum \
  data/raw/NRC-VAD-Lexicon-v2.1.txt \
  data/raw/DIMA_GROUPE_1_v35-new.xlsx \
  data/raw/DIMA_GROUPE_2_v35-new.xlsx \
  data/raw/FANCatdatabaseRevisee.xlsx
```
<!-- END:MP1_SHA_COMMANDS -->

## 4. Comportement en l'absence des jeux de données tiers (`[SKIP]` explicite)

- `extensions/lexicon/02_prefilter_nrc.py` : en l'absence de `NRC-VAD-Lexicon-v2.1.txt`, affiche un message explicite `[SKIP]` renvoyant vers `DATA_PROVENANCE.md` et termine proprement (code de sortie `0`, sauf si `--require-raw` est explicitement demandé).
- `extensions/lexicon/dima_mapping.py` : `load_dima_tables()` et `load_fancat_table()` journalisent explicitement `[SKIP]` et retournent un `DataFrame` vide lorsque `DIMA_GROUPE_*.xlsx` ou `FANCatdatabaseRevisee.xlsx` sont absents.
- `extensions/lexicon/run_pipeline.py` : saute proprement l'étape 2 si `NRC-VAD-Lexicon-v2.1.txt` est absent et que `nrc_candidates_filtered.tsv` existe déjà ; les tests automatisés vérifient explicitement ce comportement `skip` sans échec.
