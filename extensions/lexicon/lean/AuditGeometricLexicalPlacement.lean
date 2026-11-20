/-
================================================================================
Projet CARTOGRAFFECT — Certification Formelle Lean 4
Fichier : Cartograffect/Validation/AuditGeometricLexicalPlacement.lean
================================================================================
Certification mécanique (zéro `sorry`, Lean 4.35.0 standard) de :
1. La séparation ontologique stricte entre colonne centrale (0, 0, Z) et couronnes.
2. La loi de conservation Manhattan L1 : |X| + |Y| = 2(Z - 1) pour Z ≥ 2.
3. La condition de parité paire : (X + Y) % 2 == 0.
4. La projection géométrique exacte du Nuancier de la Surprise (Corpus 2)
   vers les attracteurs de la Matrice Affective (Peur, Dégoût, Courage, Désir, Aplomb).

Auteur : Manuel Cabelguen / Antigravity (2026)
SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
================================================================================
-/

import Cartograffect.Lexicon176

namespace Cartograffect.Validation.GeometricAudit

/-- Point dans l'espace affectif (X : Attente/Valence, Y : Contrôle/Dominance, Z : Profondeur/Strate). -/
structure AffectivePoint where
  x : Int
  y : Int
  z : Nat
  deriving DecidableEq, Repr, Inhabited

/-- Norme L1 horizontale (|X| + |Y|). -/
def l1Displacement (p : AffectivePoint) : Nat :=
  p.x.natAbs + p.y.natAbs

/-- Rayon théorique L1 d'une strate Z : R_Z = 2(Z - 1) pour Z ≥ 2, et 0 pour Z ∈ {0, 1}. -/
def crownRadius (z : Nat) : Nat :=
  if z < 2 then 0 else 2 * (z - 1)

/-- Prédicat booléen d'appartenance à la colonne centrale des opérateurs fonctionnels (0, 0, Z). -/
def isCentralOperatorBool (p : AffectivePoint) : Bool :=
  p.x == 0 && p.y == 0

/-- Prédicat booléen de conformité sur couronne périphérique Z ≥ 2. -/
def isValidCrownPointBool (p : AffectivePoint) : Bool :=
  (p.z ≥ 2) && (l1Displacement p == crownRadius p.z)

/-- Prédicat booléen de parité paire : (X + Y) % 2 == 0. -/
def isEvenParityBool (p : AffectivePoint) : Bool :=
  (p.x + p.y) % 2 == 0

/-!
### Définition des points projetés du Nuancier de la Surprise (Corpus 2)
-/

def ptChoc : AffectivePoint := ⟨-2, 0, 2⟩              -- Peur (-2, 0, 2)
def ptSursaut : AffectivePoint := ⟨-1, -1, 2⟩           -- Dégoût (-1, -1, 2)
def ptEtonnement : AffectivePoint := ⟨2, 0, 2⟩          -- Courage (2, 0, 2)
def ptSerieExpressive : AffectivePoint := ⟨3, 1, 3⟩     -- Aplomb (3, 1, 3) (Strate supérieure 3:1)
def ptSurpris : AffectivePoint := ⟨2, 0, 2⟩             -- Courage (2, 0, 2)
def ptSurprise : AffectivePoint := ⟨2, 0, 2⟩            -- Courage (2, 0, 2)
def ptSurprises : AffectivePoint := ⟨3, 1, 3⟩           -- Aplomb (3, 1, 3)
def ptSurprendre : AffectivePoint := ⟨3, 1, 3⟩          -- Aplomb (3, 1, 3)
def ptEtonner : AffectivePoint := ⟨1, 1, 2⟩             -- Désir (1, 1, 2)
def ptSurprenant : AffectivePoint := ⟨1, 1, 2⟩          -- Désir (1, 1, 2)

def corpus2Points : List AffectivePoint := [
  ptChoc, ptSursaut, ptEtonnement, ptSerieExpressive,
  ptSurpris, ptSurprise, ptSurprises, ptSurprendre,
  ptEtonner, ptSurprenant
]

/-- Théorème 1 : Certification de la conformité sur couronne L1 de chaque projection du Corpus 2. -/
theorem corpus2_all_valid_crown_points :
    (corpus2Points.all isValidCrownPointBool) = true := by
  decide

/-- Théorème 2 : Certification de la parité paire (X + Y) % 2 == 0 pour l'ensemble des projections. -/
theorem corpus2_all_even_parity :
    (corpus2Points.all isEvenParityBool) = true := by
  decide

/-- Théorème 3 : Certification de stricte non-centralité (séparation ontologique centre vs couronnes). -/
theorem corpus2_none_central :
    (corpus2Points.all (fun p => !isCentralOperatorBool p)) = true := by
  decide

/-- Théorème 4 : Certification de conservation L1 exacte (|X| + |Y| = 2(Z - 1)) pour tous les prototypes. -/
theorem corpus2_exact_conservation :
    (corpus2Points.all (fun p => l1Displacement p == 2 * (p.z - 1))) = true := by
  decide

end Cartograffect.Validation.GeometricAudit
