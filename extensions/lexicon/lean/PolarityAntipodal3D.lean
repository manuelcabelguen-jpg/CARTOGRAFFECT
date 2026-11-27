/-
================================================================================
Projet CARTOGRAFFECT — Lemmes d'Équipartition et d'Antipodalité 3D (Strate 1)
Fichier : extensions/lexicon/lean/PolarityAntipodal3D.lean
================================================================================
Formalisation et certification mécanique (zéro `sorry`, Lean 4.35.0 standard)
des 4 théorèmes exploratoires sur la polarité hémisphérique 3D (`polarity3D`)
et l'opposition antipodale verticale (`zAntipodal3D`) extraits du pipeline
lexical et rattachés directement au répertoire canonique `Cartograffect.Lexicon176`
de la Strate 0 (176 états, Z = 0 : `"Point de Veille"`).

Ces lemmes résident dans `extensions/lexicon/lean/` (Strate 1) afin de préserver
strictement la séparation d'avec le cœur normatif v3.0.0 (`Cartograffect/`).

Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
SPDX-License-Identifier: AGPL-3.0-or-later
================================================================================
-/

import Cartograffect.PredictiveEngine
import Cartograffect.CoreAffect
import Cartograffect.AffectiveMatrix
import Cartograffect.AffectiveTaxonomy
import Cartograffect.Lexicon176

namespace Cartograffect.Validation.PolarityAntipodal3D

open Cartograffect.PredictiveEngine
open Cartograffect.CoreAffect
open Cartograffect.AffectiveMatrix
open Cartograffect.AffectiveTaxonomy
open Cartograffect.Lexicon176

/-- Polarité hémisphérique 3D canonique (+1 : Approche / Expansion, -1 : Évitement / Rétraction). -/
def polarity3D (p : CoreAffectPoint) : Int :=
  if p.x > 0 then 1
  else if p.x < 0 then -1
  else if p.y > 0 then 1
  else if p.y < 0 then -1
  else 1

/-- Coordonnée verticale signée Z_antipodal_3D = polarity3D(p) * Z. -/
def zAntipodal3D (p : CoreAffectPoint) : Int :=
  polarity3D p * (p.z : Int)

/-- Prédicat booléen identifiant les 168 prototypes périphériques (hors opérateurs centraux). -/
def isPeripheral (p : CoreAffectPoint) : Bool :=
  !(p.x == 0 && p.y == 0)

/-- Prédicat booléen identifiant les 48 prototypes axiaux et diagonaux purs. -/
def isAxialOrDiagonal (p : CoreAffectPoint) : Bool :=
  isPeripheral p && (p.x == 0 || p.y == 0 || p.x.natAbs == p.y.natAbs)

set_option maxRecDepth 2000000
set_option maxHeartbeats 4000000

/-- Certification mécanique de l'équipartition 84 / 84 en polarité +Z des 168 prototypes périphériques. -/
theorem all176Entries_peripheral_polarity_pos_count :
    (all176Entries.filter (fun e => isPeripheral e.point && polarity3D e.point == 1)).length = 84 := by decide

/-- Certification mécanique de l'équipartition 84 / 84 en polarité -Z des 168 prototypes périphériques. -/
theorem all176Entries_peripheral_polarity_neg_count :
    (all176Entries.filter (fun e => isPeripheral e.point && polarity3D e.point == -1)).length = 84 := by decide

/-- Certification mécanique de l'invariance antipodale verticale Z_A + Z_B = 0 sur les 168 prototypes périphériques. -/
theorem all176Entries_peripheral_z_antipodal_sum_zero :
    (all176Entries.all (fun e =>
      !isPeripheral e.point || (zAntipodal3D e.point + zAntipodal3D (antagonistPoint e.point) == 0))) = true := by decide

/-- Certification mécanique de l'opposition antipodale 3D stricte P + P* = (0, 0, 0) sur les 48 pôles axiaux et diagonaux. -/
theorem all176Entries_axial_diag_strict_3d_antipodal :
    (all176Entries.all (fun e =>
      !isAxialOrDiagonal e.point ||
        (let q := antagonistPoint e.point
         e.point.x + q.x == 0 && e.point.y + q.y == 0 && zAntipodal3D e.point + zAntipodal3D q == 0))) = true := by decide

/-!
## Audit axiomatique (#print axioms)
-/

#print axioms all176Entries_peripheral_polarity_pos_count
#print axioms all176Entries_peripheral_polarity_neg_count
#print axioms all176Entries_peripheral_z_antipodal_sum_zero
#print axioms all176Entries_axial_diag_strict_3d_antipodal

end Cartograffect.Validation.PolarityAntipodal3D
