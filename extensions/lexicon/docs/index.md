# Architecture CARTOGRAFFECT® — Topologie 3D Duale ($L_1 \leftrightarrow L_2$), Taxonomie Multi-Strates (S1–S6) & Preuves Formelles Lean 4

Bienvenue dans la documentation scientifique et technique du modèle **CARTOGRAFFECT®** (Cabelguen, 2026 ; enregistrement **OPIC n° 1233199**).

---

## 1. Architecture Souveraine de CARTOGRAFFECT®

**CARTOGRAFFECT®** est une architecture théorique, géométrique et taxonomique tridimensionnelle autonome qui structure l'espace affectif, éthique, axiologique et politique humain selon des lois génératives exactes :

1. **Enveloppe Octaédrique $L_1$ (`Lexicon176.lean`)** :
   - Pyramide octaédrique discrète à **$176$ prototypes** répartis sur $8$ couronnes cognitives $Z \in \{0, \dots, 7\}$ (et extension en Diamant complet à **$303$ pôles** incluant l'hémisphère axiologique $Z^-$).
   - Pour chaque couronne $Z \ge 2$, la loi d'allocation budgétaire exacte s'écrit :
     $$R_{L_1}(Z) = |X| + |Y| = 2(Z - 1)$$
     générant $4 \cdot R_{L_1}(Z) = 8(Z - 1)$ positions périphériques par couronne ($168$ pôles périphériques + $8$ opérateurs centraux $(0, 0, Z)$ = **$176$ prototypes**).
2. **Sphère Octaédrique Duale ($L_1 \leftrightarrow L_2$)** :
   - Homéomorphisme radial continu bijectif $u_{L_p} = u \cdot (\|u\|_1 / \|u\|_p)$ autour du plan équatorial homéostatique $Z_7$ ($u = (X, Y, Z - 7)$), reliant la combinatoire discrète exacte du **Diamant $L_1$** ($p = 1$, parcimonie combinatoire et budget additif $B(Z)$) à la variété riemannienne lisse $C^\infty$ de la **Sphère $L_2$** ($p = 2$, isotropie angulaire et dynamique continue FEP/SDE).
3. **Dictionnaire Multi-Strates à 6 Niveaux (`CARTOGRAFFECT_Full_Dictionary_MultiStrata.tsv`)** :
   - Indexation complète de **$16\,183$ entrées lexicales françaises** (dont $15\,037$ lemmes affectifs et $1\,991$ lemmes Open-Data CNRS GLAWI / Morphalou-TLFi / Lexique 3.83 / DIMA / NRC-VAD) hiérarchisées sur **6 strates d'abstraction** :
     - **S1 • Somatique** : estados viscéraux, proprioceptifs et réflexes immédiats.
     - **S2 • Émotif** : émotions réactives de court terme.
     - **S3 • Sentimental** : sentiments relationnels et dispositions affectives durables.
     - **S4 • Éthique** : vertus, devoirs et jugements de conduite interpersonnelle.
     - **S5 • Axiologique** : valeurs transcendantales, esthétiques et spirituelles.
     - **S6 • Politique** : concepts civiques, institutionnels et de justice collective.

---

## 2. Fondements Axiomatiques des Trois Axes $(X, Y, Z)$

Dans **CARTOGRAFFECT®**, les trois dimensions sont définies de manière intrinsèque :

- **Axe $X$ — Attente / Révisabilité épistémique ($\mathbb{Z}$)** : Polarité de congruence du modèle interne face au réel ($+X$ ouverture/confirmation vs $-X$ menace/dissonance).
- **Axe $Y$ — Contrôle / Modalité pragmatique d'action ($\mathbb{Z}$)** : Disjonction entre l'affectivité **agie / projective** ($+Y$ : engagement, confrontation, extériorisation) et l'affectivité **réflexive / réceptive** ($-Y$ : intériorisation, retenue, élaboration interne), avec l'axe central $Y = 0$ d'équilibre suspensif.
- **Axe $Z$ — Élévation cognitive, normative et politique ($\{0, \dots, 7\}$ & Strates S1–S6)** : Hiérarchie verticale allant du Point de Veille basal ($Z = 0$) et de la Surprise ($Z = 1$) jusqu'aux Sentiments transcendantaux et politiques ($Z = 7$), gouvernant simultanément la capacité de différenciation sémantique $8(Z - 1)$ et le passage de l'ancrage somatique (S1) à l'abstraction axiologique et politique (S5–S6).

---

## 3. Support de Validation Externe *a posteriori* (Témoin Scherer GRID / CPM)

Afin de démontrer empiriquement la solidité psychométrique de **CARTOGRAFFECT®** face à la littérature existante, le modèle a été confronté *a posteriori* à des référentiels externes (NRC-VAD v2.1, DIMA et l'échantillon de 24 termes du paradigme **GRID / Component Process Model** de Scherer, 2005 ; Fontaine et al., 2007, 2013) :

- **Statut méthodologique** : Le paradigme GRID ne définit aucunement la géométrie de CARTOGRAFFECT® (GRID ne comporte que **24 mots** d'émotions courantes, limités aux strates basses S1–S3, sans loi d'enveloppe ni strates éthiques/axiologiques/politiques S4–S6). Il sert uniquement d'**échantillon-témoin externe** pour vérifier que les mesures psychométriques classiques (142 descripteurs componantiels) viennent naturellement s'inscrire aux emplacements prévus par la topologie 3D de CARTOGRAFFECT®.
- **[Rapport de Validation Psychométrique & Preuves Formelles Lean 4.35.0](validation_scherer_grid.md)** :
  - Vérification de l'invariance des octants, des symétries antagonistes et de l'homéomorphisme radial $L_1 \leftrightarrow L_2$ sous **Lean 4.35.0** (`Cartograffect/Validation/SchererGRID.lean`, zéro `sorry`).
  - Benchmark comparatif de la dualité Diamant ($L_1$) $\leftrightarrow$ Sphère ($L_2$) démontrant le gain d'isotropie angulaire ($\Delta\phi_Z = +0.2385$ sur les 176 prototypes et $+0.3407$ sur le lexique).
- **[Défi des Roues des Émotions (Scherer et al., 2013)](validation_roues_emotions_scherer.md)** :
  - Épreuve de falsification empirique confrontant CARTOGRAFFECT aux roues **GEW 3.0**, **GEW 2.0**, **GEW 1.0** et au **Circumplex de Plutchik** (7 hypothèses pré-enregistrées, permutations Monte Carlo $N=10\,000$).
  - Confirmation empirique de l'ordre circulaire ($\bar{R} = 0.728, p = 0.0001$), de l'invariance de signe de valence ($98.4\%$), de l'orthogonalisation face au cisaillement oblique empirique ($\alpha \approx -31^\circ$), et de la validité discriminante fondamentale de l'axe vertical ($Z \neq \text{intensité}$, $\rho = +0.215, p = 0.338$).

---

## 4. Propriété Intellectuelle et Double Licence (OSF / Zenodo)

- **Titulaire et enregistrement** : **CARTOGRAFFECT®** — © 2026 Manuel Cabelguen (**OPIC n° 1233199**).
- **Code source logiciel et preuves formelles (`src/`, `scripts/`, `Cartograffect/`)** : **GNU Affero General Public License v3.0 (GNU AGPLv3)** (`SPDX-License-Identifier: AGPL-3.0-or-later`).
- **Théorie, architecture géométrique, taxonomie multi-strates et documentation (`docs/`, `tables/`)** : **Creative Commons Attribution - Pas d'Utilisation Commerciale - Partage dans les Mêmes Conditions 4.0 International (CC BY-NC-SA 4.0)**.
