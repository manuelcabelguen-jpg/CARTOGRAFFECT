/*
  Copyright (c) 2026 Manuel Cabelguen. All rights reserved.
  SPDX-License-Identifier: AGPL-3.0-or-later AND CC-BY-NC-SA-4.0
  Author: Manuel Cabelguen
*/

include "PredictiveEngine.dfy"
include "CoreAffect.dfy"
include "AffectiveMatrix.dfy"
include "AffectiveTaxonomy.dfy"
include "AffectiveDynamics.dfy"
include "Lexicon176.dfy"
include "PredictiveCircuit.dfy"
include "OperantFactorization.dfy"

module EndToEndBridge {
  import opened PredictiveEngine
  import opened CoreAffect
  import opened AffectiveMatrix
  import opened AffectiveTaxonomy
  import opened AffectiveDynamics
  import opened Lexicon176
  import opened PredictiveCircuit
  import opened OperantFactorization

  // =========================================================================
  // 1. Définitions canoniques des ponts opérants et pipelines terminaux
  // =========================================================================

  datatype OperantRole =
    | RoleCentralOperator
    | PreOperantAxial(sector: OrientationSector)
    | PureOperant(contingency: OperantContingency)
    | BlendedLateral(sector: OrientationSector, contingency: OperantContingency)

  function CouplingToContingency(c: EngineCoupling): OptionContingency {
    match (c.attente, c.controle)
    case (Pos, Pos) => SomeContingency(OperantContingency(Reinforcement, Addition))
    case (Pos, Neg) => SomeContingency(OperantContingency(Reinforcement, Removal))
    case (Neg, Neg) => SomeContingency(OperantContingency(Punishment,    Addition))
    case (Neg, Pos) => SomeContingency(OperantContingency(Punishment,    Removal))
    case _          => NoContingency
  }

  function QuadrantContingency(x: int, y: int): OptionContingency {
    if x > 0 && y > 0 then SomeContingency(OperantContingency(Reinforcement, Addition))
    else if x > 0 && y < 0 then SomeContingency(OperantContingency(Reinforcement, Removal))
    else if x < 0 && y < 0 then SomeContingency(OperantContingency(Punishment,    Addition))
    else if x < 0 && y > 0 then SomeContingency(OperantContingency(Punishment,    Removal))
    else NoContingency
  }

  function ClassifyOperantRole(p: CoreAffectPoint): OperantRole {
    match (QuadrantContingency(p.x, p.y), DominantSector(p))
    case (SomeContingency(c), SomeSector(sec)) => BlendedLateral(sec, c)
    case (SomeContingency(c), NoSector)        => PureOperant(c)
    case (NoContingency,      SomeSector(sec)) => PreOperantAxial(sec)
    case (NoContingency,      NoSector)        => RoleCentralOperator
  }

  function EvaluateUnifiedTaxonomy(
    p: UnifiedDynamicsParams, c: EngineCoupling,
    z: nat, rhoHat: nat, kappaHat: nat, susp: bool
  ): TaxonomicState {
    EvaluateTaxonomy(EvaluateMatrix(ProjectUnifiedState(p, c, z, rhoHat, kappaHat, susp), CanonicalMapping()))
  }

  function EvaluateCircularTaxonomy(s: CircularCircuitState): TaxonomicState {
    EvaluateTaxonomy(EvaluateMatrix(Op3CrossingIPerceptible(s).1, CanonicalMapping()))
  }

  // =========================================================================
  // 2. Unicité nominale (all176Entries_unique_labels) et lemmes auxiliaires
  // =========================================================================

  function LabelRank(s: string): nat {
    if |s| > 0 && (s[0] as int) < 73 then
      if |s| > 4 && (s[4] as int) < 110 then
        if |s| < 9 then
          if |s| > 0 && (s[0] as int) < 69 then
            if |s| > 0 && (s[0] as int) < 67 then
              if |s| > 1 && (s[1] as int) < 112 then
                if |s| < 7 then
                  147
                else
                  if |s| < 8 then
                    148
                  else
                    92
              else
                if |s| < 7 then
                  23
                else
                  if |s| < 8 then
                    26
                  else
                    124
            else
              if |s| < 7 then
                if |s| > 0 && (s[0] as int) < 68 then
                  8
                else
                  31
              else
                if |s| < 8 then
                  6
                else
                  if |s| > 2 && (s[2] as int) < 116 then
                    44
                  else
                    139
          else
            if |s| < 7 then
              if |s| > 1 && (s[1] as int) < 111 then
                if |s| > 0 && (s[0] as int) < 72 then
                  if |s| > 2 && (s[2] as int) < 118 then
                    13
                  else
                    33
                else
                  34
              else
                if |s| < 6 then
                  39
                else
                  if |s| > 2 && (s[2] as int) < 116 then
                    78
                  else
                    51
            else
              if |s| > 0 && (s[0] as int) < 72 then
                if |s| < 8 then
                  if |s| > 0 && (s[0] as int) < 70 then
                    115
                  else
                    36
                else
                  105
              else
                if |s| > 1 && (s[1] as int) < 111 then
                  152
                else
                  135
        else
          if |s| > 1 && (s[1] as int) < 111 then
            if |s| > 0 && (s[0] as int) < 68 then
              if |s| > 3 && (s[3] as int) < 108 then
                if |s| < 11 then
                  47
                else
                  if |s| < 12 then
                    100
                  else
                    2
              else
                if |s| > 1 && (s[1] as int) < 108 then
                  if |s| > 3 && (s[3] as int) < 111 then
                    154
                  else
                    109
                else
                  93
            else
              if |s| < 10 then
                if |s| > 0 && (s[0] as int) < 70 then
                  149
                else
                  68
              else
                if |s| < 12 then
                  if |s| > 1 && (s[1] as int) < 110 then
                    89
                  else
                    60
                else
                  79
          else
            if |s| > 0 && (s[0] as int) < 68 then
              if |s| < 12 then
                if |s| < 11 then
                  if |s| > 0 && (s[0] as int) < 67 then
                    99
                  else
                    57
                else
                  59
              else
                if |s| < 13 then
                  if |s| > 3 && (s[3] as int) < 116 then
                    171
                  else
                    165
                else
                  103
            else
              if |s| < 11 then
                if |s| < 10 then
                  111
                else
                  106
              else
                if |s| > 2 && (s[2] as int) < 114 then
                  133
                else
                  if |s| > 2 && (s[2] as int) < 116 then
                    130
                  else
                    74
      else
        if |s| > 1 && (s[1] as int) < 114 then
          if |s| < 10 then
            if |s| < 7 then
              if |s| > 0 && (s[0] as int) < 69 then
                if |s| < 6 then
                  35
                else
                  7
              else
                if |s| > 0 && (s[0] as int) < 70 then
                  21
                else
                  if |s| > 1 && (s[1] as int) < 111 then
                    45
                  else
                    95
            else
              if |s| > 1 && (s[1] as int) < 109 then
                if |s| < 8 then
                  19
                else
                  if |s| > 0 && (s[0] as int) < 72 then
                    170
                  else
                    122
              else
                if |s| < 8 then
                  41
                else
                  if |s| < 9 then
                    108
                  else
                    131
          else
            if |s| > 0 && (s[0] as int) < 67 then
              if |s| < 11 then
                if |s| > 1 && (s[1] as int) < 100 then
                  126
                else
                  if |s| > 1 && (s[1] as int) < 112 then
                    48
                  else
                    101
              else
                if |s| < 14 then
                  if |s| > 1 && (s[1] as int) < 102 then
                    50
                  else
                    90
                else
                  112
            else
              if |s| < 12 then
                if |s| < 11 then
                  140
                else
                  175
              else
                if |s| < 13 then
                  12
                else
                  if |s| < 15 then
                    16
                  else
                    159
        else
          if |s| > 3 && (s[3] as int) < 105 then
            if |s| < 9 then
              if |s| < 7 then
                if |s| > 0 && (s[0] as int) < 69 then
                  91
                else
                  if |s| > 0 && (s[0] as int) < 70 then
                    119
                  else
                    94
              else
                if |s| < 8 then
                  25
                else
                  if |s| > 0 && (s[0] as int) < 69 then
                    113
                  else
                    17
            else
              if |s| < 10 then
                if |s| > 2 && (s[2] as int) < 115 then
                  157
                else
                  69
              else
                if |s| < 13 then
                  134
                else
                  if |s| < 15 then
                    75
                  else
                    61
          else
            if |s| < 10 then
              if |s| < 8 then
                if |s| < 6 then
                  9
                else
                  if |s| < 7 then
                    10
                  else
                    14
              else
                if |s| < 9 then
                  96
                else
                  if |s| > 0 && (s[0] as int) < 67 then
                    32
                  else
                    15
            else
              if |s| < 11 then
                if |s| > 0 && (s[0] as int) < 69 then
                  85
                else
                  if |s| > 2 && (s[2] as int) < 117 then
                    29
                  else
                    121
              else
                if |s| < 12 then
                  49
                else
                  24
    else
      if |s| > 2 && (s[2] as int) < 112 then
        if |s| < 9 then
          if |s| < 7 then
            if |s| < 5 then
              if |s| > 0 && (s[0] as int) < 86 then
                if |s| > 0 && (s[0] as int) < 80 then
                  3
                else
                  if |s| > 0 && (s[0] as int) < 82 then
                    144
                  else
                    172
              else
                if |s| > 0 && (s[0] as int) < 201 then
                  40
                else
                  if |s| > 1 && (s[1] as int) < 109 then
                    87
                  else
                    11
            else
              if |s| < 6 then
                if |s| > 0 && (s[0] as int) < 82 then
                  129
                else
                  if |s| > 2 && (s[2] as int) < 106 then
                    53
                  else
                    52
              else
                if |s| > 0 && (s[0] as int) < 76 then
                  128
                else
                  if |s| > 0 && (s[0] as int) < 77 then
                    117
                  else
                    42
          else
            if |s| < 8 then
              if |s| > 0 && (s[0] as int) < 82 then
                if |s| > 0 && (s[0] as int) < 80 then
                  88
                else
                  20
              else
                if |s| > 0 && (s[0] as int) < 83 then
                  107
                else
                  if |s| > 0 && (s[0] as int) < 84 then
                    150
                  else
                    160
            else
              if |s| > 0 && (s[0] as int) < 81 then
                if |s| > 0 && (s[0] as int) < 77 then
                  if |s| > 1 && (s[1] as int) < 117 then
                    30
                  else
                    169
                else
                  56
              else
                if |s| > 0 && (s[0] as int) < 83 then
                  64
                else
                  if |s| > 0 && (s[0] as int) < 84 then
                    65
                  else
                    125
        else
          if |s| < 11 then
            if |s| > 0 && (s[0] as int) < 80 then
              if |s| < 10 then
                if |s| > 0 && (s[0] as int) < 76 then
                  if |s| > 1 && (s[1] as int) < 115 then
                    63
                  else
                    153
                else
                  118
              else
                if |s| > 0 && (s[0] as int) < 77 then
                  97
                else
                  155
            else
              if |s| > 0 && (s[0] as int) < 84 then
                if |s| < 10 then
                  if |s| > 1 && (s[1] as int) < 117 then
                    116
                  else
                    54
                else
                  158
              else
                if |s| > 0 && (s[0] as int) < 201 then
                  if |s| > 1 && (s[1] as int) < 114 then
                    80
                  else
                    4
                else
                  167
          else
            if |s| > 0 && (s[0] as int) < 84 then
              if |s| < 12 then
                if |s| > 0 && (s[0] as int) < 82 then
                  104
                else
                  if |s| > 0 && (s[0] as int) < 83 then
                    136
                  else
                    174
              else
                if |s| < 13 then
                  86
                else
                  if |s| < 15 then
                    163
                  else
                    0
            else
              if |s| < 14 then
                if |s| > 0 && (s[0] as int) < 86 then
                  132
                else
                  if |s| > 0 && (s[0] as int) < 201 then
                    73
                  else
                    162
              else
                if |s| > 1 && (s[1] as int) < 112 then
                  22
                else
                  46
      else
        if |s| > 3 && (s[3] as int) < 112 then
          if |s| < 10 then
            if |s| < 9 then
              if |s| < 8 then
                if |s| > 0 && (s[0] as int) < 82 then
                  168
                else
                  if |s| > 2 && (s[2] as int) < 118 then
                    28
                  else
                    141
              else
                if |s| > 0 && (s[0] as int) < 80 then
                  102
                else
                  66
            else
              if |s| > 1 && (s[1] as int) < 114 then
                if |s| > 0 && (s[0] as int) < 80 then
                  76
                else
                  if |s| > 1 && (s[1] as int) < 108 then
                    143
                  else
                    38
              else
                if |s| > 0 && (s[0] as int) < 80 then
                  77
                else
                  if |s| > 1 && (s[1] as int) < 233 then
                    156
                  else
                    146
          else
            if |s| > 1 && (s[1] as int) < 110 then
              if |s| > 1 && (s[1] as int) < 99 then
                if |s| < 12 then
                  if |s| > 2 && (s[2] as int) < 121 then
                    166
                  else
                    164
                else
                  83
              else
                if |s| < 13 then
                  if |s| > 0 && (s[0] as int) < 201 then
                    72
                  else
                    110
                else
                  173
            else
              if |s| > 0 && (s[0] as int) < 82 then
                if |s| < 14 then
                  62
                else
                  82
              else
                if |s| < 11 then
                  120
                else
                  if |s| > 0 && (s[0] as int) < 83 then
                    151
                  else
                    18
        else
          if |s| < 9 then
            if |s| > 0 && (s[0] as int) < 82 then
              if |s| < 7 then
                if |s| < 6 then
                  5
                else
                  43
              else
                if |s| > 0 && (s[0] as int) < 74 then
                  84
                else
                  if |s| > 0 && (s[0] as int) < 78 then
                    81
                  else
                    142
            else
              if |s| < 8 then
                if |s| > 0 && (s[0] as int) < 84 then
                  27
                else
                  if |s| > 0 && (s[0] as int) < 86 then
                    98
                  else
                    137
              else
                if |s| > 0 && (s[0] as int) < 84 then
                  if |s| > 1 && (s[1] as int) < 233 then
                    1
                  else
                    37
                else
                  123
          else
            if |s| > 0 && (s[0] as int) < 79 then
              if |s| < 11 then
                if |s| < 10 then
                  114
                else
                  if |s| > 2 && (s[2] as int) < 115 then
                    71
                  else
                    70
              else
                if |s| < 15 then
                  55
                else
                  58
            else
              if |s| > 0 && (s[0] as int) < 83 then
                if |s| < 13 then
                  if |s| > 0 && (s[0] as int) < 80 then
                    145
                  else
                    67
                else
                  161
              else
                if |s| < 10 then
                  138
                else
                  127
  }

  lemma {:isolate_assertions} CheckLabelRankZ0(i: nat)
    requires i < 1
    ensures LabelRank(LabelsZ0()[i]) == 0 + i
  {
    reveal LabelsZ0();
    assert LabelsZ0()[0] == "Point de Veille";
    assert LabelRank("Point de Veille") == 0;
  }
  lemma {:isolate_assertions} CheckLabelRankZ1(i: nat)
    requires i < 1
    ensures LabelRank(LabelsZ1()[i]) == 1 + i
  {
    reveal LabelsZ1();
    assert LabelsZ1()[0] == "Surprise";
    assert LabelRank("Surprise") == 1;
  }
  lemma {:isolate_assertions} CheckLabelRankZ2(i: nat)
    requires i < 9
    ensures LabelRank(LabelsZ2()[i]) == 2 + i
  {
    reveal LabelsZ2();
    if i < 4 {
      if i < 2 {
        if i < 1 {
          assert LabelsZ2()[0] == "Anticipation";
          assert LabelRank("Anticipation") == 2;
        } else {
          assert LabelsZ2()[1] == "Joie";
          assert LabelRank("Joie") == 3;
        }
      } else {
        if i < 3 {
          assert LabelsZ2()[2] == "Tristesse";
          assert LabelRank("Tristesse") == 4;
        } else {
          assert LabelsZ2()[3] == "Peur";
          assert LabelRank("Peur") == 5;
        }
      }
    } else {
      if i < 6 {
        if i < 5 {
          assert LabelsZ2()[4] == "Courage";
          assert LabelRank("Courage") == 6;
        } else {
          assert LabelsZ2()[5] == "Colère";
          assert LabelRank("Colère") == 7;
        }
      } else {
        if i < 7 {
          assert LabelsZ2()[6] == "Calme";
          assert LabelRank("Calme") == 8;
        } else {
          if i < 8 {
            assert LabelsZ2()[7] == "Désir";
            assert LabelRank("Désir") == 9;
          } else {
            assert LabelsZ2()[8] == "Dégoût";
            assert LabelRank("Dégoût") == 10;
          }
        }
      }
    }
  }
  lemma {:isolate_assertions} CheckLabelRankZ3(i: nat)
    requires i < 17
    ensures LabelRank(LabelsZ3()[i]) == 11 + i
  {
    reveal LabelsZ3();
    if i < 8 {
      if i < 4 {
        if i < 2 {
          if i < 1 {
            assert LabelsZ3()[0] == "Émoi";
            assert LabelRank("Émoi") == 11;
          } else {
            assert LabelsZ3()[1] == "Enthousiasme";
            assert LabelRank("Enthousiasme") == 12;
          }
        } else {
          if i < 3 {
            assert LabelsZ3()[2] == "Ennui";
            assert LabelRank("Ennui") == 13;
          } else {
            assert LabelsZ3()[3] == "Crainte";
            assert LabelRank("Crainte") == 14;
          }
        }
      } else {
        if i < 6 {
          if i < 5 {
            assert LabelsZ3()[4] == "Curiosité";
            assert LabelRank("Curiosité") == 15;
          } else {
            assert LabelsZ3()[5] == "Consternation";
            assert LabelRank("Consternation") == 16;
          }
        } else {
          if i < 7 {
            assert LabelsZ3()[6] == "Euphorie";
            assert LabelRank("Euphorie") == 17;
          } else {
            assert LabelsZ3()[7] == "Soulagement";
            assert LabelRank("Soulagement") == 18;
          }
        }
      }
    } else {
      if i < 12 {
        if i < 10 {
          if i < 9 {
            assert LabelsZ3()[8] == "Chagrin";
            assert LabelRank("Chagrin") == 19;
          } else {
            assert LabelsZ3()[9] == "Panique";
            assert LabelRank("Panique") == 20;
          }
        } else {
          if i < 11 {
            assert LabelsZ3()[10] == "Effroi";
            assert LabelRank("Effroi") == 21;
          } else {
            assert LabelsZ3()[11] == "Émerveillement";
            assert LabelRank("Émerveillement") == 22;
          }
        }
      } else {
        if i < 14 {
          if i < 13 {
            assert LabelsZ3()[12] == "Aplomb";
            assert LabelRank("Aplomb") == 23;
          } else {
            assert LabelsZ3()[13] == "Exaspération";
            assert LabelRank("Exaspération") == 24;
          }
        } else {
          if i < 15 {
            assert LabelsZ3()[14] == "Détente";
            assert LabelRank("Détente") == 25;
          } else {
            if i < 16 {
              assert LabelsZ3()[15] == "Attrait";
              assert LabelRank("Attrait") == 26;
            } else {
              assert LabelsZ3()[16] == "Retrait";
              assert LabelRank("Retrait") == 27;
            }
          }
        }
      }
    }
  }
  lemma {:isolate_assertions} CheckLabelRankZ4(i: nat)
    requires i < 25
    ensures LabelRank(LabelsZ4()[i]) == 28 + i
  {
    reveal LabelsZ4();
    if i < 12 {
      if i < 6 {
        if i < 3 {
          if i < 1 {
            assert LabelsZ4()[0] == "Réserve";
            assert LabelRank("Réserve") == 28;
          } else {
            if i < 2 {
              assert LabelsZ4()[1] == "Exaltation";
              assert LabelRank("Exaltation") == 29;
            } else {
              assert LabelsZ4()[2] == "Langueur";
              assert LabelRank("Langueur") == 30;
            }
          }
        } else {
          if i < 4 {
            assert LabelsZ4()[3] == "Doute";
            assert LabelRank("Doute") == 31;
          } else {
            if i < 5 {
              assert LabelsZ4()[4] == "Assurance";
              assert LabelRank("Assurance") == 32;
            } else {
              assert LabelsZ4()[5] == "Envie";
              assert LabelRank("Envie") == 33;
            }
          }
        }
      } else {
        if i < 9 {
          if i < 7 {
            assert LabelsZ4()[6] == "Haine";
            assert LabelRank("Haine") == 34;
          } else {
            if i < 8 {
              assert LabelsZ4()[7] == "Amour";
              assert LabelRank("Amour") == 35;
            } else {
              assert LabelsZ4()[8] == "Ferveur";
              assert LabelRank("Ferveur") == 36;
            }
          }
        } else {
          if i < 10 {
            assert LabelsZ4()[9] == "Sérénité";
            assert LabelRank("Sérénité") == 37;
          } else {
            if i < 11 {
              assert LabelsZ4()[10] == "Plénitude";
              assert LabelRank("Plénitude") == 38;
            } else {
              assert LabelsZ4()[11] == "Honte";
              assert LabelRank("Honte") == 39;
            }
          }
        }
      }
    } else {
      if i < 18 {
        if i < 15 {
          if i < 13 {
            assert LabelsZ4()[12] == "Vide";
            assert LabelRank("Vide") == 40;
          } else {
            if i < 14 {
              assert LabelsZ4()[13] == "Anxiété";
              assert LabelRank("Anxiété") == 41;
            } else {
              assert LabelsZ4()[14] == "Manque";
              assert LabelRank("Manque") == 42;
            }
          }
        } else {
          if i < 16 {
            assert LabelsZ4()[15] == "Mépris";
            assert LabelRank("Mépris") == 43;
          } else {
            if i < 17 {
              assert LabelsZ4()[16] == "Défiance";
              assert LabelRank("Défiance") == 44;
            } else {
              assert LabelsZ4()[17] == "Fierté";
              assert LabelRank("Fierté") == 45;
            }
          }
        }
      } else {
        if i < 21 {
          if i < 19 {
            assert LabelsZ4()[18] == "Épanouissement";
            assert LabelRank("Épanouissement") == 46;
          } else {
            if i < 20 {
              assert LabelsZ4()[19] == "Affection";
              assert LabelRank("Affection") == 47;
            } else {
              assert LabelsZ4()[20] == "Admiration";
              assert LabelRank("Admiration") == 48;
            }
          }
        } else {
          if i < 23 {
            if i < 22 {
              assert LabelsZ4()[21] == "Frustration";
              assert LabelRank("Frustration") == 49;
            } else {
              assert LabelsZ4()[22] == "Acceptation";
              assert LabelRank("Acceptation") == 50;
            }
          } else {
            if i < 24 {
              assert LabelsZ4()[23] == "Estime";
              assert LabelRank("Estime") == 51;
            } else {
              assert LabelsZ4()[24] == "Rejet";
              assert LabelRank("Rejet") == 52;
            }
          }
        }
      }
    }
  }
  lemma {:isolate_assertions} CheckLabelRankZ5(i: nat)
    requires i < 33
    ensures LabelRank(LabelsZ5()[i]) == 53 + i
  {
    reveal LabelsZ5();
    if i < 16 {
      if i < 8 {
        if i < 4 {
          if i < 2 {
            if i < 1 {
              assert LabelsZ5()[0] == "Recul";
              assert LabelRank("Recul") == 53;
            } else {
              assert LabelsZ5()[1] == "Puissance";
              assert LabelRank("Puissance") == 54;
            }
          } else {
            if i < 3 {
              assert LabelsZ5()[2] == "Impuissance";
              assert LabelRank("Impuissance") == 55;
            } else {
              assert LabelsZ5()[3] == "Méfiance";
              assert LabelRank("Méfiance") == 56;
            }
          }
        } else {
          if i < 6 {
            if i < 5 {
              assert LabelsZ5()[4] == "Confiance";
              assert LabelRank("Confiance") == 57;
            } else {
              assert LabelsZ5()[5] == "Invulnérabilité";
              assert LabelRank("Invulnérabilité") == 58;
            }
          } else {
            if i < 7 {
              assert LabelsZ5()[6] == "Attachement";
              assert LabelRank("Attachement") == 59;
            } else {
              assert LabelsZ5()[7] == "Engagement";
              assert LabelRank("Engagement") == 60;
            }
          }
        }
      } else {
        if i < 12 {
          if i < 10 {
            if i < 9 {
              assert LabelsZ5()[8] == "Désenchantement";
              assert LabelRank("Désenchantement") == 61;
            } else {
              assert LabelsZ5()[9] == "Intolérance";
              assert LabelRank("Intolérance") == 62;
            }
          } else {
            if i < 11 {
              assert LabelsZ5()[10] == "Injustice";
              assert LabelRank("Injustice") == 63;
            } else {
              assert LabelsZ5()[11] == "Quiétude";
              assert LabelRank("Quiétude") == 64;
            }
          }
        } else {
          if i < 14 {
            if i < 13 {
              assert LabelsZ5()[12] == "Sécurité";
              assert LabelRank("Sécurité") == 65;
            } else {
              assert LabelsZ5()[13] == "Patience";
              assert LabelRank("Patience") == 66;
            }
          } else {
            if i < 15 {
              assert LabelsZ5()[14] == "Pessimisme";
              assert LabelRank("Pessimisme") == 67;
            } else {
              assert LabelsZ5()[15] == "Fermeture";
              assert LabelRank("Fermeture") == 68;
            }
          }
        }
      }
    } else {
      if i < 24 {
        if i < 20 {
          if i < 18 {
            if i < 17 {
              assert LabelsZ5()[16] == "Désespoir";
              assert LabelRank("Désespoir") == 69;
            } else {
              assert LabelsZ5()[17] == "Insécurité";
              assert LabelRank("Insécurité") == 70;
            }
          } else {
            if i < 19 {
              assert LabelsZ5()[18] == "Inquiétude";
              assert LabelRank("Inquiétude") == 71;
            } else {
              assert LabelsZ5()[19] == "Impatience";
              assert LabelRank("Impatience") == 72;
            }
          }
        } else {
          if i < 22 {
            if i < 21 {
              assert LabelsZ5()[20] == "Vulnérabilité";
              assert LabelRank("Vulnérabilité") == 73;
            } else {
              assert LabelsZ5()[21] == "Détachement";
              assert LabelRank("Détachement") == 74;
            }
          } else {
            if i < 23 {
              assert LabelsZ5()[22] == "Désengagement";
              assert LabelRank("Désengagement") == 75;
            } else {
              assert LabelsZ5()[23] == "Optimisme";
              assert LabelRank("Optimisme") == 76;
            }
          }
        }
      } else {
        if i < 28 {
          if i < 26 {
            if i < 25 {
              assert LabelsZ5()[24] == "Ouverture";
              assert LabelRank("Ouverture") == 77;
            } else {
              assert LabelsZ5()[25] == "Espoir";
              assert LabelRank("Espoir") == 78;
            }
          } else {
            if i < 27 {
              assert LabelsZ5()[26] == "Enchantement";
              assert LabelRank("Enchantement") == 79;
            } else {
              assert LabelsZ5()[27] == "Tolérance";
              assert LabelRank("Tolérance") == 80;
            }
          }
        } else {
          if i < 30 {
            if i < 29 {
              assert LabelsZ5()[28] == "Justice";
              assert LabelRank("Justice") == 81;
            } else {
              assert LabelsZ5()[29] == "Insatisfaction";
              assert LabelRank("Insatisfaction") == 82;
            }
          } else {
            if i < 31 {
              assert LabelsZ5()[30] == "Satisfaction";
              assert LabelRank("Satisfaction") == 83;
            } else {
              if i < 32 {
                assert LabelsZ5()[31] == "Intérêt";
                assert LabelRank("Intérêt") == 84;
              } else {
                assert LabelsZ5()[32] == "Désintérêt";
                assert LabelRank("Désintérêt") == 85;
              }
            }
          }
        }
      }
    }
  }
  lemma {:isolate_assertions} CheckLabelRankZ6(i: nat)
    requires i < 41
    ensures LabelRank(LabelsZ6()[i]) == 86 + i
  {
    reveal LabelsZ6();
    if i < 20 {
      if i < 10 {
        if i < 5 {
          if i < 2 {
            if i < 1 {
              assert LabelsZ6()[0] == "Saisissement";
              assert LabelRank("Saisissement") == 86;
            } else {
              assert LabelsZ6()[1] == "Élan";
              assert LabelRank("Élan") == 87;
            }
          } else {
            if i < 3 {
              assert LabelsZ6()[2] == "Inertie";
              assert LabelRank("Inertie") == 88;
            } else {
              if i < 4 {
                assert LabelsZ6()[3] == "Effacement";
                assert LabelRank("Effacement") == 89;
              } else {
                assert LabelsZ6()[4] == "Affirmation";
                assert LabelRank("Affirmation") == 90;
              }
            }
          }
        } else {
          if i < 7 {
            if i < 6 {
              assert LabelsZ6()[5] == "Ardeur";
              assert LabelRank("Ardeur") == 91;
            } else {
              assert LabelsZ6()[6] == "Angoisse";
              assert LabelRank("Angoisse") == 92;
            }
          } else {
            if i < 8 {
              assert LabelsZ6()[7] == "Allégresse";
              assert LabelRank("Allégresse") == 93;
            } else {
              if i < 9 {
                assert LabelsZ6()[8] == "Fureur";
                assert LabelRank("Fureur") == 94;
              } else {
                assert LabelsZ6()[9] == "Fougue";
                assert LabelRank("Fougue") == 95;
              }
            }
          }
        }
      } else {
        if i < 15 {
          if i < 12 {
            if i < 11 {
              assert LabelsZ6()[10] == "Frénésie";
              assert LabelRank("Frénésie") == 96;
            } else {
              assert LabelsZ6()[11] == "Jubilation";
              assert LabelRank("Jubilation") == 97;
            }
          } else {
            if i < 13 {
              assert LabelsZ6()[12] == "Terreur";
              assert LabelRank("Terreur") == 98;
            } else {
              if i < 14 {
                assert LabelsZ6()[13] == "Béatitude";
                assert LabelRank("Béatitude") == 99;
              } else {
                assert LabelsZ6()[14] == "Accablement";
                assert LabelRank("Accablement") == 100;
              }
            }
          }
        } else {
          if i < 17 {
            if i < 16 {
              assert LabelsZ6()[15] == "Apaisement";
              assert LabelRank("Apaisement") == 101;
            } else {
              assert LabelsZ6()[16] == "Morosité";
              assert LabelRank("Morosité") == 102;
            }
          } else {
            if i < 18 {
              assert LabelsZ6()[17] == "Contemplation";
              assert LabelRank("Contemplation") == 103;
            } else {
              if i < 19 {
                assert LabelsZ6()[18] == "Prostration";
                assert LabelRank("Prostration") == 104;
              } else {
                assert LabelsZ6()[19] == "Félicité";
                assert LabelRank("Félicité") == 105;
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
              assert LabelsZ6()[20] == "Désolation";
              assert LabelRank("Désolation") == 106;
            } else {
              assert LabelsZ6()[21] == "Rancœur";
              assert LabelRank("Rancœur") == 107;
            }
          } else {
            if i < 23 {
              assert LabelsZ6()[22] == "Amertume";
              assert LabelRank("Amertume") == 108;
            } else {
              if i < 24 {
                assert LabelsZ6()[23] == "Affolement";
                assert LabelRank("Affolement") == 109;
              } else {
                assert LabelsZ6()[24] == "Écrasement";
                assert LabelRank("Écrasement") == 110;
              }
            }
          }
        } else {
          if i < 27 {
            if i < 26 {
              assert LabelsZ6()[25] == "Fébrilité";
              assert LabelRank("Fébrilité") == 111;
            } else {
              assert LabelsZ6()[26] == "Anéantissement";
              assert LabelRank("Anéantissement") == 112;
            }
          } else {
            if i < 28 {
              assert LabelsZ6()[27] == "Désarroi";
              assert LabelRank("Désarroi") == 113;
            } else {
              if i < 29 {
                assert LabelsZ6()[28] == "Lassitude";
                assert LabelRank("Lassitude") == 114;
              } else {
                assert LabelsZ6()[29] == "Entrain";
                assert LabelRank("Entrain") == 115;
              }
            }
          }
        }
      } else {
        if i < 35 {
          if i < 32 {
            if i < 31 {
              assert LabelsZ6()[30] == "Placidité";
              assert LabelRank("Placidité") == 116;
            } else {
              assert LabelsZ6()[31] == "Liesse";
              assert LabelRank("Liesse") == 117;
            }
          } else {
            if i < 33 {
              assert LabelsZ6()[32] == "Limpidité";
              assert LabelRank("Limpidité") == 118;
            } else {
              if i < 34 {
                assert LabelsZ6()[33] == "Extase";
                assert LabelRank("Extase") == 119;
              } else {
                assert LabelsZ6()[34] == "Équanimité";
                assert LabelRank("Équanimité") == 120;
              }
            }
          }
        } else {
          if i < 38 {
            if i < 36 {
              assert LabelsZ6()[35] == "Exultation";
              assert LabelRank("Exultation") == 121;
            } else {
              if i < 37 {
                assert LabelsZ6()[36] == "Harmonie";
                assert LabelRank("Harmonie") == 122;
              } else {
                assert LabelsZ6()[37] == "Tourment";
                assert LabelRank("Tourment") == 123;
              }
            }
          } else {
            if i < 39 {
              assert LabelsZ6()[38] == "Ataraxie";
              assert LabelRank("Ataraxie") == 124;
            } else {
              if i < 40 {
                assert LabelsZ6()[39] == "Triomphe";
                assert LabelRank("Triomphe") == 125;
              } else {
                assert LabelsZ6()[40] == "Abattement";
                assert LabelRank("Abattement") == 126;
              }
            }
          }
        }
      }
    }
  }
  lemma {:isolate_assertions} CheckLabelRankZ7(i: nat)
    requires i < 49
    ensures LabelRank(LabelsZ7()[i]) == 127 + i
  {
    reveal LabelsZ7();
    if i < 24 {
      if i < 12 {
        if i < 6 {
          if i < 3 {
            if i < 1 {
              assert LabelsZ7()[0] == "Suspension";
              assert LabelRank("Suspension") == 127;
            } else {
              if i < 2 {
                assert LabelsZ7()[1] == "Infini";
                assert LabelRank("Infini") == 128;
              } else {
                assert LabelsZ7()[2] == "Néant";
                assert LabelRank("Néant") == 129;
              }
            }
          } else {
            if i < 4 {
              assert LabelsZ7()[3] == "Déréliction";
              assert LabelRank("Déréliction") == 130;
            } else {
              if i < 5 {
                assert LabelsZ7()[4] == "Communion";
                assert LabelRank("Communion") == 131;
              } else {
                assert LabelsZ7()[5] == "Transcendance";
                assert LabelRank("Transcendance") == 132;
              }
            }
          }
        } else {
          if i < 9 {
            if i < 7 {
              assert LabelsZ7()[6] == "Déchirement";
              assert LabelRank("Déchirement") == 133;
            } else {
              if i < 8 {
                assert LabelsZ7()[7] == "Exubérance";
                assert LabelRank("Exubérance") == 134;
              } else {
                assert LabelsZ7()[8] == "Horreur";
                assert LabelRank("Horreur") == 135;
              }
            }
          } else {
            if i < 10 {
              assert LabelsZ7()[9] == "Renaissance";
              assert LabelRank("Renaissance") == 136;
            } else {
              if i < 11 {
                assert LabelsZ7()[10] == "Vertige";
                assert LabelRank("Vertige") == 137;
              } else {
                assert LabelsZ7()[11] == "Élévation";
                assert LabelRank("Élévation") == 138;
              }
            }
          }
        }
      } else {
        if i < 18 {
          if i < 15 {
            if i < 13 {
              assert LabelsZ7()[12] == "Détresse";
              assert LabelRank("Détresse") == 139;
            } else {
              if i < 14 {
                assert LabelsZ7()[13] == "Enivrement";
                assert LabelRank("Enivrement") == 140;
              } else {
                assert LabelsZ7()[14] == "Révolte";
                assert LabelRank("Révolte") == 141;
              }
            }
          } else {
            if i < 16 {
              assert LabelsZ7()[15] == "Nirvana";
              assert LabelRank("Nirvana") == 142;
            } else {
              if i < 17 {
                assert LabelsZ7()[16] == "Perdition";
                assert LabelRank("Perdition") == 143;
              } else {
                assert LabelsZ7()[17] == "Paix";
                assert LabelRank("Paix") == 144;
              }
            }
          }
        } else {
          if i < 21 {
            if i < 19 {
              assert LabelsZ7()[18] == "Oppression";
              assert LabelRank("Oppression") == 145;
            } else {
              if i < 20 {
                assert LabelsZ7()[19] == "Pérennité";
                assert LabelRank("Pérennité") == 146;
              } else {
                assert LabelsZ7()[20] == "Abîme";
                assert LabelRank("Abîme") == 147;
              }
            }
          } else {
            if i < 22 {
              assert LabelsZ7()[21] == "Abandon";
              assert LabelRank("Abandon") == 148;
            } else {
              if i < 23 {
                assert LabelsZ7()[22] == "Damnation";
                assert LabelRank("Damnation") == 149;
              } else {
                assert LabelsZ7()[23] == "Silence";
                assert LabelRank("Silence") == 150;
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
              assert LabelsZ7()[24] == "Résignation";
              assert LabelRank("Résignation") == 151;
            } else {
              if i < 26 {
                assert LabelsZ7()[25] == "Hantise";
                assert LabelRank("Hantise") == 152;
              } else {
                assert LabelsZ7()[26] == "Isolement";
                assert LabelRank("Isolement") == 153;
              }
            }
          } else {
            if i < 28 {
              assert LabelsZ7()[27] == "Affliction";
              assert LabelRank("Affliction") == 154;
            } else {
              if i < 29 {
                assert LabelsZ7()[28] == "Mélancolie";
                assert LabelRank("Mélancolie") == 155;
              } else {
                assert LabelsZ7()[29] == "Précarité";
                assert LabelRank("Précarité") == 156;
              }
            }
          }
        } else {
          if i < 33 {
            if i < 31 {
              assert LabelsZ7()[30] == "Déchéance";
              assert LabelRank("Déchéance") == 157;
            } else {
              if i < 32 {
                assert LabelsZ7()[31] == "Sidération";
                assert LabelRank("Sidération") == 158;
              } else {
                assert LabelsZ7()[32] == "Engloutissement";
                assert LabelRank("Engloutissement") == 159;
              }
            }
          } else {
            if i < 34 {
              assert LabelsZ7()[33] == "Tumulte";
              assert LabelRank("Tumulte") == 160;
            } else {
              if i < 35 {
                assert LabelsZ7()[34] == "Pétrification";
                assert LabelRank("Pétrification") == 161;
              } else {
                assert LabelsZ7()[35] == "Éblouissement";
                assert LabelRank("Éblouissement") == 162;
              }
            }
          }
        }
      } else {
        if i < 42 {
          if i < 39 {
            if i < 37 {
              assert LabelsZ7()[36] == "Recueillement";
              assert LabelRank("Recueillement") == 163;
            } else {
              if i < 38 {
                assert LabelsZ7()[37] == "Rayonnement";
                assert LabelRank("Rayonnement") == 164;
              } else {
                assert LabelsZ7()[38] == "Contentement";
                assert LabelRank("Contentement") == 165;
              }
            }
          } else {
            if i < 40 {
              assert LabelsZ7()[39] == "Ravissement";
              assert LabelRank("Ravissement") == 166;
            } else {
              if i < 41 {
                assert LabelsZ7()[40] == "Épiphanie";
                assert LabelRank("Épiphanie") == 167;
              } else {
                assert LabelsZ7()[41] == "Louange";
                assert LabelRank("Louange") == 168;
              }
            }
          }
        } else {
          if i < 45 {
            if i < 43 {
              assert LabelsZ7()[42] == "Lucidité";
              assert LabelRank("Lucidité") == 169;
            } else {
              if i < 44 {
                assert LabelsZ7()[43] == "Effusion";
                assert LabelRank("Effusion") == 170;
              } else {
                assert LabelsZ7()[44] == "Consentement";
                assert LabelRank("Consentement") == 171;
              }
            }
          } else {
            if i < 47 {
              if i < 46 {
                assert LabelsZ7()[45] == "Rage";
                assert LabelRank("Rage") == 172;
              } else {
                assert LabelsZ7()[46] == "Impassibilité";
                assert LabelRank("Impassibilité") == 173;
              }
            } else {
              if i < 48 {
                assert LabelsZ7()[47] == "Sublimation";
                assert LabelRank("Sublimation") == 174;
              } else {
                assert LabelsZ7()[48] == "Dissolution";
                assert LabelRank("Dissolution") == 175;
              }
            }
          }
        }
      }
    }
  }

  lemma CheckGlobalLabelRank(i: nat)
    requires i < 176
    ensures LabelRank(All176Entries()[i].entryLabel) == i
  {
    assert All176Entries()[i].entryLabel == GlobalLabel(i);
    if i < 1 {
      CheckLabelRankZ0(i);
    } else if i < 2 {
      CheckLabelRankZ1(i - 1);
    } else if i < 11 {
      CheckLabelRankZ2(i - 2);
    } else if i < 28 {
      CheckLabelRankZ3(i - 11);
    } else if i < 53 {
      CheckLabelRankZ4(i - 28);
    } else if i < 86 {
      CheckLabelRankZ5(i - 53);
    } else if i < 127 {
      CheckLabelRankZ6(i - 86);
    } else {
      CheckLabelRankZ7(i - 127);
    }
  }

  // Lemme d'audit : les 176 étiquettes nominales de All176Entries sont deux à deux distinctes
  lemma all176Entries_unique_labels()
    ensures forall i, j | 0 <= i < j < |All176Entries()| ::
      All176Entries()[i].entryLabel != All176Entries()[j].entryLabel
  {
    forall i, j | 0 <= i < j < |All176Entries()|
      ensures All176Entries()[i].entryLabel != All176Entries()[j].entryLabel
    {
      CheckGlobalLabelRank(i);
      CheckGlobalLabelRank(j);
    }
  }

  lemma IntMulPos(a: int, b: int)
    requires (a > 0 && b > 0) || (a < 0 && b < 0)
    ensures a * b > 0
  {}

  lemma IntMulNeg(a: int, b: int)
    requires (a > 0 && b < 0) || (a < 0 && b > 0)
    ensures a * b < 0
  {}

  lemma DeployQuadrantEq(c: EngineCoupling, d: nat, piA: nat, piC: nat)
    ensures QuadrantContingency(
              DeployCouplingWithPrecision(c, d, piA, piC).x,
              DeployCouplingWithPrecision(c, d, piA, piC).y) == CouplingToContingency(c)
  {
    apportionRay_bounds(d, piA, piC);
  }

  lemma ProjectPerceptibleNeutralQuadrant(c: EngineCoupling, z: nat, piA: nat, piC: nat, susp: bool)
    requires IsGlobalNeutrality(c)
    ensures QuadrantContingency(
              ProjectPerceptible(c, z, piA, piC, susp).x,
              ProjectPerceptible(c, z, piA, piC, susp).y) == NoContingency
  {}

  lemma ProjectPerceptibleQuadrantEq(c: EngineCoupling, d: nat, piA: nat, piC: nat, susp: bool)
    ensures QuadrantContingency(
              ProjectPerceptible(c, d + 2, piA, piC, susp).x,
              ProjectPerceptible(c, d + 2, piA, piC, susp).y) == CouplingToContingency(c)
  {
    if IsGlobalNeutrality(c) {
      assert c == EngineCoupling(Zero, Zero);
      ProjectPerceptibleNeutralQuadrant(c, d + 2, piA, piC, susp);
    } else {
      DeployQuadrantEq(c, d, piA, piC);
    }
  }

  lemma ProjectPerceptibleZLe(c: EngineCoupling, z: nat, piA: nat, piC: nat, susp: bool)
    ensures ProjectPerceptible(c, z, piA, piC, susp).z <= z
  {
    if !IsGlobalNeutrality(c) && z >= 2 {
      deployCouplingWithPrecision_nonneutral_crown(c, z - 2, piA, piC);
    }
  }

  lemma PointInLexiconOfValidLe7(pt: CoreAffectPoint)
    requires IsValidCoreAffect(pt) && pt.z <= 7
    ensures pt in LexiconPoints()
    ensures exists e ::
      e in All176Entries() && e.point == pt &&
      (forall e' :: e' in All176Entries() && e'.point == pt ==> e' == e)
  {
    all176Entries_complete(pt);
    all176Entries_unique_points();
    var i :| 0 <= i < |All176Entries()| && All176Entries()[i].point == pt;
    assert 0 <= i < |LexiconPoints()|;
    assert LexiconPoints()[i] == GlobalPoint(i) == All176Entries()[i].point == pt;
    assert LexiconPoints()[i] in LexiconPoints();
    var e := All176Entries()[i];
    assert e in All176Entries() && e.point == pt;
    forall e' | e' in All176Entries() && e'.point == pt
      ensures e' == e
    {
      var j :| 0 <= j < |All176Entries()| && All176Entries()[j] == e';
      if j < i {
        assert All176Entries()[j].point != All176Entries()[i].point;
      } else if i < j {
        assert All176Entries()[i].point != All176Entries()[j].point;
      }
      assert j == i;
    }
  }

  lemma RunCartograffectPipelineCoherent(s: PredictiveEngineState)
    ensures IsCoherentTerminalState(s, RunCartograffectPipeline(s))
  {
    var ts := RunCartograffectPipeline(s);
    var cp := ProjectToCoreAffect(s);
    var ap := AntagonistPoint(cp);
    engine_induces_valid_core_affect(s);
    antagonistPoint_preserves_validity(cp);
    antagonistPoint_preserves_z(cp);
    antagonistPoint_preserves_displacementSum(cp);
    classifyTaxonomicGroup_correct(cp);
    classifyTaxonomicGroup_correct(ap);
    forall g: TaxonomicGroup | MatchesTaxonomicGroup(cp, g)
      ensures g == ts.group
    {
      matchesTaxonomicGroup_iff(cp, g);
    }
  }

  // =========================================================================
  // 3. Les 10 théorèmes de bout en bout (Strate 0 Hexa-Prouvée)
  // =========================================================================

  // [1/10] circuit_coupling_operant_bridge
  lemma circuit_coupling_operant_bridge(c: EngineCoupling, d: nat, piA: nat, piC: nat, susp: bool)
    ensures DiagToContingency(ProjectPerceptible(c, 2, piA, piC, susp)) == CouplingToContingency(c)
    ensures QuadrantContingency(
              ProjectPerceptible(c, d + 2, piA, piC, susp).x,
              ProjectPerceptible(c, d + 2, piA, piC, susp).y) == CouplingToContingency(c)
  {
    if IsGlobalNeutrality(c) {
      assert c == EngineCoupling(Zero, Zero);
    } else {
      projectPerceptible_z2_matches_phiL1(c, piA, piC, susp);
    }
    ProjectPerceptibleQuadrantEq(c, d, piA, piC, susp);
  }

  // [2/10] triggerSecondaryGradient_enters_operant
  lemma triggerSecondaryGradient_enters_operant(c: EngineCoupling, newPol: Polarity)
    requires IsSingleEngaged(c) && PolarityIsEngaged(newPol)
    ensures var c' := TriggerSecondaryGradient(c, newPol);
      var p' := DeployCouplingAtDepth(c', 0);
      DiagToContingency(DeployCouplingAtDepth(c, 0)) == NoContingency &&
      exists oc: OperantContingency ::
        DiagToContingency(p') == SomeContingency(oc) &&
        CouplingToContingency(c') == SomeContingency(oc) &&
        (c == EngineCoupling(Pos, Zero) ==> oc.effect == Reinforcement) &&
        (c == EngineCoupling(Neg, Zero) ==> oc.effect == Punishment) &&
        (c == EngineCoupling(Zero, Pos) ==>
          oc == OperantContingency(Reinforcement, Addition) ||
          oc == OperantContingency(Punishment, Removal)) &&
        (c == EngineCoupling(Zero, Neg) ==>
          oc == OperantContingency(Reinforcement, Removal) ||
          oc == OperantContingency(Punishment, Addition))
  {
    var c' := TriggerSecondaryGradient(c, newPol);
    var p' := DeployCouplingAtDepth(c', 0);
    assert CouplingToContingency(c').SomeContingency?;
    var oc := CouplingToContingency(c').val;
    assert DiagToContingency(p') == SomeContingency(oc);
  }

  // [3/10] p2_markov_contagion_enters_operant_punishment
  lemma p2_markov_contagion_enters_operant_punishment(p: CircuitKernelParams)
    requires p.chi > 0 && p.qPosC > 0 && p.qPosC < p.scale && p.rho + p.deltaA < p.scale
    ensures CircuitWeight(p, EngineCoupling(Neg, Zero), EngineCoupling(Neg, Pos)) > 0
    ensures CircuitWeight(p, EngineCoupling(Neg, Zero), EngineCoupling(Neg, Neg)) > 0
    ensures CouplingToContingency(EngineCoupling(Neg, Zero)) == NoContingency
    ensures CouplingToContingency(EngineCoupling(Neg, Pos)) ==
            SomeContingency(OperantContingency(Punishment, Removal))
    ensures CouplingToContingency(EngineCoupling(Neg, Neg)) ==
            SomeContingency(OperantContingency(Punishment, Addition))
  {
    axial_peur_bifurcates_p2(p);
  }

  // [4/10] operant_quadrant_lifting_all_strata
  lemma operant_quadrant_lifting_all_strata(p: CoreAffectPoint)
    requires p.x != 0 && p.y != 0
    ensures exists oc: OperantContingency ::
      QuadrantContingency(p.x, p.y) == SomeContingency(oc) &&
      (oc.effect == Reinforcement <==> p.x > 0) &&
      (oc.effect == Punishment <==> p.x < 0) &&
      (oc.op == Addition <==> p.x * p.y > 0) &&
      (oc.op == Removal <==> p.x * p.y < 0) &&
      (ComputeHedonicPolarity(p.x, p.y) == HedPositive <==> oc.effect == Reinforcement) &&
      (oc.op == Addition <==>
        (ComputeEnergyRegime(p.x, p.y) == PositiveSynergy ||
         ComputeEnergyRegime(p.x, p.y) == NegativeSynergy)) &&
      (oc.op == Removal <==>
        (ComputeEnergyRegime(p.x, p.y) == ErgotropicCompensation ||
         ComputeEnergyRegime(p.x, p.y) == TrophotropicRelease))
    ensures forall q | q in Z2DiagonalPoints() ::
      QuadrantContingency(q.x, q.y) == DiagToContingency(q)
  {
    if (p.x > 0 && p.y > 0) || (p.x < 0 && p.y < 0) {
      IntMulPos(p.x, p.y);
    } else {
      IntMulNeg(p.x, p.y);
    }
    assert QuadrantContingency(p.x, p.y).SomeContingency?;
    var oc := QuadrantContingency(p.x, p.y).val;
    assert QuadrantContingency(p.x, p.y) == SomeContingency(oc);
  }

  // [5/10] operant_antagonist_invariance_all_strata
  lemma operant_antagonist_invariance_all_strata(p: CoreAffectPoint)
    requires p.x != 0 && p.y != 0
    ensures exists c1: OperantContingency, c2: OperantContingency ::
      QuadrantContingency(p.x, p.y) == SomeContingency(c1) &&
      QuadrantContingency(AntagonistPoint(p).x, AntagonistPoint(p).y) == SomeContingency(c2) &&
      c1.effect != c2.effect &&
      c1.op == c2.op
  {
    AntagonistSignLemmas(p);
    var ap := AntagonistPoint(p);
    assert QuadrantContingency(p.x, p.y).SomeContingency?;
    assert QuadrantContingency(ap.x, ap.y).SomeContingency?;
    var c1 := QuadrantContingency(p.x, p.y).val;
    var c2 := QuadrantContingency(ap.x, ap.y).val;
    assert c1.effect != c2.effect && c1.op == c2.op;
  }

  lemma DepthKernelPreservesSingle(p: CoreAffectPoint, q: CoreAffectPoint)
    requires p.x != 0 && p.y != 0 && CanonicalDepthWeight(p, q) > 0
    ensures q.x != 0 && q.y != 0 && QuadrantContingency(q.x, q.y) == QuadrantContingency(p.x, p.y)
  {
    MulNonnegIff(p.x, q.x);
    MulNonnegIff(p.y, q.y);
  }

  // [6/10] depthKernel_preserves_operant_quadrant
  lemma {:isolate_assertions} depthKernel_preserves_operant_quadrant()
    ensures forall p: CoreAffectPoint, q: CoreAffectPoint ::
      (p.x != 0 && p.y != 0 && CanonicalDepthWeight(p, q) > 0) ==>
        (q.x != 0 && q.y != 0 && QuadrantContingency(q.x, q.y) == QuadrantContingency(p.x, p.y))
    ensures CanonicalDepthWeight(CoreAffectPoint(2, 0, 2), CoreAffectPoint(2, 2, 3)) > 0
    ensures CanonicalDepthWeight(CoreAffectPoint(2, 0, 2), CoreAffectPoint(2, -2, 3)) > 0
    ensures CanonicalDepthWeight(CoreAffectPoint(-2, 0, 2), CoreAffectPoint(-2, 2, 3)) > 0
    ensures CanonicalDepthWeight(CoreAffectPoint(-2, 0, 2), CoreAffectPoint(-2, -2, 3)) > 0
    ensures CanonicalDepthWeight(CoreAffectPoint(0, 2, 2), CoreAffectPoint(2, 2, 3)) > 0
    ensures CanonicalDepthWeight(CoreAffectPoint(0, 2, 2), CoreAffectPoint(-2, 2, 3)) > 0
    ensures CanonicalDepthWeight(CoreAffectPoint(0, -2, 2), CoreAffectPoint(2, -2, 3)) > 0
    ensures CanonicalDepthWeight(CoreAffectPoint(0, -2, 2), CoreAffectPoint(-2, -2, 3)) > 0
  {
    forall p: CoreAffectPoint, q: CoreAffectPoint | p.x != 0 && p.y != 0 && CanonicalDepthWeight(p, q) > 0
      ensures q.x != 0 && q.y != 0 && QuadrantContingency(q.x, q.y) == QuadrantContingency(p.x, p.y)
    {
      DepthKernelPreservesSingle(p, q);
    }
  }

  lemma {:isolate_assertions} LineageRPlusZ7()
    ensures CanonicalDepthWeight(CoreAffectPoint(1, 1, 2), CoreAffectPoint(2, 2, 3)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(2, 2, 3), CoreAffectPoint(3, 3, 4)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(3, 3, 4), CoreAffectPoint(4, 4, 5)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(4, 4, 5), CoreAffectPoint(5, 5, 6)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(5, 5, 6), CoreAffectPoint(6, 6, 7)) == 2
    ensures ClassifyOperantRole(CoreAffectPoint(6, 6, 7)) ==
            PureOperant(OperantContingency(Reinforcement, Addition))
    ensures ClassifyStratum(7) == Z7_sentimentsTranscendants
    ensures ClassifyTaxonomicGroup(CoreAffectPoint(6, 6, 7)) == GroupeDesir
    ensures ClassifySubsector(6, 6) == DiagonalDesire
    ensures LexiconEntry("Sublimation", CoreAffectPoint(6, 6, 7)) in All176Entries()
  {
    reveal LabelsZ7();
    assert All176Entries()[174].entryLabel == GlobalLabel(174) == LabelsZ7()[47] == "Sublimation";
    assert All176Entries()[174].point == GlobalPoint(174) == PointZ7(47) == CoreAffectPoint(6, 6, 7);
    assert All176Entries()[174] == LexiconEntry("Sublimation", CoreAffectPoint(6, 6, 7));
    assert All176Entries()[174] in All176Entries();
  }

  lemma {:isolate_assertions} LineageRMinusZ7()
    ensures CanonicalDepthWeight(CoreAffectPoint(1, -1, 2), CoreAffectPoint(2, -2, 3)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(2, -2, 3), CoreAffectPoint(3, -3, 4)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(3, -3, 4), CoreAffectPoint(4, -4, 5)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(4, -4, 5), CoreAffectPoint(5, -5, 6)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(5, -5, 6), CoreAffectPoint(6, -6, 7)) == 2
    ensures ClassifyOperantRole(CoreAffectPoint(6, -6, 7)) ==
            PureOperant(OperantContingency(Reinforcement, Removal))
    ensures ClassifyStratum(7) == Z7_sentimentsTranscendants
    ensures ClassifyTaxonomicGroup(CoreAffectPoint(6, -6, 7)) == GroupeCalme
    ensures ClassifySubsector(6, -6) == DiagonalCalm
    ensures LexiconEntry("Impassibilité", CoreAffectPoint(6, -6, 7)) in All176Entries()
  {
    reveal LabelsZ7();
    assert All176Entries()[173].entryLabel == GlobalLabel(173) == LabelsZ7()[46] == "Impassibilité";
    assert All176Entries()[173].point == GlobalPoint(173) == PointZ7(46) == CoreAffectPoint(6, -6, 7);
    assert All176Entries()[173] == LexiconEntry("Impassibilité", CoreAffectPoint(6, -6, 7));
    assert All176Entries()[173] in All176Entries();
  }

  lemma {:isolate_assertions} LineagePPlusZ7()
    ensures CanonicalDepthWeight(CoreAffectPoint(-1, -1, 2), CoreAffectPoint(-2, -2, 3)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(-2, -2, 3), CoreAffectPoint(-3, -3, 4)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(-3, -3, 4), CoreAffectPoint(-4, -4, 5)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(-4, -4, 5), CoreAffectPoint(-5, -5, 6)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(-5, -5, 6), CoreAffectPoint(-6, -6, 7)) == 2
    ensures ClassifyOperantRole(CoreAffectPoint(-6, -6, 7)) ==
            PureOperant(OperantContingency(Punishment, Addition))
    ensures ClassifyStratum(7) == Z7_sentimentsTranscendants
    ensures ClassifyTaxonomicGroup(CoreAffectPoint(-6, -6, 7)) == GroupeDegout
    ensures ClassifySubsector(-6, -6) == DiagonalDisgust
    ensures LexiconEntry("Dissolution", CoreAffectPoint(-6, -6, 7)) in All176Entries()
  {
    reveal LabelsZ7();
    assert All176Entries()[175].entryLabel == GlobalLabel(175) == LabelsZ7()[48] == "Dissolution";
    assert All176Entries()[175].point == GlobalPoint(175) == PointZ7(48) == CoreAffectPoint(-6, -6, 7);
    assert All176Entries()[175] == LexiconEntry("Dissolution", CoreAffectPoint(-6, -6, 7));
    assert All176Entries()[175] in All176Entries();
  }

  lemma {:isolate_assertions} LineagePMinusZ7()
    ensures CanonicalDepthWeight(CoreAffectPoint(-1, 1, 2), CoreAffectPoint(-2, 2, 3)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(-2, 2, 3), CoreAffectPoint(-3, 3, 4)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(-3, 3, 4), CoreAffectPoint(-4, 4, 5)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(-4, 4, 5), CoreAffectPoint(-5, 5, 6)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(-5, 5, 6), CoreAffectPoint(-6, 6, 7)) == 2
    ensures ClassifyOperantRole(CoreAffectPoint(-6, 6, 7)) ==
            PureOperant(OperantContingency(Punishment, Removal))
    ensures ClassifyStratum(7) == Z7_sentimentsTranscendants
    ensures ClassifyTaxonomicGroup(CoreAffectPoint(-6, 6, 7)) == GroupeColere
    ensures ClassifySubsector(-6, 6) == DiagonalAnger
    ensures LexiconEntry("Rage", CoreAffectPoint(-6, 6, 7)) in All176Entries()
  {
    reveal LabelsZ7();
    assert All176Entries()[172].entryLabel == GlobalLabel(172) == LabelsZ7()[45] == "Rage";
    assert All176Entries()[172].point == GlobalPoint(172) == PointZ7(45) == CoreAffectPoint(-6, 6, 7);
    assert All176Entries()[172] == LexiconEntry("Rage", CoreAffectPoint(-6, 6, 7));
    assert All176Entries()[172] in All176Entries();
  }

  // [7/10] operant_lineages_reach_z7_transcendentals
  lemma operant_lineages_reach_z7_transcendentals()
    // R+ : Désir (1,1,2) -> ... -> Sublimation (6,6,7)
    ensures CanonicalDepthWeight(CoreAffectPoint(1, 1, 2), CoreAffectPoint(2, 2, 3)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(2, 2, 3), CoreAffectPoint(3, 3, 4)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(3, 3, 4), CoreAffectPoint(4, 4, 5)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(4, 4, 5), CoreAffectPoint(5, 5, 6)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(5, 5, 6), CoreAffectPoint(6, 6, 7)) == 2
    ensures ClassifyOperantRole(CoreAffectPoint(6, 6, 7)) ==
            PureOperant(OperantContingency(Reinforcement, Addition))
    ensures ClassifyStratum(7) == Z7_sentimentsTranscendants
    ensures ClassifyTaxonomicGroup(CoreAffectPoint(6, 6, 7)) == GroupeDesir
    ensures ClassifySubsector(6, 6) == DiagonalDesire
    ensures LexiconEntry("Sublimation", CoreAffectPoint(6, 6, 7)) in All176Entries()
    // R- : Calme (1,-1,2) -> ... -> Impassibilité (6,-6,7)
    ensures CanonicalDepthWeight(CoreAffectPoint(1, -1, 2), CoreAffectPoint(2, -2, 3)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(2, -2, 3), CoreAffectPoint(3, -3, 4)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(3, -3, 4), CoreAffectPoint(4, -4, 5)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(4, -4, 5), CoreAffectPoint(5, -5, 6)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(5, -5, 6), CoreAffectPoint(6, -6, 7)) == 2
    ensures ClassifyOperantRole(CoreAffectPoint(6, -6, 7)) ==
            PureOperant(OperantContingency(Reinforcement, Removal))
    ensures ClassifyStratum(7) == Z7_sentimentsTranscendants
    ensures ClassifyTaxonomicGroup(CoreAffectPoint(6, -6, 7)) == GroupeCalme
    ensures ClassifySubsector(6, -6) == DiagonalCalm
    ensures LexiconEntry("Impassibilité", CoreAffectPoint(6, -6, 7)) in All176Entries()
    // P+ : Dégoût (-1,-1,2) -> ... -> Dissolution (-6,-6,7)
    ensures CanonicalDepthWeight(CoreAffectPoint(-1, -1, 2), CoreAffectPoint(-2, -2, 3)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(-2, -2, 3), CoreAffectPoint(-3, -3, 4)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(-3, -3, 4), CoreAffectPoint(-4, -4, 5)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(-4, -4, 5), CoreAffectPoint(-5, -5, 6)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(-5, -5, 6), CoreAffectPoint(-6, -6, 7)) == 2
    ensures ClassifyOperantRole(CoreAffectPoint(-6, -6, 7)) ==
            PureOperant(OperantContingency(Punishment, Addition))
    ensures ClassifyStratum(7) == Z7_sentimentsTranscendants
    ensures ClassifyTaxonomicGroup(CoreAffectPoint(-6, -6, 7)) == GroupeDegout
    ensures ClassifySubsector(-6, -6) == DiagonalDisgust
    ensures LexiconEntry("Dissolution", CoreAffectPoint(-6, -6, 7)) in All176Entries()
    // P- : Colère (-1,1,2) -> ... -> Rage (-6,6,7)
    ensures CanonicalDepthWeight(CoreAffectPoint(-1, 1, 2), CoreAffectPoint(-2, 2, 3)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(-2, 2, 3), CoreAffectPoint(-3, 3, 4)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(-3, 3, 4), CoreAffectPoint(-4, 4, 5)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(-4, 4, 5), CoreAffectPoint(-5, 5, 6)) == 2
    ensures CanonicalDepthWeight(CoreAffectPoint(-5, 5, 6), CoreAffectPoint(-6, 6, 7)) == 2
    ensures ClassifyOperantRole(CoreAffectPoint(-6, 6, 7)) ==
            PureOperant(OperantContingency(Punishment, Removal))
    ensures ClassifyStratum(7) == Z7_sentimentsTranscendants
    ensures ClassifyTaxonomicGroup(CoreAffectPoint(-6, 6, 7)) == GroupeColere
    ensures ClassifySubsector(-6, 6) == DiagonalAnger
    ensures LexiconEntry("Rage", CoreAffectPoint(-6, 6, 7)) in All176Entries()
  {
    LineageRPlusZ7();
    LineageRMinusZ7();
    LineagePPlusZ7();
    LineagePMinusZ7();
  }

  lemma {:isolate_assertions} ProjectPerceptibleTaxonomyCoherence(
    c: EngineCoupling, z: nat, piA: nat, piC: nat, susp: bool
  )
    ensures var cs := ProjectPerceptibleState(c, z, piA, piC, susp);
      var ts := EvaluateTaxonomy(EvaluateMatrix(cs, CanonicalMapping()));
      IsValidCoreAffect(ts.matrix.core)
    ensures var cs := ProjectPerceptibleState(c, z, piA, piC, susp);
      var ts := EvaluateTaxonomy(EvaluateMatrix(cs, CanonicalMapping()));
      IsValidCoreAffect(ts.matrix.antagonist)
    ensures var cs := ProjectPerceptibleState(c, z, piA, piC, susp);
      var ts := EvaluateTaxonomy(EvaluateMatrix(cs, CanonicalMapping()));
      ts.stratum == ClassifyStratum(ts.matrix.core.z)
    ensures var cs := ProjectPerceptibleState(c, z, piA, piC, susp);
      var ts := EvaluateTaxonomy(EvaluateMatrix(cs, CanonicalMapping()));
      MatchesTaxonomicGroup(ts.matrix.core, ts.group)
    ensures var cs := ProjectPerceptibleState(c, z, piA, piC, susp);
      var ts := EvaluateTaxonomy(EvaluateMatrix(cs, CanonicalMapping()));
      SubsectorToGroup(ts.subsector) == ts.group
    ensures var cs := ProjectPerceptibleState(c, z, piA, piC, susp);
      var ts := EvaluateTaxonomy(EvaluateMatrix(cs, CanonicalMapping()));
      SubsectorToHedonicPolarity(ts.subsector) == ts.matrix.valence
    ensures var cs := ProjectPerceptibleState(c, z, piA, piC, susp);
      var ts := EvaluateTaxonomy(EvaluateMatrix(cs, CanonicalMapping()));
      z >= 2 ==> QuadrantContingency(ts.matrix.core.x, ts.matrix.core.y) == CouplingToContingency(c)
    ensures var cs := ProjectPerceptibleState(c, z, piA, piC, susp);
      var ts := EvaluateTaxonomy(EvaluateMatrix(cs, CanonicalMapping()));
      z <= 7 ==> ts.matrix.core in LexiconPoints() && ts.matrix.antagonist in LexiconPoints()
  {
    projectPerceptible_valid(c, z, piA, piC, susp);
    var cs := ProjectPerceptibleState(c, z, piA, piC, susp);
    var ts := EvaluateTaxonomy(EvaluateMatrix(cs, CanonicalMapping()));
    var cp: CoreAffectPoint := ts.matrix.core;
    var ap: CoreAffectPoint := ts.matrix.antagonist;
    antagonistPoint_preserves_validity(cp);
    classifyTaxonomicGroup_correct(cp);
    classifySubsector_refines_group(cp);
    classifySubsector_determines_valence(cp.x, cp.y);
    if z >= 2 {
      var d: nat := z - 2;
      assert z == d + 2;
      ProjectPerceptibleQuadrantEq(c, d, piA, piC, susp);
    }
    if z <= 7 {
      ProjectPerceptibleZLe(c, z, piA, piC, susp);
      antagonistPoint_preserves_z(cp);
      PointInLexiconOfValidLe7(cp);
      PointInLexiconOfValidLe7(ap);
    }
  }

  // [8/10] unified_circuit_to_taxonomy_coherence
  lemma {:isolate_assertions} unified_circuit_to_taxonomy_coherence(
    p: UnifiedDynamicsParams, c: EngineCoupling,
    z: nat, rhoHat: nat, kappaHat: nat, susp: bool
  )
    ensures var ts := EvaluateUnifiedTaxonomy(p, c, z, rhoHat, kappaHat, susp);
      var cp: CoreAffectPoint := ts.matrix.core;
      var ap: CoreAffectPoint := ts.matrix.antagonist;
      IsValidCoreAffect(cp) &&
      IsValidCoreAffect(ap) &&
      ts.stratum == ClassifyStratum(cp.z) &&
      MatchesTaxonomicGroup(cp, ts.group) &&
      SubsectorToGroup(ts.subsector) == ts.group &&
      SubsectorToHedonicPolarity(ts.subsector) == ts.matrix.valence &&
      (z >= 2 ==> QuadrantContingency(cp.x, cp.y) == CouplingToContingency(c)) &&
      (z <= 7 ==> cp in LexiconPoints() && ap in LexiconPoints())
  {
    var sh := PrecisionShares(p, rhoHat, kappaHat, c);
    assert ProjectUnifiedState(p, c, z, rhoHat, kappaHat, susp) ==
           ProjectPerceptibleState(c, z, sh.0, sh.1, susp);
    ProjectPerceptibleTaxonomyCoherence(c, z, sh.0, sh.1, susp);
  }

  lemma Op3EngagedQuadrant(s: CircularCircuitState)
    requires AttentionalIsEngaged(s.attentional)
    ensures QuadrantContingency(
              Op3CrossingIPerceptible(s).1.x,
              Op3CrossingIPerceptible(s).1.y) ==
            CouplingToContingency(EngineCoupling(Op1SubjectiveOut(s), Op2PerceptiveOut(s)))
  {
    var c := EngineCoupling(Op1SubjectiveOut(s), Op2PerceptiveOut(s));
    var att := s.attentional;
    var susp := s.subjectiveHidden.descendingSuspension;
    if IsGlobalNeutrality(c) {
      assert c == EngineCoupling(Zero, Zero);
      var z: nat := if susp then att.persistenceDepth + 2 else 0;
      ProjectPerceptibleNeutralQuadrant(c, z, att.precisionA, att.precisionC, susp);
    } else {
      ProjectPerceptibleQuadrantEq(c, att.persistenceDepth, att.precisionA, att.precisionC, susp);
    }
  }

  lemma Op3PointZLe7(s: CircularCircuitState)
    requires s.attentional.persistenceDepth <= 5
    ensures Op3CrossingIPerceptible(s).1.z <= 7
  {
    var c := EngineCoupling(Op1SubjectiveOut(s), Op2PerceptiveOut(s));
    var att := s.attentional;
    var susp := s.subjectiveHidden.descendingSuspension;
    var z: nat :=
      if IsGlobalNeutrality(c) then
        if susp then att.persistenceDepth + 2 else 0
      else if !AttentionalIsEngaged(att) then
        if susp then att.persistenceDepth + 2 else 1
      else
        att.persistenceDepth + 2;
    ProjectPerceptibleZLe(c, z, att.precisionA, att.precisionC, susp);
  }

  // [9/10] circularCycle_to_taxonomy_and_lexicon_coherence
  lemma circularCycle_to_taxonomy_and_lexicon_coherence(s: CircularCircuitState)
    ensures var ts := EvaluateCircularTaxonomy(s);
      var cp: CoreAffectPoint := ts.matrix.core;
      var ap: CoreAffectPoint := ts.matrix.antagonist;
      var c := EngineCoupling(Op1SubjectiveOut(s), Op2PerceptiveOut(s));
      IsValidCoreAffect(cp) &&
      IsValidCoreAffect(ap) &&
      MatchesTaxonomicGroup(cp, ts.group) &&
      SubsectorToGroup(ts.subsector) == ts.group &&
      SubsectorToHedonicPolarity(ts.subsector) == ts.matrix.valence &&
      (AttentionalIsEngaged(s.attentional) ==> QuadrantContingency(cp.x, cp.y) == CouplingToContingency(c)) &&
      (s.attentional.persistenceDepth <= 5 ==>
        cp.z <= 7 && cp in LexiconPoints() && ap in LexiconPoints())
  {
    var ts := EvaluateCircularTaxonomy(s);
    var cp: CoreAffectPoint := ts.matrix.core;
    var ap: CoreAffectPoint := ts.matrix.antagonist;
    antagonistPoint_preserves_validity(cp);
    classifyTaxonomicGroup_correct(cp);
    classifySubsector_refines_group(cp);
    classifySubsector_determines_valence(cp.x, cp.y);
    if AttentionalIsEngaged(s.attentional) {
      Op3EngagedQuadrant(s);
    }
    if s.attentional.persistenceDepth <= 5 {
      Op3PointZLe7(s);
      antagonistPoint_preserves_z(cp);
      PointInLexiconOfValidLe7(cp);
      PointInLexiconOfValidLe7(ap);
    }
  }

  // [10/10] full_end_to_end_lexicon_resolution
  lemma full_end_to_end_lexicon_resolution(s: PredictiveEngineState)
    requires ProjectToCoreAffect(s).z <= 7
    ensures var ts := RunCartograffectPipeline(s);
      var cp: CoreAffectPoint := ts.matrix.core;
      var ap: CoreAffectPoint := ts.matrix.antagonist;
      IsCoherentTerminalState(s, ts) &&
      (forall ts': TaxonomicState :: IsCoherentTerminalState(s, ts') ==> ts' == ts) &&
      (exists e :: e in All176Entries() && e.point == cp &&
        (forall e' :: e' in All176Entries() && e'.point == cp ==> e' == e)) &&
      (exists ae :: ae in All176Entries() && ae.point == ap &&
        (forall ae' :: ae' in All176Entries() && ae'.point == ap ==> ae' == ae)) &&
      ((cp.x != 0 && cp.y != 0) ==>
        exists c1: OperantContingency, c2: OperantContingency ::
          QuadrantContingency(cp.x, cp.y) == SomeContingency(c1) &&
          QuadrantContingency(ap.x, ap.y) == SomeContingency(c2) &&
          c1.effect != c2.effect &&
          c1.op == c2.op)
  {
    var ts := RunCartograffectPipeline(s);
    var cp: CoreAffectPoint := ts.matrix.core;
    var ap: CoreAffectPoint := ts.matrix.antagonist;
    RunCartograffectPipelineCoherent(s);
    end_to_end_coherence(s);
    var ts0: TaxonomicState :|
      IsCoherentTerminalState(s, ts0) &&
      (forall ts': TaxonomicState :: IsCoherentTerminalState(s, ts') ==> ts' == ts0);
    assert ts == ts0;
    antagonistPoint_preserves_z(cp);
    PointInLexiconOfValidLe7(cp);
    PointInLexiconOfValidLe7(ap);
    if cp.x != 0 && cp.y != 0 {
      operant_antagonist_invariance_all_strata(cp);
    }
  }

}
