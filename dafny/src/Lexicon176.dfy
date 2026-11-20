/*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
*/

include "PredictiveEngine.dfy"
include "CoreAffect.dfy"
include "AffectiveMatrix.dfy"
include "AffectiveTaxonomy.dfy"

module Lexicon176 {
  import opened PredictiveEngine
  import opened CoreAffect
  import opened AffectiveMatrix
  import opened AffectiveTaxonomy

  datatype LexiconEntry = LexiconEntry(entryLabel: string, point: CoreAffectPoint)

  predicate IsValidPointBool(p: CoreAffectPoint) {
    (p.x == 0 && p.y == 0) || (p.z >= 2 && DisplacementSum(p) == CrownRadius(p.z))
  }

  // Stratum z=0 (1 entries)
  opaque function LabelsZ0(): seq<string>
    ensures |LabelsZ0()| == 1
  {
    [
      "Point de Veille"
    ]
  }

  function PointZ0(i: nat): CoreAffectPoint
    requires i < 1
  {
    CoreAffectPoint(0, 0, 0)
  }

  function EntriesZ0(): seq<LexiconEntry>
    ensures |EntriesZ0()| == 1
    ensures forall i | 0 <= i < 1 :: EntriesZ0()[i].point == PointZ0(i)
  {
    seq(1, i requires 0 <= i < 1 => LexiconEntry(LabelsZ0()[i], PointZ0(i)))
  }

  function IndexInZ0(x: int, y: int): int
  {
    if x == 0 && y == 0 then 0 else -1
  }

  // Stratum z=1 (1 entries)
  opaque function LabelsZ1(): seq<string>
    ensures |LabelsZ1()| == 1
  {
    [
      "Surprise"
    ]
  }

  function PointZ1(i: nat): CoreAffectPoint
    requires i < 1
  {
    CoreAffectPoint(0, 0, 1)
  }

  function EntriesZ1(): seq<LexiconEntry>
    ensures |EntriesZ1()| == 1
    ensures forall i | 0 <= i < 1 :: EntriesZ1()[i].point == PointZ1(i)
  {
    seq(1, i requires 0 <= i < 1 => LexiconEntry(LabelsZ1()[i], PointZ1(i)))
  }

  function IndexInZ1(x: int, y: int): int
  {
    if x == 0 && y == 0 then 0 else -1
  }

  // Stratum z=2 (9 entries)
  opaque function LabelsZ2(): seq<string>
    ensures |LabelsZ2()| == 9
  {
    [
      "Anticipation",
      "Joie",
      "Tristesse",
      "Peur",
      "Courage",
      "Colère",
      "Calme",
      "Désir",
      "Dégoût"
    ]
  }

  function PointZ2(i: nat): CoreAffectPoint
    requires i < 9
  {
    if i < 4 then
      if i < 2 then
        if i < 1 then
          CoreAffectPoint(0, 0, 2)
        else
          CoreAffectPoint(0, 2, 2)
      else
        if i < 3 then
          CoreAffectPoint(0, -2, 2)
        else
          CoreAffectPoint(-2, 0, 2)
    else
      if i < 6 then
        if i < 5 then
          CoreAffectPoint(2, 0, 2)
        else
          CoreAffectPoint(-1, 1, 2)
      else
        if i < 7 then
          CoreAffectPoint(1, -1, 2)
        else
          if i < 8 then
            CoreAffectPoint(1, 1, 2)
          else
            CoreAffectPoint(-1, -1, 2)
  }

  function EntriesZ2(): seq<LexiconEntry>
    ensures |EntriesZ2()| == 9
    ensures forall i | 0 <= i < 9 :: EntriesZ2()[i].point == PointZ2(i)
  {
    seq(9, i requires 0 <= i < 9 => LexiconEntry(LabelsZ2()[i], PointZ2(i)))
  }

  function IndexInZ2(x: int, y: int): int
  {
    if x < 0 || (x == 0 && y < 0) then
      if x < -1 || (x == -1 && y < 1) then
        if x < -1 || (x == -1 && y < -1) then
          if x == -2 && y == 0 then 3 else -1
        else
          if x == -1 && y == -1 then 8 else -1
      else
        if x < 0 || (x == 0 && y < -2) then
          if x == -1 && y == 1 then 5 else -1
        else
          if x == 0 && y == -2 then 2 else -1
    else
      if x < 1 || (x == 1 && y < -1) then
        if x < 0 || (x == 0 && y < 2) then
          if x == 0 && y == 0 then 0 else -1
        else
          if x == 0 && y == 2 then 1 else -1
      else
        if x < 1 || (x == 1 && y < 1) then
          if x == 1 && y == -1 then 6 else -1
        else
          if x < 2 || (x == 2 && y < 0) then
            if x == 1 && y == 1 then 7 else -1
          else
            if x == 2 && y == 0 then 4 else -1
  }

  // Stratum z=3 (17 entries)
  opaque function LabelsZ3(): seq<string>
    ensures |LabelsZ3()| == 17
  {
    [
      "Émoi",
      "Enthousiasme",
      "Ennui",
      "Crainte",
      "Curiosité",
      "Consternation",
      "Euphorie",
      "Soulagement",
      "Chagrin",
      "Panique",
      "Effroi",
      "Émerveillement",
      "Aplomb",
      "Exaspération",
      "Détente",
      "Attrait",
      "Retrait"
    ]
  }

  function PointZ3(i: nat): CoreAffectPoint
    requires i < 17
  {
    if i < 8 then
      if i < 4 then
        if i < 2 then
          if i < 1 then
            CoreAffectPoint(0, 0, 3)
          else
            CoreAffectPoint(0, 4, 3)
        else
          if i < 3 then
            CoreAffectPoint(0, -4, 3)
          else
            CoreAffectPoint(-4, 0, 3)
      else
        if i < 6 then
          if i < 5 then
            CoreAffectPoint(4, 0, 3)
          else
            CoreAffectPoint(-1, 3, 3)
        else
          if i < 7 then
            CoreAffectPoint(1, 3, 3)
          else
            CoreAffectPoint(1, -3, 3)
    else
      if i < 12 then
        if i < 10 then
          if i < 9 then
            CoreAffectPoint(-1, -3, 3)
          else
            CoreAffectPoint(-3, 1, 3)
        else
          if i < 11 then
            CoreAffectPoint(-3, -1, 3)
          else
            CoreAffectPoint(3, -1, 3)
      else
        if i < 14 then
          if i < 13 then
            CoreAffectPoint(3, 1, 3)
          else
            CoreAffectPoint(-2, 2, 3)
        else
          if i < 15 then
            CoreAffectPoint(2, -2, 3)
          else
            if i < 16 then
              CoreAffectPoint(2, 2, 3)
            else
              CoreAffectPoint(-2, -2, 3)
  }

  function EntriesZ3(): seq<LexiconEntry>
    ensures |EntriesZ3()| == 17
    ensures forall i | 0 <= i < 17 :: EntriesZ3()[i].point == PointZ3(i)
  {
    seq(17, i requires 0 <= i < 17 => LexiconEntry(LabelsZ3()[i], PointZ3(i)))
  }

  function IndexInZ3(x: int, y: int): int
  {
    if x < 0 || (x == 0 && y < 0) then
      if x < -2 || (x == -2 && y < 2) then
        if x < -3 || (x == -3 && y < 1) then
          if x < -3 || (x == -3 && y < -1) then
            if x == -4 && y == 0 then 3 else -1
          else
            if x == -3 && y == -1 then 10 else -1
        else
          if x < -2 || (x == -2 && y < -2) then
            if x == -3 && y == 1 then 9 else -1
          else
            if x == -2 && y == -2 then 16 else -1
      else
        if x < -1 || (x == -1 && y < 3) then
          if x < -1 || (x == -1 && y < -3) then
            if x == -2 && y == 2 then 13 else -1
          else
            if x == -1 && y == -3 then 8 else -1
        else
          if x < 0 || (x == 0 && y < -4) then
            if x == -1 && y == 3 then 5 else -1
          else
            if x == 0 && y == -4 then 2 else -1
    else
      if x < 2 || (x == 2 && y < -2) then
        if x < 1 || (x == 1 && y < -3) then
          if x < 0 || (x == 0 && y < 4) then
            if x == 0 && y == 0 then 0 else -1
          else
            if x == 0 && y == 4 then 1 else -1
        else
          if x < 1 || (x == 1 && y < 3) then
            if x == 1 && y == -3 then 7 else -1
          else
            if x == 1 && y == 3 then 6 else -1
      else
        if x < 3 || (x == 3 && y < -1) then
          if x < 2 || (x == 2 && y < 2) then
            if x == 2 && y == -2 then 14 else -1
          else
            if x == 2 && y == 2 then 15 else -1
        else
          if x < 3 || (x == 3 && y < 1) then
            if x == 3 && y == -1 then 11 else -1
          else
            if x < 4 || (x == 4 && y < 0) then
              if x == 3 && y == 1 then 12 else -1
            else
              if x == 4 && y == 0 then 4 else -1
  }

  // Stratum z=4 (25 entries)
  opaque function LabelsZ4(): seq<string>
    ensures |LabelsZ4()| == 25
  {
    [
      "Réserve",
      "Exaltation",
      "Langueur",
      "Doute",
      "Assurance",
      "Envie",
      "Haine",
      "Amour",
      "Ferveur",
      "Sérénité",
      "Plénitude",
      "Honte",
      "Vide",
      "Anxiété",
      "Manque",
      "Mépris",
      "Défiance",
      "Fierté",
      "Épanouissement",
      "Affection",
      "Admiration",
      "Frustration",
      "Acceptation",
      "Estime",
      "Rejet"
    ]
  }

  function PointZ4(i: nat): CoreAffectPoint
    requires i < 25
  {
    if i < 12 then
      if i < 6 then
        if i < 3 then
          if i < 1 then
            CoreAffectPoint(0, 0, 4)
          else
            if i < 2 then
              CoreAffectPoint(0, 6, 4)
            else
              CoreAffectPoint(0, -6, 4)
        else
          if i < 4 then
            CoreAffectPoint(-6, 0, 4)
          else
            if i < 5 then
              CoreAffectPoint(6, 0, 4)
            else
              CoreAffectPoint(-2, 4, 4)
      else
        if i < 9 then
          if i < 7 then
            CoreAffectPoint(-1, 5, 4)
          else
            if i < 8 then
              CoreAffectPoint(1, 5, 4)
            else
              CoreAffectPoint(2, 4, 4)
        else
          if i < 10 then
            CoreAffectPoint(2, -4, 4)
          else
            if i < 11 then
              CoreAffectPoint(1, -5, 4)
            else
              CoreAffectPoint(-2, -4, 4)
    else
      if i < 18 then
        if i < 15 then
          if i < 13 then
            CoreAffectPoint(-1, -5, 4)
          else
            if i < 14 then
              CoreAffectPoint(-4, 2, 4)
            else
              CoreAffectPoint(-5, 1, 4)
        else
          if i < 16 then
            CoreAffectPoint(-5, -1, 4)
          else
            if i < 17 then
              CoreAffectPoint(-4, -2, 4)
            else
              CoreAffectPoint(4, 2, 4)
      else
        if i < 21 then
          if i < 19 then
            CoreAffectPoint(5, 1, 4)
          else
            if i < 20 then
              CoreAffectPoint(5, -1, 4)
            else
              CoreAffectPoint(4, -2, 4)
        else
          if i < 23 then
            if i < 22 then
              CoreAffectPoint(-3, 3, 4)
            else
              CoreAffectPoint(3, -3, 4)
          else
            if i < 24 then
              CoreAffectPoint(3, 3, 4)
            else
              CoreAffectPoint(-3, -3, 4)
  }

  function EntriesZ4(): seq<LexiconEntry>
    ensures |EntriesZ4()| == 25
    ensures forall i | 0 <= i < 25 :: EntriesZ4()[i].point == PointZ4(i)
  {
    seq(25, i requires 0 <= i < 25 => LexiconEntry(LabelsZ4()[i], PointZ4(i)))
  }

  function IndexInZ4(x: int, y: int): int
  {
    if x < 0 || (x == 0 && y < 0) then
      if x < -3 || (x == -3 && y < 3) then
        if x < -4 || (x == -4 && y < -2) then
          if x < -5 || (x == -5 && y < -1) then
            if x == -6 && y == 0 then 3 else -1
          else
            if x < -5 || (x == -5 && y < 1) then
              if x == -5 && y == -1 then 15 else -1
            else
              if x == -5 && y == 1 then 14 else -1
        else
          if x < -4 || (x == -4 && y < 2) then
            if x == -4 && y == -2 then 16 else -1
          else
            if x < -3 || (x == -3 && y < -3) then
              if x == -4 && y == 2 then 13 else -1
            else
              if x == -3 && y == -3 then 24 else -1
      else
        if x < -1 || (x == -1 && y < -5) then
          if x < -2 || (x == -2 && y < -4) then
            if x == -3 && y == 3 then 21 else -1
          else
            if x < -2 || (x == -2 && y < 4) then
              if x == -2 && y == -4 then 11 else -1
            else
              if x == -2 && y == 4 then 5 else -1
        else
          if x < -1 || (x == -1 && y < 5) then
            if x == -1 && y == -5 then 12 else -1
          else
            if x < 0 || (x == 0 && y < -6) then
              if x == -1 && y == 5 then 6 else -1
            else
              if x == 0 && y == -6 then 2 else -1
    else
      if x < 3 || (x == 3 && y < -3) then
        if x < 1 || (x == 1 && y < 5) then
          if x < 0 || (x == 0 && y < 6) then
            if x == 0 && y == 0 then 0 else -1
          else
            if x < 1 || (x == 1 && y < -5) then
              if x == 0 && y == 6 then 1 else -1
            else
              if x == 1 && y == -5 then 10 else -1
        else
          if x < 2 || (x == 2 && y < -4) then
            if x == 1 && y == 5 then 7 else -1
          else
            if x < 2 || (x == 2 && y < 4) then
              if x == 2 && y == -4 then 9 else -1
            else
              if x == 2 && y == 4 then 8 else -1
      else
        if x < 4 || (x == 4 && y < 2) then
          if x < 3 || (x == 3 && y < 3) then
            if x == 3 && y == -3 then 22 else -1
          else
            if x < 4 || (x == 4 && y < -2) then
              if x == 3 && y == 3 then 23 else -1
            else
              if x == 4 && y == -2 then 20 else -1
        else
          if x < 5 || (x == 5 && y < 1) then
            if x < 5 || (x == 5 && y < -1) then
              if x == 4 && y == 2 then 17 else -1
            else
              if x == 5 && y == -1 then 19 else -1
          else
            if x < 6 || (x == 6 && y < 0) then
              if x == 5 && y == 1 then 18 else -1
            else
              if x == 6 && y == 0 then 4 else -1
  }

  // Stratum z=5 (33 entries)
  opaque function LabelsZ5(): seq<string>
    ensures |LabelsZ5()| == 33
  {
    [
      "Recul",
      "Puissance",
      "Impuissance",
      "Méfiance",
      "Confiance",
      "Invulnérabilité",
      "Attachement",
      "Engagement",
      "Désenchantement",
      "Intolérance",
      "Injustice",
      "Quiétude",
      "Sécurité",
      "Patience",
      "Pessimisme",
      "Fermeture",
      "Désespoir",
      "Insécurité",
      "Inquiétude",
      "Impatience",
      "Vulnérabilité",
      "Détachement",
      "Désengagement",
      "Optimisme",
      "Ouverture",
      "Espoir",
      "Enchantement",
      "Tolérance",
      "Justice",
      "Insatisfaction",
      "Satisfaction",
      "Intérêt",
      "Désintérêt"
    ]
  }

  function PointZ5(i: nat): CoreAffectPoint
    requires i < 33
  {
    if i < 16 then
      if i < 8 then
        if i < 4 then
          if i < 2 then
            if i < 1 then
              CoreAffectPoint(0, 0, 5)
            else
              CoreAffectPoint(0, 8, 5)
          else
            if i < 3 then
              CoreAffectPoint(0, -8, 5)
            else
              CoreAffectPoint(-8, 0, 5)
        else
          if i < 6 then
            if i < 5 then
              CoreAffectPoint(8, 0, 5)
            else
              CoreAffectPoint(1, 7, 5)
          else
            if i < 7 then
              CoreAffectPoint(2, 6, 5)
            else
              CoreAffectPoint(3, 5, 5)
      else
        if i < 12 then
          if i < 10 then
            if i < 9 then
              CoreAffectPoint(-2, 6, 5)
            else
              CoreAffectPoint(-3, 5, 5)
          else
            if i < 11 then
              CoreAffectPoint(-1, 7, 5)
            else
              CoreAffectPoint(3, -5, 5)
        else
          if i < 14 then
            if i < 13 then
              CoreAffectPoint(2, -6, 5)
            else
              CoreAffectPoint(1, -7, 5)
          else
            if i < 15 then
              CoreAffectPoint(-2, -6, 5)
            else
              CoreAffectPoint(-3, -5, 5)
    else
      if i < 24 then
        if i < 20 then
          if i < 18 then
            if i < 17 then
              CoreAffectPoint(-1, -7, 5)
            else
              CoreAffectPoint(-6, 2, 5)
          else
            if i < 19 then
              CoreAffectPoint(-5, 3, 5)
            else
              CoreAffectPoint(-7, 1, 5)
        else
          if i < 22 then
            if i < 21 then
              CoreAffectPoint(-7, -1, 5)
            else
              CoreAffectPoint(-6, -2, 5)
          else
            if i < 23 then
              CoreAffectPoint(-5, -3, 5)
            else
              CoreAffectPoint(6, 2, 5)
      else
        if i < 28 then
          if i < 26 then
            if i < 25 then
              CoreAffectPoint(5, 3, 5)
            else
              CoreAffectPoint(7, 1, 5)
          else
            if i < 27 then
              CoreAffectPoint(6, -2, 5)
            else
              CoreAffectPoint(5, -3, 5)
        else
          if i < 30 then
            if i < 29 then
              CoreAffectPoint(7, -1, 5)
            else
              CoreAffectPoint(-4, 4, 5)
          else
            if i < 31 then
              CoreAffectPoint(4, -4, 5)
            else
              if i < 32 then
                CoreAffectPoint(4, 4, 5)
              else
                CoreAffectPoint(-4, -4, 5)
  }

  function EntriesZ5(): seq<LexiconEntry>
    ensures |EntriesZ5()| == 33
    ensures forall i | 0 <= i < 33 :: EntriesZ5()[i].point == PointZ5(i)
  {
    seq(33, i requires 0 <= i < 33 => LexiconEntry(LabelsZ5()[i], PointZ5(i)))
  }

  function IndexInZ5(x: int, y: int): int
  {
    if x < 0 || (x == 0 && y < 0) then
      if x < -4 || (x == -4 && y < 4) then
        if x < -6 || (x == -6 && y < 2) then
          if x < -7 || (x == -7 && y < 1) then
            if x < -7 || (x == -7 && y < -1) then
              if x == -8 && y == 0 then 3 else -1
            else
              if x == -7 && y == -1 then 20 else -1
          else
            if x < -6 || (x == -6 && y < -2) then
              if x == -7 && y == 1 then 19 else -1
            else
              if x == -6 && y == -2 then 21 else -1
        else
          if x < -5 || (x == -5 && y < 3) then
            if x < -5 || (x == -5 && y < -3) then
              if x == -6 && y == 2 then 17 else -1
            else
              if x == -5 && y == -3 then 22 else -1
          else
            if x < -4 || (x == -4 && y < -4) then
              if x == -5 && y == 3 then 18 else -1
            else
              if x == -4 && y == -4 then 32 else -1
      else
        if x < -2 || (x == -2 && y < 6) then
          if x < -3 || (x == -3 && y < 5) then
            if x < -3 || (x == -3 && y < -5) then
              if x == -4 && y == 4 then 29 else -1
            else
              if x == -3 && y == -5 then 15 else -1
          else
            if x < -2 || (x == -2 && y < -6) then
              if x == -3 && y == 5 then 9 else -1
            else
              if x == -2 && y == -6 then 14 else -1
        else
          if x < -1 || (x == -1 && y < 7) then
            if x < -1 || (x == -1 && y < -7) then
              if x == -2 && y == 6 then 8 else -1
            else
              if x == -1 && y == -7 then 16 else -1
          else
            if x < 0 || (x == 0 && y < -8) then
              if x == -1 && y == 7 then 10 else -1
            else
              if x == 0 && y == -8 then 2 else -1
    else
      if x < 4 || (x == 4 && y < -4) then
        if x < 2 || (x == 2 && y < -6) then
          if x < 1 || (x == 1 && y < -7) then
            if x < 0 || (x == 0 && y < 8) then
              if x == 0 && y == 0 then 0 else -1
            else
              if x == 0 && y == 8 then 1 else -1
          else
            if x < 1 || (x == 1 && y < 7) then
              if x == 1 && y == -7 then 13 else -1
            else
              if x == 1 && y == 7 then 5 else -1
        else
          if x < 3 || (x == 3 && y < -5) then
            if x < 2 || (x == 2 && y < 6) then
              if x == 2 && y == -6 then 12 else -1
            else
              if x == 2 && y == 6 then 6 else -1
          else
            if x < 3 || (x == 3 && y < 5) then
              if x == 3 && y == -5 then 11 else -1
            else
              if x == 3 && y == 5 then 7 else -1
      else
        if x < 6 || (x == 6 && y < -2) then
          if x < 5 || (x == 5 && y < -3) then
            if x < 4 || (x == 4 && y < 4) then
              if x == 4 && y == -4 then 30 else -1
            else
              if x == 4 && y == 4 then 31 else -1
          else
            if x < 5 || (x == 5 && y < 3) then
              if x == 5 && y == -3 then 27 else -1
            else
              if x == 5 && y == 3 then 24 else -1
        else
          if x < 7 || (x == 7 && y < -1) then
            if x < 6 || (x == 6 && y < 2) then
              if x == 6 && y == -2 then 26 else -1
            else
              if x == 6 && y == 2 then 23 else -1
          else
            if x < 7 || (x == 7 && y < 1) then
              if x == 7 && y == -1 then 28 else -1
            else
              if x < 8 || (x == 8 && y < 0) then
                if x == 7 && y == 1 then 25 else -1
              else
                if x == 8 && y == 0 then 4 else -1
  }

  // Stratum z=6 (41 entries)
  opaque function LabelsZ6(): seq<string>
    ensures |LabelsZ6()| == 41
  {
    [
      "Saisissement",
      "Élan",
      "Inertie",
      "Effacement",
      "Affirmation",
      "Ardeur",
      "Angoisse",
      "Allégresse",
      "Fureur",
      "Fougue",
      "Frénésie",
      "Jubilation",
      "Terreur",
      "Béatitude",
      "Accablement",
      "Apaisement",
      "Morosité",
      "Contemplation",
      "Prostration",
      "Félicité",
      "Désolation",
      "Rancœur",
      "Amertume",
      "Affolement",
      "Écrasement",
      "Fébrilité",
      "Anéantissement",
      "Désarroi",
      "Lassitude",
      "Entrain",
      "Placidité",
      "Liesse",
      "Limpidité",
      "Extase",
      "Équanimité",
      "Exultation",
      "Harmonie",
      "Tourment",
      "Ataraxie",
      "Triomphe",
      "Abattement"
    ]
  }

  function PointZ6(i: nat): CoreAffectPoint
    requires i < 41
  {
    if i < 20 then
      if i < 10 then
        if i < 5 then
          if i < 2 then
            if i < 1 then
              CoreAffectPoint(0, 0, 6)
            else
              CoreAffectPoint(0, 10, 6)
          else
            if i < 3 then
              CoreAffectPoint(0, -10, 6)
            else
              if i < 4 then
                CoreAffectPoint(-10, 0, 6)
              else
                CoreAffectPoint(10, 0, 6)
        else
          if i < 7 then
            if i < 6 then
              CoreAffectPoint(3, 7, 6)
            else
              CoreAffectPoint(-3, 7, 6)
          else
            if i < 8 then
              CoreAffectPoint(4, 6, 6)
            else
              if i < 9 then
                CoreAffectPoint(-4, 6, 6)
              else
                CoreAffectPoint(2, 8, 6)
      else
        if i < 15 then
          if i < 12 then
            if i < 11 then
              CoreAffectPoint(-2, 8, 6)
            else
              CoreAffectPoint(1, 9, 6)
          else
            if i < 13 then
              CoreAffectPoint(-1, 9, 6)
            else
              if i < 14 then
                CoreAffectPoint(3, -7, 6)
              else
                CoreAffectPoint(-3, -7, 6)
        else
          if i < 17 then
            if i < 16 then
              CoreAffectPoint(4, -6, 6)
            else
              CoreAffectPoint(-4, -6, 6)
          else
            if i < 18 then
              CoreAffectPoint(2, -8, 6)
            else
              if i < 19 then
                CoreAffectPoint(-2, -8, 6)
              else
                CoreAffectPoint(1, -9, 6)
    else
      if i < 30 then
        if i < 25 then
          if i < 22 then
            if i < 21 then
              CoreAffectPoint(-1, -9, 6)
            else
              CoreAffectPoint(-6, 4, 6)
          else
            if i < 23 then
              CoreAffectPoint(-6, -4, 6)
            else
              if i < 24 then
                CoreAffectPoint(-7, 3, 6)
              else
                CoreAffectPoint(-7, -3, 6)
        else
          if i < 27 then
            if i < 26 then
              CoreAffectPoint(-8, 2, 6)
            else
              CoreAffectPoint(-8, -2, 6)
          else
            if i < 28 then
              CoreAffectPoint(-9, 1, 6)
            else
              if i < 29 then
                CoreAffectPoint(-9, -1, 6)
              else
                CoreAffectPoint(6, 4, 6)
      else
        if i < 35 then
          if i < 32 then
            if i < 31 then
              CoreAffectPoint(6, -4, 6)
            else
              CoreAffectPoint(7, 3, 6)
          else
            if i < 33 then
              CoreAffectPoint(7, -3, 6)
            else
              if i < 34 then
                CoreAffectPoint(8, 2, 6)
              else
                CoreAffectPoint(8, -2, 6)
        else
          if i < 38 then
            if i < 36 then
              CoreAffectPoint(9, 1, 6)
            else
              if i < 37 then
                CoreAffectPoint(9, -1, 6)
              else
                CoreAffectPoint(-5, 5, 6)
          else
            if i < 39 then
              CoreAffectPoint(5, -5, 6)
            else
              if i < 40 then
                CoreAffectPoint(5, 5, 6)
              else
                CoreAffectPoint(-5, -5, 6)
  }

  function EntriesZ6(): seq<LexiconEntry>
    ensures |EntriesZ6()| == 41
    ensures forall i | 0 <= i < 41 :: EntriesZ6()[i].point == PointZ6(i)
  {
    seq(41, i requires 0 <= i < 41 => LexiconEntry(LabelsZ6()[i], PointZ6(i)))
  }

  function IndexInZ6(x: int, y: int): int
  {
    if x < 0 || (x == 0 && y < 0) then
      if x < -5 || (x == -5 && y < 5) then
        if x < -7 || (x == -7 && y < -3) then
          if x < -9 || (x == -9 && y < 1) then
            if x < -9 || (x == -9 && y < -1) then
              if x == -10 && y == 0 then 3 else -1
            else
              if x == -9 && y == -1 then 28 else -1
          else
            if x < -8 || (x == -8 && y < -2) then
              if x == -9 && y == 1 then 27 else -1
            else
              if x < -8 || (x == -8 && y < 2) then
                if x == -8 && y == -2 then 26 else -1
              else
                if x == -8 && y == 2 then 25 else -1
        else
          if x < -6 || (x == -6 && y < -4) then
            if x < -7 || (x == -7 && y < 3) then
              if x == -7 && y == -3 then 24 else -1
            else
              if x == -7 && y == 3 then 23 else -1
          else
            if x < -6 || (x == -6 && y < 4) then
              if x == -6 && y == -4 then 22 else -1
            else
              if x < -5 || (x == -5 && y < -5) then
                if x == -6 && y == 4 then 21 else -1
              else
                if x == -5 && y == -5 then 40 else -1
      else
        if x < -2 || (x == -2 && y < -8) then
          if x < -4 || (x == -4 && y < 6) then
            if x < -4 || (x == -4 && y < -6) then
              if x == -5 && y == 5 then 37 else -1
            else
              if x == -4 && y == -6 then 16 else -1
          else
            if x < -3 || (x == -3 && y < -7) then
              if x == -4 && y == 6 then 8 else -1
            else
              if x < -3 || (x == -3 && y < 7) then
                if x == -3 && y == -7 then 14 else -1
              else
                if x == -3 && y == 7 then 6 else -1
        else
          if x < -1 || (x == -1 && y < -9) then
            if x < -2 || (x == -2 && y < 8) then
              if x == -2 && y == -8 then 18 else -1
            else
              if x == -2 && y == 8 then 10 else -1
          else
            if x < -1 || (x == -1 && y < 9) then
              if x == -1 && y == -9 then 20 else -1
            else
              if x < 0 || (x == 0 && y < -10) then
                if x == -1 && y == 9 then 12 else -1
              else
                if x == 0 && y == -10 then 2 else -1
    else
      if x < 5 || (x == 5 && y < -5) then
        if x < 2 || (x == 2 && y < 8) then
          if x < 1 || (x == 1 && y < -9) then
            if x < 0 || (x == 0 && y < 10) then
              if x == 0 && y == 0 then 0 else -1
            else
              if x == 0 && y == 10 then 1 else -1
          else
            if x < 1 || (x == 1 && y < 9) then
              if x == 1 && y == -9 then 19 else -1
            else
              if x < 2 || (x == 2 && y < -8) then
                if x == 1 && y == 9 then 11 else -1
              else
                if x == 2 && y == -8 then 17 else -1
        else
          if x < 3 || (x == 3 && y < 7) then
            if x < 3 || (x == 3 && y < -7) then
              if x == 2 && y == 8 then 9 else -1
            else
              if x == 3 && y == -7 then 13 else -1
          else
            if x < 4 || (x == 4 && y < -6) then
              if x == 3 && y == 7 then 5 else -1
            else
              if x < 4 || (x == 4 && y < 6) then
                if x == 4 && y == -6 then 15 else -1
              else
                if x == 4 && y == 6 then 7 else -1
      else
        if x < 7 || (x == 7 && y < 3) then
          if x < 6 || (x == 6 && y < -4) then
            if x < 5 || (x == 5 && y < 5) then
              if x == 5 && y == -5 then 38 else -1
            else
              if x == 5 && y == 5 then 39 else -1
          else
            if x < 6 || (x == 6 && y < 4) then
              if x == 6 && y == -4 then 30 else -1
            else
              if x < 7 || (x == 7 && y < -3) then
                if x == 6 && y == 4 then 29 else -1
              else
                if x == 7 && y == -3 then 32 else -1
        else
          if x < 9 || (x == 9 && y < -1) then
            if x < 8 || (x == 8 && y < -2) then
              if x == 7 && y == 3 then 31 else -1
            else
              if x < 8 || (x == 8 && y < 2) then
                if x == 8 && y == -2 then 34 else -1
              else
                if x == 8 && y == 2 then 33 else -1
          else
            if x < 9 || (x == 9 && y < 1) then
              if x == 9 && y == -1 then 36 else -1
            else
              if x < 10 || (x == 10 && y < 0) then
                if x == 9 && y == 1 then 35 else -1
              else
                if x == 10 && y == 0 then 4 else -1
  }

  // Stratum z=7 (49 entries)
  opaque function LabelsZ7(): seq<string>
    ensures |LabelsZ7()| == 49
  {
    [
      "Suspension",
      "Infini",
      "Néant",
      "Déréliction",
      "Communion",
      "Transcendance",
      "Déchirement",
      "Exubérance",
      "Horreur",
      "Renaissance",
      "Vertige",
      "Élévation",
      "Détresse",
      "Enivrement",
      "Révolte",
      "Nirvana",
      "Perdition",
      "Paix",
      "Oppression",
      "Pérennité",
      "Abîme",
      "Abandon",
      "Damnation",
      "Silence",
      "Résignation",
      "Hantise",
      "Isolement",
      "Affliction",
      "Mélancolie",
      "Précarité",
      "Déchéance",
      "Sidération",
      "Engloutissement",
      "Tumulte",
      "Pétrification",
      "Éblouissement",
      "Recueillement",
      "Rayonnement",
      "Contentement",
      "Ravissement",
      "Épiphanie",
      "Louange",
      "Lucidité",
      "Effusion",
      "Consentement",
      "Rage",
      "Impassibilité",
      "Sublimation",
      "Dissolution"
    ]
  }

  function PointZ7(i: nat): CoreAffectPoint
    requires i < 49
  {
    if i < 24 then
      if i < 12 then
        if i < 6 then
          if i < 3 then
            if i < 1 then
              CoreAffectPoint(0, 0, 7)
            else
              if i < 2 then
                CoreAffectPoint(0, 12, 7)
              else
                CoreAffectPoint(0, -12, 7)
          else
            if i < 4 then
              CoreAffectPoint(-12, 0, 7)
            else
              if i < 5 then
                CoreAffectPoint(12, 0, 7)
              else
                CoreAffectPoint(2, 10, 7)
        else
          if i < 9 then
            if i < 7 then
              CoreAffectPoint(-2, 10, 7)
            else
              if i < 8 then
                CoreAffectPoint(4, 8, 7)
              else
                CoreAffectPoint(-4, 8, 7)
          else
            if i < 10 then
              CoreAffectPoint(1, 11, 7)
            else
              if i < 11 then
                CoreAffectPoint(-1, 11, 7)
              else
                CoreAffectPoint(3, 9, 7)
      else
        if i < 18 then
          if i < 15 then
            if i < 13 then
              CoreAffectPoint(-3, 9, 7)
            else
              if i < 14 then
                CoreAffectPoint(5, 7, 7)
              else
                CoreAffectPoint(-5, 7, 7)
          else
            if i < 16 then
              CoreAffectPoint(2, -10, 7)
            else
              if i < 17 then
                CoreAffectPoint(-2, -10, 7)
              else
                CoreAffectPoint(4, -8, 7)
        else
          if i < 21 then
            if i < 19 then
              CoreAffectPoint(-4, -8, 7)
            else
              if i < 20 then
                CoreAffectPoint(1, -11, 7)
              else
                CoreAffectPoint(-1, -11, 7)
          else
            if i < 22 then
              CoreAffectPoint(3, -9, 7)
            else
              if i < 23 then
                CoreAffectPoint(-3, -9, 7)
              else
                CoreAffectPoint(5, -7, 7)
    else
      if i < 36 then
        if i < 30 then
          if i < 27 then
            if i < 25 then
              CoreAffectPoint(-5, -7, 7)
            else
              if i < 26 then
                CoreAffectPoint(-10, 2, 7)
              else
                CoreAffectPoint(-10, -2, 7)
          else
            if i < 28 then
              CoreAffectPoint(-8, 4, 7)
            else
              if i < 29 then
                CoreAffectPoint(-8, -4, 7)
              else
                CoreAffectPoint(-11, 1, 7)
        else
          if i < 33 then
            if i < 31 then
              CoreAffectPoint(-11, -1, 7)
            else
              if i < 32 then
                CoreAffectPoint(-9, 3, 7)
              else
                CoreAffectPoint(-9, -3, 7)
          else
            if i < 34 then
              CoreAffectPoint(-7, 5, 7)
            else
              if i < 35 then
                CoreAffectPoint(-7, -5, 7)
              else
                CoreAffectPoint(10, 2, 7)
      else
        if i < 42 then
          if i < 39 then
            if i < 37 then
              CoreAffectPoint(10, -2, 7)
            else
              if i < 38 then
                CoreAffectPoint(8, 4, 7)
              else
                CoreAffectPoint(8, -4, 7)
          else
            if i < 40 then
              CoreAffectPoint(11, 1, 7)
            else
              if i < 41 then
                CoreAffectPoint(11, -1, 7)
              else
                CoreAffectPoint(9, 3, 7)
        else
          if i < 45 then
            if i < 43 then
              CoreAffectPoint(9, -3, 7)
            else
              if i < 44 then
                CoreAffectPoint(7, 5, 7)
              else
                CoreAffectPoint(7, -5, 7)
          else
            if i < 47 then
              if i < 46 then
                CoreAffectPoint(-6, 6, 7)
              else
                CoreAffectPoint(6, -6, 7)
            else
              if i < 48 then
                CoreAffectPoint(6, 6, 7)
              else
                CoreAffectPoint(-6, -6, 7)
  }

  function EntriesZ7(): seq<LexiconEntry>
    ensures |EntriesZ7()| == 49
    ensures forall i | 0 <= i < 49 :: EntriesZ7()[i].point == PointZ7(i)
  {
    seq(49, i requires 0 <= i < 49 => LexiconEntry(LabelsZ7()[i], PointZ7(i)))
  }

  function IndexInZ7(x: int, y: int): int
  {
    if x < 0 || (x == 0 && y < 0) then
      if x < -6 || (x == -6 && y < 6) then
        if x < -9 || (x == -9 && y < 3) then
          if x < -10 || (x == -10 && y < -2) then
            if x < -11 || (x == -11 && y < -1) then
              if x == -12 && y == 0 then 3 else -1
            else
              if x < -11 || (x == -11 && y < 1) then
                if x == -11 && y == -1 then 30 else -1
              else
                if x == -11 && y == 1 then 29 else -1
          else
            if x < -10 || (x == -10 && y < 2) then
              if x == -10 && y == -2 then 26 else -1
            else
              if x < -9 || (x == -9 && y < -3) then
                if x == -10 && y == 2 then 25 else -1
              else
                if x == -9 && y == -3 then 32 else -1
        else
          if x < -7 || (x == -7 && y < -5) then
            if x < -8 || (x == -8 && y < -4) then
              if x == -9 && y == 3 then 31 else -1
            else
              if x < -8 || (x == -8 && y < 4) then
                if x == -8 && y == -4 then 28 else -1
              else
                if x == -8 && y == 4 then 27 else -1
          else
            if x < -7 || (x == -7 && y < 5) then
              if x == -7 && y == -5 then 34 else -1
            else
              if x < -6 || (x == -6 && y < -6) then
                if x == -7 && y == 5 then 33 else -1
              else
                if x == -6 && y == -6 then 48 else -1
      else
        if x < -3 || (x == -3 && y < 9) then
          if x < -4 || (x == -4 && y < -8) then
            if x < -5 || (x == -5 && y < -7) then
              if x == -6 && y == 6 then 45 else -1
            else
              if x < -5 || (x == -5 && y < 7) then
                if x == -5 && y == -7 then 24 else -1
              else
                if x == -5 && y == 7 then 14 else -1
          else
            if x < -4 || (x == -4 && y < 8) then
              if x == -4 && y == -8 then 18 else -1
            else
              if x < -3 || (x == -3 && y < -9) then
                if x == -4 && y == 8 then 8 else -1
              else
                if x == -3 && y == -9 then 22 else -1
        else
          if x < -1 || (x == -1 && y < -11) then
            if x < -2 || (x == -2 && y < -10) then
              if x == -3 && y == 9 then 12 else -1
            else
              if x < -2 || (x == -2 && y < 10) then
                if x == -2 && y == -10 then 16 else -1
              else
                if x == -2 && y == 10 then 6 else -1
          else
            if x < -1 || (x == -1 && y < 11) then
              if x == -1 && y == -11 then 20 else -1
            else
              if x < 0 || (x == 0 && y < -12) then
                if x == -1 && y == 11 then 10 else -1
              else
                if x == 0 && y == -12 then 2 else -1
    else
      if x < 6 || (x == 6 && y < -6) then
        if x < 3 || (x == 3 && y < -9) then
          if x < 1 || (x == 1 && y < 11) then
            if x < 0 || (x == 0 && y < 12) then
              if x == 0 && y == 0 then 0 else -1
            else
              if x < 1 || (x == 1 && y < -11) then
                if x == 0 && y == 12 then 1 else -1
              else
                if x == 1 && y == -11 then 19 else -1
          else
            if x < 2 || (x == 2 && y < -10) then
              if x == 1 && y == 11 then 9 else -1
            else
              if x < 2 || (x == 2 && y < 10) then
                if x == 2 && y == -10 then 15 else -1
              else
                if x == 2 && y == 10 then 5 else -1
        else
          if x < 4 || (x == 4 && y < 8) then
            if x < 3 || (x == 3 && y < 9) then
              if x == 3 && y == -9 then 21 else -1
            else
              if x < 4 || (x == 4 && y < -8) then
                if x == 3 && y == 9 then 11 else -1
              else
                if x == 4 && y == -8 then 17 else -1
          else
            if x < 5 || (x == 5 && y < -7) then
              if x == 4 && y == 8 then 7 else -1
            else
              if x < 5 || (x == 5 && y < 7) then
                if x == 5 && y == -7 then 23 else -1
              else
                if x == 5 && y == 7 then 13 else -1
      else
        if x < 9 || (x == 9 && y < -3) then
          if x < 7 || (x == 7 && y < 5) then
            if x < 6 || (x == 6 && y < 6) then
              if x == 6 && y == -6 then 46 else -1
            else
              if x < 7 || (x == 7 && y < -5) then
                if x == 6 && y == 6 then 47 else -1
              else
                if x == 7 && y == -5 then 44 else -1
          else
            if x < 8 || (x == 8 && y < -4) then
              if x == 7 && y == 5 then 43 else -1
            else
              if x < 8 || (x == 8 && y < 4) then
                if x == 8 && y == -4 then 38 else -1
              else
                if x == 8 && y == 4 then 37 else -1
        else
          if x < 10 || (x == 10 && y < 2) then
            if x < 9 || (x == 9 && y < 3) then
              if x == 9 && y == -3 then 42 else -1
            else
              if x < 10 || (x == 10 && y < -2) then
                if x == 9 && y == 3 then 41 else -1
              else
                if x == 10 && y == -2 then 36 else -1
          else
            if x < 11 || (x == 11 && y < 1) then
              if x < 11 || (x == 11 && y < -1) then
                if x == 10 && y == 2 then 35 else -1
              else
                if x == 11 && y == -1 then 40 else -1
            else
              if x < 12 || (x == 12 && y < 0) then
                if x == 11 && y == 1 then 39 else -1
              else
                if x == 12 && y == 0 then 4 else -1
  }

  function GlobalPoint(i: nat): CoreAffectPoint
    requires i < 176
  {
    if i < 28 then
      if i < 11 then
        if i < 2 then
          if i < 1 then PointZ0(i) else PointZ1(i - 1)
        else
          PointZ2(i - 2)
      else
        PointZ3(i - 11)
    else
      if i < 86 then
        if i < 53 then PointZ4(i - 28) else PointZ5(i - 53)
      else
        if i < 127 then PointZ6(i - 86) else PointZ7(i - 127)
  }

  function StratumOffset(z: nat): nat
    requires z <= 7
  {
    match z
    case 0 => 0
    case 1 => 1
    case 2 => 2
    case 3 => 11
    case 4 => 28
    case 5 => 53
    case 6 => 86
    case 7 => 127
  }

  opaque function All176Entries(): seq<LexiconEntry>
    ensures |All176Entries()| == 176
    ensures forall i | 0 <= i < 176 :: All176Entries()[i].point == GlobalPoint(i)
  {
    var r := EntriesZ0() + EntriesZ1() + EntriesZ2() + EntriesZ3() +
             EntriesZ4() + EntriesZ5() + EntriesZ6() + EntriesZ7();
    assert |r| == 176;
    r
  }

  opaque function LexiconPoints(): seq<CoreAffectPoint>
    ensures |LexiconPoints()| == 176
    ensures forall i | 0 <= i < 176 :: LexiconPoints()[i] == GlobalPoint(i)
  {
    seq(176, i requires 0 <= i < 176 => GlobalPoint(i))
  }

  lemma {:isolate_assertions} CheckZ0Point(i: nat)
    requires i < 1
    ensures PointZ0(i).z == 0
    ensures IsValidPointBool(PointZ0(i))
    ensures IsValidCoreAffect(PointZ0(i))
    ensures IndexInZ0(PointZ0(i).x, PointZ0(i).y) == i
  {
    // idx 0: (0, 0, 0)
    assert PointZ0(0) == CoreAffectPoint(0, 0, 0);
  }

  lemma StratumZ0Complete(p: CoreAffectPoint)
    requires p.z == 0 && IsValidCoreAffect(p)
    ensures 0 <= IndexInZ0(p.x, p.y) < 1 && EntriesZ0()[IndexInZ0(p.x, p.y)].point == p
  {
    assert p.x == 0 && p.y == 0;
  }

  lemma {:isolate_assertions} CheckZ1Point(i: nat)
    requires i < 1
    ensures PointZ1(i).z == 1
    ensures IsValidPointBool(PointZ1(i))
    ensures IsValidCoreAffect(PointZ1(i))
    ensures IndexInZ1(PointZ1(i).x, PointZ1(i).y) == i
  {
    // idx 0: (0, 0, 1)
    assert PointZ1(0) == CoreAffectPoint(0, 0, 1);
  }

  lemma StratumZ1Complete(p: CoreAffectPoint)
    requires p.z == 1 && IsValidCoreAffect(p)
    ensures 0 <= IndexInZ1(p.x, p.y) < 1 && EntriesZ1()[IndexInZ1(p.x, p.y)].point == p
  {
    assert p.x == 0 && p.y == 0;
  }

  lemma {:isolate_assertions} CheckZ2Point(i: nat)
    requires i < 9
    ensures PointZ2(i).z == 2
    ensures IsValidPointBool(PointZ2(i))
    ensures IsValidCoreAffect(PointZ2(i))
    ensures IndexInZ2(PointZ2(i).x, PointZ2(i).y) == i
  {
    if i < 4 {
      if i < 2 {
        if i < 1 {
          // idx 0: (0, 0, 2)
          assert PointZ2(0) == CoreAffectPoint(0, 0, 2);
        } else {
          // idx 1: (0, 2, 2)
          assert PointZ2(1) == CoreAffectPoint(0, 2, 2);
        }
      } else {
        if i < 3 {
          // idx 2: (0, -2, 2)
          assert PointZ2(2) == CoreAffectPoint(0, -2, 2);
        } else {
          // idx 3: (-2, 0, 2)
          assert PointZ2(3) == CoreAffectPoint(-2, 0, 2);
        }
      }
    } else {
      if i < 6 {
        if i < 5 {
          // idx 4: (2, 0, 2)
          assert PointZ2(4) == CoreAffectPoint(2, 0, 2);
        } else {
          // idx 5: (-1, 1, 2)
          assert PointZ2(5) == CoreAffectPoint(-1, 1, 2);
        }
      } else {
        if i < 7 {
          // idx 6: (1, -1, 2)
          assert PointZ2(6) == CoreAffectPoint(1, -1, 2);
        } else {
          if i < 8 {
            // idx 7: (1, 1, 2)
            assert PointZ2(7) == CoreAffectPoint(1, 1, 2);
          } else {
            // idx 8: (-1, -1, 2)
            assert PointZ2(8) == CoreAffectPoint(-1, -1, 2);
          }
        }
      }
    }
  }

  lemma {:isolate_assertions} StratumZ2Complete(p: CoreAffectPoint)
    requires p.z == 2 && IsValidCoreAffect(p)
    ensures 0 <= IndexInZ2(p.x, p.y) < 9 && EntriesZ2()[IndexInZ2(p.x, p.y)].point == p
  {
    if p.x == 0 && p.y == 0 {
      assert IndexInZ2(p.x, p.y) == 0 && EntriesZ2()[0].point == p;
    } else {
      assert AbsNat(p.x) + AbsNat(p.y) == 2;
      if p.x < 0 {
        if p.x < -1 {
          assert p.y == 0 && IndexInZ2(p.x, p.y) == 3 && EntriesZ2()[3].point == p;
        } else {
          if p.y >= 0 {
            assert p.y == 1 && IndexInZ2(p.x, p.y) == 5 && EntriesZ2()[5].point == p;
          } else {
            assert p.y == -1 && IndexInZ2(p.x, p.y) == 8 && EntriesZ2()[8].point == p;
          }
        }
      } else {
        if p.x < 1 {
          if p.y >= 0 {
            assert p.y == 2 && IndexInZ2(p.x, p.y) == 1 && EntriesZ2()[1].point == p;
          } else {
            assert p.y == -2 && IndexInZ2(p.x, p.y) == 2 && EntriesZ2()[2].point == p;
          }
        } else {
          if p.x < 2 {
            if p.y >= 0 {
              assert p.y == 1 && IndexInZ2(p.x, p.y) == 7 && EntriesZ2()[7].point == p;
            } else {
              assert p.y == -1 && IndexInZ2(p.x, p.y) == 6 && EntriesZ2()[6].point == p;
            }
          } else {
            assert p.y == 0 && IndexInZ2(p.x, p.y) == 4 && EntriesZ2()[4].point == p;
          }
        }
      }
    }
  }

  lemma {:isolate_assertions} CheckZ3Point(i: nat)
    requires i < 17
    ensures PointZ3(i).z == 3
    ensures IsValidPointBool(PointZ3(i))
    ensures IsValidCoreAffect(PointZ3(i))
    ensures IndexInZ3(PointZ3(i).x, PointZ3(i).y) == i
  {
    if i < 8 {
      if i < 4 {
        if i < 2 {
          if i < 1 {
            // idx 0: (0, 0, 3)
            assert PointZ3(0) == CoreAffectPoint(0, 0, 3);
          } else {
            // idx 1: (0, 4, 3)
            assert PointZ3(1) == CoreAffectPoint(0, 4, 3);
          }
        } else {
          if i < 3 {
            // idx 2: (0, -4, 3)
            assert PointZ3(2) == CoreAffectPoint(0, -4, 3);
          } else {
            // idx 3: (-4, 0, 3)
            assert PointZ3(3) == CoreAffectPoint(-4, 0, 3);
          }
        }
      } else {
        if i < 6 {
          if i < 5 {
            // idx 4: (4, 0, 3)
            assert PointZ3(4) == CoreAffectPoint(4, 0, 3);
          } else {
            // idx 5: (-1, 3, 3)
            assert PointZ3(5) == CoreAffectPoint(-1, 3, 3);
          }
        } else {
          if i < 7 {
            // idx 6: (1, 3, 3)
            assert PointZ3(6) == CoreAffectPoint(1, 3, 3);
          } else {
            // idx 7: (1, -3, 3)
            assert PointZ3(7) == CoreAffectPoint(1, -3, 3);
          }
        }
      }
    } else {
      if i < 12 {
        if i < 10 {
          if i < 9 {
            // idx 8: (-1, -3, 3)
            assert PointZ3(8) == CoreAffectPoint(-1, -3, 3);
          } else {
            // idx 9: (-3, 1, 3)
            assert PointZ3(9) == CoreAffectPoint(-3, 1, 3);
          }
        } else {
          if i < 11 {
            // idx 10: (-3, -1, 3)
            assert PointZ3(10) == CoreAffectPoint(-3, -1, 3);
          } else {
            // idx 11: (3, -1, 3)
            assert PointZ3(11) == CoreAffectPoint(3, -1, 3);
          }
        }
      } else {
        if i < 14 {
          if i < 13 {
            // idx 12: (3, 1, 3)
            assert PointZ3(12) == CoreAffectPoint(3, 1, 3);
          } else {
            // idx 13: (-2, 2, 3)
            assert PointZ3(13) == CoreAffectPoint(-2, 2, 3);
          }
        } else {
          if i < 15 {
            // idx 14: (2, -2, 3)
            assert PointZ3(14) == CoreAffectPoint(2, -2, 3);
          } else {
            if i < 16 {
              // idx 15: (2, 2, 3)
              assert PointZ3(15) == CoreAffectPoint(2, 2, 3);
            } else {
              // idx 16: (-2, -2, 3)
              assert PointZ3(16) == CoreAffectPoint(-2, -2, 3);
            }
          }
        }
      }
    }
  }

  lemma {:isolate_assertions} StratumZ3Complete(p: CoreAffectPoint)
    requires p.z == 3 && IsValidCoreAffect(p)
    ensures 0 <= IndexInZ3(p.x, p.y) < 17 && EntriesZ3()[IndexInZ3(p.x, p.y)].point == p
  {
    if p.x == 0 && p.y == 0 {
      assert IndexInZ3(p.x, p.y) == 0 && EntriesZ3()[0].point == p;
    } else {
      assert AbsNat(p.x) + AbsNat(p.y) == 4;
      if p.x < 0 {
        if p.x < -2 {
          if p.x < -3 {
            assert p.y == 0 && IndexInZ3(p.x, p.y) == 3 && EntriesZ3()[3].point == p;
          } else {
            if p.y >= 0 {
              assert p.y == 1 && IndexInZ3(p.x, p.y) == 9 && EntriesZ3()[9].point == p;
            } else {
              assert p.y == -1 && IndexInZ3(p.x, p.y) == 10 && EntriesZ3()[10].point == p;
            }
          }
        } else {
          if p.x < -1 {
            if p.y >= 0 {
              assert p.y == 2 && IndexInZ3(p.x, p.y) == 13 && EntriesZ3()[13].point == p;
            } else {
              assert p.y == -2 && IndexInZ3(p.x, p.y) == 16 && EntriesZ3()[16].point == p;
            }
          } else {
            if p.y >= 0 {
              assert p.y == 3 && IndexInZ3(p.x, p.y) == 5 && EntriesZ3()[5].point == p;
            } else {
              assert p.y == -3 && IndexInZ3(p.x, p.y) == 8 && EntriesZ3()[8].point == p;
            }
          }
        }
      } else {
        if p.x < 2 {
          if p.x < 1 {
            if p.y >= 0 {
              assert p.y == 4 && IndexInZ3(p.x, p.y) == 1 && EntriesZ3()[1].point == p;
            } else {
              assert p.y == -4 && IndexInZ3(p.x, p.y) == 2 && EntriesZ3()[2].point == p;
            }
          } else {
            if p.y >= 0 {
              assert p.y == 3 && IndexInZ3(p.x, p.y) == 6 && EntriesZ3()[6].point == p;
            } else {
              assert p.y == -3 && IndexInZ3(p.x, p.y) == 7 && EntriesZ3()[7].point == p;
            }
          }
        } else {
          if p.x < 3 {
            if p.y >= 0 {
              assert p.y == 2 && IndexInZ3(p.x, p.y) == 15 && EntriesZ3()[15].point == p;
            } else {
              assert p.y == -2 && IndexInZ3(p.x, p.y) == 14 && EntriesZ3()[14].point == p;
            }
          } else {
            if p.x < 4 {
              if p.y >= 0 {
                assert p.y == 1 && IndexInZ3(p.x, p.y) == 12 && EntriesZ3()[12].point == p;
              } else {
                assert p.y == -1 && IndexInZ3(p.x, p.y) == 11 && EntriesZ3()[11].point == p;
              }
            } else {
              assert p.y == 0 && IndexInZ3(p.x, p.y) == 4 && EntriesZ3()[4].point == p;
            }
          }
        }
      }
    }
  }

  lemma {:isolate_assertions} CheckZ4Point(i: nat)
    requires i < 25
    ensures PointZ4(i).z == 4
    ensures IsValidPointBool(PointZ4(i))
    ensures IsValidCoreAffect(PointZ4(i))
    ensures IndexInZ4(PointZ4(i).x, PointZ4(i).y) == i
  {
    if i < 12 {
      if i < 6 {
        if i < 3 {
          if i < 1 {
            // idx 0: (0, 0, 4)
            assert PointZ4(0) == CoreAffectPoint(0, 0, 4);
          } else {
            if i < 2 {
              // idx 1: (0, 6, 4)
              assert PointZ4(1) == CoreAffectPoint(0, 6, 4);
            } else {
              // idx 2: (0, -6, 4)
              assert PointZ4(2) == CoreAffectPoint(0, -6, 4);
            }
          }
        } else {
          if i < 4 {
            // idx 3: (-6, 0, 4)
            assert PointZ4(3) == CoreAffectPoint(-6, 0, 4);
          } else {
            if i < 5 {
              // idx 4: (6, 0, 4)
              assert PointZ4(4) == CoreAffectPoint(6, 0, 4);
            } else {
              // idx 5: (-2, 4, 4)
              assert PointZ4(5) == CoreAffectPoint(-2, 4, 4);
            }
          }
        }
      } else {
        if i < 9 {
          if i < 7 {
            // idx 6: (-1, 5, 4)
            assert PointZ4(6) == CoreAffectPoint(-1, 5, 4);
          } else {
            if i < 8 {
              // idx 7: (1, 5, 4)
              assert PointZ4(7) == CoreAffectPoint(1, 5, 4);
            } else {
              // idx 8: (2, 4, 4)
              assert PointZ4(8) == CoreAffectPoint(2, 4, 4);
            }
          }
        } else {
          if i < 10 {
            // idx 9: (2, -4, 4)
            assert PointZ4(9) == CoreAffectPoint(2, -4, 4);
          } else {
            if i < 11 {
              // idx 10: (1, -5, 4)
              assert PointZ4(10) == CoreAffectPoint(1, -5, 4);
            } else {
              // idx 11: (-2, -4, 4)
              assert PointZ4(11) == CoreAffectPoint(-2, -4, 4);
            }
          }
        }
      }
    } else {
      if i < 18 {
        if i < 15 {
          if i < 13 {
            // idx 12: (-1, -5, 4)
            assert PointZ4(12) == CoreAffectPoint(-1, -5, 4);
          } else {
            if i < 14 {
              // idx 13: (-4, 2, 4)
              assert PointZ4(13) == CoreAffectPoint(-4, 2, 4);
            } else {
              // idx 14: (-5, 1, 4)
              assert PointZ4(14) == CoreAffectPoint(-5, 1, 4);
            }
          }
        } else {
          if i < 16 {
            // idx 15: (-5, -1, 4)
            assert PointZ4(15) == CoreAffectPoint(-5, -1, 4);
          } else {
            if i < 17 {
              // idx 16: (-4, -2, 4)
              assert PointZ4(16) == CoreAffectPoint(-4, -2, 4);
            } else {
              // idx 17: (4, 2, 4)
              assert PointZ4(17) == CoreAffectPoint(4, 2, 4);
            }
          }
        }
      } else {
        if i < 21 {
          if i < 19 {
            // idx 18: (5, 1, 4)
            assert PointZ4(18) == CoreAffectPoint(5, 1, 4);
          } else {
            if i < 20 {
              // idx 19: (5, -1, 4)
              assert PointZ4(19) == CoreAffectPoint(5, -1, 4);
            } else {
              // idx 20: (4, -2, 4)
              assert PointZ4(20) == CoreAffectPoint(4, -2, 4);
            }
          }
        } else {
          if i < 23 {
            if i < 22 {
              // idx 21: (-3, 3, 4)
              assert PointZ4(21) == CoreAffectPoint(-3, 3, 4);
            } else {
              // idx 22: (3, -3, 4)
              assert PointZ4(22) == CoreAffectPoint(3, -3, 4);
            }
          } else {
            if i < 24 {
              // idx 23: (3, 3, 4)
              assert PointZ4(23) == CoreAffectPoint(3, 3, 4);
            } else {
              // idx 24: (-3, -3, 4)
              assert PointZ4(24) == CoreAffectPoint(-3, -3, 4);
            }
          }
        }
      }
    }
  }

  lemma {:isolate_assertions} StratumZ4Complete(p: CoreAffectPoint)
    requires p.z == 4 && IsValidCoreAffect(p)
    ensures 0 <= IndexInZ4(p.x, p.y) < 25 && EntriesZ4()[IndexInZ4(p.x, p.y)].point == p
  {
    if p.x == 0 && p.y == 0 {
      assert IndexInZ4(p.x, p.y) == 0 && EntriesZ4()[0].point == p;
    } else {
      assert AbsNat(p.x) + AbsNat(p.y) == 6;
      if p.x < 0 {
        if p.x < -3 {
          if p.x < -5 {
            assert p.y == 0 && IndexInZ4(p.x, p.y) == 3 && EntriesZ4()[3].point == p;
          } else {
            if p.x < -4 {
              if p.y >= 0 {
                assert p.y == 1 && IndexInZ4(p.x, p.y) == 14 && EntriesZ4()[14].point == p;
              } else {
                assert p.y == -1 && IndexInZ4(p.x, p.y) == 15 && EntriesZ4()[15].point == p;
              }
            } else {
              if p.y >= 0 {
                assert p.y == 2 && IndexInZ4(p.x, p.y) == 13 && EntriesZ4()[13].point == p;
              } else {
                assert p.y == -2 && IndexInZ4(p.x, p.y) == 16 && EntriesZ4()[16].point == p;
              }
            }
          }
        } else {
          if p.x < -2 {
            if p.y >= 0 {
              assert p.y == 3 && IndexInZ4(p.x, p.y) == 21 && EntriesZ4()[21].point == p;
            } else {
              assert p.y == -3 && IndexInZ4(p.x, p.y) == 24 && EntriesZ4()[24].point == p;
            }
          } else {
            if p.x < -1 {
              if p.y >= 0 {
                assert p.y == 4 && IndexInZ4(p.x, p.y) == 5 && EntriesZ4()[5].point == p;
              } else {
                assert p.y == -4 && IndexInZ4(p.x, p.y) == 11 && EntriesZ4()[11].point == p;
              }
            } else {
              if p.y >= 0 {
                assert p.y == 5 && IndexInZ4(p.x, p.y) == 6 && EntriesZ4()[6].point == p;
              } else {
                assert p.y == -5 && IndexInZ4(p.x, p.y) == 12 && EntriesZ4()[12].point == p;
              }
            }
          }
        }
      } else {
        if p.x < 3 {
          if p.x < 1 {
            if p.y >= 0 {
              assert p.y == 6 && IndexInZ4(p.x, p.y) == 1 && EntriesZ4()[1].point == p;
            } else {
              assert p.y == -6 && IndexInZ4(p.x, p.y) == 2 && EntriesZ4()[2].point == p;
            }
          } else {
            if p.x < 2 {
              if p.y >= 0 {
                assert p.y == 5 && IndexInZ4(p.x, p.y) == 7 && EntriesZ4()[7].point == p;
              } else {
                assert p.y == -5 && IndexInZ4(p.x, p.y) == 10 && EntriesZ4()[10].point == p;
              }
            } else {
              if p.y >= 0 {
                assert p.y == 4 && IndexInZ4(p.x, p.y) == 8 && EntriesZ4()[8].point == p;
              } else {
                assert p.y == -4 && IndexInZ4(p.x, p.y) == 9 && EntriesZ4()[9].point == p;
              }
            }
          }
        } else {
          if p.x < 5 {
            if p.x < 4 {
              if p.y >= 0 {
                assert p.y == 3 && IndexInZ4(p.x, p.y) == 23 && EntriesZ4()[23].point == p;
              } else {
                assert p.y == -3 && IndexInZ4(p.x, p.y) == 22 && EntriesZ4()[22].point == p;
              }
            } else {
              if p.y >= 0 {
                assert p.y == 2 && IndexInZ4(p.x, p.y) == 17 && EntriesZ4()[17].point == p;
              } else {
                assert p.y == -2 && IndexInZ4(p.x, p.y) == 20 && EntriesZ4()[20].point == p;
              }
            }
          } else {
            if p.x < 6 {
              if p.y >= 0 {
                assert p.y == 1 && IndexInZ4(p.x, p.y) == 18 && EntriesZ4()[18].point == p;
              } else {
                assert p.y == -1 && IndexInZ4(p.x, p.y) == 19 && EntriesZ4()[19].point == p;
              }
            } else {
              assert p.y == 0 && IndexInZ4(p.x, p.y) == 4 && EntriesZ4()[4].point == p;
            }
          }
        }
      }
    }
  }

  lemma {:isolate_assertions} CheckZ5Point(i: nat)
    requires i < 33
    ensures PointZ5(i).z == 5
    ensures IsValidPointBool(PointZ5(i))
    ensures IsValidCoreAffect(PointZ5(i))
    ensures IndexInZ5(PointZ5(i).x, PointZ5(i).y) == i
  {
    if i < 16 {
      if i < 8 {
        if i < 4 {
          if i < 2 {
            if i < 1 {
              // idx 0: (0, 0, 5)
              assert PointZ5(0) == CoreAffectPoint(0, 0, 5);
            } else {
              // idx 1: (0, 8, 5)
              assert PointZ5(1) == CoreAffectPoint(0, 8, 5);
            }
          } else {
            if i < 3 {
              // idx 2: (0, -8, 5)
              assert PointZ5(2) == CoreAffectPoint(0, -8, 5);
            } else {
              // idx 3: (-8, 0, 5)
              assert PointZ5(3) == CoreAffectPoint(-8, 0, 5);
            }
          }
        } else {
          if i < 6 {
            if i < 5 {
              // idx 4: (8, 0, 5)
              assert PointZ5(4) == CoreAffectPoint(8, 0, 5);
            } else {
              // idx 5: (1, 7, 5)
              assert PointZ5(5) == CoreAffectPoint(1, 7, 5);
            }
          } else {
            if i < 7 {
              // idx 6: (2, 6, 5)
              assert PointZ5(6) == CoreAffectPoint(2, 6, 5);
            } else {
              // idx 7: (3, 5, 5)
              assert PointZ5(7) == CoreAffectPoint(3, 5, 5);
            }
          }
        }
      } else {
        if i < 12 {
          if i < 10 {
            if i < 9 {
              // idx 8: (-2, 6, 5)
              assert PointZ5(8) == CoreAffectPoint(-2, 6, 5);
            } else {
              // idx 9: (-3, 5, 5)
              assert PointZ5(9) == CoreAffectPoint(-3, 5, 5);
            }
          } else {
            if i < 11 {
              // idx 10: (-1, 7, 5)
              assert PointZ5(10) == CoreAffectPoint(-1, 7, 5);
            } else {
              // idx 11: (3, -5, 5)
              assert PointZ5(11) == CoreAffectPoint(3, -5, 5);
            }
          }
        } else {
          if i < 14 {
            if i < 13 {
              // idx 12: (2, -6, 5)
              assert PointZ5(12) == CoreAffectPoint(2, -6, 5);
            } else {
              // idx 13: (1, -7, 5)
              assert PointZ5(13) == CoreAffectPoint(1, -7, 5);
            }
          } else {
            if i < 15 {
              // idx 14: (-2, -6, 5)
              assert PointZ5(14) == CoreAffectPoint(-2, -6, 5);
            } else {
              // idx 15: (-3, -5, 5)
              assert PointZ5(15) == CoreAffectPoint(-3, -5, 5);
            }
          }
        }
      }
    } else {
      if i < 24 {
        if i < 20 {
          if i < 18 {
            if i < 17 {
              // idx 16: (-1, -7, 5)
              assert PointZ5(16) == CoreAffectPoint(-1, -7, 5);
            } else {
              // idx 17: (-6, 2, 5)
              assert PointZ5(17) == CoreAffectPoint(-6, 2, 5);
            }
          } else {
            if i < 19 {
              // idx 18: (-5, 3, 5)
              assert PointZ5(18) == CoreAffectPoint(-5, 3, 5);
            } else {
              // idx 19: (-7, 1, 5)
              assert PointZ5(19) == CoreAffectPoint(-7, 1, 5);
            }
          }
        } else {
          if i < 22 {
            if i < 21 {
              // idx 20: (-7, -1, 5)
              assert PointZ5(20) == CoreAffectPoint(-7, -1, 5);
            } else {
              // idx 21: (-6, -2, 5)
              assert PointZ5(21) == CoreAffectPoint(-6, -2, 5);
            }
          } else {
            if i < 23 {
              // idx 22: (-5, -3, 5)
              assert PointZ5(22) == CoreAffectPoint(-5, -3, 5);
            } else {
              // idx 23: (6, 2, 5)
              assert PointZ5(23) == CoreAffectPoint(6, 2, 5);
            }
          }
        }
      } else {
        if i < 28 {
          if i < 26 {
            if i < 25 {
              // idx 24: (5, 3, 5)
              assert PointZ5(24) == CoreAffectPoint(5, 3, 5);
            } else {
              // idx 25: (7, 1, 5)
              assert PointZ5(25) == CoreAffectPoint(7, 1, 5);
            }
          } else {
            if i < 27 {
              // idx 26: (6, -2, 5)
              assert PointZ5(26) == CoreAffectPoint(6, -2, 5);
            } else {
              // idx 27: (5, -3, 5)
              assert PointZ5(27) == CoreAffectPoint(5, -3, 5);
            }
          }
        } else {
          if i < 30 {
            if i < 29 {
              // idx 28: (7, -1, 5)
              assert PointZ5(28) == CoreAffectPoint(7, -1, 5);
            } else {
              // idx 29: (-4, 4, 5)
              assert PointZ5(29) == CoreAffectPoint(-4, 4, 5);
            }
          } else {
            if i < 31 {
              // idx 30: (4, -4, 5)
              assert PointZ5(30) == CoreAffectPoint(4, -4, 5);
            } else {
              if i < 32 {
                // idx 31: (4, 4, 5)
                assert PointZ5(31) == CoreAffectPoint(4, 4, 5);
              } else {
                // idx 32: (-4, -4, 5)
                assert PointZ5(32) == CoreAffectPoint(-4, -4, 5);
              }
            }
          }
        }
      }
    }
  }

  lemma {:isolate_assertions} StratumZ5Complete(p: CoreAffectPoint)
    requires p.z == 5 && IsValidCoreAffect(p)
    ensures 0 <= IndexInZ5(p.x, p.y) < 33 && EntriesZ5()[IndexInZ5(p.x, p.y)].point == p
  {
    if p.x == 0 && p.y == 0 {
      assert IndexInZ5(p.x, p.y) == 0 && EntriesZ5()[0].point == p;
    } else {
      assert AbsNat(p.x) + AbsNat(p.y) == 8;
      if p.x < 0 {
        if p.x < -4 {
          if p.x < -6 {
            if p.x < -7 {
              assert p.y == 0 && IndexInZ5(p.x, p.y) == 3 && EntriesZ5()[3].point == p;
            } else {
              if p.y >= 0 {
                assert p.y == 1 && IndexInZ5(p.x, p.y) == 19 && EntriesZ5()[19].point == p;
              } else {
                assert p.y == -1 && IndexInZ5(p.x, p.y) == 20 && EntriesZ5()[20].point == p;
              }
            }
          } else {
            if p.x < -5 {
              if p.y >= 0 {
                assert p.y == 2 && IndexInZ5(p.x, p.y) == 17 && EntriesZ5()[17].point == p;
              } else {
                assert p.y == -2 && IndexInZ5(p.x, p.y) == 21 && EntriesZ5()[21].point == p;
              }
            } else {
              if p.y >= 0 {
                assert p.y == 3 && IndexInZ5(p.x, p.y) == 18 && EntriesZ5()[18].point == p;
              } else {
                assert p.y == -3 && IndexInZ5(p.x, p.y) == 22 && EntriesZ5()[22].point == p;
              }
            }
          }
        } else {
          if p.x < -2 {
            if p.x < -3 {
              if p.y >= 0 {
                assert p.y == 4 && IndexInZ5(p.x, p.y) == 29 && EntriesZ5()[29].point == p;
              } else {
                assert p.y == -4 && IndexInZ5(p.x, p.y) == 32 && EntriesZ5()[32].point == p;
              }
            } else {
              if p.y >= 0 {
                assert p.y == 5 && IndexInZ5(p.x, p.y) == 9 && EntriesZ5()[9].point == p;
              } else {
                assert p.y == -5 && IndexInZ5(p.x, p.y) == 15 && EntriesZ5()[15].point == p;
              }
            }
          } else {
            if p.x < -1 {
              if p.y >= 0 {
                assert p.y == 6 && IndexInZ5(p.x, p.y) == 8 && EntriesZ5()[8].point == p;
              } else {
                assert p.y == -6 && IndexInZ5(p.x, p.y) == 14 && EntriesZ5()[14].point == p;
              }
            } else {
              if p.y >= 0 {
                assert p.y == 7 && IndexInZ5(p.x, p.y) == 10 && EntriesZ5()[10].point == p;
              } else {
                assert p.y == -7 && IndexInZ5(p.x, p.y) == 16 && EntriesZ5()[16].point == p;
              }
            }
          }
        }
      } else {
        if p.x < 4 {
          if p.x < 2 {
            if p.x < 1 {
              if p.y >= 0 {
                assert p.y == 8 && IndexInZ5(p.x, p.y) == 1 && EntriesZ5()[1].point == p;
              } else {
                assert p.y == -8 && IndexInZ5(p.x, p.y) == 2 && EntriesZ5()[2].point == p;
              }
            } else {
              if p.y >= 0 {
                assert p.y == 7 && IndexInZ5(p.x, p.y) == 5 && EntriesZ5()[5].point == p;
              } else {
                assert p.y == -7 && IndexInZ5(p.x, p.y) == 13 && EntriesZ5()[13].point == p;
              }
            }
          } else {
            if p.x < 3 {
              if p.y >= 0 {
                assert p.y == 6 && IndexInZ5(p.x, p.y) == 6 && EntriesZ5()[6].point == p;
              } else {
                assert p.y == -6 && IndexInZ5(p.x, p.y) == 12 && EntriesZ5()[12].point == p;
              }
            } else {
              if p.y >= 0 {
                assert p.y == 5 && IndexInZ5(p.x, p.y) == 7 && EntriesZ5()[7].point == p;
              } else {
                assert p.y == -5 && IndexInZ5(p.x, p.y) == 11 && EntriesZ5()[11].point == p;
              }
            }
          }
        } else {
          if p.x < 6 {
            if p.x < 5 {
              if p.y >= 0 {
                assert p.y == 4 && IndexInZ5(p.x, p.y) == 31 && EntriesZ5()[31].point == p;
              } else {
                assert p.y == -4 && IndexInZ5(p.x, p.y) == 30 && EntriesZ5()[30].point == p;
              }
            } else {
              if p.y >= 0 {
                assert p.y == 3 && IndexInZ5(p.x, p.y) == 24 && EntriesZ5()[24].point == p;
              } else {
                assert p.y == -3 && IndexInZ5(p.x, p.y) == 27 && EntriesZ5()[27].point == p;
              }
            }
          } else {
            if p.x < 7 {
              if p.y >= 0 {
                assert p.y == 2 && IndexInZ5(p.x, p.y) == 23 && EntriesZ5()[23].point == p;
              } else {
                assert p.y == -2 && IndexInZ5(p.x, p.y) == 26 && EntriesZ5()[26].point == p;
              }
            } else {
              if p.x < 8 {
                if p.y >= 0 {
                  assert p.y == 1 && IndexInZ5(p.x, p.y) == 25 && EntriesZ5()[25].point == p;
                } else {
                  assert p.y == -1 && IndexInZ5(p.x, p.y) == 28 && EntriesZ5()[28].point == p;
                }
              } else {
                assert p.y == 0 && IndexInZ5(p.x, p.y) == 4 && EntriesZ5()[4].point == p;
              }
            }
          }
        }
      }
    }
  }

  lemma {:isolate_assertions} CheckZ6Point(i: nat)
    requires i < 41
    ensures PointZ6(i).z == 6
    ensures IsValidPointBool(PointZ6(i))
    ensures IsValidCoreAffect(PointZ6(i))
    ensures IndexInZ6(PointZ6(i).x, PointZ6(i).y) == i
  {
    if i < 20 {
      if i < 10 {
        if i < 5 {
          if i < 2 {
            if i < 1 {
              // idx 0: (0, 0, 6)
              assert PointZ6(0) == CoreAffectPoint(0, 0, 6);
            } else {
              // idx 1: (0, 10, 6)
              assert PointZ6(1) == CoreAffectPoint(0, 10, 6);
            }
          } else {
            if i < 3 {
              // idx 2: (0, -10, 6)
              assert PointZ6(2) == CoreAffectPoint(0, -10, 6);
            } else {
              if i < 4 {
                // idx 3: (-10, 0, 6)
                assert PointZ6(3) == CoreAffectPoint(-10, 0, 6);
              } else {
                // idx 4: (10, 0, 6)
                assert PointZ6(4) == CoreAffectPoint(10, 0, 6);
              }
            }
          }
        } else {
          if i < 7 {
            if i < 6 {
              // idx 5: (3, 7, 6)
              assert PointZ6(5) == CoreAffectPoint(3, 7, 6);
            } else {
              // idx 6: (-3, 7, 6)
              assert PointZ6(6) == CoreAffectPoint(-3, 7, 6);
            }
          } else {
            if i < 8 {
              // idx 7: (4, 6, 6)
              assert PointZ6(7) == CoreAffectPoint(4, 6, 6);
            } else {
              if i < 9 {
                // idx 8: (-4, 6, 6)
                assert PointZ6(8) == CoreAffectPoint(-4, 6, 6);
              } else {
                // idx 9: (2, 8, 6)
                assert PointZ6(9) == CoreAffectPoint(2, 8, 6);
              }
            }
          }
        }
      } else {
        if i < 15 {
          if i < 12 {
            if i < 11 {
              // idx 10: (-2, 8, 6)
              assert PointZ6(10) == CoreAffectPoint(-2, 8, 6);
            } else {
              // idx 11: (1, 9, 6)
              assert PointZ6(11) == CoreAffectPoint(1, 9, 6);
            }
          } else {
            if i < 13 {
              // idx 12: (-1, 9, 6)
              assert PointZ6(12) == CoreAffectPoint(-1, 9, 6);
            } else {
              if i < 14 {
                // idx 13: (3, -7, 6)
                assert PointZ6(13) == CoreAffectPoint(3, -7, 6);
              } else {
                // idx 14: (-3, -7, 6)
                assert PointZ6(14) == CoreAffectPoint(-3, -7, 6);
              }
            }
          }
        } else {
          if i < 17 {
            if i < 16 {
              // idx 15: (4, -6, 6)
              assert PointZ6(15) == CoreAffectPoint(4, -6, 6);
            } else {
              // idx 16: (-4, -6, 6)
              assert PointZ6(16) == CoreAffectPoint(-4, -6, 6);
            }
          } else {
            if i < 18 {
              // idx 17: (2, -8, 6)
              assert PointZ6(17) == CoreAffectPoint(2, -8, 6);
            } else {
              if i < 19 {
                // idx 18: (-2, -8, 6)
                assert PointZ6(18) == CoreAffectPoint(-2, -8, 6);
              } else {
                // idx 19: (1, -9, 6)
                assert PointZ6(19) == CoreAffectPoint(1, -9, 6);
              }
            }
          }
        }
      }
    } else {
      if i < 30 {
        if i < 25 {
          if i < 22 {
            if i < 21 {
              // idx 20: (-1, -9, 6)
              assert PointZ6(20) == CoreAffectPoint(-1, -9, 6);
            } else {
              // idx 21: (-6, 4, 6)
              assert PointZ6(21) == CoreAffectPoint(-6, 4, 6);
            }
          } else {
            if i < 23 {
              // idx 22: (-6, -4, 6)
              assert PointZ6(22) == CoreAffectPoint(-6, -4, 6);
            } else {
              if i < 24 {
                // idx 23: (-7, 3, 6)
                assert PointZ6(23) == CoreAffectPoint(-7, 3, 6);
              } else {
                // idx 24: (-7, -3, 6)
                assert PointZ6(24) == CoreAffectPoint(-7, -3, 6);
              }
            }
          }
        } else {
          if i < 27 {
            if i < 26 {
              // idx 25: (-8, 2, 6)
              assert PointZ6(25) == CoreAffectPoint(-8, 2, 6);
            } else {
              // idx 26: (-8, -2, 6)
              assert PointZ6(26) == CoreAffectPoint(-8, -2, 6);
            }
          } else {
            if i < 28 {
              // idx 27: (-9, 1, 6)
              assert PointZ6(27) == CoreAffectPoint(-9, 1, 6);
            } else {
              if i < 29 {
                // idx 28: (-9, -1, 6)
                assert PointZ6(28) == CoreAffectPoint(-9, -1, 6);
              } else {
                // idx 29: (6, 4, 6)
                assert PointZ6(29) == CoreAffectPoint(6, 4, 6);
              }
            }
          }
        }
      } else {
        if i < 35 {
          if i < 32 {
            if i < 31 {
              // idx 30: (6, -4, 6)
              assert PointZ6(30) == CoreAffectPoint(6, -4, 6);
            } else {
              // idx 31: (7, 3, 6)
              assert PointZ6(31) == CoreAffectPoint(7, 3, 6);
            }
          } else {
            if i < 33 {
              // idx 32: (7, -3, 6)
              assert PointZ6(32) == CoreAffectPoint(7, -3, 6);
            } else {
              if i < 34 {
                // idx 33: (8, 2, 6)
                assert PointZ6(33) == CoreAffectPoint(8, 2, 6);
              } else {
                // idx 34: (8, -2, 6)
                assert PointZ6(34) == CoreAffectPoint(8, -2, 6);
              }
            }
          }
        } else {
          if i < 38 {
            if i < 36 {
              // idx 35: (9, 1, 6)
              assert PointZ6(35) == CoreAffectPoint(9, 1, 6);
            } else {
              if i < 37 {
                // idx 36: (9, -1, 6)
                assert PointZ6(36) == CoreAffectPoint(9, -1, 6);
              } else {
                // idx 37: (-5, 5, 6)
                assert PointZ6(37) == CoreAffectPoint(-5, 5, 6);
              }
            }
          } else {
            if i < 39 {
              // idx 38: (5, -5, 6)
              assert PointZ6(38) == CoreAffectPoint(5, -5, 6);
            } else {
              if i < 40 {
                // idx 39: (5, 5, 6)
                assert PointZ6(39) == CoreAffectPoint(5, 5, 6);
              } else {
                // idx 40: (-5, -5, 6)
                assert PointZ6(40) == CoreAffectPoint(-5, -5, 6);
              }
            }
          }
        }
      }
    }
  }

  lemma {:isolate_assertions} StratumZ6Complete(p: CoreAffectPoint)
    requires p.z == 6 && IsValidCoreAffect(p)
    ensures 0 <= IndexInZ6(p.x, p.y) < 41 && EntriesZ6()[IndexInZ6(p.x, p.y)].point == p
  {
    if p.x == 0 && p.y == 0 {
      assert IndexInZ6(p.x, p.y) == 0 && EntriesZ6()[0].point == p;
    } else {
      assert AbsNat(p.x) + AbsNat(p.y) == 10;
      if p.x < 0 {
        if p.x < -5 {
          if p.x < -8 {
            if p.x < -9 {
              assert p.y == 0 && IndexInZ6(p.x, p.y) == 3 && EntriesZ6()[3].point == p;
            } else {
              if p.y >= 0 {
                assert p.y == 1 && IndexInZ6(p.x, p.y) == 27 && EntriesZ6()[27].point == p;
              } else {
                assert p.y == -1 && IndexInZ6(p.x, p.y) == 28 && EntriesZ6()[28].point == p;
              }
            }
          } else {
            if p.x < -7 {
              if p.y >= 0 {
                assert p.y == 2 && IndexInZ6(p.x, p.y) == 25 && EntriesZ6()[25].point == p;
              } else {
                assert p.y == -2 && IndexInZ6(p.x, p.y) == 26 && EntriesZ6()[26].point == p;
              }
            } else {
              if p.x < -6 {
                if p.y >= 0 {
                  assert p.y == 3 && IndexInZ6(p.x, p.y) == 23 && EntriesZ6()[23].point == p;
                } else {
                  assert p.y == -3 && IndexInZ6(p.x, p.y) == 24 && EntriesZ6()[24].point == p;
                }
              } else {
                if p.y >= 0 {
                  assert p.y == 4 && IndexInZ6(p.x, p.y) == 21 && EntriesZ6()[21].point == p;
                } else {
                  assert p.y == -4 && IndexInZ6(p.x, p.y) == 22 && EntriesZ6()[22].point == p;
                }
              }
            }
          }
        } else {
          if p.x < -3 {
            if p.x < -4 {
              if p.y >= 0 {
                assert p.y == 5 && IndexInZ6(p.x, p.y) == 37 && EntriesZ6()[37].point == p;
              } else {
                assert p.y == -5 && IndexInZ6(p.x, p.y) == 40 && EntriesZ6()[40].point == p;
              }
            } else {
              if p.y >= 0 {
                assert p.y == 6 && IndexInZ6(p.x, p.y) == 8 && EntriesZ6()[8].point == p;
              } else {
                assert p.y == -6 && IndexInZ6(p.x, p.y) == 16 && EntriesZ6()[16].point == p;
              }
            }
          } else {
            if p.x < -2 {
              if p.y >= 0 {
                assert p.y == 7 && IndexInZ6(p.x, p.y) == 6 && EntriesZ6()[6].point == p;
              } else {
                assert p.y == -7 && IndexInZ6(p.x, p.y) == 14 && EntriesZ6()[14].point == p;
              }
            } else {
              if p.x < -1 {
                if p.y >= 0 {
                  assert p.y == 8 && IndexInZ6(p.x, p.y) == 10 && EntriesZ6()[10].point == p;
                } else {
                  assert p.y == -8 && IndexInZ6(p.x, p.y) == 18 && EntriesZ6()[18].point == p;
                }
              } else {
                if p.y >= 0 {
                  assert p.y == 9 && IndexInZ6(p.x, p.y) == 12 && EntriesZ6()[12].point == p;
                } else {
                  assert p.y == -9 && IndexInZ6(p.x, p.y) == 20 && EntriesZ6()[20].point == p;
                }
              }
            }
          }
        }
      } else {
        if p.x < 5 {
          if p.x < 2 {
            if p.x < 1 {
              if p.y >= 0 {
                assert p.y == 10 && IndexInZ6(p.x, p.y) == 1 && EntriesZ6()[1].point == p;
              } else {
                assert p.y == -10 && IndexInZ6(p.x, p.y) == 2 && EntriesZ6()[2].point == p;
              }
            } else {
              if p.y >= 0 {
                assert p.y == 9 && IndexInZ6(p.x, p.y) == 11 && EntriesZ6()[11].point == p;
              } else {
                assert p.y == -9 && IndexInZ6(p.x, p.y) == 19 && EntriesZ6()[19].point == p;
              }
            }
          } else {
            if p.x < 3 {
              if p.y >= 0 {
                assert p.y == 8 && IndexInZ6(p.x, p.y) == 9 && EntriesZ6()[9].point == p;
              } else {
                assert p.y == -8 && IndexInZ6(p.x, p.y) == 17 && EntriesZ6()[17].point == p;
              }
            } else {
              if p.x < 4 {
                if p.y >= 0 {
                  assert p.y == 7 && IndexInZ6(p.x, p.y) == 5 && EntriesZ6()[5].point == p;
                } else {
                  assert p.y == -7 && IndexInZ6(p.x, p.y) == 13 && EntriesZ6()[13].point == p;
                }
              } else {
                if p.y >= 0 {
                  assert p.y == 6 && IndexInZ6(p.x, p.y) == 7 && EntriesZ6()[7].point == p;
                } else {
                  assert p.y == -6 && IndexInZ6(p.x, p.y) == 15 && EntriesZ6()[15].point == p;
                }
              }
            }
          }
        } else {
          if p.x < 8 {
            if p.x < 6 {
              if p.y >= 0 {
                assert p.y == 5 && IndexInZ6(p.x, p.y) == 39 && EntriesZ6()[39].point == p;
              } else {
                assert p.y == -5 && IndexInZ6(p.x, p.y) == 38 && EntriesZ6()[38].point == p;
              }
            } else {
              if p.x < 7 {
                if p.y >= 0 {
                  assert p.y == 4 && IndexInZ6(p.x, p.y) == 29 && EntriesZ6()[29].point == p;
                } else {
                  assert p.y == -4 && IndexInZ6(p.x, p.y) == 30 && EntriesZ6()[30].point == p;
                }
              } else {
                if p.y >= 0 {
                  assert p.y == 3 && IndexInZ6(p.x, p.y) == 31 && EntriesZ6()[31].point == p;
                } else {
                  assert p.y == -3 && IndexInZ6(p.x, p.y) == 32 && EntriesZ6()[32].point == p;
                }
              }
            }
          } else {
            if p.x < 9 {
              if p.y >= 0 {
                assert p.y == 2 && IndexInZ6(p.x, p.y) == 33 && EntriesZ6()[33].point == p;
              } else {
                assert p.y == -2 && IndexInZ6(p.x, p.y) == 34 && EntriesZ6()[34].point == p;
              }
            } else {
              if p.x < 10 {
                if p.y >= 0 {
                  assert p.y == 1 && IndexInZ6(p.x, p.y) == 35 && EntriesZ6()[35].point == p;
                } else {
                  assert p.y == -1 && IndexInZ6(p.x, p.y) == 36 && EntriesZ6()[36].point == p;
                }
              } else {
                assert p.y == 0 && IndexInZ6(p.x, p.y) == 4 && EntriesZ6()[4].point == p;
              }
            }
          }
        }
      }
    }
  }

  lemma {:isolate_assertions} CheckZ7Point(i: nat)
    requires i < 49
    ensures PointZ7(i).z == 7
    ensures IsValidPointBool(PointZ7(i))
    ensures IsValidCoreAffect(PointZ7(i))
    ensures IndexInZ7(PointZ7(i).x, PointZ7(i).y) == i
  {
    if i < 24 {
      if i < 12 {
        if i < 6 {
          if i < 3 {
            if i < 1 {
              // idx 0: (0, 0, 7)
              assert PointZ7(0) == CoreAffectPoint(0, 0, 7);
            } else {
              if i < 2 {
                // idx 1: (0, 12, 7)
                assert PointZ7(1) == CoreAffectPoint(0, 12, 7);
              } else {
                // idx 2: (0, -12, 7)
                assert PointZ7(2) == CoreAffectPoint(0, -12, 7);
              }
            }
          } else {
            if i < 4 {
              // idx 3: (-12, 0, 7)
              assert PointZ7(3) == CoreAffectPoint(-12, 0, 7);
            } else {
              if i < 5 {
                // idx 4: (12, 0, 7)
                assert PointZ7(4) == CoreAffectPoint(12, 0, 7);
              } else {
                // idx 5: (2, 10, 7)
                assert PointZ7(5) == CoreAffectPoint(2, 10, 7);
              }
            }
          }
        } else {
          if i < 9 {
            if i < 7 {
              // idx 6: (-2, 10, 7)
              assert PointZ7(6) == CoreAffectPoint(-2, 10, 7);
            } else {
              if i < 8 {
                // idx 7: (4, 8, 7)
                assert PointZ7(7) == CoreAffectPoint(4, 8, 7);
              } else {
                // idx 8: (-4, 8, 7)
                assert PointZ7(8) == CoreAffectPoint(-4, 8, 7);
              }
            }
          } else {
            if i < 10 {
              // idx 9: (1, 11, 7)
              assert PointZ7(9) == CoreAffectPoint(1, 11, 7);
            } else {
              if i < 11 {
                // idx 10: (-1, 11, 7)
                assert PointZ7(10) == CoreAffectPoint(-1, 11, 7);
              } else {
                // idx 11: (3, 9, 7)
                assert PointZ7(11) == CoreAffectPoint(3, 9, 7);
              }
            }
          }
        }
      } else {
        if i < 18 {
          if i < 15 {
            if i < 13 {
              // idx 12: (-3, 9, 7)
              assert PointZ7(12) == CoreAffectPoint(-3, 9, 7);
            } else {
              if i < 14 {
                // idx 13: (5, 7, 7)
                assert PointZ7(13) == CoreAffectPoint(5, 7, 7);
              } else {
                // idx 14: (-5, 7, 7)
                assert PointZ7(14) == CoreAffectPoint(-5, 7, 7);
              }
            }
          } else {
            if i < 16 {
              // idx 15: (2, -10, 7)
              assert PointZ7(15) == CoreAffectPoint(2, -10, 7);
            } else {
              if i < 17 {
                // idx 16: (-2, -10, 7)
                assert PointZ7(16) == CoreAffectPoint(-2, -10, 7);
              } else {
                // idx 17: (4, -8, 7)
                assert PointZ7(17) == CoreAffectPoint(4, -8, 7);
              }
            }
          }
        } else {
          if i < 21 {
            if i < 19 {
              // idx 18: (-4, -8, 7)
              assert PointZ7(18) == CoreAffectPoint(-4, -8, 7);
            } else {
              if i < 20 {
                // idx 19: (1, -11, 7)
                assert PointZ7(19) == CoreAffectPoint(1, -11, 7);
              } else {
                // idx 20: (-1, -11, 7)
                assert PointZ7(20) == CoreAffectPoint(-1, -11, 7);
              }
            }
          } else {
            if i < 22 {
              // idx 21: (3, -9, 7)
              assert PointZ7(21) == CoreAffectPoint(3, -9, 7);
            } else {
              if i < 23 {
                // idx 22: (-3, -9, 7)
                assert PointZ7(22) == CoreAffectPoint(-3, -9, 7);
              } else {
                // idx 23: (5, -7, 7)
                assert PointZ7(23) == CoreAffectPoint(5, -7, 7);
              }
            }
          }
        }
      }
    } else {
      if i < 36 {
        if i < 30 {
          if i < 27 {
            if i < 25 {
              // idx 24: (-5, -7, 7)
              assert PointZ7(24) == CoreAffectPoint(-5, -7, 7);
            } else {
              if i < 26 {
                // idx 25: (-10, 2, 7)
                assert PointZ7(25) == CoreAffectPoint(-10, 2, 7);
              } else {
                // idx 26: (-10, -2, 7)
                assert PointZ7(26) == CoreAffectPoint(-10, -2, 7);
              }
            }
          } else {
            if i < 28 {
              // idx 27: (-8, 4, 7)
              assert PointZ7(27) == CoreAffectPoint(-8, 4, 7);
            } else {
              if i < 29 {
                // idx 28: (-8, -4, 7)
                assert PointZ7(28) == CoreAffectPoint(-8, -4, 7);
              } else {
                // idx 29: (-11, 1, 7)
                assert PointZ7(29) == CoreAffectPoint(-11, 1, 7);
              }
            }
          }
        } else {
          if i < 33 {
            if i < 31 {
              // idx 30: (-11, -1, 7)
              assert PointZ7(30) == CoreAffectPoint(-11, -1, 7);
            } else {
              if i < 32 {
                // idx 31: (-9, 3, 7)
                assert PointZ7(31) == CoreAffectPoint(-9, 3, 7);
              } else {
                // idx 32: (-9, -3, 7)
                assert PointZ7(32) == CoreAffectPoint(-9, -3, 7);
              }
            }
          } else {
            if i < 34 {
              // idx 33: (-7, 5, 7)
              assert PointZ7(33) == CoreAffectPoint(-7, 5, 7);
            } else {
              if i < 35 {
                // idx 34: (-7, -5, 7)
                assert PointZ7(34) == CoreAffectPoint(-7, -5, 7);
              } else {
                // idx 35: (10, 2, 7)
                assert PointZ7(35) == CoreAffectPoint(10, 2, 7);
              }
            }
          }
        }
      } else {
        if i < 42 {
          if i < 39 {
            if i < 37 {
              // idx 36: (10, -2, 7)
              assert PointZ7(36) == CoreAffectPoint(10, -2, 7);
            } else {
              if i < 38 {
                // idx 37: (8, 4, 7)
                assert PointZ7(37) == CoreAffectPoint(8, 4, 7);
              } else {
                // idx 38: (8, -4, 7)
                assert PointZ7(38) == CoreAffectPoint(8, -4, 7);
              }
            }
          } else {
            if i < 40 {
              // idx 39: (11, 1, 7)
              assert PointZ7(39) == CoreAffectPoint(11, 1, 7);
            } else {
              if i < 41 {
                // idx 40: (11, -1, 7)
                assert PointZ7(40) == CoreAffectPoint(11, -1, 7);
              } else {
                // idx 41: (9, 3, 7)
                assert PointZ7(41) == CoreAffectPoint(9, 3, 7);
              }
            }
          }
        } else {
          if i < 45 {
            if i < 43 {
              // idx 42: (9, -3, 7)
              assert PointZ7(42) == CoreAffectPoint(9, -3, 7);
            } else {
              if i < 44 {
                // idx 43: (7, 5, 7)
                assert PointZ7(43) == CoreAffectPoint(7, 5, 7);
              } else {
                // idx 44: (7, -5, 7)
                assert PointZ7(44) == CoreAffectPoint(7, -5, 7);
              }
            }
          } else {
            if i < 47 {
              if i < 46 {
                // idx 45: (-6, 6, 7)
                assert PointZ7(45) == CoreAffectPoint(-6, 6, 7);
              } else {
                // idx 46: (6, -6, 7)
                assert PointZ7(46) == CoreAffectPoint(6, -6, 7);
              }
            } else {
              if i < 48 {
                // idx 47: (6, 6, 7)
                assert PointZ7(47) == CoreAffectPoint(6, 6, 7);
              } else {
                // idx 48: (-6, -6, 7)
                assert PointZ7(48) == CoreAffectPoint(-6, -6, 7);
              }
            }
          }
        }
      }
    }
  }

  lemma {:isolate_assertions} StratumZ7Complete(p: CoreAffectPoint)
    requires p.z == 7 && IsValidCoreAffect(p)
    ensures 0 <= IndexInZ7(p.x, p.y) < 49 && EntriesZ7()[IndexInZ7(p.x, p.y)].point == p
  {
    if p.x == 0 && p.y == 0 {
      assert IndexInZ7(p.x, p.y) == 0 && EntriesZ7()[0].point == p;
    } else {
      assert AbsNat(p.x) + AbsNat(p.y) == 12;
      if p.x < 0 {
        if p.x < -6 {
          if p.x < -9 {
            if p.x < -11 {
              assert p.y == 0 && IndexInZ7(p.x, p.y) == 3 && EntriesZ7()[3].point == p;
            } else {
              if p.x < -10 {
                if p.y >= 0 {
                  assert p.y == 1 && IndexInZ7(p.x, p.y) == 29 && EntriesZ7()[29].point == p;
                } else {
                  assert p.y == -1 && IndexInZ7(p.x, p.y) == 30 && EntriesZ7()[30].point == p;
                }
              } else {
                if p.y >= 0 {
                  assert p.y == 2 && IndexInZ7(p.x, p.y) == 25 && EntriesZ7()[25].point == p;
                } else {
                  assert p.y == -2 && IndexInZ7(p.x, p.y) == 26 && EntriesZ7()[26].point == p;
                }
              }
            }
          } else {
            if p.x < -8 {
              if p.y >= 0 {
                assert p.y == 3 && IndexInZ7(p.x, p.y) == 31 && EntriesZ7()[31].point == p;
              } else {
                assert p.y == -3 && IndexInZ7(p.x, p.y) == 32 && EntriesZ7()[32].point == p;
              }
            } else {
              if p.x < -7 {
                if p.y >= 0 {
                  assert p.y == 4 && IndexInZ7(p.x, p.y) == 27 && EntriesZ7()[27].point == p;
                } else {
                  assert p.y == -4 && IndexInZ7(p.x, p.y) == 28 && EntriesZ7()[28].point == p;
                }
              } else {
                if p.y >= 0 {
                  assert p.y == 5 && IndexInZ7(p.x, p.y) == 33 && EntriesZ7()[33].point == p;
                } else {
                  assert p.y == -5 && IndexInZ7(p.x, p.y) == 34 && EntriesZ7()[34].point == p;
                }
              }
            }
          }
        } else {
          if p.x < -3 {
            if p.x < -5 {
              if p.y >= 0 {
                assert p.y == 6 && IndexInZ7(p.x, p.y) == 45 && EntriesZ7()[45].point == p;
              } else {
                assert p.y == -6 && IndexInZ7(p.x, p.y) == 48 && EntriesZ7()[48].point == p;
              }
            } else {
              if p.x < -4 {
                if p.y >= 0 {
                  assert p.y == 7 && IndexInZ7(p.x, p.y) == 14 && EntriesZ7()[14].point == p;
                } else {
                  assert p.y == -7 && IndexInZ7(p.x, p.y) == 24 && EntriesZ7()[24].point == p;
                }
              } else {
                if p.y >= 0 {
                  assert p.y == 8 && IndexInZ7(p.x, p.y) == 8 && EntriesZ7()[8].point == p;
                } else {
                  assert p.y == -8 && IndexInZ7(p.x, p.y) == 18 && EntriesZ7()[18].point == p;
                }
              }
            }
          } else {
            if p.x < -2 {
              if p.y >= 0 {
                assert p.y == 9 && IndexInZ7(p.x, p.y) == 12 && EntriesZ7()[12].point == p;
              } else {
                assert p.y == -9 && IndexInZ7(p.x, p.y) == 22 && EntriesZ7()[22].point == p;
              }
            } else {
              if p.x < -1 {
                if p.y >= 0 {
                  assert p.y == 10 && IndexInZ7(p.x, p.y) == 6 && EntriesZ7()[6].point == p;
                } else {
                  assert p.y == -10 && IndexInZ7(p.x, p.y) == 16 && EntriesZ7()[16].point == p;
                }
              } else {
                if p.y >= 0 {
                  assert p.y == 11 && IndexInZ7(p.x, p.y) == 10 && EntriesZ7()[10].point == p;
                } else {
                  assert p.y == -11 && IndexInZ7(p.x, p.y) == 20 && EntriesZ7()[20].point == p;
                }
              }
            }
          }
        }
      } else {
        if p.x < 6 {
          if p.x < 3 {
            if p.x < 1 {
              if p.y >= 0 {
                assert p.y == 12 && IndexInZ7(p.x, p.y) == 1 && EntriesZ7()[1].point == p;
              } else {
                assert p.y == -12 && IndexInZ7(p.x, p.y) == 2 && EntriesZ7()[2].point == p;
              }
            } else {
              if p.x < 2 {
                if p.y >= 0 {
                  assert p.y == 11 && IndexInZ7(p.x, p.y) == 9 && EntriesZ7()[9].point == p;
                } else {
                  assert p.y == -11 && IndexInZ7(p.x, p.y) == 19 && EntriesZ7()[19].point == p;
                }
              } else {
                if p.y >= 0 {
                  assert p.y == 10 && IndexInZ7(p.x, p.y) == 5 && EntriesZ7()[5].point == p;
                } else {
                  assert p.y == -10 && IndexInZ7(p.x, p.y) == 15 && EntriesZ7()[15].point == p;
                }
              }
            }
          } else {
            if p.x < 4 {
              if p.y >= 0 {
                assert p.y == 9 && IndexInZ7(p.x, p.y) == 11 && EntriesZ7()[11].point == p;
              } else {
                assert p.y == -9 && IndexInZ7(p.x, p.y) == 21 && EntriesZ7()[21].point == p;
              }
            } else {
              if p.x < 5 {
                if p.y >= 0 {
                  assert p.y == 8 && IndexInZ7(p.x, p.y) == 7 && EntriesZ7()[7].point == p;
                } else {
                  assert p.y == -8 && IndexInZ7(p.x, p.y) == 17 && EntriesZ7()[17].point == p;
                }
              } else {
                if p.y >= 0 {
                  assert p.y == 7 && IndexInZ7(p.x, p.y) == 13 && EntriesZ7()[13].point == p;
                } else {
                  assert p.y == -7 && IndexInZ7(p.x, p.y) == 23 && EntriesZ7()[23].point == p;
                }
              }
            }
          }
        } else {
          if p.x < 9 {
            if p.x < 7 {
              if p.y >= 0 {
                assert p.y == 6 && IndexInZ7(p.x, p.y) == 47 && EntriesZ7()[47].point == p;
              } else {
                assert p.y == -6 && IndexInZ7(p.x, p.y) == 46 && EntriesZ7()[46].point == p;
              }
            } else {
              if p.x < 8 {
                if p.y >= 0 {
                  assert p.y == 5 && IndexInZ7(p.x, p.y) == 43 && EntriesZ7()[43].point == p;
                } else {
                  assert p.y == -5 && IndexInZ7(p.x, p.y) == 44 && EntriesZ7()[44].point == p;
                }
              } else {
                if p.y >= 0 {
                  assert p.y == 4 && IndexInZ7(p.x, p.y) == 37 && EntriesZ7()[37].point == p;
                } else {
                  assert p.y == -4 && IndexInZ7(p.x, p.y) == 38 && EntriesZ7()[38].point == p;
                }
              }
            }
          } else {
            if p.x < 11 {
              if p.x < 10 {
                if p.y >= 0 {
                  assert p.y == 3 && IndexInZ7(p.x, p.y) == 41 && EntriesZ7()[41].point == p;
                } else {
                  assert p.y == -3 && IndexInZ7(p.x, p.y) == 42 && EntriesZ7()[42].point == p;
                }
              } else {
                if p.y >= 0 {
                  assert p.y == 2 && IndexInZ7(p.x, p.y) == 35 && EntriesZ7()[35].point == p;
                } else {
                  assert p.y == -2 && IndexInZ7(p.x, p.y) == 36 && EntriesZ7()[36].point == p;
                }
              }
            } else {
              if p.x < 12 {
                if p.y >= 0 {
                  assert p.y == 1 && IndexInZ7(p.x, p.y) == 39 && EntriesZ7()[39].point == p;
                } else {
                  assert p.y == -1 && IndexInZ7(p.x, p.y) == 40 && EntriesZ7()[40].point == p;
                }
              } else {
                assert p.y == 0 && IndexInZ7(p.x, p.y) == 4 && EntriesZ7()[4].point == p;
              }
            }
          }
        }
      }
    }
  }

  // =========================================================================
  // Les 8 Théorèmes certifiés de Lexicon176
  // =========================================================================

  // [1/8] all176Entries_length
  lemma all176Entries_length()
    ensures |All176Entries()| == 176
  {}

  // [2/8] all176Entries_geometrically_valid
  lemma all176Entries_geometrically_valid()
    ensures forall i | 0 <= i < |All176Entries()| :: IsValidPointBool(All176Entries()[i].point)
    ensures forall i | 0 <= i < |All176Entries()| :: IsValidCoreAffect(All176Entries()[i].point)
  {
    forall i | 0 <= i < 176
      ensures IsValidPointBool(All176Entries()[i].point)
      ensures IsValidCoreAffect(All176Entries()[i].point)
    {
      if i < 1 { CheckZ0Point(i); }
      else if i < 2 { CheckZ1Point(i - 1); }
      else if i < 11 { CheckZ2Point(i - 2); }
      else if i < 28 { CheckZ3Point(i - 11); }
      else if i < 53 { CheckZ4Point(i - 28); }
      else if i < 86 { CheckZ5Point(i - 53); }
      else if i < 127 { CheckZ6Point(i - 86); }
      else { CheckZ7Point(i - 127); }
    }
  }

  // [3/8] all176Entries_z_bounds
  lemma all176Entries_z_bounds()
    ensures forall i | 0 <= i < |All176Entries()| :: 0 <= All176Entries()[i].point.z <= 7
  {
    forall i | 0 <= i < 176
      ensures 0 <= All176Entries()[i].point.z <= 7
    {
      if i < 1 { CheckZ0Point(i); }
      else if i < 2 { CheckZ1Point(i - 1); }
      else if i < 11 { CheckZ2Point(i - 2); }
      else if i < 28 { CheckZ3Point(i - 11); }
      else if i < 53 { CheckZ4Point(i - 28); }
      else if i < 86 { CheckZ5Point(i - 53); }
      else if i < 127 { CheckZ6Point(i - 86); }
      else { CheckZ7Point(i - 127); }
    }
  }

  lemma GlobalPointStratumAndIndex(i: nat)
    requires i < 176
    ensures (
      var p := GlobalPoint(i);
      0 <= p.z <= 7 &&
      i >= StratumOffset(p.z) &&
      (match p.z
        case 0 => i == 0
        case 1 => i == 1
        case 2 => i - 2 == IndexInZ2(p.x, p.y)
        case 3 => i - 11 == IndexInZ3(p.x, p.y)
        case 4 => i - 28 == IndexInZ4(p.x, p.y)
        case 5 => i - 53 == IndexInZ5(p.x, p.y)
        case 6 => i - 86 == IndexInZ6(p.x, p.y)
        case 7 => i - 127 == IndexInZ7(p.x, p.y)
      )
    )
  {
    if i < 1 { CheckZ0Point(i); }
    else if i < 2 { CheckZ1Point(i - 1); }
    else if i < 11 { CheckZ2Point(i - 2); }
    else if i < 28 { CheckZ3Point(i - 11); }
    else if i < 53 { CheckZ4Point(i - 28); }
    else if i < 86 { CheckZ5Point(i - 53); }
    else if i < 127 { CheckZ6Point(i - 86); }
    else { CheckZ7Point(i - 127); }
  }

  // [4/8] all176Entries_unique_points
  lemma all176Entries_unique_points()
    ensures forall i, j | 0 <= i < j < |All176Entries()| :: All176Entries()[i].point != All176Entries()[j].point
  {
    forall i, j | 0 <= i < j < 176
      ensures All176Entries()[i].point != All176Entries()[j].point
    {
      if All176Entries()[i].point == All176Entries()[j].point {
        GlobalPointStratumAndIndex(i);
        GlobalPointStratumAndIndex(j);
      }
    }
  }

  // [5/8] all176Entries_complete
  lemma all176Entries_complete(p: CoreAffectPoint)
    requires IsValidCoreAffect(p) && p.z <= 7
    ensures exists i | 0 <= i < |All176Entries()| :: All176Entries()[i].point == p
  {
    if p.z == 0 {
      StratumZ0Complete(p);
      assert All176Entries()[0].point == p;
    } else if p.z == 1 {
      StratumZ1Complete(p);
      assert All176Entries()[1].point == p;
    } else if p.z == 2 {
      StratumZ2Complete(p);
      var k := IndexInZ2(p.x, p.y);
      assert All176Entries()[2 + k].point == p;
    } else if p.z == 3 {
      StratumZ3Complete(p);
      var k := IndexInZ3(p.x, p.y);
      assert All176Entries()[11 + k].point == p;
    } else if p.z == 4 {
      StratumZ4Complete(p);
      var k := IndexInZ4(p.x, p.y);
      assert All176Entries()[28 + k].point == p;
    } else if p.z == 5 {
      StratumZ5Complete(p);
      var k := IndexInZ5(p.x, p.y);
      assert All176Entries()[53 + k].point == p;
    } else if p.z == 6 {
      StratumZ6Complete(p);
      var k := IndexInZ6(p.x, p.y);
      assert All176Entries()[86 + k].point == p;
    } else {
      StratumZ7Complete(p);
      var k := IndexInZ7(p.x, p.y);
      assert All176Entries()[127 + k].point == p;
    }
  }

  // [6/8] all176Entries_deterministically_reachable
  lemma all176Entries_deterministically_reachable(e: LexiconEntry)
    requires e in All176Entries()
    ensures exists s: PredictiveEngineState ::
      RunCartograffectPipeline(s).matrix.core == e.point
  {
    all176Entries_geometrically_valid();
    var s := WitnessEngineForPoint(e.point);
    projectToCoreAffect_surjective(e.point);
    assert RunCartograffectPipeline(s).matrix.core == e.point;
  }

  // [7/8] all176Entries_reachable_by_engine
  lemma all176Entries_reachable_by_engine(e: LexiconEntry)
    requires e in All176Entries()
    ensures exists s: PredictiveEngineState ::
      RunCartograffectPipeline(s).matrix.core == e.point
  {
    all176Entries_deterministically_reachable(e);
  }

  // [8/8] all176Entries_witness_check
  lemma all176Entries_witness_check()
    ensures forall i | 0 <= i < |All176Entries()| ::
      ProjectToCoreAffect(WitnessEngineForPoint(All176Entries()[i].point)) == All176Entries()[i].point
  {
    all176Entries_geometrically_valid();
    forall i | 0 <= i < |All176Entries()|
      ensures ProjectToCoreAffect(WitnessEngineForPoint(All176Entries()[i].point)) == All176Entries()[i].point
    {
      projectToCoreAffect_surjective(All176Entries()[i].point);
    }
  }
}
