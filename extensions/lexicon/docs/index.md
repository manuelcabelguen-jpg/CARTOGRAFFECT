# Architecture CARTOGRAFFECT — Topologie 3D Duale ($L_1 \leftrightarrow L_2$), Taxonomie Multi-Strates (S1–S6) & Preuves Formelles Lean 4

Bienvenue dans la documentation scientifique et technique du modèle **CARTOGRAFFECT** (Cabelguen, 2026 ; enregistrement **OPIC n° 1233199**).

---

## 1. Architecture Souveraine de CARTOGRAFFECT

**CARTOGRAFFECT** est une architecture théorique, géométrique et taxonomique tridimensionnelle autonome qui structure l'espace affectif, éthique, axiologique et politique humain selon des lois génératives exactes :

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

Dans **CARTOGRAFFECT**, les trois dimensions sont définies de manière intrinsèque :

- **Axe $X$ — Attente / Révisabilité épistémique ($\mathbb{Z}$)** : Polarité de congruence du modèle interne face au réel ($+X$ ouverture/confirmation vs $-X$ menace/dissonance).
- **Axe $Y$ — Contrôle / Modalité pragmatique d'action ($\mathbb{Z}$)** : Disjonction entre l'affectivité **agie / projective** ($+Y$ : engagement, confrontation, extériorisation) et l'affectivité **réflexive / réceptive** ($-Y$ : intériorisation, retenue, élaboration interne), avec l'axe central $Y = 0$ d'équilibre suspensif.
- **Axe $Z$ — Élévation cognitive, normative et politique ($\{0, \dots, 7\}$ & Strates S1–S6)** : Hiérarchie verticale allant du Point de Veille basal ($Z = 0$) et de la Surprise ($Z = 1$) jusqu'aux Sentiments transcendantaux et politiques ($Z = 7$), gouvernant simultanément la capacité de différenciation sémantique $8(Z - 1)$ et le passage de l'ancrage somatique (S1) à l'abstraction axiologique et politique (S5–S6).

---

## 3. Épreuve Externe Exploratoire (Roues des Émotions, Scherer et al., 2013)

- **Note d'intégrité probatoire (Phase 1, `v3.0.0-dev`) :** Les scripts et revendications de « validation empirique » **GRID-24 / CPM-142** (anciens artefacts synthétiques avec réinjection sectorielle et module `SchererGRID.lean` contenant des scores statistiques codés en dur) ont été **retirés du périmètre actif** et archivés dans `archive/deprecated_synthetic_v2/`.
- **[Défi des Roues des Émotions (Scherer et al., 2013)](validation_roues_emotions_scherer.md)** :
  - Épreuve exploratoire confrontant la projection lexicale de CARTOGRAFFECT aux roues **GEW 3.0**, **GEW 2.0**, **GEW 1.0** et au **Circumplex de Plutchik** sans surcharge manuelle cachée (permutations Monte-Carlo $N = 10\,000$).
  - Les hypothèses **H2** (orthogonalité sans rotation, $|\alpha| \le 22.5^\circ$) et **H4** (antipodalité 2D des opposés de roue) sont rapportées strictement comme **non corroborées** sans recadrage post-hoc.

---

## 4. Propriété Intellectuelle et Séparation Physique des Licences (v3.0.0 — OSF / Zenodo)

- **Titulaire et enregistrement** : **CARTOGRAFFECT** — © 2026 Manuel Cabelguen (droit d'auteur **OPIC n° 1233199**).
- **Code source logiciel et preuves formelles (`src/`, `scripts/`, `Cartograffect/`)** : **GNU Affero General Public License v3.0 or later** (`SPDX-License-Identifier: AGPL-3.0-or-later`).
- **Documentation, textes et tables taxonomiques (`docs/`, `tables/`)** : **Creative Commons Attribution 4.0 International (`CC-BY-4.0`)**.
