# Changelog

All notable changes to the **CARTOGRAFFECT®** Research Compendium are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.1] - 2026-11-21

### Changed
- **Honesty & AI Transparency (`docs/01-Article_Cartograffect.md`, `README.md`, `data/site-payload.json`)**: explicit 3-point generative AI disclosure affirming full authorial ownership of the psychological/taxonomic model, AI technical assistance (writing, showcase website, translation, and exploratory formal-method transposition across Lean 4, Rocq, Agda, Dafny, Z3, TLA+), lack of manual line-by-line verification of generated formal code by a clinical psychologist who is not a formal mathematician, reliance on mechanical prover compilation and automated tests, and open GitHub publication for independent specialist audit.
- **Editorial & Conceptual Alignment**: preserved conceptual psychological focus on Figure 1 and Data Availability synchronized to `v2.0.1`, unified APA 7 bibliography (`72` continuous A–Z entries without legacy `49+` web migration counters), and added structured `ai_disclosure` payload block alongside stricter guardrails in `scripts/export_site_payload.py`, `scripts/check_consistency.py`, and `scripts/test_check_consistency.py`.
- **Showcase Web & Independent Research Notice Patch (`manuelcabelguen-jpg.github.io`)**: restored 100% native wheel scrolling across all pages (including 3D taxonomy camera zoom bounds), repaired `FR/EN` i18n switching with complete translation coverage and `sw.js` `2.0.1` cache invalidation, verified WCAG 2.1 opaque dropdown styling, aligned Figure 1 cross-references, and clarified total intellectual independence & non-clinical research scope notice in `mentions-legales.html`.

### Verified
- **Strate 0 Hexa-Prover Core untouched**: zero modifications inside `Cartograffect/`, `rocq/`, `agda/`, `dafny/`, `smt/`, or `tla/` relative to `v2.0.0`.

## [2.0.0] - 2026-11-21

### Added
- **Stratified Research Compendium governance & Single Source of Truth (`VERSION`, `CHANGELOG.md`, `.zenodo.json`, `manifest.json`, `CITATION.cff`, `docs/CONVERGENCE_MATRIX.md`)**: unified release metadata aligning Strate 0 (formal kernel + manuscript) and Strate 1 (exploratory satellites), linking Zenodo software DOI (`10.5281/zenodo.23833938`), Zenodo preprint DOI (`10.5281/zenodo.24022795`), OSF (`https://osf.io/z89sg`), and CIPO/OPIC copyright registration No. `1233199`.
- **Epistemic boundary contracts**: explicit subordinate charters in [`extensions/lexicon/EPISTEMIC_STATUS.md`](extensions/lexicon/EPISTEMIC_STATUS.md) and [`extensions/in_silico/EPISTEMIC_STATUS.md`](extensions/in_silico/EPISTEMIC_STATUS.md).
- **Predictive Monte-Carlo extension for P4 and P5 (`extensions/in_silico/`)**: added P4 (lexicographic priority of `sgn(X_t)` over `Δ∇A_t` vs. Joffily & Coricelli, 2013) and P5 (pragmatic controllability mediation `p_hat_ctrl` of `Peur (-2,0,2) -> Colère (-1,1,2)` vs `Dégoût (-1,-1,2)`) in [`extensions/in_silico/experiments/01_falsifiable_predictions.py`](extensions/in_silico/experiments/01_falsifiable_predictions.py) and [`extensions/in_silico/tests/test_recovery_and_experiments.py`](extensions/in_silico/tests/test_recovery_and_experiments.py) using the unmodified `pymdp` generative engine with honestly documented parametric boundaries.

### Changed
- **Manuscript unification to `v2.0.0` (`docs/01-Article_Cartograffect.md`)**: applied arbitrations **A3** (nuanced distinction in Discussion between formal 2D fixed-radius refutation in `EmotionWheelsChallenge.lean` and preliminary psychometric GRID-24 triangulation without importing 16K interpolation), **A4-Sanctuaire** (kept all `in_silico` quantitative metrics out of theoretical sections, reserving them for a dedicated companion paper referenced in Data Availability), and **A5** (preserved `Z in {0,...,7}` axiomatics matching the 113 theorems, with one cautious opening in Conclusion pointing to the compartmentalized negative-`Z` exploration in `extensions/lexicon/`).
- **Lexical downward alignment (`extensions/lexicon/`)**: applied arbitration **A1** by restoring Strate 0 canonical names `Langueur` at `(0, -6, 4)` and `Rancœur` at `(-6, 4, 6)` across `01b_prepare_diamond_z_minus.py`, `lean/SchererGRID.lean`, `src/grid_cpm_integration.py`, and derived TSV/JSON artifacts, preserving `Solitude (SADNESS)` and `Irritation (IRRITATION)` strictly in the `grid_anchor_alias` metadata column.
- **SPDX Dual-Licensing & Hybrid-File Separation Clause (`NOTICE`, `README.md`, `CITATION.cff`, `extensions/in_silico/pyproject.toml`)**: unified under `AGPL-3.0-or-later AND CC-BY-NC-SA-4.0`, clarifying that code and formal proof structures fall under GNU AGPLv3 while theoretical architecture, manuscript content, and the 176-state taxonomy fall exclusively under CC BY-NC-SA 4.0.
- **Portable relative POSIX outputs & zero-leak hygiene**: removed machine-specific paths (`figure_path` normalized to `results/fig1_falsifiable_predictions.png`), removed duplicate `extensions/lexicon/CITATION.cff` and unused artifact copies.

### Verified
- **Strate 0 Hexa-Prover Core intact**: unchanged `Cartograffect/*.lean` (`11/11` `lake build` targets, `113/113` theorems, `0 sorry`, `0` custom axioms) alongside Rocq 9.0, Agda 2.9.0, Dafny 4.11.0, SMT-LIB/Z3 5.3.3, and TLA+/TLC 2.19.

## [1.0.1] - 2026-10-31

### Added
- Extended formal core to `PredictiveCircuit.lean`, `AffectiveDynamics.lean`, `AuditTests.lean`, and isomorphic Python engine `python/cartograffect_predictive_engine.py` (`113` audited theorems across 6 formal provers).
- Initial root `CITATION.cff` and Zenodo release identifier (`10.5281/zenodo.23833938`).

## [1.0.0] - 2026-10-27

### Added
- Initial Lean 4 formalization of the CARTOGRAFFECT 176-state L1 affective taxonomy, core 17 founding theorems, and dual licensing (`AGPL-3.0-or-later` / `CC BY-NC-SA 4.0`).

[2.0.1]: https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/compare/v1.0.1...v2.0.0
[1.0.1]: https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/manuelcabelguen-jpg/CARTOGRAFFECT/releases/tag/v1.0.0
