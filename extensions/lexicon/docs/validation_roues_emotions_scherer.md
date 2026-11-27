---
title: CARTOGRAFFECT mis à l'épreuve des Roues des Émotions (Scherer et al., 2013)
author: Manuel Cabelguen
date: 2026-11-25
license_code: GNU AGPLv3 (SPDX: AGPL-3.0-or-later)
license_docs: CC BY 4.0 (SPDX: CC-BY-4.0)
---

# CARTOGRAFFECT mis à l'épreuve des Roues des Émotions : Évaluation Critique (Strate 1 — Exploratoire)

[![Status: Exploratory Audit](https://img.shields.io/badge/Status-Exploratory_Audit_(Strate_1)-blue)](#2-tableau-de-synthese-des-hypotheses-pre-enregistrees)
[![Empirical Data: Scherer et al. 2013](https://img.shields.io/badge/Benchmark-Scherer_et_al._2013_OUP-blue)](#1-cadre-epistemologique-et-protocole-de-falsification)
[![Manual Overrides: 0](https://img.shields.io/badge/Manual_Overrides-0-informational)](#regles-dappariement-lexical-objectif-zero-surcharge-manuelle)

> **Statut épistémologique (Strate 1 — Phase 1 v3.0) :** Ce banc lexical confronte les projections lexicales automatiques du modèle aux coordonnées de 4 roues publiées dans Scherer et al. (2013). Il s'agit d'un **audit lexical exploratoire** (`V3 = 0` vis-à-vis d'une validation psychométrique sur participants humains). Toutes les surcharges manuelles codées en dur (`rire`, `soumission -> by_id[271]`, `canonical_alts`) ont été retirées, et les hypothèses **H2** et **H4** sont rapportées strictement comme **non corroborées** sans recadrage post-hoc.

---

## 1. Cadre Épistémologique et Protocole de Falsification

Dans cette étude exploratoire, **CARTOGRAFFECT** (OPIC n° 1233199 ; Cabelguen, 2026) est confronté aux quatre modèles circulaires colligés dans l'ouvrage de référence de Klaus R. Scherer et ses collaborateurs :

> **Source documentaire** : Scherer, K. R., Shuman, V., Fontaine, J. R. J., & Soriano, C. (2013). *The GRID meets the Wheel: Assessing emotional feeling via self-report*. In J. R. J. Fontaine, K. R. Scherer, & C. Soriano (Eds.), *Components of emotional meaning: A sourcebook* (ch. 18, pp. 289–305). Oxford University Press.

Les quatre géométries circulaires comparées sont :
1. **GEW 3.0 (Geneva Emotion Wheel v3.0, 2013)** : Coordonnées empiriques bidimensionnelles **Valence × Power/Control** issues d'un MDS (*Proxscal*) sur 20 familles d'émotions (Table 2 & Figure 6).
2. **GEW 2.0 (2005–2012)** : Roue théorique à 20 familles (40 termes français, couples de synonymes) réparties à pas angulaire constant de $18^\circ$ (Figure 4).
3. **GEW 1.0 (2003–2005)** : Prototype initial à 16 familles (17 termes français, pas de $22.5^\circ$), Figure 3.
4. **Roue de Robert Plutchik (1980, 2001)** : Circumplex à 8 pétales fondamentaux déclinés en 3 niveaux d'intensité (24 états) complétés de 8 dyades primaires (32 termes, Figure 2).

### Règles d'Appariement Lexical Objectif (Zéro Surcharge Manuelle)
Afin d'éviter tout biais de confirmation ou ajustement ad hoc :
- **Règle 1 (Ancre exacte)** : Si le lemme français correspond directement à un pôle de `ref_303_diamant_z.tsv`, ses coordonnées $(X, Y, Z)$ sont lues directement.
- **Règle 2 (Projection lexicale automatique)** : Sinon, le terme est résolu par recherche automatique stricte dans `CARTOGRAFFECT_Diamant_303_Lexique_Complet.tsv` (puis `CARTOGRAFFECT_NRC_Lexicon_Complet.tsv`), **sans aucune surcharge manuelle codée en dur** (`manual_overrides = NONE`).
- **Règle 3 (Non-couverture)** : Tout terme absent des tables est comptabilisé comme non couvert.

---

## 2. Tableau de Synthèse des Hypothèses Pré-enregistrées

Résultats exacts produits par `src/validate_emotion_wheels.py` (**10 000 permutations**, **5 000 rééchantillonnages bootstrap**, **0 surcharge manuelle**, graine `20131118`) :

| Hypothèse | Propriété Testée | Seuil Pré-enregistré | GEW 3.0 (Empirique) | GEW 2.0 (Théorique) | GEW 1.0 (Prototype) | Plutchik (Circumplex) | Verdict Pré-enregistré |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **H1** | **Préservation de l'Ordre Circulaire** | $\bar{R} \ge 0.70$, $p < 0.05$ | $\bar{R} = 0.777$ ($p = 0.0001$) | $\bar{R} = 0.831$ ($p = 0.0001$) | $\bar{R} = 0.615$ ($p = 0.0023$) | $\bar{R} = 0.481$ ($p = 0.0012$) | **VALIDÉ** (GEW 2/3) / **PARTIEL** (GEW 1) / **INVALIDÉ** (Plutchik) |
| **H2** | **Alignement Direct des Axes (sans rotation)** | $\|\alpha\| \le 22.5^\circ$ | $\alpha = -31.0^\circ$ ($[-49.0^\circ, -12.0^\circ]$) | $\alpha = -27.4^\circ$ ($[-41.8^\circ, -10.1^\circ]$) | $\alpha = -17.9^\circ$ ($[-44.4^\circ, +18.3^\circ]$) | $\alpha = +40.5^\circ$ ($[+13.5^\circ, +72.2^\circ]$) | **NON CORROBORÉE** (GEW 3.0 & GEW 2.0) / Corroborée (GEW 1.0 seul) |
| **H3** | **Non-inversion Hédonique** | $0$ violation ($\|V\| \ge 0.35$) | **$100\%$** ($0/64$ cumulé) | **$100\%$** | **$100\%$** | N/A (pas d'axe V continu) | **VALIDÉ** ($0/64$ violations) |
| **H4** | **Antipodalité 2D des Opposés de Roue** | $\text{Taux}(\Delta\theta \ge 135^\circ) \ge 75\%$ | $77.3\%$ ($17/22$ paires ; exact Lean $4.5\%$) | $52.8\%$ ($19/36$ paires ; exact Lean $2.8\%$) | $37.5\%$ ($3/8$ paires ; exact Lean $0.0\%$) | $40.0\%$ ($6/15$ paires ; exact Lean $6.7\%$) | **NON CORROBORÉE** (GEW 2.0, GEW 1.0, Plutchik) / Corroborée (GEW 3.0 seul sur le seuil $\ge 135^\circ$) |
| **H5** | **Dissociation de $Z$ vs Intensité Plutchik** | $\|\rho_{\text{Spearman}}\| < 0.50$, $p \ge 0.05$ | N/A | N/A | N/A | $\rho = +0.079$ ($p = 0.7132$) | **VALIDÉ** ($Z$ non corrélé à l'intensité de Plutchik) |
| **H6** | **Couverture Lexicale du Modèle** | $\text{Couverture} \ge 80\%$ | **$100\%$** ($20/20$) | **$100\%$** ($40/40$) | **$100\%$** ($17/17$) | **$100\%$** ($32/32$) | **VALIDÉ** ($109/109$ items couverts) |
| **H7** | **Comparaison Ligne de Base NRC Brut $(V, D)$** | $\Delta\bar{R} > 0$ (IC 95 % $> 0$) | $\bar{R}_{\text{Carto}} = 0.777$ vs $\bar{R}_{\text{NRC}} = 0.918$ ($\Delta = -0.141$, IC $[-0.245, -0.020]$) | N/A | N/A | N/A | **INVALIDÉ** (perte significative par rapport à NRC continu) |

---

## 3. Analyse Factuelle des Résultats

### 3.1 H1 & H2 : Ordre Circulaire et Échec de l'Alignement Axial Direct (H2 Non Corroborée)
- **H1** atteint le seuil pré-enregistré ($\bar{R} \ge 0.70$, $p < 0.05$) sur **GEW 3.0** ($\bar{R} = 0.777$, $p = 0.0001$, $\text{MAE} = 33.5^\circ$) et **GEW 2.0** ($\bar{R} = 0.831$, $p = 0.0001$, $\text{MAE} = 25.9^\circ$). En revanche, H1 est **partielle** sur GEW 1.0 ($\bar{R} = 0.615$, $p = 0.0023$) et **invalidée** sur Plutchik ($\bar{R} = 0.481$, $p = 0.0012$, $\text{MAE} = 54.2^\circ$, 6 outliers à résidu $> 90^\circ$).
- **H2 est non corroborée** sur les deux benchmarks principaux : l'angle optimal de rotation excède strictement la tolérance pré-enregistrée de $\pm 22.5^\circ$ aussi bien sur GEW 3.0 ($\alpha = -31.0^\circ$, IC 95 % $[-49.0^\circ, -12.0^\circ]$) que sur GEW 2.0 ($\alpha = -27.4^\circ$, IC 95 % $[-41.8^\circ, -10.1^\circ]$). Seul le prototype GEW 1.0 présente $|\alpha| \le 22.5^\circ$ ($\alpha = -17.9^\circ$, mais avec un IC 95 % large $[-44.4^\circ, +18.3^\circ]$).
- Sur les 20 familles GEW 3.0, les corrélations linéaires brutes observées sont :
  - $r(X, \text{Valence GEW3}) = +0.806$ ($p_{\text{perm}} = 0.0001$)
  - $r(Y, \text{Power GEW3}) = +0.468$ ($p_{\text{perm}} = 0.0399$)
  - $r(X, \text{Power GEW3}) = -0.091$ et $r(Y, \text{Valence GEW3}) = +0.404$
- Ces corrélations et le décalage angulaire de $\sim 30^\circ$ indiquent que les axes $(X, Y)$ actuels du lexique ne coïncident pas directement sans rotation avec les axes empiriques $(\text{Valence}, \text{Power})$ de GEW 3.0. Conformément au protocole pré-enregistré, **H2 demeure strictement non corroborée**.

### 3.2 H3 : Conformité du Signe Hédonique ($X$ vs Valence)
Sur les 64 items polarisés évalués ($\|V\| \ge 0.35$) par recherche lexicale strictement automatique (**0 surcharge manuelle**), aucune inversion de signe n'est observée ($0/64$ violations, $100.0\%$).

---

## 4. H4 : Non-Corroboration de l'Antipodalité 2D des Opposés de Roue

Le critère pré-enregistré de H4 ($\ge 75\%$ des paires diamétralement opposées sur chaque roue séparées d'au moins $135^\circ$ dans le plan $(X, Y)$) est **non corroboré** sur trois des quatre roues :
- **GEW 3.0** : $77.3\%$ ($17/22$ paires $\ge 135^\circ$, mais seulement $1/22 = 4.5\%$ d'antagonistes exacts au sens de l'opérateur formel).
- **GEW 2.0** : $52.8\%$ ($19/36$ paires $\ge 135^\circ$ ; exact $2.8\%$) — **NON CORROBORÉE**.
- **GEW 1.0** : $37.5\%$ ($3/8$ paires $\ge 135^\circ$ ; exact $0.0\%$) — **NON CORROBORÉE**.
- **Plutchik** : $40.0\%$ ($6/15$ paires $\ge 135^\circ$ ; exact $6.7\%$) — **NON CORROBORÉE**.

Conformément à la règle anti-recadrage post-hoc (Phase 1), **H4 est rapportée strictement comme non corroborée** : l'involutivité interne de l'opérateur géométrique par morceaux de CARTOGRAFFECT,

$$\mathcal{A}(X, Y, Z) = \begin{cases} (-X, -Y, Z) & \text{si } XY = 0 \\ (-\operatorname{sgn}(X)|Y|,\; -\operatorname{sgn}(Y)|X|,\; Z) & \text{si } XY \neq 0 \end{cases}$$

est une **propriété algébrique interne** du modèle (certifiée dans `Cartograffect/AffectiveMatrix.lean` et `extensions/lexicon/lean/EmotionWheelsChallenge.lean`) et **ne constitue pas** une validation empirique substitutive de H4 ni une réfutation empirique de la roue de Plutchik. Les écarts observés (par exemple *Peur* $(-2,0,2)$ et *Colère* $(-1,+1,2)$ distantes de $45^\circ$ dans CARTOGRAFFECT alors qu'elles sont opposées sur la roue de Plutchik) reflètent une **divergence de construction géométrique** entre les deux taxonomies, qui ne peut être tranchée que par des données comportementales ou psychométriques humaines indépendantes (V3).

---

## 5. H5 : Dissociation entre $Z$ et l'Intensité de Plutchik

Sur les 24 états gradués en 3 niveaux d'intensité sur la roue de Plutchik, la corrélation de rang entre le niveau d'intensité Plutchik et la coordonnée $Z$ de CARTOGRAFFECT est non significative :
$$\rho_{\text{Spearman}}(\text{Intensité Plutchik}, Z_{\text{Cartograffect}}) = +0.079 \quad (p_{\text{perm}} = 0.7132)$$
(analyse de sensibilité avec traductions alternatives : $\rho = -0.049$, $p_{\text{perm}} = 0.8258$). Ce résultat confirme que la coordonnée $Z$ ne réplique pas l'ordonnancement d'intensité de Plutchik ; il ne prouve pas à lui seul la validité empirique du construit « profondeur d'abstraction » sans mesure comportementale humaine dédiée.

---

## 6. H6 & H7 : Couverture Lexicale et Infériorité face à la Ligne de Base NRC Continue

- **H6 (Couverture)** : **$100\%$** ($109/109$ items couverts sur l'ensemble des 4 roues sans surcharge manuelle : GEW 3.0 $20/20$, GEW 2.0 $40/40$, GEW 1.0 $17/17$, Plutchik $32/32$).
- **H7 (Ligne de base NRC brut $(V, D)$)** : **INVALIDÉ**. Sur GEW 3.0 ($n = 20$), la concentration circulaire obtenue par CARTOGRAFFECT ($\bar{R} = 0.7774$) est **significativement inférieure** à celle des normes continues NRC-VAD $(V, D)$ ($\bar{R} = 0.9184$, $\Delta = -0.1409$, IC 95 % $[-0.2449, -0.0201]$).
- **Diagnostique exploratoire (hors critères pré-enregistrés)** : La projection sphérique $L_2$ (`H7b_dual_L2_exploratory_diagnostic`) donne $\bar{R} = 0.7774$ ($\Delta$ vs NRC inchangé à $-0.1409$), $\text{MAE} = 33.48^\circ$, $r(X_{L_2}, \text{Valence}) = +0.811$ et $r(Y_{L_2}, \text{Power}) = +0.466$.

---

## 7. Fichiers de Données et Reproductibilité

- `data/emotion_wheels/scherer2013_wheels.tsv` : Table normalisée des 4 roues extraites de Scherer et al. (2013).
- `CARTOGRAFFECT_Wheels_Challenge_Items.tsv` : Projection automatique item par item (0 surcharge manuelle).
- `CARTOGRAFFECT_Wheels_Challenge_Stats.json` : Statistiques complètes (permutations, bootstrap, corrélations, primaire et sensibilité).
- `src/validate_emotion_wheels.py` : Script reproductible exécuté sans surcharges manuelles.
- `lean/EmotionWheelsChallenge.lean` : Uniquement les 2 théorèmes géométriques/combinatoires purs (0 constante statistique Python codée en dur).
