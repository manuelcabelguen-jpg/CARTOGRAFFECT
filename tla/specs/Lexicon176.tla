----------------------------- MODULE Lexicon176 ------------------------------
(*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen

  Module 06 : Lexique des 176 etats affectifs (Z = 0..7) (TLA+ / TLC)
*)
EXTENDS Integers, Sequences, FiniteSets, PredictiveEngine, CoreAffect, AffectiveMatrix, AffectiveTaxonomy

EntriesZ0 == <<
  [label |-> "Point de Veille", point |-> MkPoint(0, 0, 0)]
>>

EntriesZ1 == <<
  [label |-> "Surprise", point |-> MkPoint(0, 0, 1)]
>>

EntriesZ2 == <<
  [label |-> "Anticipation", point |-> MkPoint(0, 0, 2)],
  [label |-> "Joie", point |-> MkPoint(0, 2, 2)],
  [label |-> "Tristesse", point |-> MkPoint(0, -2, 2)],
  [label |-> "Peur", point |-> MkPoint(-2, 0, 2)],
  [label |-> "Courage", point |-> MkPoint(2, 0, 2)],
  [label |-> "Colere", point |-> MkPoint(-1, 1, 2)],
  [label |-> "Calme", point |-> MkPoint(1, -1, 2)],
  [label |-> "Desir", point |-> MkPoint(1, 1, 2)],
  [label |-> "Degout", point |-> MkPoint(-1, -1, 2)]
>>

EntriesZ3 == <<
  [label |-> "Emoi", point |-> MkPoint(0, 0, 3)],
  [label |-> "Enthousiasme", point |-> MkPoint(0, 4, 3)],
  [label |-> "Ennui", point |-> MkPoint(0, -4, 3)],
  [label |-> "Crainte", point |-> MkPoint(-4, 0, 3)],
  [label |-> "Curiosite", point |-> MkPoint(4, 0, 3)],
  [label |-> "Consternation", point |-> MkPoint(-1, 3, 3)],
  [label |-> "Euphorie", point |-> MkPoint(1, 3, 3)],
  [label |-> "Soulagement", point |-> MkPoint(1, -3, 3)],
  [label |-> "Chagrin", point |-> MkPoint(-1, -3, 3)],
  [label |-> "Panique", point |-> MkPoint(-3, 1, 3)],
  [label |-> "Effroi", point |-> MkPoint(-3, -1, 3)],
  [label |-> "Emerveillement", point |-> MkPoint(3, -1, 3)],
  [label |-> "Aplomb", point |-> MkPoint(3, 1, 3)],
  [label |-> "Exasperation", point |-> MkPoint(-2, 2, 3)],
  [label |-> "Detente", point |-> MkPoint(2, -2, 3)],
  [label |-> "Attrait", point |-> MkPoint(2, 2, 3)],
  [label |-> "Retrait", point |-> MkPoint(-2, -2, 3)]
>>

EntriesZ4 == <<
  [label |-> "Reserve", point |-> MkPoint(0, 0, 4)],
  [label |-> "Exaltation", point |-> MkPoint(0, 6, 4)],
  [label |-> "Langueur", point |-> MkPoint(0, -6, 4)],
  [label |-> "Doute", point |-> MkPoint(-6, 0, 4)],
  [label |-> "Assurance", point |-> MkPoint(6, 0, 4)],
  [label |-> "Envie", point |-> MkPoint(-2, 4, 4)],
  [label |-> "Haine", point |-> MkPoint(-1, 5, 4)],
  [label |-> "Amour", point |-> MkPoint(1, 5, 4)],
  [label |-> "Ferveur", point |-> MkPoint(2, 4, 4)],
  [label |-> "Serenite", point |-> MkPoint(2, -4, 4)],
  [label |-> "Plenitude", point |-> MkPoint(1, -5, 4)],
  [label |-> "Honte", point |-> MkPoint(-2, -4, 4)],
  [label |-> "Vide", point |-> MkPoint(-1, -5, 4)],
  [label |-> "Anxiete", point |-> MkPoint(-4, 2, 4)],
  [label |-> "Manque", point |-> MkPoint(-5, 1, 4)],
  [label |-> "Mepris", point |-> MkPoint(-5, -1, 4)],
  [label |-> "Defiance", point |-> MkPoint(-4, -2, 4)],
  [label |-> "Fierte", point |-> MkPoint(4, 2, 4)],
  [label |-> "Epanouissement", point |-> MkPoint(5, 1, 4)],
  [label |-> "Affection", point |-> MkPoint(5, -1, 4)],
  [label |-> "Admiration", point |-> MkPoint(4, -2, 4)],
  [label |-> "Frustration", point |-> MkPoint(-3, 3, 4)],
  [label |-> "Acceptation", point |-> MkPoint(3, -3, 4)],
  [label |-> "Estime", point |-> MkPoint(3, 3, 4)],
  [label |-> "Rejet", point |-> MkPoint(-3, -3, 4)]
>>

EntriesZ5 == <<
  [label |-> "Recul", point |-> MkPoint(0, 0, 5)],
  [label |-> "Puissance", point |-> MkPoint(0, 8, 5)],
  [label |-> "Impuissance", point |-> MkPoint(0, -8, 5)],
  [label |-> "Mefiance", point |-> MkPoint(-8, 0, 5)],
  [label |-> "Confiance", point |-> MkPoint(8, 0, 5)],
  [label |-> "Invulnerabilite", point |-> MkPoint(1, 7, 5)],
  [label |-> "Attachement", point |-> MkPoint(2, 6, 5)],
  [label |-> "Engagement", point |-> MkPoint(3, 5, 5)],
  [label |-> "Desenchantement", point |-> MkPoint(-2, 6, 5)],
  [label |-> "Intolerance", point |-> MkPoint(-3, 5, 5)],
  [label |-> "Injustice", point |-> MkPoint(-1, 7, 5)],
  [label |-> "Quietude", point |-> MkPoint(3, -5, 5)],
  [label |-> "Securite", point |-> MkPoint(2, -6, 5)],
  [label |-> "Patience", point |-> MkPoint(1, -7, 5)],
  [label |-> "Pessimisme", point |-> MkPoint(-2, -6, 5)],
  [label |-> "Fermeture", point |-> MkPoint(-3, -5, 5)],
  [label |-> "Desespoir", point |-> MkPoint(-1, -7, 5)],
  [label |-> "Insecurite", point |-> MkPoint(-6, 2, 5)],
  [label |-> "Inquietude", point |-> MkPoint(-5, 3, 5)],
  [label |-> "Impatience", point |-> MkPoint(-7, 1, 5)],
  [label |-> "Vulnerabilite", point |-> MkPoint(-7, -1, 5)],
  [label |-> "Detachement", point |-> MkPoint(-6, -2, 5)],
  [label |-> "Desengagement", point |-> MkPoint(-5, -3, 5)],
  [label |-> "Optimisme", point |-> MkPoint(6, 2, 5)],
  [label |-> "Ouverture", point |-> MkPoint(5, 3, 5)],
  [label |-> "Espoir", point |-> MkPoint(7, 1, 5)],
  [label |-> "Enchantement", point |-> MkPoint(6, -2, 5)],
  [label |-> "Tolerance", point |-> MkPoint(5, -3, 5)],
  [label |-> "Justice", point |-> MkPoint(7, -1, 5)],
  [label |-> "Insatisfaction", point |-> MkPoint(-4, 4, 5)],
  [label |-> "Satisfaction", point |-> MkPoint(4, -4, 5)],
  [label |-> "Interet", point |-> MkPoint(4, 4, 5)],
  [label |-> "Desinteret", point |-> MkPoint(-4, -4, 5)]
>>

EntriesZ6 == <<
  [label |-> "Saisissement", point |-> MkPoint(0, 0, 6)],
  [label |-> "Elan", point |-> MkPoint(0, 10, 6)],
  [label |-> "Inertie", point |-> MkPoint(0, -10, 6)],
  [label |-> "Effacement", point |-> MkPoint(-10, 0, 6)],
  [label |-> "Affirmation", point |-> MkPoint(10, 0, 6)],
  [label |-> "Ardeur", point |-> MkPoint(3, 7, 6)],
  [label |-> "Angoisse", point |-> MkPoint(-3, 7, 6)],
  [label |-> "Allegresse", point |-> MkPoint(4, 6, 6)],
  [label |-> "Fureur", point |-> MkPoint(-4, 6, 6)],
  [label |-> "Fougue", point |-> MkPoint(2, 8, 6)],
  [label |-> "Frenesie", point |-> MkPoint(-2, 8, 6)],
  [label |-> "Jubilation", point |-> MkPoint(1, 9, 6)],
  [label |-> "Terreur", point |-> MkPoint(-1, 9, 6)],
  [label |-> "Beatitude", point |-> MkPoint(3, -7, 6)],
  [label |-> "Accablement", point |-> MkPoint(-3, -7, 6)],
  [label |-> "Apaisement", point |-> MkPoint(4, -6, 6)],
  [label |-> "Morosite", point |-> MkPoint(-4, -6, 6)],
  [label |-> "Contemplation", point |-> MkPoint(2, -8, 6)],
  [label |-> "Prostration", point |-> MkPoint(-2, -8, 6)],
  [label |-> "Felicite", point |-> MkPoint(1, -9, 6)],
  [label |-> "Desolation", point |-> MkPoint(-1, -9, 6)],
  [label |-> "Rancoeur", point |-> MkPoint(-6, 4, 6)],
  [label |-> "Amertume", point |-> MkPoint(-6, -4, 6)],
  [label |-> "Affolement", point |-> MkPoint(-7, 3, 6)],
  [label |-> "Ecrasement", point |-> MkPoint(-7, -3, 6)],
  [label |-> "Febrilite", point |-> MkPoint(-8, 2, 6)],
  [label |-> "Aneantissement", point |-> MkPoint(-8, -2, 6)],
  [label |-> "Desarroi", point |-> MkPoint(-9, 1, 6)],
  [label |-> "Lassitude", point |-> MkPoint(-9, -1, 6)],
  [label |-> "Entrain", point |-> MkPoint(6, 4, 6)],
  [label |-> "Placidite", point |-> MkPoint(6, -4, 6)],
  [label |-> "Liesse", point |-> MkPoint(7, 3, 6)],
  [label |-> "Limpidite", point |-> MkPoint(7, -3, 6)],
  [label |-> "Extase", point |-> MkPoint(8, 2, 6)],
  [label |-> "Equanimite", point |-> MkPoint(8, -2, 6)],
  [label |-> "Exultation", point |-> MkPoint(9, 1, 6)],
  [label |-> "Harmonie", point |-> MkPoint(9, -1, 6)],
  [label |-> "Tourment", point |-> MkPoint(-5, 5, 6)],
  [label |-> "Ataraxie", point |-> MkPoint(5, -5, 6)],
  [label |-> "Triomphe", point |-> MkPoint(5, 5, 6)],
  [label |-> "Abattement", point |-> MkPoint(-5, -5, 6)]
>>

EntriesZ7 == <<
  [label |-> "Suspension", point |-> MkPoint(0, 0, 7)],
  [label |-> "Infini", point |-> MkPoint(0, 12, 7)],
  [label |-> "Neant", point |-> MkPoint(0, -12, 7)],
  [label |-> "Dereliction", point |-> MkPoint(-12, 0, 7)],
  [label |-> "Communion", point |-> MkPoint(12, 0, 7)],
  [label |-> "Transcendance", point |-> MkPoint(2, 10, 7)],
  [label |-> "Dechirement", point |-> MkPoint(-2, 10, 7)],
  [label |-> "Exuberance", point |-> MkPoint(4, 8, 7)],
  [label |-> "Horreur", point |-> MkPoint(-4, 8, 7)],
  [label |-> "Renaissance", point |-> MkPoint(1, 11, 7)],
  [label |-> "Vertige", point |-> MkPoint(-1, 11, 7)],
  [label |-> "Elevation", point |-> MkPoint(3, 9, 7)],
  [label |-> "Detresse", point |-> MkPoint(-3, 9, 7)],
  [label |-> "Enivrement", point |-> MkPoint(5, 7, 7)],
  [label |-> "Revolte", point |-> MkPoint(-5, 7, 7)],
  [label |-> "Nirvana", point |-> MkPoint(2, -10, 7)],
  [label |-> "Perdition", point |-> MkPoint(-2, -10, 7)],
  [label |-> "Paix", point |-> MkPoint(4, -8, 7)],
  [label |-> "Oppression", point |-> MkPoint(-4, -8, 7)],
  [label |-> "Perennite", point |-> MkPoint(1, -11, 7)],
  [label |-> "Abime", point |-> MkPoint(-1, -11, 7)],
  [label |-> "Abandon", point |-> MkPoint(3, -9, 7)],
  [label |-> "Damnation", point |-> MkPoint(-3, -9, 7)],
  [label |-> "Silence", point |-> MkPoint(5, -7, 7)],
  [label |-> "Resignation", point |-> MkPoint(-5, -7, 7)],
  [label |-> "Hantise", point |-> MkPoint(-10, 2, 7)],
  [label |-> "Isolement", point |-> MkPoint(-10, -2, 7)],
  [label |-> "Affliction", point |-> MkPoint(-8, 4, 7)],
  [label |-> "Melancolie", point |-> MkPoint(-8, -4, 7)],
  [label |-> "Precarite", point |-> MkPoint(-11, 1, 7)],
  [label |-> "Decheance", point |-> MkPoint(-11, -1, 7)],
  [label |-> "Sideration", point |-> MkPoint(-9, 3, 7)],
  [label |-> "Engloutissement", point |-> MkPoint(-9, -3, 7)],
  [label |-> "Tumulte", point |-> MkPoint(-7, 5, 7)],
  [label |-> "Petrification", point |-> MkPoint(-7, -5, 7)],
  [label |-> "Eblouissement", point |-> MkPoint(10, 2, 7)],
  [label |-> "Recueillement", point |-> MkPoint(10, -2, 7)],
  [label |-> "Rayonnement", point |-> MkPoint(8, 4, 7)],
  [label |-> "Contentement", point |-> MkPoint(8, -4, 7)],
  [label |-> "Ravissement", point |-> MkPoint(11, 1, 7)],
  [label |-> "Epiphanie", point |-> MkPoint(11, -1, 7)],
  [label |-> "Louange", point |-> MkPoint(9, 3, 7)],
  [label |-> "Lucidite", point |-> MkPoint(9, -3, 7)],
  [label |-> "Effusion", point |-> MkPoint(7, 5, 7)],
  [label |-> "Consentement", point |-> MkPoint(7, -5, 7)],
  [label |-> "Rage", point |-> MkPoint(-6, 6, 7)],
  [label |-> "Impassibilite", point |-> MkPoint(6, -6, 7)],
  [label |-> "Sublimation", point |-> MkPoint(6, 6, 7)],
  [label |-> "Dissolution", point |-> MkPoint(-6, -6, 7)]
>>

All176Entries ==
  EntriesZ0 \o EntriesZ1 \o EntriesZ2 \o EntriesZ3 \o
  EntriesZ4 \o EntriesZ5 \o EntriesZ6 \o EntriesZ7

All176Points == {All176Entries[i].point : i \in 1..Len(All176Entries)}

All176EntrySet == {All176Entries[i] : i \in 1..Len(All176Entries)}

All176Labels == {All176Entries[i].label : i \in 1..Len(All176Entries)}

HasUniqueLexiconEntry(p) ==
  \E e \in All176EntrySet :
    e.point = p /\ (\A e2 \in All176EntrySet : e2.point = p => e2 = e)

ValidPointsUpToZ7 ==
  UNION {
    LET r == CrownRadius(z) IN
    {p \in [x : (-r)..r, y : (-r)..r, z : {z}] : IsValidCoreAffect(p)} :
    z \in 0..7
  }

-----------------------------------------------------------------------------
(* 8 audited theorem predicates + unicite nominale + cloture antagoniste *)
-----------------------------------------------------------------------------

Thm_all176Entries_length ==
  Len(All176Entries) = 176

Thm_all176Entries_geometrically_valid ==
  \A i \in 1..Len(All176Entries) : IsValidCoreAffect(All176Entries[i].point)

Thm_all176Entries_z_bounds ==
  \A i \in 1..Len(All176Entries) :
    All176Entries[i].point.z >= 0 /\ All176Entries[i].point.z <= 7

Thm_all176Entries_unique_points ==
  \A i \in 1..Len(All176Entries), j \in 1..Len(All176Entries) :
    i # j => All176Entries[i].point # All176Entries[j].point

Thm_all176Entries_unique_labels ==
  \A i \in 1..Len(All176Entries), j \in 1..Len(All176Entries) :
    i # j => All176Entries[i].label # All176Entries[j].label

Thm_all176Entries_closed_under_antagonist ==
  \A i \in 1..Len(All176Entries) :
    AntagonistPoint(All176Entries[i].point) \in All176Points

Thm_all176Entries_complete ==
  \A p \in ValidPointsUpToZ7 : p \in All176Points

Thm_all176Entries_deterministically_reachable ==
  \A i \in 1..Len(All176Entries) :
    LET s == WitnessEngineForPoint(All176Entries[i].point) IN
    RunCartograffectPipeline(s).matrix.core = All176Entries[i].point

Thm_all176Entries_reachable_by_engine ==
  \A i \in 1..Len(All176Entries) :
    LET s == WitnessEngineForPoint(All176Entries[i].point) IN
    RunCartograffectPipeline(s).matrix.core = All176Entries[i].point

Thm_all176Entries_witness_check ==
  \A i \in 1..Len(All176Entries) :
    ProjectToCoreAffect(WitnessEngineForPoint(All176Entries[i].point)) = All176Entries[i].point

=============================================================================
