# CARTOGRAFFECT — Formal Verification in Lean 4.35.0

[![Lean 4 Formal Verification](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/lean.yml/badge.svg)](https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/actions/workflows/lean.yml)
![Lean 4.35.0](https://img.shields.io/badge/Lean-v4.35.0-blue?logo=lean)
![Zero Sorry](https://img.shields.io/badge/Proof_Audit-0_sorry_%7C_0_custom_axioms-success)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

Ce dépôt contient la formalisation mathématique et la preuve assistée par ordinateur sous **Lean 4 (v4.35.0)** de l'architecture fonctionnelle de la **Cartographie des affects**, ainsi que le référentiel algorithmique complet des **176 positions de l'espace affectif ($Z = 0$ à $Z = 7$)**.

---

## Architecture des Modules Certifiés

1. **[`Cartograffect/PredictiveEngine.lean`](Cartograffect/PredictiveEngine.lean)** : Formalisation de l'écart de prédiction saillant (avec hystérésis de résorption), des trois interfaces (Perceptive, Subjective, Attentionnelle), des régimes de charge/décharge et de la partition des 9 couplages $(A/C)$.
2. **[`Cartograffect/CoreAffect.lean`](Cartograffect/CoreAffect.lean)** : Projection spatiale tridimensionnelle $(X, Y, Z)$, opérateurs centraux ($Z = 0$ à $Z = 7$), loi géométrique des couronnes ($R(Z) = 2Z - 2$ pour $Z \ge 2$), conservation du budget attentionnel, réallocation axiale $\to$ diagonale et dissipation allostatique graduelle vers le Point de Veille $(0, 0, 0)$.
3. **[`Cartograffect/AffectiveMatrix.lean`](Cartograffect/AffectiveMatrix.lean)** : Transduction phénoménologique (valence et activation), formalisation des 8 prototypes de la première couronne ($Z = 2$) et preuve d'involutivité de l'opérateur d'antagonisme (symétrie centrale axiale/diagonale et réflexion diagonale controlatérale pour $Z \ge 3$).
4. **[`Cartograffect/AffectiveTaxonomy.lean`](Cartograffect/AffectiveTaxonomy.lean)** : Partition exhaustive et mutuellement exclusive des 9 groupes d'orientation, certification arithmétique des 176 entrées ($8 \text{ centres} + 168 \text{ positions périphériques}$) et démonstration du théorème maître `end_to_end_coherence`.
5. **[`Cartograffect/Lexicon176.lean`](Cartograffect/Lexicon176.lean)** : Répertoire nominal exhaustif des 176 positions affectives ($Z = 0$ à $Z = 7$) et vérification mécanique des 84 paires antagonistes axiales, diagonales et controlatérales.
6. **[`Cartograffect/AuditTests.lean`](Cartograffect/AuditTests.lean) & [`AUDIT_REPORT.md`](AUDIT_REPORT.md)** : Audit axiomatique (`#print axioms`), tests d'évaluation constructive (`#eval`) et certificat d'audit formel complet.

---

## Vérification Formelle & Audit des Axiomes

Le projet est certifié sous **Lean 4.35.0** avec le système de build Lake 5.0.0 (`lake build`, compilation stricte).
L'audit continu ([`Cartograffect/AuditTests.lean`](Cartograffect/AuditTests.lean)) inspecte via `#print axioms` l'ensemble des théorèmes du système à chaque run d'Intégration Continue (CI) et en local, attestant de **0 `sorry`**, **0 `admit`**, et de l'**absence totale d'axiome non standard ou personnalisé**.

### Tableau récapitulatif de l'audit des théorèmes (`Cartograffect/AuditTests.lean`)

#### 1. Théorèmes purement constructifs (0 axiome, `[none]`)

| Théorème certifié | Dépendances axiomatiques (`#print axioms`) | Classification logique |
|---|---|---|
| `Cartograffect.PredictiveEngine.Polarity.invert_involutive` | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |
| `Cartograffect.PredictiveEngine.coupling_regime_partition` | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |
| `Cartograffect.CoreAffect.z2_budget_conservation` | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |
| `Cartograffect.AffectiveMatrix.contralateral_swaps_amplitudes` | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |
| `Cartograffect.AffectiveTaxonomy.inventory_176_certified` | `[none]` *(0 axiome)* | **Purement constructif** (`does not depend on any axioms`) |

#### 2. Théorèmes reposant uniquement sur les axiomes standards des fondations de Lean (`propext`, `Quot.sound`, `Classical.choice`)

| Théorème certifié | Dépendances axiomatiques (`#print axioms`) | Classification logique |
|---|---|---|
| `Cartograffect.CoreAffect.engine_induces_valid_core_affect` | `propext`, `Quot.sound` | **Fondations standard de Lean** |
| `Cartograffect.AffectiveTaxonomy.taxonomy_group_exclusive` | `propext`, `Quot.sound` | **Fondations standard de Lean** |
| `Cartograffect.CoreAffect.axial_to_diagonal_reallocation` | `propext`, `Classical.choice`, `Quot.sound` | **Fondations classiques standard** |
| `Cartograffect.CoreAffect.dissipationStep_valid` | `propext`, `Classical.choice`, `Quot.sound` | **Fondations classiques standard** |
| `Cartograffect.AffectiveMatrix.antagonistPoint_preserves_validity` | `propext`, `Classical.choice`, `Quot.sound` | **Fondations classiques standard** |
| `Cartograffect.AffectiveMatrix.antagonistPoint_involutive` | `propext`, `Classical.choice`, `Quot.sound` | **Fondations classiques standard** |
| `Cartograffect.AffectiveTaxonomy.taxonomy_group_exhaustive` | `propext`, `Classical.choice`, `Quot.sound` | **Fondations classiques standard** |
| `Cartograffect.AffectiveTaxonomy.end_to_end_coherence` | `propext`, `Classical.choice`, `Quot.sound` | **Fondations classiques standard** *(Théorème Maître)* |

> **Note sur le socle logique :**  
> `propext` (extensionalité des propositions), `Classical.choice` (principe du choix classique) et `Quot.sound` (exactitude des types quotients) constituent les axiomes fondamentaux standard du noyau de Lean 4. Le modèle CARTOGRAFFECT n'admet aucun axiome supplémentaire ni aucune dépendance externe (sans Mathlib).

---

## Reproductibilité (Compilation locale)

Prérequis : `elan` et `leanprover/lean4:v4.35.0`.

```bash
# Compilation de la bibliothèque et des preuves
lake build

# Exécution du banc d'audit axiomatique (#print axioms) et des tests (#eval)
lake env lean Cartograffect/AuditTests.lean
```

---

## Documentation associée

- **[`AUDIT_REPORT.md`](AUDIT_REPORT.md)** : Rapport complet d'audit de certification formelle et de fidélité épistémique (Phases 1 à 5).
- **[`docs/docs001-Article_Cartograffect.md.txt`](docs/docs001-Article_Cartograffect.md.txt)** : Article théorique de référence (fondements conceptuels et dynamiques).
- **[`docs/docs002-Inventaire_176.md.txt`](docs/docs002-Inventaire_176.md.txt)** : Inventaire exhaustif des 176 positions affectives et relations antagonistes.

---

## Auteur et Correspondance

Manuel Cabelguen, Ph. D.  
Correspondance : manuelcabelguen@gmail.com

---

## Licence

Ce projet (code source Lean 4 et documentation associée) est distribué sous licence MIT.  
Copyright (c) 2026 Manuel Cabelguen. Consultez le fichier [LICENSE](./LICENSE) pour le texte intégral.
