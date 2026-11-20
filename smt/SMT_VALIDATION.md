# SMT_VALIDATION — Validation croisée formelle isolée (SMT-LIB 2.6 / Z3 5.3.3)

**Projet :** CARTOGRAFFECT — *Cartographie des affects*  
**Date :** 2026-11-19  
**Statut :** ✅ **CERTIFIÉ (8 / 8 `[CONSISTENCY] = sat`, 113 / 113 `[THM] = unsat`, 11 / 11 `[EVAL] = unsat`, 0 `unknown`, 0 `timeout`)**

---

## 1. Garantie d'isolation stricte

L'intégralité du développement SMT-LIB 2.6 est confinée dans [`smt/`](.) :
- [`smt/.gitignore`](.gitignore)
- [`smt/verify.ps1`](verify.ps1)
- [`smt/theories/`](theories/) (8 fichiers autonomes directement exécutables par `z3 -smt2`)
- [`.github/workflows/smt-ci.yml`](../.github/workflows/smt-ci.yml)

Aucun fichier des formalisations Lean 4, Rocq 9, Dafny, TLA+ ou Agda, ni du moteur Python n'est altéré.

---

## 2. Environnement et discipline de preuve SMT-LIB 2.6

| Composant / Contrôle | Résultat observé |
|---|---|
| Solveur SMT | **Z3 version 5.3.3 - 64 bit** (`build hashcode 430d19e697e2ec9bad79ff210d41b4a7a5fcfa3e`) |
| Logique et standard | **SMT-LIB 2.6 (`(set-logic ALL)`, 0 dépendance externe)** |
| Contrôle de non-vacuité | **8 / 8** fichiers vérifient d'abord `[CONSISTENCY] → sat` avant toute réfutation, prouvant la satisfiabilité des invariants de domaine et des fonctions d'hystérésis `thetaDown < thetaUp` |
| Contrôle statique | **0** mot-clé interdit (`sorry`, `admit`, `Admitted`, `cheat`, `assert false` hors réfutation `(push)/(pop)`) |
| Théorèmes certifiés (`[THM]`) | **113 / 113** réfutations exactes **`unsat`** (0 `sat`, 0 `unknown`, 0 `timeout`) |
| Lois structurelles auxiliaires (`[AUX]`) | **1 / 1** (`canonicalDepthKernel_laws` : 4 axiomes de `DepthTransitionKernel`) **`unsat`** |
| Évaluations concrètes (`[EVAL]`) | **11 / 11** blocs d'évaluation **`unsat`** + concordance bit à bit des `[VALUES]` |
| Durée totale (`verify.ps1`) | **14,50 s** |

---

## 3. Modules validés et temps d'exécution mesurés

| # | Fichier SMT-LIB 2.6 (`smt/theories/`) | Équivalent Lean 4 / Rocq | Lignes | Théorèmes (`[THM]`) | Contrôles | Temps (`verify.ps1`) |
|---|---|---|---|---|---|---|
| 1 | [`01_PredictiveEngine.smt2`](theories/01_PredictiveEngine.smt2) | `PredictiveEngine` | 320 | 7 / 7 `unsat` | 1 `sat` | 0,06 s |
| 2 | [`02_CoreAffect.smt2`](theories/02_CoreAffect.smt2) | `CoreAffect` | 621 | 23 / 23 `unsat` | 1 `sat` | 0,50 s |
| 3 | [`03_AffectiveMatrix.smt2`](theories/03_AffectiveMatrix.smt2) | `AffectiveMatrix` | 393 | 13 / 13 `unsat` | 1 `sat` | 0,32 s |
| 4 | [`04_AffectiveTaxonomy.smt2`](theories/04_AffectiveTaxonomy.smt2) | `AffectiveTaxonomy` | 569 | 10 / 10 `unsat` | 1 `sat` | 0,28 s |
| 5 | [`05_AffectiveDynamics.smt2`](theories/05_AffectiveDynamics.smt2) | `AffectiveDynamics` | 345 | 10 / 10 `unsat` | 1 `sat` + 1 `[AUX] unsat` | 0,18 s |
| 6 | [`06_Lexicon176.smt2`](theories/06_Lexicon176.smt2) | `Lexicon176` | 1 019 | 8 / 8 `unsat` | 1 `sat` | 11,21 s |
| 7 | [`07_PredictiveCircuit.smt2`](theories/07_PredictiveCircuit.smt2) | `PredictiveCircuit` | 982 | 41 / 41 `unsat` | 1 `sat` | 1,82 s |
| 8 | [`08_AuditTests.smt2`](theories/08_AuditTests.smt2) | `AuditTests` | 750 | 1 / 1 `unsat` | 1 `sat` + 11 `[EVAL] unsat` | 0,05 s |
| **Total** | **8 fichiers autonomes `.smt2`** | **Modules 1 à 8** | **4 999** | **113 / 113** | **8 `sat` + 12 `unsat`** | **14,50 s** |

---

## 4. Transposition logique et couverture inductive

1. **Fonctions non interprétées pour les paramètres d'ordre supérieur (R3, R5) :**
   - Dans [`03_AffectiveMatrix.smt2`](theories/03_AffectiveMatrix.smt2), deux mappings arbitraires `(m1_*, m2_*)` sont déclarés par `declare-fun` non interprétés afin d'établir `evaluateMatrix_core_antagonist_independent` et `mapping_independent_antagonist_invariants`.
   - Dans [`07_PredictiveCircuit.smt2`](theories/07_PredictiveCircuit.smt2), `thetaUp` et `thetaDown` sont déclarées non interprétées sous l'unique contrainte $\forall z \ge 0,\; 0 \le \theta_{\downarrow}(z) < \theta_{\uparrow}(z)$ (`[CONSISTENCY] = sat`).
2. **Témoins constructifs de Skolem et obligations d'induction :**
   - Pour `dissipation_reaches_veille` ([`02_CoreAffect.smt2`](theories/02_CoreAffect.smt2)) et `lateral_reachable_from_surprise` ([`05_AffectiveDynamics.smt2`](theories/05_AffectiveDynamics.smt2)), la logique du premier ordre SMT-LIB 2.6 ne disposant pas de schéma d'induction structurelle natif, les preuves vérifient **conjointement** les cas de base, le pas inductif universel sur tout $\mathbb{Z}$ (avec témoin explicite `predForCrown` pour les antécédents inter-strates et `witnessSuccForPoint` pour `outgoingWeight_pos`) et l'évaluation récursive complète sur toutes les strates $Z = 0 \dots 7$.
3. **Arithmétique entière non linéaire exacte :**
   - Z3 5.3.3 décharge directement en `unsat` les identités polynomiales de degré 6 (`circuitRowSum_exact` = $4 \cdot \mathrm{scale}^6$, `lyapunov_expected_drift_constant`), la division entière symbolique (`apportionRay_exact`, `charge_accumulator_bounded`, `symmetricSigmoid_sum`/`pos`) et l'ensemble des 176 entrées du lexique (`all176Entries_spatial_completeness`, `all176Entries_unique_points`, `all176Entries_closed_under_antagonist`).

---

## 5. Reproduction locale autonome

Depuis la racine du dépôt :

```powershell
powershell -ExecutionPolicy Bypass -File smt/verify.ps1
```

*(Option `-Z3Bin <chemin>` si `z3.exe` se trouve à un autre emplacement que `C:\Users\drcab\.local\tools\z3\z3-5.3.3-x64-win\bin` ou `PATH`.)*
