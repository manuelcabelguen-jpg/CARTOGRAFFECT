# Rapport d'Audit — Micro-Passe 2 : Calibrage psychométrique FANCat ↔ NRC-VAD v2.1 & Pont FR→EN sur $Z_+$ (CARTOGRAFFECT v3.0.0)

- **Script :** [`python/lexicon_pipeline/02_bridge_psychometrics.py`](../../python/lexicon_pipeline/02_bridge_psychometrics.py) *(strictement idempotent, zéro appel réseau)*
- **Périmètre Lean 4 :** `Cartograffect/` strictement en lecture seule (0 fichier modifié)
- **Partition MP1c :** `549` `Z_PLUS_ACTIVE` (`369 NOM` + `180 ADJ`, unigrammes standard `ExpAffect`) + `945` `Z_PLUS_SATELLITE` = **`1,494` entrées traitées** ; `1,367` `Z_MINUS_RESERVE` (dont `138` `Z_MINUS_HUMAN_ROLE`) et `481` `NON_LEXICAL_DISCARD` laissées intactes
- **Table d'overrides :** [`data/config/fr_en_bridge_overrides.csv`](../../data/config/fr_en_bridge_overrides.csv) (`84` règles, SHA-256 `3b329617dea56a19...` ; priorité contextuelle `(lemme_norm, classe)` avant `fancat_direct`)

### Empreintes des entrées consommées (lecture seule)

| Fichier | SHA-256 |
| :--- | :--- |
| `data/processed/dima_normalized.parquet` | `0ac6a8b34e9f9b0e874cda8fe805760d45076c0b273c1a819e189977f39dfda3` |
| `data/processed/fancat_clean.parquet` | `39685b2f61d1b573533ca893f44f1f2f14e9d28b8d8ea87005eb24461c0bdeab` |
| `data/raw/NRC-VAD-Lexicon-v2.1.txt` | `42c718817fc91d5c133581b24b0bb31d2b14a0b16edb19bc6ce6ab70343e5a45` |

---

## 1. Calibrage empirique FANCat ↔ NRC-VAD v2.1

Appariement exact sur la glose anglaise normalisée (`word_en` en minuscules/strip == `term_norm`) : **`976` paires** sur `1 031` mots FANCat (`55` gloses sans correspondance exacte NRC-VAD, ex. expressions multi-mots ou variantes orthographiques).

| Axe | Paires ($N$) | Pearson $r$ | $p$-valeur ($r$) | Spearman $\rho$ | $p$-valeur ($\rho$) | $R^2$ | Pente $\hat{b}$ (± SE) | Ordonnée $\hat{a}$ (± SE) | RMSE |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| **Valence** (`valence_fan_mean` → `valence`) | 976 | `0.787191` | `1.12e-206` | `0.745600` | `7.06e-174` | `0.6197` | `0.231360` (± `0.005808`) | `-1.125610` (± `0.032589`) | `0.2545` |
| **Arousal** (`arousal_fan_mean` → `arousal`) | 976 | `0.592399` | `1.65e-93` | `0.548929` | `6.76e-78` | `0.3509` | `0.207195` (± `0.009029`) | `-1.058466` (± `0.039861`) | `0.3027` |

### Équations de transfert appliquées à FANCat (échelle 1–9 → $[-1, +1]$)

- **Valence harmonisée :** $V_{\text{harm}} = -1.125610 + 0.231360 \cdot V_{\text{FAN}}$ — plage projetée sur les 1 031 mots FANCat : `[-0.8133, 0.8595]` (`0` valeurs écrêtées).
- **Arousal harmonisé :** $A_{\text{harm}} = -1.058466 + 0.207195 \cdot A_{\text{FAN}}$ — plage projetée sur les 1 031 mots FANCat : `[-0.6151, 0.5701]` (`0` valeurs écrêtées).

---

## 2. Dominance orthogonale résidualisée ($D_{\perp}$)

Régression MCO estimée sur l'intégralité des **`54,801`** entrées de `NRC-VAD-Lexicon-v2.1.txt` :

$$D = \hat{\alpha} + \hat{\beta} V + \varepsilon, \qquad D_{\perp} = \frac{D - (\hat{\alpha} + \hat{\beta} V)}{\max|\varepsilon|}$$

| Paramètre | Valeur observée | Contrôle |
| :--- | ---: | :--- |
| $\hat{\alpha}$ (ordonnée à l'origine) | `0.045167` | Repère $\approx 0.0452$ |
| $\hat{\beta}$ (pente sur $V$) | `0.411128` | Repère $\approx 0.4111$ |
| $r(V, D)$ avant résidualisation | `0.473011` ($R^2 = 0.2237$) | Repère $\approx 0.4730$ |
| $\max|\varepsilon|$ | `1.365961` | Normalisateur $[-1, +1]$ |
| Plage de $D_{\perp}$ | `[-0.965906, +1.000000]` | Bornes exactes $[-1, +1]$ |
| $r(V, D_{\perp})$ après résidualisation | `-5.516e-16` | **PASS** ($|r| < 10^{-6}$) |

---

## 3. Couverture par `hemisphere_route` et par `metric_provenance` (1,494 entrées $Z_+$)

Distinction explicite entre le noyau actif épuré **`Z_PLUS_ACTIVE`** (`549` unigrammes standard `ExpAffect` : `369 NOM`, `180 ADJ`) et les satellites **`Z_PLUS_SATELLITE`** (`945` entrées : verbes, locutions MWE/métaphores, registres `fam` et `vx`/`allemand`/`jur`) :

| `metric_provenance` | `Z_PLUS_ACTIVE` ($n$) | `Z_PLUS_ACTIVE` (%) | `Z_PLUS_SATELLITE` ($n$) | `Z_PLUS_SATELLITE` (%) | Total $Z_+$ ($n$) | Total $Z_+$ (%) |
| :--- | ---: | ---: | ---: | ---: | ---: | ---: |
| `fancat_direct` | 54 | 9.84% | 7 | 0.74% | 61 | 4.08% |
| `nrc_override` | 61 | 11.11% | 9 | 0.95% | 70 | 4.69% |
| `nrc_bridge_auto` | 414 | 75.41% | 483 | 51.11% | 897 | 60.04% |
| `subclass_centroid` | 19 | 3.46% | 196 | 20.74% | 215 | 14.39% |
| `class_centroid` | 1 | 0.18% | 250 | 26.46% | 251 | 16.80% |
| **Sous-total ancres directes** (`fancat_direct + nrc_override + nrc_bridge_auto`) | **529** | **96.36%** | **499** | **52.80%** | **1028** | **68.81%** |
| **Sous-total imputation hiérarchique** (`subclass_centroid + class_centroid`) | **20** | **3.64%** | **446** | **47.20%** | **466** | **31.19%** |
| **Total partition $Z_+$** | **549** | **100.00%** | **945** | **100.00%** | **1494** | **100.00%** |

- **Classes sans aucune ancre directe :** `0` sur `92` classes $Z_+$ (`76` `Z_PLUS_ACTIVE` + `16` classes exclusivement `Z_PLUS_SATELLITE` toutes ancrées directement).
- **Détail `nrc_bridge_auto` (`897` entrées) :** `770` dictionnaire statique FR→EN, `103` cognates directs sans accents (`NOM`/`ADJ`), `24` cognates suffixaux contrôlés.
- **Périmètre non modifié (`dima_normalized.parquet`) :** `Z_MINUS_RESERVE` = `1367` entrées (dont `138` `Z_MINUS_HUMAN_ROLE`) ; `NON_LEXICAL_DISCARD` = `481` entrées.

### Détail par panier `pruning_bucket`

| `hemisphere_route` | `pruning_bucket` | Total ($n$) | `fancat_direct` | `nrc_override` | `nrc_bridge_auto` | `subclass_centroid` | `class_centroid` | Couv. directe (%) |
| :--- | :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `Z_PLUS_ACTIVE` | `Z_PLUS_EXPAFFECT` | 549 | 54 | 61 | 414 | 19 | 1 | 96.4% |
| `Z_PLUS_SATELLITE` | `Z_PLUS_ARCHAIC_FOREIGN` | 19 | 1 | 3 | 14 | 0 | 1 | 94.7% |
| `Z_PLUS_SATELLITE` | `Z_PLUS_COLLOQUIAL` | 47 | 0 | 1 | 42 | 3 | 1 | 91.5% |
| `Z_PLUS_SATELLITE` | `Z_PLUS_IDIOM_MWE` | 209 | 6 | 2 | 200 | 1 | 0 | 99.5% |
| `Z_PLUS_SATELLITE` | `Z_PLUS_VERB_EXP` | 670 | 0 | 3 | 227 | 192 | 248 | 34.3% |

---

## 4. Classes de `Z_PLUS_ACTIVE` (sur les 76 présentes) à couverture directe < 30 %

- **Nombre de classes `Z_PLUS_ACTIVE` analysées :** `76` (couverture directe médiane par classe : `100.0%`, moyenne : `98.9%`).
- **Classes sous le seuil de 30 % de couverture directe :** **`0`** / `76`.

> **Aucune classe `Z_PLUS_ACTIVE` n'a une couverture directe inférieure à 30 %.**

### Rappel de couverture des 9 classes comportant `z_minus_value_candidate == True` (`24` entrées)

| Classe DIMA (`classe`) | Effectif `Z_PLUS_ACTIVE` | `n_z_minus_value_candidate` | Direct ($n$) | Couv. directe (%) |
| :--- | ---: | ---: | ---: | ---: |
| `Croyance` | 1 | 1 | 1 | 100.0% |
| `Croyance relig` | 1 | 1 | 1 | 100.0% |
| `Estime respect` | 4 | 4 | 4 | 100.0% |
| `Gratitude` | 3 | 3 | 3 | 100.0% |
| `Incrédulité` | 2 | 2 | 2 | 100.0% |
| `Incrédulité relig` | 2 | 2 | 2 | 100.0% |
| `Mauvaise conscience` | 9 | 9 | 9 | 100.0% |
| `Mauvaise conscience scrupule` | 1 | 1 | 1 | 100.0% |
| `Pudeur` | 1 | 1 | 1 | 100.0% |

---

## 5. Panel témoin des 14 jalons psychométriques

Pour les 3 lemmes polysémiques/bi-POS présents dans le panel (`rage` en `Colère`/`Désir`, `hostilité` en `Inimitié`/`Aversion`, `calme` en `NOM`/`ADJ` dans `Apaiser`), la ligne canonique `NOM` de la classe affective primaire est affichée ci-dessous (les entrées sœurs portent exactement le même vecteur psychométrique).

| Jalon (`lemme_norm`) | `part_disc` | Classe primaire | $V_{\text{harm}}$ | $A_{\text{harm}}$ | $D_{\text{raw}}$ | $D_{\perp}$ | `en_matched_term` | `metric_provenance` |
| :--- | :---: | :--- | ---: | ---: | ---: | ---: | :--- | :--- |
| `colère` | `NOM` | `Colère` | `-0.4824` | `+0.2427` | `+0.3140` | `+0.3973` | `anger` | `fancat_direct` |
| `rage` | `NOM` | `Colère` | `-0.3691` | `+0.4251` | `+0.3160` | `+0.4499` | `rage` | `fancat_direct` |
| `frustration` | `NOM` | `Décevoir` | `-0.8800` | `+0.4600` | `-0.4400` | `-0.0903` | `frustration` | `nrc_override` |
| `hostilité` | `NOM` | `Inimitié` | `-0.7560` | `+0.5500` | `-0.0700` | `+0.1432` | `hostility` | `nrc_override` |
| `peur` | `NOM` | `Peur` | `-0.4246` | `+0.2738` | `-0.4140` | `-0.0791` | `fear` | `fancat_direct` |
| `angoisse` | `NOM` | `Inquiéter` | `-0.6940` | `+0.5840` | `-0.4700` | `-0.1683` | `anguish` | `nrc_override` |
| `terreur` | `NOM` | `Inquiéter Effrayer` | `-0.8620` | `+0.8040` | `-0.1700` | `+0.1019` | `terror` | `nrc_override` |
| `tristesse` | `NOM` | `Attrister` | `-0.6444` | `+0.0625` | `-0.6720` | `-0.2553` | `sadness` | `fancat_direct` |
| `désespoir` | `NOM` | `Mauvais moral` | `-0.7700` | `+0.5880` | `-0.5100` | `-0.1747` | `despair` | `nrc_override` |
| `honte` | `NOM` | `Honte` | `-0.8800` | `+0.3400` | `-0.6900` | `-0.2733` | `shame` | `nrc_override` |
| `calme` | `NOM` | `Apaiser` | `+0.5679` | `-0.3872` | `-0.3330` | `-0.4776` | `quietness` | `fancat_direct` |
| `sérénité` | `NOM` | `Rassurer` | `+0.8000` | `-0.8780` | `+0.1140` | `-0.1904` | `serenity` | `nrc_override` |
| `joie` | `NOM` | `Réjouir` | `+0.8595` | `+0.4955` | `+0.5880` | `+0.1085` | `joy` | `fancat_direct` |
| `fierté` | `NOM` | `Orgueil` | `+0.4580` | `+0.2680` | `+0.6960` | `+0.3386` | `pride` | `nrc_override` |

> **Observation psychométrique sur $D_{\perp}$ :** la résidualisation retire la corrélation structurelle de Valence ($r(V, D) = 0.4730$ dans NRC-VAD) et isole l'agentivité / contrôle pur. Ainsi, `hostilité` passe de $D_{\text{raw}} = -0.0700$ (contaminé par sa valence négative $-0.756$) à $D_{\perp} = +0.1432$ (cohérent avec `colère` $+0.3973$ et `rage` $+0.4499$), tandis que `calme` ($-0.4776$) et `sérénité` ($-0.1904$) se distinguent nettement de `fierté` ($+0.3386$) et `joie` ($+0.1085$).

---

## 6. Points d'audit qualitatif pour relecture humaine (contrôle post-MP1c)

### 6.1 Contrôle zéro homographe FANCat non pertinent dans `Z_PLUS_ACTIVE`

- **Gloses FANCat interdites dans `Z_PLUS_ACTIVE` (`laughter, mood, roach, thirst, transportation`) :** **`0` occurrence** (vérification formelle PASS).
- **Devenir des anciens homographes et overrides contextuels prioritaires :**

| `lemme_norm` | `part_disc` | Classe DIMA | Route / Panier | `en_matched_term` | `metric_provenance` | Statut |
| :--- | :---: | :--- | :--- | :--- | :--- | :--- |
| `cafard` | `NOM` | `Apathie` | `Z_PLUS_SATELLITE` / `Z_PLUS_IDIOM_MWE` | `roach` | `fancat_direct` | Exclu de `Z_PLUS_ACTIVE` via `z_plus_metaphor_exclusions.csv` → `Z_PLUS_IDIOM_MWE` |
| `transport` | `NOM` | `Troubler` | `Z_PLUS_SATELLITE` / `Z_PLUS_IDIOM_MWE` | `transportation` | `fancat_direct` | Exclu de `Z_PLUS_ACTIVE` (`vx` + métaphore) → `Z_PLUS_IDIOM_MWE` |
| `humeur` | `NOM` | `Colère` | `Z_PLUS_SATELLITE` / `Z_PLUS_IDIOM_MWE` | `mood` | `fancat_direct` | Exclu de `Z_PLUS_ACTIVE` (`vx` + métaphore) → `Z_PLUS_IDIOM_MWE` |
| `humeur` | `NOM` | `Humeur mauvaise` | `Z_PLUS_SATELLITE` / `Z_PLUS_IDIOM_MWE` | `mood` | `fancat_direct` | Exclu de `Z_PLUS_ACTIVE` (`vx` + métaphore) → `Z_PLUS_IDIOM_MWE` |
| `soif` | `NOM` | `Désir` | `Z_PLUS_SATELLITE` / `Z_PLUS_IDIOM_MWE` | `thirst` | `fancat_direct` | Exclu de `Z_PLUS_ACTIVE` via `z_plus_metaphor_exclusions.csv` → `Z_PLUS_IDIOM_MWE` |
| `rage` | `NOM` | `Désir` | `Z_PLUS_SATELLITE` / `Z_PLUS_IDIOM_MWE` | `rage` | `fancat_direct` | Exclu de `Z_PLUS_ACTIVE` via `z_plus_metaphor_exclusions.csv` → `Z_PLUS_IDIOM_MWE` |
| `rire` | `VERB` | `Mépris` | `Z_PLUS_SATELLITE` / `Z_PLUS_VERB_EXP` | `mock` | `nrc_override` | Intercepté avant `fancat_direct` par override contextuel `(rire, Mépris) -> mock` |
| `crainte` | `NOM` | `Estime respect` | `Z_PLUS_ACTIVE` / `Z_PLUS_EXPAFFECT` | `reverence` | `nrc_override` | Intercepté avant `fancat_direct` par override contextuel `(crainte, Estime respect) -> reverence` |
| `crainte` | `NOM` | `Crainte` | `Z_PLUS_ACTIVE` / `Z_PLUS_EXPAFFECT` | `fear` | `fancat_direct` | Conservé en `Z_PLUS_ACTIVE` avec norme native `fancat_direct` (`fear`) |
| `lassitude` | `NOM` | `Importuner` | `Z_PLUS_ACTIVE` / `Z_PLUS_EXPAFFECT` | `weariness` | `fancat_direct` | `V_harm`/`A_harm` FANCat + complétion `D_raw`/`D_orth` via override global `weariness` |

### 6.2 Audit complet des appariements par règle cognate (`127` entrées)

| `lemme_norm` | `part_disc` | Classe DIMA | `en_matched_term` | Règle appliquée |
| :--- | :---: | :--- | :--- | :--- |
| `adoration` | `NOM` | `Amour` | `adoration` | `cognate_exact` |
| `agitation` | `NOM` | `Troubler` | `agitation` | `cognate_exact` |
| `amateur` | `ADJ` | `Goût` | `amateur` | `cognate_exact` |
| `anglophile` | `ADJ` | `Amitié` | `anglophile` | `cognate_exact` |
| `anticlérical` | `ADJ` | `Inimitié` | `anticlerical` | `cognate_exact` |
| `appréhension` | `NOM` | `Crainte` | `apprehension` | `cognate_exact` |
| `ardent` | `ADJ` | `Désir` | `ardent` | `cognate_exact` |
| `aspiration` | `NOM` | `Désir` | `aspiration` | `cognate_exact` |
| `assurance` | `NOM` | `Confiance_Sentiment de sécurité` | `assurance` | `cognate_exact` |
| `attraction` | `NOM` | `Plaire_A` | `attraction` | `cognate_exact` |
| `aversion` | `NOM` | `Aversion` | `aversion` | `cognate_exact` |
| `aversion` | `NOM` | `Haine de qq` | `aversion` | `cognate_exact` |
| `béatitude` | `NOM` | `Combler Bonheur` | `beatitude` | `cognate_exact` |
| `camaraderie` | `NOM` | `Amitié` | `camaraderie` | `cognate_exact` |
| `commisération` | `NOM` | `Compassion` | `commiseration` | `cognate_exact` |
| `compassion` | `NOM` | `Compassion` | `compassion` | `cognate_exact` |
| `compulsion` | `NOM` | `Désir` | `compulsion` | `cognate_exact` |
| `confusion` | `NOM` | `Embarrasser` | `confusion` | `cognate_exact` |
| `confusion` | `NOM` | `Troubler` | `confusion` | `cognate_exact` |
| `considération` | `NOM` | `Estime` | `consideration` | `cognate_exact` |
| `consternation` | `NOM` | `Mauvais moral` | `consternation` | `cognate_exact` |
| `content` | `ADJ` | `Combler Bonheur` | `content` | `cognate_exact` |
| `contrition` | `NOM` | `Mauvaise conscience` | `contrition` | `cognate_exact` |
| `convivial` | `ADJ` | `Amitié` | `convivial` | `cognate_exact` |
| `cool` | `ADJ` | `Apaiser` | `cool` | `cognate_exact` |
| `cordial` | `ADJ` | `Amitié` | `cordial` | `cognate_exact` |
| `dépression` | `NOM` | `Mauvais moral` | `depression` | `cognate_exact` |
| `dépréciation` | `NOM` | `Mésestime` | `depreciation` | `cognate_exact` |
| `désolation` | `NOM` | `Attrister` | `desolation` | `cognate_exact` |
| `détestation` | `NOM` | `Aversion` | `detestation` | `cognate_exact` |
| `détestation` | `NOM` | `Haine de qq` | `detestation` | `cognate_exact` |
| `effervescence` | `NOM` | `Energie` | `effervescence` | `cognate_exact` |
| `exaltation` | `NOM` | `Bon moral` | `exaltation` | `cognate_exact` |
| `excitation` | `NOM` | `Bon moral` | `excitation` | `cognate_exact` |
| `excitation` | `NOM` | `Plaire_A` | `excitation` | `cognate_exact` |
| `exubérance` | `NOM` | `Energie` | `exuberance` | `cognate_exact` |
| `exubérant` | `ADJ` | `Energie` | `exuberant` | `cognate_exact` |
| `exultation` | `NOM` | `Réjouir` | `exultation` | `cognate_exact` |
| `fervent` | `ADJ` | `Admiration` | `fervent` | `cognate_exact` |
| `germanophile` | `ADJ` | `Amitié` | `germanophile` | `cognate_exact` |
| `homophobe` | `ADJ` | `Inimitié` | `homophobe` | `cognate_exact` |
| `hostile` | `ADJ` | `Aversion` | `hostile` | `cognate_exact` |
| `hostile` | `ADJ` | `Inimitié` | `hostile` | `cognate_exact` |
| `impassible` | `ADJ` | `Apaiser` | `impassible` | `cognate_exact` |
| `impassible` | `ADJ` | `Désintérêt` | `impassible` | `cognate_exact` |
| `impatience` | `NOM` | `Colère` | `impatience` | `cognate_exact` |
| `impatience` | `NOM` | `Désir impatience` | `impatience` | `cognate_exact` |
| `impatient` | `ADJ` | `Désir impatience` | `impatient` | `cognate_exact` |
| `imperturbable` | `ADJ` | `Apaiser` | `imperturbable` | `cognate_exact` |
| `inclination` | `NOM` | `Amour` | `inclination` | `cognate_exact` |
| `inclination` | `NOM` | `Goût` | `inclination` | `cognate_exact` |
| `inconsolable` | `ADJ` | `Attrister` | `inconsolable` | `cognate_exact` |
| `indifférence` | `NOM` | `Désintérêt` | `indifference` | `cognate_exact` |
| `indifférent` | `ADJ` | `Désintérêt` | `indifferent` | `cognate_exact` |
| `indigestion` | `NOM` | `Absence de désir` | `indigestion` | `cognate_exact` |
| `inhibition` | `NOM` | `Inhiber` | `inhibition` | `cognate_exact` |
| `insatiable` | `ADJ` | `Désir` | `insatiable` | `cognate_exact` |
| `insensible` | `ADJ` | `Désintérêt` | `insensible` | `cognate_exact` |
| `instinct` | `NOM` | `Désir` | `instinct` | `cognate_exact` |
| `irritation` | `NOM` | `Colère` | `irritation` | `cognate_exact` |
| `jovial` | `ADJ` | `Humeur bonne` | `jovial` | `cognate_exact` |
| `jubilant` | `ADJ` | `Réjouir` | `jubilant` | `cognate_exact` |
| `jubilation` | `NOM` | `Réjouir` | `jubilation` | `cognate_exact` |
| `libido` | `NOM` | `Amour` | `libido` | `cognate_exact` |
| `malaise` | `NOM` | `Embarrasser` | `malaise` | `cognate_exact` |
| `misanthrope` | `ADJ` | `Inimitié` | `misanthrope` | `cognate_exact` |
| `morose` | `ADJ` | `Humeur mauvaise` | `morose` | `cognate_exact` |
| `motivation` | `NOM` | `Désir` | `motivation` | `cognate_exact` |
| `oppression` | `NOM` | `Inquiéter` | `oppression` | `cognate_exact` |
| `penchant` | `NOM` | `Amour` | `penchant` | `cognate_exact` |
| `penchant` | `NOM` | `Goût` | `penchant` | `cognate_exact` |
| `prostration` | `NOM` | `Apathie` | `prostration` | `cognate_exact` |
| `prudent` | `ADJ` | `Doute` | `prudent` | `cognate_exact` |
| `prédilection` | `NOM` | `Amitié préférence` | `predilection` | `cognate_exact` |
| `prédilection` | `NOM` | `Goût` | `predilection` | `cognate_exact` |
| `préférence` | `NOM` | `Amitié préférence` | `preference` | `cognate_exact` |
| `préférence` | `NOM` | `Goût` | `preference` | `cognate_exact` |
| `préoccupation` | `NOM` | `Inquiéter` | `preoccupation` | `cognate_exact` |
| `préoccupation` | `NOM` | `Intéresser_A` | `preoccupation` | `cognate_exact` |
| `pénitence` | `NOM` | `Mauvaise conscience` | `penitence` | `cognate_exact` |
| `quiet` | `ADJ` | `Rassurer` | `quiet` | `cognate_exact` |
| `relax` | `ADJ` | `Désinhiber` | `relax` | `cognate_exact` |
| `repentance` | `NOM` | `Mauvaise conscience` | `repentance` | `cognate_exact` |
| `repentant` | `ADJ` | `Mauvaise conscience` | `repentant` | `cognate_exact` |
| `respect` | `NOM` | `Estime respect` | `respect` | `cognate_exact` |
| `réconciliation` | `NOM` | `Amitié` | `reconciliation` | `cognate_exact` |
| `répugnance` | `NOM` | `Aversion` | `repugnance` | `cognate_exact` |
| `répugnance` | `NOM` | `Déplaire_A` | `repugnance` | `cognate_exact` |
| `répulsion` | `NOM` | `Déplaire_A` | `repulsion` | `cognate_exact` |
| `révulsion` | `NOM` | `Déplaire_A` | `revulsion` | `cognate_exact` |
| `révérence` | `NOM` | `Estime respect` | `reverence` | `cognate_exact` |
| `satisfaction` | `NOM` | `Combler Bonheur` | `satisfaction` | `cognate_exact` |
| `saturation` | `NOM` | `Absence de désir` | `saturation` | `cognate_exact` |
| `sentiment` | `NOM` | `Amour` | `sentiment` | `cognate_exact` |
| `stress` | `NOM` | `Importuner` | `stress` | `cognate_exact` |
| `stupéfaction` | `NOM` | `Surprendre` | `stupefaction` | `cognate_exact` |
| `subjugation` | `NOM` | `Plaire_B` | `subjugation` | `cognate_exact` |
| `suspicion` | `NOM` | `Défiance_Sentiment d'insécurité` | `suspicion` | `cognate_exact` |
| `tension` | `NOM` | `Importuner` | `tension` | `cognate_exact` |
| `tension` | `NOM` | `Inimitié` | `tension` | `cognate_exact` |
| `trouble` | `NOM` | `Troubler` | `trouble` | `cognate_exact` |
| `vénération` | `NOM` | `Estime respect` | `veneration` | `cognate_exact` |
| `xénophobe` | `ADJ` | `Inimitié` | `xenophobe` | `cognate_exact` |
| `allergie` | `NOM` | `Aversion` | `allergy` | `cognate_suffix:-ie->-y` |
| `misanthropie` | `NOM` | `Inimitié` | `misanthropy` | `cognate_suffix:-ie->-y` |
| `misogynie` | `NOM` | `Inimitié` | `misogyny` | `cognate_suffix:-ie->-y` |
| `philanthropie` | `NOM` | `Amitié` | `philanthropy` | `cognate_suffix:-ie->-y` |
| `allergique` | `ADJ` | `Aversion` | `allergic` | `cognate_suffix:-ique->-ic` |
| `anticléricalisme` | `NOM` | `Inimitié` | `anticlericalism` | `cognate_suffix:-isme->-ism` |
| `antisémitisme` | `NOM` | `Inimitié` | `antisemitism` | `cognate_suffix:-isme->-ism` |
| `affinité` | `NOM` | `Amitié` | `affinity` | `cognate_suffix:-ité->-ity` |
| `curiosité` | `NOM` | `Curiosité` | `curiosity` | `cognate_suffix:-ité->-ity` |
| `fraternité` | `NOM` | `Amitié` | `fraternity` | `cognate_suffix:-ité->-ity` |
| `impassibilité` | `NOM` | `Désintérêt` | `impassibility` | `cognate_suffix:-ité->-ity` |
| `incrédulité` | `NOM` | `Incrédulité` | `incredulity` | `cognate_suffix:-ité->-ity` |
| `insensibilité` | `NOM` | `Désintérêt` | `insensibility` | `cognate_suffix:-ité->-ity` |
| `jovialité` | `NOM` | `Humeur bonne` | `joviality` | `cognate_suffix:-ité->-ity` |
| `perplexité` | `NOM` | `Troubler` | `perplexity` | `cognate_suffix:-ité->-ity` |
| `placidité` | `NOM` | `Apaiser` | `placidity` | `cognate_suffix:-ité->-ity` |
| `sensibilité` | `NOM` | `Curiosité` | `sensibility` | `cognate_suffix:-ité->-ity` |
| `agoraphobe` | `ADJ` | `Peur phobie` | `agoraphobic` | `cognate_suffix:-phobe->-phobic` |
| `claustrophobe` | `ADJ` | `Peur phobie` | `claustrophobic` | `cognate_suffix:-phobe->-phobic` |
| `agoraphobie` | `NOM` | `Peur phobie` | `agoraphobia` | `cognate_suffix:-phobie->-phobia` |
| `claustrophobie` | `NOM` | `Peur phobie` | `claustrophobia` | `cognate_suffix:-phobie->-phobia` |
| `homophobie` | `NOM` | `Inimitié` | `homophobia` | `cognate_suffix:-phobie->-phobia` |
| `xénophobie` | `NOM` | `Inimitié` | `xenophobia` | `cognate_suffix:-phobie->-phobia` |
| `zoophobie` | `NOM` | `Peur phobie` | `zoophobia` | `cognate_suffix:-phobie->-phobia` |

---

## 7. Artefacts produits par la Micro-Passe 2

| Artefact | Taille (octets) | SHA-256 | Statut Git |
| :--- | ---: | :--- | :--- |
| `data/processed/dima_z_plus_psychometrics.parquet` | 168,709 | `726b09a0b5b099084dc947c3da889bb499e2dad555c8a79317a029cbaf629453` | Local uniquement (ignoré par `.gitignore`) |
| `data/config/fr_en_bridge_overrides.csv` | 5,450 | `3b329617dea56a19e633a6a7448ec9808b806650c0ce15cc3224e4a53d3fcf73` | Versionnable dans Git |
| `python/lexicon_pipeline/02_bridge_psychometrics.py` | — | *(script source)* | Versionnable dans Git |
| `reports/lexicon_v3/mp2_calibration_report.md` | — | *(présent rapport)* | Versionnable dans Git |
