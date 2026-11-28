# Rapport d'Audit — Micro-Passe 1 : Ingestion & Gouvernance lexicale (CARTOGRAFFECT v3.0.0)

- **Date d'exécution :** `2026-11-28 14:35:07 UTC`
- **Script :** [`python/lexicon_pipeline/01_ingest_normalize.py`](../../python/lexicon_pipeline/01_ingest_normalize.py)
- **Périmètre Lean 4 :** `Cartograffect/` strictement en lecture seule (0 fichier modifié)
- **Gouvernance FAIR4RS :** [`DATA_PROVENANCE.md`](../../DATA_PROVENANCE.md) mis à jour de façon idempotente ; `data/raw/` et les dérivés FANCat restent exclus du suivi Git.

---

## 1. Sources brutes vérifiées (SHA-256)

| Fichier (`data/raw/`) | Taille (octets) | SHA-256 |
| :--- | ---: | :--- |
| `data/raw/NRC-VAD-Lexicon-v2.1.txt` | 1,612,583 | `42c718817fc91d5c133581b24b0bb31d2b14a0b16edb19bc6ce6ab70343e5a45` |
| `data/raw/DIMA_GROUPE_1_v35-new.xlsx` | 147,198 | `4a8094961dcacc3f7c17d8a2ce99bbf883088bafc2a33dfaa907488a9e2510d0` |
| `data/raw/DIMA_GROUPE_2_v35-new.xlsx` | 207,614 | `bb40b8374bb6ee29d73e2878a6436f4a54d280a4c8e76586309c532e66f265c3` |
| `data/raw/FANCatdatabaseRevisee.xlsx` | 545,252 | `e73b150c64385e7daece6f299b945fd1f37dd6bccd8f6356e02244d71df6b7a6` |

---

## 2. Audit des colonnes `Unnamed:*` dans `DIMA_GROUPE_2_v35-new.xlsx` (onglet `Sentiments`)

Les 7 colonnes excédentaires (`Unnamed: 24` à `Unnamed: 30`) présentes dans `DIMA_GROUPE_2_v35-new.xlsx` ont été inspectées avant suppression :

| Colonne | Cellules non nulles | Statut |
| :--- | ---: | :--- |
| `Unnamed: 24` | 0 | Vide — écartée |
| `Unnamed: 25` | 0 | Vide — écartée |
| `Unnamed: 26` | 1 | Journalisée puis écartée |
| `Unnamed: 27` | 0 | Vide — écartée |
| `Unnamed: 28` | 0 | Vide — écartée |
| `Unnamed: 29` | 1 | Journalisée puis écartée |
| `Unnamed: 30` | 1 | Journalisée puis écartée |

### Contenu exact des 3 cellules non nulles journalisées

| Colonne | Index DataFrame | Ligne Excel | Valeur exacte (`repr`) | Contexte DIMA (`LEMME`, `PART DISC`, `TYPE`, `CLASSE`, `CATEG`) |
| :--- | ---: | ---: | :--- | :--- |
| `Unnamed: 26` | 1104 | 1106 | `'CARCOMP=-'` | `(dans l'espoir, PREPCONJ, ExpAffect, Espoir, II)` |
| `Unnamed: 29` | 1104 | 1106 | `'EUPH=+'` | `(dans l'espoir, PREPCONJ, ExpAffect, Espoir, II)` |
| `Unnamed: 30` | 1104 | 1106 | `'CLASS=Espoir'` | `(dans l'espoir, PREPCONJ, ExpAffect, Espoir, II)` |

---

## 3. Normalisation et fusion DIMA 1 + DIMA 2

- **Lignes brutes chargées :** `3373` (`1 401` DIMA 1 Catégorie I + `1 972` DIMA 2 Catégorie II)
- **Entrées uniques après fusion sur `(lemme_norm, part_disc, classe, categ)` :** `3342`
- **Clés dupliquées consolidées :** `30` clés distinctes (61 lignes brutes fusionnées en 30 entrées ; **0 doublon inter-groupes** I/II)
- **Clés protégées par le tri prioritaire :** `8` / `30` clés où la ligne brute apparaissant en premier avait un emploi moins central (ex. `CausAffect`/`ObjAffect`) que la ligne `ExpAffect` retenue.

### Répartition par `tier` (sur les 3 342 entrées fusionnées)

| Tier | Effectif | Part (%) |
| :--- | ---: | ---: |
| `TIER1_STATE` | 1017 | 30.43% |
| `TIER2_VERB_BEHAVIOR` | 787 | 23.55% |
| `EXCLUDED_CONTEXT` | 1538 | 46.02% |

### Tableau croisé `part_disc × type → tier` (3 342 entrées fusionnées)

| `part_disc` | `type` | `tier` | `tier_reason` | Effectif |
| :--- | :--- | :--- | :--- | ---: |
| `VERB` | `CausAffect` | `EXCLUDED_CONTEXT` | `CausAffect` | 440 |
| `ADVERB` | `ExpAffect` | `EXCLUDED_CONTEXT` | `non_state_pos:ADVERB` | 248 |
| `ADJ` | `CausAffect` | `EXCLUDED_CONTEXT` | `CausAffect` | 211 |
| `ADJ` | `ObjAffect` | `EXCLUDED_CONTEXT` | `ObjAffect` | 140 |
| `VERB` | `ObjAffect` | `EXCLUDED_CONTEXT` | `ObjAffect` | 112 |
| `ADVPREPCONJ` | `ExpAffect` | `EXCLUDED_CONTEXT` | `non_state_pos:ADVPREPCONJ` | 98 |
| `ADVPREP` | `ExpAffect` | `EXCLUDED_CONTEXT` | `non_state_pos:ADVPREP` | 87 |
| `NOM` | `CausAffect` | `EXCLUDED_CONTEXT` | `CausAffect` | 70 |
| `NOM` | `ObjAffect` | `EXCLUDED_CONTEXT` | `ObjAffect` | 26 |
| `ADVERB` | `ObjAffect` | `EXCLUDED_CONTEXT` | `ObjAffect` | 21 |
| `ADVERB` | `CausAffect` | `EXCLUDED_CONTEXT` | `CausAffect` | 13 |
| `VERB` | `ParoleAffect` | `EXCLUDED_CONTEXT` | `ParoleAffect` | 13 |
| `NOM` | `ExpAffect` | `EXCLUDED_CONTEXT` | `classifier_class` | 11 |
| `PREP` | `ExpAffect` | `EXCLUDED_CONTEXT` | `non_state_pos:PREP` | 11 |
| `ADJRELAT` | `ExpAffect` | `EXCLUDED_CONTEXT` | `non_state_pos:ADJRELAT` | 9 |
| `PREP` | `CausAffect` | `EXCLUDED_CONTEXT` | `CausAffect` | 9 |
| `PREPCONJ` | `ExpAffect` | `EXCLUDED_CONTEXT` | `non_state_pos:PREPCONJ` | 7 |
| `NOM` | `ParoleAffect` | `EXCLUDED_CONTEXT` | `ParoleAffect` | 3 |
| `PREP` | `ObjAffect` | `EXCLUDED_CONTEXT` | `ObjAffect` | 3 |
| `ADV` | `ExpAffect` | `EXCLUDED_CONTEXT` | `non_state_pos:ADV` | 2 |
| `NOM` | `CaractAffect` | `EXCLUDED_CONTEXT` | `classifier_class` | 2 |
| `NOM` | `ComportAffect` | `EXCLUDED_CONTEXT` | `classifier_class` | 2 |
| `NOM` | `ExpAffect` | `TIER1_STATE` | `NOM+ExpAffect` | 512 |
| `ADJ` | `ExpAffect` | `TIER1_STATE` | `ADJ+ExpAffect` | 316 |
| `NOM` | `HumAffect` | `TIER1_STATE` | `NOM+HumAffect` | 138 |
| `ADJ` | `CaractAffect` | `TIER1_STATE` | `ADJ+CaractAffect` | 38 |
| `NOM` | `CaractAffect` | `TIER1_STATE` | `NOM+CaractAffect` | 13 |
| `VERB` | `ExpAffect` | `TIER2_VERB_BEHAVIOR` | `VERB+ExpAffect` | 670 |
| `VERB` | `ComportAffect` | `TIER2_VERB_BEHAVIOR` | `VERB+ComportAffect` | 38 |
| `NOM` | `ComportAffect` | `TIER2_VERB_BEHAVIOR` | `NOM+ComportAffect` | 25 |
| `ADJ` | `ComportAffect` | `TIER2_VERB_BEHAVIOR` | `ADJ+ComportAffect` | 24 |
| `ADVERB` | `ComportAffect` | `TIER2_VERB_BEHAVIOR` | `ADVERB+ComportAffect` | 16 |
| `VERB` | `CaractAffect` | `TIER2_VERB_BEHAVIOR` | `VERB+CaractAffect` | 14 |

### Cas frontières signalés pour validation humaine

- **Classifieurs exclus (`EXCLUDED_CONTEXT`, `classifier_class`) :** `15` entrées (`Z Classifieurs` : 12, `Sentiment classifieur` : 3) — écartées explicitement conformément au cahier des charges.
- **`ADVERB + ComportAffect` en `TIER2_VERB_BEHAVIOR` :** `16` entrées (ex. *comme un fauve en cage*, *avec rancune* / *acrimonieusement*) — incluses via la clause `OU TYPE == 'ComportAffect'`.
- **`ParoleAffect` en `EXCLUDED_CONTEXT` :** `16` entrées (ex. *gueuler*, *pester*, *vitupérer*) — exclues car ne relevant pas de `ExpAffect/HumAffect/CaractAffect/ComportAffect`.
- **`ADJRELAT` en `EXCLUDED_CONTEXT` :** `9` entrées (adjectifs relationnels *affectif*, *émotionnel*, *amoureux*, *phobique*, etc.) — exclues car `PART DISC == 'ADJRELAT'` hors `{NOM, ADJ}`.

### Détail des 30 clés multi-emplois consolidées

| `lemme_norm` | `part_disc` | `classe` | `categ` | Lignes | Types bruts (ordre fichier) | Retenu (`tier` / `type`) | Sauvé par tri prioritaire |
| :--- | :--- | :--- | :--- | ---: | :--- | :--- | :---: |
| `admirer` | `VERB` | `Admiration` | `II` | 3 | `ExpAffect | ExpAffect | ExpAffect` | `TIER2_VERB_BEHAVIOR` / `ExpAffect` | non |
| `aimer` | `VERB` | `Goût` | `II` | 2 | `ExpAffect | ExpAffect` | `TIER2_VERB_BEHAVIOR` / `ExpAffect` | non |
| `amoureux` | `NOM` | `Amour` | `II` | 2 | `HumAffect | HumAffect` | `TIER1_STATE` / `HumAffect` | non |
| `apitoyer` | `VERB` | `Compassion` | `II` | 2 | `ObjAffect | ExpAffect` | `TIER2_VERB_BEHAVIOR` / `ExpAffect` | OUI |
| `avoir confiance` | `VERB` | `Confiance` | `II` | 2 | `ExpAffect | ExpAffect` | `TIER2_VERB_BEHAVIOR` / `ExpAffect` | non |
| `bien dans sa peau` | `ADJ` | `Combler Bonheur` | `I` | 2 | `ExpAffect | ExpAffect` | `TIER1_STATE` / `ExpAffect` | non |
| `croire` | `VERB` | `Croyance` | `II` | 2 | `ExpAffect | ExpAffect` | `TIER2_VERB_BEHAVIOR` / `ExpAffect` | non |
| `enrager` | `VERB` | `Colère` | `II` | 2 | `CausAffect | ExpAffect` | `TIER2_VERB_BEHAVIOR` / `ExpAffect` | OUI |
| `enthousiasmer` | `VERB` | `Intéresser_A` | `II` | 2 | `CausAffect | ObjAffect` | `EXCLUDED_CONTEXT` / `CausAffect` | non |
| `heureusement` | `ADVERB` | `Combler Bonheur` | `I` | 2 | `ExpAffect | CausAffect` | `EXCLUDED_CONTEXT` / `CausAffect` | OUI |
| `heureux` | `ADJ` | `Combler Bonheur` | `I` | 2 | `ExpAffect | CausAffect` | `TIER1_STATE` / `ExpAffect` | non |
| `honteux` | `ADJ` | `Honte` | `II` | 2 | `ObjAffect | ExpAffect` | `TIER1_STATE` / `ExpAffect` | OUI |
| `intéresser` | `VERB` | `Intéresser_A` | `II` | 2 | `CausAffect | ObjAffect` | `EXCLUDED_CONTEXT` / `CausAffect` | non |
| `jeter le doute` | `VERB` | `Doute` | `II` | 2 | `CausAffect | CausAffect` | `EXCLUDED_CONTEXT` / `CausAffect` | non |
| `jouir` | `VERB` | `Jouissance` | `I` | 2 | `ExpAffect | ExpAffect` | `TIER2_VERB_BEHAVIOR` / `ExpAffect` | non |
| `lamenter` | `VERB` | `Déplorer` | `II` | 2 | `ComportAffect | ComportAffect` | `TIER2_VERB_BEHAVIOR` / `ComportAffect` | non |
| `malheureusement` | `ADVERB` | `Décevoir Malheur` | `I` | 2 | `ExpAffect | CausAffect` | `EXCLUDED_CONTEXT` / `CausAffect` | OUI |
| `malheureux` | `ADJ` | `Décevoir Malheur` | `I` | 2 | `ExpAffect | CausAffect` | `TIER1_STATE` / `ExpAffect` | non |
| `mépriser` | `VERB` | `Mépris` | `II` | 2 | `ExpAffect | ExpAffect` | `TIER2_VERB_BEHAVIOR` / `ExpAffect` | non |
| `panique` | `NOM` | `Peur panique` | `II` | 2 | `ExpAffect | ExpAffect` | `TIER1_STATE` / `ExpAffect` | non |
| `par amour` | `ADVPREP` | `Amour` | `II` | 2 | `ExpAffect | ExpAffect` | `EXCLUDED_CONTEXT` / `ExpAffect` | non |
| `répugner` | `VERB` | `Déplaire_A` | `II` | 2 | `ObjAffect | ObjAffect` | `EXCLUDED_CONTEXT` / `ObjAffect` | non |
| `réservé` | `ADJ` | `Doute` | `II` | 2 | `ExpAffect | ExpAffect` | `TIER1_STATE` / `ExpAffect` | non |
| `sensible` | `ADJ` | `Intéresser_B` | `II` | 2 | `ObjAffect | ObjAffect` | `EXCLUDED_CONTEXT` / `ObjAffect` | non |
| `sûr` | `ADJ` | `Confiance_Sentiment de sécurité` | `II` | 2 | `ExpAffect | ObjAffect` | `TIER1_STATE` / `ExpAffect` | non |
| `tenir en haute estime` | `VERB` | `Estime` | `II` | 2 | `ExpAffect | ExpAffect` | `TIER2_VERB_BEHAVIOR` / `ExpAffect` | non |
| `triste` | `ADJ` | `Attrister` | `I` | 2 | `CausAffect | ExpAffect` | `TIER1_STATE` / `ExpAffect` | OUI |
| `tristement` | `ADVERB` | `Attrister` | `I` | 2 | `CausAffect | ExpAffect` | `EXCLUDED_CONTEXT` / `CausAffect` | non |
| `tristesse` | `NOM` | `Attrister` | `I` | 2 | `CausAffect | ExpAffect` | `TIER1_STATE` / `ExpAffect` | OUI |
| `tristounet` | `ADJ` | `Attrister` | `I` | 2 | `CausAffect | ExpAffect` | `TIER1_STATE` / `ExpAffect` | OUI |

---

## 4. Routage bi-hémisphérique $Z_+$ / Réserve $-Z$ (Micro-Passe 1b)

L'élagage réversible sans perte partitionne les `3 342` entrées DIMA en 4 routes et 9 buckets (`Z_PLUS_ACTIVE > Z_PLUS_SATELLITE > Z_MINUS_RESERVE > NON_LEXICAL_DISCARD`) :

### Répartition par `hemisphere_route`

| Route (`hemisphere_route`) | Effectif | Part (%) | Rôle architectural |
| :--- | ---: | ---: | :--- |
| `Z_PLUS_ACTIVE` | 966 | 28.90% | Cœur actif $Z_+$ (`NOM`/`ADJ` en `ExpAffect` ou `HumAffect`) |
| `Z_PLUS_SATELLITE` | 670 | 20.05% | Satellites verbaux $Z_+$ (`VERB` en `ExpAffect` ou `HumAffect`) |
| `Z_MINUS_RESERVE` | 1229 | 36.77% | Réserve structurée $-Z$ (exportée localement dans `data/processed/dima_z_minus_reserve.parquet`) |
| `NON_LEXICAL_DISCARD` | 477 | 14.27% | Écartés non lexicaux (`META_CLASSIFIER` + adverbes/prépositions/conjonctions/`ADJRELAT`) |
| **Total** | **3342** | **100.00%** | Partition complète sans perte |

### Détail des 9 `pruning_bucket`

| `hemisphere_route` | `pruning_bucket` | Effectif | Part (%) |
| :--- | :--- | ---: | ---: |
| `NON_LEXICAL_DISCARD` | `GRAMMATICAL_ADV_PREP` | 462 | 13.82% |
| `NON_LEXICAL_DISCARD` | `META_CLASSIFIER` | 15 | 0.45% |
| `Z_MINUS_RESERVE` | `Z_MINUS_CAUSAFFECT` | 743 | 22.23% |
| `Z_MINUS_RESERVE` | `Z_MINUS_OBJAFFECT` | 302 | 9.04% |
| `Z_MINUS_RESERVE` | `Z_MINUS_BEHAVIOR_SPEECH` | 119 | 3.56% |
| `Z_MINUS_RESERVE` | `Z_MINUS_TRAIT_CARACT` | 65 | 1.94% |
| `Z_PLUS_ACTIVE` | `Z_PLUS_EXPAFFECT` | 828 | 24.78% |
| `Z_PLUS_ACTIVE` | `Z_PLUS_HUMAFFECT` | 138 | 4.13% |
| `Z_PLUS_SATELLITE` | `Z_PLUS_VERB_EXP` | 670 | 20.05% |

### Effet de la priorité de routage sur les clés multi-emplois (`8` cas)

Par rapport au tri initial MP1, la priorité `Z_PLUS_ACTIVE > Z_PLUS_SATELLITE > Z_MINUS_RESERVE > NON_LEXICAL_DISCARD` promeut 3 adverbes multi-emplois vers `Z_MINUS_RESERVE` (`Z_MINUS_CAUSAFFECT`) plutôt que `NON_LEXICAL_DISCARD` (`ExpAffect`), tout en conservant `types_all` et `routes_all` :

- `apitoyer` (`VERB`, `Compassion`) : `Z_MINUS_RESERVE` (`ObjAffect`) → `Z_PLUS_SATELLITE` (`ExpAffect`)
- `enrager` (`VERB`, `Colère`) : `Z_MINUS_RESERVE` (`CausAffect`) → `Z_PLUS_SATELLITE` (`ExpAffect`)
- `heureusement` (`ADVERB`, `Combler Bonheur`) : `NON_LEXICAL_DISCARD` (`ExpAffect`) → `Z_MINUS_RESERVE` (`CausAffect`)
- `honteux` (`ADJ`, `Honte`) : `Z_MINUS_RESERVE` (`ObjAffect`) → `Z_PLUS_ACTIVE` (`ExpAffect`)
- `malheureusement` (`ADVERB`, `Décevoir Malheur`) : `NON_LEXICAL_DISCARD` (`ExpAffect`) → `Z_MINUS_RESERVE` (`CausAffect`)
- `triste` (`ADJ`, `Attrister`) : `Z_MINUS_RESERVE` (`CausAffect`) → `Z_PLUS_ACTIVE` (`ExpAffect`)
- `tristesse` (`NOM`, `Attrister`) : `Z_MINUS_RESERVE` (`CausAffect`) → `Z_PLUS_ACTIVE` (`ExpAffect`)
- `tristounet` (`ADJ`, `Attrister`) : `Z_MINUS_RESERVE` (`CausAffect`) → `Z_PLUS_ACTIVE` (`ExpAffect`)

### Candidats frontières axiologiques/épistémiques (`z_minus_value_candidate = True` : `46` entrées en `Z_PLUS_ACTIVE` sur 12 classes)

Ces entrées sont marquées pour arbitrage humain explicite en MP3 (maintien en $Z_+$ vs bascule vers la réserve $-Z$) :

| Classe DIMA (`classe`) | `pruning_bucket` | Effectif | Exemples de lemmes |
| :--- | :--- | ---: | :--- |
| `Bonne conscience` | `Z_PLUS_EXPAFFECT` | 4 | `bonne conscience, en paix avec sa conscience, en paix avec soi-même, en règle avec sa conscience` |
| `Croyance` | `Z_PLUS_EXPAFFECT` | 1 | `croyance` |
| `Croyance relig` | `Z_PLUS_EXPAFFECT` | 2 | `croyance religieuse, foi` |
| `Défiance_Non fiabilité` | `Z_PLUS_HUMAFFECT` | 1 | `suspect` |
| `Estime respect` | `Z_PLUS_EXPAFFECT` | 6 | `crainte, crainte révérencielle, respect, respectueux, révérence` |
| `Gratitude` | `Z_PLUS_EXPAFFECT` | 3 | `gratitude, reconnaissance, reconnaissant` |
| `Incrédulité` | `Z_PLUS_EXPAFFECT` | 2 | `incrédule, incrédulité` |
| `Incrédulité` | `Z_PLUS_HUMAFFECT` | 1 | `incrédule` |
| `Incrédulité relig` | `Z_PLUS_EXPAFFECT` | 2 | `incroyance, incroyant` |
| `Incrédulité relig` | `Z_PLUS_HUMAFFECT` | 2 | `incroyant, incrédule` |
| `Mauvaise conscience` | `Z_PLUS_EXPAFFECT` | 14 | `bourrelé de remords, contrit, contrition, mauvaise conscience, pris de remords` |
| `Mauvaise conscience` | `Z_PLUS_HUMAFFECT` | 2 | `pénitent, repenti` |
| `Mauvaise conscience scrupule` | `Z_PLUS_EXPAFFECT` | 2 | `scrupule, scrupule de conscience` |
| `Orgueil surestimation de soi` | `Z_PLUS_EXPAFFECT` | 1 | `surestimation de soi` |
| `Orgueil surestimation de soi` | `Z_PLUS_HUMAFFECT` | 2 | `fat, vaniteux` |
| `Pudeur` | `Z_PLUS_EXPAFFECT` | 1 | `pudeur` |

---

## 5. Synthèse des 109 classes DIMA et familles `ANTONYMIE`

- **Nombre total de classes :** `109` (`35` en Catégorie I, `74` en Catégorie II)
- **Libellés distincts de familles `ANTONYMIE` (non vides) :** `31` (dont 2 libellés proches dans `Nostalgie` : `Nostalgie de qqc / Regretter qq || Nostalgie de qqc / Regretter qqc ou qq`)
- **Classes sans famille `ANTONYMIE` renseignée :** `9` (`Compassion`, `Jalousie envie`, `Jalousie sexuelle`, `Peur`, `Peur panique`, `Peur phobie`, `Sentiment`, `Sentiment classifieur`, `Z Classifieurs`).

---

## 6. Ingestion FANCat & NRC-VAD v2.1

### FANCat (`FANCatdatabaseRevisee.xlsx`, onglet `FANCat All`)
- **Lignes ingérées :** `1031` mots français uniques (après saut de la ligne d'en-tête secondaire `Mean/SD`)
- **Colonnes :** `29` (`27` colonnes canoniques renommées + `word_fr_norm`, `word_en_norm`)
- **Nettoyage appliqué :** `210` espaces de fin supprimés sur `word_fr`, `0` sur `word_en`, `1` normalisation de casse (`père-Noël` -> `père-noël`) ; `0` valeur manquante.
- **Plages observées :** `valence_fan_mean` ∈ `[1.35, 8.58]`, `arousal_fan_mean` ∈ `[2.14, 7.86]`, `fancat_n_ratings` ∈ `[26, 84]`.

### NRC-VAD v2.1 (`NRC-VAD-Lexicon-v2.1.txt`)
- **Termes ingérés :** `54801` (`44728` unigrammes, `10073` expressions multi-mots ; lecture `keep_default_na=False`)
- **Plages observées :** `valence` ∈ `[-1.000, 1.000]`, `arousal` ∈ `[-1.000, 1.000]`, `dominance` ∈ `[-1.000, 1.000]`.

---

## 7. Pré-diagnostic de recouvrement inter-bases (préparation Micro-Passe 2)

- **DIMA ∩ FANCat (`lemme_norm == word_fr_norm`) :** `58` lemmes distincts (sur `3001` lemmes uniques DIMA et `1031` mots FANCat) — dont `48` en `TIER1_STATE`, `1` en `TIER2_VERB_BEHAVIOR`, `14` en `EXCLUDED_CONTEXT`.
- **FANCat (glose anglaise) ∩ NRC-VAD (`word_en_norm == term_norm`) :** `939` mots FANCat sur `1031` (`91.1%` ; attention : correspondance exacte brute avant lemmatisation / désambiguïsation des gloses).

---

## 8. Artefacts exportés (`data/processed/`)

| Fichier | Taille (octets) | SHA-256 | Statut Git |
| :--- | ---: | :--- | :--- |
| `data/processed/dima_normalized.parquet` | 210,756 | `dea009e2f67cd98898c6b4a12a2468ba617ae2aa2207f11e7bbaa78ced12a815` | Local uniquement (ignoré par `.gitignore`) |
| `data/processed/dima_z_minus_reserve.parquet` | 102,038 | `33d50b85b071d05e61dc2a05edb973ad4d7f09032a4f160b6fa2415fbb795a06` | Local uniquement (ignoré par `.gitignore`) |
| `data/processed/fancat_clean.parquet` | 100,173 | `39685b2f61d1b573533ca893f44f1f2f14e9d28b8d8ea87005eb24461c0bdeab` | Local uniquement (ignoré par `.gitignore`) |
| `data/processed/dima_classes_summary.csv` | 11,256 | `f63759ac514aec54708d87eecf3a4ed322672a9707f31f3641315f613bb48421` | Suivi dans Git |
