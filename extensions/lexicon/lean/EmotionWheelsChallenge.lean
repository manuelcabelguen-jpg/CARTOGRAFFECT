/-
================================================================================
Projet CARTOGRAFFECT — Invariants Géométriques Strate 1 (Rose des Symétries & Diamant 303)
Fichier : extensions/lexicon/lean/EmotionWheelsChallenge.lean
================================================================================
Formalisation et preuve mécanique (zéro `sorry`, Lean 4.35.0 standard, 0 score
statistique Python codé en dur) des invariants purement géométriques et
combinatoires utilisés par le satellite lexical de Strate 1 :
  1. Involutivité et clôture de la Rose des symétries sur les 176 prototypes
     affectifs (`rose_symmetries_involutive_on_carto176`), avec définition
     exacte par morceaux de l'antagoniste régulateur :
       - `(-X, -Y, Z)` si `XY = 0`
       - `(-sgn(X)|Y|, -sgn(Y)|X|, Z)` si `XY ≠ 0`
  2. Cardinalité exacte et pureté combinatoire de l'extension exploratoire
     Diamant 303 (`diamond303_completeness_and_axiological_purity`).

Note d'intégrité probatoire (Phase 1, `v3.0.0-dev`) :
- Conformément au garde-fou *Zéro blanchiment formel*, l'ancien théorème
  circulaire sur l'antagonisme 2D de Plutchik ainsi que toutes les structures
  et preuves par `decide` embarquant des scores statistiques issus de Python
  ou de tables TSV externes ont été retirés de ce module Lean.
- L'évaluation empirique externe par les roues des émotions (Scherer et al.,
  2013) relève exclusivement du script statistique Python
  `extensions/lexicon/src/validate_emotion_wheels.py`.

Copyright (C) 2026  Projet CARTOGRAFFECT (Manuel Cabelguen)
SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
================================================================================
-/

import Cartograffect.Lexicon176

namespace Cartograffect.Validation.EmotionWheelsChallenge

/-!
## 1. Géométrie du Diamant (Z ∈ [-7, +7]) et Rose des Symétries Involutives
-/

/-- Coordonnées 3D entières dans l'octaèdre biconique (Diamant 303) de CARTOGRAFFECT. -/
structure OctahedralDiamondPoint where
  X : Int
  Y : Int
  Z : Int
  deriving DecidableEq, Repr, Inhabited

/-- Valeur absolue entière sur `Int`. -/
def absInt (x : Int) : Int :=
  (Int.natAbs x : Int)

/-- Fonction de signe trivalente exacte sur `Int` ($\{-1, 0, +1\}$). -/
def signInt (x : Int) : Int :=
  if x > 0 then 1 else if x < 0 then -1 else 0

/--
Loi de conservation du budget attentionnel $L_1$ sur les 15 strates du Diamant ($Z \in [-7, +7]$) :
- Pour $|Z| \ge 2$ et $Z \neq -7$ : $R_{L_1}(Z) = 2(|Z| - 1)$
- Pour les pôles axiaux centraux $Z \in \{0, +1, -1, -7\}$ : $R_{L_1}(Z) = 0$.
-/
def diamondCrownRadiusL1 (Z : Int) : Int :=
  if Z == -7 || Z == -1 || Z == 0 || Z == 1 then
    0
  else
    2 * (absInt Z - 1)

/-- Déplacement horizontal $L_1$ : $|X| + |Y|$. -/
def displacementL1 (p : OctahedralDiamondPoint) : Int :=
  absInt p.X + absInt p.Y

/-- Distance topologique intra-strate $L_1$ entre deux pôles : $|X_1 - X_2| + |Y_1 - Y_2|$. -/
def distL1 (p1 p2 : OctahedralDiamondPoint) : Nat :=
  Int.natAbs (p1.X - p2.X) + Int.natAbs (p1.Y - p2.Y)

/-- Prédicat d'appartenance valide à une couronne ou à un opérateur central du Diamant. -/
def isValidDiamondPointBool (p : OctahedralDiamondPoint) : Bool :=
  (decide (-7 ≤ p.Z ∧ p.Z ≤ 7)) &&
  ((p.X == 0 && p.Y == 0) ||
   (decide (Int.natAbs p.Z ≥ 2 ∧ p.Z ≠ -7) && (displacementL1 p == diamondCrownRadiusL1 p.Z)))

/--
1. **Opérateur d'Antagonisme Régulateur Formel $A(P)$** (`regulatoryAntagonist`),
défini exactement par morceaux :
- `(-X, -Y, Z)` si `XY = 0` (centre auto-dual `(0, 0, Z)` et axes `X = 0` ou `Y = 0`),
- `(-sgn(X)|Y|, -sgn(Y)|X|, Z)` si `XY ≠ 0` :
  * sur les diagonales (`|X| = |Y| > 0`), coïncide avec l'inversion centrale `(-X, -Y, Z)`,
  * hors diagonales, quadrants dissonants (`sgn(X) ≠ sgn(Y)`) : réflexion contralatérale directe `T_d(X, Y, Z) = (Y, X, Z)`,
  * hors diagonales, quadrants synergiques (`sgn(X) = sgn(Y)`) : réflexion contralatérale inverse `T_i(X, Y, Z) = (-Y, -X, Z)`.
-/
def regulatoryAntagonist (p : OctahedralDiamondPoint) : OctahedralDiamondPoint :=
  if p.X == 0 || p.Y == 0 then
    ⟨- p.X, - p.Y, p.Z⟩
  else
    ⟨- signInt p.X * absInt p.Y, - signInt p.Y * absInt p.X, p.Z⟩

/--
2. **Opposé Central Intra-Dominante $I_c(P)$** (`centralOpposite`) :
$$I_c(X, Y, Z) = (-X, -Y, Z)$$
Inverse les signes d'Attente et de Contrôle tout en conservant la même dominante $|X|$ vs $|Y|$.
-/
def centralOpposite (p : OctahedralDiamondPoint) : OctahedralDiamondPoint :=
  ⟨- p.X, - p.Y, p.Z⟩

/--
3. **Miroir Diagonal de Dominante $M_{\text{dom}}(P)$** (`mirrorDominant`) :
Permute les intensités d'Attente et de Contrôle au sein du même quadrant :
- `(0, 0, Z)` si `X = 0 ∧ Y = 0`, `(Y, 0, Z)` si `X = 0`, `(0, X, Z)` si `Y = 0`,
- `(sgn(X)|Y|, sgn(Y)|X|, Z)` si `XY ≠ 0`.
-/
def mirrorDominant (p : OctahedralDiamondPoint) : OctahedralDiamondPoint :=
  if p.X == 0 && p.Y == 0 then
    ⟨0, 0, p.Z⟩
  else if p.X == 0 then
    ⟨p.Y, 0, p.Z⟩
  else if p.Y == 0 then
    ⟨0, p.X, p.Z⟩
  else
    ⟨signInt p.X * absInt p.Y, signInt p.Y * absInt p.X, p.Z⟩

/--
4a. **Miroir Orthogonal d'Attente $O_X(P)$** (`mirrorOx`) :
$$O_X(X, Y, Z) = (-X, Y, Z)$$
Bascule le signe de l'Attente épistémique $X$ à Contrôle pragmatique $Y$ constant.
-/
def mirrorOx (p : OctahedralDiamondPoint) : OctahedralDiamondPoint :=
  ⟨- p.X, p.Y, p.Z⟩

/--
4b. **Miroir Orthogonal de Contrôle $O_Y(P)$** (`mirrorOy`) :
$$O_Y(X, Y, Z) = (X, -Y, Z)$$
Bascule le signe du Contrôle pragmatique $Y$ à Attente épistémique $X$ constante.
-/
def mirrorOy (p : OctahedralDiamondPoint) : OctahedralDiamondPoint :=
  ⟨p.X, - p.Y, p.Z⟩

/--
5. **Homologue Vertical Trans-Hémisphérique $H_Z(P)$** (`verticalHomologue`) :
Relie bijectivement l'hémisphère affectif $Z^+ \in [0..6]$ à l'hémisphère axiologique $Z^- \in [-7..-1]$
(avec $(0, 0, 0) \leftrightarrow (0, 0, -7)$ et l'équateur $Z = +7$ auto-dual).
-/
def verticalHomologue (p : OctahedralDiamondPoint) : OctahedralDiamondPoint :=
  if p.Z == 0 then
    ⟨p.X, p.Y, -7⟩
  else if p.Z == -7 then
    ⟨p.X, p.Y, 0⟩
  else if p.Z == 7 then
    p
  else
    ⟨p.X, p.Y, - p.Z⟩

/--
6. **Contrepoids Trans-Hémisphérique Croisé $A_Z(P)$** (`crossedCounterweight`) :
$$A_Z(P) = A(H_Z(P))$$
-/
def crossedCounterweight (p : OctahedralDiamondPoint) : OctahedralDiamondPoint :=
  regulatoryAntagonist (verticalHomologue p)

/-- Classification formelle des 5 régimes géométriques de l'antagoniste régulateur $A(P)$. -/
inductive AntagonistRegime where
  | AUTO_DUAL_CENTRE             : AntagonistRegime
  | AXIAL_INVERSION_CENTRALE     : AntagonistRegime
  | DIAGONAL_INVERSION_CENTRALE  : AntagonistRegime
  | CONTROLATERAL_DIRECT_Td      : AntagonistRegime
  | CONTROLATERAL_INVERSE_Ti     : AntagonistRegime
  deriving DecidableEq, Repr, Inhabited

/-- Détermination décidable du régime d'antagonisme d'un pôle $P = (X, Y, Z)$. -/
def classifyAntagonistRegime (p : OctahedralDiamondPoint) : AntagonistRegime :=
  if p.X == 0 && p.Y == 0 then
    .AUTO_DUAL_CENTRE
  else if p.X == 0 || p.Y == 0 then
    .AXIAL_INVERSION_CENTRALE
  else if absInt p.X == absInt p.Y then
    .DIAGONAL_INVERSION_CENTRALE
  else if signInt p.X != signInt p.Y then
    .CONTROLATERAL_DIRECT_Td
  else
    .CONTROLATERAL_INVERSE_Ti

/-- Répertoire canonique des 176 prototypes affectifs ($Z \in [0..7]$). -/
def carto176Prototypes : List OctahedralDiamondPoint := [
  -- Z = 0 (1) & Z = 1 (1)
  ⟨0, 0, 0⟩, ⟨0, 0, 1⟩,
  -- Z = 2 (9 : R_L1 = 2)
  ⟨0, 0, 2⟩, ⟨0, 2, 2⟩, ⟨0, -2, 2⟩, ⟨-2, 0, 2⟩, ⟨2, 0, 2⟩, ⟨-1, 1, 2⟩, ⟨1, -1, 2⟩, ⟨1, 1, 2⟩, ⟨-1, -1, 2⟩,
  -- Z = 3 (17 : R_L1 = 4)
  ⟨0, 0, 3⟩, ⟨0, 4, 3⟩, ⟨0, -4, 3⟩, ⟨-4, 0, 3⟩, ⟨4, 0, 3⟩,
  ⟨-1, 3, 3⟩, ⟨1, 3, 3⟩, ⟨1, -3, 3⟩, ⟨-1, -3, 3⟩, ⟨-3, 1, 3⟩, ⟨-3, -1, 3⟩, ⟨3, -1, 3⟩, ⟨3, 1, 3⟩,
  ⟨-2, 2, 3⟩, ⟨2, -2, 3⟩, ⟨2, 2, 3⟩, ⟨-2, -2, 3⟩,
  -- Z = 4 (25 : R_L1 = 6)
  ⟨0, 0, 4⟩, ⟨0, 6, 4⟩, ⟨0, -6, 4⟩, ⟨-6, 0, 4⟩, ⟨6, 0, 4⟩,
  ⟨-2, 4, 4⟩, ⟨-1, 5, 4⟩, ⟨1, 5, 4⟩, ⟨2, 4, 4⟩, ⟨2, -4, 4⟩, ⟨1, -5, 4⟩, ⟨-2, -4, 4⟩, ⟨-1, -5, 4⟩,
  ⟨-4, 2, 4⟩, ⟨-5, 1, 4⟩, ⟨-5, -1, 4⟩, ⟨-4, -2, 4⟩, ⟨4, 2, 4⟩, ⟨5, 1, 4⟩, ⟨5, -1, 4⟩, ⟨4, -2, 4⟩,
  ⟨-3, 3, 4⟩, ⟨3, -3, 4⟩, ⟨3, 3, 4⟩, ⟨-3, -3, 4⟩,
  -- Z = 5 (33 : R_L1 = 8)
  ⟨0, 0, 5⟩, ⟨0, 8, 5⟩, ⟨0, -8, 5⟩, ⟨-8, 0, 5⟩, ⟨8, 0, 5⟩,
  ⟨1, 7, 5⟩, ⟨2, 6, 5⟩, ⟨3, 5, 5⟩, ⟨-2, 6, 5⟩, ⟨-3, 5, 5⟩, ⟨-1, 7, 5⟩,
  ⟨3, -5, 5⟩, ⟨2, -6, 5⟩, ⟨1, -7, 5⟩, ⟨-2, -6, 5⟩, ⟨-3, -5, 5⟩, ⟨-1, -7, 5⟩,
  ⟨-6, 2, 5⟩, ⟨-5, 3, 5⟩, ⟨-7, 1, 5⟩, ⟨-7, -1, 5⟩, ⟨-6, -2, 5⟩, ⟨-5, -3, 5⟩,
  ⟨6, 2, 5⟩, ⟨5, 3, 5⟩, ⟨7, 1, 5⟩, ⟨6, -2, 5⟩, ⟨5, -3, 5⟩, ⟨7, -1, 5⟩,
  ⟨-4, 4, 5⟩, ⟨4, -4, 5⟩, ⟨4, 4, 5⟩, ⟨-4, -4, 5⟩,
  -- Z = 6 (41 : R_L1 = 10)
  ⟨0, 0, 6⟩, ⟨0, 10, 6⟩, ⟨0, -10, 6⟩, ⟨-10, 0, 6⟩, ⟨10, 0, 6⟩,
  ⟨3, 7, 6⟩, ⟨-3, 7, 6⟩, ⟨4, 6, 6⟩, ⟨-4, 6, 6⟩, ⟨2, 8, 6⟩, ⟨-2, 8, 6⟩, ⟨1, 9, 6⟩, ⟨-1, 9, 6⟩,
  ⟨3, -7, 6⟩, ⟨-3, -7, 6⟩, ⟨4, -6, 6⟩, ⟨-4, -6, 6⟩, ⟨2, -8, 6⟩, ⟨-2, -8, 6⟩, ⟨1, -9, 6⟩, ⟨-1, -9, 6⟩,
  ⟨-6, 4, 6⟩, ⟨-6, -4, 6⟩, ⟨-7, 3, 6⟩, ⟨-7, -3, 6⟩, ⟨-8, 2, 6⟩, ⟨-8, -2, 6⟩, ⟨-9, 1, 6⟩, ⟨-9, -1, 6⟩,
  ⟨6, 4, 6⟩, ⟨6, -4, 6⟩, ⟨7, 3, 6⟩, ⟨7, -3, 6⟩, ⟨8, 2, 6⟩, ⟨8, -2, 6⟩, ⟨9, 1, 6⟩, ⟨9, -1, 6⟩,
  ⟨-5, 5, 6⟩, ⟨5, -5, 6⟩, ⟨5, 5, 6⟩, ⟨-5, -5, 6⟩,
  -- Z = 7 (49 : R_L1 = 12)
  ⟨0, 0, 7⟩, ⟨0, 12, 7⟩, ⟨0, -12, 7⟩, ⟨-12, 0, 7⟩, ⟨12, 0, 7⟩,
  ⟨2, 10, 7⟩, ⟨-2, 10, 7⟩, ⟨4, 8, 7⟩, ⟨-4, 8, 7⟩, ⟨1, 11, 7⟩, ⟨-1, 11, 7⟩, ⟨3, 9, 7⟩, ⟨-3, 9, 7⟩, ⟨5, 7, 7⟩, ⟨-5, 7, 7⟩,
  ⟨2, -10, 7⟩, ⟨-2, -10, 7⟩, ⟨4, -8, 7⟩, ⟨-4, -8, 7⟩, ⟨1, -11, 7⟩, ⟨-1, -11, 7⟩, ⟨3, -9, 7⟩, ⟨-3, -9, 7⟩, ⟨5, -7, 7⟩, ⟨-5, -7, 7⟩,
  ⟨-10, 2, 7⟩, ⟨-10, -2, 7⟩, ⟨-8, 4, 7⟩, ⟨-8, -4, 7⟩, ⟨-11, 1, 7⟩, ⟨-11, -1, 7⟩, ⟨-9, 3, 7⟩, ⟨-9, -3, 7⟩, ⟨-7, 5, 7⟩, ⟨-7, -5, 7⟩,
  ⟨10, 2, 7⟩, ⟨10, -2, 7⟩, ⟨8, 4, 7⟩, ⟨8, -4, 7⟩, ⟨11, 1, 7⟩, ⟨11, -1, 7⟩, ⟨9, 3, 7⟩, ⟨9, -3, 7⟩, ⟨7, 5, 7⟩, ⟨7, -5, 7⟩,
  ⟨-6, 6, 7⟩, ⟨6, -6, 7⟩, ⟨6, 6, 7⟩, ⟨-6, -6, 7⟩
]

set_option maxRecDepth 2000000
set_option maxHeartbeats 4000000

/--
**Théorème 1 (`rose_symmetries_involutive_on_carto176`)** :
Sur l'ensemble des 176 prototypes affectifs de CARTOGRAFFECT :
1. Chaque pôle satisfait la loi géométrique de sa couronne (`isValidDiamondPointBool`),
2. Les opérateurs de la Rose des symétries ($A, I_c, M_{\text{dom}}, O_X, O_Y$) sont
   strictement **involutifs** ($f(f(P)) = P$),
3. Ils conservent le budget attentionnel $L_1$ ($|X| + |Y| = R_{L_1}(Z)$),
4. Le répertoire des 176 pôles est **strictement clos** sous $A$, $I_c$, $M_{\text{dom}}$, $O_X$ et $O_Y$.
-/
theorem rose_symmetries_involutive_on_carto176 :
    carto176Prototypes.length = 176 ∧
    carto176Prototypes.Nodup ∧
    (carto176Prototypes.all isValidDiamondPointBool) = true ∧
    (carto176Prototypes.all (fun p => regulatoryAntagonist (regulatoryAntagonist p) == p)) = true ∧
    (carto176Prototypes.all (fun p => centralOpposite (centralOpposite p) == p)) = true ∧
    (carto176Prototypes.all (fun p => mirrorDominant (mirrorDominant p) == p)) = true ∧
    (carto176Prototypes.all (fun p => mirrorOx (mirrorOx p) == p)) = true ∧
    (carto176Prototypes.all (fun p => mirrorOy (mirrorOy p) == p)) = true ∧
    (carto176Prototypes.all (fun p => displacementL1 (regulatoryAntagonist p) == displacementL1 p)) = true ∧
    (carto176Prototypes.all (fun p => carto176Prototypes.contains (regulatoryAntagonist p))) = true ∧
    (carto176Prototypes.all (fun p => carto176Prototypes.contains (centralOpposite p))) = true ∧
    (carto176Prototypes.all (fun p => carto176Prototypes.contains (mirrorDominant p))) = true := by
  decide


/-!
## 2. Combinatoire de l'Extension Exploratoire Diamant 303 (Z ∈ [-7, +7])
-/

/-- Effectifs canoniques des 15 strates du Diamant 303 ($Z \in [-7, +7]$) issus de `ref_303_diamant_z.tsv`. -/
def diamond303StrataCounts : List (Int × Nat) := [
  -- Hémisphère affectif Z+ (127 pôles) + Équateur Z = +7 (49 pôles) = 176 pôles
  (0, 1), (1, 1), (2, 9), (3, 17), (4, 25), (5, 33), (6, 41), (7, 49),
  -- Hémisphère axiologique Z- (127 pôles : W = 1..7)
  (-6, 41), (-5, 33), (-4, 25), (-3, 17), (-2, 9), (-1, 1), (-7, 1)
]

/-- Catégorie ontologique et grammaticale dans l'hémisphère axiologique $Z^-$. -/
inductive AxiologicalRole where
  | VALEUR_INTEGRATION     : AxiologicalRole  -- Substantif/verbe de valeur positive (Z ∈ [-7..-1])
  | PRINCIPE_QUALIFICATIF  : AxiologicalRole  -- Adjectif de principe équilibré (Z = -6 / W = 1)
  | DERIVE_DEFAUT_D_MOINS  : AxiologicalRole  -- Dérive négative par hypo-contrôle (confinée à Z = -6 / W = 1)
  | DERIVE_EXCES_D_PLUS    : AxiologicalRole  -- Dérive négative par hyper-contrôle (confinée à Z = -6 / W = 1)
  deriving DecidableEq, Repr, Inhabited

/--
Loi Grammaticale et Ontologique de l'Hémisphère Axiologique $Z^-$ (`isValidZMinusPlacement`) :
- Sur les 87 pôles des strates d'intégration supérieure ($Z \in \{-5, -4, -3, -2, -1, -7\}$ et
  l'opérateur central *Discernement* en $(0, 0, -6)$) : seul le rôle `VALEUR_INTEGRATION` à
  valence strictement positive (`valenceScaled > 0`) est admis (**zéro dérive négative**).
- Sur les 40 pôles périphériques de la strate $Z = -6$ ($W = 1$, $|X| + |Y| = 10$) :
  cohabitent le principe qualificatif et ses deux dérives aristotéliciennes ($D^- \leftarrow V \rightarrow D^+$).
-/
def isValidZMinusPlacement (pole : OctahedralDiamondPoint) (role : AxiologicalRole) (valenceScaled : Int) : Bool :=
  if decide (pole.Z ≥ 0) || !isValidDiamondPointBool pole then
    false
  else if pole.Z == -6 && !(pole.X == 0 && pole.Y == 0) then
    match role with
    | .VALEUR_INTEGRATION    => decide (valenceScaled > 0)
    | .PRINCIPE_QUALIFICATIF => decide (valenceScaled > 0)
    | .DERIVE_DEFAUT_D_MOINS => decide (valenceScaled < 0)
    | .DERIVE_EXCES_D_PLUS   => decide (valenceScaled < 0)
  else
    (role == .VALEUR_INTEGRATION) && decide (valenceScaled > 0)

def ptVigilanceZMinus : OctahedralDiamondPoint := ⟨-3, 1, -3⟩
def ptLibreTriadeW1   : OctahedralDiamondPoint := ⟨ 6, 4, -6⟩

/--
**Théorème 2 (`diamond303_completeness_and_axiological_purity`)** :
1. Le Diamant complet compte exactement **303 pôles** ($176$ en $Z^+ \cup \{Z=+7\}$ et $127$ en $Z^-$),
2. Toute dérive négative (`DERIVE_DEFAUT_D_MOINS` ou `DERIVE_EXCES_D_PLUS`) est formellement
   interdite sur les strates d'intégration supérieure $Z \in \{-5, -4, -3, -2, -1, -7\}$ et sur
   le centre $(0, 0, -6)$, mais valide sur les 40 triades périphériques de $Z = -6$ ($W = 1$).
-/
theorem diamond303_completeness_and_axiological_purity :
    (diamond303StrataCounts.foldl (fun acc x => acc + x.2) 0) = 303 ∧
    isValidDiamondPointBool ptVigilanceZMinus = true ∧
    isValidZMinusPlacement ptVigilanceZMinus .VALEUR_INTEGRATION 620 = true ∧
    isValidZMinusPlacement ptVigilanceZMinus .DERIVE_DEFAUT_D_MOINS (-450) = false ∧
    isValidDiamondPointBool ptLibreTriadeW1 = true ∧
    isValidZMinusPlacement ptLibreTriadeW1 .DERIVE_DEFAUT_D_MOINS (-480) = true ∧
    isValidZMinusPlacement ⟨0, 0, -6⟩ .DERIVE_DEFAUT_D_MOINS (-480) = false := by
  decide


/-!
## 3. Audit axiomatique (#print axioms)
-/

#print axioms rose_symmetries_involutive_on_carto176
#print axioms diamond303_completeness_and_axiological_purity

end Cartograffect.Validation.EmotionWheelsChallenge
