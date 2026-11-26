# Archive — Deprecated Synthetic Validation Artifacts (v2 → v3.0.0-dev Phase 1)

**Statut :** ARCHIVÉ / DÉPRÉCIÉ — **ZÉRO VALIDATION EMPIRIQUE (V3 = 0)**  
**Date d'archivage :** 2026-11-25 (Phase 1 — Purges d'intégrité probatoire, branche `v3.0.0-dev`)

## Motif de dépréciation

Les scripts, tables dérivées, rapports et preuves Lean 4 archivés dans ce dossier ont été retirés du périmètre actif de CARTOGRAFFECT® lors de la Phase 1 de refonte `v3.0.0-dev` pour les raisons méthodologiques suivantes :

1. **Circularité synthétique du pipeline GRID-24 / CPM-142 (`extensions/lexicon/src/grid_cpm_integration.py`) :**
   - Les profils CPM-142 des 24 ancres étaient synthétisés / calibrés sur `Z` puis projetés avec réinjection convexe explicite des coordonnées cibles (`0.55 * x_raw + 0.45 * u_s`, `0.55 * y_raw + 0.45 * v_s`, L735–L740).
   - Les corrélations CCA (`rho_1 = 0.9502`, `0.9309`, `0.9104`) et congruences de Tucker/Procrustes dérivées (`validate_grid_cartograffect_stats.py`, `CARTOGRAFFECT_GRID_CPM_Validation_Stats.json`, `CARTOGRAFFECT_L1_vs_L2_Benchmark_Stats.json`, `docs/validation_scherer_grid.md`, `tables/table_validation_grid_apa7.tex`) ne constituent donc **pas** une validation psychométrique externe indépendante.
2. **Blanchiment formel retiré (`extensions/lexicon/lean/SchererGRID.lean`) :**
   - Ce module embarquait des constantes statistiques issues de Python (`cca_rho1_grid24 := 9502`, etc.) certifiées par `decide` (`empirical_thresholds_certified`) ainsi que des profils CPM synthétiques codés en dur.
   - Conformément au garde-fou *Zéro blanchiment formel* de la Phase 1 (`v3.0.0-dev`), ce module a été retiré du build actif et archivé ici à des fins de traçabilité historique uniquement.
3. **Scripts et sorties dépendants :**
   - `build_full_cartograffect_dictionary.py` et `generate_publication_report.py` importaient ou publiaient directement les sorties de `grid_cpm_integration.py`.
   - Le rendu statique `extensions/lexicon/site/` contenait la page générée `validation_scherer_grid/` et son index de recherche incluant les métriques dépréciées.

Ces artefacts sont conservés exclusivement pour l'historique d'audit ; ils ne doivent plus être cités comme preuves empiriques ou psychométriques externes.
