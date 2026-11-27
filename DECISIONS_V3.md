# DECISIONS_V3 — Verrouillage des 4 Arbitrages Théoriques (Phase 0)

**Projet :** CARTOGRAFFECT (v3.0) · **Date :** 2026-11-25 · **Statut :** Irréversible — Validé par l'auteur (Manuel Cabelguen)
**Garde-fous :** Tag `v2.1.0` immuable ; aucun chantier sur Rocq/Agda/Dafny/SMT/TLA+, le Diamant 303 ni les 26 profils DSM-5.

---

## 1. Axe Y — Contrôlabilité instrumentale stricte et canal d'activation autonome (Option 1A)
- **Définition :** `Y` mesure exclusivement la **contrôlabilité instrumentale perçue** (capacité d'agir sur le monde), découplée de l'activation physiologique / mobilisation allostatique externalisée dans un canal autonome indépendant `A ≥ 0`.
- **Impact formel :** Suppression de `computeActivation(p.y)` dans `Cartograffect/AffectiveMatrix.lean` et refonte de la clause correspondante (`isCoherentTerminalState`, `end_to_end_coherence`) dans `Cartograffect/AffectiveTaxonomy.lean`.
- **Impact lexical et symétrie sémantique totale sur `Y−` :**
  - **`(X < 0, Y > 0)` :** Limité à l'affrontement agentique (`Colère`, `Frustration`, `Hostilité`, `Révolte`). Les états aversifs à faible contrôle (`Consternation`, `Angoisse`, `Frénésie`, `Terreur`, `Déchirement`, `Horreur`, `Vertige`, `Détresse`) sortent de `Y+` vers `Y < 0` (distingués de la résignation par `A` élevé).
  - **`(X > 0, Y < 0)` :** Rejet de « non-nécessité d'action ». `Y−` garde partout son sens univoque de faible contrôle perçu et code l'**accommodation / contrôle secondaire accepté face à une limite objective d'action** (`Calme`, `Acceptation`, `Lâcher-prise`). Les états de maîtrise ou sécurité stable (`Sécurité`, `Plénitude`, `Sérénité` hors limite d'action) migrent vers `Y ≥ 0` (`A` bas).

## 2. Dynamique verticale sur Z — Régime pas-à-pas strict (Option 2a)
- **Loi unique :** Transitions régies par `ΔZ ∈ {-1, 0, +1}` avec **unique court-circuit descendant `2 → 0`** (évitant la Surprise `Z = 1`, réservée à l'amorçage ascendant), sans seuil discontinu additionnel `Θ_crit(Z)` en v3.0 (parcimonie et identifiabilité).
- **Impacts :** Alignement sur §6.3, `CoreAffect.dissipationStep` et `PredictiveCircuit.nextStratumR5`. Retrait de la « projection directe sans pas séquentiel » dans §4, la Figure 1 et déclassement/refonte de `extensions/predictive_engine/PredictiveEngineCanonical.lean`. Reformulation des effractions aiguës (§5.2, §7.2) en cascades rapides `1 → 2 → … → Z` à constante de temps brève sous erreur saturée.

## 3. Périmètre de P2 — Instabilité axiale restreinte aux pôles en Charge (Option 3b)
- **Périmètre :** L'instabilité axiale (`χ > 0`) s'applique **uniquement aux 2 pôles en Charge négative** (`Peur (-2,0,2)`, `Tristesse (0,-2,2)`), alignée sur `Cartograffect/PredictiveCircuit.lean` et `python/cartograffect_predictive_engine.py` (cohérence cybernétique/Lyapunov). Les 2 pôles en Décharge (`Joie (0,2,2)`, `Courage (2,0,2)`) ne s'auto-déstabilisent pas à bruit nul et retournent vers `Veille (0,0,0)` via dissipation (`γ_A, γ_C`).
- **Impacts :** L'antagonisme est une **symétrie géométrique statique**, la dynamique assumant une **brisure de symétrie Charge / Décharge** (biais de négativité). Retrait de `DepthTransitionKernel.antagonist_equivariant` et réécriture de `canonicalDepthKernel_axial_instability_p2` dans `Cartograffect/AffectiveDynamics.lean`, ainsi que de §5.2, §6.1 et P2 (§8.2, Tableau 2).

## 4. Périmètre publiable v3.0 — Z continu (0..5) et discrétisation canonique bornée à Z ∈ {0, 1, 2}
- **Cœur du manuscrit :** `Z` modélise une profondeur hiérarchique continue couvrant *Veille / Surprise / Affect / Émotion / Sentiment / Humeur* (régimes `0..5`, conservant l'analyse de la dépression en §8.1). Seuls `Z = 0` (Veille), `Z = 1` (Surprise) et la couronne `Z = 2` (8 prototypes affectifs primaires) reçoivent une discrétisation canonique ; pour `Z ≥ 3`, les étiquettes sont de simples repères illustratifs non normatifs (aucune nomenclature bijective fermée).
- **Annexes exploratoires :** Rétrogradation intégrale hors du corps du manuscrit du pavage à 176 cases (dont `Z = 6` Identités affectives et `Z = 7` Sentiments transcendantaux), de `Cartograffect/Lexicon176.lean`, des extensions *in silico* DSM-5 et de la vitrine multi-prouveurs.

---

**Validation Phase 0 (Go/No-Go) :** Approuvé sans réserve par l'auteur (Manuel Cabelguen, 2026-11-25) comme référentiel normatif irréversible de la refonte v3.0.

---

## Addenda de consolidation v3.0 (pré-release — 2026-11-27)

En cohérence stricte avec les quatre arbitrages de Phase 0 ci-dessus, la consolidation pré-release v3.0 acte trois précisions normatives :

1. **Bijection $2 \times 2$ de Rolls (2014) et prototype `Calme` (`Z = 2`) :** Les quatre diagonales de `Z = 2` réalisent la bijection exacte `Rew+` (*Désir* `(+1,+1,2)`), `Rew−` (*Colère* `(-1,+1,2)`), `Pun+` (*Dégoût* `(-1,-1,2)`) et `Pun−` (*Calme* `(+1,-1,2)`), bornée strictement à `Z = 2` et terminologiquement dissociée du renforcement négatif skinnerien (`R−`). Le prototype `(+1, -1, 2)` est nommé **Calme** (retrait définitif de « adaptatif »).
2. **Géométrie en couches planes à surface remplie (`|x| + |y| ≤ R(Z)`) et frontière de capacité (`A = 1`) :** Chaque couche $Z \ge 2$ déploie une surface pleine $|x| + |y| \le R(Z)$ structurée radialement par le canal d'activation autonome $A \in (0, 1]$ (`A = 1` correspondant à la frontière de saturation/capacité $|x| + |y| = 2z - 2$ certifiée dans `Cartograffect/CoreAffect.lean`, et `A < 1` à la surface intérieure sous-saturée).
3. **Correspondance 1-à-1 entre les 17 `FunctionalSubsector` Lean 4 et le Tableau 1b :** Les 17 constructeurs de `FunctionalSubsector` (`Cartograffect/AffectiveTaxonomy.lean`), joints aux théorèmes `contralateral_swaps_amplitudes` (`Cartograffect/AffectiveMatrix.lean`) et `contralateral_group_bindings` (`Cartograffect/AffectiveTaxonomy.lean`), correspondent 1-à-1 au centre fixe `(0, 0, Z)` et aux **8 paires antagonistes conjuguées** (`A1, A2, D1, D2` et `L1, L2, L3, L4`) du Tableau 1b (`docs/01-Article_Cartograffect.md`), avec échange $|X| \leftrightarrow |Y|$ découplé de $A' = A$.
