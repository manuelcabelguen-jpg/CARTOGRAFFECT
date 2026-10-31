/-
Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
Author: Manuel Cabelguen
-/

import Cartograffect.PredictiveEngine
import Cartograffect.CoreAffect
import Cartograffect.AffectiveMatrix
import Cartograffect.AffectiveTaxonomy

namespace Cartograffect.Lexicon176

open PredictiveEngine
open CoreAffect
open AffectiveMatrix
open AffectiveTaxonomy

/-- Entrée lexicale associant un libellé phénoménologique à ses coordonnées (X, Y, Z). -/
structure LexiconEntry where
  label : String
  point : CoreAffectPoint
  deriving DecidableEq, Repr, Inhabited

/-- Accesseur direct pour la coordonnée X (Attente) d'une entrée lexicale. -/
abbrev LexiconEntry.x (e : LexiconEntry) : Int := e.point.x

/-- Accesseur direct pour la coordonnée Y (Contrôle) d'une entrée lexicale. -/
abbrev LexiconEntry.y (e : LexiconEntry) : Int := e.point.y

/-- Accesseur direct pour la coordonnée Z (Strate) d'une entrée lexicale. -/
abbrev LexiconEntry.z (e : LexiconEntry) : Nat := e.point.z

/-- Fonction booléenne décidable vérifiant la conformité géométrique d'un point (centre ou couronne). -/
def isValidPointBool (p : CoreAffectPoint) : Bool :=
  (p.x == 0 && p.y == 0) || (decide (p.z ≥ 2) && p.displacementSum == crownRadius p.z)

/-- Répertoire nominal exhaustif des 176 positions affectives de l'espace Cartograffect (Z = 0 à Z = 7). -/
def all176Entries : List LexiconEntry := [
  -- Strate Z = 0 (1 entrée)
  ⟨"Point de Veille", ⟨0, 0, 0⟩⟩,

  -- Strate Z = 1 (1 entrée)
  ⟨"Surprise", ⟨0, 0, 1⟩⟩,

  -- Strate Z = 2 (9 entrées : 1 centre, 4 axiales, 4 diagonales)
  ⟨"Anticipation", ⟨0, 0, 2⟩⟩,
  ⟨"Joie", ⟨0, 2, 2⟩⟩,
  ⟨"Tristesse", ⟨0, -2, 2⟩⟩,
  ⟨"Peur", ⟨-2, 0, 2⟩⟩,
  ⟨"Courage", ⟨2, 0, 2⟩⟩,
  ⟨"Colère", ⟨-1, 1, 2⟩⟩,
  ⟨"Calme", ⟨1, -1, 2⟩⟩,
  ⟨"Désir", ⟨1, 1, 2⟩⟩,
  ⟨"Dégoût", ⟨-1, -1, 2⟩⟩,

  -- Strate Z = 3 (17 entrées : 1 centre, 4 axiales, 8 latérales, 4 diagonales)
  ⟨"Émoi", ⟨0, 0, 3⟩⟩,
  ⟨"Enthousiasme", ⟨0, 4, 3⟩⟩,
  ⟨"Ennui", ⟨0, -4, 3⟩⟩,
  ⟨"Crainte", ⟨-4, 0, 3⟩⟩,
  ⟨"Curiosité", ⟨4, 0, 3⟩⟩,
  ⟨"Consternation", ⟨-1, 3, 3⟩⟩,
  ⟨"Euphorie", ⟨1, 3, 3⟩⟩,
  ⟨"Soulagement", ⟨1, -3, 3⟩⟩,
  ⟨"Chagrin", ⟨-1, -3, 3⟩⟩,
  ⟨"Panique", ⟨-3, 1, 3⟩⟩,
  ⟨"Effroi", ⟨-3, -1, 3⟩⟩,
  ⟨"Émerveillement", ⟨3, -1, 3⟩⟩,
  ⟨"Aplomb", ⟨3, 1, 3⟩⟩,
  ⟨"Exaspération", ⟨-2, 2, 3⟩⟩,
  ⟨"Détente", ⟨2, -2, 3⟩⟩,
  ⟨"Attrait", ⟨2, 2, 3⟩⟩,
  ⟨"Retrait", ⟨-2, -2, 3⟩⟩,

  -- Strate Z = 4 (25 entrées : 1 centre, 4 axiales, 16 latérales, 4 diagonales)
  ⟨"Réserve", ⟨0, 0, 4⟩⟩,
  ⟨"Exaltation", ⟨0, 6, 4⟩⟩,
  ⟨"Langueur", ⟨0, -6, 4⟩⟩,
  ⟨"Doute", ⟨-6, 0, 4⟩⟩,
  ⟨"Assurance", ⟨6, 0, 4⟩⟩,
  ⟨"Envie", ⟨-2, 4, 4⟩⟩,
  ⟨"Haine", ⟨-1, 5, 4⟩⟩,
  ⟨"Amour", ⟨1, 5, 4⟩⟩,
  ⟨"Ferveur", ⟨2, 4, 4⟩⟩,
  ⟨"Sérénité", ⟨2, -4, 4⟩⟩,
  ⟨"Plénitude", ⟨1, -5, 4⟩⟩,
  ⟨"Honte", ⟨-2, -4, 4⟩⟩,
  ⟨"Vide", ⟨-1, -5, 4⟩⟩,
  ⟨"Anxiété", ⟨-4, 2, 4⟩⟩,
  ⟨"Manque", ⟨-5, 1, 4⟩⟩,
  ⟨"Mépris", ⟨-5, -1, 4⟩⟩,
  ⟨"Défiance", ⟨-4, -2, 4⟩⟩,
  ⟨"Fierté", ⟨4, 2, 4⟩⟩,
  ⟨"Épanouissement", ⟨5, 1, 4⟩⟩,
  ⟨"Affection", ⟨5, -1, 4⟩⟩,
  ⟨"Admiration", ⟨4, -2, 4⟩⟩,
  ⟨"Frustration", ⟨-3, 3, 4⟩⟩,
  ⟨"Acceptation", ⟨3, -3, 4⟩⟩,
  ⟨"Estime", ⟨3, 3, 4⟩⟩,
  ⟨"Rejet", ⟨-3, -3, 4⟩⟩,

  -- Strate Z = 5 (33 entrées : 1 centre, 4 axiales, 24 latérales, 4 diagonales)
  ⟨"Recul", ⟨0, 0, 5⟩⟩,
  ⟨"Puissance", ⟨0, 8, 5⟩⟩,
  ⟨"Impuissance", ⟨0, -8, 5⟩⟩,
  ⟨"Méfiance", ⟨-8, 0, 5⟩⟩,
  ⟨"Confiance", ⟨8, 0, 5⟩⟩,
  ⟨"Invulnérabilité", ⟨1, 7, 5⟩⟩,
  ⟨"Attachement", ⟨2, 6, 5⟩⟩,
  ⟨"Engagement", ⟨3, 5, 5⟩⟩,
  ⟨"Désenchantement", ⟨-2, 6, 5⟩⟩,
  ⟨"Intolérance", ⟨-3, 5, 5⟩⟩,
  ⟨"Injustice", ⟨-1, 7, 5⟩⟩,
  ⟨"Quiétude", ⟨3, -5, 5⟩⟩,
  ⟨"Sécurité", ⟨2, -6, 5⟩⟩,
  ⟨"Patience", ⟨1, -7, 5⟩⟩,
  ⟨"Pessimisme", ⟨-2, -6, 5⟩⟩,
  ⟨"Fermeture", ⟨-3, -5, 5⟩⟩,
  ⟨"Désespoir", ⟨-1, -7, 5⟩⟩,
  ⟨"Insécurité", ⟨-6, 2, 5⟩⟩,
  ⟨"Inquiétude", ⟨-5, 3, 5⟩⟩,
  ⟨"Impatience", ⟨-7, 1, 5⟩⟩,
  ⟨"Vulnérabilité", ⟨-7, -1, 5⟩⟩,
  ⟨"Détachement", ⟨-6, -2, 5⟩⟩,
  ⟨"Désengagement", ⟨-5, -3, 5⟩⟩,
  ⟨"Optimisme", ⟨6, 2, 5⟩⟩,
  ⟨"Ouverture", ⟨5, 3, 5⟩⟩,
  ⟨"Espoir", ⟨7, 1, 5⟩⟩,
  ⟨"Enchantement", ⟨6, -2, 5⟩⟩,
  ⟨"Tolérance", ⟨5, -3, 5⟩⟩,
  ⟨"Justice", ⟨7, -1, 5⟩⟩,
  ⟨"Insatisfaction", ⟨-4, 4, 5⟩⟩,
  ⟨"Satisfaction", ⟨4, -4, 5⟩⟩,
  ⟨"Intérêt", ⟨4, 4, 5⟩⟩,
  ⟨"Désintérêt", ⟨-4, -4, 5⟩⟩,

  -- Strate Z = 6 (41 entrées : 1 centre, 4 axiales, 32 latérales, 4 diagonales)
  ⟨"Saisissement", ⟨0, 0, 6⟩⟩,
  ⟨"Élan", ⟨0, 10, 6⟩⟩,
  ⟨"Inertie", ⟨0, -10, 6⟩⟩,
  ⟨"Effacement", ⟨-10, 0, 6⟩⟩,
  ⟨"Affirmation", ⟨10, 0, 6⟩⟩,
  ⟨"Ardeur", ⟨3, 7, 6⟩⟩,
  ⟨"Angoisse", ⟨-3, 7, 6⟩⟩,
  ⟨"Allégresse", ⟨4, 6, 6⟩⟩,
  ⟨"Fureur", ⟨-4, 6, 6⟩⟩,
  ⟨"Fougue", ⟨2, 8, 6⟩⟩,
  ⟨"Frénésie", ⟨-2, 8, 6⟩⟩,
  ⟨"Jubilation", ⟨1, 9, 6⟩⟩,
  ⟨"Terreur", ⟨-1, 9, 6⟩⟩,
  ⟨"Béatitude", ⟨3, -7, 6⟩⟩,
  ⟨"Accablement", ⟨-3, -7, 6⟩⟩,
  ⟨"Apaisement", ⟨4, -6, 6⟩⟩,
  ⟨"Morosité", ⟨-4, -6, 6⟩⟩,
  ⟨"Contemplation", ⟨2, -8, 6⟩⟩,
  ⟨"Prostration", ⟨-2, -8, 6⟩⟩,
  ⟨"Félicité", ⟨1, -9, 6⟩⟩,
  ⟨"Désolation", ⟨-1, -9, 6⟩⟩,
  ⟨"Rancœur", ⟨-6, 4, 6⟩⟩,
  ⟨"Amertume", ⟨-6, -4, 6⟩⟩,
  ⟨"Affolement", ⟨-7, 3, 6⟩⟩,
  ⟨"Écrasement", ⟨-7, -3, 6⟩⟩,
  ⟨"Fébrilité", ⟨-8, 2, 6⟩⟩,
  ⟨"Anéantissement", ⟨-8, -2, 6⟩⟩,
  ⟨"Désarroi", ⟨-9, 1, 6⟩⟩,
  ⟨"Lassitude", ⟨-9, -1, 6⟩⟩,
  ⟨"Entrain", ⟨6, 4, 6⟩⟩,
  ⟨"Placidité", ⟨6, -4, 6⟩⟩,
  ⟨"Liesse", ⟨7, 3, 6⟩⟩,
  ⟨"Limpidité", ⟨7, -3, 6⟩⟩,
  ⟨"Extase", ⟨8, 2, 6⟩⟩,
  ⟨"Équanimité", ⟨8, -2, 6⟩⟩,
  ⟨"Exultation", ⟨9, 1, 6⟩⟩,
  ⟨"Harmonie", ⟨9, -1, 6⟩⟩,
  ⟨"Tourment", ⟨-5, 5, 6⟩⟩,
  ⟨"Ataraxie", ⟨5, -5, 6⟩⟩,
  ⟨"Triomphe", ⟨5, 5, 6⟩⟩,
  ⟨"Abattement", ⟨-5, -5, 6⟩⟩,

  -- Strate Z = 7 (49 entrées : 1 centre, 4 axiales, 40 latérales, 4 diagonales)
  ⟨"Suspension", ⟨0, 0, 7⟩⟩,
  ⟨"Infini", ⟨0, 12, 7⟩⟩,
  ⟨"Néant", ⟨0, -12, 7⟩⟩,
  ⟨"Déréliction", ⟨-12, 0, 7⟩⟩,
  ⟨"Communion", ⟨12, 0, 7⟩⟩,
  ⟨"Transcendance", ⟨2, 10, 7⟩⟩,
  ⟨"Déchirement", ⟨-2, 10, 7⟩⟩,
  ⟨"Exubérance", ⟨4, 8, 7⟩⟩,
  ⟨"Horreur", ⟨-4, 8, 7⟩⟩,
  ⟨"Renaissance", ⟨1, 11, 7⟩⟩,
  ⟨"Vertige", ⟨-1, 11, 7⟩⟩,
  ⟨"Élévation", ⟨3, 9, 7⟩⟩,
  ⟨"Détresse", ⟨-3, 9, 7⟩⟩,
  ⟨"Enivrement", ⟨5, 7, 7⟩⟩,
  ⟨"Révolte", ⟨-5, 7, 7⟩⟩,
  ⟨"Nirvana", ⟨2, -10, 7⟩⟩,
  ⟨"Perdition", ⟨-2, -10, 7⟩⟩,
  ⟨"Paix", ⟨4, -8, 7⟩⟩,
  ⟨"Oppression", ⟨-4, -8, 7⟩⟩,
  ⟨"Pérennité", ⟨1, -11, 7⟩⟩,
  ⟨"Abîme", ⟨-1, -11, 7⟩⟩,
  ⟨"Abandon", ⟨3, -9, 7⟩⟩,
  ⟨"Damnation", ⟨-3, -9, 7⟩⟩,
  ⟨"Silence", ⟨5, -7, 7⟩⟩,
  ⟨"Résignation", ⟨-5, -7, 7⟩⟩,
  ⟨"Hantise", ⟨-10, 2, 7⟩⟩,
  ⟨"Isolement", ⟨-10, -2, 7⟩⟩,
  ⟨"Affliction", ⟨-8, 4, 7⟩⟩,
  ⟨"Mélancolie", ⟨-8, -4, 7⟩⟩,
  ⟨"Précarité", ⟨-11, 1, 7⟩⟩,
  ⟨"Déchéance", ⟨-11, -1, 7⟩⟩,
  ⟨"Sidération", ⟨-9, 3, 7⟩⟩,
  ⟨"Engloutissement", ⟨-9, -3, 7⟩⟩,
  ⟨"Tumulte", ⟨-7, 5, 7⟩⟩,
  ⟨"Pétrification", ⟨-7, -5, 7⟩⟩,
  ⟨"Éblouissement", ⟨10, 2, 7⟩⟩,
  ⟨"Recueillement", ⟨10, -2, 7⟩⟩,
  ⟨"Rayonnement", ⟨8, 4, 7⟩⟩,
  ⟨"Contentement", ⟨8, -4, 7⟩⟩,
  ⟨"Ravissement", ⟨11, 1, 7⟩⟩,
  ⟨"Épiphanie", ⟨11, -1, 7⟩⟩,
  ⟨"Louange", ⟨9, 3, 7⟩⟩,
  ⟨"Lucidité", ⟨9, -3, 7⟩⟩,
  ⟨"Effusion", ⟨7, 5, 7⟩⟩,
  ⟨"Consentement", ⟨7, -5, 7⟩⟩,
  ⟨"Rage", ⟨-6, 6, 7⟩⟩,
  ⟨"Impassibilité", ⟨6, -6, 7⟩⟩,
  ⟨"Sublimation", ⟨6, 6, 7⟩⟩,
  ⟨"Dissolution", ⟨-6, -6, 7⟩⟩
]

set_option maxRecDepth 2000000
set_option maxHeartbeats 4000000

/-- Certification mécanique de la cardinalité exacte du répertoire (176 entrées). -/
theorem all176Entries_length : all176Entries.length = 176 := by decide

/-- Certification mécanique de la conformité géométrique de chaque entrée (loi des centres ou des couronnes). -/
theorem all176Entries_geometrically_valid : (all176Entries.all (fun e => isValidPointBool e.point)) = true := by decide

/-- Certification mécanique de l'absence totale de collision spatiale (unicité de chaque point du répertoire). -/
theorem all176Entries_unique_points : (all176Entries.map (·.point)).Nodup := by decide

/-- Certification mécanique de la clôture intégrale du répertoire sous l'opérateur d'antagonisme controlatéral. -/
theorem all176Entries_closed_under_antagonist :
    (all176Entries.all (fun e => (all176Entries.map (·.point)).contains (antagonistPoint e.point))) = true := by decide

/-- Génère les 4 combinaisons de signes `(±ax, ±ay, z)` pour un couple d'amplitudes donné. -/
def signVariants (ax ay z : Nat) : List CoreAffectPoint :=
  let x : Int := (ax : Int)
  let y : Int := (ay : Int)
  [⟨x, y, z⟩, ⟨x, -y, z⟩, ⟨-x, y, z⟩, ⟨-x, -y, z⟩]

/-- Tout point `p` appartient aux variantes de signes de ses propres valeurs absolues `(p.x.natAbs, p.y.natAbs, p.z)`. -/
theorem mem_signVariants (p : CoreAffectPoint) :
    p ∈ signVariants p.x.natAbs p.y.natAbs p.z := by
  obtain ⟨x, y, z⟩ := p
  dsimp [signVariants]
  have hx : x = (x.natAbs : Int) ∨ x = - (x.natAbs : Int) := by omega
  have hy : y = (y.natAbs : Int) ∨ y = - (y.natAbs : Int) := by omega
  rcases hx with hx | hx <;> rcases hy with hy | hy
  · rw [← hx, ← hy]; exact List.Mem.head _
  · rw [← hx, ← hy]; exact List.Mem.tail _ (List.Mem.head _)
  · rw [← hx, ← hy]; exact List.Mem.tail _ (List.Mem.tail _ (List.Mem.head _))
  · rw [← hx, ← hy]; exact List.Mem.tail _ (List.Mem.tail _ (List.Mem.tail _ (List.Mem.head _)))

/-- Grille géométrique complète des positions admissibles (centres et couronnes) pour une strate `z`. -/
def stratumValidGrid (z : Nat) : List CoreAffectPoint :=
  ⟨0, 0, z⟩ :: (List.range (crownRadius z + 1)).flatMap (fun ax =>
    signVariants ax (crownRadius z - ax) z)

/-- Tout point géométriquement valide `p` appartient à la grille `stratumValidGrid p.z` de sa strate. -/
theorem mem_stratumValidGrid (p : CoreAffectPoint) (hv : isValidCoreAffect p) :
    p ∈ stratumValidGrid p.z := by
  rcases p with ⟨x, y, z⟩
  rcases hv with ⟨hx, hy⟩ | ⟨_, hsum⟩
  · dsimp at hx hy
    subst hx hy
    exact List.Mem.head _
  · dsimp [CoreAffectPoint.displacementSum] at hsum ⊢
    refine List.Mem.tail _ (List.mem_flatMap.mpr ⟨x.natAbs, List.mem_range.mpr (by omega), ?_⟩)
    have hy_abs : crownRadius z - x.natAbs = y.natAbs := by omega
    rw [hy_abs]
    exact mem_signVariants ⟨x, y, z⟩

/-- Certification mécanique que la grille géométrique des strates Z = 0 à Z = 7 est incluse dans `all176Entries`. -/
theorem stratumValidGrid_sub_all176 (z : Nat) (hz : z ≤ 7) :
    ∀ q ∈ stratumValidGrid z, q ∈ all176Entries.map (·.point) := by
  rcases (by omega : z = 0 ∨ z = 1 ∨ z = 2 ∨ z = 3 ∨ z = 4 ∨ z = 5 ∨ z = 6 ∨ z = 7) with
    rfl | rfl | rfl | rfl | rfl | rfl | rfl | rfl <;> decide

/--
Théorème de complétude spatiale réciproque (Surjectivité sur la grille Z ≤ 7, Doc. 2, §1, §3 & §5) :
Tout point à coordonnées entières `(X, Y, Z)` avec `0 ≤ Z ≤ 7` satisfaisant l'invariant géométrique
`isValidCoreAffect` appartient effectivement au répertoire `all176Entries` (aucune coordonnée
géométriquement admissible n'a été omise).
-/
theorem all176Entries_spatial_completeness (p : CoreAffectPoint)
    (hz : p.z ≤ 7) (hv : isValidCoreAffect p) :
    p ∈ all176Entries.map (·.point) :=
  stratumValidGrid_sub_all176 p.z hz p (mem_stratumValidGrid p hv)

end Cartograffect.Lexicon176
