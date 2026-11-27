# SUBMISSION_STRATEGY_V3 — Stratégie Éditoriale Opérationnelle (CARTOGRAFFECT v3.0.0)

**Version de référence :** `3.0.0` (branche `v3.0.0-dev`, alignée sur `DECISIONS_V3.md` et le commit `66d9a0d`)  
**Auteur :** Manuel Cabelguen, Ph. D. (`manuelcabelguen@gmail.com`)  
**Statut épistémique réel :** **`V3 = 0` donnée humaine collectée** · Strate 0 certifiée mécaniquement en Lean 4 (**8 modules normatifs, 148 théorèmes substantiels / 169 déclarations exportées, 8 théorèmes piliers, 0 `sorryAx`, 0 `native_decide`**) + identifiabilité synthétique résolue (`synthetic_identifiability_check` : 5 paramètres orthogonalisés, $\min r = 0{,}926$, $\max |r_{\text{off-diag}}| = 0{,}174 < 0{,}35$).  
**Identifiants pérennes :** Zenodo Article [`10.5281/zenodo.24022795`](https://doi.org/10.5281/zenodo.24022795) · Zenodo Code [`10.5281/zenodo.23833938`](https://doi.org/10.5281/zenodo.23833938) · OSF [`https://osf.io/z89sg`](https://osf.io/z89sg) · CIPO / OPIC `1233199`  
**Licences :** Code & preuves Lean 4 sous `AGPL-3.0-or-later` · Manuscrit, protocoles & documentation sous `CC-BY-4.0`.

---

## 1. Principe Directeur : Deux Voies Distinctes, Zéro Surestimation Épistémique

Parce que CARTOGRAFFECT `v3.0.0` dispose aujourd'hui d'un noyau formel mécaniquement vérifié (`V2` complet) mais d'**aucune donnée humaine empirique (`V3 = 0`)**, tenter de soumettre le compendium comme un article empirique ou clinique entraînerait un rejet éditorial immédiat (*desk-reject*). La stratégie optimale scinde proprement le programme en **deux voies éditoriales complémentaires, soumissibles en parallèle sans chevauchement ni auto-plagiat** :

| Axe | Voie 1 — Article Théorique / Perspective (`V3 = 0`) | Voie 2 — Stage 1 Registered Report (`V2 → V3`) |
|:---|:---|:---|
| **Document source** | Adaptation anglaise sobre de [`docs/01-Article_Cartograffect.md`](docs/01-Article_Cartograffect.md) (`66d9a0d`) | [`protocols/STAGE1_REGISTERED_REPORT_STUDY1.md`](protocols/STAGE1_REGISTERED_REPORT_STUDY1.md) + [`protocols/study1_analysis_pipeline.py`](protocols/study1_analysis_pipeline.py) |
| **Matériel compagnon** | [`FORMAL_AUDIT_PACK.md`](FORMAL_AUDIT_PACK.md) (8 théorèmes piliers + audit `#print axioms`) & attestation humaine indépendante | [`extensions/in_silico/results/v3_identifiability_report.json`](extensions/in_silico/results/v3_identifiability_report.json) (`synthetic_identifiability_check`) & dry-run pilote OSF |
| **Revues cibles** | *Psychological Review* · *Behavioral and Brain Sciences* · *Emotion Review* · *Neuroscience & Biobehavioral Reviews* | *Nature Human Behaviour* (Registered Reports) · *Royal Society Open Science* (Registered Reports / PCI-RR) |
| **Ce qui est revendiqué** | Architecture fonctionnelle intégrative, cohérence formelle certifiée Lean 4, 5 prédictions falsifiables (P1–P5) sans clause d'immunisation | Protocole confirmatoire pré-enregistré ($N \ge 600$, FR + EN) à 3 tests sévères (1A, 1B, 1C) avec critères numériques d'abandon a priori |
| **Ce qui est exclu** | Toute métrique *in silico* dans le corps théorique (garde A4-Sanctuaire), toute revendication clinique/DSM-5, toute grille `Z = 6..7` | Toute présentation du `synthetic_identifiability_check` ou du `pilot_pipeline_dry_run` comme preuve empirique humaine |

---

## 2. Voie 1 — Article Théorique / Perspective (`V3 = 0` Donnée Humaine)

### 2.1. Préparation de la version anglaise sobre (`docs/01-Article_Cartograffect.md`, `66d9a0d`)
La traduction/adaptation anglaise doit conserver intégralement les arbitrages verrouillés de [`DECISIONS_V3.md`](DECISIONS_V3.md) :
- **Terminologie exacte :** *Expectation* (`X`, epistemic revisability), *Control* (`Y`, strict instrumental controllability, Option 1A), autonomous allostatic mobilization channel (`A ≥ 0`), stepwise vertical depth `Z ∈ [0, 5]` with canonical discretization restricted to `Z ∈ {0, 1, 2}` and unique descending shortcut `2 → 0` (Option 2a), asymmetric axial instability restricted to negative Charge poles `Fear` and `Sadness` (Option 3b), Rolls' exact $2 \times 2$ bijection bounded to `Z = 2` (`Rew+` *Desire*, `Rew−` *Anger*, `Pun+` *Disgust*, `Pun−` *Calm* — canonical prototype *Calm* without any added epithet, explicitly dissociated from Skinnerian negative reinforcement `R−`), filled-surface planar layers $|x| + |y| \le R(Z)$, and **Table 1b in 17 sub-sectors** (1 fixed center + 8 conjugate antagonist pairs `A1, A2, D1, D2, L1, L2, L3, L4` with $|X| \leftrightarrow |Y|$ swap decoupled from $A' = A$).
- **Garde A4-Sanctuaire :** Le corps théorique demeure 100 % exempt de statistiques *in silico* (`PXP`, simulations DSM-5, `Lexicon176`), afin que les rapporteurs évaluent l'architecture conceptuelle et ses 5 prédictions réfutables P1–P5 (Tableau 2) sur leurs mérites théoriques propres.
- **Économie de format :** Calibrer entre 9 000 et 12 000 mots pour *Psychological Review* / *BBS* / *NBR* (ou version resserrée ~6 000 mots pour *Emotion Review*), avec les 4 figures vectorielles haute résolution (Figures 1 à 4 alignées `v3.0.0`).

### 2.2. Classement stratégique des revues cibles (Voie 1)
1. ***Psychological Review* (APA) — Cible prioritaire n° 1 :** Référence mondiale pour les théories formelles de l'affect (ex. Russell, 2003). Atout décisif : formalisation Lean 4 complète (Guest & Martin, 2021 ; Robinaugh et al., 2021) + 5 prédictions quantitatives à critères d'abandon explicites (notamment l'exposant libre $p$ contre Russell $p = 2$, le quadrant risqué $(+X\text{ faible}, -Y\text{ fort})$ de P4, et `Peur → Dégoût` contre `Peur → Tristesse` en P5).
2. ***Emotion Review* (SAGE / ISRE) — Cible rapide n° 2 :** Spécialisée en théorie affective ; accueil naturel du dialogue critique avec Ekman, Russell, Scherer, Barrett, Panksepp et Rolls. Format plus court, délai éditorial rapide.
3. ***Behavioral and Brain Sciences* (Cambridge) — Option cible d'impact dialogique :** Le format *Target Article + Open Peer Commentary* est idéal pour exposer simultanément le noyau formel (`FORMAL_AUDIT_PACK.md`) et les prédictions falsifiables à la critique ouverte des théoriciens de l'inférence active et des sciences affectives.
4. ***Neuroscience & Biobehavioral Reviews* (Elsevier) — Option intégrative « Affectome » :** Positionnement direct dans le sillage de Schiller et al. (2024, *The human affectome*), reliant inférence intéroceptive, allostasie et taxonomie fonctionnelle.

### 2.3. Matériel supplémentaire formel & Attestation humaine indépendante sur les 8 théorèmes piliers
Par souci d'honnêteté scientifique (l'auteur étant psychologue clinicien et non mathématicien formel), le dépôt publie déjà la déclaration transparente d'assistance IA et [`FORMAL_AUDIT_PACK.md`](FORMAL_AUDIT_PACK.md). Avant la soumission en Voie 1 (ou au plus tard lors de la révision), il est fortement recommandé de **lever l'objection prévisible sur la vérification humaine** par un protocole léger en 4 étapes :

1. **Solliciter 1 à 2 vérificateurs indépendants spécialistes Lean 4** (communauté Lean Zulip *#formalized-mathematics*, chercheur en méthodes formelles universitaire, ou relecteur open-science rémunéré/remercié en *Acknowledgments*).
2. **Périmètre borné à 30 minutes de lecture :** Limiter la demande aux **8 théorèmes piliers `P1`–`P8`** recensés en tête de [`FORMAL_AUDIT_PACK.md`](FORMAL_AUDIT_PACK.md) (`projectToCoreAffect_surjective`, `deployCouplingWithPrecision_valid`, `dissipation_reaches_veille`, `antagonistPoint_inverts_hedonic_polarity`, `end_to_end_coherence`, `canonicalDepthKernel_axial_instability_p2`, `lyapunov_expected_drift_constant`, `rolls_contingencies_z2_bound` & `full_end_to_end_v3_coherence`).
3. **Checklist de 4 points à attester par écrit :**
   - Re-compilation locale propre (`lake build` + `lake env lean Cartograffect/AuditTests.lean`) avec `0 sorryAx`, `0 native_decide`, `0` axiome *ad hoc* ;
   - Adéquation sémantique entre les énoncés formels `P1`–`P8` et leur formulation en prose dans le manuscrit (zéro lemme vide ni hypothèse cachée) ;
   - Conformité de l'isolation de `Lexicon176.lean` hors des 8 modules normatifs ;
   - Exactitude de la ventilation axiomatique (`Classical.choice` explicitement documenté, zéro qualification « constructive » abusive).
4. **Archivage de l'attestation datée et signée** dans un fichier dédié (ex. `ATTESTATION_FORMAL_AUDIT.md`) joint au supplément Zenodo/OSF et mentionné dans la lettre de couverture.

---

## 3. Voie 2 — Stage 1 Registered Report (`V2 → V3`)

### 3.1. Revues cibles et verrouillage OSF
1. ***Nature Human Behaviour* (Registered Reports track) — Cible prioritaire n° 1 :** Accepte les Stage 1 Registered Reports testant de grandes questions théoriques en psychologie et neurosciences affectives (ex. géométrie de l'affect, réfutation $L_1$ vs $L_2$ de Russell, bijection de Rolls). Exige précisément le **Study Design Table** (Section 5 de `STAGE1_REGISTERED_REPORT_STUDY1.md`), l'analyse de puissance / BFDA pour $N \ge 600$, les critères numériques de réfutation a priori et le code exécutable (`protocols/study1_analysis_pipeline.py`).
2. ***Royal Society Open Science* (Registered Reports track) — Cible prioritaire n° 2 (ou via *Peer Community in Registered Reports*, PCI-RR) :** Politique éditoriale transparente, licence `CC-BY-4.0` native, évaluation rigoureuse centrée sur la sévérité des tests et la puissance sans biais de nouveauté, délai rapide vers l'*In-Principle Acceptance* (IPA).

**Séquence stricte avant soumission Stage 1 :**
1. Déposer le préprint théorique v3.0.0 anglais sur PsyArXiv / Zenodo (`10.5281/zenodo.24022795`) comme référence théorique citée par le Stage 1 RR (aucun chevauchement de résultats puisque `V3 = 0`).
2. Obtenir l'approbation éthique (IRB / CER) pour la collecte anonyme en ligne ($N_{\text{brut}} = 660$, FR + EN) — ou soumettre en Stage 1 sous réserve d'approbation éthique avant IPA selon la revue.
3. Soumettre [`protocols/STAGE1_REGISTERED_REPORT_STUDY1.md`](protocols/STAGE1_REGISTERED_REPORT_STUDY1.md) avec [`protocols/study1_analysis_pipeline.py`](protocols/study1_analysis_pipeline.py) et [`extensions/in_silico/results/v3_identifiability_report.json`](extensions/in_silico/results/v3_identifiability_report.json) en fichiers supplémentaires (explicitement balisés `pilot_pipeline_dry_run` / `synthetic_identifiability_check`, `V3 = 0`).
4. Dès l'*In-Principle Acceptance* (IPA), **geler l'enregistrement OSF horodaté** (`https://osf.io/z89sg`) avec les empreintes SHA-256 du protocole et du script, puis lancer la collecte humaine ($N \ge 600$).

### 3.2. Trame de Lettre de Couverture Éditoriale (Stage 1 Registered Report — *Nature Human Behaviour* / *Royal Society Open Science*)

> **Subject:** Stage 1 Registered Report Submission — *Testing the Geometry of Core Affect: Instrumental Controllability, Autonomous Arousal, Minkowski Capacity Norm ($L_1$ vs $L_2$), Rolls’ $2 \times 2$ Contingencies, and Contralateral Antagonism ($N \ge 600$)*
>
> Dear Editor,
>
> Please find enclosed our Stage 1 Registered Report manuscript entitled *"Testing the Geometry of Core Affect: Instrumental Controllability, Autonomous Arousal, Minkowski Capacity Norm ($L_1$ vs $L_2$), Rolls’ $2 \times 2$ Contingencies, and Contralateral Antagonism in a Cross-Linguistic Study ($N \ge 600$)"* for consideration at *[Nature Human Behaviour / Royal Society Open Science]*.
>
> **Scientific significance and falsifiability.** A longstanding debate in affective science opposes two-dimensional circumplex models of core affect (Valence × Arousal, Euclidean $L_2$ geometry; Russell, 1980) against appraisal and active-inference frameworks emphasizing instrumental controllability and epistemic updating. We recently formalized an integrative predictive-processing architecture of affect (CARTOGRAFFECT v3.0.0; internal deductive consistency mechanically verified in Lean 4 across 8 normative modules and 148 substantial theorems, DOI: `10.5281/zenodo.23833938` / `10.5281/zenodo.24022795`). Crucially, formal consistency is not empirical validation: **zero human empirical data have been collected to date (`V3 = 0`)**.
>
> This Stage 1 Registered Report submits the core structural postulates of CARTOGRAFFECT v3.0.0 to **three severe, high-powered, cross-linguistic empirical tests** ($N_{\text{analysed}} \ge 600$ naive French- and English-speaking participants; power $> 0.99$ at $\alpha = 0.01$; BFDA $> 0.98$ for $\text{BF}_{10} > 10$ / $\text{BF}_{01} > 10$), with **explicit a priori abandonment criteria and zero immunization clauses**:
>
> 1. **Test 1A (Construct validity of instrumental controllability $Y$, orthogonality of autonomous arousal $A$, and filled-surface radial structure):** Blind rating of the 17 functional sub-sectors across hierarchical depth strata ($Z = 2\text{–}5$) on continuous VAS scales ($X, Y, A, V$). The model is explicitly refuted if low-control aversive states (e.g., *anguish*, *terror*, *shame*) fail to separate from agentic opposition (*anger*, *hostility*, *revolt*) on $Y$, if perimeter landmarks do not exceed interior landmarks on $A$, or if $|r(Y, A)| > 0.70$.
> 2. **Test 1B (Free estimation of the Minkowski capacity exponent $p$ on the capacity boundary $A = 1$):** Hierarchical Bayesian estimation of $p$ in $|X|^p + |Y|^p = R^p$ directly pitted against Russell's Euclidean circumplex ($p = 2$) and an unconstrained no-budget model via PSIS-LOO-CV, WAIC, and Bayes Factors. **We commit a priori to abandoning the $L_1$ diamond metric** if $\hat{p} \ge 1.70$, if $L_2$ or the unconstrained model wins in LOO-CV ($\Delta\text{ELPD} > 2\,\text{SE}$), or if $\text{BF}_{01} > 10$.
> 3. **Test 1C (Rolls' $2 \times 2$ reinforcement bijection bounded to $Z = 2$ and contralateral amplitude-swap law on lateral pairs `L1–L4`):** Blind test of non-lexicalized `Rew+`, `Rew−`, `Pun+`, `Pun−` scenarios predicting *Desire*, *Anger*, *Disgust*, and *Calm* (strictly dissociated from Skinnerian active avoidance `R−`), alongside a direct LOO-CV/BF comparison of contralateral axis-dominance swapping $(|X| \leftrightarrow |Y|$, decoupled from $A' = A$) against rival pure central inversion $(-X, -Y)$.
>
> **Reproducibility and epistemic transparency.** The complete executable analysis pipeline (`protocols/study1_analysis_pipeline.py`, AGPL-3.0-or-later) has been verified in a dual-world `pilot_pipeline_dry_run` confirming that it reliably corroborates the model under a CARTOGRAFFECT data-generating process and **reliably outputs `REFUTED`** under a rival Euclidean/central-inversion process. In preparation for subsequent behavioral Study 2, we also include a `synthetic_identifiability_check` (`extensions/in_silico/results/v3_identifiability_report.json`) verifying parameter identifiability of the 5-parameter orthogonalized behavioral model under realistic Likert 1–7 ordinal noise, 10% MCAR missingness, and 5% motor lapses ($\min r = 0.926$, $\max |r_{\text{off-diag}}| = 0.174 < 0.35$). Neither simulation is presented as empirical evidence. Upon Stage 1 In-Principle Acceptance, the protocol and analysis code will be timestamp-frozen on OSF (`https://osf.io/z89sg`) prior to enrolling the first participant, and all anonymized raw data and scripts will be released openly regardless of outcome.
>
> **AI disclosure & competing interests.** The author (clinical psychologist, independent researcher) conceived and owns all theoretical, psychological, and experimental decisions; generative AI tools assisted technical Lean 4 formalization and software engineering, transparently disclosed in the manuscript and companion repository. The author declares no competing interests and confirms that this protocol is not under consideration elsewhere.
>
> Thank you for considering our Stage 1 Registered Report.
>
> Sincerely,  
> **Manuel Cabelguen, Ph. D.**  
> Independent Researcher, Sainte-Agathe-des-Monts, Québec, Canada  
> `manuelcabelguen@gmail.com` · OSF: `https://osf.io/z89sg`

---

## 4. Chronogramme Opérationnel Synthétique (J0 → J+180)

| Phase | Horizon | Livrables & Jalons Go/No-Go |
|:---|:---|:---|
| **M0 — Consolidation pré-soumission** | J0 → J+21 | Audit indépendant 30 min des 8 piliers Lean 4 (`ATTESTATION_FORMAL_AUDIT.md`) · Adaptation anglaise sobre de `docs/01-Article_Cartograffect.md` (`66d9a0d`) · Dépôt préprint anglais Zenodo (`10.5281/zenodo.24022795`) · Dossier éthique (CER / IRB). |
| **M1 — Soumissions parallèles** | J+21 → J+30 | **Voie 1 :** Soumission de l'article théorique anglais (*Psychological Review*, fallback *Emotion Review* / *BBS*).<br>**Voie 2 :** Soumission du Stage 1 Registered Report (`STAGE1_REGISTERED_REPORT_STUDY1.md` + `study1_analysis_pipeline.py`) à *Nature Human Behaviour* (fallback *Royal Society Open Science* / PCI-RR). |
| **M2 — Gel OSF & Collecte Étude 1** | Post-IPA Stage 1 (~J+90 → J+120) | Gel horodaté OSF (`https://osf.io/z89sg`) · Collecte bilingue Prolific ($N_{\text{brut}} = 660 \to N_{\text{analysable}} \ge 600$, FR + EN) · Exécution aveugle de `study1_analysis_pipeline.py` sur les données réelles. |
| **M3 — Soumission Stage 2 & Décision V3** | J+120 → J+180 | Rédaction et soumission Stage 2 (quel que soit le verdict) · Si 1A–1C corroborés : déclenchement Étude 2 (comportementale/SCR/HRV sur les 5 paramètres $(\rho, p, \gamma_A, \chi, \beta)$) puis Étude 3 (EMA 14 jours P2/P3) · Si réfutation d'un pilier (ex. $p \ge 1{,}70$) : révision formelle documentée en `v4.0` ou abandon de la métrique $L_1$. |
