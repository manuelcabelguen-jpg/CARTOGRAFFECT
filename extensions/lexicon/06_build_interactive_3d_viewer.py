#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
================================================================================
06_build_interactive_3d_viewer.py
Génère l'explorateur interactif 3D autonome (HTML/Canvas) pour la Pyramide CARTOGRAFFECT :
- 176 prototypes répartis sur la Pyramide des Couronnes L1 (Z = 0..7, R_L1 = 2*(Z-1)) certifiée sous Lean 4
- Morphing géométrique radial L1 (Diamant) ↔ L2 (Sphère)
- Note Phase 1 (v3.0.0-dev) : les métriques synthétiques GRID-24 / CPM-142 (ex-SchererGRID.lean)
  ont été retirées et archivées dans `archive/deprecated_synthetic_v2/`.

Copyright (C) 2026  Projet CARTOGRAFFECT (Manuel Cabelguen)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

SPDX-License-Identifier: AGPL-3.0-or-later
================================================================================
"""

import json
import os
import pandas as pd

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Explorateur 3D Interactif — CARTOGRAFFECT® (Sphère Octaédrique Duale L1 ↔ L2 &amp; Taxonomie 6 Strates)</title>
  <script src="https://www.gstatic.com/antigravity/web/dev/tailwindcss.min.js"></script>
</head>
<body class="bg-[var(--background)] text-[var(--foreground)] antialiased p-4 select-none">
  <div class="max-w-[1640px] mx-auto flex flex-col gap-4">
    <!-- En-tête et métriques clés CARTOGRAFFECT® -->
    <div class="bg-[var(--card)] border border-[var(--border)] rounded-xl p-4 shadow-sm flex flex-wrap items-center justify-between gap-4">
      <div>
        <div class="flex flex-wrap items-center gap-2">
          <span class="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-600 text-white shadow-sm">
            ✓ Lean 4.35.0 Verified (Lexicon176.lean • Zero Sorry)
          </span>
          <span class="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-sky-500/20 text-sky-400 border border-sky-500/40">
            Explorateur Lexical Strate 1 (Z⁺ / Z⁻)
          </span>
          <span class="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-amber-500/20 text-amber-500 border border-amber-500/40">
            Sphère Octaédrique Duale (L1 ↔ L2)
          </span>
          <h1 class="text-lg font-bold text-[var(--foreground)]">CARTOGRAFFECT® — Sphère Octaédrique Duale (L1 ↔ L2) &amp; Taxonomie Multi-Strates (Z = 0 à 7)</h1>
        </div>
        <p class="text-xs text-[var(--muted-foreground)] mt-1">
          Architecture géométrique souveraine (OPIC n° 1233199) • Loi d'enveloppe |X| + |Y| = 2(Z - 1) • 176 prototypes (8 couronnes Z₀–Z₇) • 1 991 lemmes 3D (CNRS GLAWI / Lexique 3.83 / DIMA / NRC-VAD)
        </p>
      </div>
      <div class="flex flex-wrap gap-2 text-xs">
        <div class="bg-[var(--content)] border border-[var(--border)] rounded-lg px-3 py-1.5">
          <span class="text-[var(--muted-foreground)]">Architecture CARTOGRAFFECT® :</span>
          <span id="metricCcaBadge" class="font-bold text-[var(--foreground)] ml-1">176 pôles (Z₀–Z₇) • B(Z) = ‖u‖₁ = ‖u_Lp‖_p</span>
        </div>
        <div class="bg-[var(--content)] border border-[var(--border)] rounded-lg px-3 py-1.5">
          <span class="text-[var(--muted-foreground)]">Géométrie Lp :</span>
          <span id="metricTucker176Badge" class="font-bold text-emerald-400 ml-1">Homéomorphisme radial L1 ↔ L2</span>
        </div>
        <div class="bg-[var(--content)] border border-[var(--border)] rounded-lg px-3 py-1.5">
          <span class="text-[var(--muted-foreground)]">Statut épistémique :</span>
          <span id="metricTuckerZBadge" class="font-bold text-amber-400 ml-1">Strate 1 exploratoire (V3 = 0)</span>
        </div>
        <div class="bg-[var(--content)] border border-[var(--border)] rounded-lg px-3 py-1.5">
          <span class="text-[var(--muted-foreground)]">Licences (OPIC n° 1233199) :</span>
          <span class="font-bold text-[var(--foreground)] ml-1">AGPLv3 (Code) • CC BY-NC-SA 4.0 (Théorie)</span>
        </div>
      </div>
    </div>

    <!-- Curseur de Morphing Topologique Lp : Diamant (L1) <-> Sphère Riemannienne (L2) -->
    <div class="bg-[var(--card)] border border-[var(--border)] rounded-xl p-3.5 shadow-sm flex flex-wrap items-center justify-between gap-4">
      <div class="flex flex-col sm:flex-row sm:items-center gap-3 flex-1 min-w-[300px]">
        <div class="flex items-center gap-2">
          <label for="lpMorphSlider" class="text-xs font-bold text-[var(--foreground)] whitespace-nowrap">
            Géométrie de la Variété : Diamant (L1) ↔ Sphère (L2)
          </label>
          <span id="lpValueBadge" class="px-2.5 py-0.5 rounded-full text-xs font-mono font-bold bg-emerald-500/20 text-emerald-400 border border-emerald-500/40">
            p = 2.00 • Sphère Riemannienne L2
          </span>
        </div>
        <div class="flex items-center gap-2.5 flex-1 max-w-[440px]">
          <span class="text-xs font-mono text-[var(--muted-foreground)]">L1 (1.00)</span>
          <input id="lpMorphSlider" type="range" min="1.00" max="2.00" step="0.01" value="2.00"
            class="w-full accent-emerald-500 cursor-pointer h-2 rounded-lg" />
          <span class="text-xs font-mono text-[var(--muted-foreground)]">L2 (2.00)</span>
        </div>
      </div>
      <div class="flex flex-wrap items-center gap-2 text-xs">
        <button id="btnPresetL1" type="button"
          class="px-2.5 py-1 rounded-lg bg-[var(--content)] text-[var(--foreground)] border border-[var(--border)] hover:opacity-85 font-medium transition">
          [Diamant L1 (p=1)]
        </button>
        <button id="btnPresetP15" type="button"
          class="px-2.5 py-1 rounded-lg bg-[var(--content)] text-[var(--foreground)] border border-[var(--border)] hover:opacity-85 font-medium transition">
          [Superquadrique (p=1.5)]
        </button>
        <button id="btnPresetL2" type="button"
          class="px-2.5 py-1 rounded-lg bg-emerald-500/20 text-emerald-400 border border-emerald-500/40 hover:opacity-85 font-semibold transition">
          [Sphère Riemannienne L2 (p=2)]
        </button>
        <span id="lpFormulaInfo" class="text-[11px] font-mono text-[var(--muted-foreground)] hidden xl:inline ml-1">
          u_Lp = u · (‖u‖₁ / ‖u‖_p) • 8 Octants de Riemann (Z₇ équateur, pôles Z₋ / Z₊)
        </span>
      </div>
    </div>

    <!-- Barre de contrôle -->
    <div class="bg-[var(--card)] border border-[var(--border)] rounded-xl p-3.5 shadow-sm grid grid-cols-1 md:grid-cols-2 lg:grid-cols-12 gap-3 items-end">
      <div class="lg:col-span-3">
        <label class="block text-xs font-medium text-[var(--muted-foreground)] mb-1">Orientation de la Pyramide</label>
        <select id="geomMode" class="w-full bg-[var(--content)] text-[var(--foreground)] border border-[var(--border)] rounded-lg px-2.5 py-1.5 text-xs focus:outline-none">
          <option value="pyramid_up" selected>Pyramide L1 (Sommet Z=0 en haut • Base Z=7 en bas)</option>
          <option value="pyramid_asc">Pyramide Ascendante (Z=0 en bas • Z=7 en haut)</option>
          <option value="plan">Projection Plane Concentrique 2D (X, Y)</option>
        </select>
      </div>

      <div class="lg:col-span-2">
        <label class="block text-xs font-medium text-[var(--muted-foreground)] mb-1">Hémisphère / Couronne Z</label>
        <select id="zFilter" class="w-full bg-[var(--content)] text-[var(--foreground)] border border-[var(--border)] rounded-lg px-2.5 py-1.5 text-xs focus:outline-none">
          <option value="ALL">Sphère Complète • 303 pôles (Z⁺ + Équateur + Z⁻)</option>
          <option value="HEMI_PLUS">Hémisphère Affectif Z⁺ + Équateur (176 pôles)</option>
          <option value="HEMI_MINUS">Hémisphère Axiologique Z⁻ + Équateur (176 pôles)</option>
          <option value="0">Z = 0 — Veille (Pôle Nord Affectif)</option>
          <option value="1">Z = +1 — Surprise (1)</option>
          <option value="2">Z = +2 — Affects primaires (9 • R=2)</option>
          <option value="3">Z = +3 — Émotions réactives (17 • R=4)</option>
          <option value="4">Z = +4 — Sentiments réflexifs (25 • R=6)</option>
          <option value="5">Z = +5 — Dispositions durables (33 • R=8)</option>
          <option value="6">Z = +6 — Identités affectives (41 • R=10)</option>
          <option value="7">Z = +7 — Équateur Homéostatique (49 • R=12)</option>
          <option value="8">Z = -6 — Principes personnels (41 • R=10)</option>
          <option value="9">Z = -5 — Engagements éthiques (33 • R=8)</option>
          <option value="10">Z = -4 — Vertus relationnelles (25 • R=6)</option>
          <option value="11">Z = -3 — Postures axiologiques (17 • R=4)</option>
          <option value="12">Z = -2 — Fondements cardinaux (9 • R=2)</option>
          <option value="13">Z = -1 — Évidence (1)</option>
          <option value="14">Z = -7 — Éveil (Pôle Sud Axiologique)</option>
        </select>
      </div>

      <div class="lg:col-span-2">
        <label class="block text-xs font-medium text-[var(--muted-foreground)] mb-1">Groupe géométrique / Strate (S1-S6)</label>
        <div class="flex gap-1">
          <select id="groupFilter" class="w-1/2 bg-[var(--content)] text-[var(--foreground)] border border-[var(--border)] rounded-lg px-2 py-1.5 text-xs focus:outline-none">
            <option value="ALL">Tous Groupes (303)</option>
            <option value="JOIE">JOIE / VOLONTÉ (+Y)</option>
            <option value="TRISTESSE">TRISTESSE / TEMPÉRANCE (-Y)</option>
            <option value="COURAGE">COURAGE / AUDACE (+X)</option>
            <option value="PEUR">PEUR / PRUDENCE (-X)</option>
            <option value="DESIR">DÉSIR / ASPIRATION (+X/+Y)</option>
            <option value="DEGOUT">DÉGOÛT / INTÉGRITÉ (-X/-Y)</option>
            <option value="COLERE">COLÈRE / ÉQUITÉ (-X/+Y)</option>
            <option value="CALME">CALME / CLÉMENCE (+X/-Y)</option>
            <option value="OPERATEUR_CENTRAL">CENTRE (0,0,Z)</option>
          </select>
          <select id="stratumFilter" class="w-1/2 bg-[var(--content)] text-[var(--foreground)] border border-[var(--border)] rounded-lg px-2 py-1.5 text-xs focus:outline-none">
            <option value="ALL">6 Strates (S1-S6)</option>
            <option value="1">S1 • Somatique (&lt;0.65)</option>
            <option value="2">S2 • Émotif (0.65-0.95)</option>
            <option value="3">S3 • Sentimental (0.95-1.25)</option>
            <option value="4">S4 • Éthique (1.25-1.60)</option>
            <option value="5">S5 • Axiologique (1.60-2.00)</option>
            <option value="6">S6 • Politique (&ge;2.00)</option>
          </select>
        </div>
      </div>

      <div class="lg:col-span-2">
        <label class="block text-xs font-medium text-[var(--muted-foreground)] mb-1">Rechercher dans CARTOGRAFFECT®</label>
        <input id="searchInput" type="text" placeholder="Ex : citoyenneté, probité, équité, joie..."
          class="w-full bg-[var(--content)] text-[var(--foreground)] border border-[var(--border)] rounded-lg px-2.5 py-1.5 text-xs focus:outline-none" />
      </div>

      <div class="lg:col-span-3 flex items-center gap-2.5 flex-wrap text-xs pt-1">
        <label class="inline-flex items-center gap-1.5 cursor-pointer">
          <input id="showAffects" type="checkbox" checked class="rounded" />
          <span>Nuage 1 991 lemmes 3D</span>
        </label>
        <label class="inline-flex items-center gap-1.5 cursor-pointer">
          <input id="showWireframe" type="checkbox" checked class="rounded" />
          <span>Enveloppe Lp</span>
        </label>
        <label class="inline-flex items-center gap-1.5 cursor-pointer px-2 py-1 rounded-md bg-amber-500/10 border border-amber-500/30 text-amber-500" title="Afficher/masquer l'échantillon externe de 24 termes Scherer GRID utilisé pour la validation psychométrique">
          <input id="showGrid24" type="checkbox" class="rounded" />
          <span>Témoins GRID (24)</span>
        </label>
        <button id="resetCamBtn" class="ml-auto px-2.5 py-1 rounded-lg bg-[var(--content)] border border-[var(--border)] hover:opacity-80 text-xs font-medium">
          Réinitialiser
        </button>
      </div>
    </div>

    <!-- Zone principale : Canvas 3D + Panneau d'inspection CARTOGRAFFECT -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-4">
      <!-- Canvas 3D -->
      <div class="lg:col-span-7 bg-[var(--card)] border border-[var(--border)] rounded-xl p-3 shadow-sm flex flex-col">
        <div class="flex items-center justify-between mb-2 text-xs text-[var(--muted-foreground)]">
          <span id="canvasStatus">Glisser pour pivoter • Molette pour zoomer • Cliquer sur un pôle CARTOGRAFFECT® pour inspecter sa couronne Z et ses lemmes</span>
          <span id="visibleCountBadge" class="font-medium text-[var(--foreground)]">176 prototypes affichés</span>
        </div>
        <div class="relative w-full h-[680px] rounded-lg overflow-hidden border border-[var(--border)] bg-[var(--content)]">
          <canvas id="sceneCanvas" class="w-full h-full block cursor-grab active:cursor-grabbing"></canvas>
          <!-- Légende flottante des groupes -->
          <div id="legendBox" class="absolute bottom-3 left-3 bg-[var(--card)]/90 backdrop-blur border border-[var(--border)] rounded-lg p-2.5 text-xs flex flex-wrap gap-x-3 gap-y-1 max-w-[95%]"></div>
        </div>
      </div>

      <!-- Inspecteur de prototype CARTOGRAFFECT (Géométrie, Symétrie Lean 4, Lexique Multi-Strates & Validation externe) -->
      <div class="lg:col-span-5 bg-[var(--card)] border border-[var(--border)] rounded-xl p-4 shadow-sm flex flex-col h-[732px] overflow-y-auto">
        <div id="inspectorHeader" class="border-b border-[var(--border)] pb-2.5">
          <div class="flex items-center justify-between gap-2 flex-wrap">
            <div class="flex items-center gap-1.5">
              <span id="protoIdBadge" class="px-2 py-0.5 rounded text-xs font-mono bg-[var(--content)] border border-[var(--border)]">#4</span>
              <span id="protoGridBadge" class="hidden px-2 py-0.5 rounded text-xs font-semibold bg-amber-500/20 text-amber-400 border border-amber-500/40">Témoin externe GRID</span>
            </div>
            <span id="protoGroupBadge" class="px-2.5 py-0.5 rounded-full text-xs font-semibold">JOIE</span>
          </div>
          <div class="flex items-baseline justify-between mt-1.5">
            <h2 id="protoTitle" class="text-xl font-bold text-[var(--foreground)]">Joie</h2>
            <span class="text-[11px] font-mono text-emerald-500 font-semibold">CARTOGRAFFECT® • Lean 4.35.0 Verified</span>
          </div>
          <p id="protoCoords" class="text-xs text-[var(--muted-foreground)] mt-0.5 font-mono"></p>
        </div>

        <!-- 1. Architecture & Symétrie Antagoniste CARTOGRAFFECT® (Lean 4 Intra-couronne Z) -->
        <div class="bg-[var(--content)] border border-[var(--border)] rounded-lg p-2.5 my-2.5 text-xs space-y-1">
          <div class="flex items-center justify-between">
            <span class="text-[var(--muted-foreground)] font-medium">Antagoniste CARTOGRAFFECT® (même couronne Z) :</span>
            <button id="jumpAntagBtn" class="font-semibold underline hover:opacity-80 text-[var(--foreground)]"></button>
          </div>
          <div class="flex items-center justify-between">
            <span class="text-[var(--muted-foreground)]">Coordonnées antagoniste | Règle :</span>
            <span id="protoAntagCoords" class="font-mono text-[var(--foreground)]"></span>
          </div>
          <div class="flex items-center justify-between">
            <span class="text-[var(--muted-foreground)]">Barycentre lexical (V, A, D) | d_L1 :</span>
            <span id="protoMeanVAD" class="font-mono text-[var(--foreground)]"></span>
          </div>
        </div>

        <!-- 2. Top 5 des termes français les plus fidèles au pôle CARTOGRAFFECT -->
        <div class="mb-2">
          <div class="text-xs font-semibold text-[var(--muted-foreground)] mb-1">Top 5 des lemmes français canoniques du pôle :</div>
          <div id="protoTop5" class="flex flex-wrap gap-1.5 text-xs"></div>
        </div>

        <!-- 3. Liste déroulante des affects ancrés (Dictionnaire Multi-Strates S1-S6) -->
        <div class="flex items-center justify-between mt-1 mb-1">
          <span class="text-xs font-semibold text-[var(--foreground)]">Lemmes CARTOGRAFFECT® ancrés (<span id="anchoredCount">0</span>)</span>
          <span class="text-xs text-[var(--muted-foreground)]">Strates S1–S6 • Triés par distance L1</span>
        </div>
        <div id="anchoredList" class="flex-1 min-h-[180px] overflow-y-auto border border-[var(--border)] rounded-lg divide-y divide-[var(--border)] bg-[var(--content)] text-xs"></div>

        <!-- 4. Volet secondaire repliable : Support de validation externe (Scherer GRID / CPM) -->
        <details class="mt-2.5 bg-[var(--content)] border border-[var(--border)] rounded-lg p-2.5 text-xs">
          <summary class="cursor-pointer font-semibold text-[var(--muted-foreground)] hover:text-[var(--foreground)] select-none">
            Support de validation externe (Échantillon-témoin Scherer GRID / CPM)
          </summary>
          <div class="grid grid-cols-1 sm:grid-cols-12 gap-3 mt-2.5 pt-2 border-t border-[var(--border)]">
            <!-- Diagramme Radar des 5 composantes CPM -->
            <div class="sm:col-span-6 flex flex-col items-center justify-center border-b sm:border-b-0 sm:border-r border-[var(--border)] pr-0 sm:pr-2 pb-2 sm:pb-0">
              <div class="text-[11px] font-semibold text-[var(--muted-foreground)] mb-1 text-center">
                Projection CPM 5 Composantes (142 items)
              </div>
              <canvas id="cpmRadarCanvas" width="210" height="175" class="block"></canvas>
            </div>

            <!-- Jauge de Régime Vertical Z & Facteurs GRID 4D -->
            <div class="sm:col-span-6 flex flex-col justify-between text-xs space-y-2 pl-0 sm:pl-1">
              <div>
                <div class="flex items-center justify-between mb-1">
                  <span class="text-[11px] font-semibold text-[var(--muted-foreground)]">Régime Vertical Z (Proxy Ratio_Z) :</span>
                  <span id="zRegimeBadge" class="px-2 py-0.5 rounded text-[11px] font-mono font-bold">Z_pos</span>
                </div>
                <div class="relative w-full h-3 rounded-full overflow-hidden bg-gradient-to-r from-rose-500/80 via-amber-400/80 to-emerald-500/80 border border-[var(--border)]">
                  <div class="absolute inset-y-0 left-1/2 w-0.5 bg-white/90" title="Z_7 Équilibre homéostatique (Ratio_Z = 1.0)"></div>
                  <div id="zRatioMarker" class="absolute top-0 bottom-0 w-2.5 -ml-1.25 rounded-full bg-white border-2 border-slate-900 shadow" style="left:50%"></div>
                </div>
                <div class="flex justify-between text-[10px] text-[var(--muted-foreground)] font-mono mt-0.5">
                  <span>Z_neg (&lt;1 Somatique)</span>
                  <span>Z_7 (=1)</span>
                  <span>Z_pos (&gt;1 Normatif)</span>
                </div>
              </div>

              <div class="space-y-1 text-[11px] border-t border-[var(--border)] pt-1.5">
                <div class="flex justify-between">
                  <span class="text-[var(--muted-foreground)]">Proxy Ratio_Z :</span>
                  <span id="cpmRatioZVal" class="font-mono font-bold text-[var(--foreground)]">1.00</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-[var(--muted-foreground)]">Agentivité (Axe Y) :</span>
                  <span id="cpmCopingBadge" class="font-mono font-semibold"></span>
                </div>
                <div class="flex justify-between">
                  <span class="text-[var(--muted-foreground)]">Facteurs témoins (V, P, A, N) :</span>
                  <span id="cpmFactors4D" class="font-mono text-[var(--foreground)]"></span>
                </div>
              </div>

              <div id="cpmBarsList" class="space-y-0.5 text-[10px] font-mono border-t border-[var(--border)] pt-1"></div>
            </div>
          </div>
        </details>
      </div>
    </div>
  </div>

  <script>
    const PROTOS = __PROTOS_JSON__;
    const AFFECTS = __AFFECTS_JSON__;

    const GROUP_COLORS = {
      JOIE: "#f59e0b",
      VOLONTÉ: "#f59e0b",
      TRISTESSE: "#3b82f6",
      TEMPÉRANCE: "#3b82f6",
      COURAGE: "#10b981",
      AUDACE: "#10b981",
      PEUR: "#8b5cf6",
      PRUDENCE: "#8b5cf6",
      DESIR: "#ec4899",
      ASPIRATION: "#ec4899",
      DEGOUT: "#84cc16",
      INTÉGRITÉ: "#84cc16",
      COLERE: "#ef4444",
      ÉQUITÉ: "#ef4444",
      CALME: "#06b6d4",
      CLÉMENCE: "#06b6d4",
      OPERATEUR_CENTRAL: "#eab308"
    };

    const GROUP_EQUIV = {
      JOIE: ["JOIE", "VOLONTÉ"],
      TRISTESSE: ["TRISTESSE", "TEMPÉRANCE"],
      COURAGE: ["COURAGE", "AUDACE"],
      PEUR: ["PEUR", "PRUDENCE"],
      DESIR: ["DESIR", "ASPIRATION"],
      DEGOUT: ["DEGOUT", "INTÉGRITÉ"],
      COLERE: ["COLERE", "ÉQUITÉ"],
      CALME: ["CALME", "CLÉMENCE"],
      OPERATEUR_CENTRAL: ["OPERATEUR_CENTRAL"]
    };

    const protoById = {};
    PROTOS.forEach(p => {
      protoById[p.id_176] = p;
    });

    const affectsByProto = {};
    PROTOS.forEach(p => { affectsByProto[p.id_176] = []; });
    AFFECTS.forEach(a => {
      if (affectsByProto[a.id]) affectsByProto[a.id].push(a);
    });

    // Légende
    const legendBox = document.getElementById("legendBox");
    Object.entries(GROUP_COLORS).forEach(([grp, col]) => {
      const item = document.createElement("button");
      item.className = "inline-flex items-center gap-1.5 hover:opacity-80";
      item.innerHTML = `<span class="w-2.5 h-2.5 rounded-full inline-block" style="background:${col}"></span><span>${grp}</span>`;
      item.onclick = () => {
        const sel = document.getElementById("groupFilter");
        sel.value = sel.value === grp ? "ALL" : grp;
        updateFilters();
      };
      legendBox.appendChild(item);
    });

    // État de la caméra et sélection (Joie #4 sélectionné par défaut pour illustrer une ancre GRID)
    let rotYaw = -0.62;
    let rotPitch = 0.28;
    let zoom = 0.92;
    let lpExponent = 2.00;
    let selectedProtoId = 4;
    let hoveredProtoId = null;
    let filteredProtoIds = new Set(PROTOS.map(p => p.id_176));
    let matchedAffectTerm = null;

    // Homéomorphisme radial bijectif Lp : u_Lp = u * (||u||_1 / ||u||_p) autour de l'équateur Z_eq = 7.0
    // Sur les couronnes Z = 1..7, |X| + |Y| = 2(Z - 1), donc avec Z_rel = 2(Z - 7),
    // on a l'identité exacte de l'octaèdre régulier : |X| + |Y| + |Z_rel| = 12 = constante !
    // Pour p = 2.0, tous les points se projettent sur la SPHÈRE EXACTE de rayon R = 12 : X_lp² + Y_lp² + Z_rel_lp² = 12².
    function mapOctahedralL1ToLpSphere(X, Y, Z, p = lpExponent, Z_eq = 7.0) {
      const pVal = Math.max(1.0, Math.min(2.0, Number(p) || 1.0));
      const zRel = 2.0 * (Z - Z_eq);
      const ax = Math.abs(X), ay = Math.abs(Y), az = Math.abs(zRel);
      const norm1 = ax + ay + az;
      if (norm1 < 1e-9 || pVal <= 1.0001) {
        return { X_lp: X, Y_lp: Y, Z_lp: Z, Z_rel_lp: zRel, norm1, scale: 1.0 };
      }
      const normP = Math.pow(Math.pow(ax, pVal) + Math.pow(ay, pVal) + Math.pow(az, pVal), 1.0 / pVal);
      const scale = normP > 1e-9 ? (norm1 / normP) : 1.0;
      const zRelLp = zRel * scale;
      return {
        X_lp: X * scale,
        Y_lp: Y * scale,
        Z_lp: Z_eq + 0.5 * zRelLp,
        Z_rel_lp: zRelLp,
        norm1,
        scale
      };
    }

    function updateLpMetricsHeader() {
      const badge = document.getElementById("lpValueBadge");
      let geomName = "Variété Superquadrique Lp";
      if (lpExponent <= 1.02) geomName = "Diamant Octaédrique L1";
      else if (lpExponent >= 1.98) geomName = "Sphère Riemannienne L2";
      else if (Math.abs(lpExponent - 1.5) <= 0.03) geomName = "Superquadrique Intermédiaire";
      if (badge) {
        badge.textContent = `p = ${lpExponent.toFixed(2)} • ${geomName}`;
      }

      const ccaEl = document.getElementById("metricCcaBadge");
      if (ccaEl) {
        ccaEl.textContent = `303 pôles (Z⁺/Z⁻) • p = ${lpExponent.toFixed(2)} • B(Z) = ‖u‖₁ = ‖u_Lp‖_p`;
      }
      const t176El = document.getElementById("metricTucker176Badge");
      if (t176El) {
        t176El.textContent = `${geomName} (homéomorphisme radial L1 ↔ L2)`;
      }
      const tzEl = document.getElementById("metricTuckerZBadge");
      if (tzEl) {
        tzEl.textContent = `Strate 1 exploratoire (GRID-24 synthétique retiré en Phase 1)`;
      }

      // Mise à jour de l'état actif des 3 boutons rapides
      const b1 = document.getElementById("btnPresetL1");
      const b15 = document.getElementById("btnPresetP15");
      const b2 = document.getElementById("btnPresetL2");
      const activeCls = "px-2.5 py-1 rounded-lg bg-emerald-500/20 text-emerald-400 border border-emerald-500/40 hover:opacity-85 font-semibold transition";
      const idleCls = "px-2.5 py-1 rounded-lg bg-[var(--content)] text-[var(--foreground)] border border-[var(--border)] hover:opacity-85 font-medium transition";
      if (b1 && b15 && b2) {
        b1.className = Math.abs(lpExponent - 1.0) < 0.03 ? activeCls : idleCls;
        b15.className = Math.abs(lpExponent - 1.5) < 0.03 ? activeCls : idleCls;
        b2.className = Math.abs(lpExponent - 2.0) < 0.03 ? activeCls : idleCls;
      }
    }

    const canvas = document.getElementById("sceneCanvas");
    const ctx = canvas.getContext("2d");

    function resizeCanvas() {
      const rect = canvas.parentElement.getBoundingClientRect();
      const dpr = window.devicePixelRatio || 1;
      canvas.width = rect.width * dpr;
      canvas.height = rect.height * dpr;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      drawScene();
    }
    window.addEventListener("resize", resizeCanvas);

    function zHeightForMode(zVal, mode) {
      if (mode === "plan") return 0;
      const tMorph = Math.max(0.0, Math.min(1.0, lpExponent - 1.0));
      // En mode Pyramide pure (p=1), centré sur Z=3.5 ; en mode Sphère duale (p=2), centré sur l'équateur Z=7
      const zCenter = (1.0 - tMorph) * 3.5 + tMorph * 7.0;
      const zScale = (1.0 - tMorph) * 2.25 + tMorph * 1.85;
      if (mode === "pyramid_up") {
        return (zCenter - zVal) * zScale;
      }
      return (zVal - zCenter) * zScale;
    }

    function getProtoCoords3D(p, mode) {
      const mapped = mapOctahedralL1ToLpSphere(p.X, p.Y, p.Z, lpExponent, 7.0);
      return [mapped.X_lp, mapped.Y_lp, zHeightForMode(mapped.Z_lp, mode)];
    }

    function getAffectCoords3D(a, mode) {
      const p = protoById[a.id];
      const r = p && p.rayon_L1 > 0 ? p.rayon_L1 : 1;
      const mapped = mapOctahedralL1ToLpSphere(a.x * r, a.y * r, a.z, lpExponent, 7.0);
      return [mapped.X_lp, mapped.Y_lp, zHeightForMode(mapped.Z_lp, mode)];
    }

    function projectPoint([x, y, z], w, h) {
      const cosY = Math.cos(rotYaw), sinY = Math.sin(rotYaw);
      const cosP = Math.cos(rotPitch), sinP = Math.sin(rotPitch);
      const x1 = x * cosY - y * sinY;
      const y1 = x * sinY + y * cosY;
      const z2 = z * cosP - y1 * sinP;
      const depth = z * sinP + y1 * cosP;
      const scale = (Math.min(w, h) * 0.032 * zoom) * (42 / (42 - depth * 0.45));
      return {
        sx: w * 0.5 + x1 * scale,
        sy: h * 0.52 - z2 * scale,
        depth,
        scale
      };
    }

    let projectedNodes = [];

    function drawScene() {
      const rect = canvas.parentElement.getBoundingClientRect();
      const w = rect.width, h = rect.height;
      ctx.clearRect(0, 0, w, h);

      const isLight = document.documentElement.classList.contains("light");
      const gridStroke = isLight ? "rgba(100,116,139,0.28)" : "rgba(148,163,184,0.22)";
      const ribStroke = isLight ? "rgba(71,85,105,0.40)" : "rgba(148,163,184,0.32)";
      const axisStroke = isLight ? "rgba(71,85,105,0.55)" : "rgba(203,213,225,0.40)";
      const textFill = isLight ? "#0f172a" : "#f8fafc";

      const mode = document.getElementById("geomMode").value;
      const showWire = document.getElementById("showWireframe").checked;
      const showAff = document.getElementById("showAffects").checked;
      const showGrid24 = document.getElementById("showGrid24").checked;

      // 1. Axes, couronnes Lp (Diamant L1 -> Sphère L2), équateur Z7, pôles Z-/Z+ et 8 octants de Riemann
      if (showWire) {
        const tMorph = Math.max(0.0, Math.min(1.0, lpExponent - 1.0));
        const z0 = zHeightForMode(0, mode);
        const z1 = zHeightForMode(1, mode);
        const z7 = zHeightForMode(7, mode);
        const zSouthPole = zHeightForMode(13, mode); // Pôle dual Z+ symétrique par rapport à Z=7

        ctx.strokeStyle = axisStroke;
        ctx.lineWidth = 1.2;
        const axes = [
          [[-13, 0, z7], [13, 0, z7]],
          [[0, -13, z7], [0, 13, z7]],
          [[0, 0, z0], [0, 0, tMorph > 0.02 ? zSouthPole : z7]]
        ];
        axes.forEach(([p1, p2]) => {
          const a = projectPoint(p1, w, h);
          const b = projectPoint(p2, w, h);
          ctx.beginPath();
          ctx.moveTo(a.sx, a.sy);
          ctx.lineTo(b.sx, b.sy);
          ctx.stroke();
        });

        // Parallèles / Couronnes Lp (hémisphère Z=2..7 + hémisphère dual Z'=8..12 pour former la sphère complète à 8 octants)
        const nRingSteps = 64;
        const maxZRing = tMorph > 0.02 ? 12 : 7;
        for (let z = 2; z <= maxZRing; z++) {
          const zMirror = z <= 7 ? z : (14 - z);
          const rL1 = 2 * (zMirror - 1);
          const isEquatorZ7 = (z === 7);
          const isDualSouth = (z > 7);
          ctx.strokeStyle = isEquatorZ7 && tMorph > 0.05
            ? (isLight ? "rgba(16,185,129,0.75)" : "rgba(52,211,153,0.65)")
            : gridStroke;
          ctx.lineWidth = isEquatorZ7 && tMorph > 0.05 ? 1.85 : 1.15;
          ctx.globalAlpha = isDualSouth ? (0.55 * tMorph) : 1.0;
          ctx.beginPath();
          for (let s = 0; s <= nRingSteps; s++) {
            const theta = (s / nRingSteps) * Math.PI * 2;
            const c = Math.cos(theta), sn = Math.sin(theta);
            const l1Unit = Math.max(1e-6, Math.abs(c) + Math.abs(sn));
            // Point exact sur le losange L1 de rayon rL1
            const xL1 = rL1 * (c / l1Unit);
            const yL1 = rL1 * (sn / l1Unit);
            const mapped = mapOctahedralL1ToLpSphere(xL1, yL1, z, lpExponent, 7.0);
            const pr = projectPoint([mapped.X_lp, mapped.Y_lp, zHeightForMode(mapped.Z_lp, mode)], w, h);
            if (s === 0) ctx.moveTo(pr.sx, pr.sy);
            else ctx.lineTo(pr.sx, pr.sy);
          }
          ctx.stroke();
        }
        ctx.globalAlpha = 1.0;

        if (mode !== "plan") {
          // 8 Méridiens délimitant les 8 Octants de Riemann (4 cardinaux + 4 diagonaux) :
          // Arêtes rectilignes de l'octaèdre en p=1 -> grands cercles méridiens de pôle à pôle en p=2
          const meridianAngles = [
            0, Math.PI * 0.5, Math.PI, Math.PI * 1.5,
            Math.PI * 0.25, Math.PI * 0.75, Math.PI * 1.25, Math.PI * 1.75
          ];
          const nMeridianSteps = 48;
          const zEndMeridian = tMorph > 0.02 ? 13.0 : 7.0;
          meridianAngles.forEach((theta, idx) => {
            const c = Math.cos(theta), sn = Math.sin(theta);
            const l1Unit = Math.max(1e-6, Math.abs(c) + Math.abs(sn));
            ctx.strokeStyle = ribStroke;
            ctx.lineWidth = idx < 4 ? 1.35 : 1.05;
            ctx.globalAlpha = idx < 4 ? 1.0 : (0.45 + 0.45 * tMorph);
            ctx.beginPath();
            for (let k = 0; k <= nMeridianSteps; k++) {
              const zVal = 1.0 + (k / nMeridianSteps) * (zEndMeridian - 1.0);
              const zMirror = zVal <= 7.0 ? zVal : (14.0 - zVal);
              const rL1 = 2.0 * (zMirror - 1.0);
              const xL1 = rL1 * (c / l1Unit);
              const yL1 = rL1 * (sn / l1Unit);
              const mapped = mapOctahedralL1ToLpSphere(xL1, yL1, zVal, lpExponent, 7.0);
              const pr = projectPoint([mapped.X_lp, mapped.Y_lp, zHeightForMode(mapped.Z_lp, mode)], w, h);
              if (k === 0) ctx.moveTo(pr.sx, pr.sy);
              else ctx.lineTo(pr.sx, pr.sy);
            }
            ctx.stroke();
          });
          ctx.globalAlpha = 1.0;

          // Étiquettes des pôles Z- / Z+ et de l'équateur homéostatique Z_7 lorsque p > 1.05
          if (tMorph > 0.05) {
            ctx.save();
            ctx.font = "bold 10.5px monospace";
            ctx.fillStyle = isLight ? "#059669" : "#34d399";
            const eqPt = projectPoint([12.4, 0, z7], w, h);
            ctx.fillText("Équateur homéostatique Z₇ (R=12)", eqPt.sx + 6, eqPt.sy + 3);
            const poleNeg = projectPoint([0, 0, z1], w, h);
            ctx.fillText("Pôle Z₀/Z₁ (Veille / Somatique)", poleNeg.sx + 8, poleNeg.sy - 4);
            const polePos = projectPoint([0, 0, zSouthPole], w, h);
            ctx.fillText("Pôle Dual Z⁻ (Hémisphère Axiologique)", polePos.sx + 8, polePos.sy + 12);
            ctx.restore();
          }
        }
      }

      // 2. Nuage des affects si activé
      if (showAff) {
        AFFECTS.forEach(a => {
          if (!filteredProtoIds.has(a.id)) return;
          const p = protoById[a.id];
          const pt = projectPoint(getAffectCoords3D(a, mode), w, h);
          ctx.fillStyle = GROUP_COLORS[p.groupe_geom] || "#94a3b8";
          ctx.globalAlpha = a.id === selectedProtoId ? 0.75 : 0.25;
          ctx.beginPath();
          ctx.arc(pt.sx, pt.sy, a.id === selectedProtoId ? 2.6 : 1.7, 0, Math.PI * 2);
          ctx.fill();
        });
        ctx.globalAlpha = 1.0;
      }

      // 3. Lien d'antagonisme intra-couronne P <-> P* pour le prototype sélectionné
      const selP = protoById[selectedProtoId];
      if (selP && selP.antag_id > 0 && selP.antag_id !== selP.id_176 && protoById[selP.antag_id]) {
        const antP = protoById[selP.antag_id];
        const pA = projectPoint(getProtoCoords3D(selP, mode), w, h);
        const pB = projectPoint(getProtoCoords3D(antP, mode), w, h);
        ctx.save();
        ctx.setLineDash([5, 4]);
        ctx.strokeStyle = isLight ? "#0f172a" : "#f8fafc";
        ctx.lineWidth = 1.6;
        ctx.beginPath();
        ctx.moveTo(pA.sx, pA.sy);
        ctx.lineTo(pB.sx, pB.sy);
        ctx.stroke();
        ctx.restore();
      }

      // 4. Prototypes triés par profondeur
      projectedNodes = PROTOS.map(p => {
        const c3 = getProtoCoords3D(p, mode);
        const pr = projectPoint(c3, w, h);
        return { p, ...pr };
      }).sort((a, b) => a.depth - b.depth);

      projectedNodes.forEach(node => {
        const { p, sx, sy } = node;
        const isVisible = filteredProtoIds.has(p.id_176);
        const isSelected = p.id_176 === selectedProtoId;
        const isAntagSelected = selP && selP.antag_id === p.id_176 && p.id_176 !== selectedProtoId;
        const isHovered = p.id_176 === hoveredProtoId;
        const isGridAnchor = Boolean(p.is_grid_24);

        const baseRadius = Math.max(4.0, Math.min(9.5, 3.8 + Math.sqrt(p.nb_termes) * 0.65));
        const r = isSelected ? baseRadius + 3.8 : (isHovered || isAntagSelected ? baseRadius + 2.2 : (showGrid24 && isGridAnchor ? baseRadius + 1.5 : baseRadius));

        ctx.globalAlpha = isVisible ? (showGrid24 && !isGridAnchor && !isSelected && !isHovered ? 0.42 : 1.0) : 0.10;

        // Halo doré pour les 24 Ancres Canoniques Scherer GRID
        if (showGrid24 && isGridAnchor && isVisible) {
          ctx.save();
          ctx.beginPath();
          ctx.arc(sx, sy, r + 4.2, 0, Math.PI * 2);
          ctx.strokeStyle = "#f59e0b";
          ctx.lineWidth = isSelected ? 2.6 : 1.8;
          ctx.stroke();
          ctx.restore();
        }

        ctx.fillStyle = GROUP_COLORS[p.groupe_geom] || "#64748b";
        ctx.beginPath();
        ctx.arc(sx, sy, r, 0, Math.PI * 2);
        ctx.fill();

        if (isSelected || isAntagSelected || isHovered) {
          ctx.lineWidth = isSelected ? 2.5 : 1.8;
          ctx.strokeStyle = textFill;
          ctx.stroke();
        }

        if (isSelected || isAntagSelected || isHovered || (showGrid24 && isGridAnchor && isVisible) || (isVisible && filteredProtoIds.size <= 36)) {
          ctx.font = (isSelected || (showGrid24 && isGridAnchor)) ? "bold 11.5px sans-serif" : "11px sans-serif";
          ctx.fillStyle = (showGrid24 && isGridAnchor && !isSelected) ? "#fbbf24" : textFill;
          const lblText = (showGrid24 && isGridAnchor && p.grid_label_fr !== p.label_fr)
            ? `${p.label_fr} [GRID: ${p.grid_label_fr}]`
            : p.label_fr;
          ctx.fillText(lblText, sx + r + 5, sy + 4);
        }
      });
      ctx.globalAlpha = 1.0;
    }

    function drawCPMRadar(p) {
      const rCanvas = document.getElementById("cpmRadarCanvas");
      if (!rCanvas) return;
      const rCtx = rCanvas.getContext("2d");
      const w = rCanvas.width, h = rCanvas.height;
      rCtx.clearRect(0, 0, w, h);

      const isLight = document.documentElement.classList.contains("light");
      const webStroke = isLight ? "rgba(100,116,139,0.30)" : "rgba(148,163,184,0.28)";
      const labelColor = isLight ? "#0f172a" : "#e2e8f0";
      const accentColor = GROUP_COLORS[p.groupe_geom] || "#10b981";

      const cx = w * 0.50;
      const cy = h * 0.54;
      const maxR = 60;

      const axes = [
        { label: "Appraisal [33]", val: p.cpm_app || 0.5 },
        { label: "Bodily [27]", val: p.cpm_bod || 0.5 },
        { label: "Expression [33]", val: p.cpm_mot || 0.5 },
        { label: "Action [28]", val: p.cpm_act || 0.5 },
        { label: "Feeling [21]", val: p.cpm_sub || 0.5 }
      ];

      // Toiles concentriques (0.25, 0.50, 0.75, 1.00)
      rCtx.strokeStyle = webStroke;
      rCtx.lineWidth = 1;
      [0.25, 0.5, 0.75, 1.0].forEach(level => {
        rCtx.beginPath();
        axes.forEach((_, i) => {
          const ang = -Math.PI / 2 + (i * 2 * Math.PI) / axes.length;
          const px = cx + Math.cos(ang) * maxR * level;
          const py = cy + Math.sin(ang) * maxR * level;
          if (i === 0) rCtx.moveTo(px, py);
          else rCtx.lineTo(px, py);
        });
        rCtx.closePath();
        rCtx.stroke();
      });

      // Rayons et étiquettes
      rCtx.font = "10px sans-serif";
      rCtx.fillStyle = labelColor;
      axes.forEach((ax, i) => {
        const ang = -Math.PI / 2 + (i * 2 * Math.PI) / axes.length;
        const ex = cx + Math.cos(ang) * maxR;
        const ey = cy + Math.sin(ang) * maxR;
        rCtx.beginPath();
        rCtx.moveTo(cx, cy);
        rCtx.lineTo(ex, ey);
        rCtx.stroke();

        const lx = cx + Math.cos(ang) * (maxR + 16);
        const ly = cy + Math.sin(ang) * (maxR + 13);
        rCtx.textAlign = Math.abs(Math.cos(ang)) < 0.2 ? "center" : (Math.cos(ang) > 0 ? "left" : "right");
        rCtx.fillText(ax.label, lx, ly + 3);
      });

      // Polygone de données CPM
      rCtx.beginPath();
      axes.forEach((ax, i) => {
        const ang = -Math.PI / 2 + (i * 2 * Math.PI) / axes.length;
        const rVal = Math.max(0.05, Math.min(1.0, ax.val)) * maxR;
        const px = cx + Math.cos(ang) * rVal;
        const py = cy + Math.sin(ang) * rVal;
        if (i === 0) rCtx.moveTo(px, py);
        else rCtx.lineTo(px, py);
      });
      rCtx.closePath();
      rCtx.fillStyle = accentColor + "44";
      rCtx.fill();
      rCtx.strokeStyle = accentColor;
      rCtx.lineWidth = 2;
      rCtx.stroke();

      // Sommets du radar
      axes.forEach((ax, i) => {
        const ang = -Math.PI / 2 + (i * 2 * Math.PI) / axes.length;
        const rVal = Math.max(0.05, Math.min(1.0, ax.val)) * maxR;
        const px = cx + Math.cos(ang) * rVal;
        const py = cy + Math.sin(ang) * rVal;
        rCtx.beginPath();
        rCtx.arc(px, py, 3.0, 0, Math.PI * 2);
        rCtx.fillStyle = accentColor;
        rCtx.fill();
      });
    }

    function updateInspector() {
      const p = protoById[selectedProtoId];
      if (!p) return;

      document.getElementById("protoIdBadge").textContent = `#${p.id_176} • ${p.type_geom}`;
      const gridBadge = document.getElementById("protoGridBadge");
      if (p.is_grid_24) {
        gridBadge.classList.remove("hidden");
        gridBadge.textContent = `★ Ancre Scherer GRID : ${p.grid_label_fr}`;
      } else {
        gridBadge.classList.add("hidden");
      }

      const grpBadge = document.getElementById("protoGroupBadge");
      grpBadge.textContent = p.groupe_geom;
      grpBadge.style.backgroundColor = GROUP_COLORS[p.groupe_geom] + "28";
      grpBadge.style.color = GROUP_COLORS[p.groupe_geom];

      document.getElementById("protoTitle").textContent = p.label_fr;
      const mappedP = mapOctahedralL1ToLpSphere(p.X, p.Y, p.Z, lpExponent, 7.0);
      const sxStr = p.X >= 0 ? "+" + p.X : String(p.X);
      const syStr = p.Y >= 0 ? "+" + p.Y : String(p.Y);
      const sxLp = (mappedP.X_lp >= 0 ? "+" : "") + mappedP.X_lp.toFixed(2);
      const syLp = (mappedP.Y_lp >= 0 ? "+" : "") + mappedP.Y_lp.toFixed(2);
      const szLp = mappedP.Z_lp.toFixed(2);
      document.getElementById("protoCoords").textContent =
        `L1 : (${sxStr}, ${syStr}, ${p.Z}) | Lp(p=${lpExponent.toFixed(2)}) : (${sxLp}, ${syLp}, ${szLp}) • B(Z)=${mappedP.norm1.toFixed(0)}`;

      // Radar CPM & Jauge Ratio_Z
      drawCPMRadar(p);

      const ratioZ = p.ratio_z || 1.0;
      document.getElementById("cpmRatioZVal").textContent = ratioZ.toFixed(4);

      const zRegBadge = document.getElementById("zRegimeBadge");
      let zRegLabel = "Z_pos (Cognitivo-Normatif)";
      let zRegColor = "bg-emerald-500/20 text-emerald-400 border border-emerald-500/40";
      if (p.Z === 0) {
        zRegLabel = "Z_0 (Origine Basale)";
        zRegColor = "bg-slate-500/20 text-slate-300 border border-slate-500/40";
      } else if (ratioZ < 0.96) {
        zRegLabel = "Z_neg (Somatique / Réactif)";
        zRegColor = "bg-rose-500/20 text-rose-400 border border-rose-500/40";
      } else if (ratioZ <= 1.04) {
        zRegLabel = "Z_7 (Équilibre Homéostatique)";
        zRegColor = "bg-amber-500/20 text-amber-400 border border-amber-500/40";
      }
      zRegBadge.className = `px-2 py-0.5 rounded text-[10px] font-mono font-bold ${zRegColor}`;
      zRegBadge.textContent = zRegLabel;

      // Position du curseur sur la jauge (Ratio_Z de 0.2 à 2.2 centré sur 1.0 -> 50%)
      const pct = Math.max(4, Math.min(96, 50 + Math.tanh(1.25 * Math.log(Math.max(0.1, ratioZ))) * 46));
      document.getElementById("zRatioMarker").style.left = `${pct}%`;

      const copingVal = p.grid_p || 0.0;
      const copingEl = document.getElementById("cpmCopingBadge");
      if (copingVal > 0.02) {
        copingEl.textContent = `Agie / Confrontation (+${copingVal.toFixed(2)})`;
        copingEl.className = "font-mono font-semibold text-emerald-400";
      } else if (copingVal < -0.02) {
        copingEl.textContent = `Réflexive / Subie (${copingVal.toFixed(2)})`;
        copingEl.className = "font-mono font-semibold text-sky-400";
      } else {
        copingEl.textContent = `Suspendue (${copingVal.toFixed(2)})`;
        copingEl.className = "font-mono font-semibold text-amber-400";
      }

      document.getElementById("cpmFactors4D").textContent =
        `V=${p.grid_v.toFixed(2)} P=${p.grid_p.toFixed(2)} A=${p.grid_a.toFixed(2)} N=${p.grid_n.toFixed(2)}`;

      const barsContainer = document.getElementById("cpmBarsList");
      const items5 = [
        ["Appraisal (Norms)", p.cpm_app, p.cpm_norms],
        ["Bodily Symptoms", p.cpm_bod, null],
        ["Motor Expression", p.cpm_mot, null],
        ["Action Tendencies", p.cpm_act, null],
        ["Feeling (Regul.)", p.cpm_sub, p.cpm_reg]
      ];
      barsContainer.innerHTML = items5.map(([lbl, v, subV]) => {
        const subTxt = subV !== null ? ` (ss=${subV.toFixed(2)})` : "";
        return `<div class="flex justify-between"><span>${lbl}:</span><span class="font-semibold">${v.toFixed(2)}${subTxt}</span></div>`;
      }).join("");

      const antP = protoById[p.antag_id];
      const jumpBtn = document.getElementById("jumpAntagBtn");
      jumpBtn.textContent = `${p.antag_label} (#${p.antag_id})`;
      jumpBtn.onclick = () => {
        if (p.antag_id > 0) {
          selectedProtoId = p.antag_id;
          updateInspector();
          drawScene();
        }
      };

      let symRule = "Réflexion contralatérale (-Y, -X, Z)";
      if (p.rayon_L1 === 0) symRule = "Pivot central auto-dual (0, 0, Z)";
      else if (p.type_geom === "Axiale" || p.type_geom === "Diagonale") symRule = "Opposition centrale (-X, -Y, Z)";

      if (antP) {
        document.getElementById("protoAntagCoords").textContent =
          `(${antP.X >= 0 ? "+" + antP.X : antP.X}, ${antP.Y >= 0 ? "+" + antP.Y : antP.Y}, ${antP.Z}) • ${symRule}`;
      }

      document.getElementById("protoMeanVAD").textContent =
        `V=${p.mean_v.toFixed(2)}, A=${p.mean_a.toFixed(2)}, D=${p.mean_d.toFixed(2)} | d=${p.mean_dist.toFixed(3)}`;

      const top5Container = document.getElementById("protoTop5");
      top5Container.innerHTML = "";
      p.top5.split(", ").forEach(w => {
        const span = document.createElement("span");
        span.className = "px-2 py-0.5 rounded-md bg-[var(--content)] border border-[var(--border)] font-medium";
        span.textContent = w;
        top5Container.appendChild(span);
      });

      const sVal = document.getElementById("stratumFilter") ? document.getElementById("stratumFilter").value : "ALL";
      const list = (affectsByProto[p.id_176] || []).filter(a => sVal === "ALL" || String(a.srk || "") === sVal);
      document.getElementById("anchoredCount").textContent = String(list.length);
      const listContainer = document.getElementById("anchoredList");
      listContainer.innerHTML = "";

      list.forEach((a, idx) => {
        const row = document.createElement("div");
        const isHighlighted = matchedAffectTerm && a.fr.toLowerCase().includes(matchedAffectTerm);
        row.className = `px-2.5 py-1.5 flex items-center justify-between gap-2 ${isHighlighted ? "bg-[var(--primary)]/15 font-semibold" : ""}`;
        const posBadge = a.pos ? `<span class="px-1 py-0.2 rounded text-[10px] font-mono bg-emerald-500/15 text-emerald-400 border border-emerald-500/30 ml-1">${a.pos}</span>` : "";
        const stratBadge = a.srk ? `<span class="px-1 py-0.2 rounded text-[10px] font-mono bg-sky-500/15 text-sky-400 border border-sky-500/30 ml-1">S${a.srk} • Rz=${(a.rz || 1.0).toFixed(2)}</span>` : "";
        const srcBadge = a.src ? `<span class="px-1 py-0.2 rounded text-[10px] bg-[var(--card)] border border-[var(--border)] ml-1">${a.src}</span>` : "";
        const domInfo = a.gdom ? ` • ${a.gdom}` : "";
        const octInfo = a.oct ? ` • ${a.oct}` : "";
        row.innerHTML = `
          <div class="truncate" title="${a.fr} (${a.cat}${domInfo}${octInfo})">
            <span class="text-[var(--muted-foreground)] mr-1">${idx + 1}.</span>
            <span class="font-medium">${a.fr}</span>
            ${posBadge}${stratBadge}
            <span class="text-[var(--muted-foreground)] ml-1 text-[10px]">${a.gdom || a.cat}</span>
            ${srcBadge}
          </div>
          <div class="font-mono text-[11px] text-[var(--muted-foreground)] shrink-0">
            ${a.oct || ""} • V=${a.v >= 0 ? "+" : ""}${a.v.toFixed(2)}
          </div>
        `;
        listContainer.appendChild(row);
      });
    }

    function updateFilters() {
      const zVal = document.getElementById("zFilter").value;
      const gVal = document.getElementById("groupFilter").value;
      const sVal = document.getElementById("stratumFilter") ? document.getElementById("stratumFilter").value : "ALL";
      const q = document.getElementById("searchInput").value.trim().toLowerCase();
      matchedAffectTerm = q || null;

      filteredProtoIds.clear();
      let firstMatchId = null;

      PROTOS.forEach(p => {
        if (zVal === "HEMI_PLUS" && p.Z > 7) return;
        if (zVal === "HEMI_MINUS" && p.Z < 7) return;
        if (zVal !== "ALL" && zVal !== "HEMI_PLUS" && zVal !== "HEMI_MINUS" && String(p.Z) !== zVal) return;
        if (gVal !== "ALL") {
          const allowedGrps = GROUP_EQUIV[gVal] || [gVal];
          if (!allowedGrps.includes(p.groupe_geom)) return;
        }
        const pAffects = (affectsByProto[p.id_176] || []).filter(a => sVal === "ALL" || String(a.srk || "") === sVal);
        if (sVal !== "ALL" && pAffects.length === 0) return;

        if (q) {
          const matchProto = p.label_fr.toLowerCase().includes(q) || (p.grid_label_fr && p.grid_label_fr.toLowerCase().includes(q));
          const matchAff = pAffects.some(a => a.fr.toLowerCase().includes(q) || (a.gdom && a.gdom.toLowerCase().includes(q)));
          if (!matchProto && !matchAff) return;
          if ((matchProto || matchAff) && firstMatchId === null) firstMatchId = p.id_176;
        }
        filteredProtoIds.add(p.id_176);
        if (firstMatchId === null) firstMatchId = p.id_176;
      });

      if (q && firstMatchId !== null) {
        selectedProtoId = firstMatchId;
      }

      document.getElementById("visibleCountBadge").textContent =
        `${filteredProtoIds.size} / ${PROTOS.length} pôles affichés`;
      updateInspector();
      drawScene();
    }

    // Interactions souris (rotation, zoom, clic)
    let isDragging = false;
    let dragStartX = 0, dragStartY = 0;
    let movedDuringDrag = false;

    canvas.addEventListener("mousedown", e => {
      isDragging = true;
      movedDuringDrag = false;
      dragStartX = e.clientX;
      dragStartY = e.clientY;
    });

    window.addEventListener("mousemove", e => {
      const rect = canvas.getBoundingClientRect();
      if (isDragging) {
        const dx = e.clientX - dragStartX;
        const dy = e.clientY - dragStartY;
        if (Math.abs(dx) + Math.abs(dy) > 3) movedDuringDrag = true;
        rotYaw += dx * 0.0075;
        rotPitch = Math.max(-1.45, Math.min(1.45, rotPitch + dy * 0.0075));
        dragStartX = e.clientX;
        dragStartY = e.clientY;
        drawScene();
        return;
      }

      if (e.target === canvas) {
        const mx = e.clientX - rect.left;
        const my = e.clientY - rect.top;
        let found = null;
        for (let i = projectedNodes.length - 1; i >= 0; i--) {
          const n = projectedNodes[i];
          if (!filteredProtoIds.has(n.p.id_176)) continue;
          if (Math.hypot(mx - n.sx, my - n.sy) <= 10) {
            found = n.p.id_176;
            break;
          }
        }
        if (found !== hoveredProtoId) {
          hoveredProtoId = found;
          drawScene();
        }
      }
    });

    window.addEventListener("mouseup", e => {
      if (isDragging && !movedDuringDrag && e.target === canvas && hoveredProtoId !== null) {
        selectedProtoId = hoveredProtoId;
        updateInspector();
        drawScene();
      }
      isDragging = false;
    });

    canvas.addEventListener("wheel", e => {
      e.preventDefault();
      zoom = Math.max(0.45, Math.min(2.6, zoom * (e.deltaY < 0 ? 1.09 : 0.92)));
      drawScene();
    }, { passive: false });

    document.getElementById("geomMode").addEventListener("change", () => {
      if (document.getElementById("geomMode").value === "plan") {
        rotYaw = 0.0;
        rotPitch = 1.57;
      } else {
        rotYaw = -0.62;
        rotPitch = 0.36;
      }
      drawScene();
    });
    document.getElementById("zFilter").addEventListener("change", updateFilters);
    document.getElementById("groupFilter").addEventListener("change", updateFilters);
    if (document.getElementById("stratumFilter")) {
      document.getElementById("stratumFilter").addEventListener("change", updateFilters);
    }
    document.getElementById("searchInput").addEventListener("input", updateFilters);
    document.getElementById("showGrid24").addEventListener("change", drawScene);
    document.getElementById("showAffects").addEventListener("change", drawScene);
    document.getElementById("showWireframe").addEventListener("change", drawScene);
    document.getElementById("resetCamBtn").addEventListener("click", () => {
      if (document.getElementById("geomMode").value === "plan") {
        rotYaw = 0.0;
        rotPitch = 1.57;
      } else {
        rotYaw = -0.62;
        rotPitch = 0.36;
      }
      zoom = 1.05;
      drawScene();
    });

    // Gestion du curseur de morphing temps réel Diamant (L1, p=1) <-> Sphère (L2, p=2)
    let morphAnimFrame = null;
    function setLpMorphValue(val) {
      lpExponent = Math.max(1.0, Math.min(2.0, Number(val) || 1.0));
      const slider = document.getElementById("lpMorphSlider");
      if (slider) slider.value = lpExponent.toFixed(2);
      updateLpMetricsHeader();
      updateInspector();
      drawScene();
    }

    function animateLpMorphTo(targetP) {
      if (morphAnimFrame) cancelAnimationFrame(morphAnimFrame);
      const startP = lpExponent;
      const diff = targetP - startP;
      if (Math.abs(diff) < 0.005) {
        setLpMorphValue(targetP);
        return;
      }
      const durationMs = 260;
      const startTime = performance.now();
      function step(now) {
        const t = Math.min(1.0, (now - startTime) / durationMs);
        const ease = t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;
        setLpMorphValue(startP + diff * ease);
        if (t < 1.0) {
          morphAnimFrame = requestAnimationFrame(step);
        } else {
          morphAnimFrame = null;
        }
      }
      morphAnimFrame = requestAnimationFrame(step);
    }

    const lpSliderEl = document.getElementById("lpMorphSlider");
    if (lpSliderEl) {
      lpSliderEl.addEventListener("input", e => {
        if (morphAnimFrame) {
          cancelAnimationFrame(morphAnimFrame);
          morphAnimFrame = null;
        }
        setLpMorphValue(parseFloat(e.target.value));
      });
    }
    const btnL1 = document.getElementById("btnPresetL1");
    if (btnL1) btnL1.addEventListener("click", () => animateLpMorphTo(1.00));
    const btnP15 = document.getElementById("btnPresetP15");
    if (btnP15) btnP15.addEventListener("click", () => animateLpMorphTo(1.50));
    const btnL2 = document.getElementById("btnPresetL2");
    if (btnL2) btnL2.addEventListener("click", () => animateLpMorphTo(2.00));

    updateLpMetricsHeader();
    updateInspector();
    setTimeout(resizeCanvas, 20);
  </script>
</body>
</html>
"""


def main():
    import numpy as np

    df_stats = pd.read_csv("CARTOGRAFFECT_176_Stats_Synthese.tsv", sep="\t", encoding="utf-8")
    df_303 = pd.read_csv("CARTOGRAFFECT_Diamant_303_Stats_Synthese.tsv", sep="\t", encoding="utf-8")
    df_lex303 = pd.read_csv("CARTOGRAFFECT_Diamant_303_Lexique_Complet.tsv", sep="\t", encoding="utf-8")
    open_3d_path = "CARTOGRAFFECT_OpenData_CNRS_Lexique_GLAWI_3D.tsv"
    use_open_3d = os.path.exists(open_3d_path)
    if use_open_3d:
        df_lex = pd.read_csv(open_3d_path, sep="\t", encoding="utf-8")
    else:
        df_lex = pd.read_csv("CARTOGRAFFECT_Affectif_Purifie_Z_Plus.tsv", sep="\t", encoding="utf-8")
    # Phase 1 (v3.0.0-dev) : les tables synthétiques GRID-24 / CPM-142 ont été archivées dans archive/deprecated_synthetic_v2/
    stats176_by_id = {int(r.id_176): r for r in df_stats.itertuples()}
    grid24_by_id = {}
    cpm176_by_id = {}

    protos_data = []
    dual_303_rows = []
    for r303 in df_303.itertuples():
        pid = int(r303.id_303)
        h3d = int(r303.h_diamant_3d)
        z_sphere_idx = 7 + h3d  # 0..6 (Z+), 7 (Équateur), 8..14 (Z-)
        z_signe = int(r303.Z_signe)
        hemi = str(r303.hemisphere)
        x_val = int(r303.X)
        y_val = int(r303.Y)
        z_rel = 2.0 * float(h3d)
        norm1 = abs(x_val) + abs(y_val) + abs(z_rel)
        norm2 = float(np.sqrt(x_val**2 + y_val**2 + z_rel**2))
        scale2 = (norm1 / norm2) if norm2 > 1e-9 else 1.0
        x_l2 = round(x_val * scale2, 4)
        y_l2 = round(y_val * scale2, 4)
        z_rel_l2 = round(z_rel * scale2, 4)
        z_l2 = round(7.0 + 0.5 * z_rel_l2, 4)

        hom_id = int(getattr(r303, "homologue_id_303", pid))
        cpm_ref_id = pid if pid <= 176 else (hom_id if 1 <= hom_id <= 176 else 1)
        cpm_row = cpm176_by_id.get(cpm_ref_id)

        dual_303_rows.append({
            "id_303": pid,
            "hemisphere": hemi,
            "label_fr": str(r303.label_fr),
            "groupe_geom": str(r303.groupe_geom),
            "type_geom": str(r303.type_geom),
            "X_L1": x_val,
            "Y_L1": y_val,
            "Z_signe": z_signe,
            "h_diamant_3d": h3d,
            "Z_sphere_index": z_sphere_idx,
            "rayon_L1": int(r303.rayon_L1),
            "budget_radial_3D_L1": int(norm1),
            "X_L2": x_l2,
            "Y_L2": y_l2,
            "Z_rel_L2": z_rel_l2,
            "Z_L2": z_l2,
            "contrepoids_id_303": int(r303.contrepoids_id_303),
            "contrepoids_label": str(r303.contrepoids_label),
            "homologue_id_303": hom_id,
            "homologue_label": str(r303.homologue_label),
        })

        protos_data.append({
            "id_176": pid,
            "label_fr": str(r303.label_fr),
            "hemisphere": hemi,
            "Z_signe": z_signe,
            "X": x_val,
            "Y": y_val,
            "Z": z_sphere_idx,
            "rayon_L1": int(r303.rayon_L1),
            "type_geom": str(r303.type_geom),
            "groupe_geom": str(r303.groupe_geom),
            "nb_termes": int(r303.effectif_termes),
            "mean_v": float(r303.valence_moyenne),
            "mean_a": float(r303.arousal_moyen),
            "mean_d": float(r303.dominance_moyenne),
            "mean_dist": float(r303.distance_L1_moyenne),
            "top5": str(r303.top5_mots_fideles),
            "antag_label": str(r303.contrepoids_label),
            "antag_id": int(r303.contrepoids_id_303),
            "hom_label": str(r303.homologue_label),
            "hom_id": hom_id,
            "is_grid_24": pid in grid24_by_id,
            "grid_label_fr": grid24_by_id.get(pid, ""),
            "grid_v": float(cpm_row.GRID_Valence) if cpm_row is not None else float(r303.valence_moyenne),
            "grid_p": float(cpm_row.GRID_Power_Coping) if cpm_row is not None else float(r303.dominance_moyenne),
            "grid_a": float(cpm_row.GRID_Arousal) if cpm_row is not None else float(r303.arousal_moyen),
            "grid_n": float(cpm_row.GRID_Novelty) if cpm_row is not None else 0.0,
            "cpm_app": float(cpm_row.Score_Appraisal) if cpm_row is not None else 0.5,
            "cpm_norms": float(cpm_row.Score_Appraisal_Norms) if cpm_row is not None else 0.5,
            "cpm_bod": float(cpm_row.Score_Bodily_Symptoms) if cpm_row is not None else 0.5,
            "cpm_mot": float(cpm_row.Score_Motor_Expression) if cpm_row is not None else 0.5,
            "cpm_act": float(cpm_row.Score_Action_Tendencies) if cpm_row is not None else 0.5,
            "cpm_sub": float(cpm_row.Score_Subjective_Feeling) if cpm_row is not None else 0.5,
            "cpm_reg": float(cpm_row.Score_Subjective_Regulation) if cpm_row is not None else 0.5,
            "ratio_z": float(cpm_row.Ratio_Z_CPM) if cpm_row is not None else (1.45 if pid > 176 else 1.0),
        })

    pd.DataFrame(dual_303_rows).to_csv(
        "CARTOGRAFFECT_303_Dual_L1_L2_Sphere_Complete.tsv",
        sep="\t",
        index=False,
        encoding="utf-8",
    )

    homologue_by_176 = {
        int(r.id_303): int(r.homologue_id_303)
        for r in df_303.itertuples()
        if int(r.id_303) <= 176 and int(r.homologue_id_303) > 176
    }
    proto_z_by_id = {p["id_176"]: p["Z"] for p in protos_data}

    affects_data = []
    seen_pole_term = set()
    if use_open_3d:
        for r in df_lex.sort_values("distance_L1_3d").itertuples():
            base_id = int(r.id176)
            srk = int(r.stratum_rank)
            target_id = homologue_by_176.get(base_id, base_id) if (srk >= 4 and base_id in homologue_by_176) else base_id
            key = (target_id, str(r.lemme_fr).strip().lower())
            seen_pole_term.add(key)
            z_target = float(proto_z_by_id.get(target_id, float(r.Z_proj_3d)))
            affects_data.append({
                "id": target_id,
                "fr": str(r.lemme_fr),
                "pos": str(r.pos_cnrs_lexique),
                "gdom": str(r.glawi_domaine_cnrs),
                "srk": srk,
                "rz": round(float(r.Ratio_Z), 3),
                "oct": str(r.octant_code),
                "cat": str(r.domaine_semantique),
                "src": str(r.open_data_badge),
                "cls": str(r.dima_classe),
                "v": round(float(r.valence), 3),
                "x": round(float(r.X_proj_3d), 3),
                "y": round(float(r.Y_proj_3d), 3),
                "z": round(z_target, 2),
                "d": round(float(r.distance_L1_3d), 4),
            })

    # Ajout des termes axiologiques Z- de CARTOGRAFFECT_Diamant_303_Lexique_Complet.tsv
    for r in df_lex303.itertuples():
        pid = int(r.id_303_ancre)
        if pid <= 176:
            continue
        t_fr = str(r.terme_fr).strip()
        if (pid, t_fr.lower()) in seen_pole_term:
            continue
        seen_pole_term.add((pid, t_fr.lower()))
        z_target = float(proto_z_by_id.get(pid, 10.0))
        affects_data.append({
            "id": pid,
            "fr": t_fr,
            "pos": "NOM/ADJ",
            "gdom": "Axiologie / Éthique (Z⁻)",
            "srk": 5,
            "rz": 1.65,
            "oct": "Z⁻",
            "cat": str(r.categorie_semantique),
            "src": str(r.source_lexicale),
            "cls": str(getattr(r, "triade_statut_z_minus", "-")),
            "v": round(float(r.valence), 3),
            "x": round(float(getattr(r, "X_proj_unit", getattr(r, "X_proj", 0.0))), 3),
            "y": round(float(getattr(r, "Y_proj_unit", getattr(r, "Y_proj", 0.0))), 3),
            "z": round(z_target, 2),
            "d": round(float(getattr(r, "distance_L1_cible", getattr(r, "distance_L1", 0.0))), 4),
        })

    n_affects_fmt = f"{len(affects_data):,}".replace(",", " ")
    html_out = (
        HTML_TEMPLATE
        .replace("1 991", n_affects_fmt)
        .replace("176 prototypes affichés", "303 pôles affichés (Sphère Complète Z⁺ + Z⁻)")
        .replace("176 prototypes (8 couronnes Z₀–Z₇)", "303 pôles sur 2 hémisphères (127 Affectifs Z⁺ + 49 Équateur Z₇ + 127 Axiologiques Z⁻)")
        .replace("176 pôles (Z₀–Z₇)", "303 pôles (Sphère Complète Z⁺/Z⁻)")
        .replace("__PROTOS_JSON__", json.dumps(protos_data, ensure_ascii=False))
        .replace("__AFFECTS_JSON__", json.dumps(affects_data, ensure_ascii=False))
    )

    out_targets = [
        "CARTOGRAFFECT_Interactive_3D_Explorer.html",
    ]
    for target in out_targets:
        parent = os.path.dirname(target)
        if not parent or os.path.exists(parent):
            with open(target, "w", encoding="utf-8") as f:
                f.write(html_out)
    print(f"Explorateur interactif Sphère Complète 303 pôles généré : {out_targets[0]} ({len(protos_data)} pôles, {len(affects_data)} termes)")


if __name__ == "__main__":
    main()
